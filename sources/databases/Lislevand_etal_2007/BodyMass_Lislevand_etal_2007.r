adat <- read.table(file.path(wd_source, 'avian_ssd_jan07.txt'), sep = '\t', header = TRUE)
taxon_tax <- adat[, c('Species_name', 'Family')]
taxon_tax <- taxon_tax[!duplicated(taxon_tax$Species_name), ]
taxon_tax$family <- iconv(as.character(taxon_tax$Family), to = 'ASCII//TRANSLIT')
names(taxon_tax)[1] <- 'taxon'
taxon_tax <- taxon_tax[, c('taxon', 'family')]
adat <- adat[, c('Species_name', 'M_mass', 'F_mass', 'unsexed_mass')]
colnames(adat)[1] <- 'taxon'
adat[which(adat == '-999', arr.ind = TRUE)] <- NA
adat$mass_g <- apply(adat[, -1], 1, mean, na.rm = TRUE)
adat <- adat[, c('taxon', 'mass_g')]
adat <- adat[!is.nan(adat$mass_g), ]
adat$n <- 1
adat$source_mass <- 'Lislevand_etal_2007'
adat <- merge(adat, taxon_tax, by = 'taxon', all.x = TRUE)
LI <- adat
save(LI, file = file.path(wd_rdata, 'BodyMass_Lislevand_etal_2007.Rdata'))
