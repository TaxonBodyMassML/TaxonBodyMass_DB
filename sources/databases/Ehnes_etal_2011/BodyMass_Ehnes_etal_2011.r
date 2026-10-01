# Ehnes, Rall & Brose (2011) Ecology Letters 14:993-1000, Appendix a) of the
# supplementary material (ele_1660_sm_meta-scaling-appendix.pdf): 3,661 respiration
# measurements of terrestrial (mainly soil) invertebrates with individual body
# weight in mg, compiled from 192 sources (incl. the Chown et al. 2007 insect data
# and the authors' own measurements). The PDF table was parsed with
# parse_ehnes_appendix.py into ehnes2011_appendix_a.csv (3,645 of 3,661 records;
# the 16 unparsed rows are unidentified 'Species 1'-type taxa). Weights are live
# (fresh) body masses, as used throughout the Ehnes et al. metabolic-scaling
# analyses. Genus-level, 'sp.', 'cf.' and juvenile ('juv.') records are dropped;
# individual records are averaged within species by RunMe Pass 1.
adat <- read.csv(file.path(wd_source, 'ehnes2011_appendix_a.csv'), header = TRUE,
                 stringsAsFactors = FALSE, na.strings = c('', 'NA'))
adat$taxon <- trimws(adat$sp)
adat <- adat[grepl('^[A-Z][a-z]+ [a-z]+$', adat$taxon) &
             !grepl('\\b(sp|spp|cf|aff|juv)\\b', adat$taxon), ]
adat$mass_g <- suppressWarnings(as.numeric(adat$mg)) / 1000
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
class_map <- c(Insecta = 'Insecta', Chilopoda = 'Chilopoda', Arachnida = 'Arachnida',
               Oribatida = 'Arachnida', Prostigmata = 'Arachnida', Mesostigmata = 'Arachnida',
               Clitellata = 'Clitellata', Isopoda = 'Malacostraca', Progoneata = NA_character_)
adat$class  <- unname(class_map[adat$g2])
adat$phylum <- adat$g1
adat$order  <- ifelse(adat$g2 %in% c('Insecta', 'Clitellata', 'Isopoda', 'Progoneata'), adat$g3,
                      ifelse(adat$g2 %in% c('Chilopoda', 'Arachnida'), adat$g4, adat$g2))
adat$n <- 1
adat$source_mass <- 'Ehnes_etal_2011'
EHN <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'phylum', 'class', 'order')]
save(EHN, file = file.path(wd_rdata, 'BodyMass_Ehnes_etal_2011.Rdata'))
