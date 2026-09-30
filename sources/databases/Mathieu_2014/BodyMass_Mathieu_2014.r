# Mathieu & Davies (2014) Journal of Biogeography 41:1204-1214, traits.txt: traits
# of French earthworm species compiled from Bouche (1972, Lombriciens de France).
# maximal_weight is the maximum fresh body mass in mg (e.g. Lumbricus terrestris
# 15000 mg); species names use '.' as separator and follow Fauna Europaea.
adat <- read.delim(file.path(wd_source, 'traits.txt'), header = TRUE, sep = '\t',
                   stringsAsFactors = FALSE, na.strings = c('', 'NA'),
                   fileEncoding = 'latin1')
adat <- data.frame(taxon  = gsub('\\.', ' ', adat$species.name),
                   mass_g = suppressWarnings(as.numeric(adat$maximal_weight)) / 1000,  # mg -> g
                   family = adat$family, stringsAsFactors = FALSE)
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
adat <- adat[grepl('^[A-Z][a-z]+ [a-z]+$', adat$taxon) & !grepl('\\b(sp|spp|cf|aff)\\b', adat$taxon), ]
adat$class <- 'Clitellata'
adat$n <- 1
adat$source_mass <- 'Mathieu_2014'
MAT <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'class', 'family')]
save(MAT, file = file.path(wd_rdata, 'BodyMass_Mathieu_2014.Rdata'))
