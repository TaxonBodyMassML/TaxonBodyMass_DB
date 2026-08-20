adat <- read.csv(file.path(wd_source, 'appendixA.csv'), header = TRUE)
adat <- adat[, c('Genus.name', 'Species.name', 'Adult.female.mass')]
adat$Genus.name   <- gsub("[^[:alnum:]]", "", adat$Genus.name)
adat$Species.name <- gsub("[^[:alnum:]]", "", adat$Species.name)
adat$taxon <- paste(adat$Genus.name, adat$Species.name)
adat <- adat[, c('taxon', 'Adult.female.mass')]
colnames(adat) <- c('taxon', 'mass_g')
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g), ]
adat <- FixNames(adat)
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Fisher_2001'
FI <- adat
save(FI, file = file.path(wd_rdata, 'BodyMass_Fisher_2001.Rdata'))
