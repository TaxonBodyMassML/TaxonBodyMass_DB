# Cache-completeness check for sources/Rdata/ (#17).
#
# Step 2 of RunMe.r loads every .Rdata file it finds in sources/Rdata/, so a
# missing frame (fresh clone, interrupted or failed earlier recompile, download
# flag left FALSE) silently yields an incomplete database, and a frame that no
# current script writes (renamed or removed source) is loaded as if it were
# current. ExpectedFrames() lists the frames the pipeline should have written
# together with the RunMe.r flag that regenerates each; CheckCacheComplete()
# compares that list with the directory, stops on any missing frame and warns
# on extras. RunMe.r calls it before step 2 regardless of `recompile`.

# Scripts whose save() target does not follow BodyMass_<Source>.Rdata, keyed by
# source folder. Checked against every script's save() call on 2026-10-03;
# ExpectedFrames() stops if a script does not mention the frame expected of it,
# so a new exception has to be added here rather than being derived.
frame_overrides <- c(
  Makarieva_etal_2008 = 'BodyMass_Makarieva_2008.Rdata',
  Smith_etal_2003     = 'BodyMass_Smith_2003.Rdata',
  Tobias_etal_2022    = 'BodyMass_Tobias_2022.Rdata'
)

# Frames written by the download blocks at the top of RunMe.r rather than by
# the recompile loop, with the flag that regenerates each. Fishbase and
# Sealifebase have scripts under sources/databases/ but are run by the
# DataFishbase block (the loop skips them); the other two have no script there.
live_frame_flags <- c(
  BodyMass_DataRetrieverAll.Rdata = 'DataRetrieve',
  BodyMass_VertNetAll.Rdata       = 'DataVertNet',
  BodyMass_Fishbase.Rdata         = 'DataFishbase',
  BodyMass_Sealifebase.Rdata      = 'DataFishbase'
)

# One row per frame the cache should hold: `frame`, `source` (the folder under
# wd_db, NA for the two download-only frames) and `flag`, the RunMe.r flag that
# regenerates it.
ExpectedFrames <- function(wd_db) {
  scripts <- list.files(wd_db, pattern = '^BodyMass_.*\\.[Rr]$',
                        recursive = TRUE, full.names = TRUE)
  src    <- basename(dirname(scripts))
  frames <- sub('\\.[Rr]$', '.Rdata', basename(scripts))
  ovr    <- src %in% names(frame_overrides)
  frames[ovr] <- frame_overrides[src[ovr]]
  # Each script must save under the frame expected here; otherwise the
  # completeness check would report its frame missing and the real one as an
  # orphan at every run.
  mentions <- vapply(seq_along(scripts), function(i)
    any(grepl(frames[i], readLines(scripts[i], warn = FALSE),
              fixed = TRUE, useBytes = TRUE)), logical(1))
  if (any(!mentions))
    stop(sum(!mentions), ' parse script(s) do not mention the frame expected of them; ',
         'add the save() target to frame_overrides in R/library/check_cache.r:\n',
         paste0('  ', file.path(src, basename(scripts))[!mentions], ' -> ',
                frames[!mentions], collapse = '\n'), call. = FALSE)
  if (anyDuplicated(frames))
    stop('several parse scripts map to the same frame: ',
         paste(unique(frames[duplicated(frames)]), collapse = ', '), call. = FALSE)
  expected <- data.frame(frame = frames, source = src, flag = 'recompile',
                         stringsAsFactors = FALSE)
  is_live <- expected$frame %in% names(live_frame_flags)
  expected$flag[is_live] <- live_frame_flags[expected$frame[is_live]]
  only_live <- setdiff(names(live_frame_flags), expected$frame)
  expected  <- rbind(expected,
                     data.frame(frame = only_live, source = NA_character_,
                                flag = unname(live_frame_flags[only_live]),
                                stringsAsFactors = FALSE))
  expected <- expected[order(expected$frame), ]
  rownames(expected) <- NULL
  expected
}

