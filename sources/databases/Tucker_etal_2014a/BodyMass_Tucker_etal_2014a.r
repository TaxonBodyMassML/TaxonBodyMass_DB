adat <- read.csv(file.path(wd_source, 'TrophicLevel_Appendix1.csv'), header = TRUE)
adat <- adat[, c('Taxon', 'Mass..log10.kg.')]
colnames(adat) <- c('taxon', 'mass_g')
adat$mass_g <- (10^adat$mass_g) * 1000
adat <- adat[!is.na(adat$mass_g), ]
adat$n <- 1
adat$source_mass <- 'Tucker_etal_2014a'
TU1 <- adat
save(TU1, file = file.path(wd_rdata, 'BodyMass_Tucker_etal_2014a.Rdata'))
