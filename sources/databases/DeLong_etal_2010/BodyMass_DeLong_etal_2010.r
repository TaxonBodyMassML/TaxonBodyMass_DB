adat1 <- read.csv(file.path(wd_source, 'sd01.csv'), header = TRUE)
adat2 <- read.csv(file.path(wd_source, 'sd02.csv'), header = TRUE)
adat1 <- adat1[, c('species', 'mass_g')]
adat2 <- adat2[, c('species', 'body_mass_g')]
colnames(adat2)[2] <- 'mass_g'
adat <- rbind(adat1, adat2)
colnames(adat)[1] <- 'taxon'
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g), ]
adat$n <- 1
adat$source_mass <- 'DeLong_etal_2010'
DLa <- adat
save(DLa, file = file.path(wd_rdata, 'BodyMass_DeLong_etal_2010.Rdata'))
