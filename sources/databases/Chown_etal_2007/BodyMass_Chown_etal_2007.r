# Chown et al. (2007) Functional Ecology 21:282-290, Supplementary Material
# (fec1245_supmat.doc). Appendix S2 lists body mass (mg) and metabolic rate for
# insects compiled from the literature; Appendix S1 gives individual masses for
# eight size-polymorphic ant species. Both appendices were extracted from the
# Word file with `textutil -convert txt` and parsed into the two *_parsed.csv
# files kept here (parser anchored on the Method/Wing-status columns; 347 of 347
# S2 records recovered). Masses are live (fresh) body masses as used in the
# metabolic-scaling analysis. Unidentified taxa ('Species 1', 'sp.', 'nr.') and
# subspecies suffixes are removed.
s2 <- read.csv(file.path(wd_source, 'AppendixS2_insect_mass_parsed.csv'),
               stringsAsFactors = FALSE)
s2 <- data.frame(taxon = s2$Species, mass_g = s2$Mass_mg / 1000,
                 order = s2$Order, family = s2$Family, stringsAsFactors = FALSE)
s1 <- read.csv(file.path(wd_source, 'AppendixS1_ant_mass_parsed.csv'),
               stringsAsFactors = FALSE)
s1 <- data.frame(taxon = s1$Species, mass_g = s1$Mass_mg / 1000,
                 order = 'Hymenoptera', family = 'Formicidae', stringsAsFactors = FALSE)
adat <- rbind(s2, s1)
adat$taxon <- gsub('[*†Ŧ]', '', adat$taxon)
adat$taxon <- trimws(gsub('\\s*\\([^)]*\\)', '', adat$taxon))
adat$taxon <- sub('^([A-Z][a-z]+ [a-z]+).*$', '\\1', adat$taxon)     # drop subspecies
adat <- adat[grepl('^[A-Z][a-z]+ [a-z]+$', adat$taxon), ]
adat <- adat[!grepl('\\b(sp|spp|cf|aff|nr|indet)\\b', adat$taxon), ]
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
adat$class <- 'Insecta'
adat$mass_type <- 'wet'
adat$mass_group <- 'insect'
adat$n <- 1
adat$source_mass <- 'Chown_etal_2007'
CHO <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'class', 'order', 'family',
                'mass_type', 'mass_group')]
save(CHO, file = file.path(wd_rdata, 'BodyMass_Chown_etal_2007.Rdata'))
