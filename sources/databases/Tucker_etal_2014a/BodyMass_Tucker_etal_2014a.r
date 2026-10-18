adat <- read.csv(file.path(wd_source, 'TrophicLevel_Appendix1.csv'), header = TRUE,
                 fileEncoding = 'latin1')
# Reference key lookup: 'Predator Body Mass Source' abbreviated -> key (references.csv)
ref_lookup_path <- file.path(wd_source, 'references.csv')
ref_lookup <- if (file.exists(ref_lookup_path)) {
  rl <- read.csv(ref_lookup_path, stringsAsFactors = FALSE, colClasses = 'character')
  setNames(rl$key, rl$key)
} else character(0)
ref_raw <- trimws(adat$Predator.Body.Mass.Source)
ref_raw[ref_raw %in% c('', '-')] <- NA_character_
# Split multi-ref cells (', ' before capital letter) and join matched keys with ';'
ref_keys <- vapply(ref_raw, function(x) {
  if (is.na(x)) return(NA_character_)
  parts <- trimws(strsplit(x, ',\\s*(?=[A-Z])', perl = TRUE)[[1]])
  keys <- ref_lookup[parts]
  keys <- keys[!is.na(keys)]
  if (length(keys) == 0) return(NA_character_)
  paste(keys, collapse = ';')
}, character(1), USE.NAMES = FALSE)
adat <- adat[, c('Taxon', 'Mass..log10.kg.')]
colnames(adat) <- c('taxon', 'mass_g')
adat$mass_g <- (10^adat$mass_g) * 1000
adat$ref_keys <- ref_keys
adat <- adat[!is.na(adat$mass_g), ]
adat$n <- 1
adat$source_mass <- 'Tucker_etal_2014a'
TU1 <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'ref_keys')]
save(TU1, file = file.path(wd_rdata, 'BodyMass_Tucker_etal_2014a.Rdata'))
