# McCoy & Gillooly (2008) Ecology Letters 11:710-716, Appendix S1 in the version
# corrected by the erratum (McCoy & Gillooly 2009, Ecology Letters 12:731-733,
# Wiley supplementary file ele_1338_sm_appendixs1; 'Temperature, Body Mass, and
# Mortality data with Sources'): 2,116 rows of Group | Species | Dry mass (g) |
# Temp. C | *Mortality (y-1) | Ref. for birds (779), fish (234), invertebrates
# (197), mammals (524), multicellular plants (348) and phytoplankton (34), each
# row keyed to one or more of the 30 numbered data references listed at the end
# of the appendix. Against the 2008 file (ELE_1190_sm_AppendixS1, 2,117 rows, 29
# references) the erratum changes no dry mass: it corrects 138 mortality rates,
# cites Siliqua patula to a new ref 30 (Taylor 1959) instead of ref 4, replaces
# ref 8 (Froese & Palomares 2000 for Hissmann et al. 1998), respells 'Sebastes
# jorani' as jordani and deletes the second (ref 16) Lamellibranchia row (#61).
# The appendix is parsed by parse_mcg_appendixS1.py (pdftotext -layout) into
# McCoy_2008_appendixS1.csv, which is read here; the publisher's file itself is
# not redistributed (README.md gives the download links).
# Brown, Hall & Sibly (2018, Nature Ecology & Evolution 2:262-268) Supplementary
# Table 1 reproduces this appendix row for row but without the reference column
# (2,021 of its 2,041 rows match the parse on group, genus, epithet, dry mass and
# temperature; the remainder are Brown's malformed, respelled or dropped rows, see
# README.md). The table therefore enters the database here, from the appendix,
# and no longer through Brown_etal_2018 (issue #7).
#
# Mass basis. The appendix header states "Dry mass was calculated as 1/4*wet
# mass", but the 'dry mass' column is only wet mass / 4 where the reference
# supplied a wet mass; the reference code decides the unit, so the rules below
# are keyed on group x ref (owner decisions of 2026-10-02, issue #7):
#  1. Bird and Mammal (all refs) and Fish refs 5 (Pauly 1980 asymptotic weights,
#     175 rows), 4 (Gillooly et al. 2001 killifish), 7 (Childress et al. 1980
#     mesopelagic fish), 8,9 (Latimeria) and 9,12 / 9,13 / 9,14 (orange roughy,
#     grenadiers): the references supplied wet masses, so wet mass is recovered
#     by inverting the source's own ratio, mass_g = value / 0.25 (Accipiter
#     gentilis 256.1 x 4 = 1,024.4 g, the mean of the male and female masses in
#     Dunning; ratio of other sources to these values 3.999 for birds, 4.000 for
#     mammals; the x4 fish values sit at a median 0.34 of the FishBase maximum
#     published weight for Pauly's stocks and at 0.26-0.84 for the other refs,
#     Latimeria 80 kg = the literature value). No external factor is involved, so
#     no conversion CiteID is appended (precedent: Cohen_2014, Mulder_2011).
#     Parus inornatus (blank ref) belongs to refs 1,2 and is kept. Cathartes aura
#     is dropped: the appendix prints 3.668E+03 g 'dry', already twice the wet
#     mass of a turkey vulture (1.4-2.0 kg; 12 other sources in this database), a
#     decimal-exponent error that x4 would turn into 14.7 kg; the value is not
#     'corrected'.
#  1b. Fish refs 9,10,11 (Cailliet et al. 2001 and Orr et al. 1998; 40 Sebastes
#     and Sebastolobus rows): the printed values are already wet maximum-type
#     weights, not wet / 4: they sit at a median 0.39 of the FishBase maximum
#     published weight (37 species with a maximum) and at 1.01x the other
#     sources' adult masses, where Pauly's validated values reach 0.34 and 1.6
#     only after x4; x4 would exceed the FishBase maximum for 27 of the 37
#     species (S. aleutianus 9.38 kg -> 37.5 kg). Used as printed (x1).
#  1c. Fish ref 6 (Mauchline 1988: Benthosema glaciale, Cyclothone braueri,
#     Lampanyctus macdonaldi, Maurolicus muelleri): neither reading fits; x4
#     gives 10x the other sources' masses and exceeds the maximum size of
#     Cyclothone braueri (0.52 g vs 0.44 g at the maximum length), x1 puts
#     asymptotic weights at 0.03 of the maximum; the unit is undeterminable and
#     the four rows are excluded (DropImputed).
#  2. Invertebrate, ref 25 (Brey 2001 data bank, 117 rows): the values are kJ
#     per mean individual, not grams (the temperatures end in .x5, i.e. Kelvin -
#     273.15, as in Brey's data bank; as grams or x4 grams the values exceed the
#     documented maximum size of 5 and 17 of 25 checked species, as kJ -> wet
#     mass they fit adult masses, median log10 error -0.12 against +0.13 as-is
#     and +0.73 x4). They are converted with ToWetMass(from = 'energy'):
#     divided by the class/order energy density (kJ per g wet mass, species-level
#     medians of Brey et al. 2010 Conversion04 'J / mgWM') and, for molluscs, by
#     the shell ratio WM/(WM+Shell) (bivalves 0.44, gastropods 0.40), so that
#     molluscs enter as whole wet mass including the shell; the conversion
#     CiteID Brey_2010 is appended to the label. Classes come from the genus map
#     below (the taxonomy cache is not available at parse time). Nucella lapillus
#     is dropped: the appendix prints 2.060E+01 where Brown et al. have 2.06,
#     and the two publications cannot be reconciled.
#  3. Invertebrate, ref 4 (Gillooly et al. 2001, 49 rows): Gammarus fossarum and
#     Gammarus roeseli are wet / 4 and are kept as value / 0.25; the laboratory
#     zooplankton (Daphnia, Acanthocyclops, Cyclops, Eucyclops, Mesocyclops,
#     Keratella, Filinia, Notholca) mix dry and dry/4 units and are excluded
#     (DropImputed). Siliqua patula (10 rows, ref 4 in the 2008 appendix, ref 30
#     Taylor 1959 in the erratum; values unchanged) keeps the same value / 0.25
#     treatment under either code until the owner rules on the new reference (#61).
#  4. Invertebrate, ref 6 alone (Mauchline 1988: Boreomysis microps,
#     Gnathophausia zoea, Gennadas elegans): value / 0.25.
#  5. Invertebrate, refs 6,26 (Mauchline euphausiids, 6 rows): units cannot be
#     verified; excluded (DropImputed).
#  6. Invertebrate deep-sea references: value / 0.25 for ref 18 (Prochaetoderma
#     yongei), 20 (Tindaria callistiformis), 22 Ophiocten hastatum, 23 (Echinus
#     acutus, E. elegans) and 9,27 (Ophiocten gracilis); excluded for ref 15
#     (Lamellibranchia, genus only; the erratum deleted the duplicate ref-16 row),
#     17 (Reticulammina labyrinthica), 19 (Vesicomyid sp.), 21 (Mytilid sp.), 24
#     and 22 Calyptogena magnifica, whose mass basis is undefined (DropImputed).
#  7. Multicellular plant and Phytoplankton rows are autotrophs and are dropped
#     first, without logging (filter_autotrophs.r would remove them anyway).
#  8. ref_keys carries the printed Ref code(s) with commas turned into '; '
#     ('1; 2', '9; 10; 11'); the codes are resolved in appendixS1_references.csv.
# Names are taken as printed (species_printed) with minimal cleaning: a
# parenthetical synonym ('Sula (= Morus) bassanus'), single-letter tokens (the
# abbreviated middle names of 'Accipiter n. nisus' and 'Cygnus c. columbianus',
# the 'f' of 'Bovallia gigantea f', the broken 's' of 'Pseudopleuronecte s
# americanus') and 'ssp.' / 'var. ...' suffixes are removed, and the appendix's
# abbreviation 'Strongylocentr.' / 'Strongylocentr' is expanded to
# Strongylocentrotus (droeb. -> droebachiensis; the printed genus is kept for
# S. franciscanus, the pipeline's name fixes handle the synonymy). Trinomials
# are truncated by the pipeline's FixFormatting and the remaining misspellings
# ('Acipsnser fulvescens', 'Aechmophorus accidentalis', 'Pseudopleuronecte
# americanus') by FixMisspellings, whose rules were written for the
# Brown_etal_2018 copy of the table.
adat <- read.csv(file.path(wd_source, 'McCoy_2008_appendixS1.csv'), stringsAsFactors = FALSE,
                 colClasses = c(ref = 'character'), na.strings = character(0))
