adat <- read.csv(file.path(wd_source, 'MOMv10.2.csv'))
adat <- adat[, c('Genus', 'Species', 'Combined.Mass..g.')]
adat$taxon <- paste(adat$Genus, adat$Species, sep = '_')
colnames(adat)[3] <- 'mass_g'
adat <- adat[, c('taxon', 'mass_g')]
adat <- FixNames(adat)
adat <- adat[which(adat$mass_g != -999), ]
adat <- adat[!is.na(adat$mass_g), ]
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Smith_2003'
MM <- adat
save(MM, file = file.path(wd_rdata, 'BodyMass_Smith_2003.Rdata'))
