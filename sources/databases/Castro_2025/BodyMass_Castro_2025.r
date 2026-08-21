adat <- read.csv(file.path(wd_source, 'FieldMR_SciDataPub.csv'), header = TRUE)
adat <- adat[, c('SpeciesAcceptedName', 'Mass_g')]
colnames(adat) <- c('taxon', 'mass_g')
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g), ]
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Castro_2025'
CA <- adat
save(CA, file = file.path(wd_rdata, 'BodyMass_Castro_2025.Rdata'))
