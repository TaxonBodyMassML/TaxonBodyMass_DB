adat1 <- read.csv(file.path(wd_source, 'TableS1.csv'), skip = 1, header = TRUE)
adat1 <- adat1[, c('X.1', 'Mean.2')]
adat2 <- read.csv(file.path(wd_source, 'TableS5.csv'), header = TRUE)
adat2 <- adat2[, c('Latin.name', 'W..g.')]
colnames(adat1) <- colnames(adat2) <- c('taxon', 'mass_g')
adat <- rbind(adat1, adat2)
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g), ]
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Mahe_2023'
MAH <- adat
save(MAH, file = file.path(wd_rdata, 'BodyMass_Mahe_2023.Rdata'))
