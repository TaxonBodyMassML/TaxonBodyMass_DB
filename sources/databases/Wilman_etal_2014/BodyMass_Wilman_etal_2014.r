adat <- read.csv(file.path(wd_source, 'BirdFuncDat.txt'), header = TRUE, sep = '\t')
taxon_tax <- adat[, c('Scientific', 'IOCOrder', 'BLFamilyLatin')]
taxon_tax <- taxon_tax[!duplicated(taxon_tax$Scientific), ]
taxon_tax$order  <- iconv(as.character(taxon_tax$IOCOrder),     to = 'ASCII//TRANSLIT')
taxon_tax$family <- iconv(as.character(taxon_tax$BLFamilyLatin), to = 'ASCII//TRANSLIT')
names(taxon_tax)[1] <- 'taxon'
taxon_tax <- taxon_tax[, c('taxon', 'order', 'family')]
adat <- adat[, c('Scientific', 'BodyMass.Value', 'BodyMass.Source',
                 'BodyMass.SpecLevel', 'BodyMass.Comment')]
colnames(adat)[1:2] <- c('taxon', 'mass_g')
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g), ]
# Genus/family typical values (BodyMass-Source 'GenAvg', BodyMass-SpecLevel 0)
# and values copied from another species are not species-specific. 'PrimScale'
# masses (a measured length of the species through a family-level mass-length
# relationship) are kept as allometry-derived values; records flagged
# 'DataFromSplit' in Record-Comment are kept pending issue #5.
adat <- DropImputed(adat,
                    adat$BodyMass.Source == 'GenAvg' | adat$BodyMass.SpecLevel %in% 0 |
                      grepl('^Copied', adat$BodyMass.Comment),
                    'Wilman_etal_2014',
                    'GenAvg genus/family average or value copied from another species')
adat <- adat[, c('taxon', 'mass_g')]
adat$n <- 1
adat$source_mass <- 'Wilman_etal_2014'
adat <- merge(adat, taxon_tax, by = 'taxon', all.x = TRUE)
WI <- adat
save(WI, file = file.path(wd_rdata, 'BodyMass_Wilman_etal_2014.Rdata'))
