# Hoehler et al. (2023) PNAS 120:e2303764120, Dataset S01 (pnas.2303764120.sd01.xlsx,
# sheet Metabolic_Data): >10,000 metabolic-rate measurements on >2,900 species
# with the body mass of the measured organisms. 'Wet Mass (g)' is an entered value
# for all but six rows (where it is a spreadsheet formula from dry mass); the dry
# and carbon columns are mostly formulas derived from wet mass, so wet mass is
# taken as the primary measurement. Only rows resolved to species (or subspecies)
# are used; autotroph and fungal groups are excluded; bacteria/archaea retained.
adat <- readxl::read_excel(file.path(wd_source, 'pnas.2303764120.sd01.xlsx'),
                           sheet = 'Metabolic_Data', na = c('', 'NA'))
adat <- as.data.frame(adat)
names(adat) <- trimws(names(adat))
adat <- adat[adat$`tsn rank` %in% c('Species', 'Subspecies'), ]
excl <- c('Seedling', 'Tree sapling', 'Eukaryotic Microalgae (non-filamentous)',
          'Cyanobacteria', 'Fungi')
adat <- adat[!(adat$Group %in% excl), ]
# Fish records are mostly juveniles/small individuals from metabolic studies and
# sit ~0.2-0.7 log10 below other sources for the same species: exclude fishes.
adat <- adat[!(adat$Group %in% 'Fishes'), ]
adat$mass_g <- suppressWarnings(as.numeric(adat$`Wet Mass (g)`))   # formulas -> NA, dropped
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
adat$taxon <- trimws(adat$Species)
adat$taxon <- sub('^([A-Z][a-z]+ [a-z]+).*$', '\\1', adat$taxon)   # drop subspecies/strain suffixes
adat <- adat[grepl('^[A-Z][a-z]+ [a-z]+$', adat$taxon), ]
adat <- adat[!grepl('\\b(sp|spp|cf|aff|indet)\\b', adat$taxon), ]
out <- data.frame(taxon = adat$taxon, mass_g = adat$mass_g,
                  kingdom = adat$Kingdom, phylum = adat$Phylum, class = adat$Class,
                  order = adat$Order, family = adat$Family, stringsAsFactors = FALSE)
for (col in c('kingdom', 'phylum', 'class', 'order', 'family'))
  out[[col]] <- iconv(as.character(out[[col]]), to = 'ASCII//TRANSLIT')
out$n <- 1
out$source_mass <- 'Hoehler_etal_2023'
HOE <- out[, c('taxon', 'mass_g', 'n', 'source_mass', 'kingdom', 'phylum', 'class',
               'order', 'family')]
save(HOE, file = file.path(wd_rdata, 'BodyMass_Hoehler_etal_2023.Rdata'))
