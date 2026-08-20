adat <- read.csv(file.path(wd_source, 'AmphiBIO_v1.csv'), header = TRUE)
adat <- adat[, c('Species', 'Body_mass_g')]
colnames(adat) <- c('taxon', 'mass_g')
adat <- adat[!is.na(adat$mass_g), ]
adat <- FixNames(adat)
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'AmphiBIO'
AM <- adat
save(AM, file = file.path(wd_rdata, 'BodyMass_AmphiBIO.Rdata'))