groups <- c('Bird', 'Fish', 'Invertebrate', 'Mammal', 'Multicellular plant', 'Phytoplankton')
unknown <- setdiff(unique(adat$group), groups)
if (length(unknown) > 0) stop('McCoy_2008: unexpected group(s): ', paste(unknown, collapse = ', '))
adat <- adat[adat$group %in% c('Bird', 'Fish', 'Invertebrate', 'Mammal'), ]   # rule 7: autotrophs out

tx <- trimws(adat$species_printed)
tx <- gsub('\\s*\\([^)]*\\)', '', tx)                              # 'Sula (= Morus) bassanus'
tx <- gsub('(^|\\s)[A-Za-z]\\.?(?=\\s|$)', ' ', tx, perl = TRUE)    # 'n.', 'c.', 'f', broken 's'
tx <- sub('\\s+ssp\\.?$', '', tx)                                  # 'Colaptes auratus ssp.'
tx <- sub('\\s+var\\..*$', '', tx)                                 # 'Echinus acutus var. norvegicus'
tx <- sub('^Strongylocentr\\.? ', 'Strongylocentrotus ', tx)        # appendix abbreviation
tx <- sub('^Strongylocentrotus droeb\\.?$', 'Strongylocentrotus droebachiensis', tx)
adat$taxon <- trimws(gsub('\\s+', ' ', tx))

