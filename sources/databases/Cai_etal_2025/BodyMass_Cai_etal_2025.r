adat <- read.csv(file.path(wd_source, 'Dataset S27.csv'), skip = 1, header = TRUE)
adat$taxon <- adat$Species
taxon_tax <- adat[, c('taxon', 'Class', 'Order', 'Family')]
taxon_tax <- taxon_tax[!duplicated(taxon_tax$taxon), ]
taxon_tax$class  <- iconv(as.character(taxon_tax$Class),  to = 'ASCII//TRANSLIT')
taxon_tax$order  <- iconv(as.character(taxon_tax$Order),  to = 'ASCII//TRANSLIT')
taxon_tax$family <- iconv(as.character(taxon_tax$Family), to = 'ASCII//TRANSLIT')
taxon_tax <- taxon_tax[, c('taxon', 'class', 'order', 'family')]
# Reference key lookup: Ref.BodyMass citation string -> key (references.csv)
ref_lookup_path <- file.path(wd_source, 'references.csv')
ref_lookup <- if (file.exists(ref_lookup_path)) {
  rl <- read.csv(ref_lookup_path, stringsAsFactors = FALSE, colClasses = 'character',
                 encoding = 'UTF-8', fileEncoding = 'UTF-8')
  setNames(rl$key, rl$citation)
} else character(0)
adat <- adat[, c('taxon', 'BodyMass..g.', 'Ref.BodyMass')]
colnames(adat)[2] <- 'mass_g'
adat <- adat[!is.na(adat$mass_g), ]
# Ref.BodyMass names the source of each value. 'Estimated' (no method given),
# 'Sister species', 'My' (no source given) and genus/family averages are not
# species-specific measurements and are dropped. The 90 amphibian rows marked
# 'Estimated by total length' are kept as allometry-derived values (owner
# decision 2026-10-02).
ref_raw <- trimws(adat$Ref.BodyMass)
adat <- DropImputed(adat,
                    ref_raw %in% c('Estimated', 'Sister species', 'My') |
                      grepl('^Average of (genus|family)', ref_raw, ignore.case = TRUE),
                    'Cai_etal_2025',
                    'Ref.BodyMass Estimated, Sister species, My or genus/family average')
ref_raw <- trimws(adat$Ref.BodyMass)
ref_keys <- if (length(ref_lookup) > 0) ref_lookup[ref_raw] else rep(NA_character_, nrow(adat))
ref_keys[is.na(ref_raw) | ref_raw == ''] <- NA_character_
adat$ref_keys <- ref_keys
adat <- adat[, c('taxon', 'mass_g', 'ref_keys')]
adat$n <- 1
adat$source_mass <- 'Cai_etal_2025'
adat <- merge(adat, taxon_tax, by = 'taxon', all.x = TRUE)
CA <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'class', 'order', 'family', 'ref_keys')]
save(CA, file = file.path(wd_rdata, 'BodyMass_Cai_etal_2025.Rdata'))
