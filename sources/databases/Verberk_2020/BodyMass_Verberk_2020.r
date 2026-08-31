adat <- read.csv(file.path(wd_source, 'Diving_dataset.csv'), header = TRUE)
adat <- adat[, c('Species', 'Mass..kg.')]
colnames(adat) <- c('taxon', 'mass_g')
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g)) * 1000
adat <- adat[!is.na(adat$mass_g), ]
adat$n <- 1
adat$source_mass <- 'Verberk_2020'
VE <- adat
save(VE, file = file.path(wd_rdata, 'BodyMass_Verberk_2020.Rdata'))
