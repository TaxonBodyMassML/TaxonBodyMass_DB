# González et al. (2025) StoichLife: a global dataset of plant and animal
# elemental content. Scientific Data 12:569; data from Dryad 10.5061/dryad.3tx95x6r2
# (CC0), sheet 'Data' exported as datapaper_2025_02_11_data.csv (28,049 records,
# 19,664 of them animals). One row per analysed individual (or pooled sample);
# `body.weight.gr` is the body DRY mass in grams (sheet 'Metadata'), present on
# 9,942 animal rows. Only the rows identified to species (`species.level == 'y'`,
# `sp.morphosp_revised` a clean binomial after the compilers' taxonomic revision)
# are used; morphospecies ('Formicidae sp.11', 'Culex sp.') and common-name
# labels leave with `species.level == 'n'`. The file has no sex or life-stage
# column (README.md, Filters). Dry mass is converted to wet grams with the
# group-specific factors of R/library/mass_conversion.r, chosen by class /
# phylum / habitat below; the conversion CiteIDs are appended to source_mass.
adat <- read.csv(file.path(wd_source, 'datapaper_2025_02_11_data.csv'), header = TRUE,
                 check.names = FALSE, stringsAsFactors = FALSE,
                 na.strings = c('', 'NA', '#N/A'), fileEncoding = 'UTF-8-BOM')
adat <- adat[adat$kingdom_revised %in% 'Animalia' & !is.na(adat$body.weight.gr), ]
adat$taxon <- trimws(adat$sp.morphosp_revised)
adat <- adat[adat$species.level %in% 'y', ]
if (!all(grepl('^[A-Z][a-z]+ [a-z]+$', adat$taxon)))
  stop('Gonzalez_2025: species-level name that is not a clean binomial: ',
       paste(head(unique(adat$taxon[!grepl('^[A-Z][a-z]+ [a-z]+$', adat$taxon)])), collapse = '; '))
adat$mass_g <- suppressWarnings(as.numeric(adat$body.weight.gr))
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]

# Exclusions (README.md, Imputed rows). The file carries no life-stage column,
# so only groups that are non-adult by biology or by their mass are removed:
#  - the aquatic stages of Odonata and Trichoptera (and Ephemeroptera,
#    Plecoptera, Megaloptera, none at species level) are nymphs and larvae, and
#    the freshwater Diptera of González et al. (2018) are the mosquito larvae of
#    bromeliad tanks (Culex, Anopheles; the adults are not aquatic). The nine
#    freshwater Diptera of Hambäck et al. (2009) are adults classified by larval
#    habitat and are kept;
#  - 'unpublished - Roussel': Salmo trutta and Salvelinus fontinalis at
#    0.18-0.32 mg 'dry mass', below the dry mass of a salmonid egg, so the unit
#    of these rows cannot be grams (unverifiable units);
#  - 'unpublished - Harrower': ant workers at 0.4-6.7 ug 'dry mass' (Camponotus
#    vicinus 6.7 ug, Solenopsis molesta 0.4 ug: two to three orders of magnitude
#    below published worker masses) beside one species at 0.4 mg; the unit is
#    inconsistent within the dataset (unverifiable units).
immature_orders <- c('Odonata', 'Trichoptera', 'Ephemeroptera', 'Plecoptera', 'Megaloptera')
immature <- adat$class_revised %in% 'Insecta' & adat$habitat %in% 'freshwater' &
  (adat$order_revised %in% immature_orders |
     (adat$order_revised %in% 'Diptera' & adat$data.source1 %in% 'Gonzalez et al. 2018'))
adat <- DropImputed(adat, immature, 'Gonzalez_2025',
                    'freshwater Odonata/Trichoptera nymphs and larvae and the bromeliad mosquito larvae of Gonzalez et al. 2018: non-adult records (no life-stage column)')
adat <- DropImputed(adat, adat$data.source1 %in% 'unpublished - Roussel', 'Gonzalez_2025',
                    'unpublished - Roussel: salmonids at 0.18-0.32 mg dry mass, below an egg: unverifiable units')
adat <- DropImputed(adat, adat$data.source1 %in% 'unpublished - Harrower', 'Gonzalez_2025',
                    'unpublished - Harrower: ant workers at 0.4-6.7 ug dry mass beside one at 0.4 mg: unverifiable units')
#  - Amphibia: the stream-salamander rows (Milanovich 2007, 2008, Milanovich &
#    Hopton 2014, Milanovich & Maerz) are larvae and the anuran rows (Rugenski
#    2013, Moody et al. 2017, Vanni et al. 2002) tadpoles and metamorphs:
#    Rhinella marina at 3 mg dry, Desmognathus quadramaculatus at 0.05-0.1 g
#    dry; all 13 species x source values sit 1.5-4 log10 below the database's
#    adult values (README.md). Non-adult records; the class is dropped.
adat <- DropImputed(adat, adat$class_revised %in% 'Amphibia', 'Gonzalez_2025',
                    'Amphibia: larval salamanders, tadpoles and metamorphs (every species x source value 1.5-4 log10 below the adult value): non-adult records')
#  - the fishes of the Vanni excretion-database sub-sources (data.type
#    Vanni_database: McIntyre et al. 2008, Torres & Vanni 2007, Small et al.
#    2011, Vanni et al. 2002, ...) are the small individuals of large species
#    that excretion studies sample (Lepomis macrochirus at 2.4 g wet, Hoplias
#    malabaricus at 13 g; per-source medians 0.7-1.6 log10 below the database's
#    values): non-adult records (owner decision 2026-10-04). The non-fish rows
#    of these sub-sources (Sterrett et al. 2015 turtles, a copepod, a snail) stay.
adat <- DropImputed(adat, adat$data.type %in% 'Vanni_database' & adat$class_revised %in% 'Actinopterygii', 'Gonzalez_2025',
                    'fishes of the Vanni excretion-database sub-sources: small individuals of large species, non-adult records (owner decision 2026-10-04)')
