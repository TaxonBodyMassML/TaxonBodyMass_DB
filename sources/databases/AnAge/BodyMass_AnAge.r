adat <- read.csv(file.path(wd_source, 'AnAge_data.csv'), header = TRUE)
adat$taxon <- paste(adat$Genus, adat$Species)
taxon_tax <- adat[, c('taxon', 'Kingdom', 'Phylum', 'Class', 'Order', 'Family')]
taxon_tax <- taxon_tax[!duplicated(taxon_tax$taxon), ]
taxon_tax$kingdom <- iconv(as.character(taxon_tax$Kingdom), to = 'ASCII//TRANSLIT')
taxon_tax$phylum  <- iconv(as.character(taxon_tax$Phylum),  to = 'ASCII//TRANSLIT')
taxon_tax$class   <- iconv(as.character(taxon_tax$Class),   to = 'ASCII//TRANSLIT')
taxon_tax$order   <- iconv(as.character(taxon_tax$Order),   to = 'ASCII//TRANSLIT')
taxon_tax$family  <- iconv(as.character(taxon_tax$Family),  to = 'ASCII//TRANSLIT')
taxon_tax <- taxon_tax[, c('taxon', 'kingdom', 'phylum', 'class', 'order', 'family')]
adat <- adat[, c('taxon', 'Adult.weight..g.', 'Body.mass..g.')]
colnames(adat) <- c('taxon', 'a.mass_g', 'mass_g')
adat$mass_g[is.na(adat$mass_g) & !is.na(adat$a.mass_g)] <-
  adat$a.mass_g[is.na(adat$mass_g) & !is.na(adat$a.mass_g)]
adat <- adat[!is.na(adat$mass_g), ]
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'AnAge'
adat <- merge(adat, taxon_tax, by = 'taxon', all.x = TRUE)
AN <- adat[!is.na(adat$mass_g), ]
save(AN, file = file.path(wd_rdata, 'BodyMass_AnAge.Rdata'))
