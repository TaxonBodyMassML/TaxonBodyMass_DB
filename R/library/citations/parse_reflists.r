# Citation tooling (issue #1): reading a source's reference list and building
# the skeleton of sources/databases/<Src>/primary_references.csv.
#
#   SplitRefKeys(x, sep)        records' reference column -> '; '-joined native keys
#   JoinRefKeys(ref_keys)       the distinct keys of several records (Pass 1 of RunMe.r)
#   ParseRefListCSV(...)        a key/citation CSV (Kiorboe_2013, McCoy_2008, Hebert_etal_2016, ...)
#   ParseInRowCitations(...)    full-text citations carried by every record (Herberstein_etal_2022, ...)
#   ExpandSameAuthorMarkers()   the '---' / em-dash "same author as above" convention
#   InitPrimaryReferences()     the skeleton: one row per native key used in the data,
#                               raw_citation verbatim, parsed_* from ParseCitationString(),
#                               role 'self' for the compiler's own unpublished data
#   MergePrimaryReferences()    re-running --init keeps the owner's edits and the
#                               verification columns of existing rows
#   ReadPrimaryReferences() / WritePrimaryReferences()
# The parsers for the other formats of issue #1 (xlsx, bib, docx, pdf, html,
# EndNote .doc) stop with a clear message until their tier is reached.
# Everything is offline.

# ---- native keys in the records ----------------------------------------------------
# The reference column of a parse script, split at the per-source separator
# (`sep`, a regular expression; ';' or ',' for most sources), trimmed, empty
# and NA-like tokens dropped, de-duplicated within a record and joined with
# '; ' (the convention of McCoy_2008 and Ikeda_2014). NA where a record cites
# nothing.
SplitRefKeys <- function(x, sep = ';') {
  x <- as.character(x)
  out <- vapply(x, function(s) {
    if (is.na(s)) return(NA_character_)
    toks <- trimws(strsplit(s, sep, perl = TRUE)[[1]])
    toks <- toks[nzchar(toks) & !toupper(toks) %in% c('NA', 'N/A', '-', '--', '?')]
    if (length(toks) == 0) NA_character_ else paste(unique(toks), collapse = '; ')
  }, character(1), USE.NAMES = FALSE)
  out
}

# The distinct keys of several records' ref_keys as one '; '-joined string (the
# Pass-1 summarise of RunMe.r); NA when no record carries a key.
JoinRefKeys <- function(ref_keys) {
  k <- unique(trimws(unlist(strsplit(as.character(ref_keys[!is.na(ref_keys)]), ';', fixed = TRUE))))
  k <- k[nzchar(k)]
  if (length(k) == 0) NA_character_ else paste(k, collapse = '; ')
}

# The keys of a '; '-joined ref_keys vector, one row per record x key; a record
# whose ref_keys is NA contributes no row (`record` indexes the input vector).
ExplodeRefKeys <- function(ref_keys) {
  ref_keys <- as.character(ref_keys)
  keys <- strsplit(ref_keys, ';', fixed = TRUE)
  keys[is.na(ref_keys)] <- list(character(0))
  out <- data.frame(record = rep(seq_along(ref_keys), lengths(keys)),
                    native_key = trimws(unlist(keys)), stringsAsFactors = FALSE)
  out[nzchar(out$native_key), , drop = FALSE]
}

