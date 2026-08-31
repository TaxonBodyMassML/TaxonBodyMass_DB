adat <- read.csv(file.path(wd_source, 'Jennings_2002.csv'))
adat <- adat[, c('Species', 'Mean_mass_g')]
colnames(adat) <- c('taxon', 'mass_g')
adat <- adat[!is.na(adat$mass_g), ]
adat$n <- 1
adat$source_mass <- 'Jennings_2002'
JE <- adat
save(JE, file = file.path(wd_rdata, 'BodyMass_Jennings_2002.Rdata'))
