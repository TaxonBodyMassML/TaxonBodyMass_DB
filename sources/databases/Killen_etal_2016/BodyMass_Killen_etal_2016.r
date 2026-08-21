adat <- read.csv(file.path(wd_source, 'TableS1.csv'), header = TRUE)
adat <- adat[, c('species', 'MMRmass')]
colnames(adat) <- c('taxon', 'mass_g')
adat <- adat[!is.na(adat$mass_g), ]
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Killen_etal_2016'
KI <- adat
save(KI, file = file.path(wd_rdata, 'BodyMass_Killen_etal_2016.Rdata'))
