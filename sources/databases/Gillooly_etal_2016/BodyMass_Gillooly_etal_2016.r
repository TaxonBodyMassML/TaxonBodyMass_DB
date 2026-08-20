adat <- read.csv(file.path(wd_source, 'Gillooly_etal_2016.csv'), header = TRUE)
adat$taxon <- paste(adat$Genus, adat$Species)
adat <- adat[, c('taxon', 'M')]
colnames(adat) <- c('taxon', 'mass_g')
adat <- FixNames(adat)
adat <- adat[!is.na(adat$mass_g), ]
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Gillooly_etal_2016'
GI <- adat
save(GI, file = file.path(wd_rdata, 'BodyMass_Gillooly_etal_2016.Rdata'))
