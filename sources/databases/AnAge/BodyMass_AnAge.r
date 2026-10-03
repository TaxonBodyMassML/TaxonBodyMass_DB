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
# `Adult weight (g)` is the species' adult body mass (the 'Adult weight' of the
# Life history traits section of an AnAge entry). `Body mass (g)` is the mass of
# the specimens whose `Metabolic rate (W)` is reported (the 'Body mass' of the
# Metabolism section, e.g. Mus musculus 18.0 g vs an adult weight of 20.5 g) and
# is largely copied from the same compilations as Makarieva_2008,
# Uyeda_etal_2017 and Hoehler_etal_2023, so it is not used, not even as a
# fallback where the adult weight is missing (#15; see README.md).
adat <- adat[, c('taxon', 'Adult.weight..g.', 'Body.mass..g.')]
colnames(adat) <- c('taxon', 'mass_g', 'mr.mass_g')
adat <- adat[!is.na(adat$mass_g) | !is.na(adat$mr.mass_g), ]
adat <- DropImputed(adat, is.na(adat$mass_g) & !is.na(adat$mr.mass_g), 'AnAge',
                    'metabolic-rate body mass only, no adult weight')
adat <- adat[, c('taxon', 'mass_g')]
adat$n <- 1
adat$source_mass <- 'AnAge'
adat <- merge(adat, taxon_tax, by = 'taxon', all.x = TRUE)
AN <- adat[!is.na(adat$mass_g), ]
save(AN, file = file.path(wd_rdata, 'BodyMass_AnAge.Rdata'))
