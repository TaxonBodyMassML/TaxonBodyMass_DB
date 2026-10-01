# Lukić, Limberger, Agatha, Montagnes & Weisse (2022) Limnology and Oceanography
# Letters 7:520-526 (Dryad 10.5061/dryad.ksn02v76k): compilation of growth-rate
# experiments on planktonic ciliates, Dataset_v2.xlsx, with the cell volume (µm^3)
# of the ciliates used in each experiment. Cell volume is converted to wet mass
# assuming unit density (1 µm^3 = 1e-12 g; CellVolumeToWetMass), the same convention
# as the protist 'wet mass' of Kiørboe (2013). Species-level names only; 'sp.',
# 'cf.' and 'nomen dubium' entries are dropped. One row per experiment; RunMe Pass 1
# takes the within-source geometric mean per species.
adat <- readxl::read_excel(file.path(wd_source, 'Dataset_v2.xlsx'), sheet = 'Tabelle1',
                           na = c('', 'NA'))
adat <- as.data.frame(adat)
adat$taxon <- trimws(adat[['ciliate.species']])
adat <- adat[grepl('^[A-Z][a-z]+ [a-z]+$', adat$taxon) & !grepl('\\b(sp|spp|cf|aff)\\b', adat$taxon), ]
vol <- suppressWarnings(as.numeric(adat[['ciliate.volume (µm3)']]))
adat$mass_g <- CellVolumeToWetMass(vol)
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
adat$phylum <- 'Ciliophora'
adat$n <- 1
adat$source_mass <- 'Lukic_2022'
LUK <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'phylum')]
save(LUK, file = file.path(wd_rdata, 'BodyMass_Lukic_2022.Rdata'))
