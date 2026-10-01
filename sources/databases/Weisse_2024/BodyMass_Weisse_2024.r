# Weisse (2024) Limnology and Oceanography 69:524-532 (Dryad 10.5061/dryad.cnp5hqc99):
# compilation of growth and physiological mortality experiments on planktonic
# ciliates, dataset_v2.xlsx, with the cell volume (µm^3) of each ciliate species.
# Genus names are abbreviated after first mention in the species column
# (e.g. 'Str. conicum', 'U. farcta'); they are expanded with the table below,
# checked against the 'order' column. Cell volume is converted to wet mass at unit
# density (1 µm^3 = 1e-12 g; CellVolumeToWetMass), as for Lukic_2022 and the
# protist 'wet mass' of Kiørboe (2013). 'sp.' and 'cf.' entries are dropped.
adat <- readxl::read_excel(file.path(wd_source, 'dataset_v2.xlsx'), sheet = 'Sheet1',
                           na = c('', 'NA', 'N.A.', 'n/a'))
adat <- as.data.frame(adat)
sp <- trimws(adat$species)
abbrev <- c('C.' = 'Colpidium', 'F.' = 'Favella', 'H.' = 'Histiobalantium',
            'P.' = 'Parallelostrombidium', 'R.' = 'Rimostrombidium', 'S.' = 'Strombidinopsis',
            'Str.' = 'Strombidium', 'T.' = 'Tintinnopsis', 'U.' = 'Urotricha', 'V.' = 'Vorticella')
for (ab in names(abbrev))
  sp <- sub(paste0('^', gsub('.', '\\.', ab, fixed = TRUE), '\\s*([a-z]+)$'),
            paste0(abbrev[ab], ' \\1'), sp)
adat$taxon <- sp
adat <- adat[grepl('^[A-Z][a-z]+ [a-z]+$', adat$taxon) & !grepl('\\b(sp|spp|cf|aff)\\b', adat$taxon), ]
adat$mass_g <- CellVolumeToWetMass(suppressWarnings(as.numeric(adat$volume)))
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
adat$phylum <- 'Ciliophora'
adat$order  <- adat$order
adat$n <- 1
adat$source_mass <- 'Weisse_2024'
WEI <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'phylum', 'order')]
save(WEI, file = file.path(wd_rdata, 'BodyMass_Weisse_2024.Rdata'))
