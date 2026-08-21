adat <- read.csv(file.path(wd_source, 'Eklof_etal_2017.csv'), header = TRUE)
adat <- adat[, c('Taxa', 'DW')]
colnames(adat) <- c('taxon', 'mass_g')
adat <- adat[!is.na(adat$mass_g), ]
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Eklof_etal_2017'
EK <- adat
save(EK, file = file.path(wd_rdata, 'BodyMass_Eklof_etal_2017.Rdata'))
