# Citation tooling (issue #1): the generated bibliography
# Bib/TaxonBodyMass_PrimaryCitations.bib.
#
#   ReadBibEntries(path)        key, type, doi of every entry of a .bib file
#   BibKeyFor(...)              'Surname:YYYYaa' with aa -> ab -> ... over every known key;
#                               an existing key is reused when the DOI is already in a bib
#   BuildBibEntry(work, key)    a BibTeX entry from a Crossref work record only (type map,
#                               LaTeX escaping); nothing typed by a person or an LLM
#   BuildBibEntryNoDOI(...)     an entry from the owner-approved parsed fields with the
#                               note 'No DOI; from <label> reference list; approved <date> <by>'
#   WritePrimaryBib(entries)    the GENERATED header and the entries in key order
#   CheckBibKeysUnique()        stops on a key present in both bib files
#   CheckBibSyntax(path)        RefManageR parse of a generated file (optional)
# Offline.

# ---- reading --------------------------------------------------------------------------
# The entries of a .bib file: key, type (lowercase) and doi (lowercase, NA when
# the entry has none), by line scan; BibDesk's and the generated file's layout
# both put '@type{key,' on one line and one field per line.
ReadBibEntries <- function(path) {
  if (!file.exists(path)) return(data.frame(key = character(), type = character(), doi = character(), stringsAsFactors = FALSE))
  lines <- readLines(path, warn = FALSE, encoding = 'UTF-8')
  starts <- grep('^\\s*@[A-Za-z]+\\s*\\{', lines, perl = TRUE)
  starts <- starts[!grepl('^\\s*@(comment|string|preamble)', lines[starts], ignore.case = TRUE, perl = TRUE)]
  if (length(starts) == 0) return(data.frame(key = character(), type = character(), doi = character(), stringsAsFactors = FALSE))
  ends <- c(starts[-1] - 1L, length(lines))
  out <- data.frame(
    key  = trimws(sub('^\\s*@[A-Za-z]+\\s*\\{\\s*([^,]+),.*$', '\\1', lines[starts], perl = TRUE)),
    type = tolower(sub('^\\s*@([A-Za-z]+).*$', '\\1', lines[starts], perl = TRUE)),
    doi  = vapply(seq_along(starts), function(i) {
      block <- lines[starts[i]:ends[i]]
      d <- grep('^\\s*doi\\s*=', block, ignore.case = TRUE, perl = TRUE, value = TRUE)
      if (length(d) == 0) return(NA_character_)
      CleanDOI(sub('^\\s*doi\\s*=\\s*[{"]?\\s*([^}"]+?)\\s*[}"]?\\s*,?\\s*$', '\\1', d[1], ignore.case = TRUE, perl = TRUE))
    }, character(1)),
    stringsAsFactors = FALSE)
  rownames(out) <- NULL
  out
}

# ---- keys -------------------------------------------------------------------------------
# The surname part of a key: diacritics folded, blanks to '-', anything but
# letters, digits and '-' removed ('Menden-Deuer', 'van-der-Meer', 'Kiorboe').
FoldSurnameForKey <- function(surname) {
  s <- FoldASCII(trimws(surname))
  s <- gsub('\\s+', '-', s)
  s <- gsub('[^A-Za-z0-9-]', '', s)
  s
}

TwoLetterSuffixes <- function() {
  l <- letters
  as.vector(t(outer(l, l, paste0)))    # aa, ab, ..., az, ba, ...
}

# 'Surname:YYYYaa' (BibDesk's cite-key format), with the first free two-letter
# suffix over `known_keys` (curated bib + primary bib + Sheet keys). When `doi`
# is already attached to a key in `known_dois` (named by key), that key is
# returned instead, so the same work never gets two keys (issue #1, F9).
BibKeyFor <- function(surname, year, doi = NA_character_, known_keys = character(), known_dois = character()) {
  doi <- CleanDOI(doi)
  if (!is.na(doi) && length(known_dois) > 0) {
    hit <- names(known_dois)[!is.na(known_dois) & known_dois == doi]
    if (length(hit) > 0) return(hit[1])
  }
  base <- FoldSurnameForKey(surname)
  if (is.na(base) || !nzchar(base)) base <- 'Anon'
  year <- if (is.na(year)) 'nd' else as.character(year)
  for (suf in TwoLetterSuffixes()) {
    key <- paste0(base, ':', year, suf)
    if (!key %in% known_keys) return(key)
  }
  stop('BibKeyFor(): no free suffix for ', base, ':', year, call. = FALSE)
}

