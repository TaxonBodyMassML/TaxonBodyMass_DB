# Tests for the recompile-loop guards in R/RunMe.r and the cache-completeness
# check in R/library/check_cache.r (#8, #17).
#
# Builds a throwaway source tree (three tiny parse scripts plus dummies for the
# four download frames) and runs the real step-1 section of RunMe.r against it,
# i.e. the lines from the "1. Re-generate per-source Rdata files" header to the
# CheckCacheComplete() call, so the code under test is RunMe.r itself rather
# than a copy. No network access and no packages beyond base R are needed.
#
#   Rscript R/library/tests/test_recompile_guard.R      (from any directory)
#
# Prints one line per expectation and exits with status 1 if any failed.

# ---- locate the repository and the code under test ---------------------------
this_file <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE))
if (length(this_file) == 0)         # sourced interactively from the repo root
  this_file <- file.path('R', 'library', 'tests', 'test_recompile_guard.R')
repo <- normalizePath(file.path(dirname(this_file), '..', '..', '..'))
source(file.path(repo, 'R', 'library', 'helpers.r'))       # %!in%, imputed_log
source(file.path(repo, 'R', 'library', 'check_cache.r'))
CheckSourceDocs <- function(...) invisible(NULL)           # README check: not under test

runme <- readLines(file.path(repo, 'R', 'RunMe.r'))
from  <- grep('^# 1\\. Re-generate per-source Rdata files', runme)
to    <- grep('^CheckCacheComplete\\(wd_db, wd_rdata\\)', runme)
stopifnot(length(from) == 1, length(to) == 1, from < to)
section <- parse(text = runme[from:to])

# ---- helpers ------------------------------------------------------------------
failures <- character(0)
n_checks <- 0L
Expect <- function(ok, what) {
  n_checks <<- n_checks + 1L
  if (!isTRUE(ok)) failures <<- c(failures, what)
  cat(sprintf('  %s %s\n', if (isTRUE(ok)) 'ok  ' else 'FAIL', what))
}
Has <- function(x, pattern) !is.null(x) && grepl(pattern, x, fixed = TRUE)

# A fresh tree: sources/databases/Src?/BodyMass_Src?.r, each saving one row to
# sources/Rdata/BodyMass_Src?.Rdata, plus the four download frames. The RunMe.r
# globals the section reads (wd_root, wd_db, wd_rdata) are pointed at it.
sources <- c('SrcA', 'SrcB', 'SrcC')
trees   <- character(0)
MakeTree <- function() {
  root <- tempfile('tbm_tree_')
  trees    <<- c(trees, root)
  wd_root  <<- root
  wd_db    <<- file.path(root, 'sources', 'databases')
  wd_rdata <<- file.path(root, 'sources', 'Rdata')
  dir.create(wd_rdata, recursive = TRUE)
  for (s in sources) WriteScript(s)
  dummy <- data.frame(taxon = 'Live_x', mass_g = 1)
  for (f in names(live_frame_flags)) save(dummy, file = file.path(wd_rdata, f))
  invisible(root)
}
ScriptPath <- function(s) file.path(wd_db, s, sprintf('BodyMass_%s.r', s))
FramePath  <- function(f) file.path(wd_rdata, f)
WriteScript <- function(s, body = NULL, frame = sprintf('BodyMass_%s.Rdata', s)) {
  dir.create(dirname(ScriptPath(s)), recursive = TRUE, showWarnings = FALSE)
  if (is.null(body))
    body <- c(sprintf("dat <- data.frame(taxon = 'Genus_%s', mass_g = 1, source_mass = '%s')",
                      tolower(s), s),
              sprintf("save(dat, file = file.path(wd_rdata, '%s'))", frame))
  writeLines(body, ScriptPath(s))
}
# A frame dated an hour ago, as a previous run would have left it.
WriteOldFrame <- function(f) {
  dat <- data.frame(taxon = 'Old_x', mass_g = 1)
  save(dat, file = FramePath(f))
  Sys.setFileTime(FramePath(f), Sys.time() - 3600)
}
IsOld <- function(f) file.exists(FramePath(f)) && file.mtime(FramePath(f)) < Sys.time() - 3000
# Run the extracted section in the global environment (where RunMe.r runs);
# return list(error = message or NULL, warnings = character()).
RunSection <- function(recompile_flag) {
  recompile   <<- recompile_flag
  imputed_log <<- list()
  warns <- character(0)
  err <- tryCatch(
    withCallingHandlers(
      { eval(section, envir = globalenv()); NULL },
      warning = function(w) {
        warns <<- c(warns, conditionMessage(w))
        invokeRestart('muffleWarning')
      }),
    error = function(e) conditionMessage(e))
  list(error = err, warnings = warns)
}

# ---- ExpectedFrames() on the real tree ---------------------------------------
cat('ExpectedFrames() on the real sources/databases tree\n')
real_db   <- file.path(repo, 'sources', 'databases')
n_scripts <- length(list.files(real_db, pattern = '^BodyMass_.*\\.[Rr]$', recursive = TRUE))
real      <- ExpectedFrames(real_db)
Expect(nrow(real) == n_scripts + 2,
       sprintf('%d scripts + DataRetrieverAll + VertNetAll = %d expected frames', n_scripts, nrow(real)))
Expect(sum(real$flag == 'recompile') == n_scripts - 2,
       'every script but Fishbase/Sealifebase is owned by the recompile loop')
Expect(identical(sort(real$frame[real$flag != 'recompile']), sort(names(live_frame_flags))),
       'the four download frames carry their download flag')
