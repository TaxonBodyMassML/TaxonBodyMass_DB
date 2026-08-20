adat <- read.csv(
  file.path(wd_source, 'data_input', 'Trait_dataset_level2',
            'trait_dataset_level2-2023-09-14.csv'),
  header = TRUE
)
adat <- adat[, c('scientificName', 'traitName', 'traitValue', 'traitUnit')]
adat <- subset(adat, traitName == 'wetWeight')
adat$traitValue <- as.numeric(adat$traitValue) / 1000
adat <- adat[, c('scientificName', 'traitValue')]
colnames(adat) <- c('taxon', 'mass_g')
adat <- adat[!is.na(adat$mass_g), ]
adat <- FixNames(adat)
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Pata_2025'
PA <- adat
save(PA, file = file.path(wd_rdata, 'BodyMass_Pata_2025.Rdata'))
