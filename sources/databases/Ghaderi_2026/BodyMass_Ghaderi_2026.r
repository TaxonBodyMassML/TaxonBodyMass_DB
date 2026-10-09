# Ghaderi, Nielsen & He (2026) Applied Soil Ecology 217:106605, supplementary
# workbook 1-s2.0-S0929139325007437-mmc1.xlsx, sheet 'Original', exported as
# Ghaderi_2026_data.csv: 573 population records (one row per population x life
# stage) of predatory soil nematodes (Mononchida; 8 families, 48 genera, 242
# binomials). Nothing in the workbook is a weighed mass: the authors took the
# body length L (um) and the de Man ratio a (= L / greatest body diameter) of
# each population from the taxonomic description cited in `Source` (an
# author-year key, 85 keys; no reference list ships with the workbook) and
# computed the fresh (wet) mass with the volumetric formula of Andrassy (1956),
# Fresh W (ug) = L * D^2 / 1.6e6 with D = L / a; the other mass columns follow
# from it (Dry W = 0.104 x Fresh W, Pc = Dry W / 48, plus respiration and
# carbon budget). The other xlsx sheets ('Order-*', 'Suborder-*',
# 'Superfamily-*', 'Family-*', 'Subfamil(t)y-*', 'Genera-*', 'Juveniles',
# 'G index') are subsets or rank-level averages of 'Original' and are not read.
# The CSV was derived from the xlsx by reading with readxl and writing with
# write.csv (dropping 3 unnamed trailing columns that held only a footnote),
# then verified that Fresh W satisfies the Andrassy formula to within 1e-6
# relative tolerance (README.md). The frame holds Fresh W as grams (ug -> g):
# an allometry-derived value kept by DropImputed() rules, class `derived`
# (Bib/source_provenance_classes.csv). Adults of both sexes (f, m) are kept,
# one row per population (n = 1); 14 juvenile rows (J1-J4) are dropped. The
# `Source` key is kept as `ref_keys` (issue #1).
adat <- read.csv(file.path(wd_source, 'Ghaderi_2026_data.csv'),
                 na.strings = '', stringsAsFactors = FALSE, check.names = FALSE)
names(adat) <- trimws(names(adat))
needed <- c('Source', 'Order', 'Family', 'Genus', 'Species', 'L', 'a', 'D', 'Life stage', 'Fresh W')
if (!all(needed %in% names(adat)))
  stop('Ghaderi_2026: expected columns missing: ', paste(setdiff(needed, names(adat)), collapse = ', '))
num <- function(x) suppressWarnings(as.numeric(x))
adat$fresh_ug <- num(adat[['Fresh W']])
# Guard: every mass must be the Andrassy (1956) value of its own L and a, so
# that a weighed value or a changed formula in a later version of the file is
# noticed rather than taken as a derived one.
andrassy <- num(adat$L) * (num(adat$L) / num(adat$a))^2 / 1.6e6
if (any(abs(adat$fresh_ug - andrassy) / adat$fresh_ug > 1e-6, na.rm = TRUE))
  stop('Ghaderi_2026: Fresh W is not L * (L/a)^2 / 1.6e6 on every row; check the file')
adat$taxon  <- trimws(paste(trimws(adat$Genus), trimws(adat$Species)))
adat$mass_g <- adat$fresh_ug * 1e-6                       # ug fresh -> g wet
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
adat <- adat[grepl('^[A-Z][a-z]+ [a-z]+$', adat$taxon) & !grepl('\\b(sp|spp|cf|aff)\\b', adat$taxon), ]
adat <- DropImputed(adat, adat[['Life stage']] %in% c('J1', 'J2', 'J3', 'J4'), 'Ghaderi_2026',
                    'juvenile life stage (J1-J4): not adult records')
if (!all(adat[['Life stage']] %in% c('f', 'm')))
  stop('Ghaderi_2026: unexpected Life stage value(s): ',
       paste(unique(setdiff(adat[['Life stage']], c('f', 'm'))), collapse = ', '))
adat$n <- 1
adat$source_mass <- 'Ghaderi_2026'
# The per-row `Source` key (author-year as written, one key per row; the
# workbook ships no reference list, so the keys stay `uningested` until one is
# on disk) is kept as `ref_keys` for the primary-source attribution of issue #1.
adat$ref_keys <- SplitRefKeys(adat$Source, ';')
if (anyNA(adat$ref_keys)) warning('Ghaderi_2026: ', sum(is.na(adat$ref_keys)), ' record(s) without a source key')
GHA <- data.frame(taxon = adat$taxon, mass_g = adat$mass_g, n = adat$n,
                  source_mass = adat$source_mass, ref_keys = adat$ref_keys,
                  phylum = 'Nematoda', order = trimws(adat$Order), family = trimws(adat$Family),
                  stringsAsFactors = FALSE)
save(GHA, file = file.path(wd_rdata, 'BodyMass_Ghaderi_2026.Rdata'))
