# Eklöf et al. (2017) PeerJ 5:e2906, supplemental data set (Eklof_etal_2017.xlsx,
# sheet 'Data', exported to Eklof_etal_2017.csv): per-individual dry weight (DW, g)
# and ash-free dry weight (AFDW, g) of 14 common epibenthic invertebrate taxa of
# the Swedish Baltic Sea coast, by body-size class (mm, juveniles to adults). No
# wet mass is reported. For the bivalves, gastropods and the barnacle Amphibalanus
# improvisus DW includes the shell (AFDW:DW median 13 %, IQR 10-19 %, vs median
# 69 %, IQR 59-85 % for the chitinous crustaceans and insects), so for these
# shelled taxa AFDW is converted to shell-free wet tissue mass with the 'afdw'
# factors (the convention of the Brey 2010 mollusc factors); unshelled taxa are
# converted from DW with the 'dry' factors of R/library/mass_conversion.r.
# LabelWithConversion() appends the conversion CiteIDs to the source label.
adat <- read.csv(file.path(wd_source, 'Eklof_etal_2017.csv'), header = TRUE)
adat$taxon <- trimws(as.character(adat$Taxa))
adat$Class <- iconv(as.character(adat$Class), to = 'ASCII//TRANSLIT')
group_map <- c(Insecta = 'insect', Crustacea = 'crustacean_zooplankton',
               Gastropoda = 'mollusc', Bivalvia = 'mollusc')
unknown <- setdiff(unique(adat$Class), names(group_map))
if (length(unknown) > 0) stop('Eklof_etal_2017: unmapped class(es): ', paste(unknown, collapse = ', '))
grp     <- unname(group_map[adat$Class])
shelled <- adat$Class %in% c('Bivalvia', 'Gastropoda') | adat$taxon == 'Amphibalanus improvisus'
from    <- ifelse(shelled, 'afdw', 'dry')
val     <- ifelse(shelled, adat$AFDW, adat$DW)
keep    <- !is.na(val) & val > 0
adat <- adat[keep, ]; grp <- grp[keep]; from <- from[keep]; val <- val[keep]
adat$mass_g <- ToWetMass(val, from = from, group = grp)
adat$n <- 1
adat$source_mass <- LabelWithConversion('Eklof_etal_2017', grp)
# Crustacea is a subphylum, not a class: leave class NA for those rows
adat$class <- ifelse(adat$Class == 'Crustacea', NA_character_, adat$Class)
EK <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'class')]
save(EK, file = file.path(wd_rdata, 'BodyMass_Eklof_etal_2017.Rdata'))
