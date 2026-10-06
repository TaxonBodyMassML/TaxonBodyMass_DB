# Tests for the tracked copies of the lab Google Sheet tabs (issue #118):
# R/library/sheet_snapshots.r and the DataSheets wiring of R/RunMe.r. The
# three committed copies load with the columns sections 4 and 8 need; a
# refresh through a fake reader that returns the committed copies (as
# ReadSheetTab() would return the tabs) rewrites them byte for byte, so the
# DataSheets = TRUE path hands the pipeline exactly what the FALSE path reads;
# the number formatting round-trips every double; a missing copy stops with
# the flag named; the comparison report counts added, removed and changed rows;
# and RunMe.r authenticates and downloads only inside `if (DataSheets)`. No
# network access, no googlesheets4 and no packages beyond base R are needed.
#
#   Rscript R/library/tests/test_sheet_snapshots.R      (from any directory)
#
# Prints one line per expectation and exits with status 1 if any failed.

this_file <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE))
if (length(this_file) == 0)
  this_file <- file.path('R', 'library', 'tests', 'test_sheet_snapshots.R')
repo <- normalizePath(file.path(dirname(this_file), '..', '..', '..'))
lib  <- file.path(repo, 'R', 'library')
source(file.path(lib, 'citations', 'citations_config.r'))
source(file.path(lib, 'sheet_snapshots.r'))

failures <- character(0)
n_checks <- 0L
Expect <- function(ok, what) {
  n_checks <<- n_checks + 1L
  if (!isTRUE(ok)) failures <<- c(failures, what)
  cat(sprintf('  %s %s\n', if (isTRUE(ok)) 'ok  ' else 'FAIL', what))
}
ErrorOf <- function(expr) tryCatch({ expr; NULL }, error = function(e) conditionMessage(e))
Has <- function(x, pattern) !is.null(x) && !is.na(x) && grepl(pattern, x, fixed = TRUE)
Bytes <- function(path) readBin(path, 'raw', n = file.size(path))

paths <- CitationsPaths(repo)
tabs  <- SheetSnapshotTabs(paths)

# ---- (a) the committed copies ----------------------------------------------------------
cat('LoadSheetSnapshot() on the committed copies\n')
Expect(identical(vapply(tabs, `[[`, character(1), 'tab'), c('BM_data', 'BM_citations', 'BM_primary_citations')) &&
         identical(basename(vapply(tabs, `[[`, character(1), 'path')), c('BM_data_snapshot.csv', 'BM_citations_snapshot.csv', 'BM_primary_citations_snapshot.csv')) &&
         dirname(paths$snapshot_data) == file.path(repo, 'sources') && dirname(paths$snapshot_citations) == file.path(repo, 'Bib'),
       'one copy per tab: BM_data in sources/, the two citation tabs in Bib/')
Expect(all(file.exists(vapply(tabs, `[[`, character(1), 'path'))), 'the three copies are tracked in the repository')
bm <- LoadSheetSnapshot(paths$snapshot_data)
Expect(identical(names(bm)[2:4], c('taxon', 'mass_g', 'source_mass')) && ncol(bm) == nchar(sheet_data_col_types) &&
         all(vapply(bm, is.character, logical(1))) && nrow(bm) > 1000,
       'BM_data: taxon, mass_g, source_mass in columns 2-4 of seven, every column character, every row of the tab (with or without a mass)')
mass <- suppressWarnings(as.numeric(bm$mass_g))
Expect(identical(is.na(mass), is.na(bm$mass_g)) && all(is.finite(mass[!is.na(mass)])) && all(mass[!is.na(mass)] > 0) && sum(!is.na(mass)) > 900,
       'as.numeric(mass_g) is a finite positive number for every row with a mass and NA only for the empty cells')
gm <- LoadSheetSnapshot(paths$snapshot_citations)
pm <- LoadSheetSnapshot(paths$snapshot_primary)
Expect(identical(names(gm)[1:2], c('CiteID', 'Bibcite')) && nrow(gm) > 400 && all(grepl('^\\\\citep?\\{', gm$Bibcite[!is.na(gm$Bibcite)])),
       'BM_citations: CiteID and Bibcite first (what section 8 keeps), the Bibcite cells as typed in the Sheet (\\citep{...}, two \\cite{...})')
