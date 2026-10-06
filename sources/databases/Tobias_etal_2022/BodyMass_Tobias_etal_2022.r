# AVONET (Tobias et al. 2022, Ecology Letters 25:581-597), Supplementary dataset 1,
# sheet AVONET1_BirdLife (BirdLife taxonomy, 11,009 species). Mass (g) is the
# species mean body mass. Rows whose mass is inferred from a reference species
# (Traits.inferred contains "Body Mass") or taken from EltonTraits genus averages
# or models are excluded so that only species-specific measured masses remain.
# Label 'Tobias_2022' matches the CiteID already used by the Google-Sheet
# override rows for this source.
# Provenance (issue #1): the per-row mass source is kept as `ref_keys`
# (SplitRefKeys(), R/library/citations/parse_reflists.r) and resolved in
# references.csv (README.md, Provenance). `Mass.Source` is a code word defined
# in the Metadata sheet: 'Dunning' (the 2008 CRC Handbook of Avian Body Masses,
# key 'Dunning (2008)' of the Mass_Sources sheet), 'EltonTraits_Other' (a mass
# published by Wilman et al. 2014 from literature other than Dunning),
# 'DataFromSplit' (the parent species' mass after a taxonomic split), and
# 'Updated_literature' / 'Updated_live.sample', whose reference(s) stand in
# `Mass.Refs.Other`: the Citation keys of the Mass_Sources sheet, '; '-separated
# when a row cites two ('Jackson (1972); Dunning (2021)'), or the AVONET team's
# own 'Live sample (museum data)' / 'Live sample (field data)'.
adat <- readxl::read_excel(file.path(wd_source, 'AVONET_Supplementary_dataset_1.xlsx'),
                           sheet = 'AVONET1_BirdLife', na = c('', 'NA'))
adat <- as.data.frame(adat)
excl_source <- c('Inferred', 'EltonTraits_GenAvg', 'EltonTraits_Model')
adat <- adat[!(adat$Mass.Source %in% excl_source), ]
adat <- adat[is.na(adat$Traits.inferred) |
             !grepl('Body Mass', adat$Traits.inferred, ignore.case = TRUE), ]
keys <- ifelse(adat$Mass.Source %in% c('Updated_literature', 'Updated_live.sample'),
               adat$Mass.Refs.Other,
               ifelse(adat$Mass.Source %in% 'Dunning', 'Dunning (2008)', adat$Mass.Source))
adat$ref_keys <- SplitRefKeys(keys, ';')
adat <- adat[, c('Species1', 'Mass', 'Order1', 'Family1', 'ref_keys')]
colnames(adat) <- c('taxon', 'mass_g', 'order', 'family', 'ref_keys')
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
adat$class <- 'Aves'
adat$n <- 1
adat$source_mass <- 'Tobias_2022'
if (anyNA(adat$ref_keys))
  warning('Tobias_2022: ', sum(is.na(adat$ref_keys)), ' record(s) without a Mass.Source / Mass.Refs.Other key')
TOB <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'ref_keys', 'class', 'order', 'family')]
save(TOB, file = file.path(wd_rdata, 'BodyMass_Tobias_2022.Rdata'))
