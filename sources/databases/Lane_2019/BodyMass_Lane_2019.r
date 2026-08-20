adat <- read.csv(file.path(wd_source, 'PRSB_data.csv'), header = TRUE, skip = 3)
colnames(adat)[1:2] <- c('taxon', 'mass_g')
for (i in 2:nrow(adat)) {
  if (adat$taxon[i] == '') adat$taxon[i] <- adat$taxon[i - 1]
}
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g), ]
adat <- adat[, c('taxon', 'mass_g')]
adat <- FixNames(adat)
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Lane_2019'
LA <- adat
save(LA, file = file.path(wd_rdata, 'BodyMass_Lane_2019.Rdata'))