# ---- reference-list formats --------------------------------------------------------
# A CSV with one reference per row: `key_col` holds the native key as it appears
# in the data, `citation_col` the citation text (or `citation_cols`, several
# columns pasted with '. ' after trimming each field's trailing period, when
# the list is split into author/year/title/journal fields, as Hebert_etal_2016's
# references.csv), `doi_col` an optional DOI column and `type_col` an optional
# publication type kept in `notes`. `file_encoding` names the file's encoding
# when it is not UTF-8 (Hebert's list is latin1).
# Returns native_key, raw_citation, raw_doi, note (all character).
ParseRefListCSV <- function(path, key_col, citation_col = NULL, doi_col = NULL,
                            citation_cols = NULL, type_col = NULL, csv_sep = ',',
                            file_encoding = 'UTF-8') {
  if (!file.exists(path)) stop('reference list not found: ', path, call. = FALSE)
  d <- read.table(path, header = TRUE, sep = csv_sep, quote = '"', stringsAsFactors = FALSE,
                  check.names = FALSE, colClasses = 'character', na.strings = c('', 'NA'),
                  encoding = 'UTF-8', fileEncoding = file_encoding, comment.char = '', fill = TRUE,
                  strip.white = TRUE)
  for (col in names(d)) d[[col]] <- enc2utf8(d[[col]])
  need <- c(key_col, citation_col, doi_col, citation_cols, type_col)
  miss <- setdiff(need, names(d))
  if (length(miss) > 0)
    stop(basename(path), ' lacks column(s) ', paste(miss, collapse = ', '), call. = FALSE)
  if (is.null(citation_col) && is.null(citation_cols))
    stop('ParseRefListCSV(): give citation_col or citation_cols', call. = FALSE)
  cit <- if (!is.null(citation_col)) d[[citation_col]] else
    apply(d[, citation_cols, drop = FALSE], 1, function(r) {
      r <- trimws(r[!is.na(r) & nzchar(trimws(r))]); r <- sub('[.]$', '', r)
      if (length(r) == 0) NA_character_ else paste0(paste(r, collapse = '. '), '.')
    })
  out <- data.frame(native_key   = trimws(d[[key_col]]),
                    raw_citation = trimws(enc2utf8(cit)),
                    raw_doi      = if (is.null(doi_col)) NA_character_ else CleanDOI(d[[doi_col]]),
                    note         = if (is.null(type_col)) NA_character_ else trimws(d[[type_col]]),
                    stringsAsFactors = FALSE)
  out <- out[!is.na(out$native_key) & nzchar(out$native_key), ]
  dup <- duplicated(out$native_key)
  if (any(dup))
    stop(basename(path), ': duplicated native key(s) ', paste(unique(out$native_key[dup]), collapse = ', '),
         call. = FALSE)
  rownames(out) <- NULL
  out
}

# The '---' / em-dash convention of printed reference lists ("———, and B. Bruce.
# 1986." means the authors of the previous entry up to the first one): the
# marker is replaced by the previous entry's author block, so that the parse
# finds the surname. Applied to the parsing copy only; raw_citation keeps the
# dashes. A marker in the first entry is left as it is.
ExpandSameAuthorMarkers <- function(citations) {
  citations <- as.character(citations)
  marker <- '^\\s*([\u2014\u2015\u2013\\-_]{2,}|\u2014)\\s*'
  prev_block <- NA_character_
  out <- citations
  for (i in seq_along(citations)) {
    s <- citations[i]
    if (is.na(s)) next
    if (grepl(marker, s, perl = TRUE) && !is.na(prev_block)) {
      rest <- sub(marker, '', s, perl = TRUE)
      first_author <- sub(',\\s*(and|&)\\s.*$', '', prev_block)           # 'Ikeda, T., and B. Bruce' -> 'Ikeda, T.'
      first_author <- sub('\\s*,\\s*[A-Z]\\.\\s*[A-Z]\\.?\\s*[A-Z][a-z]+.*$', '', first_author) # 'Omori, M., T. Ikeda' -> 'Omori, M.'
      if (grepl('\\b[A-Z]$', first_author)) first_author <- paste0(first_author, '.')   # the initial's period AuthorBlock() trimmed
      sep <- if (grepl('^[,.]', rest)) '' else ' '
      out[i] <- paste0(first_author, sep, rest)
    }
    blk <- AuthorBlock(out[i])
    if (!is.na(blk)) prev_block <- blk
  }
  out
}

# Full-text citations carried by every record (Herberstein, Faurby, Pekar, ...):
# the distinct strings become references keyed by 'h:<sha1-8>' of the normalised
# string; `dois` (optional, same length) supplies raw_doi, else a DOI embedded in
# the text is used. Returns native_key, raw_citation, raw_doi, n_records and the
# per-record key vector (`keys`) for the parse script.
ParseInRowCitations <- function(citations, dois = NULL) {
  citations <- trimws(as.character(citations))
  citations[!is.na(citations) & !nzchar(citations)] <- NA_character_
  keys <- CitationHashKey(citations)
  if (is.null(dois)) dois <- ExtractDOI(citations) else dois <- CleanDOI(dois)
  dois[is.na(dois)] <- ExtractDOI(citations)[is.na(dois)]
  ok <- !is.na(keys)
  tab <- table(keys[ok])
  first <- !duplicated(keys) & ok
  refs <- data.frame(native_key = keys[first], raw_citation = citations[first],
                     raw_doi = dois[first], n_records = as.integer(tab[keys[first]]),
                     stringsAsFactors = FALSE)
  refs <- refs[order(refs$native_key, method = 'radix'), ]
  rownames(refs) <- NULL
  list(references = refs, keys = keys)
}

