adat <- read.csv(file.path(wd_source, 'oo_32985.csv'), skip = 3, header = TRUE)
adat <- adat[, c('Species', 'Adult.body.mass')]
colnames(adat) <- c('taxon', 'mass_g')
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g), ]
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Trochet_2014'
TR <- adat
save(TR, file = file.path(wd_rdata, 'BodyMass_Trochet_2014.Rdata'))
