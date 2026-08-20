adat <- read.csv(file.path(wd_source, 'Pauly_2024_AppendixTable1.csv'), header = TRUE)
adat <- adat[, c('Species', 'Weight_g')]
colnames(adat) <- c('taxon', 'mass_g')
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g), ]
adat <- FixNames(adat)
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Pauly_2024'
PAU <- adat
save(PAU, file = file.path(wd_rdata, 'BodyMass_Pauly_2024.Rdata'))
