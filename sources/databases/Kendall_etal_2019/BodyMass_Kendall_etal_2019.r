# pollimetry (Kendall et al. 2019, Ecology and Evolution 9:1702-1714): the measured
# specimen dataset shipped with the R package (data/pollimetry_dataset.rdata,
# GitHub liamkendall/pollimetry; package archived from CRAN 2025). One row per
# specimen: Species (Genus_species), Spec.wgt = specimen dry weight (mg).
# The package's allometric predictions are NOT used here, only measured weights.
load(file.path(wd_source, 'pollimetry_dataset.rdata'))   # loads pollimetry_dataset
adat <- pollimetry_dataset
adat$taxon <- gsub('_', ' ', as.character(adat$Species))
adat <- adat[, c('taxon', 'Spec.wgt', 'Family')]
colnames(adat) <- c('taxon', 'mass_g', 'family')
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g)) / 1000   # mg -> g (dry)
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
adat <- adat[!grepl('\\b(sp|spp|cf|aff|indet)\\b', adat$taxon), ]
adat$family <- as.character(adat$family)
adat$class <- 'Insecta'
mass_group <- 'insect'
adat$mass_g <- ToWetMass(adat$mass_g, from = 'dry', group = mass_group)
adat$n <- 1
adat$source_mass <- 'Kendall_etal_2019'
KEN <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'class', 'family')]
save(KEN, file = file.path(wd_rdata, 'BodyMass_Kendall_etal_2019.Rdata'))
