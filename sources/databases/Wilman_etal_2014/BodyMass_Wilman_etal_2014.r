adat <- read.csv(file.path(wd_source, 'BirdFuncDat.txt'), header = TRUE, sep = '\t')
taxon_tax <- adat[, c('Scientific', 'IOCOrder', 'BLFamilyLatin')]
taxon_tax <- taxon_tax[!duplicated(taxon_tax$Scientific), ]
taxon_tax$order  <- iconv(as.character(taxon_tax$IOCOrder),     to = 'ASCII//TRANSLIT')
taxon_tax$family <- iconv(as.character(taxon_tax$BLFamilyLatin), to = 'ASCII//TRANSLIT')
names(taxon_tax)[1] <- 'taxon'
taxon_tax <- taxon_tax[, c('taxon', 'order', 'family')]
adat <- adat[, c('Scientific', 'BodyMass.Value')]
colnames(adat) <- c('taxon', 'mass_g')
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g), ]
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Wilman_etal_2014'
adat <- merge(adat, taxon_tax, by = 'taxon', all.x = TRUE)
WI <- adat
save(WI, file = file.path(wd_rdata, 'BodyMass_Wilman_etal_2014.Rdata'))
