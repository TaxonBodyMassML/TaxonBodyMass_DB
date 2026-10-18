adat <- read.csv(file.path(wd_source, 'Gillooly_etal_2016.csv'), header = TRUE)
adat$taxon <- paste(adat$Genus, adat$Species)
# M column: body mass (g); M.1 column: mass reference (negative integer index)
adat <- adat[, c('taxon', 'M', 'M.1')]
colnames(adat) <- c('taxon', 'mass_g', 'ref_idx')
# Convert negative integer index to string key matching references.csv
adat$ref_keys <- ifelse(!is.na(adat$ref_idx) & adat$ref_idx != 0,
                        as.character(abs(adat$ref_idx)),
                        NA_character_)
adat <- adat[!is.na(adat$mass_g), ]
adat$n <- 1
adat$source_mass <- 'Gillooly_etal_2016'
GI <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'ref_keys')]
save(GI, file = file.path(wd_rdata, 'BodyMass_Gillooly_etal_2016.Rdata'))
