# Broecher et al. (2025) Ecology 106:e70077, JEXIS dataset 703 v10
# (JExIS_703_v10_data.csv): ecological traits for 1,374 arthropod species from the
# Jena Experiment grassland. 'Body mass' is in mg (live mass, calculated in the
# source from body length with the equations of Sohlstroem et al. 2018; owner
# decision 2026-09-29 to include). Converted mg -> g; class/order/family carried.
adat <- read.csv(file.path(wd_source, 'JExIS_703_v10_data.csv'), header = TRUE,
                 check.names = FALSE, stringsAsFactors = FALSE, na.strings = c('', 'NA'))
adat <- data.frame(taxon  = trimws(adat$Taxa),
                   mass_g = suppressWarnings(as.numeric(adat[['Body mass']])) / 1000,
                   class  = adat$Class, order = adat$Order, family = adat$Family,
                   stringsAsFactors = FALSE)
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
adat <- adat[grepl('^[A-Z][a-z]+ [a-z]+$', adat$taxon) & !grepl('\\b(sp|spp|cf|aff|agg)\\b', adat$taxon), ]
adat$n <- 1
adat$source_mass <- 'Brocher_etal_2025'
BRC <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'class', 'order', 'family')]
save(BRC, file = file.path(wd_rdata, 'BodyMass_Brocher_etal_2025.Rdata'))
