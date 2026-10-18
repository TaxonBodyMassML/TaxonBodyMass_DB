adat <- read.csv(file.path(wd_source, 'Hirt_etal_2017.csv'), header = TRUE)
# Reference key lookup: mass.ref integer -> key (references.csv)
ref_lookup_path <- file.path(wd_source, 'references.csv')
ref_lookup <- if (file.exists(ref_lookup_path)) {
  rl <- read.csv(ref_lookup_path, stringsAsFactors = FALSE, colClasses = 'character')
  setNames(rl$key, rl$key)
} else character(0)
ref_raw <- as.character(adat$mass.ref)
ref_keys <- if (length(ref_lookup) > 0) ref_lookup[ref_raw] else rep(NA_character_, nrow(adat))
ref_keys[is.na(ref_raw) | ref_raw == ''] <- NA_character_
adat <- adat[, c('species', 'body.mass..kg.')]
colnames(adat) <- c('taxon', 'mass_g')
adat$mass_g <- adat$mass_g * 1000
adat$ref_keys <- ref_keys
adat <- adat[!is.na(adat$mass_g), ]
adat$n <- 1
adat$source_mass <- 'Hirt_etal_2017'
HI <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'ref_keys')]
save(HI, file = file.path(wd_rdata, 'BodyMass_Hirt_etal_2017.Rdata'))