adat$dry_mass_g <- as.numeric(adat$dry_mass_g)
adat <- adat[!is.na(adat$dry_mass_g) & adat$dry_mass_g > 0, ]
adat$ref <- trimws(adat$ref)
genus  <- sub(' .*', '', adat$taxon)
inv    <- adat$group == 'Invertebrate'

# ---- rule per record, keyed on group x ref (see header) -----------------------
zooplankton <- c('Daphnia', 'Acanthocyclops', 'Cyclops', 'Eucyclops', 'Mesocyclops',
                 'Keratella', 'Filinia', 'Notholca')
fish <- adat$group == 'Fish'
rule <- rep(NA_character_, nrow(adat))
rule[!inv] <- 'quarter'                                                        # 1
rule[fish & adat$ref == '9,10,11'] <- 'asis'                                    # 1b
rule[fish & adat$ref == '6'] <- 'drop_fish6'                                    # 1c
rule[inv & adat$ref == '25'] <- 'energy'                                        # 2
rule[inv & adat$ref == '4' & genus == 'Gammarus'] <- 'quarter'                 # 3
rule[inv & adat$ref %in% c('4', '30') & genus == 'Siliqua'] <- 'quarter'        # 3 (ref 30 since the erratum)
rule[inv & adat$ref == '4' & genus %in% zooplankton] <- 'drop_zooplankton'      # 3
rule[inv & adat$ref == '6'] <- 'quarter'                                        # 4
rule[inv & adat$ref == '6,26'] <- 'drop_euphausiid'                             # 5
rule[inv & adat$ref %in% c('18', '20', '23', '9,27')] <- 'quarter'              # 6
rule[inv & adat$ref == '22' & genus == 'Ophiocten'] <- 'quarter'                # 6
rule[inv & adat$ref %in% c('15', '16', '17', '19', '21', '24')] <- 'drop_deepsea'  # 6
rule[inv & adat$ref == '22' & genus == 'Calyptogena'] <- 'drop_deepsea'         # 6
if (anyNA(rule))
  stop('McCoy_2008: no rule for ', paste(unique(paste(adat$group, adat$ref, adat$taxon)[is.na(rule)]),
                                         collapse = '; '))
adat$rule <- rule

# Nucella lapillus (ref 25): 2.060E+01 in the appendix, 2.06 in Brown et al.'s copy;
# the value is ambiguous between the two publications, so the record is dropped.
adat <- adat[!(adat$rule == 'energy' & adat$taxon == 'Nucella lapillus'), ]
# Cathartes aura (refs 1,2): printed 3.668E+03 g 'dry', twice a turkey vulture's wet
# mass before any x4; a decimal-exponent error in the appendix, dropped (see header).
adat <- adat[!(adat$group == 'Bird' & adat$taxon == 'Cathartes aura'), ]

