# FoRAGE (DeLong & Uiterwaal 2018, KNB doi:10.5063/F17H1GTQ), data set version
# 2018-12-19: one functional-response data set per row with predator and prey
# masses in mg. The file is latin1-encoded; without fileEncoding, trimws() on
# the raw bytes fails in a UTF-8 locale ("input string 56 is invalid UTF-8").
adat <- read.csv(file.path(wd_source, 'FoRAGE_db_12_19_18_data_set.csv'), header = TRUE,
                 fileEncoding = 'latin1', stringsAsFactors = FALSE)

keep_pred <- is.na(adat$Predator.type) | trimws(adat$Predator.type) == '' |
             grepl('^adult|female|male', trimws(adat$Predator.type), ignore.case = TRUE)
keep_prey <- is.na(adat$Prey.type)    | trimws(adat$Prey.type) == '' |
             grepl('^adult|female|male', trimws(adat$Prey.type), ignore.case = TRUE)

adat1 <- adat[keep_pred, c('Predator.scientific.name', 'Predator.mass..mg.',
                           'Predator.mass.source.code')]
adat2 <- adat[keep_prey, c('Prey.scientific.name', 'Prey.mass..mg.',
                           'Prey.mass.source.code')]
colnames(adat1) <- colnames(adat2) <- c('taxon', 'mass_mg', 'code')

adat <- rbind(adat1, adat2)
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_mg)) / 1000
adat <- adat[!is.na(adat$mass_g), ]
# Mass source codes: 'original <taxon> mass/length/volume/carbon' is the study's
# own measurement, or its own measured dimension through a regression (kept;
# length-derived values are allometry-derived); 'alternate <taxon> ...' takes
# the mass or length from another species, genus, family, order or a generic
# zooplankter; '% adult mass' is a fraction of another mass; 'average genus/
# order mass' is a taxon average. 'average species mass' is kept.
adat$code <- trimws(tolower(adat$code))
adat <- DropImputed(adat,
                    grepl('^alternat', adat$code) | grepl('^%', adat$code) |
                      grepl('pred mass', adat$code) |
                      grepl('^average (genus|order)', adat$code),
                    'DeLong_etal_2018',
                    'mass source code: alternate taxon, % adult mass or genus/order average')
adat <- adat[, c('taxon', 'mass_g')]
adat$n <- 1
adat$source_mass <- 'DeLong_etal_2018'
DLb <- adat
save(DLb, file = file.path(wd_rdata, 'BodyMass_DeLong_etal_2018.Rdata'))