# Stop if any expected frame is missing from wd_rdata (naming the flag to set),
# warn on frames present that no current script writes. Returns the expected
# table invisibly.
CheckCacheComplete <- function(wd_db, wd_rdata) {
  expected <- ExpectedFrames(wd_db)
  cached   <- list.files(wd_rdata, pattern = '\\.Rdata$')
  extra    <- setdiff(cached, expected$frame)
  missing  <- expected[!expected$frame %in% cached, , drop = FALSE]
  if (length(extra) > 0)
    warning(length(extra), ' frame(s) in sources/Rdata that no current parse script writes ',
            '(renamed or removed source?); step 2 would load them as current. ',
            'Delete them, or add the mapping to R/library/check_cache.r:\n',
            paste0('  ', extra, collapse = '\n'), immediate. = TRUE, call. = FALSE)
  if (nrow(missing) > 0)
    stop(nrow(missing), ' of ', nrow(expected), ' expected frame(s) are missing from ',
         'sources/Rdata; set the flag shown to TRUE in RunMe.r and rerun:\n',
         paste0('  ', missing$frame, '  (', missing$flag, ' = TRUE)', collapse = '\n'),
         call. = FALSE)
  message(sprintf('CheckCacheComplete: all %d expected frames are present in sources/Rdata.',
                  nrow(expected)))
  invisible(expected)
}

# ---- the saved imputed-row entries of the live frames (#40) -------------------
# The `frame` value of audit/imputed_rows_live.csv for a live frame file:
# 'BodyMass_DataRetrieverAll.Rdata' -> 'DataRetrieverAll'.
LiveFrameName <- function(file) sub('^BodyMass_(.*)\\.Rdata$', '\\1', file)

# The live frames (by LiveFrameName()) regenerated in this run, from the
# RunMe.r download flags; MergeImputedLog() skips their saved rows because
# their fresh entries are already in imputed_log.
DownloadedLiveFrames <- function(DataRetrieve, DataVertNet, DataFishbase) {
  flags <- c(DataRetrieve = isTRUE(DataRetrieve), DataVertNet = isTRUE(DataVertNet),
             DataFishbase = isTRUE(DataFishbase))
  LiveFrameName(names(live_frame_flags)[flags[live_frame_flags]])
}

# Consistency of audit/imputed_rows_live.csv (ReadImputedLive(), helpers.r)
# with the live frames in wd_rdata. Warns when the cached frame is not the
# file whose download saved the rows (md5 differs: the frame was downloaded
# again without saving its entries, or the cache was copied from a run with a
# different frame; a copy of the same file passes, whatever its timestamp),
# and when the file holds rows for a name that is not a live frame or whose
# frame file is absent. A live frame without rows is the normal case for the
# frames with no drop rules; only DataRetrieverAll, the one frame with drop
# rules today, is reported, as information. Returns the table invisibly.
CheckImputedLive <- function(wd_rdata, path) {
  live   <- ReadImputedLive(path)
  frames <- LiveFrameName(names(live_frame_flags))
  unknown <- setdiff(unique(live$frame), frames)
  if (length(unknown) > 0)
    warning(basename(path), ' has rows for ', length(unknown), ' name(s) that are not live frames (',
            paste(unknown, collapse = ', '), '); the live frames are ',
            paste(frames, collapse = ', '), '.', immediate. = TRUE, call. = FALSE)
  for (fr in intersect(frames, unique(live$frame))) {
    f <- LiveFrameFile(wd_rdata, fr)
    if (!file.exists(f)) {
      warning(basename(path), ' has rows for ', fr, ' but ', basename(f),
              ' is not in sources/Rdata.', immediate. = TRUE, call. = FALSE)
      next
    }
    rows <- live[live$frame == fr, , drop = FALSE]
    if (!all(rows$frame_md5 == unname(tools::md5sum(f))))
      warning(basename(f), ' in sources/Rdata is not the frame whose download saved the ',
              basename(path), ' rows of ', fr, ' (written ', max(rows$written), '); the saved ',
              'entries may be stale. Rerun with ', live_frame_flags[basename(f)],
              ' = TRUE to refresh the frame and its entries together.',
              immediate. = TRUE, call. = FALSE)
  }
  if (!'DataRetrieverAll' %in% live$frame)
    message('CheckImputedLive: no saved entries for DataRetrieverAll (the Brose_2005 placeholder ',
            'rows); audit/imputed_rows.csv will lack them until a DataRetrieve = TRUE run.')
  message(sprintf('CheckImputedLive: %d saved imputed-row entr%s for %d live frame(s) in %s.',
                  nrow(live), if (nrow(live) == 1L) 'y' else 'ies',
                  length(unique(live$frame)), basename(path)))
  invisible(live)
}
