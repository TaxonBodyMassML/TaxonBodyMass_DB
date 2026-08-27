adat <- read.csv(file.path(wd_source, 'TableS1.csv'), header = TRUE)
taxon_tax <- adat[, c('species', 'order', 'family')]
taxon_tax <- taxon_tax[!duplicated(taxon_tax$species), ]
taxon_tax$order  <- iconv(as.character(taxon_tax$order),  to = 'ASCII//TRANSLIT')
taxon_tax$family <- iconv(as.character(taxon_tax$family), to = 'ASCII//TRANSLIT')
names(taxon_tax)[1] <- 'taxon'
adat <- adat[, c('species', 'MMRmass')]
colnames(adat) <- c('taxon', 'mass_g')
adat <- adat[!is.na(adat$mass_g), ]
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Killen_etal_2016'
adat <- merge(adat, taxon_tax, by = 'taxon', all.x = TRUE)
KI <- adat
save(KI, file = file.path(wd_rdata, 'BodyMass_Killen_etal_2016.Rdata'))
