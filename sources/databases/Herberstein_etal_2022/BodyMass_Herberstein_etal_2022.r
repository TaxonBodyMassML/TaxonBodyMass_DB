# AnimalTraits (Herberstein et al. 2022, Scientific Data 9:265), observations.csv
# (Zenodo 6468938, CC0). One row per published observation; 'body mass' is the
# standardised value in kg (original value and units retained in the file).
# All observations are kept; RunMe Pass 1 takes the within-source geometric mean.
adat <- read.csv(file.path(wd_source, 'observations.csv'), header = TRUE,
                 check.names = FALSE, stringsAsFactors = FALSE,
                 na.strings = c('', 'NA'), encoding = 'UTF-8')
stopifnot(all(adat[['body mass - units']][!is.na(adat[['body mass']])] == 'kg'))
adat <- adat[!is.na(adat[['body mass']]),
             c('species', 'body mass', 'phylum', 'class', 'order', 'family', 'fullReference')]
colnames(adat) <- c('taxon', 'mass_g', 'phylum', 'class', 'order', 'family', 'fullReference')
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g)) * 1000
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
for (col in c('phylum', 'class', 'order', 'family'))
  adat[[col]] <- iconv(as.character(adat[[col]]), to = 'ASCII//TRANSLIT')
adat$n <- 1
adat$source_mass <- 'Herberstein_etal_2022'
# The originating study of every observation is carried in the row itself
# (`fullReference`, full citation text with a DOI on about 61% of the rows;
# `inTextReference` is its short form). For the primary-source attribution of
# issue #1 the record keeps, as `ref_keys`, the hash key 'h:<sha1-8>' of the
# normalised citation string (ParseInRowCitations() / CitationHashKey(),
# R/library/citations/), one key per row, NA where the row cites nothing; the
# same keys index sources/databases/Herberstein_etal_2022/primary_references.csv.
adat$ref_keys <- ParseInRowCitations(adat$fullReference)$keys
if (anyNA(adat$ref_keys)) warning('Herberstein_etal_2022: ', sum(is.na(adat$ref_keys)), ' record(s) without a reference')
HER <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'phylum', 'class', 'order',
                'family', 'ref_keys')]
save(HER, file = file.path(wd_rdata, 'BodyMass_Herberstein_etal_2022.Rdata'))
