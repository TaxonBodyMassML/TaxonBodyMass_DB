adat <- read.csv(file.path(wd_source, 'FoRAGE_db_12_19_18_data_set.csv'), header = TRUE)
adat1 <- adat[, c('Predator.scientific.name', 'Predator.mass..mg.')]
colnames(adat1) <- c('taxon', 'mass_mg')
adat2 <- adat[, c('Prey.scientific.name', 'Prey.mass..mg.')]
colnames(adat2) <- c('taxon', 'mass_mg')
adat <- rbind(adat1, adat2)
adat$mass_g <- adat$mass_mg / 1000
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g), ]
adat <- FixNames(adat)
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'DeLong_etal_2018'
DLb <- adat
save(DLb, file = file.path(wd_rdata, 'BodyMass_DeLong_etal_2018.Rdata'))
