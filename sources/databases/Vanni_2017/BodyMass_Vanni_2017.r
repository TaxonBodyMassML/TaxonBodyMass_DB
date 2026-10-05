# Vanni et al. (2017) A global database of nitrogen and phosphorus excretion
# rates of aquatic animals. Ecology 98:1475 (doi 10.1002/ecy.1792), data file
# Aquatic_animal_excretion_data.csv (Ecological Archives; 10,534 excretion
# measurements of field-caught freshwater and marine animals from 92 sources,
# 'Source name' an author-year key, an 'unpubl' label or 'Ikeda database').
# Every record carries the DRY mass in grams of the incubated animal ('Dry
# mass (g)'; soft tissue only for molluscs and turtles; Metadata S1, Class II
# B.3.a): invertebrates were dried and weighed, vertebrates were mostly
# weighed live and the compilers converted wet to dry mass with DM = 0.25 WM.
# Only the rows named with a clean binomial are used (README.md, Filters);
# dry mass is converted back to wet grams with the group factors of
# R/library/mass_conversion.r (the vertebrate classes with the generic 0.25,
# the inverse of the compilers' own factor); the study key of every row is
# kept as `ref_keys`, resolved in references.csv (Metadata S1, 'Data source
# references'). The file has classic-Mac line endings (CR only) and a few
# non-ASCII bytes of mixed encoding (one key, one species name), handled below.
adat <- read.csv(file.path(wd_source, 'Aquatic_animal_excretion_data.csv'), header = TRUE,
                 check.names = FALSE, stringsAsFactors = FALSE,
                 na.strings = c('', '.'), encoding = 'latin1')
stopifnot(nrow(adat) == 10534)
squish <- function(x) gsub('\\s+', ' ', trimws(x))
to_ascii <- function(x) iconv(enc2utf8(as.character(x)), from = 'UTF-8', to = 'ASCII//TRANSLIT', sub = '?')
adat$key   <- squish(to_ascii(adat[['Source name']]))
adat$key   <- sub('^B[^ ]*mstedt & Tande 1985$', 'Bamstedt & Tande 1985', adat$key)   # one garbled byte in 'Båmstedt'
adat$taxon <- squish(to_ascii(adat[['Species name']]))
adat$taxon <- sub('^Notemigonus crysoleucas.*$', 'Notemigonus crysoleucas', adat$taxon)  # a stray byte after the epithet
adat$mass_dry <- suppressWarnings(as.numeric(adat[['Dry mass (g)']]))
adat <- adat[!is.na(adat$mass_dry) & adat$mass_dry > 0, ]

# Names (README.md, Filters). The data name the animal as the study did: a
# binomial, a genus or family with 'sp.', a stage or a pooled group. Clean-ups
# that follow the rules of audit/raw_name_patterns.csv are made here, because
# a bracket group the pipeline has no rule for ('(aka ...)') stops the run:
#  - a bracket group after the genus (a subgenus or an alternative genus:
#    'Cosmocalanus (Undinula) darwinii', 'Hypsophrys (Neetroplus) nematopus')
#    or after the binomial (a synonym: 'Atherinella hubbsi (Melanirus hubbsi)',
#    'Pseudocaranx dentex (aka Longirostrum delicatissimus)', a treatment
#    label) is removed and the first-written name kept;
#  - 'Lucilus (Notropis) cornutus' is the common shiner Luxilus cornutus
#    (misspelt genus);
#  - a lowercase third token is a subspecies and folds into the species
#    ('Dreissena rostriformis bugensis', 'Lampsilis radiata siliquoidea',
#    'Salmo trutta fario');
#  - the two generations of Salpa fusiformis ('-Blastozoid', '-Oozoid') are
#    both adult forms and fold into the species, as Kiorboe_2013's
#    'Salpa maxima. Agg'; 'Euphausia superba gravid female' loses its
#    condition mark and stays.
adat$taxon <- sub('^Lucilus \\(Notropis\\) cornutus$', 'Luxilus cornutus', adat$taxon)
adat$taxon <- squish(gsub('\\([^)]*\\)', '', adat$taxon))
adat$taxon <- sub('^([A-Z][a-z]+ [a-z]+) [a-z]+$', '\\1', adat$taxon)
adat$taxon <- sub('^Salpa fusiformis-(Blastozoid|Oozoid)$', 'Salpa fusiformis', adat$taxon)
adat$taxon <- sub('^Euphausia superba gravid female$', 'Euphausia superba', adat$taxon)

