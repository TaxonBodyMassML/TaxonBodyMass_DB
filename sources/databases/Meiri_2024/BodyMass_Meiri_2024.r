# SquamBase (Meiri 2024, Global Ecology and Biogeography 33:e13812), Supplementary
# Table S1 (Zenodo 10602503, CC0). Only the measured column 'mean female mass (g)'
# is used (1,211 species); the allometry-derived mass columns (from Feldman et al.
# 2016 equations) are not, because those equations already enter the DB through
# Feldman_etal_2016 and Meiri_2018.
adat <- readxl::read_excel(file.path(wd_source, 'Supplementary_Table_S1_squamBase1.xlsx'),
                           sheet = 'data', na = c('', 'NA'))
adat <- as.data.frame(adat)
adat <- adat[, c('Species name (Binomial)', 'mean female mass (g)', 'Family')]
colnames(adat) <- c('taxon', 'mass_g', 'family')
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
adat$family <- iconv(as.character(adat$family), to = 'ASCII//TRANSLIT')
adat$class <- 'Reptilia'
adat$order <- 'Squamata'
adat$mass_type <- 'wet'
adat$mass_group <- 'vertebrate'
adat$n <- 1
adat$source_mass <- 'Meiri_2024'
MEI <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'class', 'order', 'family',
                'mass_type', 'mass_group')]
save(MEI, file = file.path(wd_rdata, 'BodyMass_Meiri_2024.Rdata'))
