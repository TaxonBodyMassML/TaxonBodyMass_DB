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

RemoveSource <- function(dat, taxon, source) {
  rows <- !is.na(dat$taxon) & dat$taxon == taxon
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
