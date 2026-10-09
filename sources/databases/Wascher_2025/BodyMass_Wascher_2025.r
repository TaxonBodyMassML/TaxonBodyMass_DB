# CORVIDATA (Wascher 2025, Scientific Data 12:2032), Zenodo 10.5281/zenodo.17531251,
# CORVIDATA_data.csv (derived from CORVIDATA.xlsx sheet 'CORVIDATA'): one row per
# corvid species (135, AviList 2025 taxonomy). `bodymass` is the species average
# in grams ('not reported' when missing) and `bodymass_ref` the reference it was
# taken from: AVONET (Tobias et al. 2022; 123 rows, the two-decimal values of the
# BirdLife and BirdTree sheets of its Supplementary dataset 1), the Handbook of
# the Birds of the World vol. 14 (del Hoyo et al. 2009; 4), BIRDBASE (Sekercioglu
# et al. 2025; 2), Atwood (1980; 1) or 'not reported' (5). The compilation
# measured nothing itself: every value is a copy, so the AVONET rows are registered
# as verbatim copies of Tobias_2022 in Bib/source_dependencies.csv and every row
# keeps its reference as `ref_keys`. The CSV was derived from the xlsx by reading
# with readxl and writing with write.csv, standardising bodymass to 2 decimal
# places to remove floating-point noise stored in the xlsx cells (README.md).
adat <- read.csv(file.path(wd_source, 'CORVIDATA_data.csv'), na.strings = '',
                 stringsAsFactors = FALSE, check.names = FALSE)
adat <- as.data.frame(adat, stringsAsFactors = FALSE)
adat$taxon  <- trimws(adat$scientific_name)
adat$mass_g <- suppressWarnings(as.numeric(adat$bodymass))      # 'not reported' -> NA
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
# Five AVONET-cited values are not species-specific measurements in AVONET
# itself (Supplementary dataset 1, sheet AVONET1_BirdLife, checked 2026-10-04):
# Corvus fuscicapillus, C. leucognaphalus, C. meeki and Cyanolyca pulchra carry
# Mass.Source 'Inferred' with 'Body Mass' among Traits.inferred (the mass of a
# related species), Corvus palmarum Mass.Source 'EltonTraits_Model'. The
# Tobias_2022 parser excludes those AVONET rows for the same reason, so the
# copies are dropped here (scope rule: no imputed or modelled values; README).
avonet_inferred <- c('Corvus fuscicapillus', 'Corvus leucognaphalus', 'Corvus meeki',
                     'Cyanolyca pulchra', 'Corvus palmarum')
adat <- DropImputed(adat, adat$taxon %in% avonet_inferred, 'Wascher_2025',
                    'AVONET value flagged Inferred (Body Mass) or EltonTraits_Model in AVONET1_BirdLife: not species-specific')
# `bodymass_ref` holds the full citation; the four distinct references are
# keyed in references.csv (key, citation verbatim) and the key is kept as
# `ref_keys` for the primary-source attribution of issue #1 (SplitRefKeys(),
# R/library/citations/parse_reflists.r). An unknown reference string stops the
# parser so that a changed upstream file is noticed, not silently unkeyed.
ref_patterns <- c(Tobias_2022      = '^Tobias, J\\. A\\.',
                  delHoyo_2009     = '^del Hoyo, J\\.',
                  Sekercioglu_2025 = 'BIRDBASE',
                  Atwood_1980      = '^Atwood, Jonathan L\\.')
ref <- trimws(adat$bodymass_ref)
key <- rep(NA_character_, nrow(adat))
for (k in names(ref_patterns)) key[!is.na(ref) & grepl(ref_patterns[[k]], ref, perl = TRUE)] <- k
unknown <- is.na(key) & !is.na(ref) & !ref %in% 'not reported'
if (any(unknown))
  stop('Wascher_2025: unkeyed bodymass_ref value(s): ', paste(unique(ref[unknown]), collapse = ' | '))
adat$ref_keys <- SplitRefKeys(key, ';')
if (anyNA(adat$ref_keys)) warning('Wascher_2025: ', sum(is.na(adat$ref_keys)), ' record(s) without a body-mass reference')
adat$n <- 1
adat$source_mass <- 'Wascher_2025'
WAS <- data.frame(taxon = adat$taxon, mass_g = adat$mass_g, n = adat$n,
                  source_mass = adat$source_mass, ref_keys = adat$ref_keys,
                  class = 'Aves', order = 'Passeriformes', family = 'Corvidae',
                  stringsAsFactors = FALSE)
save(WAS, file = file.path(wd_rdata, 'BodyMass_Wascher_2025.Rdata'))
