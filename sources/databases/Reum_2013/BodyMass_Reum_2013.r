adat <- read.csv(file.path(wd_source, 'Reum_2013_Appendix2_BodyMass.csv'), header = TRUE)
adat <- adat[, c('Species', 'MeanMass_g')]
colnames(adat) <- c('taxon', 'mass_g')
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g), ]
adat <- FixNames(adat)
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Reum_2013'
REb <- adat
save(REb, file = file.path(wd_rdata, 'BodyMass_Reum_2013.Rdata'))
