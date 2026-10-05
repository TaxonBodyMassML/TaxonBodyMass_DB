# Baach & Dormann (2026) Scientific Data 13:1132, "Multitrophic dataset for
# multi-taxon abundance and richness estimations from biomass and nutrient
# energetics" (Zenodo 10.5281/zenodo.18630029). The Abundance Richness
# spreadsheet holds the sheet 'individual mass', exported here as
# 'individual mass.csv' (Windows-1252; 2,027 lines of which 935 are blank):
# one row per individual mass in grams ("all mass converted to g", note of row 1)
# with the name as written by the source, Family, tax_cat, trophic_level,
# trophic_niche, ref (the compilation's source key, resolved in references.csv,
# a transcription of the spreadsheet's References sheet), alt refs (taxonomic
# authorities on the snail rows, the primary studies cited through the Golley
# et al. book on the small-mammal rows) and notes. Birds and mammals are species
# means copied from EltonTraits, AVONET / the Handbuch der Voegel Mitteleuropas,
# Jedrzejewska & Jedrzejewski (1998) and Golley et al. (2009); the insects are the
# individual masses of Chown et al. (2007) Appendices S1-S2 (Bib/source_dependencies.csv).
# One row per value, so n = 1 and Pass 1 of RunMe.r takes the species geometric mean.
adat <- read.csv(file.path(wd_source, 'individual mass.csv'), header = TRUE,
                 check.names = FALSE, stringsAsFactors = FALSE,
                 fileEncoding = 'WINDOWS-1252', na.strings = c('', 'NA'),
                 strip.white = TRUE)
adat <- adat[, c('name', 'Family', 'tax_cat', 'indiv_mass', 'ref', 'alt refs', 'notes')]
adat <- adat[!is.na(adat$name), ]
adat$taxon  <- trimws(adat$name)
adat$mass_g <- suppressWarnings(as.numeric(adat$indiv_mass))
if (anyNA(adat$mass_g) || any(adat$mass_g <= 0))
  stop('Baach_2026: ', sum(is.na(adat$mass_g) | adat$mass_g <= 0), ' row(s) without a positive mass')
# The reference keys as the sheet writes them, with the Handbuch volume/page
# locator '(B9 S605)' removed and transliterated to ASCII (the export wrote
# 'J?drzejewska' for the e-ogonek the Windows-1252 code page lacks); every key
# must be one of the References sheet's names (references.csv, column key).
adat$ref <- sub('\\s*\\(B[0-9_]+ S[0-9]+\\)\\s*$', '', trimws(adat$ref))
ref_key_map <- c(
  'Bába_K. 2000'                             = 'Baba_K. 2000',
  'Golley Petrusewicz and Ryszowski 2009'    = 'Golley Petrusewicz and Ryszowski 2009',
  'AVONET; Handbuch der Vögel Mitteleuropas' = 'AVONET; Handbuch der Vogel Mitteleuropas',
  'EltonTraits'                              = 'EltonTraits',
  'J?drzejewska_B. and J?drzejewski_W. 1998' = 'Jedrzejewska_B. and Jedrzejewski_W. 1998',
  'Norberg_R.Å. 1978'                        = 'Norberg_R.A. 1978',
  'Chown_S.L. et al. 2007'                   = 'Chown_S.L. et al. 2007',
  'Snow_N.P. et al. 2025'                    = 'Snow_N.P. et al. 2025',
  'Rendon_D. et al. 2019'                    = 'Rendon_D. et al. 2019')
names(ref_key_map) <- enc2utf8(names(ref_key_map))
adat$ref <- enc2utf8(adat$ref)
unknown <- setdiff(unique(adat$ref), names(ref_key_map))
if (length(unknown) > 0)
  stop('Baach_2026: reference key(s) not in ref_key_map: ', paste(unknown, collapse = ' | '))
adat$ref_keys <- SplitRefKeys(unname(ref_key_map[adat$ref]), ';')
# Scope exclusions (README.md, Imputed rows): the one Sus scrofa value is the
# midpoint of a published range of visually estimated masses (notes 'average
# from range'; Snow et al. 2025), not a measurement; the 22 Norberg (1978) rows
# are order- and family-level records (Araneae, Psocoptera, Curculionidae) of an
# energy-content study whose mass type the sheet does not state.
adat <- DropImputed(adat, !is.na(adat$notes) & adat$notes == 'average from range', 'Baach_2026',
                    'average of a published range (notes "average from range"; Snow et al. 2025 visually estimated wild-pig masses): not a measured value')
adat <- DropImputed(adat, adat$ref_keys == 'Norberg_R.A. 1978', 'Baach_2026',
                    'order/family-level records of Norberg (1978), an energy-content study whose mass type (dry or fresh) the sheet does not state: unverifiable units')
adat$n <- 1
adat$source_mass <- 'Baach_2026'
# Taxonomy hints: the class from tax_cat (bird, mammal; the invertebrates get
# none) and the Family column where it is a family name (the sheet also writes
# orders, a class and a subfamily there).
adat$class  <- c(bird = 'Aves', mammal = 'Mammalia')[adat$tax_cat]
adat$family <- ifelse(grepl('idae$', adat$Family), adat$Family, NA_character_)
if (anyNA(adat$ref_keys)) warning('Baach_2026: ', sum(is.na(adat$ref_keys)), ' record(s) without a reference key')
BAA <- data.frame(taxon = adat$taxon, mass_g = adat$mass_g, n = adat$n,
                  source_mass = adat$source_mass, class = adat$class, family = adat$family,
                  ref_keys = adat$ref_keys, stringsAsFactors = FALSE)
save(BAA, file = file.path(wd_rdata, 'BodyMass_Baach_2026.Rdata'))
