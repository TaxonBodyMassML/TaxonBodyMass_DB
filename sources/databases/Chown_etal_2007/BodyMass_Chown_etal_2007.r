# Chown et al. (2007) Functional Ecology 21:282-290, Supporting Information
# (fec1245_supmat.pdf, the publisher's Supporting Information file; the folder
# tracked the same supplement as a Word file, fec1245_supmat.doc, from
# 2026-09-28 to 2026-10-04). Appendix S2 lists body mass (mg) and metabolic rate
# for 391 insects compiled from the literature, each row citing its source as a
# superscript number (reference list 1-115 at the end of the supplement) or an
# asterisk (Chown lab, unpublished data); Appendix S1 gives individual masses
# for eight size-polymorphic ant species without reference marks. Both
# appendices and the reference list are parsed from the PDF by
# parse_chown_supmat.py into the two *_parsed.csv files and references.csv kept
# here. Masses are live (fresh) body masses as used in the metabolic-scaling
# analysis. Unidentified taxa ('Species 1', 'sp.', 'nr.') and subspecies
# suffixes are removed.
#
# Record set: the 347 S2 rows with both a Method and a Wing-status cell are the
# rows the first parse (textutil export of the .doc, 2026-09-28, anchored on
# those two columns) recovered and the database has carried since; the 44 rows
# with a blank Method (15) or Wing-status (29) cell were found when the PDF was
# parsed (issue #63) and are held back here until the owner decides on them
# (drop the filter below to add them).
s2 <- read.csv(file.path(wd_source, 'AppendixS2_insect_mass_parsed.csv'),
               stringsAsFactors = FALSE, na.strings = character(0),
               colClasses = c(Method = 'character', WingStatus = 'character', ref_keys = 'character'))
s2 <- s2[nzchar(s2$Method) & nzchar(s2$WingStatus), ]
stopifnot(nrow(s2) == 347)
s2 <- data.frame(taxon = s2$Species, mass_g = s2$Mass_mg / 1000,
                 order = s2$Order, family = s2$Family,
                 # the superscript reference number(s) or '*' of each row,
                 # resolved in references.csv (issue #1, SplitRefKeys())
                 ref_keys = SplitRefKeys(s2$ref_keys, ';'),
                 stringsAsFactors = FALSE)
s1 <- read.csv(file.path(wd_source, 'AppendixS1_ant_mass_parsed.csv'),
               stringsAsFactors = FALSE)
s1 <- data.frame(taxon = s1$Species, mass_g = s1$Mass_mg / 1000,
                 order = 'Hymenoptera', family = 'Formicidae',
                 ref_keys = NA_character_,     # S1 carries no reference marks
                 stringsAsFactors = FALSE)
adat <- rbind(s2, s1)
adat$taxon <- gsub('[*†Ŧ]', '', adat$taxon)
adat$taxon <- trimws(gsub('\\s*\\([^)]*\\)', '', adat$taxon))
adat$taxon <- sub('^([A-Z][a-z]+ [a-z]+).*$', '\\1', adat$taxon)     # drop subspecies
adat <- adat[grepl('^[A-Z][a-z]+ [a-z]+$', adat$taxon), ]
adat <- adat[!grepl('\\b(sp|spp|cf|aff|nr|indet)\\b', adat$taxon), ]
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
if (anyNA(adat$ref_keys[adat$family != 'Formicidae' | adat$order != 'Hymenoptera']))
  warning('Chown_etal_2007: S2 record(s) without a reference mark')
adat$class <- 'Insecta'
adat$n <- 1
adat$source_mass <- 'Chown_etal_2007'
CHO <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'class', 'order', 'family', 'ref_keys')]
save(CHO, file = file.path(wd_rdata, 'BodyMass_Chown_etal_2007.Rdata'))
