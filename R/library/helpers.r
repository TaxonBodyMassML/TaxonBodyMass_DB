gmean <- function(x){
  exp(mean(log(x[!is.infinite(x)]), na.rm = TRUE))
}

'%!in%' <- function(x, y)!('%in%'(x, y))

firstup <-
  function(x) {
    substr(x, 1, 1) <- toupper(substr(x, 1, 1))
    x
  }

FixNames <- function(dat) {
  require('stringr')
  dat$taxon <- gsub(' ', '_', iconv(dat$taxon, from = "ISO-8859-1", to = "UTF-8"))
  dat$taxon <- gsub("[^[:alpha:]_]", "", dat$taxon)
  dat$taxon <- gsub("_sp$", "", dat$taxon)
  dat$taxon <- gsub("_spp$", "", dat$taxon)
  dat$taxon <- firstup(dat$taxon)
  dat$taxon <- gsub("^([^_]*_[^_]*)(_.*)?$", "\\1", dat$taxon)
  dat <- subset(dat, taxon != '')
  return(dat)
}
