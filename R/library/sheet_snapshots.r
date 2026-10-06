# The lab Google Sheet and its tracked copies (issue #118).
#
# RunMe.r reads three tabs of the lab Sheet: BM_data (the curated mass
# overrides, section 4), BM_citations and BM_primary_citations (the citation
# maps, section 8). Each tab has ONE tracked CSV copy, written by the same
# function whichever tool refreshes it (RunMe.r with DataSheets = TRUE, or
# run_citations.r --sheet for the two citation tabs):
#
#   sources/BM_data_snapshot.csv             paths$snapshot_data
#   Bib/BM_citations_snapshot.csv            paths$snapshot_citations
#   Bib/BM_primary_citations_snapshot.csv    paths$snapshot_primary
#
# The pipeline always reads the copies (LoadSheetSnapshot()). With
# DataSheets = TRUE it first downloads the tabs and rewrites the copies
# (RefreshSheetSnapshots()), printing the difference against the committed
# files; with DataSheets = FALSE it checks that the copies exist
# (CheckSheetSnapshots()) and reports their age (ReportSheetSnapshots()). So
# the two modes take one read path and write byte-identical outputs by
# construction, and a fresh clone runs without a Google token.
#
#   SheetAuth()                          the cached gargle token, no browser prompt
#   ReadSheetTab(url, tab, col_types)    one tab as a data frame (character by default)
#   SnapshotSheetTab(df, path)           a tab to its CSV copy: the Sheet's row and column
#                                        order, every column as character (a double as the
#                                        shortest decimal that reads back exactly), NA as ''
#   LoadSheetSnapshot(path)              a copy back as an all-character frame (NA for '')
#   CheckSheetSnapshots(paths)           stop with every missing copy named
#   ReportSheetSnapshots(paths, wd_root) one line: rows and last commit date of each copy
#   CompareSheetFrames(old, new, key)    rows added / removed / changed between two reads
#   RefreshSheetSnapshots(url, paths)    download the three tabs, print the comparison,
#                                        rewrite the copies
#
# Everything but SheetAuth() and ReadSheetTab() is offline; the two network
# functions are called only from RefreshSheetSnapshots() and the citation
# tooling (sheet_append.r), never from the DataSheets = FALSE path. The tab
# names, the column types of BM_data and the paths are in citations_config.r
# (sheet_tab_*, sheet_data_col_types, CitationsPaths()).

SheetAuth <- function() {
  options(gargle_oauth_email = TRUE)        # the cached token, no browser prompt
  if (!googlesheets4::gs4_has_token()) googlesheets4::gs4_auth()
  invisible(TRUE)
}

# `col_types` as read_sheet() takes it: 'c' (every column character) for the
# citation tabs; sheet_data_col_types for BM_data, whose mass column is read
# as the cell's number (the character read would give the formatted text, ten
# significant digits or the displayed decimals, not the value).
ReadSheetTab <- function(url, tab, col_types = 'c') {
  SheetAuth()
  d <- googlesheets4::read_sheet(url, sheet = tab, col_types = col_types)
  as.data.frame(d, stringsAsFactors = FALSE)
}

# ---- the copies -----------------------------------------------------------------------

# The three tabs, their copies, their read types and the columns that
# identify a row in the comparison report.
SheetSnapshotTabs <- function(paths) list(
  list(tab = sheet_tab_data,      path = paths$snapshot_data,      col_types = sheet_data_col_types, key = c('taxon', 'source_mass')),
  list(tab = sheet_tab_citations, path = paths$snapshot_citations, col_types = 'c',                  key = 'CiteID'),
  list(tab = sheet_tab_primary,   path = paths$snapshot_primary,   col_types = 'c',                  key = 'CiteID'))

