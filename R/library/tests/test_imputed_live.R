# Tests for the persistence of the imputed-row log entries of the live download
# frames (#40): ImputedEntriesSince(), SaveImputedLive(), ReadImputedLive() and
# MergeImputedLog() in R/library/helpers.r, DownloadedLiveFrames() and
# CheckImputedLive() in R/library/check_cache.r, on synthetic logs, a throwaway
# cache and files under tempdir(); then the two committed files
# audit/imputed_rows_live.csv and audit/imputed_rows.csv against each other.
# No network access and no packages beyond base R are needed.
#
#   Rscript R/library/tests/test_imputed_live.R      (from any directory)
#
# Prints one line per expectation and exits with status 1 if any failed.

# ---- locate the repository and the code under test ---------------------------
this_file <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE))
if (length(this_file) == 0)         # sourced interactively from the repo root
  this_file <- file.path('R', 'library', 'tests', 'test_imputed_live.R')
repo <- normalizePath(file.path(dirname(this_file), '..', '..', '..'))
source(file.path(repo, 'R', 'library', 'helpers.r'))       # imputed_log, DropImputed(), the live-file functions
source(file.path(repo, 'R', 'library', 'check_cache.r'))   # live_frame_flags, CheckImputedLive()

# ---- helpers ------------------------------------------------------------------
failures <- character(0)
n_checks <- 0L
Expect <- function(ok, what) {
  n_checks <<- n_checks + 1L
  if (!isTRUE(ok)) failures <<- c(failures, what)
  cat(sprintf('  %s %s\n', if (isTRUE(ok)) 'ok  ' else 'FAIL', what))
}
Has <- function(x, pattern) !is.null(x) && any(grepl(pattern, x, fixed = TRUE))
# Evaluate an expression, collecting its warnings and messages.
Capture <- function(expr) {
  warns <- character(0); msgs <- character(0)
  val <- withCallingHandlers(expr,
    warning = function(w) { warns <<- c(warns, conditionMessage(w)); invokeRestart('muffleWarning') },
    message = function(m) { msgs  <<- c(msgs,  conditionMessage(m)); invokeRestart('muffleMessage') })
  list(value = val, warnings = warns, messages = msgs)
}
Err <- function(expr) tryCatch({ expr; NULL }, error = function(e) conditionMessage(e))
# A DropImputed() record.
Entry <- function(source, reason, n_dropped, n_taxa, n_kept)
  data.frame(source = source, reason = reason, n_dropped = n_dropped, n_taxa = n_taxa,
             n_kept = n_kept, stringsAsFactors = FALSE)
# The seed of a data frame decides the frame file's content, hence its md5.
WriteFrame <- function(frame, seed = 1) {
  dummy <- data.frame(taxon = paste0('Live_', seed), mass_g = seed)
  save(dummy, file = LiveFrameFile(wd_rdata, frame))
}
Md5 <- function(frame) unname(tools::md5sum(LiveFrameFile(wd_rdata, frame)))

# A throwaway cache holding the four live frames, and a live file beside it.
root     <- tempfile('tbm_live_')
wd_rdata <- file.path(root, 'sources', 'Rdata')
dir.create(wd_rdata, recursive = TRUE)
frames <- LiveFrameName(names(live_frame_flags))
for (fr in frames) WriteFrame(fr)
path <- file.path(root, 'imputed_rows_live.csv')

# ---- 1. DropImputed() entries and ImputedEntriesSince() -----------------------
cat('1. DropImputed() and ImputedEntriesSince()\n')
imputed_log <- list()
dat <- data.frame(taxon = c('A_a', 'A_a', 'B_b', 'C_c'), mass_g = 1:4)
n0 <- length(imputed_log)
kept <- suppressMessages(DropImputed(dat, dat$taxon == 'A_a', 'Brose_2005', 'placeholder rule'))
Expect(nrow(kept) == 2 && length(imputed_log) == 1 && imputed_log[[1]]$n_dropped == 2L,
       'DropImputed() drops the rows and appends one entry')