# Exclusions through DropImputed() (logged to audit/imputed_rows.csv; README.md,
# Imputed rows), in this order:
#  1. names that label a larval or juvenile stage: the calyptopis / furcilia
#     stages of Euphausia superba ('C3', 'F1-F2', ...), 'Euphausia pacifica late
#     Fursilia', 'Furcilia larva', 'Megalopa larva', 'Copepod nauplii &
#     copepodids', 'Veliger larva', '<Genus> larva' (Zaitzevia, Sialis,
#     Phyllosoma), and the 1.7 mg 'Ranzania laevis' of the Ikeda database, an
#     ocean sunfish larva (adults weigh kilograms): non-adult records;
stage <- grepl('larva|Fursilia|Furcilia|nauplii|copepodid|megalopa|\\bC[0-9]|\\bF[0-9]', adat$taxon, ignore.case = TRUE) |
  adat$taxon %in% 'Ranzania laevis'
adat <- DropImputed(adat, stage, 'Vanni_2017',
                    'larval and juvenile stages named in the taxon (euphausiid calyptopis/furcilia, megalopa, nauplii, veliger, insect larvae) and the 1.7 mg Ranzania laevis larva: non-adult records')
# Species-level rows only: a clean binomial after the clean-ups above (the
# 'Genus sp.', family, order and pooled-group names leave here; the one
# 'Dytiscidae adult' / 'Zaitzevia adult' pair is not a species either).
adat <- adat[grepl('^[A-Z][a-z]+ [a-z]+$', adat$taxon) & !grepl(' (adult|larva)$', adat$taxon), ]
#  2. Insecta: every insect was incubated in water, so the species-level rows
#     (chironomid, chaoborid, mayfly and caddisfly names) are larvae and nymphs,
#     as the freshwater Odonata / Trichoptera / Diptera rows of Gonzalez_2025:
#     non-adult records;
adat <- DropImputed(adat, adat$Class %in% 'Insecta', 'Vanni_2017',
                    'Insecta: aquatic larvae and nymphs (chironomids, Chaoborus, mayflies, caddisflies): non-adult records')
#  3. Amphibia: tadpoles (Rugenski 2013, Vanni et al. 2002, Whiles et al. 2009:
#     Bufo marinus at 7.5 mg dry) and larval or small salamanders (Milanovich,
#     Munshaw et al. 2013); the two species with a database value sit 1.6-1.9
#     log10 below it, as the StoichLife amphibians (Gonzalez_2025): non-adult
#     records;
adat <- DropImputed(adat, adat$Class %in% 'Amphibia', 'Vanni_2017',
                    'Amphibia: tadpoles, metamorphs and larval salamanders (species x study values 1.6-1.9 log10 below the adult values): non-adult records')
#  4. Osteichthyes: excretion studies incubate the small individuals of their
#     species (species x study geometric means a median 0.8 log10 below the
#     database's values over 60 pairs, 0.3-1.9 by study; README.md, Filters),
#     so the fishes are excluded as non-adult records, as the fishes of the
#     Vanni-database sub-sources of Gonzalez_2025 were (owner decision
#     2026-10-04). Option (b) of issue #99; comment this one call out to
#     ingest every fish record (option a).
adat <- DropImputed(adat, adat$Class %in% 'Osteichthyes', 'Vanni_2017',
                    'Osteichthyes: small individuals of their species sampled for excretion (median 0.8 log10 below the database values): non-adult records (issue #99, option b)')

