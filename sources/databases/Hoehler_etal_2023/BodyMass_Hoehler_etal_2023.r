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
# Rows whose Comments mark the cell size as a genus-level value ('BacDive,
# GENUS', 'BM Vol 3, genus') are not species-specific.
adat <- DropImputed(adat,
                    !is.na(adat$Comments) & grepl('genus', adat$Comments, ignore.case = TRUE),
                    'Hoehler_etal_2023', 'genus-level cell size (Comments)')
# The 1,497 rows coded 'Hudson et al. (2013)' in `Reference Code` copy Hudson,
# Isaac & Reuman (2013) Appendix S5 row by row (604 mammals, 893 birds), which
# enters the database directly as Hudson_2013 with a per-row study key (#59),
# and 262 of the bird copies carry another species' mass (#66: every one of
# them occurs in Appendix S5 under a different species). All Hudson-coded rows
# are dropped and logged; the species keep their Hudson_2013 records.
adat <- DropImputed(adat, adat$`Reference Code` %in% 'Hudson et al. (2013)',
                    'Hoehler_etal_2023',
                    'copied from Hudson_2013 (Reference Code Hudson et al. (2013)), which enters directly; 262 bird masses sit under the wrong species (#66)')
# The compilation each row was taken from (`Reference Code`, resolved verbatim
# in references.csv from the workbook's Refs sheet) is kept as `ref_keys` for
# the primary-source attribution of issue #1 (SplitRefKeys(),
# R/library/citations/parse_reflists.r); the codes contain no ';'.
adat$ref_keys <- SplitRefKeys(adat$`Reference Code`, ';')
if (anyNA(adat$ref_keys)) warning('Hoehler_etal_2023: ', sum(is.na(adat$ref_keys)), ' record(s) without a Reference Code')
out <- data.frame(taxon = adat$taxon, mass_g = adat$mass_g,
                  kingdom = adat$Kingdom, phylum = adat$Phylum, class = adat$Class,
                  order = adat$Order, family = adat$Family, ref_keys = adat$ref_keys,
                  stringsAsFactors = FALSE)
for (col in c('kingdom', 'phylum', 'class', 'order', 'family'))
  out[[col]] <- iconv(as.character(out[[col]]), to = 'ASCII//TRANSLIT')
out$n <- 1
out$source_mass <- 'Hoehler_etal_2023'
HOE <- out[, c('taxon', 'mass_g', 'n', 'source_mass', 'ref_keys', 'kingdom', 'phylum', 'class',
               'order', 'family')]
save(HOE, file = file.path(wd_rdata, 'BodyMass_Hoehler_etal_2023.Rdata'))