Expect(identical(ImputedEntriesSince(n0), imputed_log),
       'ImputedEntriesSince(0) returns every entry (imputed_log[-seq_len(0)] would be empty)')
Expect(length(ImputedEntriesSince(length(imputed_log))) == 0, 'ImputedEntriesSince(length) is empty')
suppressMessages(DropImputed(dat, dat$taxon == 'B_b', 'Brose_2005', 'second rule'))
Expect(length(ImputedEntriesSince(1)) == 1 && ImputedEntriesSince(1)[[1]]$reason == 'second rule',
       'ImputedEntriesSince(n) returns the entries after the n-th')
Expect(identical(names(BindImputedLog(imputed_log)), imputed_cols) && nrow(BindImputedLog(imputed_log)) == 2,
       'BindImputedLog() binds the list into the five-column table')
Expect(nrow(BindImputedLog(list())) == 0 && identical(names(BindImputedLog(list())), imputed_cols),
       'BindImputedLog() of an empty list is a zero-row five-column table')

# ---- 2. SaveImputedLive(): round trip and replace-own-rows --------------------
cat('2. SaveImputedLive() and ReadImputedLive()\n')
r <- Capture(SaveImputedLive('DataRetrieverAll', ImputedEntriesSince(n0), path, wd_rdata,
                             written = '2026-10-03'))
Expect(file.exists(path) && Has(r$messages, 'DataRetrieverAll: 2 imputed-row entries saved'),
       'the live file is written and the save reported')
live <- ReadImputedLive(path)
Expect(identical(names(live), imputed_live_cols), 'the file has the columns of imputed_live_cols, in order')
Expect(nrow(live) == 2 && all(live$frame == 'DataRetrieverAll') && all(live$written == '2026-10-03'),
       'two rows for the frame, dated as given')
Expect(is.integer(live$n_dropped) && is.integer(live$n_taxa) && is.integer(live$n_kept),
       'the counts read back as integers')
Expect(identical(live[, imputed_cols], BindImputedLog(imputed_log)),
       'source, reason and counts round-trip unchanged')
Expect(all(live$frame_md5 == Md5('DataRetrieverAll')), 'frame_md5 is the md5 of the saved frame file')

vn_entries <- list(Entry('vertnet-aves-sept2016', 'a VertNet rule', 3L, 2L, 10L))
suppressMessages(SaveImputedLive('VertNetAll', vn_entries, path, wd_rdata))
live <- ReadImputedLive(path)
Expect(nrow(live) == 3 && sum(live$frame == 'DataRetrieverAll') == 2 && sum(live$frame == 'VertNetAll') == 1,
       "saving a second frame keeps the first frame's rows")
Expect(live$written[live$frame == 'VertNetAll'] == format(Sys.Date()), 'written defaults to today')
Expect(identical(live$frame, c('DataRetrieverAll', 'DataRetrieverAll', 'VertNetAll')), 'the file is ordered by frame')

suppressMessages(SaveImputedLive('DataRetrieverAll', list(Entry('Brose_2005', 'new placeholder rule', 5L, 1L, 20L)),
                                 path, wd_rdata, written = '2026-10-05'))
live <- ReadImputedLive(path)
Expect(sum(live$frame == 'DataRetrieverAll') == 1 &&
         live$reason[live$frame == 'DataRetrieverAll'] == 'new placeholder rule' &&
         live$written[live$frame == 'DataRetrieverAll'] == '2026-10-05',
       "a new download replaces the frame's previous rows")
Expect(identical(live[live$frame == 'VertNetAll', imputed_cols, drop = FALSE] |> `rownames<-`(NULL),
                 BindImputedLog(vn_entries)),
       "the other frame's rows are untouched")
suppressMessages(SaveImputedLive('VertNetAll', list(), path, wd_rdata))
live <- ReadImputedLive(path)
Expect(!'VertNetAll' %in% live$frame && nrow(live) == 1,
       "an empty set of entries removes the frame's rows and keeps the others")