# ---- building entries ------------------------------------------------------------------
# Text from a service record into a BibTeX field value: HTML tags and entities
# removed, the LaTeX special characters escaped. Braces are kept (none occur in
# Crossref metadata in practice; a stray one is escaped).
EscapeLaTeX <- function(x) {
  x <- as.character(x)
  x <- gsub('<[^>]+>', '', x, perl = TRUE)
  x <- gsub('&amp;', '&', x, fixed = TRUE); x <- gsub('&lt;', '<', x, fixed = TRUE); x <- gsub('&gt;', '>', x, fixed = TRUE)
  x <- gsub('&nbsp;', ' ', x, fixed = TRUE); x <- gsub('&#?\\w+;', '', x, perl = TRUE)
  x <- gsub('\\', '\\textbackslash{}', x, fixed = TRUE)
  for (ch in c('&', '%', '$', '#', '_')) x <- gsub(ch, paste0('\\', ch), x, fixed = TRUE)
  x <- gsub('~', '\\textasciitilde{}', x, fixed = TRUE)
  x <- gsub('^', '\\textasciicircum{}', x, fixed = TRUE)
  x <- gsub('(?<!\\\\)\\{', '\\\\{', x, perl = TRUE)
  x <- gsub('(?<!\\\\)\\}', '\\\\}', x, perl = TRUE)
  x <- gsub('\\textbackslash\\{\\}', '\\textbackslash{}', x, fixed = TRUE)
  trimws(gsub('\\s+', ' ', x, perl = TRUE))
}

crossref_type_map <- c('journal-article' = 'article', 'book' = 'book', 'monograph' = 'book',
                       'edited-book' = 'book', 'reference-book' = 'book', 'book-chapter' = 'incollection',
                       'book-part' = 'incollection', 'book-section' = 'incollection',
                       'dissertation' = 'phdthesis', 'report' = 'techreport',
                       'proceedings-article' = 'inproceedings')

CrossrefAuthors <- function(work) {
  if (length(work$author) == 0) return(NA_character_)
  parts <- vapply(work$author, function(a) {
    if (!is.null(a$family)) {
      fam <- a$family; giv <- if (!is.null(a$given)) a$given else ''
      if (nzchar(giv)) paste0(fam, ', ', giv) else fam
    } else if (!is.null(a$name)) paste0('{', a$name, '}') else NA_character_
  }, character(1))
  parts <- parts[!is.na(parts)]
  if (length(parts) == 0) NA_character_ else paste(EscapeLaTeX(parts), collapse = ' and ')
}

CrossrefYear <- function(work) {
  for (f in c('issued', 'published-print', 'published-online', 'approved', 'created')) {
    dp <- work[[f]][['date-parts']]
    if (length(dp) > 0 && length(dp[[1]]) > 0 && !is.null(dp[[1]][[1]])) return(as.integer(dp[[1]][[1]]))
  }
  NA_integer_
}

CrossrefTitle <- function(work) {
  t <- if (length(work$title) > 0) work$title[[1]] else NA_character_
  if (length(work$subtitle) > 0 && !is.na(t) && nzchar(work$subtitle[[1]]) &&
      !grepl(tolower(work$subtitle[[1]]), tolower(t), fixed = TRUE))
    t <- paste0(t, ': ', work$subtitle[[1]])
  t
}

FormatBibEntry <- function(type, key, fields) {
  fields <- fields[!vapply(fields, function(v) is.null(v) || length(v) == 0 || is.na(v) || !nzchar(v), logical(1))]
  body <- paste0('\t', names(fields), ' = {', unlist(fields), '}')
  paste0('@', type, '{', key, ',\n', paste(body, collapse = ',\n'), '}')
}

# A BibTeX entry built from a Crossref work record (the `message` of
# /works/<doi>) and nothing else: author, title, the container by type,
# volume, number, pages, year, doi. Returns the entry text.
BuildBibEntry <- function(work, key) {
  if (is.null(work) || is.null(work$DOI)) stop('BuildBibEntry(): a Crossref work record with a DOI is required', call. = FALSE)
  type <- unname(crossref_type_map[work$type]); if (is.na(type)) type <- 'misc'
  container <- if (length(work[['container-title']]) > 0) work[['container-title']][[1]] else NA_character_
  publisher <- work$publisher
  inst <- if (length(work$institution) > 0) work$institution[[1]]$name else NA_character_
  f <- list(author = CrossrefAuthors(work), title = EscapeLaTeX(CrossrefTitle(work)))
  if (type == 'article') { f$journal <- EscapeLaTeX(container) }
  else if (type == 'incollection' || type == 'inproceedings') { f$booktitle <- EscapeLaTeX(container); f$publisher <- EscapeLaTeX(publisher) }
  else if (type == 'book') { f$publisher <- EscapeLaTeX(publisher); if (!is.na(container) && length(work$title) > 0 && container != work$title[[1]]) f$series <- EscapeLaTeX(container) }
  else if (type == 'phdthesis') { f$school <- EscapeLaTeX(if (!is.na(inst)) inst else publisher) }
  else if (type == 'techreport') { f$institution <- EscapeLaTeX(if (!is.na(inst)) inst else publisher) }
  else { f$howpublished <- EscapeLaTeX(if (!is.na(container)) container else publisher) }
  f$volume <- if (!is.null(work$volume)) EscapeLaTeX(work$volume) else NA_character_
  f$number <- if (!is.null(work$issue)) EscapeLaTeX(work$issue) else NA_character_
  f$pages  <- if (!is.null(work$page)) gsub('-+', '--', EscapeLaTeX(work$page)) else NA_character_
  yr <- CrossrefYear(work)
  f$year <- if (is.na(yr)) NA_character_ else as.character(yr)
  f$doi  <- CleanDOI(work$DOI)
  FormatBibEntry(type, key, f)
}

