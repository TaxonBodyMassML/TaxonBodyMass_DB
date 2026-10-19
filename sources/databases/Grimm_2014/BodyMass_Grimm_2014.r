# Grimm et al. (2014) Nature Conservation 9:45-67, "Life-history trait database
# of European reptile species" (doi:10.3897/natureconservation.9.8908). The
# source is an MS Access database (Grimm_etal_Reptile_DB_Update_2015.accdb, a
# 2015 update of the database published with the paper); body mass rows and
# their attributed references were extracted by extract_body_mass.py and saved
# as Grimm_2014_body_mass.csv (131 rows, Morphometry table, Trait == 2 "mass
# (g)"). Only adult rows are used (who: "adults", "adult females", "adult
# males"); eggs, hatchlings, clutch, and juvenile rows are excluded as
# non-adult body mass. Mass is the published mean where available; for 3 adult
# rows (Podarcis muralis, Dexel 1986) that carry only min and max, the midpoint
# (min + max) / 2 is used. n = 1 per record (one published mean or midpoint);
# RunMe.r pass 1 takes the geometric mean across all records for a species.
# Per-record primary references are the Ref_Abbr keys of the database's
# References table (one key per row; resolved in primary_references.csv).
adat <- read.csv(file.path(wd_source, 'Grimm_2014_body_mass.csv'), header = TRUE,
                 stringsAsFactors = FALSE, na.strings = c('', 'NA'))

# Keep adult life stages only.
adult_who <- c('adults', 'adult females', 'adult males')
adat <- adat[adat$who %in% adult_who, ]

# Mass: published mean; midpoint of min and max as fallback.
adat$mass_g <- ifelse(!is.na(adat$mass_mean_g), adat$mass_mean_g,
                      (adat$mass_min_g + adat$mass_max_g) / 2)
if (anyNA(adat$mass_g))
  stop('Grimm_2014: ', sum(is.na(adat$mass_g)), ' adult row(s) without a usable mass value')
if (any(adat$mass_g <= 0))
  stop('Grimm_2014: ', sum(adat$mass_g <= 0), ' adult row(s) with non-positive mass')

adat$taxon      <- trimws(adat$current_species_name)
adat$n          <- 1
adat$source_mass <- 'Grimm_2014'
adat$ref_keys   <- SplitRefKeys(adat$ref_abbr, ';')
if (anyNA(adat$ref_keys)) warning('Grimm_2014: ', sum(is.na(adat$ref_keys)), ' record(s) without a reference key')

GRI <- data.frame(taxon       = adat$taxon,
                  mass_g      = adat$mass_g,
                  n           = adat$n,
                  source_mass = adat$source_mass,
                  ref_keys    = adat$ref_keys,
                  class       = 'Reptilia',
                  stringsAsFactors = FALSE)
save(GRI, file = file.path(wd_rdata, 'BodyMass_Grimm_2014.Rdata'))
