adat <- read.csv(file.path(wd_source, 'wstdb-1785518160391.csv'), header = TRUE)
adat <- adat[, c('genus', 'species', 'trait', 'value')]
adat$taxon <- paste(adat$genus, adat$species)
adat <- subset(adat, trait == 'bodm')
adat <- adat[, c('taxon', 'value')]
colnames(adat) <- c('taxon', 'mass_g')
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g), ]
adat <- FixNames(adat)
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Pekar_etal_2021'
PE <- adat
save(PE, file = file.path(wd_rdata, 'BodyMass_Pekar_etal_2021.Rdata'))
