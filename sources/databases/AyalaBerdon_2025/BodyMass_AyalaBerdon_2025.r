# Ayala-Berdon et al. (2025) J. Comp. Physiol. B 195:577-587, Supplementary
# material (360_2025_1630_MOESM1_ESM.pdf, a publisher file kept locally and not
# committed; Springer TDM licence). Its first table lists, for 39 vespertilionid
# bat species, the body mass Mb (g) of every bat whose basal metabolic rate the
# authors measured ('This study', their earlier papers and their unpublished
# data) or took from the literature (the Mb reported in the cited publication),
# one row per measurement with locality, climate class, BMR, a modelled
# digestibility and the reference. The table was transcribed by hand into
# 360_2025_1630_MOESM1_ESM_table1.csv (README.md: Data; checked against the
# page images). Mb is live ('wet') mass in grams; one row per measurement, so
# n = 1 and Pass 1 of RunMe.r takes the species geometric mean. Nothing in the
# table is imputed: the modelled column is a digestibility, not a mass, and is
# not used.
adat <- read.csv(file.path(wd_source, '360_2025_1630_MOESM1_ESM_table1.csv'), header = TRUE,
                 check.names = FALSE, stringsAsFactors = FALSE, encoding = 'UTF-8')
adat$taxon  <- trimws(adat$species)
adat$mass_g <- suppressWarnings(as.numeric(adat$Mb_g))
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
adat$n <- 1
adat$source_mass <- 'AyalaBerdon_2025'
# The reference of every row (the author-year key as printed in the table's
# References column; 'This study' and 'Ayala-Berdon et al. unpublished data'
# are the compilers' own measurements), resolved in references.csv (the
# supplement's reference list), is kept as `ref_keys` for the primary-source
# attribution of issue #1 (SplitRefKeys(), R/library/citations/parse_reflists.r).
adat$ref_keys <- SplitRefKeys(adat$reference, ';')
if (anyNA(adat$ref_keys)) warning('AyalaBerdon_2025: ', sum(is.na(adat$ref_keys)), ' record(s) without a reference key')
AYA <- data.frame(taxon = adat$taxon, mass_g = adat$mass_g, n = adat$n,
                  source_mass = adat$source_mass, ref_keys = adat$ref_keys,
                  class = 'Mammalia', order = 'Chiroptera',
                  stringsAsFactors = FALSE)
save(AYA, file = file.path(wd_rdata, 'BodyMass_AyalaBerdon_2025.Rdata'))
