adat <- read.csv(file.path(wd_source, 'Dataset S27.csv'), skip = 1, header = TRUE)
adat$taxon <- adat$Species
adat <- adat[, c('taxon', 'BodyMass..g.')]
colnames(adat) <- c('taxon', 'mass_g')
adat <- adat[!is.na(adat$mass_g), ]
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Cai_etal_2025'
CA <- adat
save(CA, file = file.path(wd_rdata, 'BodyMass_Cai_etal_2025.Rdata'))
