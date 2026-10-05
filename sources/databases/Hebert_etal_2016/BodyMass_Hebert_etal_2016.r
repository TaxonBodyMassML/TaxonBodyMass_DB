# Hébert, Beisner & Maranger (2016) Ecology 97:1081 (Ecological Archives data
# paper), zooplankton_traits.csv (semicolon-delimited, decimal commas).
# Dry.mass = individual mean body dry mass (mg) of adult (mostly female)
# copepods and cladocerans, compiled from the literature. Rows whose dry mass
# comes from the freshwater length-weight allometry sub-data set (Ref.dm codes
# 18 = Culver et al. 1985 and 20 = McCauley 1984) are excluded because those
# values are regression estimates rather than measurements.
adat <- read.csv(file.path(wd_source, 'zooplankton_traits.csv'), header = TRUE,
                 sep = ';', dec = ',', stringsAsFactors = FALSE,
                 na.strings = c('', 'NA'), fileEncoding = 'latin1', check.names = FALSE)
adat$taxon <- trimws(paste(adat$Genus, adat$Species))
refs <- strsplit(as.character(adat$Ref.dm), ',')
allometric <- vapply(refs, function(r) any(trimws(r) %in% c('18', '20')), logical(1))
adat <- adat[!is.na(adat$Dry.mass) & !allometric, ]
# The per-record dry-mass reference codes (Ref.dm, comma-separated; several
# codes per row are allowed), resolved in references.csv, are kept as
# `ref_keys` for the primary-source attribution of issue #1 (SplitRefKeys(),
# R/library/citations/). Rows carrying the regression codes 18 or 20 were
# dropped above, so those codes never appear among the keys of kept records.
adat <- data.frame(taxon    = adat$taxon,
                   mass_g   = suppressWarnings(as.numeric(adat$Dry.mass)) / 1000,  # mg -> g (dry)
                   class    = ifelse(adat$Group == 'Cladocera', 'Branchiopoda', adat$Group),
                   ref_keys = SplitRefKeys(adat$Ref.dm, ','),
                   stringsAsFactors = FALSE)
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
adat <- adat[!grepl('\\b(sp|spp|cf|aff|indet)\\b', adat$taxon) & grepl('^[A-Z][a-z]+ [a-z]+$', adat$taxon), ]
adat$phylum <- 'Arthropoda'
mass_group <- 'crustacean_zooplankton'
adat$mass_g <- ToWetMass(adat$mass_g, from = 'dry', group = mass_group)
adat$n <- 1
adat$source_mass <- LabelWithConversion('Hebert_etal_2016', mass_group)
if (any(trimws(unlist(strsplit(adat$ref_keys[!is.na(adat$ref_keys)], ';', fixed = TRUE))) %in% c('18', '20')))
  stop('Hebert_etal_2016: regression reference code 18 or 20 among the keys of kept records')
if (anyNA(adat$ref_keys)) warning('Hebert_etal_2016: ', sum(is.na(adat$ref_keys)), ' record(s) without a dry-mass reference code')
HEB <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'phylum', 'class', 'ref_keys')]
save(HEB, file = file.path(wd_rdata, 'BodyMass_Hebert_etal_2016.Rdata'))
