# Citation tooling (issue #1): the generated bibliography
# Bib/TaxonBodyMass_PrimaryCitations.bib.
#
#   ReadBibEntries(path)        key, type, doi of every entry of a .bib file
#   BibKeyFor(...)              'Surname:YYYYaa' with aa -> ab -> ... over every known key;
#                               an existing key is reused when the DOI is already in a bib
#   BuildBibEntry(work, key)    a BibTeX entry from a Crossref work record only (type map,
#                               LaTeX escaping); nothing typed by a person or an LLM
#   BuildBibEntryNoDOI(...)     an entry from the owner-approved parsed fields with the
#                               note 'No DOI; from <label> reference list; approved <date> <by>';
#                               the type (article, book, incollection, phdthesis,
#                               mastersthesis, misc) follows the conventions for the
#                               parsed_* fields set out before NoDOIEntryType()
#   AssignPrimaryKeys(...)      the --bib step over every source's accepted rows: keys,
#                               CiteIDs and the entries (rows without a Crossref record
#                               are reported, not fatal)
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
      # the closing brace of the entry may follow the field's own ('doi = {...}}' when doi is the last field)
      CleanDOI(sub('^\\s*doi\\s*=\\s*[{"]?\\s*([^}"]+?)\\s*[}"]*\\s*,?\\s*$', '\\1', d[1], ignore.case = TRUE, perl = TRUE))
    }, character(1)),
    stringsAsFactors = FALSE)
  rownames(out) <- NULL
  out
}

# ---- keys -------------------------------------------------------------------------------
# The surname part of a key: diacritics folded, blanks to '-', anything but
# letters, digits and '-' removed ('Menden-Deuer', 'van-der-Meer', 'Kiorboe').
# A surname as the services deliver it, made fit for a key: leading initials
# that a publisher folded into the family name ('A. Piechnik' -> 'Piechnik') are
# dropped, and the case is repaired token by token (#64; #114 item 8): an
# all-capitals token ('MULDER', the 'WHITE' of 'Evans-WHITE') is written in
# title case, and a token with a run of two or more capitals after a lowercase
# letter ('VillEGER') is lowercased after its first letter ('Villeger');
# ordinary mixed case ('McLaughlin', 'DeLong', "O'Gorman", 'van der Meer') is
# left alone. Diacritics are folded afterwards (FoldSurnameForKey()); a letter
# the record itself lost ('Bmstedt' for Båmstedt, 'Sma' for Srna, 'Schnheit')
# cannot be restored by code -- the owner renames such a key.
NormaliseSurname <- function(surname) {
  s <- trimws(as.character(surname))
  s <- sub('^(?:[A-Z]\\.\\s*)+(?=\\S)', '', s, perl = TRUE)
  Fix <- function(tok) {
    if (nchar(tok) > 1 && grepl('^[A-Z]+$', tok, perl = TRUE)) return(paste0(substr(tok, 1, 1), tolower(substring(tok, 2))))
    if (grepl('[a-z][A-Z]{2,}', tok, perl = TRUE)) return(paste0(substr(tok, 1, 1), tolower(substring(tok, 2))))
    tok
  }
  vapply(s, function(x) {
    if (is.na(x) || !nzchar(x)) return(x)
    toks <- regmatches(x, gregexpr("[^\\s'’-]+|[\\s'’-]+", x, perl = TRUE))[[1]]
    paste(vapply(toks, function(t) if (grepl("^[\\s'’-]+$", t, perl = TRUE)) t else Fix(t), character(1)), collapse = '')
  }, character(1), USE.NAMES = FALSE)
}

# The first author of a Crossref record that carries a name (a university
# thesis record may list a nameless contributor first), as the surname for key
# minting; NA when no author has one.
CrossrefFirstSurname <- function(work) {
  for (a in work[['author']]) {
    if (!is.null(a[['family']]) && nzchar(a[['family']])) return(a[['family']])
    if (!is.null(a[['name']]) && nzchar(a[['name']])) return(a[['name']])
  }
  NA_character_
}

FoldSurnameForKey <- function(surname) {
  s <- FoldASCII(NormaliseSurname(surname))
  s <- gsub('\\s+', '-', s)
  s <- gsub('[^A-Za-z0-9-]', '', s)
  s
}

# The first surname of an owner-approved author field ('Ikeda and Hirakawa and
# Imamura' -> 'Ikeda'; 'Kremer' -> 'Kremer'; '{Birdcare Avicultural}' ->
# 'Birdcare Avicultural'), for keys and CiteIDs of nodoi entries.
FirstOfAuthorList <- function(author) {
  a <- trimws(strsplit(as.character(author), '\\s+and\\s+', perl = TRUE)[[1]])[1]
  if (is.na(a)) NA_character_ else sub(',.*$', '', gsub('[{}]', '', a))    # a braced corporate name gives its words
}

