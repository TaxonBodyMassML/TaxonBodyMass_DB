gmean <- function(x){
  exp(mean(log(x[!is.infinite(x)]), na.rm = TRUE))
}

'%!in%' <- function(x, y)!('%in%'(x, y))

RemoveSource <- function(dat, taxon, source) {
  rows <- dat$taxon == taxon
  for (src in source) {
    dat$mass_g[rows & dat$source_mass == src] <- NA
    s  <- dat$source_mass[rows]
    s  <- gsub(paste0(src, "(-|; )"), "", s)
    s  <- gsub(paste0("(-|; )", src), "", s)
    dat$source_mass[rows] <- s
  }
  dat
}

RemoveRecord <- function(dat, taxon, source = NULL) {
  if (is.null(source)) {
    dat[dat$taxon != taxon, ]
  } else {
    dat[!(dat$taxon == taxon & dat$source_mass == source), ]
  }
}
