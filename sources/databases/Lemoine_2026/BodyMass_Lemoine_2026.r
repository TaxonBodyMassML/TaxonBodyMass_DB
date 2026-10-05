# Lemoine, Lechopier, Marichal, Molin & Coulis (2026) Eur. J. Soil Biol.
# 130:103854, calibration data set of the image-based biomass method:
# mass_surface_data.csv from CIRAD Dataverse (doi:10.18167/DVN1/SCH4AV, v1.0,
# CC BY 4.0; semicolon-separated, decimal commas). One row per individual soil
# macroinvertebrate collected alive in Martinique (2021-2023) and weighed
# fresh within 24 h on a microbalance (mass_fresh_mg; Methods 2.2), then
# freeze-dried for dry mass (mass_dry_mg, 921 individuals) and scanned for the
# paper's area/perimeter allometries. Only the weighed fresh masses enter the
# database: the dry masses, the ImageJ morphometrics and the regression
# estimates of the paper are not used, so no value here is image-derived.
adat <- read.csv(file.path(wd_source, 'mass_surface_data.csv'), header = TRUE,
                 sep = ';', dec = ',', stringsAsFactors = FALSE, check.names = FALSE,
                 na.strings = c('', 'NA'), encoding = 'UTF-8')
adat <- adat[, c('species', 'mass_fresh_mg', 'mass_dry_mg', 'class', 'order', 'family',
                 'larve', 'id_morphotype')]
adat$taxon  <- trimws(adat$species)
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_fresh_mg)) / 1000   # mg -> g (fresh)
# Twelve individuals carry a dry mass only (five Chondromorpha xanthotricha,
# five Nanostreptus geayi, one Dichogaster bolaui, one Haplocyclodesmus
# angustipes); their fresh mass was not recorded and they are not converted,
# since every one of these species has weighed fresh individuals (README.md).
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
# The source writes one species-level identification with the family in
# front and the binomial in brackets; the binomial is the identification.
adat$taxon[adat$taxon == 'Curculionidae (Metamasius hemipterus)'] <- 'Metamasius hemipterus'
# Individuals not identified to species. The `species` column mixes binomials
# with morphospecies codes: genus- or family-level placeholders
# ('Nylanderia sp', 'Ataenius_sp', 'Gryllidae sp1', 'Rhinodrilidae_sp',
# 'Phyllophaga sp - Larve'), genus-less codes ('sp_isoptera', 'sp1_formicidae',
# 'Larve_coleo', 'Cloporte Blanc', 'Orthoporus R.lezarde') and two
# identifications qualified by cf. ('Olios cf. sanctivincenti', 'Spherarmadillo
# cf. nebulosus'). The raw-name vocabulary of FixFormatting() reads the
# placeholders and the cf. qualifiers but not the genus-less codes (which it
# would file as binomials or stop the run on), so every label that is not a
# plain binomial is dropped here through DropImputed(), logged in two groups.
# 'Clivina (Paraclivina) tuberculata' keeps its subgenus for the vocabulary,
# which strips it (subgenus rule), and is a binomial for this purpose.
is_binomial <- grepl('^[A-Z][a-z]+ (\\([A-Z][a-z]+\\) )?[a-z]+$', adat$taxon) &
               !grepl(' sp$', adat$taxon)
is_cf       <- grepl('^[A-Z][a-z]+ cf\\. [a-z]+$', adat$taxon)
adat <- DropImputed(adat, is_cf, 'Lemoine_2026',
                    'identification qualified by cf. (Olios cf. sanctivincenti, Spherarmadillo cf. nebulosus): not a species-level record')
adat <- DropImputed(adat, !is_binomial[!is_cf], 'Lemoine_2026',
                    'morphospecies code or genus-/family-level placeholder (Genus sp, sp1, sp_<order>, Larve_coleo, Cloporte Blanc, ...): not identified to species')
# Life stage: `larve` is TRUE for larvae and nymphs (holometabolous larvae and
# the nymphs of cockroaches, earwigs and ants; Hermetia illucens occurs only
# as larvae), FALSE for the rest and NA where it was not recorded (186 rows of
# the file). TRUE rows are dropped as non-adult records; NA is not evidence of
# a life stage and those rows are kept (README.md). The authors sampled
# 'the entire range of body sizes, from the smallest juvenile stages to fully
# grown adults' within species (Methods 2.1), so the kept FALSE/NA rows are
# field individuals of all post-larval sizes, not adult means.
adat <- DropImputed(adat, adat$larve %in% TRUE, 'Lemoine_2026',
                    'larval or nymphal stage (larve = TRUE): not adult records')
adat$n <- 1
adat$source_mass <- 'Lemoine_2026'
# Taxonomy hints from the file (class, order, family); a family cell that is
# not a family name (the genus 'Cryptops' written for Cryptops doriae) is
# blanked, and the phylum follows from the class.
adat$family[!grepl('idae$', adat$family)] <- NA_character_
adat$phylum <- ifelse(adat$class == 'Clitellata', 'Annelida',
                      ifelse(adat$class == 'Gastropoda', 'Mollusca', 'Arthropoda'))
LEM <- data.frame(taxon = adat$taxon, mass_g = adat$mass_g, n = adat$n,
                  source_mass = adat$source_mass, phylum = adat$phylum,
                  class = adat$class, order = adat$order, family = adat$family,
                  stringsAsFactors = FALSE)
save(LEM, file = file.path(wd_rdata, 'BodyMass_Lemoine_2026.Rdata'))
