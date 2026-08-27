adat <- read.csv(file.path(wd_source, 'MOMv10.2.csv'))
taxon_tax <- adat[, c('Genus', 'Species', 'Order', 'FAMILY')]
taxon_tax$taxon  <- paste(taxon_tax$Genus, taxon_tax$Species, sep = '_')
taxon_tax$order  <- iconv(as.character(taxon_tax$Order),  to = 'ASCII//TRANSLIT')
taxon_tax$family <- iconv(as.character(taxon_tax$FAMILY), to = 'ASCII//TRANSLIT')
taxon_tax <- taxon_tax[!duplicated(taxon_tax$taxon), c('taxon', 'order', 'family')]
adat <- adat[, c('Genus', 'Species', 'Combined.Mass..g.')]
adat$taxon <- paste(adat$Genus, adat$Species, sep = '_')
colnames(adat)[3] <- 'mass_g'
adat <- adat[, c('taxon', 'mass_g')]
adat <- adat[which(adat$mass_g != -999), ]
adat <- adat[!is.na(adat$mass_g), ]
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Smith_2003'
adat <- merge(adat, taxon_tax, by = 'taxon', all.x = TRUE)
MM <- adat
save(MM, file = file.path(wd_rdata, 'BodyMass_Smith_2003.Rdata'))
