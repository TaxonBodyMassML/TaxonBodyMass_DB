# Hishi et al. (2019) Ecological Research 34:8 (JaLTER ERDP-2019-03), Japanese
# Collembola trait data. D_trait.csv holds species traits keyed by (spID1, spID2)
# and is joined to A_sptaxon.csv for Genus and Specific_name. body_mass is adult
# dry body mass in micrograms (calculated in the source from body length with
# family-level length-weight equations); converted to wet grams with the insect
# (hexapod) factor of R/library/mass_conversion.r.
tr <- read.csv(file.path(wd_source, 'ERDP_2019_03_5_1_D_trait.csv'), header = TRUE,
               stringsAsFactors = FALSE, na.strings = c('', 'NA', 'ND'))
tx <- read.csv(file.path(wd_source, 'ERDP_2019_03_2_1_A_sptaxon.csv'), header = TRUE,
               stringsAsFactors = FALSE, na.strings = c('', 'NA', 'ND'))
adat <- merge(tr[, c('spID1', 'spID2', 'body_mass')],
              tx[, c('spID1', 'spID2', 'Genus', 'Specific_name', 'Family')],
              by = c('spID1', 'spID2'))
adat$taxon <- trimws(paste(adat$Genus, adat$Specific_name))
adat <- adat[grepl('^[A-Z][a-z]+ [a-z]+$', adat$taxon) & !grepl('\\b(sp|spp|cf|aff)\\b', adat$taxon), ]
adat$mass_g <- suppressWarnings(as.numeric(adat$body_mass)) * 1e-6      # ug dry -> g dry
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
adat$family <- adat$Family
adat$class  <- 'Collembola'
mass_group <- 'insect'
adat$mass_g <- ToWetMass(adat$mass_g, from = 'dry', group = mass_group)
adat$n <- 1
adat$source_mass <- LabelWithConversion('Hishi_etal_2019', mass_group)
HIS <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'class', 'family')]
save(HIS, file = file.path(wd_rdata, 'BodyMass_Hishi_etal_2019.Rdata'))