Expect(identical(names(pm), sheet_primary_columns) && nrow(pm) > 2000 && all(vapply(pm, is.character, logical(1))),
       'BM_primary_citations: the seven sheet_primary_columns, all character')

# ---- (b) the TRUE path reproduces the FALSE path --------------------------------------------
cat('RefreshSheetSnapshots() through a fake reader\n')
# the tabs as ReadSheetTab() returns them: the committed copies, BM_data's
# numeric columns (col_types 'ccncnnn') as numbers
AsRead <- function(t) {
  d <- LoadSheetSnapshot(t$path)
  if (t$col_types != 'c') for (i in which(strsplit(t$col_types, '')[[1]] == 'n')) d[[i]] <- as.numeric(d[[i]])
  d
}
fake_tabs <- setNames(lapply(tabs, AsRead), vapply(tabs, `[[`, character(1), 'tab'))
log <- character(0)
fake_io <- list(read = function(url, tab, col_types = 'c') { log <<- c(log, paste(tab, col_types)); fake_tabs[[tab]] })
tmp <- tempfile('sheets_'); dir.create(file.path(tmp, 'sources'), recursive = TRUE); dir.create(file.path(tmp, 'Bib'))
tpaths <- list(snapshot_data = file.path(tmp, 'sources', 'BM_data_snapshot.csv'),
               snapshot_citations = file.path(tmp, 'Bib', 'BM_citations_snapshot.csv'),
               snapshot_primary = file.path(tmp, 'Bib', 'BM_primary_citations_snapshot.csv'))
invisible(file.copy(unlist(paths[names(tpaths)]), unlist(tpaths)))
msgs <- character(0)
cmp <- withCallingHandlers(RefreshSheetSnapshots('url', tpaths, io = fake_io),
                           message = function(m) { msgs <<- c(msgs, conditionMessage(m)); invokeRestart('muffleMessage') })
Expect(identical(log, c('BM_data ccncnnn', 'BM_citations c', 'BM_primary_citations c')),
       'the three tabs are read once each, BM_data with its numeric column types')
Expect(identical(Bytes(tpaths$snapshot_data), Bytes(paths$snapshot_data)) &&
         identical(Bytes(tpaths$snapshot_citations), Bytes(paths$snapshot_citations)) &&
         identical(Bytes(tpaths$snapshot_primary), Bytes(paths$snapshot_primary)),
       'the copies written from the tabs are byte-identical to the committed copies')
Expect(identical(LoadSheetSnapshot(tpaths$snapshot_data), bm) && identical(LoadSheetSnapshot(tpaths$snapshot_citations), gm) &&
         identical(LoadSheetSnapshot(tpaths$snapshot_primary), pm),
       'read back, they are identical() to the committed copies: the TRUE path hands the pipeline what the FALSE path reads')
Expect(all(vapply(cmp, function(x) x$added == 0 && x$removed == 0 && x$changed == 0 && !x$columns_differ, logical(1))) &&
         cmp$BM_data$n_new == nrow(bm) && cmp$BM_data$n_old == nrow(bm) &&
         any(grepl('^BM_data: [0-9,]+ rows read \\(copy had [0-9,]+: 0 added, 0 removed, 0 changed\\) -> ', trimws(msgs))),
       'an unchanged Sheet reports 0 added, 0 removed, 0 changed for every tab')
unlink(tpaths$snapshot_data)
msgs <- character(0)
cmp <- withCallingHandlers(RefreshSheetSnapshots('url', tpaths, io = fake_io),
                           message = function(m) { msgs <<- c(msgs, conditionMessage(m)); invokeRestart('muffleMessage') })
