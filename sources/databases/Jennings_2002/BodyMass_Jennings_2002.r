adat <- read.csv(file.path(wd_source, 'Jennings_2002.csv'))
adat <- adat[, c('Species', 'Mean_mass_g')]
colnames(adat) <- c('taxon', 'mass_g')
adat <- FixNames(adat)
adat <- adat[!is.na(adat$mass_g), ]
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Jennings_2002'
JE <- adat
save(JE, file = file.path(wd_rdata, 'BodyMass_Jennings_2002.Rdata'))
