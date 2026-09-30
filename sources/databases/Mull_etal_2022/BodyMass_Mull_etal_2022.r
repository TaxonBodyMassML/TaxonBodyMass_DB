# Sharkipedia (Mull et al. 2022, Scientific Data 9:559), traits export
# Sharkipedia-Traits-v1.0-22-01-25.csv. Only records with trait_name 'Body Mass'
# are used (the 'Offspring mass' trait is excluded). Units are given per record in
# standard_name (g or kg) and converted to grams; all value types (max, mean, min,
# raw) are retained and averaged within species by RunMe Pass 1.
adat <- read.csv(file.path(wd_source, 'Sharkipedia-Traits-v1.0-22-01-25.csv'),
                 header = TRUE, stringsAsFactors = FALSE, na.strings = c('', 'NA'),
                 fileEncoding = 'UTF-8-BOM')
adat <- adat[adat$trait_name == 'Body Mass' & !(adat$dubious %in% c('TRUE', TRUE)), ]
unit_to_g <- c(g = 1, kg = 1000, mg = 1e-3)
u <- tolower(trimws(adat$standard_name))
if (any(!u %in% names(unit_to_g)))
  stop('Mull_etal_2022: unhandled mass unit(s): ', paste(unique(u[!u %in% names(unit_to_g)]), collapse = ', '))
adat <- data.frame(taxon  = trimws(adat$species_name),
                   mass_g = suppressWarnings(as.numeric(adat$value)) * unit_to_g[u],
                   stringsAsFactors = FALSE)
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
adat <- adat[grepl('^[A-Z][a-z]+ [a-z]+$', adat$taxon) & !grepl('\\b(sp|spp|cf|aff)\\b', adat$taxon), ]
adat$n <- 1
adat$source_mass <- 'Mull_etal_2022'
MUL <- adat[, c('taxon', 'mass_g', 'n', 'source_mass')]
save(MUL, file = file.path(wd_rdata, 'BodyMass_Mull_etal_2022.Rdata'))
