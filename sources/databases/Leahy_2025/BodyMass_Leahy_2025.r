# Leahy et al. (2025) PNAS 122(29): e2501541122, Dryad 10.5061/dryad.d7wm37qb7,
# mr_ant_525.csv: 2,805 individual worker ants of 214 colonies, 114 names (57
# binomials, 57 morphospecies / 'nr.' / 'sp.' names) from six locations in
# south-eastern Australia, each weighed by the authors after its metabolic
# assay (wet.mass, mg, the frozen ant weighed the next day; dry.mass after 48 h
# at 50 C). The authors' own measurements: every record cites the study itself
# (`ref_keys` 'self', resolved in references.csv). One row per individual, so
# n = 1 and Pass 1 of RunMe.r takes the species geometric mean.
adat <- read.csv(file.path(wd_source, 'mr_ant_525.csv'), header = TRUE,
                 stringsAsFactors = FALSE, na.strings = c('', 'NA'), encoding = 'UTF-8')
# One ant (individ.code 4123, Crematogaster laeviceps, colony WS2) is listed on
# four rows with the same masses (they differ only in the activity and noise
# columns of the trace); the individual is kept once (README.md).
adat$taxon  <- trimws(adat$species)
adat <- DropImputed(adat, duplicated(adat$individ.code), 'Leahy_2025',
                    'duplicate rows of one individual (individ.code 4123): kept once')
adat$mass_g <- suppressWarnings(as.numeric(adat$wet.mass)) / 1000      # mg -> g (wet)
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
# Species-level binomials only: the 'nr.' near-identifications, the 'sp.' and
# lettered or coded morphospecies ('Camponotus sp. cla1 (claripes gp.)',
# 'Crematogaster lae1 (laeviceps gp.)') and the bracketed qualifier
# 'Stigmacros reticulata (nr.)' are not identified to species (README.md).
adat <- adat[grepl('^[A-Z][a-z]+ [a-z]+$', adat$taxon), ]
adat$n <- 1
adat$source_mass <- 'Leahy_2025'
# Every record is the authors' own measurement: the constant key 'self' is
# resolved in references.csv (role self, never sent to a service) so that a
# compilation citing this paper is attributed through it at hop 2 (issue #1).
adat$ref_keys <- SplitRefKeys(rep('self', nrow(adat)), ';')
LEA <- data.frame(taxon = adat$taxon, mass_g = adat$mass_g, n = adat$n,
                  source_mass = adat$source_mass, ref_keys = adat$ref_keys,
                  class = 'Insecta', order = 'Hymenoptera', family = 'Formicidae',
                  stringsAsFactors = FALSE)
save(LEA, file = file.path(wd_rdata, 'BodyMass_Leahy_2025.Rdata'))
