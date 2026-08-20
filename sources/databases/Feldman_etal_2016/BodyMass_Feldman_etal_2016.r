adat <- read.csv(file.path(wd_source, 'Appendix S1 - Lepidosaur body sizes.csv'), header = TRUE)
adat <- adat[, c('binomial', 'mass..g.')]
colnames(adat) <- c('taxon', 'mass_g')
adat <- FixNames(adat)
adat <- adat[!is.na(adat$mass_g), ]
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Feldman_etal_2016'
FE <- adat
save(FE, file = file.path(wd_rdata, 'BodyMass_Feldman_etal_2016.Rdata'))
