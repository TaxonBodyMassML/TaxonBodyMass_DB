adat <- read.csv(file.path(wd_source, 'Reum_2012.csv'), header = TRUE)
adat <- adat[, c('species', 'mean_mass_g')]
colnames(adat) <- c('taxon', 'mass_g')
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g), ]
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Reum_2012'
REa <- adat
save(REa, file = file.path(wd_rdata, 'BodyMass_Reum_2012.Rdata'))