NotYet <- function(fmt, tier)
  function(...) stop('ParseRefList', fmt, '() is not implemented yet: the ', tier,
                     ' sources of issue #1 that need it have not been reached (see citations_config.r reflist_specs)',
                     call. = FALSE)
ParseRefListXLSX       <- NotYet('XLSX', 'tier A1/A2')
ParseRefListBib        <- NotYet('Bib', 'tier A2 (Fisher_2001)')
ParseRefListDocx       <- NotYet('Docx', 'tier A2/C (Brocher, Galan-Acedo)')
ParseRefListPDF        <- NotYet('PDF', 'tier A2/C')
ParseRefListHTML       <- NotYet('HTML', 'tier A2 (Barnes, Lislevand, AnAge)')
ParseRefListEndNoteDoc <- NotYet('EndNoteDoc', 'tier A2 (Chown_etal_2007)')

# ---- the skeleton -----------------------------------------------------------------
# The compiler's own measurements and unpublished data ('this study', 'present
# study', 'unpublished data', 'own data', 'pers. obs.'), or an entry naming the
# compiler as the source of unpublished data, are role 'self' and are never
# sent to a service (issue #1, 2.3).
DetectSelf <- function(raw_citation, compiler = NA_character_) {
  s <- tolower(FoldASCII(raw_citation))
  self_pat <- '\\b(this study|present study|this paper|own (unpublished )?data|our (unpublished )?data|pers(onal)?\\.? obs)'
  is_self <- !is.na(s) & grepl(self_pat, s, perl = TRUE)
  unpub <- !is.na(s) & grepl('\\bunpubl', s, perl = TRUE)
  if (!is.na(compiler) && nzchar(compiler)) {
    comp <- tolower(FoldASCII(compiler))
    is_self <- is_self | (unpub & grepl(comp, s, fixed = TRUE))
  }
  is_self
}

EmptyPrimaryReferences <- function() {
  out <- as.data.frame(setNames(rep(list(character()), length(primary_reference_columns)),
                                primary_reference_columns), stringsAsFactors = FALSE)
  out$n_records <- integer(); out$parsed_year <- integer(); out$title_sim <- numeric()
  for (col in c('author_match', 'year_match', 'container_match', 'volume_match', 'pages_match', 'is_retracted'))
    out[[col]] <- logical()
  out
}

# One row per native key cited by the records of `source_label` (`ref_keys`:
# the records' '; '-joined keys, NA for none), joined to the reference list
# (`reflist`: native_key, raw_citation, raw_doi[, note]). Keys the list does not
# resolve get an empty raw_citation and the note 'key not in reference list';
# entries of the list no record cites are not included (reported by the CLI).
InitPrimaryReferences <- function(source_label, reflist, ref_keys, compiler = NA_character_,
                                  expand_same_author = TRUE) {
  stopifnot(is.data.frame(reflist), all(c('native_key', 'raw_citation') %in% names(reflist)))
  if (!'raw_doi' %in% names(reflist)) reflist$raw_doi <- NA_character_
  if (!'note' %in% names(reflist)) reflist$note <- NA_character_
  ex <- ExplodeRefKeys(ref_keys[!is.na(ref_keys)])
  counts <- table(ex$native_key)
  keys <- as.character(names(counts))
  # keep the reference list's order for keys it holds, then the unmatched keys
  in_list <- keys[keys %in% reflist$native_key]
  in_list <- reflist$native_key[reflist$native_key %in% in_list]
  keys <- c(in_list, sort(setdiff(keys, in_list), method = 'radix'))
  out <- EmptyPrimaryReferences()[rep(1L, 0), ]
  if (length(keys) == 0) return(out)
  idx <- match(keys, reflist$native_key)
  out <- EmptyPrimaryReferences()
  out[seq_along(keys), 'native_key'] <- keys
  out$source_label  <- source_label
  out$raw_citation  <- reflist$raw_citation[idx]
  out$raw_doi       <- CleanDOI(reflist$raw_doi[idx])
  out$n_records     <- as.integer(counts[keys])
  out$notes         <- reflist$note[idx]
  out$notes[is.na(idx)] <- 'key not in reference list'
  out$match_reason[is.na(idx)] <- 'key_not_in_reflist'
  # the same-author markers refer to the previous entry of the list, so the
  # expansion runs over the whole list in its order, then the rows are picked
  parse_all  <- if (expand_same_author) ExpandSameAuthorMarkers(reflist$raw_citation) else reflist$raw_citation
  parse_text <- ifelse(is.na(idx), out$raw_citation, parse_all[idx])
  p <- ParseCitationString(parse_text)
  for (col in c('parsed_author1', 'parsed_year', 'parsed_title', 'parsed_container', 'parsed_volume', 'parsed_pages'))
    out[[col]] <- p[[col]]
  out$raw_doi[is.na(out$raw_doi)] <- p$parsed_doi[is.na(out$raw_doi)]
  self <- DetectSelf(out$raw_citation, compiler)
  out$role <- ifelse(self, 'self', 'measurement')
  out$match_status[self] <- 'self'
  out$match_reason[self] <- 'self'
  out$tool_version <- citations_tool_version
  rownames(out) <- NULL
  out
}

