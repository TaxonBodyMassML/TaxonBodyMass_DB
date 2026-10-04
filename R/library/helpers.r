gmean <- function(x){
  exp(mean(log(x[!is.infinite(x)]), na.rm = TRUE))
}

'%!in%' <- function(x, y)!('%in%'(x, y))

# Normalise a source_mass label (or a BM_citations CiteID) to plain ASCII so
# hand-typed variants compare equal: trims whitespace, converts non-breaking
# spaces to spaces, maps every Unicode dash (U+2010..U+2015, U+2212) to '-',
# and transliterates diacritics (e.g. Cervigón -> Cervigon), mirroring the
# treatment FixFormatting gives taxon names. NA is preserved. Multi-source
# strings ('A; B') are handled label by label.
NormaliseSourceLabel <- function(x) {
  is_na <- is.na(x)
  x <- enc2utf8(as.character(x))
  x <- gsub(' ', ' ', x, fixed = TRUE)
  x <- gsub('[‐‑‒–—―−]', '-', x, perl = TRUE)
  x <- iconv(x, from = 'UTF-8', to = 'ASCII//TRANSLIT')
  x <- gsub('[^\x01-\x7F]', '', x)
  # ASCII//TRANSLIT on macOS emits stray accent marks (Cervig'on, Mart'inez)
  # and '?' for untransliterable characters; none can occur in a real label.
  x <- gsub("[?'`^~\"]", '', x)
  x <- gsub('\\s*;\\s*', '; ', x)
  x <- trimws(x)
  x[is_na] <- NA_character_
  x
}

# Rows that a source itself flags as not species-specific measurements
# (statistical or phylogenetic imputations, genus/family averages, values
# copied from another species, unsatisfactory conversions) are removed in the
# parse scripts with DropImputed(), which appends one record per filter to
# `imputed_log`; FixFormatting() (life stages and small size classes, #38) and
# the live download scripts (#40) call it too. RunMe.r prints the log after
# FixFormatting() and writes it to audit/imputed_rows.csv, merged with the
# saved entries of the live download frames (audit/imputed_rows_live.csv,
# below). Allometry-derived values (a measured dimension of the species itself
# through a published equation) are kept, not dropped here.
imputed_log <- list()

DropImputed <- function(dat, drop, source, reason) {
  stopifnot(length(drop) == nrow(dat))
  drop <- !is.na(drop) & drop            # an NA flag is not evidence of imputation
  entry <- data.frame(
    source    = source,
    reason    = reason,
    n_dropped = sum(drop),
    n_taxa    = if ('taxon' %in% names(dat)) length(unique(dat$taxon[drop])) else NA_integer_,
    n_kept    = sum(!drop),
    stringsAsFactors = FALSE)
  imputed_log[[length(imputed_log) + 1L]] <<- entry
  message(sprintf('    %s: dropped %d imputed rows (%d taxa; %s), %d kept',
                  source, entry$n_dropped, entry$n_taxa, reason, entry$n_kept))
  dat[!drop, , drop = FALSE]
}

# ---- the saved entries of the live download frames (#40) ---------------------
# The DropImputed() calls of a live download frame run only while the frame is
# downloaded (data_retrieve.r: the Brose_2005 placeholder rows; none yet in
# data_vertnet.r or data_fishbase.r), so a recompile-only run would write
# audit/imputed_rows.csv without them. Each download script therefore saves
# its own entries to audit/imputed_rows_live.csv with SaveImputedLive(), which
# replaces the frame's previous rows and leaves the other frames' rows alone,
# and RunMe.r merges the file into the run's log with MergeImputedLog() when
# it writes audit/imputed_rows.csv. Each row records the md5 of the frame file
# its download saved, which CheckImputedLive() (check_cache.r) compares with
# the cached frame at every run.
imputed_cols      <- c('source', 'reason', 'n_dropped', 'n_taxa', 'n_kept')
imputed_live_cols <- c(imputed_cols, 'frame', 'written', 'frame_md5')

ImputedLivePath <- function(wd_root) file.path(wd_root, 'audit', 'imputed_rows_live.csv')
LiveFrameFile   <- function(wd_rdata, frame) file.path(wd_rdata, sprintf('BodyMass_%s.Rdata', frame))

# One table (the columns imputed_cols) from a list of DropImputed() entries or
# a data frame holding them; zero rows when the list is empty.
BindImputedLog <- function(log) {
  if (is.data.frame(log)) tab <- log
  else if (length(log) == 0)
    tab <- data.frame(source = character(), reason = character(), n_dropped = integer(),
                      n_taxa = integer(), n_kept = integer(), stringsAsFactors = FALSE)
  else tab <- do.call(rbind, log)
  rownames(tab) <- NULL
  tab[, imputed_cols, drop = FALSE]
}

