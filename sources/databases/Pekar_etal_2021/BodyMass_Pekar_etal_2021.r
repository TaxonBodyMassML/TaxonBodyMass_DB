adat <- read.csv(file.path(wd_source, 'wstdb-1785518160391.csv'), header = TRUE)
taxon_tax <- adat[adat$trait == 'bodm' & !is.na(adat$genus) & !is.na(adat$species),
                  c('genus', 'species', 'family')]
taxon_tax$taxon  <- paste(taxon_tax$genus, taxon_tax$species)
taxon_tax$family <- iconv(as.character(taxon_tax$family), to = 'ASCII//TRANSLIT')
taxon_tax <- taxon_tax[!duplicated(taxon_tax$taxon), c('taxon', 'family')]
adat <- adat[, c('genus', 'species', 'trait', 'value')]
adat$taxon <- paste(adat$genus, adat$species)
adat <- subset(adat, trait == 'bodm')
adat <- adat[, c('taxon', 'value')]
colnames(adat) <- c('taxon', 'mass_g')
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g), ]
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Pekar_etal_2021'
adat <- merge(adat, taxon_tax, by = 'taxon', all.x = TRUE)
PE <- adat
save(PE, file = file.path(wd_rdata, 'BodyMass_Pekar_etal_2021.Rdata'))
