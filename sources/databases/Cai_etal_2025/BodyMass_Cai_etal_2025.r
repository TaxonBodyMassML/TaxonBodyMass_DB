adat <- read.csv(file.path(wd_source, 'Dataset S27.csv'), skip = 1, header = TRUE)
adat$taxon <- adat$Species
taxon_tax <- adat[, c('taxon', 'Class', 'Order', 'Family')]
taxon_tax <- taxon_tax[!duplicated(taxon_tax$taxon), ]
taxon_tax$class  <- iconv(as.character(taxon_tax$Class),  to = 'ASCII//TRANSLIT')
taxon_tax$order  <- iconv(as.character(taxon_tax$Order),  to = 'ASCII//TRANSLIT')
taxon_tax$family <- iconv(as.character(taxon_tax$Family), to = 'ASCII//TRANSLIT')
taxon_tax <- taxon_tax[, c('taxon', 'class', 'order', 'family')]
adat <- adat[, c('taxon', 'BodyMass..g.', 'Ref.BodyMass')]
colnames(adat)[2] <- 'mass_g'
adat <- adat[!is.na(adat$mass_g), ]
# Ref.BodyMass names the source of each value. 'Estimated' (no method given),
# 'Sister species', 'My' (no source given) and genus/family averages are not
# species-specific measurements and are dropped. The 90 amphibian rows marked
# 'Estimated by total length' are kept as allometry-derived values (owner
# decision 2026-10-02).
ref <- trimws(adat$Ref.BodyMass)
adat <- DropImputed(adat,
                    ref %in% c('Estimated', 'Sister species', 'My') |
                      grepl('^Average of (genus|family)', ref, ignore.case = TRUE),
                    'Cai_etal_2025',
                    'Ref.BodyMass Estimated, Sister species, My or genus/family average')
adat <- adat[, c('taxon', 'mass_g')]
adat$n <- 1
adat$source_mass <- 'Cai_etal_2025'
adat <- merge(adat, taxon_tax, by = 'taxon', all.x = TRUE)
CA <- adat
save(CA, file = file.path(wd_rdata, 'BodyMass_Cai_etal_2025.Rdata'))