#  - the remaining Vanni-database rows (the Sterrett et al. 2015 turtles, one
#    Johnson et al. 2010 copepod, five 'McIntyre, PB, unpub' snails) are
#    verbatim copies of subsets of the record sets of Vanni_2017, a source of
#    this database since issue #99, and leave as copies (owner decision
#    2026-10-05).
adat <- DropImputed(adat, adat$data.type %in% 'Vanni_database', 'Gonzalez_2025',
                    'remaining Vanni-database rows (Sterrett et al. 2015 turtles, a copepod, a snail): copies of Vanni_2017 record subsets, now a source (owner decision 2026-10-05)')

# Conversion group of every record (dry -> wet), by the compilers' revised
# class / phylum and the habitat column (README.md, Mass type).
cls <- adat$class_revised; phy <- adat$phylum_revised; hab <- adat$habitat
grp <- rep(NA_character_, nrow(adat))
grp[cls %in% c('Insecta', 'Arachnida', 'Chilopoda', 'Diplopoda', 'Collembola', 'Diplura',
               'Symphyla', 'Pauropoda')] <- 'insect'            # terrestrial arthropods (Studier & Sevick 1992; non-insects by analogy, as Hishi_etal_2019)
grp[cls %in% c('Actinopterygii', 'Chondrichthyes', 'Elasmobranchii')] <- 'fish'
grp[cls %in% 'Aves'] <- 'bird'                                   # Horn & de la Vega 2016 (the Wadden Sea birds of this very source)
grp[cls %in% 'Mammalia'] <- 'mammal'                             # Rizzuto et al. 2019 (the snowshoe hares of this very source)
grp[cls %in% c('Amphibia', 'Reptilia')] <- 'vertebrate'           # generic factor, no conversion CiteID (issue #86)
grp[cls %in% c('Copepoda', 'Ostracoda', 'Branchiopoda', 'Hexanauplia')] <- 'crustacean_zooplankton'
grp[cls %in% 'Malacostraca' & hab %in% 'marine'] <- 'crustacean_zooplankton'  # pelagic euphausiids, hyperiids, mysids, decapods (Ikeda database)
grp[cls %in% 'Malacostraca' & !hab %in% 'marine'] <- 'invertebrate'            # freshwater shrimps and crayfish
grp[phy %in% 'Mollusca'] <- 'mollusc'
grp[phy %in% 'Annelida'] <- 'annelid'
grp[phy %in% 'Chaetognatha'] <- 'chaetognath'
grp[phy %in% c('Cnidaria', 'Ctenophora') | cls %in% c('Thaliacea', 'Appendicularia')] <- 'gelatinous_zooplankton'
grp[phy %in% c('Platyhelminthes', 'Nematoda', 'Acanthocephala')] <- 'helminth'
if (anyNA(grp))
  stop('Gonzalez_2025: no conversion group for class/phylum: ',
       paste(unique(paste(phy[is.na(grp)], cls[is.na(grp)], sep = '/')), collapse = '; '))
# Stoichiometric analyses of shelled molluscs are made on the soft tissue, so
# the dry mass of bivalves and of the freshwater snail is tissue mass and is
# scaled to whole wet mass including the shell (ToWetMass(whole = TRUE), the
# Brey 2010 shell ratios); the pelagic pteropods of the Ikeda database
# (Limacina, Clio, the naked Clione) are treated as whole animals, as in
# Ikeda_2014, and cephalopods have no shell.
whole <- cls %in% 'Bivalvia' | (cls %in% 'Gastropoda' & !hab %in% 'marine')
shell <- ifelse(cls %in% 'Bivalvia', 'bivalve', 'gastropod')
adat$mass_g <- ToWetMass(adat$mass_g, from = 'dry', group = grp, whole = whole, shell_group = shell)
adat$n <- 1
adat$source_mass <- LabelWithConversion('Gonzalez_2025', grp)

# The per-record reference key (`data.source1`: an author-year key, an
# 'unpublished - contributor' template label, or a sub-source of the Vanni /
# Ikeda / Elser databases), resolved in references.csv (built from the Dryad
# sheet 'References' by build_references.r), is kept as `ref_keys` for the
# primary-source attribution of issue #1. The one key that names two papers
# ('Jochum et al. 2016 / Drescher et al. 2016') is split into both; the other
# slashes join the contributors of one template dataset and are kept.
adat$ref_keys <- SplitRefKeys(sub('^Jochum et al. 2016 / Drescher et al. 2016$',
                                  'Jochum et al. 2016; Drescher et al. 2016', adat$data.source1), ';')
if (anyNA(adat$ref_keys)) warning('Gonzalez_2025: ', sum(is.na(adat$ref_keys)), ' record(s) without a data.source1 key')

for (col in c('phylum_revised', 'class_revised', 'order_revised', 'family_revised'))
  adat[[col]] <- iconv(as.character(adat[[col]]), to = 'ASCII//TRANSLIT')
GON <- data.frame(taxon = adat$taxon, mass_g = adat$mass_g, n = adat$n,
                  source_mass = adat$source_mass, ref_keys = adat$ref_keys,
                  phylum = adat$phylum_revised, class = adat$class_revised,
                  order = adat$order_revised, family = adat$family_revised,
                  stringsAsFactors = FALSE)
save(GON, file = file.path(wd_rdata, 'BodyMass_Gonzalez_2025.Rdata'))