Expect(is.na(cmp$BM_data$n_old) && cmp$BM_data$added == nrow(bm) && any(grepl('^BM_data: [0-9,]+ rows read \\(no copy yet\\)', trimws(msgs))) &&
         identical(Bytes(tpaths$snapshot_data), Bytes(paths$snapshot_data)),
       'a first refresh (no copy yet) writes the copy and says so')

# ---- (c) a missing copy stops ---------------------------------------------------------------
cat('CheckSheetSnapshots() and LoadSheetSnapshot() on a missing copy\n')
e <- ErrorOf(LoadSheetSnapshot(file.path(tmp, 'nowhere.csv')))
Expect(Has(e, 'Set DataSheets = TRUE (at least once)') && Has(e, 'the local copies are missing: ') && Has(e, file.path(tmp, 'nowhere.csv')),
       'a missing copy stops with the flag to set and the file named')
unlink(c(tpaths$snapshot_data, tpaths$snapshot_primary))
e <- ErrorOf(CheckSheetSnapshots(tpaths))
Expect(Has(e, 'Set DataSheets = TRUE') && Has(e, tpaths$snapshot_data) && Has(e, tpaths$snapshot_primary) && !Has(e, tpaths$snapshot_citations),
       'the upfront check names every missing copy in one message and not the present one')
Expect(identical(unname(CheckSheetSnapshots(paths)), unname(unlist(paths[c('snapshot_data', 'snapshot_citations', 'snapshot_primary')]))),
       'with the three copies present the check passes and returns their paths')

# ---- (d) the comparison report --------------------------------------------------------------
cat('CompareSheetFrames()\n')
old <- data.frame(taxon = c('A', 'B', 'C', 'C'), source_mass = 's', mass_g = c('1', '2', '3', '3'), stringsAsFactors = FALSE)
new <- data.frame(taxon = c('A', 'C', 'C', 'D', 'E'), source_mass = 's', mass_g = c(1, 3, 4, 5, 6), stringsAsFactors = FALSE)
r <- CompareSheetFrames(old, new, c('taxon', 'source_mass'))
Expect(r$n_old == 4 && r$n_new == 5 && r$added == 2 && r$removed == 1 && r$changed == 1 && !r$columns_differ,
       'rows matched by content (a numeric read against a character copy), duplicates one to one; a key in both sides with another content is one changed row')
Expect(FormatSheetComparison('BM_data', r) == 'BM_data: 5 rows read (copy had 4: 2 added, 1 removed, 1 changed)', 'the report line')
r0 <- CompareSheetFrames(old, old[c(2, 1, 3, 4), ], 'taxon')
Expect(r0$added == 0 && r0$removed == 0 && r0$changed == 0, 'reordered rows are not a change')
r1 <- CompareSheetFrames(old, new, character(0))
Expect(r1$added == 3 && r1$removed == 2 && r1$changed == 0, 'without key columns every difference is an addition or a removal')
r2 <- CompareSheetFrames(old, cbind(new, extra = 'x'), 'taxon')
Expect(r2$columns_differ && grepl('the columns differ', FormatSheetComparison('BM_data', r2), fixed = TRUE), 'a column added or removed is reported')
r3 <- CompareSheetFrames(old, new[0, ], 'taxon')
Expect(r3$n_new == 0 && r3$removed == 4 && r3$added == 0 && r3$changed == 0, 'an empty read: every copied row removed')
rn <- CompareSheetFrames(NULL, new)
Expect(is.na(rn$n_old) && rn$added == 5 && FormatSheetComparison('T', rn) == 'T: 5 rows read (no copy yet)', 'no copy yet')

# ---- (e) numbers and cells round-trip ----------------------------------------------------------
cat('FormatSheetNumber(), SnapshotSheetTab(), LoadSheetSnapshot()\n')
x <- c(5.8, 1/3, 3e6, 1.74e-05, NA, 195.527745925457, 0.1 + 0.2, 123456789012345678, -2.5, 0)
f <- FormatSheetNumber(x)
Expect(identical(f, c('5.8', '0.333333333333333', '3000000', '1.74e-05', NA, '195.527745925457', '0.3', '1.23456789012346e+17', '-2.5', '0')) &&
         identical(as.numeric(f)[c(1, 3, 4, 6, 9, 10)], x[c(1, 3, 4, 6, 9, 10)]) && abs(as.numeric(f[2]) - 1/3) < 1e-15 && abs(as.numeric(f[7]) - (0.1 + 0.2)) < 1e-15,
       '15 significant digits: every typed value reads back as the same double, a computed one (1/3, 0.1 + 0.2) within 1e-15 relative, NA kept')