# ---- rule 2: energy (kJ) -> whole wet mass, class/order from the genus --------
energy_group <- c(
  Anodonta = 'bivalve', Arctica = 'bivalve', Aulacomya = 'bivalve', Cardium = 'bivalve',
  Chamelea = 'bivalve', Chione = 'bivalve', Corbicula = 'bivalve', Donax = 'bivalve',
  Dosinia = 'bivalve', Egeria = 'bivalve', Eurhomalea = 'bivalve', Hiatella = 'bivalve',
  Ledella = 'bivalve', Lissarca = 'bivalve', Macoma = 'bivalve', Mercenaria = 'bivalve',
  Mesodesma = 'bivalve', Mya = 'bivalve', Nucula = 'bivalve', Parvicardium = 'bivalve',
  Perna = 'bivalve', Spisula = 'bivalve', Tapes = 'bivalve', Tellina = 'bivalve',
  Theora = 'bivalve', Unio = 'bivalve', Venerupis = 'bivalve', Venus = 'bivalve',
  Yoldia = 'bivalve', Zygochlamys = 'bivalve',
  Ancylus = 'gastropod', Haliotis = 'gastropod', Hydrobia = 'gastropod',
  Laevilacunaria = 'gastropod', Littorina = 'gastropod', Lymnaea = 'gastropod',
  Nacella = 'gastropod', Notoacmaea = 'gastropod', Nucella = 'gastropod',
  Philine = 'gastropod', Turbo = 'gastropod',
  Acanthochitona = 'polyplacophoran',
  Cassidulus = 'echinoid', Echinosigra = 'echinoid', Echinus = 'echinoid', Moira = 'echinoid',
  Sterechinus = 'echinoid', Strongylocentrotus = 'echinoid',
  Ophiocten = 'ophiuroid', Ophionepthys = 'ophiuroid', Ophionotus = 'ophiuroid', Ophiura = 'ophiuroid',
  Holothuria = 'holothurian',
  Chorismus = 'decapod', Pachygrapsus = 'decapod', Uca = 'decapod',
  Bovallia = 'amphipod', Hyalella = 'amphipod', Pontoporeia = 'amphipod',
  Aega = 'isopod', Serolis = 'isopod',
  Amphicteis = 'polychaete', Laeonereis = 'polychaete', Lumbrinereis = 'polychaete',
  Nephtys = 'polychaete', Nereis = 'polychaete', Pectinaria = 'polychaete',
  Scolelepis = 'polychaete', Terebellides = 'polychaete',
  Brachycentrus = 'aquatic_insect', Ephemerella = 'aquatic_insect', Epitheca = 'aquatic_insect')
genus <- sub(' .*', '', adat$taxon)
e <- adat$rule == 'energy'
unmapped <- setdiff(unique(genus[e]), names(energy_group))
if (length(unmapped) > 0) stop('McCoy_2008: no energy group for genus: ', paste(unmapped, collapse = ', '))
adat$mass_group <- NA_character_
adat$mass_group[e] <- unname(energy_group[genus[e]])

adat$mass_g <- NA_real_
q <- adat$rule == 'quarter'
adat$mass_g[q] <- adat$dry_mass_g[q] / 0.25                                  # invert dry = wet / 4
x1 <- adat$rule == 'asis'
adat$mass_g[x1] <- adat$dry_mass_g[x1]                                       # refs 9,10,11: already wet
adat$mass_g[e] <- ToWetMass(adat$dry_mass_g[e], from = 'energy', group = adat$mass_group[e])
adat$source_mass <- 'McCoy_2008'
adat$source_mass[e] <- LabelWithConversion('McCoy_2008', adat$mass_group[e])   # 'McCoy_2008; Brey_2010'

# ---- exclusions (rules 1c, 3, 5, 6), logged to audit/imputed_rows.csv ---------
adat <- DropImputed(adat, adat$rule == 'drop_fish6', 'McCoy_2008',
                    'mesopelagic fish rows of undeterminable unit (ref 6)')
adat <- DropImputed(adat, adat$rule == 'drop_zooplankton', 'McCoy_2008',
                    'lab zooplankton rows of mixed dry/dry-quarter units (ref 4)')
adat <- DropImputed(adat, adat$rule == 'drop_euphausiid', 'McCoy_2008',
                    'euphausiid rows with unverifiable units (refs 6,26)')
adat <- DropImputed(adat, adat$rule == 'drop_deepsea', 'McCoy_2008',
                    'deep-sea rows with undefined mass basis')
stopifnot(!anyNA(adat$mass_g), all(adat$mass_g > 0))

adat$n <- 1
adat$ref_keys <- ifelse(nzchar(adat$ref), gsub(',', '; ', adat$ref), NA_character_)
if (anyNA(adat$ref_keys)) warning('McCoy_2008: ', sum(is.na(adat$ref_keys)), ' record(s) without a reference code')
MCG <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'ref_keys')]
save(MCG, file = file.path(wd_rdata, 'BodyMass_McCoy_2008.Rdata'))
