adat <- read.csv(file.path(wd_source, 'AndersonGillooly_2017_EER_data.csv'))
adat <- adat[, c('Species', 'Mass_g')]
colnames(adat) <- c('taxon', 'mass_g')
adat <- FixNames(adat)
adat <- adat[!is.na(adat$mass_g), ]
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'AndersonGillooly_2017'
AG <- adat
save(AG, file = file.path(wd_rdata, 'BodyMass_AndersonGillooly_2017.Rdata'))
