remove_high_range_taxa <- function(dat, threshold = 1) {
  removed <- dat[!is.na(dat$log10_range) & dat$log10_range > threshold, ]
  kept    <- dat[ is.na(dat$log10_range) | dat$log10_range <= threshold, ]
  list(dat = kept, n_removed = nrow(removed))
}