suppressMessages(SaveImputedLive('Fishbase', list(Entry('Zed', 'z', 1L, 1L, 1L), Entry('Alpha', 'a', 1L, 1L, 1L)),
                                 path, wd_rdata))
live <- ReadImputedLive(path)
Expect(identical(live$source[live$frame == 'Fishbase'], c('Zed', 'Alpha')),
       'rows within a frame keep the order of the calls')
Expect(identical(unique(live$frame), c('DataRetrieverAll', 'Fishbase')), 'frames in C-locale order')
Expect(Has(Err(SaveImputedLive('Nope', list(), path, wd_rdata)), 'must be saved before'),
       'SaveImputedLive() stops when the frame file has not been saved')
suppressMessages(SaveImputedLive('Sealifebase', list(Entry('NoTaxonColumn', 'frame without taxon', 2L, NA_integer_, 8L)),
                                 path, wd_rdata))
live <- ReadImputedLive(path)
Expect(is.na(live$n_taxa[live$frame == 'Sealifebase']) && is.integer(live$n_taxa),
       'an NA n_taxa (frame without a taxon column) round-trips as NA')

# ---- 3. ReadImputedLive(): missing file and validation ------------------------
cat('3. ReadImputedLive() on a missing or malformed file\n')
empty <- ReadImputedLive(file.path(root, 'none.csv'))
Expect(nrow(empty) == 0 && identical(names(empty), imputed_live_cols) && is.integer(empty$n_dropped),
       'a missing file reads as zero rows with the columns and integer counts')
bad <- file.path(root, 'bad.csv')
Bad <- function(...) write.csv(data.frame(..., stringsAsFactors = FALSE), bad, row.names = FALSE)
Bad(source = 'S', reason = 'r', n_dropped = 1, n_taxa = 1, n_kept = 1, frame = 'DataRetrieverAll')
Expect(Has(Err(ReadImputedLive(bad)), 'lacks the column(s) written, frame_md5'), 'missing columns are named')
Bad(source = 'S', reason = 'r', n_dropped = 1, n_taxa = 1, n_kept = 1, frame = 'DataRetrieverAll',
    written = '03/10/2026', frame_md5 = 'x')
Expect(Has(Err(ReadImputedLive(bad)), 'ISO date'), 'a non-ISO written date stops')
Bad(source = 'S', reason = 'r', n_dropped = 1, n_taxa = 1, n_kept = 1, frame = '',
    written = '2026-10-03', frame_md5 = 'x')
Expect(Has(Err(ReadImputedLive(bad)), 'needs a frame'), 'an empty frame stops')

# ---- 4. MergeImputedLog() -----------------------------------------------------
cat('4. MergeImputedLog()\n')
# A run's in-memory log: parse scripts in folder order, then a FixFormatting()
# entry for a source already logged, then a lowercase label.
log <- list(Entry('Zeta_2020',   'parse rule',            10L, 2L, 90L),
            Entry('Alpha_2019',  'parse rule',             1L, 1L, 99L),
            Entry('Zeta_2020',   'life-stage annotation',  5L, 1L, 85L),
            Entry('alpha_lower', 'parse rule',             1L, 1L,  1L))
live_tab <- data.frame(source = c('Brose_2005', 'vertnet-aves-sept2016'),
                       reason = c('placeholder', 'a VertNet rule'),
                       n_dropped = c(2269L, 3L), n_taxa = c(68L, 2L), n_kept = c(16906L, 10L),
                       frame = c('DataRetrieverAll', 'VertNetAll'), written = '2026-10-03',
                       frame_md5 = 'abc', stringsAsFactors = FALSE)
m <- MergeImputedLog(log, live_tab)
Expect(identical(names(m), imputed_cols), 'the merged table has exactly the five log columns')
Expect(nrow(m) == 6, 'no flag TRUE: every in-memory and saved row is present')
Expect(identical(m$source, c('Alpha_2019', 'Brose_2005', 'Zeta_2020', 'Zeta_2020', 'alpha_lower',
                             'vertnet-aves-sept2016')),
       'rows ordered by source in the C locale (uppercase before lowercase)')