# A double as the shortest string that as.numeric() reads back as the same
# double, so that the copy holds the Sheet's values exactly and a copy
# re-read and re-written is byte-identical: 15 significant digits for every
# hand-typed value ('5.8', '3000000', '1.74e-05'), 16 or 17 for most values
# the Sheet computed by formula (39.185428331549502; as.character() would
# round them). as.numeric() is not correctly rounded for 17-digit strings on
# every platform (R's own strtod; it is one ulp off for a few per cent of
# such strings on arm64), so the values no decimal string reaches are
# written as C99 hexadecimal floats ('0x1.52669c0e2a4bp+13'), which
# as.numeric() reads exactly everywhere (about 3 % of the BM_data masses at
# the 2026-10-05 run, all formula results). NA -> NA.
FormatSheetNumber <- function(x) {
  out <- rep(NA_character_, length(x))
  todo <- !is.na(x)
  for (digits in 15:17) {
    if (!any(todo)) break
    s <- sprintf('%.*g', digits, x[todo])
    ok <- as.numeric(s) == x[todo]
    out[which(todo)[ok]] <- s[ok]
    todo[which(todo)[ok]] <- FALSE
  }
  if (any(todo)) out[todo] <- sprintf('%a', x[todo])
  out
}

# A text cell as it comes back from the copy: a line break inside a cell (a
# pasted Citation) as LF. The Sheet holds CRLF in such a cell, which
# write.csv() keeps and read.csv() reads back as LF, so the copy would not be
# a fixpoint of write-then-read without this; the comparison uses it too.
NormaliseSheetText <- function(x) {
  x <- as.character(x)
  has <- !is.na(x) & grepl('\r', x, fixed = TRUE)
  if (any(has)) x[has] <- gsub('\r\n?', '\n', x[has], perl = TRUE)
  x
}

SnapshotSheetTab <- function(df, path) {
  df <- as.data.frame(df, stringsAsFactors = FALSE)
  for (col in names(df)) {
    v <- df[[col]]
    df[[col]] <- if (is.double(v)) FormatSheetNumber(v) else NormaliseSheetText(v)
  }
  write.csv(df, path, row.names = FALSE, na = '', fileEncoding = 'UTF-8')
  invisible(path)
}

MissingSheetSnapshotMessage <- function(paths) {
  paste0('Set DataSheets = TRUE (at least once) at the top of R/RunMe.r to download the Google Sheet tabs; ',
         'the local copies are missing: ', paste(paths, collapse = ', '))
}

# Every column character, an empty cell NA (as read_sheet() gives it; a cell
# that says NA is the string "NA"), the Sheet's column names untouched.
LoadSheetSnapshot <- function(path) {
  if (!file.exists(path)) stop(MissingSheetSnapshotMessage(path), call. = FALSE)
  read.csv(path, colClasses = 'character', na.strings = '', check.names = FALSE,
           encoding = 'UTF-8', stringsAsFactors = FALSE)
}

CheckSheetSnapshots <- function(paths) {
  files <- vapply(SheetSnapshotTabs(paths), `[[`, character(1), 'path')
  missing <- files[!file.exists(files)]
  if (length(missing) > 0) stop(MissingSheetSnapshotMessage(missing), call. = FALSE)
  invisible(files)
}

# When the copy was last committed (git keeps no mtimes, so the file's own
# date says nothing after a checkout); the mtime, flagged, when git is not
# available or the file is not committed. `git -C` works in worktrees as it
# does in the main checkout.
SheetSnapshotAge <- function(path, wd_root) {
  committed <- tryCatch(
    system2('git', c('-C', shQuote(wd_root), 'log', '-1', '--format=%cs', '--', shQuote(path)), stdout = TRUE, stderr = FALSE),
    error = function(e) character(0), warning = function(w) character(0))
  committed <- trimws(committed[nzchar(trimws(committed))])
  if (length(committed) >= 1 && grepl('^\\d{4}-\\d{2}-\\d{2}$', committed[1])) return(paste('committed', committed[1]))
  paste('modified', format(file.mtime(path), '%Y-%m-%d'), 'uncommitted')
}