# Conversion group of every record (dry -> wet; README.md, Mass type), by the
# file's Class and Ecosystem Type / Habitat columns.
cls <- adat$Class; eco <- adat[['Ecosystem Type']]; hab <- adat$Habitat
grp <- rep(NA_character_, nrow(adat))
grp[cls %in% c('Osteichthyes', 'Amphibia', 'Reptilia')] <- 'vertebrate'        # 0.25: the inverse of the compilers' DM = 0.25 WM (Metadata S1)
grp[cls %in% 'Insecta'] <- 'insect'
grp[cls %in% c('Maxillopoda', 'Branchiopoda', 'Ostracoda')] <- 'crustacean_zooplankton'
grp[cls %in% 'Malacostraca' & eco %in% 'Marine'] <- 'crustacean_zooplankton'  # euphausiids, mysids, amphipods, shrimps (Kiørboe 2013)
grp[cls %in% 'Malacostraca' & !eco %in% 'Marine'] <- 'invertebrate'           # freshwater shrimps, crayfish, amphipods (Brey 2010)
grp[cls %in% c('Bivalvia', 'Gastropoda', 'Cephalopoda')] <- 'mollusc'
grp[cls %in% c('Polychaeta', 'Clitellata')] <- 'annelid'
grp[cls %in% 'Sagittoidea'] <- 'chaetognath'
grp[cls %in% c('Thaliacea', 'Appendicularia', 'Scyphozoa', 'Hydrozoa', 'Tentaculata', 'Nuda')] <- 'gelatinous_zooplankton'
grp[cls %in% 'Turbellaria'] <- 'helminth'
if (anyNA(grp))
  stop('Vanni_2017: no conversion group for class: ', paste(unique(cls[is.na(grp)]), collapse = '; '))
# The dry mass of molluscs is soft tissue (Metadata S1), scaled to whole wet
# mass including the shell with the Brey 2010 shell ratios for bivalves and
# benthic gastropods; the pelagic pteropods of the Ikeda database (Clio,
# Limacina, Clione, ...) are whole animals, as in Ikeda_2014 and Gonzalez_2025,
# and cephalopods have no shell. Turtles are soft tissue too (no shell ratio
# is available; README.md).
whole <- cls %in% 'Bivalvia' | (cls %in% 'Gastropoda' & !hab %in% 'Pelagic')
shell <- ifelse(cls %in% 'Bivalvia', 'bivalve', 'gastropod')
adat$mass_g <- ToWetMass(adat$mass_dry, from = 'dry', group = grp, whole = whole, shell_group = shell)
adat$n <- 1                                   # one incubated animal per record (the smallest were pooled, mass per individual)
adat$source_mass <- LabelWithConversion('Vanni_2017', grp, ifelse(whole, shell, grp))

# The per-row study key (`Source name`, one key per row; StoichLife's
# Vanni_database rows cite the same strings), resolved in references.csv, is
# kept as `ref_keys` for the primary-source attribution of issue #1.
adat$ref_keys <- SplitRefKeys(adat$key, ';')
if (anyNA(adat$ref_keys)) warning('Vanni_2017: ', sum(is.na(adat$ref_keys)), ' record(s) without a Source name')

for (col in c('Phylum', 'Class', 'Order', 'Family'))
  adat[[col]] <- to_ascii(adat[[col]])
VAN <- data.frame(taxon = adat$taxon, mass_g = adat$mass_g, n = adat$n,
                  source_mass = adat$source_mass, ref_keys = adat$ref_keys,
                  phylum = adat$Phylum, class = adat$Class, order = adat$Order, family = adat$Family,
                  stringsAsFactors = FALSE)
save(VAN, file = file.path(wd_rdata, 'BodyMass_Vanni_2017.Rdata'))
