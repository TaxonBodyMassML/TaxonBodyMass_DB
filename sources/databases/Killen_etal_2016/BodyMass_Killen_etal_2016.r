adat <- read.csv(file.path(wd_source, 'TableS1.csv'), header = TRUE,
                 fileEncoding = 'latin1')
taxon_tax <- adat[, c('species', 'order', 'family')]
taxon_tax <- taxon_tax[!duplicated(taxon_tax$species), ]
taxon_tax$order  <- iconv(as.character(taxon_tax$order),  to = 'ASCII//TRANSLIT')
taxon_tax$family <- iconv(as.character(taxon_tax$family), to = 'ASCII//TRANSLIT')
names(taxon_tax)[1] <- 'taxon'
# Build ref_keys from MMRref using key_map.csv (full citation text -> abbreviated key)
key_map_path <- file.path(wd_source, 'key_map.csv')
key_map <- if (file.exists(key_map_path)) {
  km <- read.csv(key_map_path, stringsAsFactors = FALSE, colClasses = 'character')
  setNames(km$key, km$citation_text)
} else character(0)
ref_raw <- trimws(adat$MMRref)
ref_raw[ref_raw %in% c('', 'NA')] <- NA_character_
ref_keys <- vapply(ref_raw, function(x) {
  if (is.na(x)) return(NA_character_)
  k <- key_map[x]
  if (is.na(k)) NA_character_ else k
}, character(1), USE.NAMES = FALSE)
adat <- adat[, c('species', 'MMRmass')]
colnames(adat) <- c('taxon', 'mass_g')
adat$ref_keys <- ref_keys
adat <- adat[!is.na(adat$mass_g), ]
adat$n <- 1
adat$source_mass <- 'Killen_etal_2016'
adat <- merge(adat, taxon_tax, by = 'taxon', all.x = TRUE)
KI <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'ref_keys')]
save(KI, file = file.path(wd_rdata, 'BodyMass_Killen_etal_2016.Rdata'))