# A DOI-less entry from the owner-approved parsed fields of a
# primary_references row (`nodoi` decision): the type follows the container
# (thesis -> phdthesis, a volume or pages -> article, else book/misc) and the
# note records the provenance of the text and the approval.
BuildBibEntryNoDOI <- function(row, key, approved_by, approved_date) {
  row <- as.list(row)
  cont <- row$parsed_container
  grey_thesis <- !is.na(cont) && grepl('thesis|dissertation', cont, ignore.case = TRUE)
  type <- if (grey_thesis) 'phdthesis'
          else if (!is.na(row$parsed_volume) || !is.na(row$parsed_pages)) 'article'
          else if (!is.na(cont)) 'book' else 'misc'
  f <- list(author = if (is.na(row$parsed_author1)) NA_character_ else EscapeLaTeX(row$parsed_author1),
            title  = EscapeLaTeX(row$parsed_title))
  if (type == 'article') f$journal <- EscapeLaTeX(cont)
  else if (type == 'phdthesis') f$school <- EscapeLaTeX(sub('^.*thesis,?\\s*', '', cont, ignore.case = TRUE))
  else if (type == 'book') f$publisher <- EscapeLaTeX(cont)
  f$volume <- if (is.na(row$parsed_volume)) NA_character_ else EscapeLaTeX(row$parsed_volume)
  f$pages  <- if (is.na(row$parsed_pages)) NA_character_ else gsub('-+', '--', EscapeLaTeX(row$parsed_pages))
  f$year   <- if (is.na(row$parsed_year)) NA_character_ else as.character(row$parsed_year)
  f$note   <- sprintf('No DOI; from %s reference list; approved %s %s', row$source_label, approved_date, approved_by)
  FormatBibEntry(type, key, f)
}

# ---- the file ---------------------------------------------------------------------------
primary_bib_header <- function(tool_version = citations_tool_version) c(
  '%% GENERATED by R/library/citations/build_bib.r -- do not edit by hand.',
  sprintf('%%%% %s. Entries are built from Crossref metadata (BuildBibEntry) or from', tool_version),
  '%% owner-approved fields (BuildBibEntryNoDOI, see the note field) and are re-derivable',
  '%% from sources/databases/*/primary_references.csv and sources/citations_cache/.',
  '%% Keys are in byte order; a key present in Bib/TaxonBodyMass_Citations.bib as well',
  '%% fails the pipeline (CheckBibKeysUnique). Issue #1.',
  '')

# `entries`: a named character vector, key -> entry text. Written in byte order
# of the keys, UTF-8, one blank line between entries.
WritePrimaryBib <- function(entries, path, tool_version = citations_tool_version) {
  stopifnot(is.character(entries), !is.null(names(entries)) || length(entries) == 0)
  if (anyDuplicated(names(entries))) stop('WritePrimaryBib(): duplicated key(s) ', paste(unique(names(entries)[duplicated(names(entries))]), collapse = ', '), call. = FALSE)
  entries <- entries[order(names(entries), method = 'radix')]
  con <- file(path, open = 'w', encoding = 'UTF-8')
  on.exit(close(con))
  writeLines(primary_bib_header(tool_version), con)
  if (length(entries) > 0) writeLines(paste0(unname(entries), '\n'), con)
  invisible(path)
}

# Stops when a key occurs in both bib files (or twice within one of them).
CheckBibKeysUnique <- function(curated_path, primary_path) {
  cur <- ReadBibEntries(curated_path); pri <- ReadBibEntries(primary_path)
  both <- intersect(cur$key, pri$key)
  if (length(both) > 0)
    stop('bib key(s) present in both ', basename(curated_path), ' and ', basename(primary_path), ': ',
         paste(both, collapse = ', '), call. = FALSE)
  dup <- c(cur$key[duplicated(cur$key)], pri$key[duplicated(pri$key)])
  if (length(dup) > 0)
    stop('duplicated bib key(s): ', paste(unique(dup), collapse = ', '), call. = FALSE)
  invisible(list(curated = cur, primary = pri))
}

# RefManageR must parse every entry of a generated file (standard types only).
CheckBibSyntax <- function(path) {
  if (!requireNamespace('RefManageR', quietly = TRUE)) return(invisible(NA_integer_))
  n_expected <- nrow(ReadBibEntries(path))
  b <- suppressMessages(suppressWarnings(RefManageR::ReadBib(path, check = FALSE, .Encoding = 'UTF-8')))
  if (length(b) != n_expected)
    stop(basename(path), ': RefManageR parsed ', length(b), ' of ', n_expected, ' entries', call. = FALSE)
  invisible(length(b))
}
