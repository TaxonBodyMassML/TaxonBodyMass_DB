adat <- read.table(file.path(wd_source, 'Cyclothone_body_mass_density.tab'),
                   sep = '\t', header = TRUE, skip = 50)
adat <- adat[, c('Species.UID..Visual.observation.', 'Wet.m..mg...Fish..wet.weighed.')]
colnames(adat) <- c('taxon', 'mass_g')
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g)) / 1000
adat <- adat[!is.na(adat$mass_g), ]
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Sarmiento-Lezcano_2023'
SA <- adat
save(SA, file = file.path(wd_rdata, 'BodyMass_Sarmiento-Lezcano_2023.Rdata'))