# Re-running --init: the rows of the existing file keep every column but
# n_records and raw_doi (the owner's role/parsed_*/notes edits and the tool's
# verification columns survive); new keys are appended; keys no record cites
# any more stay with n_records 0. raw_citation is never rewritten: a changed
# reference list is reported, not applied (issue #1, F6).
MergePrimaryReferences <- function(existing, skeleton) {
  if (is.null(existing) || nrow(existing) == 0) return(skeleton)
  stopifnot(identical(names(existing), names(skeleton)))
  key_e <- existing$native_key; key_s <- skeleton$native_key
  changed <- key_s %in% key_e &
    !is.na(skeleton$raw_citation) &
    !is.na(existing$raw_citation[match(key_s, key_e)]) &
    skeleton$raw_citation != existing$raw_citation[match(key_s, key_e)]
  if (any(changed))
    warning('raw_citation differs between the reference list and primary_references.csv for key(s) ',
            paste(key_s[changed], collapse = ', '), '; the file keeps its text (raw_citation is immutable)',
            call. = FALSE, immediate. = TRUE)
  existing$n_records <- 0L
  i <- match(key_e, key_s)
  existing$n_records[!is.na(i)] <- skeleton$n_records[i[!is.na(i)]]
  fill_doi <- !is.na(i) & is.na(existing$raw_doi)
  existing$raw_doi[fill_doi] <- skeleton$raw_doi[i[fill_doi]]
  new <- skeleton[!key_s %in% key_e, , drop = FALSE]
  out <- rbind(existing, new)
  rownames(out) <- NULL
  out
}

PrimaryReferencesPath <- function(wd_db, source_label) file.path(wd_db, source_label, 'primary_references.csv')

ReadPrimaryReferences <- function(path) {
  if (!file.exists(path)) return(NULL)
  d <- read.csv(path, stringsAsFactors = FALSE, colClasses = 'character', na.strings = c('', 'NA'),
                check.names = FALSE, encoding = 'UTF-8', fileEncoding = 'UTF-8')
  miss <- setdiff(primary_reference_columns, names(d))
  if (length(miss) > 0)
    stop(path, ' lacks column(s) ', paste(miss, collapse = ', '), call. = FALSE)
  d <- d[, primary_reference_columns]
  d$n_records   <- as.integer(d$n_records)
  d$parsed_year <- as.integer(d$parsed_year)
  d$title_sim   <- as.numeric(d$title_sim)
  for (col in c('author_match', 'year_match', 'container_match', 'volume_match', 'pages_match', 'is_retracted'))
    d[[col]] <- as.logical(d[[col]])
  d
}

WritePrimaryReferences <- function(d, path) {
  d <- d[, primary_reference_columns]
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  write.csv(d, path, row.names = FALSE, na = '', fileEncoding = 'UTF-8')
  invisible(d)
}