Expect(all(frame_overrides %in% real$frame) &&
         !any(sub('\\.Rdata$', '', real$frame) %in% paste0('BodyMass_', names(frame_overrides))),
       'overridden scripts (Makarieva, Smith, Tobias) map to their save() targets')
Expect(!anyDuplicated(real$frame), 'no two scripts map to the same frame')

# ---- (a) parser fails, old frame present -------------------------------------
cat('(a) recompile = TRUE, SrcB fails, old BodyMass_SrcB.Rdata present\n')
MakeTree(); WriteScript('SrcB', "stop('boom')"); WriteOldFrame('BodyMass_SrcB.Rdata')
r <- RunSection(TRUE)
Expect(Has(r$error, '1 parse script(s) failed'), 'run stops on the parser error before the stale check')
Expect(Has(r$error, 'SrcB: boom'), 'stop message names SrcB and its error message')
Expect(IsOld('BodyMass_SrcB.Rdata'), 'the old SrcB frame is left in place (stale, not loaded)')
Expect(file.exists(FramePath('BodyMass_SrcA.Rdata')) && file.exists(FramePath('BodyMass_SrcC.Rdata')),
       'the passing scripts still wrote their frames')

cat('(a2) recompile = TRUE, SrcB runs without saving, old BodyMass_SrcB.Rdata present\n')
MakeTree(); WriteScript('SrcB', "invisible(NULL)"); WriteOldFrame('BodyMass_SrcB.Rdata')
r <- RunSection(TRUE)
Expect(Has(r$error, 'were not rewritten'), 'stale check fires (no parser error to report)')
Expect(Has(r$error, 'BodyMass_SrcB.Rdata'), 'stale check names the frame')

cat('(a3) recompile = TRUE, all scripts pass, orphan old frame present\n')
MakeTree(); WriteOldFrame('BodyMass_Orphan.Rdata')
r <- RunSection(TRUE)
Expect(Has(r$error, 'were not rewritten') && Has(r$error, 'BodyMass_Orphan.Rdata'),
       'stale check fires on the orphan')

# ---- (b) parsers fail, no frame to leave behind -------------------------------
cat('(b) recompile = TRUE, SrcB and SrcC fail, no cached frames for them\n')
MakeTree(); WriteScript('SrcB', "stop('boom')"); WriteScript('SrcC', "x <- (")
r <- RunSection(TRUE)
Expect(Has(r$error, '2 parse script(s) failed'), 'both failures accumulated into one stop')
Expect(Has(r$error, 'SrcB: boom'), 'SrcB listed with its message')
Expect(Has(r$error, '\n  SrcC: '), 'SrcC (syntax error) listed')
Expect(!Has(r$error, 'expected frame(s) are missing'), 'stops before the completeness check')
Expect(!file.exists(FramePath('BodyMass_SrcB.Rdata')), 'no SrcB frame exists (the case the stale check misses)')

# ---- (c) recompile = FALSE, frames missing -------------------------------------
cat('(c) recompile = FALSE, BodyMass_SrcB and BodyMass_VertNetAll missing, orphan present\n')
MakeTree(); r <- RunSection(TRUE)
Expect(is.null(r$error), 'setup: a passing recompile fills the cache')
unlink(FramePath(c('BodyMass_SrcB.Rdata', 'BodyMass_VertNetAll.Rdata')))
WriteOldFrame('BodyMass_Orphan.Rdata')
r <- RunSection(FALSE)
Expect(Has(r$error, '2 of 7 expected frame(s) are missing'), 'completeness check fires')
Expect(Has(r$error, 'BodyMass_SrcB.Rdata  (recompile = TRUE)'), 'missing script frame points to recompile')
Expect(Has(r$error, 'BodyMass_VertNetAll.Rdata  (DataVertNet = TRUE)'), 'missing download frame points to its flag')
Expect(any(grepl('BodyMass_Orphan.Rdata', r$warnings, fixed = TRUE)), 'orphan frame raises a warning')

# ---- (d) passing runs ------------------------------------------------------------
cat('(d) recompile = TRUE then FALSE on a complete cache\n')
MakeTree(); for (s in sources) WriteOldFrame(sprintf('BodyMass_%s.Rdata', s))
t_start <- Sys.time()
r <- RunSection(TRUE)
Expect(is.null(r$error) && length(r$warnings) == 0, 'recompile = TRUE run passes without warnings')
Expect(all(file.mtime(FramePath(sprintf('BodyMass_%s.Rdata', sources))) >= t_start - 1),
       'all three frames rewritten')
r <- RunSection(FALSE)
Expect(is.null(r$error) && length(r$warnings) == 0, 'recompile = FALSE run passes on the complete cache')

# ---- (e) a script saving under an unexpected name ------------------------------
cat('(e) SrcC saves to BodyMass_SrcC_v2.Rdata without a frame_overrides entry\n')
MakeTree(); WriteScript('SrcC', frame = 'BodyMass_SrcC_v2.Rdata')
r <- RunSection(FALSE)
Expect(Has(r$error, 'frame_overrides'), 'ExpectedFrames() stops and points to frame_overrides')
Expect(Has(r$error, 'SrcC/BodyMass_SrcC.r -> BodyMass_SrcC.Rdata'), 'names the script and the frame expected')

# ---- summary -------------------------------------------------------------------
unlink(trees, recursive = TRUE)
cat(sprintf('\n%d expectations, %d failed\n', n_checks, length(failures)))
if (length(failures) > 0) {
  cat(paste0('  FAIL: ', failures, '\n'), sep = '')
  quit(status = 1)
}
