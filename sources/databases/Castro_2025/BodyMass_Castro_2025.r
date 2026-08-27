adat <- read.csv(file.path(wd_source, 'FieldMR_SciDataPub.csv'), header = TRUE)
taxon_tax <- adat[, c('SpeciesAcceptedName', 'Kingdom', 'Phylum', 'Class', 'Order', 'Family')]
taxon_tax <- taxon_tax[!duplicated(taxon_tax$SpeciesAcceptedName), ]
taxon_tax$kingdom <- iconv(as.character(taxon_tax$Kingdom), to = 'ASCII//TRANSLIT')
taxon_tax$phylum  <- iconv(as.character(taxon_tax$Phylum),  to = 'ASCII//TRANSLIT')
taxon_tax$class   <- iconv(as.character(taxon_tax$Class),   to = 'ASCII//TRANSLIT')
taxon_tax$order   <- iconv(as.character(taxon_tax$Order),   to = 'ASCII//TRANSLIT')
taxon_tax$family  <- iconv(as.character(taxon_tax$Family),  to = 'ASCII//TRANSLIT')
names(taxon_tax)[1] <- 'taxon'
taxon_tax <- taxon_tax[, c('taxon', 'kingdom', 'phylum', 'class', 'order', 'family')]
adat <- adat[, c('SpeciesAcceptedName', 'Mass_g')]
colnames(adat) <- c('taxon', 'mass_g')
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g), ]
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Castro_2025'
adat <- merge(adat, taxon_tax, by = 'taxon', all.x = TRUE)
CA <- adat
save(CA, file = file.path(wd_rdata, 'BodyMass_Castro_2025.Rdata'))
