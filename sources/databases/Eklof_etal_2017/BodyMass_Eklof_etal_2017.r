adat <- read.csv(file.path(wd_source, 'Eklof_etal_2017.csv'), header = TRUE)
taxon_tax <- adat[, c('Taxa', 'Class')]
taxon_tax <- taxon_tax[!duplicated(taxon_tax$Taxa), ]
taxon_tax$class <- iconv(as.character(taxon_tax$Class), to = 'ASCII//TRANSLIT')
names(taxon_tax)[1] <- 'taxon'
taxon_tax <- taxon_tax[, c('taxon', 'class')]
adat <- adat[, c('Taxa', 'DW')]
colnames(adat) <- c('taxon', 'mass_g')
adat <- adat[!is.na(adat$mass_g), ]
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Eklof_etal_2017'
adat <- merge(adat, taxon_tax, by = 'taxon', all.x = TRUE)
EK <- adat
save(EK, file = file.path(wd_rdata, 'BodyMass_Eklof_etal_2017.Rdata'))
