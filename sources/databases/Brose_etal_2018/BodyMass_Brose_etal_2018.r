adat <- read.csv(file.path(wd_source, '283_2_FoodWebDataBase_2018_12_10.csv'), header = TRUE)
adat1 <- adat[, c('con.taxonomy', 'con.mass.mean.g.')]
adat2 <- adat[, c('res.taxonomy', 'res.mass.mean.g.')]
colnames(adat1) <- colnames(adat2) <- c('taxon', 'mass_g')
adat <- rbind(adat1, adat2)
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g), ]
adat <- adat[adat$mass_g > 0, ]
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Brose_etal_2018'
BRO <- adat
save(BRO, file = file.path(wd_rdata, 'BodyMass_Brose_etal_2018.Rdata'))
