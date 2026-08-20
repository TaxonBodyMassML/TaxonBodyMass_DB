adat <- read.csv(file.path(wd_source, 'BirdFuncDat.txt'), header = TRUE, sep = '\t')
adat <- adat[, c('Scientific', 'BodyMass.Value')]
colnames(adat) <- c('taxon', 'mass_g')
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g), ]
adat <- FixNames(adat)
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Wilman_etal_2014'
WI <- adat
save(WI, file = file.path(wd_rdata, 'BodyMass_Wilman_etal_2014.Rdata'))
