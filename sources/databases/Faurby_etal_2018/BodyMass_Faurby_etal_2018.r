adat <- read.csv(file.path(wd_source, 'Trait_data.csv'), header = TRUE)
# Keep extant species only: drop IUCN status EP (extinct in prehistory),
# EX (extinct) and EW (extinct in the wild).
adat <- adat[!(adat$IUCN.Status.1.2 %in% c('EP', 'EX', 'EW')), ]
taxon_tax <- adat[, c('Binomial.1.2', 'Order.1.2', 'Family.1.2')]
taxon_tax <- taxon_tax[!duplicated(taxon_tax$Binomial.1.2), ]
taxon_tax$order  <- iconv(as.character(taxon_tax$Order.1.2),  to = 'ASCII//TRANSLIT')
taxon_tax$family <- iconv(as.character(taxon_tax$Family.1.2), to = 'ASCII//TRANSLIT')
names(taxon_tax)[1] <- 'taxon'
taxon_tax <- taxon_tax[, c('taxon', 'order', 'family')]
adat <- adat[, c('Binomial.1.2', 'Mass.g', 'Mass.Method')]
colnames(adat)[1:2] <- c('taxon', 'mass_g')
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g), ]
# Phylogenetically imputed masses and masses taken from a relative of suggested
# similar size are not species-specific. 'Reported' values and the 'Assumed
# isometric based on <dimension>' / 'Estimated based on equation from
# <dimension>' values (a measured dimension of the species scaled to mass) are
# kept, the latter as allometry-derived values.
adat <- DropImputed(adat,
                    adat$Mass.Method == 'Imputed' | grepl('^As relative', adat$Mass.Method),
                    'Faurby_etal_2018',
                    'Mass.Method Imputed or As relative of suggested similar size')
adat <- adat[, c('taxon', 'mass_g')]
adat$n <- 1
adat$source_mass <- 'Faurby_etal_2018'
adat <- merge(adat, taxon_tax, by = 'taxon', all.x = TRUE)
FA <- adat
save(FA, file = file.path(wd_rdata, 'BodyMass_Faurby_etal_2018.Rdata'))
