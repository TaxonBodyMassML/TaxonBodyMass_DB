adat <- read.csv(file.path(wd_source, 'BodyMass.csv'), header = TRUE)
adat <- adat[, c('Species..ITIS.', 'BodyMass_kg')]
adat$BodyMass_kg <- adat$BodyMass_kg * 1000
colnames(adat) <- c('taxon', 'mass_g')
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g), ]
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'GalanAcedo_etal_2026'
GA <- adat
save(GA, file = file.path(wd_rdata, 'BodyMass_GalanAcedo_etal_2026.Rdata'))
