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
# `imputed_log`. RunMe.r prints the log after the recompile loop and writes it
# to audit/imputed_rows.csv. Allometry-derived values (a measured dimension of
# the species itself through a published equation) are kept, not dropped here.
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