Expect(identical(m$reason[m$source == 'Zeta_2020'], c('parse rule', 'life-stage annotation')),
       'ties keep the order of the calls (parse script before FixFormatting), n_kept a running tally')
Expect(identical(attr(m, 'row.names'), seq_len(6L)), 'row names are reset')
log_dl <- c(list(Entry('Brose_2005', 'placeholder', 2269L, 68L, 16906L)), log)   # the download block ran first
m_dl <- MergeImputedLog(log_dl, live_tab, downloaded = 'DataRetrieverAll')
Expect(sum(m_dl$source == 'Brose_2005') == 1, "a downloaded frame's saved rows are not duplicated")
Expect(identical(m_dl, m), 'the table is identical whether the frame was downloaded or its rows came from the file')
m_vn <- MergeImputedLog(log, live_tab, downloaded = c('VertNetAll', 'Fishbase', 'Sealifebase'))
Expect(!'vertnet-aves-sept2016' %in% m_vn$source && 'Brose_2005' %in% m_vn$source && nrow(m_vn) == 5,
       'a downloaded frame with no fresh entries contributes nothing; the other saved rows stay')
e1 <- MergeImputedLog(list(), live_tab[0, ])
Expect(nrow(e1) == 0 && identical(names(e1), imputed_cols), 'empty log and empty file give zero rows')
e2 <- MergeImputedLog(list(), live_tab)
Expect(nrow(e2) == 2 && identical(e2$source, c('Brose_2005', 'vertnet-aves-sept2016')),
       'an empty log still yields the saved rows')

# ---- 5. DownloadedLiveFrames() and LiveFrameName() ---------------------------
cat('5. DownloadedLiveFrames()\n')
Expect(identical(frames, c('DataRetrieverAll', 'VertNetAll', 'Fishbase', 'Sealifebase')),
       'LiveFrameName() strips the BodyMass_ prefix and the .Rdata suffix')
Expect(identical(DownloadedLiveFrames(FALSE, FALSE, FALSE), character(0)), 'no flag: no frame')
Expect(identical(DownloadedLiveFrames(TRUE, FALSE, FALSE), 'DataRetrieverAll'), 'DataRetrieve -> DataRetrieverAll')
Expect(identical(DownloadedLiveFrames(FALSE, TRUE, TRUE), c('VertNetAll', 'Fishbase', 'Sealifebase')),
       'DataVertNet + DataFishbase -> VertNetAll, Fishbase, Sealifebase')

# ---- 6. CheckImputedLive() ----------------------------------------------------
cat('6. CheckImputedLive()\n')
unlink(path)
suppressMessages(SaveImputedLive('DataRetrieverAll', list(Entry('Brose_2005', 'placeholder', 1L, 1L, 1L)),
                                 path, wd_rdata, written = '2026-10-03'))
r <- Capture(CheckImputedLive(wd_rdata, path))
Expect(length(r$warnings) == 0, 'consistent file and cache: no warning')
Expect(Has(r$messages, '1 saved imputed-row entry for 1 live frame'), 'the summary message counts rows and frames')
Expect(!Has(r$messages, 'no saved entries for DataRetrieverAll'), 'no information message when DataRetrieverAll has rows')
Sys.setFileTime(LiveFrameFile(wd_rdata, 'DataRetrieverAll'), Sys.time() + 3600)
r <- Capture(CheckImputedLive(wd_rdata, path))
Expect(length(r$warnings) == 0, 'a frame with a newer timestamp but the same content passes (copied cache)')
WriteFrame('DataRetrieverAll', seed = 2)
r <- Capture(CheckImputedLive(wd_rdata, path))
Expect(length(r$warnings) == 1 && Has(r$warnings, 'BodyMass_DataRetrieverAll.Rdata') &&
         Has(r$warnings, 'written 2026-10-03') && Has(r$warnings, 'DataRetrieve = TRUE'),
       'a frame that is not the one its rows were saved with is warned about, with the flag to set')
