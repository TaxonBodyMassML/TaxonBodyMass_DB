adat <- read.csv(
  file.path(wd_source, 'data_input', 'Trait_dataset_level2',
            'trait_dataset_level2-2023-09-14.csv'),
  header = TRUE
)
taxon_tax <- adat[adat$traitName == 'wetWeight' & !is.na(adat$scientificName),
                  c('scientificName', 'kingdom', 'phylum', 'class', 'order', 'family')]
taxon_tax <- taxon_tax[!duplicated(taxon_tax$scientificName), ]
for (col in c('kingdom', 'phylum', 'class', 'order', 'family')) {
  taxon_tax[[col]] <- iconv(as.character(taxon_tax[[col]]), to = 'ASCII//TRANSLIT')
}
names(taxon_tax)[1] <- 'taxon'
adat <- adat[, c('scientificName', 'traitName', 'traitValue', 'traitUnit')]
adat <- subset(adat, traitName == 'wetWeight')
adat$traitValue <- as.numeric(adat$traitValue) / 1000
adat <- adat[, c('scientificName', 'traitValue')]
colnames(adat) <- c('taxon', 'mass_g')
adat <- adat[!is.na(adat$mass_g), ]
adat <- ddply(adat, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
adat$source_mass <- 'Pata_2025'
adat <- merge(adat, taxon_tax, by = 'taxon', all.x = TRUE)
PA <- adat
save(PA, file = file.path(wd_rdata, 'BodyMass_Pata_2025.Rdata'))
