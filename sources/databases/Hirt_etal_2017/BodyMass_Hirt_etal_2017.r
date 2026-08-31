adat <- read.csv(file.path(wd_source, 'Hirt_etal_2017.csv'), header = TRUE)
adat <- adat[, c('species', 'body.mass..kg.')]
colnames(adat) <- c('taxon', 'mass_g')
adat$mass_g <- adat$mass_g * 1000
adat <- adat[!is.na(adat$mass_g), ]
adat$n <- 1
adat$source_mass <- 'Hirt_etal_2017'
HI <- adat
save(HI, file = file.path(wd_rdata, 'BodyMass_Hirt_etal_2017.Rdata'))