suppressMessages(SaveImputedLive('DataRetrieverAll', list(Entry('Brose_2005', 'placeholder', 1L, 1L, 1L)),
                                 path, wd_rdata))
r <- Capture(CheckImputedLive(wd_rdata, path))
Expect(length(r$warnings) == 0, "saving the frame's entries again (a DataRetrieve = TRUE run) clears the warning")
live <- ReadImputedLive(path); live$frame[1] <- 'Bogus'; write.csv(live, path, row.names = FALSE)
r <- Capture(CheckImputedLive(wd_rdata, path))
Expect(Has(r$warnings, 'not live frames') && Has(r$warnings, 'Bogus'),
       'rows for a name that is not a live frame are warned about')
Expect(Has(r$messages, 'no saved entries for DataRetrieverAll'),
       'DataRetrieverAll without rows is reported as information')
live$frame[1] <- 'VertNetAll'; write.csv(live, path, row.names = FALSE)
unlink(LiveFrameFile(wd_rdata, 'VertNetAll'))
r <- Capture(CheckImputedLive(wd_rdata, path))
Expect(Has(r$warnings, 'BodyMass_VertNetAll.Rdata is not in sources/Rdata'),
       'rows for a frame whose file is absent are warned about')
WriteFrame('VertNetAll'); unlink(path)
suppressMessages(SaveImputedLive('DataRetrieverAll', list(Entry('Brose_2005', 'placeholder', 1L, 1L, 1L)),
                                 path, wd_rdata))
r <- Capture(CheckImputedLive(wd_rdata, path))
Expect(length(r$warnings) == 0 && !any(grepl('VertNetAll|Fishbase|Sealifebase', r$messages)),
       'live frames without rows (no drop rules) are passed over in silence')
r <- Capture(CheckImputedLive(wd_rdata, file.path(root, 'none.csv')))
Expect(length(r$warnings) == 0 && Has(r$messages, 'no saved entries for DataRetrieverAll'),
       'a missing live file: information only')

# ---- 7. The committed files ---------------------------------------------------
cat('7. audit/imputed_rows_live.csv and audit/imputed_rows.csv\n')
real_live <- ReadImputedLive(file.path(repo, 'audit', 'imputed_rows_live.csv'))
Expect(nrow(real_live) >= 1 && all(real_live$frame %in% frames),
       'audit/imputed_rows_live.csv reads and names live frames only')
Expect(all(grepl('^[0-9a-f]{32}$', real_live$frame_md5)), 'every row carries a frame md5')
Expect('Brose_2005' %in% real_live$source[real_live$frame == 'DataRetrieverAll'],
       'the Brose_2005 placeholder row is saved for DataRetrieverAll')
real_log <- read.csv(file.path(repo, 'audit', 'imputed_rows.csv'), stringsAsFactors = FALSE)
Expect(identical(names(real_log), imputed_cols), 'audit/imputed_rows.csv has the five log columns')
Key <- function(d) do.call(paste, c(d[imputed_cols], sep = '\r'))
Expect(all(Key(real_live) %in% Key(real_log)), 'every saved live row is in audit/imputed_rows.csv')
in_memory <- real_log[!Key(real_log) %in% Key(real_live), , drop = FALSE]
Expect(isTRUE(all.equal(MergeImputedLog(in_memory, real_live), real_log, check.attributes = FALSE)),
       'audit/imputed_rows.csv is in the merged order (its own rows merged with the live file reproduce it)')

# ---- summary ------------------------------------------------------------------
unlink(root, recursive = TRUE)
cat(sprintf('\n%d expectations, %d failed\n', n_checks, length(failures)))
if (length(failures) > 0) {
  cat(paste0('  FAIL: ', failures, '\n'), sep = '')
  quit(status = 1)
}
