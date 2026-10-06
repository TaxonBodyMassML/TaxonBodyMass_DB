# Lislevand, Figuerola & Szekely (2007) Ecology 88:1605 (Ecological Archives
# E088-096), avian_ssd_jan07.txt: body mass (g) of males (M_mass), females
# (F_mass) and unsexed birds (unsexed_mass), -999 for missing; the record's
# mass is the mean of the values given.
adat <- read.table(file.path(wd_source, 'avian_ssd_jan07.txt'), sep = '\t', header = TRUE, quote = '')
taxon_tax <- adat[, c('Species_name', 'Family')]
taxon_tax <- taxon_tax[!duplicated(taxon_tax$Species_name), ]
taxon_tax$family <- iconv(as.character(taxon_tax$Family), to = 'ASCII//TRANSLIT')
names(taxon_tax)[1] <- 'taxon'
taxon_tax <- taxon_tax[, c('taxon', 'family')]
# The per-record reference numbers (`References`, ';'-separated indices into
# the reference list of metadata.htm, section F, resolved in references.csv;
# several per row, cited for the whole row -- masses, egg mass, clutch size
# and behaviour alike -- so a record may carry a reference that supports
# another of its variables) are kept as `ref_keys` for the primary-source
# attribution of issue #1 (SplitRefKeys(), R/library/citations/).
ref_keys <- SplitRefKeys(adat$References, ';')
adat <- adat[, c('Species_name', 'M_mass', 'F_mass', 'unsexed_mass')]
colnames(adat)[1] <- 'taxon'
adat[which(adat == '-999', arr.ind = TRUE)] <- NA
adat$mass_g <- apply(adat[, -1], 1, mean, na.rm = TRUE)
adat$ref_keys <- ref_keys
adat <- adat[, c('taxon', 'mass_g', 'ref_keys')]
adat <- adat[!is.nan(adat$mass_g), ]
adat$n <- 1
adat$source_mass <- 'Lislevand_etal_2007'
adat <- merge(adat, taxon_tax, by = 'taxon', all.x = TRUE)
if (anyNA(adat$ref_keys)) warning('Lislevand_etal_2007: ', sum(is.na(adat$ref_keys)), ' record(s) without a reference number')
LI <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'family', 'ref_keys')]
save(LI, file = file.path(wd_rdata, 'BodyMass_Lislevand_etal_2007.Rdata'))