# The DOI-less entry another source's `nodoi` decision already produced for the
# same work: among `prim` rows (every source's primary_references) with
# match_status nodoi_approved and a bibcite, the one whose first surname
# (FirstOfAuthorList, folded), year and normalised title equal `row`'s. A
# DOI-less work cited by two compilations thus keeps one key and one CiteID
# (owner decision 2026-10-04, Hebert_etal_2016 key 74 -> Kiorboe_2013 key 7).
# Returns that row as a list, or NULL.
MatchingNoDOIEntry <- function(row, prim) {
  row <- as.list(row)
  if (is.null(prim) || nrow(prim) == 0 || is.na(row$parsed_title) || is.na(row$parsed_year)) return(NULL)
  Key <- function(author1, year, title)
    paste(tolower(FoldASCII(vapply(as.character(author1), FirstOfAuthorList, character(1), USE.NAMES = FALSE))),
          as.character(year), NormaliseCitationString(title), sep = '\r')
  cand <- prim$match_status %in% 'nodoi_approved' & !is.na(prim$bibcite) & nzchar(prim$bibcite) &
          !(prim$source_label == row$source_label & prim$native_key == row$native_key) &
          !is.na(prim$parsed_title) & !is.na(prim$parsed_year) & !is.na(prim$parsed_author1)
  if (!any(cand)) return(NULL)
  hit <- which(cand)[Key(prim$parsed_author1[cand], prim$parsed_year[cand], prim$parsed_title[cand]) ==
                     Key(row$parsed_author1, row$parsed_year, row$parsed_title)]
  if (length(hit) == 0) return(NULL)
  as.list(prim[hit[1], ])
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
    known_dois <- setNames(CleanDOI(known_dois), names(known_dois))      # a row's DOI as recorded, whatever its case
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
# removed, the LaTeX special characters escaped. Braces of the source text are
# escaped (none occur in Crossref metadata in practice); the characters that
# become LaTeX commands are held in placeholders until the braces are done, so
# that the commands' own braces survive.
EscapeLaTeX <- function(x) {
  x <- as.character(x)
  x <- gsub('<[^>]+>', '', x, perl = TRUE)
  x <- gsub('&amp;', '&', x, fixed = TRUE); x <- gsub('&lt;', '<', x, fixed = TRUE); x <- gsub('&gt;', '>', x, fixed = TRUE)
  x <- gsub('&nbsp;', ' ', x, fixed = TRUE); x <- gsub('&#?\\w+;', '', x, perl = TRUE)
  x <- gsub('\\', '\u0001', x, fixed = TRUE)
  x <- gsub('~', '\u0002', x, fixed = TRUE)
  x <- gsub('^', '\u0003', x, fixed = TRUE)
  x <- gsub('{', '\\{', x, fixed = TRUE)
  x <- gsub('}', '\\}', x, fixed = TRUE)
  for (ch in c('&', '%', '$', '#', '_')) x <- gsub(ch, paste0('\\', ch), x, fixed = TRUE)
  x <- gsub('\u0001', '\\textbackslash{}', x, fixed = TRUE)
  x <- gsub('\u0002', '\\textasciitilde{}', x, fixed = TRUE)
  x <- gsub('\u0003', '\\textasciicircum{}', x, fixed = TRUE)
  trimws(gsub('\\s+', ' ', x, perl = TRUE))
}

crossref_type_map <- c('journal-article' = 'article', 'book' = 'book', 'monograph' = 'book',
                       'edited-book' = 'book', 'reference-book' = 'book', 'book-chapter' = 'incollection',
                       'book-part' = 'incollection', 'book-section' = 'incollection',
                       'dissertation' = 'phdthesis', 'report' = 'techreport',
                       'proceedings-article' = 'inproceedings')

# 'Family, Given and Family, Given'; an organisation (`name` without `family`)
# is braced so that BibTeX keeps it as one name. Every part is escaped before
# the braces are added.
CrossrefAuthors <- function(work) {
  if (length(work[['author']]) == 0) return(NA_character_)
  parts <- vapply(work[['author']], function(a) {
    if (!is.null(a[['family']])) {
      fam <- EscapeLaTeX(a[['family']]); giv <- if (!is.null(a[['given']])) EscapeLaTeX(a[['given']]) else ''
      if (nzchar(giv)) paste0(fam, ', ', giv) else fam
    } else if (!is.null(a[['name']])) paste0('{', EscapeLaTeX(a[['name']]), '}') else NA_character_
  }, character(1))
  parts <- parts[!is.na(parts)]
  if (length(parts) == 0) NA_character_ else paste(parts, collapse = ' and ')
}

CrossrefYear <- function(work) {
  for (f in c('issued', 'published-print', 'published-online', 'approved', 'created')) {
    dp <- work[[f]][['date-parts']]
    if (length(dp) > 0 && length(dp[[1]]) > 0 && !is.null(dp[[1]][[1]])) return(as.integer(dp[[1]][[1]]))
  }
  NA_integer_
}

# Every year a Crossref record carries (issued, print, online, approved, created).
CrossrefYears <- function(work) {
  out <- integer()
  for (f in c('issued', 'published-print', 'published-online', 'approved', 'created')) {
    dp <- work[[f]][['date-parts']]
    if (length(dp) > 0 && length(dp[[1]]) > 0 && !is.null(dp[[1]][[1]])) out <- c(out, as.integer(dp[[1]][[1]]))
  }
  unique(out[!is.na(out)])
}

# The year a new key and CiteID are minted with (#114 item 8): the owner's
# year override when recorded; else the citation's own year (`parsed_year`)
# when the record carries it among its dates -- a paper published online in
# 2012 and in print in 2013, cited as 2013, is keyed 2013, not Crossref's
# online-first `issued` year; else the record's year (CrossrefYear()). Only
# a year the record itself attests is taken from the citation. The entry's
# `year` field stays the record's unless overridden (BuildBibEntry()).
KeyYear <- function(work, year_override = NA_integer_, parsed_year = NA_integer_) {
  if (!is.na(year_override)) return(as.integer(year_override))
  if (!is.na(parsed_year) && as.integer(parsed_year) %in% CrossrefYears(work)) return(as.integer(parsed_year))
  CrossrefYear(work)
}

# Fields are read with [[ ]] throughout: `$` would partially match `issued`
# for a record without `issue` (books), `publisher-location` for one without
# `publisher`.
CrossrefTitle <- function(work) {
  t <- if (length(work[['title']]) > 0) work[['title']][[1]] else NA_character_
  if (length(work[['subtitle']]) > 0 && !is.na(t) && nzchar(work[['subtitle']][[1]]) &&
      !grepl(tolower(work[['subtitle']][[1]]), tolower(t), fixed = TRUE))
    t <- paste0(t, ': ', work[['subtitle']][[1]])
  t
}

FormatBibEntry <- function(type, key, fields) {
  fields <- fields[!vapply(fields, function(v) is.null(v) || length(v) == 0 || is.na(v[1]) || !nzchar(v[1]), logical(1))]
  body <- paste0('\t', names(fields), ' = {', unlist(fields), '}')
  paste0('@', type, '{', key, ',\n', paste(body, collapse = ',\n'), '}')
}

# A BibTeX entry built from a Crossref work record (the `message` of
# /works/<doi>) and nothing else: author, title, the container by type,
# volume, number, pages, year, doi. `year_override` (an owner decision
# ':year=YYYY' recorded in primary_references.csv) replaces the record's year
# and is noted in the entry; nothing else is ever typed in. Returns the entry text.
BuildBibEntry <- function(work, key, year_override = NA_integer_) {
  if (is.null(work) || is.null(work[['DOI']])) stop('BuildBibEntry(): a Crossref work record with a DOI is required', call. = FALSE)
  type <- if (is.null(work[['type']])) NA_character_ else unname(crossref_type_map[work[['type']]])
  if (length(type) != 1 || is.na(type)) type <- 'misc'        # an unmapped or missing type
  container <- if (length(work[['container-title']]) > 0) work[['container-title']][[1]] else NA_character_
  publisher <- if (is.null(work[['publisher']])) NA_character_ else work[['publisher']]
  inst <- if (length(work[['institution']]) > 0) work[['institution']][[1]][['name']] else NA_character_
  if (is.null(inst)) inst <- NA_character_
  f <- list(author = CrossrefAuthors(work), title = EscapeLaTeX(CrossrefTitle(work)))
  if (type == 'article') { f$journal <- EscapeLaTeX(container) }
  else if (type == 'incollection' || type == 'inproceedings') { f$booktitle <- EscapeLaTeX(container); f$publisher <- EscapeLaTeX(publisher) }
  else if (type == 'book') { f$publisher <- EscapeLaTeX(publisher); if (!is.na(container) && length(work[['title']]) > 0 && container != work[['title']][[1]]) f$series <- EscapeLaTeX(container) }
  else if (type == 'phdthesis') { f$school <- EscapeLaTeX(if (!is.na(inst)) inst else publisher) }
  else if (type == 'techreport') { f$institution <- EscapeLaTeX(if (!is.na(inst)) inst else publisher) }
  else { f$howpublished <- EscapeLaTeX(if (!is.na(container)) container else publisher) }
  f$volume <- if (!is.null(work[['volume']])) EscapeLaTeX(work[['volume']]) else NA_character_
  f$number <- if (!is.null(work[['issue']])) EscapeLaTeX(work[['issue']]) else NA_character_
  f$pages  <- if (!is.null(work[['page']])) gsub('-+', '--', EscapeLaTeX(work[['page']])) else NA_character_
  yr <- CrossrefYear(work)
  if (!is.na(year_override)) {
    f$note <- sprintf('Year %s by owner decision (the Crossref record says %s)', year_override, if (is.na(yr)) 'none' else yr)
    yr <- as.integer(year_override)
  }
  f$year <- if (is.na(yr)) NA_character_ else as.character(yr)
  f$doi  <- CleanDOI(work[['DOI']])
  FormatBibEntry(type, key, f)
}

# ---- DOI-less entries: the conventions for the owner's parsed_* fields -----------------
# A `nodoi` entry is built from the owner-approved parsed fields alone, so the
# fields follow a small convention (issue #114, item 1; README):
#  * parsed_author1: 'Surname' or a BibTeX list 'A and B and C'; a corporate
#    author in braces, '{Birdcare Avicultural}', is written to the entry as
#    {{Birdcare Avicultural}} (one name for BibTeX), never escaped.
#  * parsed_container of a thesis: '<degree> thesis, <school>' -- an 'M.S.',
#    'MSc', 'M.A.', 'MPhil' or "Master's" degree gives @mastersthesis, any
#    other thesis or dissertation @phdthesis; the school is the text after
#    the thesis word.
#  * parsed_container of a book chapter, either form (both already in use):
#      In: <Editors> (eds.), <Book title>. <Publisher>, <Place>
#      <Book title> (<Editors>, eds), <Publisher>, <Place>
#    A leading 'In:' (optionally after a pages clause, 'pp. 84-116. In:') or an
#    editor marker -- '(eds)', '(Eds.)', '(ed. Name)', '(editor)', 'editors',
#    ', eds)' -- makes the entry @incollection: editor, booktitle (up to the
#    first sentence end after the marker), publisher (the rest); a singular
#    'ed.' outside brackets is an edition, not a marker. Pages in the leading
#    clause fill parsed_pages when that is empty.
#  * a database-style reference (a web page, an online database): a URL in
#    parsed_url (the optional column), in parsed_container or -- when the
#    container or the notes say database / web / online / accessed -- in
#    `notes`, with no volume or pages, gives @misc with howpublished (the
#    container) and url.
#  * otherwise a volume or pages give @article, a container alone @book, a
#    bare title @misc; parsed_url, when set, adds a url field to any type.
nodoi_masters_pattern <- "(\\bM\\.?\\s?Sc?\\.?(?=\\s)|\\bMSc\\b|\\bM\\.?A\\.(?=\\s)|\\b[Mm]aster'?s?\\b|\\bM\\.?Phil\\b)"
nodoi_thesis_pattern  <- '\\b(thesis|dissertation)\\b'
nodoi_editor_marker   <- '(?i)(\\((eds?|editors?)\\.?\\)|\\(eds?\\.?\\s|,\\s*(eds?|editors?)\\.?\\)|\\beditors?\\b|\\beds\\.?(?=[\\s,.:;)]|$))'
nodoi_url_pattern     <- '(https?://[^\\s)\\]]+|\\bwww\\.[^\\s)\\],;]+)'
nodoi_database_words  <- '(?i)\\b(database|data ?base|web ?page|website|web site|online|accessed|retrieved|www\\.)'

# The URL of a DOI-less reference: parsed_url, else a URL in the container,
# else -- for a database-style reference only -- a URL in the notes. NA when none.
NoDOIURL <- function(row) {
  Find <- function(x) {
    if (is.null(x) || is.na(x)) return(NA_character_)
    m <- regmatches(x, regexpr(nodoi_url_pattern, x, perl = TRUE))
    if (length(m) == 0) NA_character_ else sub('[.,;:]+$', '', m)
  }
  u <- if (!is.null(row$parsed_url)) row$parsed_url else NA_character_
  if (!is.na(u) && nzchar(trimws(u))) return(trimws(u))
  u <- Find(row$parsed_container)
  if (!is.na(u)) return(u)
  dbish <- any(grepl(nodoi_database_words, c(row$parsed_container, row$notes), perl = TRUE), na.rm = TRUE)
  if (dbish) Find(row$notes) else NA_character_
}

# The school of a thesis container ('Ph.D. thesis, Univ. of Rhode Island' ->
# 'Univ. of Rhode Island'; 'University of X, MSc thesis' -> 'University of X').
ThesisSchool <- function(cont) {
  s <- sub(paste0('^.*?', nodoi_thesis_pattern, '[,.:;]?\\s*'), '', cont, ignore.case = TRUE, perl = TRUE)
  if (!nzchar(trimws(s)))
    s <- sub(paste0('\\s*[,(]?\\s*(unpubl\\.?|unpublished)?\\s*(Ph\\.?\\s?D\\.?|D\\.?Phil\\.?|Dr\\.?|M\\.?\\s?Sc?\\.?|MSc\\.?|M\\.?A\\.?|',
                    "Master'?s?|MPhil|Doctoral|Diploma)?\\s*", nodoi_thesis_pattern, '[,.:;)]*\\s*$'), '', cont, ignore.case = TRUE, perl = TRUE)
  s <- trimws(gsub('^[,.:;\\s]+|[,.:;\\s]+$', '', s, perl = TRUE))
  if (nzchar(s)) s else NA_character_
}

# The parts of a book-chapter container under the convention above:
# list(editor, booktitle, publisher, pages), each NA when not found; NULL when
# the container carries neither an 'In:' prefix nor an editor marker.
ParseChapterContainer <- function(cont) {
  if (is.null(cont) || is.na(cont) || !nzchar(trimws(cont))) return(NULL)
  s <- gsub('\\s+', ' ', trimws(cont), perl = TRUE)
  # surrounding punctuation removed; a final period stays after a lone initial ('Rockstein, M.')
  Clean <- function(x) {
    x <- sub('^[\\s,.:;)(]+', '', trimws(x), perl = TRUE)
    for (k in 1:2) { x <- sub('[\\s,:;(]+$', '', x, perl = TRUE); x <- sub('(?<![^A-Za-z][A-Z])(?<!^[A-Z])\\.$', '', x, perl = TRUE) }
    x <- trimws(x)
    if (nzchar(x)) x else NA_character_
  }
  boundary <- '(?<=\\w\\w|\\d|\\)|\\])\\.\\s+(?=[A-Z0-9(])'
  has_marker <- grepl(nodoi_editor_marker, s, perl = TRUE)
  # a pages clause anywhere ('pp. 84-116', 'p. 127-223', '84-116. In:') fills the pages
  pg <- regmatches(s, regexec('(?i)(?:^|\\b(?:pages?|pp?)\\.?\\s*)(\\d+\\s*[-]+\\s*\\d+)(?=[.,;:\\s]|$)', s, perl = TRUE))[[1]]
  pages <- if (length(pg) > 0) gsub('\\s', '', pg[2]) else NA_character_
  StripPages <- function(x) if (is.na(x)) x else Clean(sub('(?i)[,.;:]?\\s*\\b(pages?|pp?)\\.?\\s*\\d+\\s*[-]+\\s*\\d+', '', x, perl = TRUE))
  # Form A: an optional pages clause, then 'In:' (or 'In ' when a marker follows)
  lead <- regmatches(s, regexec('(?i)^(?:(?:pages?|pp?\\.)?\\s*(\\d+\\s*[-]+\\s*\\d+)[.,]?\\s*)?in(:|\\s)\\s*(.*)$', s, perl = TRUE))[[1]]
  if (length(lead) > 0 && (lead[3] == ':' || has_marker)) {
    rest <- lead[4]
    mk <- regexpr(nodoi_editor_marker, rest, perl = TRUE)
    if (mk > 0) {
      editor <- Clean(substr(rest, 1, mk - 1))
      after  <- Clean(substr(rest, mk + attr(mk, 'match.length'), nchar(rest)))
    } else { editor <- NA_character_; after <- rest }
    if (is.na(after)) return(list(editor = editor, booktitle = NA_character_, publisher = NA_character_, pages = pages))
    sb <- regexpr(boundary, after, perl = TRUE)
    if (sb > 0) list(editor = editor, booktitle = StripPages(Clean(substr(after, 1, sb - 1))), publisher = Clean(substr(after, sb + 1, nchar(after))), pages = pages)
    else list(editor = editor, booktitle = StripPages(Clean(after)), publisher = NA_character_, pages = pages)
  } else if (has_marker) {
    # Form B: the editors in a bracketed block after the book title
    blocks <- gregexpr('\\([^()]*\\)', s, perl = TRUE)[[1]]
    hit <- if (blocks[1] > 0) which(grepl(nodoi_editor_marker, regmatches(s, gregexpr('\\([^()]*\\)', s, perl = TRUE))[[1]], perl = TRUE)) else integer()
    if (length(hit) > 0) {
      b <- blocks[hit[1]]; len <- attr(blocks, 'match.length')[hit[1]]
      inside <- sub('(?i)^\\s*(eds?|editors?)\\.?\\s+', '', substr(s, b + 1, b + len - 2), perl = TRUE)
      editor <- Clean(sub(nodoi_editor_marker, '', inside, perl = TRUE))
      before <- Clean(substr(s, 1, b - 1)); after <- Clean(substr(s, b + len, nchar(s)))
      # '<Editors> (editor) <Book title>. <Publisher>': the text before a marker-only
      # bracket is the editors when it reads as names (dotted initials, few tokens)
      if (is.na(editor) && !is.na(before) && grepl('\\b[A-Z]\\.', before, perl = TRUE) && length(strsplit(before, '\\s+')[[1]]) <= 8 && !is.na(after)) {
        sb <- regexpr(boundary, after, perl = TRUE)
        if (sb > 0) return(list(editor = before, booktitle = StripPages(Clean(substr(after, 1, sb - 1))), publisher = Clean(substr(after, sb + 1, nchar(after))), pages = pages))
        return(list(editor = before, booktitle = StripPages(after), publisher = NA_character_, pages = pages))
      }
      list(editor = editor, booktitle = StripPages(before), publisher = after, pages = pages)
    } else {
      # 'Book title. Editors, Editors, Publisher': the marker outside brackets, the
      # editors in the sentence before it
      mk <- regexpr(nodoi_editor_marker, s, perl = TRUE)
      before <- substr(s, 1, mk - 1)
      sb <- gregexpr(boundary, before, perl = TRUE)[[1]]
      publisher <- Clean(substr(s, mk + attr(mk, 'match.length'), nchar(s)))
      if (sb[1] > 0) { last <- sb[length(sb)]
        list(editor = Clean(substr(before, last + 1, nchar(before))), booktitle = StripPages(Clean(substr(before, 1, last - 1))), publisher = publisher, pages = pages) }
      else list(editor = NA_character_, booktitle = StripPages(Clean(before)), publisher = publisher, pages = pages)
    }
  } else NULL
}

# The owner-approved author field as BibTeX text: every name escaped; a
# corporate name the owner wrote in braces keeps them unescaped.
NoDOIAuthorField <- function(author1) {
  if (is.null(author1) || is.na(author1) || !nzchar(trimws(author1))) return(NA_character_)
  parts <- trimws(strsplit(author1, '\\s+and\\s+', perl = TRUE)[[1]])
  parts <- vapply(parts, function(a) {
    if (grepl('^\\{.*\\}$', a, perl = TRUE)) paste0('{', EscapeLaTeX(sub('^\\{(.*)\\}$', '\\1', a, perl = TRUE)), '}') else EscapeLaTeX(a)
  }, character(1), USE.NAMES = FALSE)
  paste(parts, collapse = ' and ')
}

# An editor list as the chapter container prints it ('Gans, C., Dawson, W. R.',
# 'Huei, R. B., Pianka, E. R. and Schoener, T. W.', 'Horn, H.-G., Bohme, W. &
# U. Krebs', 'Kunz TH, Fenton MB') in BibTeX form, the names joined by ' and ':
# the list is split at commas, '&' and 'and'; a piece that is only initials
# ('C.', 'W. R.', 'H.-G.', 'TH') belongs to the surname before it; a list
# already joined by ' and ' comes back unchanged. BibTeX reads a name list only
# at ' and ', so a comma-joined list is one unparsable name (RefManageR
# rejected six Meiri_2018 chapter entries, Hudson round 2026-10-06).
BibTeXNameList <- function(x) {
  if (is.null(x) || is.na(x) || !nzchar(trimws(x))) return(x)
  toks <- trimws(strsplit(x, '\\s*(?:,|&|\\band\\b)\\s*', perl = TRUE)[[1]])
  toks <- toks[nzchar(toks)]
  is_init <- grepl('^(?:[A-Z]\\.?[-\\s]*)+$', toks, perl = TRUE)
  names <- character(); for (i in seq_along(toks)) {
    if (is_init[i] && length(names) > 0) names[length(names)] <- paste0(names[length(names)], ', ', toks[i])
    else names <- c(names, toks[i])
  }
  paste(names, collapse = ' and ')
}

# The entry type of a DOI-less reference under the conventions above, with
# the chapter parts and the URL it rests on: list(type, chapter, url).
NoDOIEntryType <- function(row) {
  row <- as.list(row)
  cont <- row$parsed_container
  thesis <- !is.na(cont) && grepl(nodoi_thesis_pattern, cont, ignore.case = TRUE, perl = TRUE)
  chapter <- if (thesis) NULL else ParseChapterContainer(cont)
  url <- NoDOIURL(row)
  no_vp <- is.na(row$parsed_volume) && is.na(row$parsed_pages)
  type <- if (thesis) { if (grepl(nodoi_masters_pattern, cont, perl = TRUE)) 'mastersthesis' else 'phdthesis' }
          else if (!is.null(chapter)) 'incollection'
          else if (!is.na(url) && no_vp) 'misc'
          else if (!no_vp) 'article'
          else if (!is.na(cont)) 'book' else 'misc'
  list(type = type, chapter = chapter, url = url)
}

# A DOI-less entry from the owner-approved parsed fields of a
# primary_references row (`nodoi` decision): the type and the fields follow
# the conventions above and the note records the provenance of the text and
# the approval.
BuildBibEntryNoDOI <- function(row, key, approved_by, approved_date) {
  row <- as.list(row)
  cont <- row$parsed_container
  et <- NoDOIEntryType(row)
  type <- et$type
  f <- list(author = NoDOIAuthorField(row$parsed_author1), title = EscapeLaTeX(row$parsed_title))
  pages <- row$parsed_pages
  if (type == 'article') f$journal <- EscapeLaTeX(cont)
  else if (type %in% c('phdthesis', 'mastersthesis')) f$school <- EscapeLaTeX(ThesisSchool(cont))
  else if (type == 'incollection') {
    ch <- et$chapter
    f$editor    <- if (is.na(ch$editor)) NA_character_ else EscapeLaTeX(BibTeXNameList(ch$editor))
    f$booktitle <- if (is.na(ch$booktitle)) EscapeLaTeX(cont) else EscapeLaTeX(ch$booktitle)
    f$publisher <- if (is.na(ch$publisher)) NA_character_ else EscapeLaTeX(ch$publisher)
    if (is.na(pages) && !is.na(ch$pages)) pages <- ch$pages
  }
  else if (type == 'book') f$publisher <- EscapeLaTeX(cont)
  else if (type == 'misc' && !is.na(cont)) f$howpublished <- EscapeLaTeX(cont)
  f$volume <- if (is.na(row$parsed_volume)) NA_character_ else EscapeLaTeX(row$parsed_volume)
  f$pages  <- if (is.na(pages)) NA_character_ else gsub('-+', '--', EscapeLaTeX(pages))
  f$year   <- if (is.na(row$parsed_year)) NA_character_ else as.character(row$parsed_year)
  f$url    <- if (is.na(et$url)) NA_character_ else gsub('%', '\\%', et$url, fixed = TRUE)
  f$note   <- sprintf('No DOI; from %s reference list; approved %s %s', row$source_label, approved_date, approved_by)
  FormatBibEntry(type, key, f)
}

# ---- keys, CiteIDs and entries for every accepted row (--bib) ----------------------------
# The bib step over the primary_references rows of every source (`all_prim`):
# for each accepted row (certain, approved, nodoi_approved) in a deterministic
# order -- by DOI, then source and key, so that keys never depend on the run --
# the bib key, the CiteID and, for a key the curated bib lacks, the entry
# text. A DOI row's entry is built from its Crossref record (`work_for(doi)`,
# CrossrefWork() from the cache or the network); a row whose DOI has no
# Crossref record (an OpenAlex-only DOI approved before the rule of #114 item
# 3) keeps its bibcite / cite_id as they are and is reported in `no_record`
# instead of stopping the step. A record without any author name mints its
# key from the row's parsed surname and is reported in `authorless` (#64). A
# nodoi row reuses the key of the same DOI-less work approved for another
# source (MatchingNoDOIEntry()); a manual_bib row must name a curated key. A
# new key takes the normalised surname (NormaliseSurname()) and the year of
# KeyYear(); a row that already has a bibcite keeps it whatever these would
# give (existing keys are never renamed by the tool; the owner renames).
# A row that keeps its key keeps its CiteID (KeepOrMintCiteID()). `curated`:
# ReadBibEntries() of the curated bib; `ids`: the tracked CiteIDs table
# (Bibcite, CiteID, doi). Returns list(prim, entries, authorless, no_record):
# `entries` is the named character vector key -> entry text.
AssignPrimaryKeys <- function(all_prim, cfg, curated, ids, work_for = function(doi) CrossrefWork(doi, cfg)) {
  known_keys <- c(curated$key, ids$Bibcite)
  known_dois <- setNames(curated$doi, curated$key)
  known_ids  <- ids[, intersect(c('CiteID', 'Bibcite', 'doi'), names(ids)), drop = FALSE]
  entries <- character(); authorless <- character(); no_record <- character()
  acc <- which(all_prim$match_status %in% c('certain', 'approved', 'nodoi_approved'))
  acc <- acc[order(is.na(all_prim$doi[acc]), all_prim$doi[acc], all_prim$source_label[acc], all_prim$native_key[acc], method = 'radix')]
  row_dois <- setNames(all_prim$doi[acc], all_prim$bibcite[acc])[!is.na(all_prim$bibcite[acc])]
  has_id <- !is.na(all_prim$bibcite[acc]) & !is.na(all_prim$cite_id[acc])
  row_ids <- setNames(all_prim$cite_id[acc][has_id], all_prim$bibcite[acc][has_id])    # the CiteID the rows already give a key
  Remember <- function(i) {
    if (!is.na(all_prim$cite_id[i]) && !all_prim$cite_id[i] %in% known_ids$CiteID)
      known_ids <<- rbind(known_ids, data.frame(CiteID = all_prim$cite_id[i], Bibcite = all_prim$bibcite[i],
                                                doi = if ('doi' %in% names(known_ids)) all_prim$doi[i] else NULL, stringsAsFactors = FALSE)[, names(known_ids)])
  }
  for (i in acc) {
    r <- all_prim[i, ]
    if (!is.na(r$doi)) {
      w <- work_for(r$doi)
      if (is.null(w)) { no_record <- c(no_record, sprintf('%s %s (%s)', r$source_label, r$native_key, r$doi)); next }
      fam <- CrossrefFirstSurname(w)
      if (is.na(fam) || !nzchar(fam)) {
        fam <- FirstOfAuthorList(r$parsed_author1)
        if (is.na(fam) || !nzchar(fam)) fam <- 'Anon'
        authorless <- c(authorless, sprintf('%s %s (%s)', r$source_label, r$native_key, r$doi))
      }
      yr <- KeyYear(w, r$year_override, r$parsed_year)
      key <- if (!is.na(r$bibcite) && (r$bibcite %in% names(entries) || r$bibcite %in% curated$key)) r$bibcite
             else BibKeyFor(fam, yr, r$doi, known_keys, c(known_dois, row_dois))
      if (!key %in% curated$key && !key %in% names(entries)) entries[key] <- BuildBibEntry(w, key, r$year_override)
      known_keys <- union(known_keys, key)
      row_dois <- c(row_dois, setNames(r$doi, key))       # the next row with this DOI reuses the key
      all_prim$bibcite[i] <- key
      all_prim$cite_id[i] <- KeepOrMintCiteID(r, key, fam, yr, known_ids, row_ids)
      row_ids[key] <- all_prim$cite_id[i]
    } else if (r$match_status == 'nodoi_approved') {
      surname <- FirstOfAuthorList(r$parsed_author1)
      twin <- if (is.na(r$bibcite)) MatchingNoDOIEntry(r, all_prim) else NULL
      key <- if (!is.na(r$bibcite)) r$bibcite else if (!is.null(twin)) twin$bibcite else BibKeyFor(surname, r$parsed_year, NA, known_keys)
      if (!key %in% curated$key && !key %in% names(entries)) {
        own <- if (!is.null(twin)) twin else r
        entries[key] <- BuildBibEntryNoDOI(own, key, own$decided_by, own$decided_at)
      }
      known_keys <- union(known_keys, key)
      all_prim$bibcite[i] <- key
      all_prim$cite_id[i] <- KeepOrMintCiteID(r, key, surname, r$parsed_year, known_ids, row_ids)
      row_ids[key] <- all_prim$cite_id[i]
    } else if (r$match_reason %in% 'manual_bib') {
      if (!r$bibcite %in% curated$key) stop('manual bibcite ', r$bibcite, ' (', r$source_label, ' ', r$native_key, ') is not in ', basename(cfg$curated_bib), call. = FALSE)
      all_prim$cite_id[i] <- CiteIDFor(sub(':.*$', '', r$bibcite), sub('^.*:(\\d{4}).*$', '\\1', r$bibcite), NA, r$bibcite, known_ids)
    }
    Remember(i)
  }
  list(prim = all_prim, entries = entries, authorless = authorless, no_record = no_record)
}

# The CiteID of a row that keeps its key is the one it has (#114 item 7: a
# stale Sheet row for the same Bibcite once flipped Wilman's Dunning08 id);
# a row that takes a key another row already carries with a CiteID takes
# that id (`row_ids`, key -> CiteID over the accepted rows); otherwise
# CiteIDFor() reuses the id of the key or DOI in the table, or mints.
KeepOrMintCiteID <- function(r, key, surname, year, known_ids, row_ids = character()) {
  if (!is.na(r$cite_id) && !is.na(r$bibcite) && identical(r$bibcite, key)) return(r$cite_id)
  if (key %in% names(row_ids)) return(unname(row_ids[key]))
  CiteIDFor(surname, year, r$doi, key, known_ids)
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
  if (length(entries) > 0) entries <- entries[order(names(entries), method = 'radix')]
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
