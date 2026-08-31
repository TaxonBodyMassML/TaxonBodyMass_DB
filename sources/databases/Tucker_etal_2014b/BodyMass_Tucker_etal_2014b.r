adat <- read.csv(file.path(wd_source, 'Tucker_etal_2014b.csv'), header = TRUE)
adat <- adat[, c('Taxon', 'log10.Mass..kg.')]
colnames(adat) <- c('taxon', 'mass_g')
adat$mass_g <- (10^adat$mass_g) * 1000
adat <- adat[!is.na(adat$mass_g), ]
adat$n <- 1
adat$source_mass <- 'Tucker_etal_2014b'
TU2 <- adat
save(TU2, file = file.path(wd_rdata, 'BodyMass_Tucker_etal_2014b.Rdata'))
