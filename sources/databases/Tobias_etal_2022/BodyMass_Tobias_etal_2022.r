# AVONET (Tobias et al. 2022, Ecology Letters 25:581-597), Supplementary dataset 1,
# sheet AVONET1_BirdLife (BirdLife taxonomy, 11,009 species). Mass (g) is the
# species mean body mass. Rows whose mass is inferred from a reference species
# (Traits.inferred contains "Body Mass") or taken from EltonTraits genus averages
# or models are excluded so that only species-specific measured masses remain.
# Label 'Tobias_2022' matches the CiteID already used by the Google-Sheet
# override rows for this source.
adat <- readxl::read_excel(file.path(wd_source, 'AVONET_Supplementary_dataset_1.xlsx'),
                           sheet = 'AVONET1_BirdLife', na = c('', 'NA'))
adat <- as.data.frame(adat)
excl_source <- c('Inferred', 'EltonTraits_GenAvg', 'EltonTraits_Model')
adat <- adat[!(adat$Mass.Source %in% excl_source), ]
adat <- adat[is.na(adat$Traits.inferred) |
             !grepl('Body Mass', adat$Traits.inferred, ignore.case = TRUE), ]
adat <- adat[, c('Species1', 'Mass', 'Order1', 'Family1')]
colnames(adat) <- c('taxon', 'mass_g', 'order', 'family')
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
adat$class <- 'Aves'
adat$n <- 1
adat$source_mass <- 'Tobias_2022'
TOB <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'class', 'order', 'family')]
save(TOB, file = file.path(wd_rdata, 'BodyMass_Tobias_2022.Rdata'))