Expect(identical(FormatSheetNumber(as.numeric(f)), f) && identical(FormatSheetNumber(as.numeric(bm$mass_g)), bm$mass_g) &&
         !any(grepl('0x', bm$mass_g, fixed = TRUE)) && all(nchar(sub('^0+\\.?0*', '', gsub('e.*$|[^0-9.]', '', bm$mass_g[!is.na(bm$mass_g)]))) <= 16),   # <= 15 digits plus the point
       'the 15-digit string is a fixpoint of read-then-write, on these values and on every mass of the committed copy (decimals only)')
sf <- tempfile(fileext = '.csv')
SnapshotSheetTab(data.frame(k = c('A', NA, 'NA', 'q"uote'), v = c(1.5, NA, 2, 1/3), i = c(1L, 2L, NA, 4L), stringsAsFactors = FALSE), sf)
Expect(identical(readLines(sf)[1:3], c('"k","v","i"', '"A","1.5","1"', ',,"2"')),
       'the copy is a plain CSV: every cell quoted text, an empty cell for NA, the Sheet\'s column order')
back <- LoadSheetSnapshot(sf)
Expect(identical(back$k, c('A', NA, 'NA', 'q"uote')) && identical(back$v, c('1.5', NA, '2', '0.333333333333333')) && identical(back$i, c('1', '2', NA, '4')) &&
         identical(as.numeric(back$v)[1:3], c(1.5, NA, 2)) && abs(as.numeric(back$v[4]) - 1/3) < 1e-15,
       'read back: an empty cell is NA, a cell that says NA is the string "NA" (as read_sheet() gives them), quotes survive, the numbers at 15 digits')

# ---- (f) the age of a copy ------------------------------------------------------------------
cat('SheetSnapshotAge(), ReportSheetSnapshots()\n')
age <- SheetSnapshotAge(paths$snapshot_citations, repo)
Expect(grepl('^committed \\d{4}-\\d{2}-\\d{2}$', age) || grepl('^modified \\d{4}-\\d{2}-\\d{2} uncommitted$', age),
       paste0('a committed copy reports its last commit date (', age, ')'))
Expect(grepl('^modified \\d{4}-\\d{2}-\\d{2} uncommitted$', SheetSnapshotAge(sf, repo)), 'an uncommitted file reports its mtime, flagged')
msgs <- character(0)
withCallingHandlers(ReportSheetSnapshots(paths, repo), message = function(m) { msgs <<- c(msgs, conditionMessage(m)); invokeRestart('muffleMessage') })
Expect(length(msgs) == 1 && grepl(sprintf('^Lab Sheet copies \\(DataSheets = FALSE\\): BM_data %s rows \\((committed|modified) ', format(nrow(bm), big.mark = ',')), msgs) &&
         grepl(', BM_citations [0-9,]+ rows \\(', msgs) && grepl(', BM_primary_citations [0-9,]+ rows \\(', msgs),
       'the staleness line: each copy with its row count and date')

