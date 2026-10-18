adat <- read.csv(file.path(wd_source, 'BodyMass.csv'), header = TRUE,
                 fileEncoding = 'latin1')
taxon_tax <- adat[, c('Species..ITIS.', 'Family')]
taxon_tax <- taxon_tax[!duplicated(taxon_tax$Species..ITIS.), ]
taxon_tax$family <- iconv(as.character(taxon_tax$Family), to = 'ASCII//TRANSLIT')
names(taxon_tax)[1] <- 'taxon'
taxon_tax <- taxon_tax[, c('taxon', 'family')]
# Reference key lookup: Refs1 integer -> key (references.csv)
ref_lookup_path <- file.path(wd_source, 'references.csv')
ref_lookup <- if (file.exists(ref_lookup_path)) {
  rl <- read.csv(ref_lookup_path, stringsAsFactors = FALSE, colClasses = 'character')
  setNames(rl$key, rl$key)
} else character(0)
ref_raw <- as.character(adat$Refs1)
ref_raw[ref_raw %in% c('NA', '?', '')] <- NA_character_
ref_keys <- if (length(ref_lookup) > 0) ref_lookup[ref_raw] else rep(NA_character_, nrow(adat))
ref_keys[is.na(ref_raw)] <- NA_character_
adat <- data.frame(taxon    = adat$Species..ITIS.,
                   mass_g   = suppressWarnings(as.numeric(adat$BodyMass_kg)) * 1000,
                   ref_keys = ref_keys,
                   stringsAsFactors = FALSE)
adat <- adat[!is.na(adat$mass_g), ]
adat$n <- 1
adat$source_mass <- 'GalanAcedo_etal_2026'
adat <- merge(adat, taxon_tax, by = 'taxon', all.x = TRUE)
GA <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'family', 'ref_keys')]
save(GA, file = file.path(wd_rdata, 'BodyMass_GalanAcedo_etal_2026.Rdata'))
