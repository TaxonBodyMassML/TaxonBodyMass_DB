# Hudson, Isaac & Reuman (2013) J. Anim. Ecol. 82:1009-1020, Appendix S5
# (jane12086-sup-0003-AppendixS5.csv): 1,498 individual birds (894) and mammals
# (604) of 133 species whose body mass and field metabolic rate were measured
# in 126 doubly-labelled-water studies (column Study, an author-year key resolved
# in references.csv, a transcription of Appendix S6). M (kg) is the live ('wet')
# mass of the measured individual (Methods, 'Database'); an individual measured
# more than once enters as the mean of its measurements. One row per individual,
# so n = 1 and Pass 1 of RunMe.r takes the species geometric mean.
# Hoehler et al. (2023) Dataset S01 copies 1,497 of these rows under Reference
# Code 'Hudson et al. (2013)'; its parser drops them since #66
# (Bib/source_dependencies.csv, provenance_only edge).
adat <- read.csv(file.path(wd_source, 'jane12086-sup-0003-AppendixS5.csv'), header = TRUE,
                 check.names = FALSE, stringsAsFactors = FALSE, encoding = 'UTF-8')
adat$taxon  <- paste(trimws(adat$Genus), trimws(adat$Species))
adat$mass_g <- suppressWarnings(as.numeric(adat[['M (kg)']])) * 1000
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
# The database does not record life stage, but four studies measured nestlings
# or chicks (their Appendix S6 titles: Degen et al. 1992 northern shrike
# nestlings, Dykstra & Karasov 1993 nestling house wrens, Dykstra et al. 2001
# nestling bald eagles, Tjorve et al. 2007 African black oystercatcher chicks);
# their rows are dropped as non-adult records (README.md). No other study of
# these four species is in the database, so the species leave with them.
nestling_studies <- c('Degen et al 1992', 'Dykstra & Karasov 1993', 'Dykstra et al 2001',
                      'Tjørve et al 2007')
adat <- DropImputed(adat, adat$Study %in% nestling_studies, 'Hudson_2013',
                    'nestling/chick study (Appendix S6 title): not adult records')
adat$n <- 1
adat$source_mass <- 'Hudson_2013'
# The per-row study key (author-year, one key per row), resolved in
# references.csv, is kept as `ref_keys` for the primary-source attribution of
# issue #1 (SplitRefKeys(), R/library/citations/parse_reflists.r).
adat$ref_keys <- SplitRefKeys(adat$Study, ';')
if (anyNA(adat$ref_keys)) warning('Hudson_2013: ', sum(is.na(adat$ref_keys)), ' record(s) without a study key')
HUD <- data.frame(taxon = adat$taxon, mass_g = adat$mass_g, n = adat$n,
                  source_mass = adat$source_mass, ref_keys = adat$ref_keys,
                  class = adat$Class, order = adat$Order, family = adat$Family,
                  stringsAsFactors = FALSE)
save(HUD, file = file.path(wd_rdata, 'BodyMass_Hudson_2013.Rdata'))
