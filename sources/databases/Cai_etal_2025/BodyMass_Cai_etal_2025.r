adat <- read.csv(file.path(wd_source, 'Dataset S27.csv'), skip = 1, header = TRUE)
adat$taxon <- adat$Species
taxon_tax <- adat[, c('taxon', 'Class', 'Order', 'Family')]
taxon_tax <- taxon_tax[!duplicated(taxon_tax$taxon), ]
taxon_tax$class  <- iconv(as.character(taxon_tax$Class),  to = 'ASCII//TRANSLIT')
taxon_tax$order  <- iconv(as.character(taxon_tax$Order),  to = 'ASCII//TRANSLIT')
taxon_tax$family <- iconv(as.character(taxon_tax$Family), to = 'ASCII//TRANSLIT')
taxon_tax <- taxon_tax[, c('taxon', 'class', 'order', 'family')]
adat <- adat[, c('taxon', 'BodyMass..g.')]
colnames(adat) <- c('taxon', 'mass_g')
adat <- adat[!is.na(adat$mass_g), ]
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Cai_etal_2025'
adat <- merge(adat, taxon_tax, by = 'taxon', all.x = TRUE)
CA <- adat
save(CA, file = file.path(wd_rdata, 'BodyMass_Cai_etal_2025.Rdata'))
