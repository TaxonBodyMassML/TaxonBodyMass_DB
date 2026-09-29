# AnimalTraits (Herberstein et al. 2022, Scientific Data 9:265), observations.csv
# (Zenodo 6468938, CC0). One row per published observation; 'body mass' is the
# standardised value in kg (original value and units retained in the file).
# All observations are kept; RunMe Pass 1 takes the within-source geometric mean.
adat <- read.csv(file.path(wd_source, 'observations.csv'), header = TRUE,
                 check.names = FALSE, stringsAsFactors = FALSE,
                 na.strings = c('', 'NA'), encoding = 'UTF-8')
stopifnot(all(adat[['body mass - units']][!is.na(adat[['body mass']])] == 'kg'))
adat <- adat[!is.na(adat[['body mass']]),
             c('species', 'body mass', 'phylum', 'class', 'order', 'family')]
colnames(adat) <- c('taxon', 'mass_g', 'phylum', 'class', 'order', 'family')
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g)) * 1000
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
for (col in c('phylum', 'class', 'order', 'family'))
  adat[[col]] <- iconv(as.character(adat[[col]]), to = 'ASCII//TRANSLIT')
adat$n <- 1
adat$source_mass <- 'Herberstein_etal_2022'
HER <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'phylum', 'class', 'order',
                'family')]
save(HER, file = file.path(wd_rdata, 'BodyMass_Herberstein_etal_2022.Rdata'))
