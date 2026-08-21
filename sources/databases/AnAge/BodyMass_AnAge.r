adat <- read.csv(file.path(wd_source, 'AnAge_data.csv'), header = TRUE)
adat$taxon <- paste(adat$Genus, adat$Species)
adat <- adat[, c('taxon', 'Adult.weight..g.', 'Body.mass..g.')]
colnames(adat) <- c('taxon', 'a.mass_g', 'mass_g')
adat$mass_g[is.na(adat$mass_g) & !is.na(adat$a.mass_g)] <-
  adat$a.mass_g[is.na(adat$mass_g) & !is.na(adat$a.mass_g)]
adat <- adat[!is.na(adat$mass_g), ]
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'AnAge'
AN <- adat[!is.na(adat$mass_g), ]
save(AN, file = file.path(wd_rdata, 'BodyMass_AnAge.Rdata'))