ReportSheetSnapshots <- function(paths, wd_root, flag = 'DataSheets = FALSE') {
  parts <- vapply(SheetSnapshotTabs(paths), function(t) {
    sprintf('%s %s rows (%s)', t$tab, format(nrow(LoadSheetSnapshot(t$path)), big.mark = ','), SheetSnapshotAge(t$path, wd_root))
  }, character(1))
  message(sprintf('Lab Sheet copies (%s): %s', flag, paste(parts, collapse = ', ')))
  invisible(parts)
}

# ---- the refresh ----------------------------------------------------------------------

# Rows of `new` not in `old` and the reverse, by row content (every column, NA
# as ''). A row that is in neither but whose key (`key` columns) is in both is
# counted once as changed rather than as one added and one removed. Duplicate
# rows are matched one to one. `old = NULL`: no copy yet, everything is added.
CompareSheetFrames <- function(old, new, key = character(0)) {
  Cell <- function(x) ifelse(is.na(x), '', if (is.double(x)) FormatSheetNumber(x) else NormaliseSheetText(x))
  Rows <- function(d, cols) if (nrow(d) == 0) character(0) else do.call(paste, c(lapply(d[cols], Cell), sep = '\x1f'))
  Tag  <- function(s) if (length(s) == 0) s else paste(s, ave(seq_along(s), s, FUN = seq_along), sep = '\x1e')
  if (is.null(old)) return(list(n_new = nrow(new), n_old = NA_integer_, added = nrow(new), removed = 0L, changed = 0L, columns_differ = FALSE))
  columns_differ <- !identical(names(old), names(new))
  cols <- intersect(names(old), names(new))
  so <- Tag(Rows(old, cols)); sn <- Tag(Rows(new, cols))
  rest_old <- old[!so %in% sn, cols, drop = FALSE]
  rest_new <- new[!sn %in% so, cols, drop = FALSE]
  key <- intersect(key, cols)
  changed <- 0L
  if (length(key) > 0 && nrow(rest_old) > 0 && nrow(rest_new) > 0) {
    ko <- Tag(Rows(rest_old, key)); kn <- Tag(Rows(rest_new, key))
    changed <- sum(kn %in% ko)
  }
  list(n_new = nrow(new), n_old = nrow(old), added = nrow(rest_new) - changed, removed = nrow(rest_old) - changed,
       changed = changed, columns_differ = columns_differ)
}

FormatSheetComparison <- function(tab, cmp) {
  n <- function(x) format(x, big.mark = ',')
  if (is.na(cmp$n_old)) return(sprintf('%s: %s rows read (no copy yet)', tab, n(cmp$n_new)))
  sprintf('%s: %s rows read (copy had %s: %s added, %s removed, %s changed%s)', tab, n(cmp$n_new), n(cmp$n_old),
          n(cmp$added), n(cmp$removed), n(cmp$changed), if (cmp$columns_differ) '; the columns differ' else '')
}

# Download the three tabs through `io$read(url, tab, col_types)` (googlesheets4
# by default; the tests pass a fake), print each tab's comparison with its
# committed copy, and rewrite the copies. The pipeline then reads the copies,
# as it does with DataSheets = FALSE. Returns the comparisons invisibly. A
# missing tab stops here, before any computation.
RefreshSheetSnapshots <- function(url, paths, io = list(read = ReadSheetTab)) {
  out <- list()
  for (t in SheetSnapshotTabs(paths)) {
    new <- io$read(url, t$tab, col_types = t$col_types)
    old <- if (file.exists(t$path)) LoadSheetSnapshot(t$path) else NULL
    cmp <- CompareSheetFrames(old, new, t$key)
    message('  ', FormatSheetComparison(t$tab, cmp), ' -> ', t$path)
    dir.create(dirname(t$path), showWarnings = FALSE, recursive = TRUE)
    SnapshotSheetTab(new, t$path)
    out[[t$tab]] <- cmp
  }
  invisible(out)
}
