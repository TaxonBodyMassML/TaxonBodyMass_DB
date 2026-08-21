adat <- read.csv(file.path(wd_source, 'Trait_data.csv'), header = TRUE)
adat <- adat[, c('Binomial.1.2', 'Mass.g')]
colnames(adat) <- c('taxon', 'mass_g')
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g), ]
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Faurby_etal_2018'
FA <- adat
save(FA, file = file.path(wd_rdata, 'BodyMass_Faurby_etal_2018.Rdata'))
