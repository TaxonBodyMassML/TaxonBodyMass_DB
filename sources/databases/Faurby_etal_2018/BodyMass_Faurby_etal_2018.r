adat <- read.csv(file.path(wd_source, 'Trait_data.csv'), header = TRUE)
taxon_tax <- adat[, c('Binomial.1.2', 'Order.1.2', 'Family.1.2')]
taxon_tax <- taxon_tax[!duplicated(taxon_tax$Binomial.1.2), ]
taxon_tax$order  <- iconv(as.character(taxon_tax$Order.1.2),  to = 'ASCII//TRANSLIT')
taxon_tax$family <- iconv(as.character(taxon_tax$Family.1.2), to = 'ASCII//TRANSLIT')
names(taxon_tax)[1] <- 'taxon'
taxon_tax <- taxon_tax[, c('taxon', 'order', 'family')]
adat <- adat[, c('Binomial.1.2', 'Mass.g')]
colnames(adat) <- c('taxon', 'mass_g')
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g), ]
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Faurby_etal_2018'
adat <- merge(adat, taxon_tax, by = 'taxon', all.x = TRUE)
FA <- adat
save(FA, file = file.path(wd_rdata, 'BodyMass_Faurby_etal_2018.Rdata'))
