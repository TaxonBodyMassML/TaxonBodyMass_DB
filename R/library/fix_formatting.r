firstup <- function(x) {
  substr(x, 1, 1) <- toupper(substr(x, 1, 1))
  x
}

# Convert the elements of a character vector that are not valid UTF-8 from
# Latin-1 (the retriever's copy of Brose 2005 arrives so) and leave valid
# UTF-8, which every other frame is, untouched. Converting every element from
# Latin-1, as FixFormatting() did before issue #37, double-encoded the UTF-8
# names: 'Nausithoë rubra' became 'NausithoÃ« rubra' and the two Makarieva_2008
# 'Tetrao urogallus ♀' records became NA. Shared with TaxonKey() in
# foodweb_units.r.
Latin1ToUtf8 <- function(x) {
  x <- as.character(x)
  bad <- !is.na(x) & !validUTF8(x)
  x[bad] <- iconv(x[bad], from = 'latin1', to = 'UTF-8')
  x
}

FixFormatting <- function(dat) {

  # Normalise encoding: only strings that are not valid UTF-8 are converted
  # from Latin-1 (#37).
  dat$taxon <- Latin1ToUtf8(dat$taxon)

  # Sex signs appended to a name ('Tetrao urogallus ♀', Makarieva_2008) are
  # dropped and the record is kept as the species' value (owner decision,
  # #37; text annotations such as 'female' are the subject of #38). This must
  # precede the transliteration: macOS iconv has no ASCII rendering of U+2640
  # and U+2642 and, without `sub`, returns NA for the whole name.
  dat$taxon <- gsub('[\u2640\u2642]', '', dat$taxon)

  # Convert spaces to underscores.
  dat$taxon <- gsub(' ', '_', dat$taxon)

  # Transliterate diacritics to ASCII base characters (ë→e, ü→u, ñ→n, etc.;
  # macOS iconv writes them as "e, "u, ~n, glibc as e, u, n), then strip any
  # residual non-ASCII bytes and the '?' glibc inserts for untransliterable
  # characters. `sub = ''` drops a character that has no transliteration
  # instead of turning the whole name into NA. Must run before any regex or
  # API call.
  dat$taxon <- iconv(dat$taxon, from = 'UTF-8', to = 'ASCII//TRANSLIT', sub = '')
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

  # Drop rows with an empty or missing taxon after all normalisation (an NA
  # in the logical index would keep a row of NAs instead of dropping it).
  dat <- dat[!is.na(dat$taxon) & dat$taxon != '', ]

  return(dat)
}
