# Hechinger et al. (2011) Ecology 92:791 (Ecological Archives E092-066),
# Metaweb_Nodes.txt (UTF-16): node tables for three Pacific-coast estuaries
# (CSM, EPB, BSQ). BodySize(g) is individual body mass as fresh weight including
# hard parts (metadata II.C.2). Only species-resolution, adult (or unstaged
# free-living) nodes are used, and only body sizes estimated from the species
# itself (BodySizeEstimation 'species' or 'population'); nodes whose size was
# approximated from another species ('approximation') are excluded. The three
# estuary values per species are left for RunMe Pass 1 to average.
adat <- read.delim(file.path(wd_source, 'Metaweb_Nodes.txt'), header = TRUE,
                   sep = '\t', quote = '', fileEncoding = 'UTF-16LE',
                   stringsAsFactors = FALSE, na.strings = c('', 'NA'),
                   check.names = FALSE)
stage <- trimws(tolower(adat$Stage))
adat <- adat[adat$Resolution == 'Species' &
             (is.na(stage) | stage == '' | stage == 'adult') &
             adat$BodySizeEstimation %in% c('species', 'population'), ]
adat <- adat[!is.na(adat$Genus) & !is.na(adat$SpecificEpithet), ]
adat$taxon <- trimws(paste(adat$Genus, adat$SpecificEpithet))
adat <- adat[, c('taxon', 'BodySize(g)', 'Kingdom', 'Phylum', 'Class', 'Order', 'Family')]
colnames(adat) <- c('taxon', 'mass_g', 'kingdom', 'phylum', 'class', 'order', 'family')
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
adat <- adat[!grepl('\\b(sp|spp|cf|aff|indet)\\b', adat$taxon) & grepl(' ', adat$taxon), ]
for (col in c('kingdom', 'phylum', 'class', 'order', 'family'))
  adat[[col]] <- iconv(as.character(adat[[col]]), to = 'ASCII//TRANSLIT')
adat$n <- 1
adat$source_mass <- 'Hechinger_etal_2011'
HEC <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'kingdom', 'phylum', 'class',
                'order', 'family')]
save(HEC, file = file.path(wd_rdata, 'BodyMass_Hechinger_etal_2011.Rdata'))
