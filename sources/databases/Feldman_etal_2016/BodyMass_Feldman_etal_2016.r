adat <- read.csv(file.path(wd_source, 'Appendix S1 - Lepidosaur body sizes.csv'), header = TRUE)
taxon_tax <- adat[, c('binomial', 'Order', 'Family')]
taxon_tax <- taxon_tax[!duplicated(taxon_tax$binomial), ]
taxon_tax$order  <- iconv(as.character(taxon_tax$Order),  to = 'ASCII//TRANSLIT')
taxon_tax$family <- iconv(as.character(taxon_tax$Family), to = 'ASCII//TRANSLIT')
names(taxon_tax)[1] <- 'taxon'
taxon_tax <- taxon_tax[, c('taxon', 'order', 'family')]
adat <- adat[, c('binomial', 'mass..g.')]
colnames(adat) <- c('taxon', 'mass_g')
adat <- adat[!is.na(adat$mass_g), ]
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Feldman_etal_2016'
adat <- merge(adat, taxon_tax, by = 'taxon', all.x = TRUE)
FE <- adat
save(FE, file = file.path(wd_rdata, 'BodyMass_Feldman_etal_2016.Rdata'))