# ---- (g) the wiring in RunMe.r ---------------------------------------------------------------
cat('R/RunMe.r wiring\n')
runme <- readLines(file.path(repo, 'R', 'RunMe.r'))
i_flag  <- grep('^DataSheets   <- FALSE$', runme)
i_fish  <- grep('^DataFishbase <- TRUE$', runme)
i_src   <- grep("^source\\(file\\.path\\(wd_root, 'R', 'library', 'sheet_snapshots\\.r'\\)\\)$", runme)
i_paths <- grep('^sheet_paths <- CitationsPaths\\(wd_root\\)$', runme)
i_if    <- grep('^if \\(DataSheets\\) \\{$', runme)
i_else  <- grep('^\\} else \\{$', runme)
i_else  <- i_else[i_else > i_if][1]
i_end   <- grep('^\\}$', runme); i_end <- i_end[i_end > i_else][1]
i_check <- grep('^  CheckSheetSnapshots\\(sheet_paths\\)', runme)
i_rep   <- grep('^  ReportSheetSnapshots\\(sheet_paths, wd_root\\)$', runme)
i_auth  <- grep('SheetAuth\\(\\)|gs4_auth|gs4_has_token', runme)
i_refr  <- grep('RefreshSheetSnapshots\\(', runme)
i_s1    <- grep('^# 1\\. Re-generate per-source Rdata files', runme)
i_dl    <- grep('^if \\(DataRetrieve\\)\\{', runme)
Expect(length(i_flag) == 1 && length(i_fish) == 1 && i_flag > i_fish && i_flag < grep('^fresh_start', runme)[1],
       'DataSheets is defined in the control-flag block, committed as FALSE')
Expect(length(i_src) == 1 && length(i_paths) == 1 && length(i_if) == 1 && i_src < i_paths && i_paths < i_if,
       'RunMe.r sources sheet_snapshots.r and takes the paths from CitationsPaths() before the Sheet block')
Expect(length(i_auth) >= 1 && all(i_auth > i_if & i_auth < i_else) && length(i_refr) == 1 && i_refr > i_if && i_refr < i_else &&
         !any(grepl('^\\s*if \\(!googlesheets4::gs4_has_token', runme)),
       'the authentication and the download happen only inside if (DataSheets)')
Expect(length(i_check) == 1 && length(i_rep) == 1 && i_check > i_else && i_rep > i_check && i_rep < i_end,
       'the else branch checks the copies (stopping on a missing one) and reports their age')
Expect(length(i_s1) == 1 && length(i_dl) == 1 && i_end < i_dl && i_dl < i_s1,
       'the Sheet block sits before the download blocks and section 1, so a missing copy stops the run in its first second')
Expect(!any(grepl('read_sheet\\(|sheet_names\\(|bm_sheet_url', runme)), 'no bare read_sheet(), sheet_names() or hardcoded Sheet URL is left')
i_load  <- grep('^ddat <- LoadSheetSnapshot\\(sheet_paths\\$snapshot_data\\)$', runme)
i_num   <- grep('^ddat\\$mass_g <- as\\.numeric\\(ddat\\$mass_g\\)$', runme)
i_filt  <- grep('^ddat <- ddat\\[which\\(!is\\.na\\(ddat\\$mass_g\\)\\), 1:4\\]$', runme)
i_taxa  <- grep('^ddat <- CheckSheetTaxa\\(ddat\\)$', runme)
Expect(all(lengths(list(i_load, i_num, i_filt, i_taxa)) == 1) && i_load < i_num && i_num < i_filt && i_filt < i_taxa,
       'section 4 loads the BM_data copy, restores mass_g as a number, keeps the rows with a mass and columns 1-4, then checks the taxa as before')
i_gmap <- grep('^gmap <- LoadSheetSnapshot\\(sheet_paths\\$snapshot_citations\\)\\[, 1:2\\]', runme)
i_pmap <- grep('^pmap <- LoadSheetSnapshot\\(sheet_paths\\$snapshot_primary\\)', runme)
Expect(length(i_gmap) == 1 && length(i_pmap) == 1 && i_gmap < i_pmap && i_pmap < grep('^gmap <- CleanCiteMap\\(gmap\\)$', runme)[1],
       'section 8 reads the two citation copies (CiteID and Bibcite of BM_citations; every column of BM_primary_citations) with no Sheet fallback')

# ---- summary -------------------------------------------------------------------
cat(sprintf('\n%d expectations, %d failed\n', n_checks, length(failures)))
if (length(failures) > 0) {
  cat(paste0('  FAIL: ', failures, '\n'), sep = '')
  quit(status = 1)
}
