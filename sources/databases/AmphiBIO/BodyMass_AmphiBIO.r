adat <- read.csv(file.path(wd_source, 'AmphiBIO_v1.csv'), header = TRUE)
taxon_tax <- adat[, c('Species', 'Order', 'Family')]
taxon_tax <- taxon_tax[!duplicated(taxon_tax$Species), ]
taxon_tax$order  <- iconv(as.character(taxon_tax$Order),  to = 'ASCII//TRANSLIT')
taxon_tax$family <- iconv(as.character(taxon_tax$Family), to = 'ASCII//TRANSLIT')
names(taxon_tax)[1] <- 'taxon'
taxon_tax <- taxon_tax[, c('taxon', 'order', 'family')]
adat <- adat[, c('Species', 'Body_mass_g')]
colnames(adat) <- c('taxon', 'mass_g')
adat <- adat[!is.na(adat$mass_g), ]
adat$n <- 1
adat$source_mass <- 'AmphiBIO'
adat <- merge(adat, taxon_tax, by = 'taxon', all.x = TRUE)
AM <- adat
save(AM, file = file.path(wd_rdata, 'BodyMass_AmphiBIO.Rdata'))
