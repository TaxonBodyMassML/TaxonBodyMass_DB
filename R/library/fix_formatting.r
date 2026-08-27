firstup <- function(x) {
  substr(x, 1, 1) <- toupper(substr(x, 1, 1))
  x
}

FixFormatting <- function(dat) {

  # Normalise encoding and convert spaces to underscores.
  dat$taxon <- gsub(' ', '_', iconv(dat$taxon, from = 'ISO-8859-1', to = 'UTF-8'))

  # Transliterate diacritics to ASCII base characters (é→e, ü→u, ñ→n, etc.)
  # then strip any residual non-ASCII bytes and the '?' iconv inserts for
  # untransliterable characters. Must run before any regex or API call.
  dat$taxon <- iconv(dat$taxon, from = 'UTF-8', to = 'ASCII//TRANSLIT')
  dat$taxon <- gsub('[^\x01-\x7F]', '', dat$taxon)
  dat$taxon <- gsub('\\?', '', dat$taxon)

  # Strip characters that cannot appear in a Latin binomial (digits, punctuation, etc.).
  dat$taxon <- gsub('[^[:alpha:]_]', '', dat$taxon)

  # Strip leading underscores produced by leading spaces or punctuation in source data.
  dat$taxon <- gsub('^_+', '', dat$taxon)

  # Collapse two or more consecutive underscores to a single underscore.
  # Handles entries like Chiton__cummingii, Phacochoerus__aethiopicus,
  # and the truncated-genus cases (Lonchorhi__aurita, Mystaci__robusta,
  # Holmesi__occidentalis) which FixMisspellings then maps to full names.
  dat$taxon <- gsub('__+', '_', dat$taxon)

  # Strip trailing underscores (e.g. Argoctenus_, Clubiona_).
  dat$taxon <- gsub('_+$', '', dat$taxon)

  # Capitalise first letter of genus.
  dat$taxon <- firstup(dat$taxon)

  # Lowercase the first character of the species epithet.
  # Handles capitalised epithets such as Bathygobius_Andrei,
  # Sebastes_Saxicola, Gillellus_Arenicola, Podilymbus_Podiceps, etc.
  has_sp <- grepl('_', dat$taxon, fixed = TRUE)
  if (any(has_sp)) {
    genera   <- sub('_.*$',    '', dat$taxon[has_sp])
    epithets <- sub('^[^_]+_', '', dat$taxon[has_sp])
    dat$taxon[has_sp] <- paste0(genera, '_',
                                tolower(substr(epithets, 1, 1)),
                                substr(epithets, 2, nchar(epithets)))
  }

  # Truncate trinomials to binomials: keep only Genus_species.
  dat$taxon <- sub('^([^_]+_[^_]+)_.*$', '\\1', dat$taxon)

  # Drop rows with empty taxon after all normalisation.
  dat <- dat[dat$taxon != '', ]

  return(dat)
}
