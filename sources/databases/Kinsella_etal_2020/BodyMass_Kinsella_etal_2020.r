# Kinsella et al. (2020) Ecology and Evolution 10:8394-8404. moth_data.csv
# (GitHub CallumJMacgregor/KinsellaBiomass, Zenodo 3786303): field-collected
# British moths, one row per specimen, DRY_MASS in mg. The modelled species
# estimates (FinalBiomassEstimates.csv) are deliberately not used.
adat <- read.csv(file.path(wd_source, 'moth_data.csv'), header = TRUE,
                 stringsAsFactors = FALSE, na.strings = c('', 'NA'))
adat <- adat[, c('BINOMIAL', 'DRY_MASS', 'FAMILY')]
colnames(adat) <- c('taxon', 'mass_g', 'family')
adat$taxon <- trimws(gsub('\\s*\\([^)]*\\)', '', adat$taxon))   # drop parenthetical subgenus
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g)) / 1000   # mg -> g (dry)
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0 & !is.na(adat$taxon), ]
adat <- adat[!grepl('\\b(sp|spp|cf|aff|indet|agg)\\b|/', adat$taxon), ]
adat$class <- 'Insecta'
adat$order <- 'Lepidoptera'
mass_group <- 'insect'
adat$mass_g <- ToWetMass(adat$mass_g, from = 'dry', group = mass_group)
adat$n <- 1
adat$source_mass <- LabelWithConversion('Kinsella_etal_2020', mass_group)
KIN <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'class', 'order', 'family')]
save(KIN, file = file.path(wd_rdata, 'BodyMass_Kinsella_etal_2020.Rdata'))
