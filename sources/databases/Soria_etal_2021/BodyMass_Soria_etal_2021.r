# COMBINE (Soria et al. 2021, Ecology 102:e03344), file trait_data_reported.csv
# (figshare 13028255, CC BY 4.0): reported (non-imputed) values only.
# adult_mass_g is the species mean adult body mass in grams.
adat <- read.csv(file.path(wd_source, 'trait_data_reported.csv'), header = TRUE,
                 stringsAsFactors = FALSE, na.strings = c('', 'NA'))
adat <- adat[, c('iucn2020_binomial', 'adult_mass_g', 'order', 'family')]
colnames(adat) <- c('taxon', 'mass_g', 'order', 'family')
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0 & !is.na(adat$taxon), ]
adat$order  <- iconv(as.character(adat$order),  to = 'ASCII//TRANSLIT')
adat$family <- iconv(as.character(adat$family), to = 'ASCII//TRANSLIT')
adat$class <- 'Mammalia'
adat$n <- 1
adat$source_mass <- 'Soria_etal_2021'
SOR <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'class', 'order', 'family')]
save(SOR, file = file.path(wd_rdata, 'BodyMass_Soria_etal_2021.Rdata'))