# The entries appended to imputed_log after it held `n` entries. A download
# script notes n <- length(imputed_log) before its first DropImputed() call and
# passes ImputedEntriesSince(n) to SaveImputedLive() once its frame is saved.
# (imputed_log[-seq_len(0)] would be the empty list, hence the helper.)
ImputedEntriesSince <- function(n) imputed_log[seq_along(imputed_log) > n]

# audit/imputed_rows_live.csv as a table with the columns imputed_live_cols:
# `frame`, the live frame the rows belong to ('DataRetrieverAll', 'VertNetAll',
# 'Fishbase' or 'Sealifebase', the stem of the frame file); `written`, the ISO
# date of the download that produced them; `frame_md5`, the md5 of the frame
# file that download saved. A missing file reads as zero rows. Stops on a
# missing column, an empty frame or a malformed date.
ReadImputedLive <- function(path) {
  count_cols <- c('n_dropped', 'n_taxa', 'n_kept')
  if (!file.exists(path)) {
    live <- as.data.frame(setNames(rep(list(character()), length(imputed_live_cols)),
                                   imputed_live_cols), stringsAsFactors = FALSE)
  } else {
    live <- read.csv(path, stringsAsFactors = FALSE, colClasses = 'character')
    missing <- setdiff(imputed_live_cols, names(live))
    if (length(missing) > 0)
      stop(basename(path), ' lacks the column(s) ', paste(missing, collapse = ', '), call. = FALSE)
    if (any(is.na(live$frame) | !nzchar(live$frame)))
      stop(basename(path), ': every row needs a frame', call. = FALSE)
    if (any(is.na(as.Date(live$written, format = '%Y-%m-%d'))))
      stop(basename(path), ': `written` must be an ISO date (YYYY-MM-DD) in every row', call. = FALSE)
  }
  for (col in count_cols) live[[col]] <- as.integer(live[[col]])
  live[, imputed_live_cols, drop = FALSE]
}

# Replace the rows of `frame` in audit/imputed_rows_live.csv (`path`) with
# `entries` (a list of DropImputed() entries, usually ImputedEntriesSince(n);
# may be empty, the frame then has no rows), dated `written` and stamped with
# the md5 of the frame file in wd_rdata, which the script must have saved
# first. The other frames' rows are kept as they are; the file is ordered by
# frame (C locale), each frame's rows in the order of the calls. Returns the
# table invisibly.
SaveImputedLive <- function(frame, entries, path, wd_rdata, written = Sys.Date()) {
  stopifnot(is.character(frame), length(frame) == 1L, nzchar(frame))
  frame_file <- LiveFrameFile(wd_rdata, frame)
  if (!file.exists(frame_file))
    stop('SaveImputedLive(): ', basename(frame_file), ' must be saved before its entries', call. = FALSE)
  new <- BindImputedLog(entries)
  new$frame     <- rep(frame, nrow(new))
  new$written   <- rep(format(as.Date(written), '%Y-%m-%d'), nrow(new))
  new$frame_md5 <- rep(unname(tools::md5sum(frame_file)), nrow(new))
  live <- ReadImputedLive(path)
  live <- rbind(live[live$frame != frame, , drop = FALSE], new[, imputed_live_cols, drop = FALSE])
  live <- live[order(live$frame, method = 'radix'), , drop = FALSE]
  rownames(live) <- NULL
  write.csv(live, path, row.names = FALSE)
  message(sprintf('    %s: %d imputed-row entries saved to %s', frame, nrow(new), basename(path)))
  invisible(live)
}

# The table RunMe.r writes to audit/imputed_rows.csv: the run's entries (`log`:
# the parse scripts, FixFormatting() and the fresh entries of any live frame
# downloaded in this run) plus the saved rows of the live frames that were not
# downloaded (`live`: ReadImputedLive(); `downloaded`: the frames whose RunMe.r
# flag was TRUE, whose saved rows would duplicate the fresh entries). Rows are
# ordered by source in the C locale, ties in the order of the calls, so the
# file does not depend on which download blocks ran and n_kept remains a
# running tally within each source.
MergeImputedLog <- function(log, live, downloaded = character()) {
  saved <- live[!live$frame %in% downloaded, imputed_cols, drop = FALSE]
  tab   <- rbind(saved, BindImputedLog(log))
  tab   <- tab[order(tab$source, method = 'radix'), , drop = FALSE]
  rownames(tab) <- NULL
  tab
}
