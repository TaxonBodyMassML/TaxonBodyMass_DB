RemoveNonTaxa <- function(dat) {

  # Family-level entries from Brose_etal_2018 (genus field is literally "Family").
  dat <- dat[!grepl("^Family_", dat$taxon), ]

  # Placeholder identification qualifiers used in place of species epithets:
  # _sp   = species indeterminate (most common)
  # _spp  = species plural (unresolved group)
  # _cf   = confer (compare; identification uncertain)
  # _nr   = near (closely related to but not identical to the named species)
  # _unk  = unknown species
  # _spX  = informal morphospecies code (e.g., spA, spB, spC, spD)
  dat <- dat[!grepl("_sp$",     dat$taxon, ignore.case = FALSE), ]
  dat <- dat[!grepl("_spp$",    dat$taxon, ignore.case = FALSE), ]
  dat <- dat[!grepl("_cf$",     dat$taxon, ignore.case = FALSE), ]
  dat <- dat[!grepl("_nr$",     dat$taxon, ignore.case = FALSE), ]
  dat <- dat[!grepl("_unk$",    dat$taxon, ignore.case = FALSE), ]
  dat <- dat[!grepl("_sp[A-Z]$", dat$taxon), ]
  dat <- dat[!grepl("_spec$",   dat$taxon, ignore.case = FALSE), ]
  dat <- dat[!grepl("^Order_",  dat$taxon, ignore.case = TRUE),  ]

  # Uninformative genus-level unknown placeholders.
  dat <- dat[!grepl('^(Unk|Unknown)($|_)', dat$taxon), ]

  # Placeholder "species" token as genus or epithet.
  dat <- dat[!grepl('(^|_)[Ss]pecies($|_)', dat$taxon), ]

  # Functional-group labels used as taxon names in food-web databases.
  nontaxa <- c(
    "Acari_phyto",
    "Acari_pred",
    "Bathylagidae",                     # family-level common name
    "Bacterivorous_nematodes",
    "Calanoid_copepods",
    "Calanoid_nauplii",                # DeLong_etal_2018 (capitalised form caught by FixFormatting)
    "Candiacervus_spii",               # informal sp. II tag stripped; fossil deer genus
    "Chironomidae_indet",              # family + indeterminate qualifier; space→underscore after FixFormatting
    "Chironomid_larvae",               # variant prefix for Chironomidae larvae
    "Chironomidae_juv",                # family + life-stage qualifier; not a species
    "Chironomidae_larvae",             # family + life-stage qualifier
    "Diptera_larvaepupae",             # pooled larva+pupa stage descriptor; not a species
    "Oligochaeta_indet",               # class + indeterminate qualifier; not a species
    "Oligochaeta_type",                # class + morphotype qualifier; not a species
    "Oligochaete_type",                # spelling variant of Oligochaeta_type
    "Copepd_nauplii",                  # OCR corruption of "Copepod nauplii"
    "Copepod_nauplii",                 # DeLong_etal_2018 (capitalised form caught by FixFormatting)
    "Copepoda_nauplii",                # OCR corruption of "Copepoda nauplii"
    "Cyclopoid_copepodites",           # Order-level functional group"
    "Fish_eggs",
    "Fish_eggslarvae",
    "Brachyuran_larvae",               # decapod larval stage descriptor; not a species (DeLong_etal_2010)
    "Lepadogaster_zebrina",            # misidentified as gastropod; actually a clingfish (Gobiesocidae); no reliable correction (Brose_etal_2018)
    "Omnivorous_nematodes",            # functional-group label, not a species; incorrectly classified as insect (DeLong_etal_2010)
    "Order_coleoptera",                # order-level descriptor, not a species; invalid binomial (Brose_etal_2018)
    "Order_isopoda",                    # order-level descriptor, not a species; invalid binomial (Brose_etal_2018)
    "Tetraphyllidean_larva",           # tapeworm larval stage descriptor (Cestoda: Tetraphyllidea); not a species binomial
    "Fish_larvae",
    "Root_feeding",
    "Sea_anemones",
    "Antarctic_phytoplanktonic",      # phytoplankton functional group label
    "Boreal_clubhook",                # common-name descriptor, not a binomial
    "Fish_fry",                       # juvenile-fish functional group
    "Fungivorous_nematodes",          # fungal-feeding nematode functional group
    "Green_gammaridean",              # colour+group descriptor, not a species
    "Harpacticoid_copepods",          # order-level functional group
    "Hermit_crabs",                   # common name for multiple taxa, not a binomial
    "Hymenostome_ciliate",            # ciliate functional group label
    "Pacific_herring",                # common name used in food-web datasets
    "Predacious_nematodes",           # predatory nematode functional group
    "Scirtid_broad",                  # morphological functional label
    "Scyllarid_lobsters",             # family-level common name
    "Sea_birds",                      # common name for multiple taxa, not a binomial
    "Sea_fan",                        # common name for gorgonian corals, not a binomial
    "Sea_turtles",                    # common name for multiple taxa, not a binomial
    "Sipunculid_worms",               # phylum-level common name
    "Skate_raja",                     # hybrid descriptor (order common name + genus)
    "Spiny_lobsters",                 # common name for multiple taxa, not a binomial
    "Stony_corals",                   # common name for order Scleractinia, not a binomial
    "Benthic_algae",                  # benthic algal community descriptor, not a taxon (Brose_etal_2018)
    "Other_algae",                    # catch-all algae category, not a taxon (Brose_etal_2018)
    "Symbiotic_algae",                # functional role descriptor, not a species
    "Tropical_atlantic",              # geographic+functional label, not a binomial
    "Unclassified_flagellates",       # classification label used in food-web databases
    "Unclassified_microflagellates",  # classification label used in food-web databases
    "Unidentified_amoeba",            # no valid binomial; non-species entry (DeLong_etal_2010)
    "Unidentified_bacterium",         # no valid species identifier (DeLong_etal_2010)
    "UnID_chrysomonad",               # unidentified chrysophyte functional label
    "UNID_kinetoplastid"              # unidentified kinetoplastid functional label
  )

  # Entries that cannot be linked to a valid genus or species binomial.
  invalid <- c(
    "Crayvertebrate_cambarus",     # malformed entry in Brown_etal_2018
    "Crithidia strigomonas",       # historical grouping of insect trypanosomatid flagellates
    "Euschides_luctata",           
    "Glossotherium_myloides",      # historical grouping of extinct ground sloths
    "Hebridae_indet",              # family + indeterminate qualifier; not a species
    "Homo_spdenisova",             # Denisovans have no formal binomial
    "Larsia_iI",                   # two-letter placeholder epithet; not a species name
    "Magistrate_armhook",          # not a real taxon in Brown_etal_2018
    "Naia_io",                     # OCR corruption of unknown Naja species
    "Octolasion_tyrtaeumxxl",      # size-class code appended to species name
    "Octolasion_tyrtaeumxxxl",     # size-class code appended to species name
    "Tanytarsini_i",               # Tanytarsini is a tribe name, not a genus; i not a valid epithet
    "Tanytarsini_iI",              # same
    "Bathylagidae",                # family name used as taxon entry; no species-level data
    "Catopsis_s",                  # single-letter placeholder epithet; not resolvable
    "Chordeumatidae_juv",          # family + life-stage qualifier; not a species
    "Clubionidae_juv",             # family + life-stage qualifier; not a species
    "Cystacanthfish_bcav",         # not a valid genus; acanthomorpha placeholder
    "Cystacanthfish_musc",         # not a valid genus; acanthomorpha placeholder
    "Edwardsii_mIN",               # malformed; mixed-case stub; not resolvable
    "Elephas_namadicus",           # extinct South Asian elephant; no extant mass data
    "Entomobryidae_juv",           # family + life-stage qualifier; not a species
    "Lysigamasus_jugincola",
    "Lysigamasus_minorleitneriae",
    "Linyphiidae_juv",             # family + life-stage qualifier; not a species
    "Lumbricidae_undiff",          # family + undifferentiated qualifier; not a species
    "Macrochelidae_juv",           # family + life-stage qualifier; not a species
    "Macropus_piltonesis",         # extinct wallaby (Pleistocene); not an extant species
    "Mesoveliidae_indet",          # family + indeterminate qualifier; not a species
    "Muscidae_copro",              # family + ecological qualifier (coprophilous)
    "Muscidae_flor",               # family + ecological qualifier (floricole)
    "Mytilid_e",                   # malformed single-letter suffix; not a valid binomial
    "Naucoridae_indet",            # family + indeterminate qualifier; not a species
    "Order_enchytraeidae",         # malformed; not a valid binomial
    "Order_gastropoda",            # malformed; not a valid binomial
    "Order_hemiptera",             # malformed; not a valid binomial (Brose_etal_2018)
    "Order_nematoda",              # malformed; not a valid binomial
    "Order_pseudoscorpionidae",    # malformed; not a valid binomial
    "Order_psocoptera",            # malformed; not a valid binomial
    "Paramegatherium_nazarrei",        # historical grouping of extinct ground sloths
    "Parasitidae_juv",             # family + life-stage qualifier; not a species
    "Pergamasinae_juv",            # subfamily + life-stage qualifier; not a species
    "Pergamasinae_male",           # subfamily + sex qualifier; not a species
    "Phaoniinae_indet",            # subfamily + indeterminate qualifier; not a species
    "Phlaeothripidae_phyto",       # family + ecological qualifier (phytophagous)
    "Phlaeothripidae_pred",        # family + ecological qualifier (predaceous)
    "Piceaen_gelmanii",            # OCR corruption of Picea engelmannii; not a valid binomial
    "Plesiorycteropus_germainepetterae",      # historical grouping of extinct Malagasy aardvarks
    "Protemnodon_nombensis",        # historical grouping of extinct wallabies
    "Saguinus_caffer",             # not a recognised valid species; treated as invalid (Makarieva_2008)
    "Scirtidae_larvae",            # family + life-stage qualifier; not a species
    "Sclerocalyptus_migoyanus",      # historical grouping of extinct glyptodonts
    "Sminthuridae_juv",            # family + life-stage qualifier; not a species
    "Spirocerus_kiakhtensis",        # extinct antelope
    "Staphylinidae_spec",          # spec placeholder; family-level only
    "Tanytarsus_bruchonidae",      # family-group suffix in epithet; malformed
    "Toxodon_bilobidens",          # extinct South American ungulate
    "Trigonodops_lopesi",          # extinct South American mammal (Notoungulata)
    "Trichomonas_nasai",           # historical grouping of trichomonad flagellates
    "Trichomonas_tritrichomonas",  # historical grouping of trichomonad flagellates
    "Vesicomyid_e",                # adjectival stub; not a valid binomial
    "Glyptotherium_cylindricum",   # extinct glyptodont (Cingulata: Glyptodontidae); Pliocene–Pleistocene North America (outlier_report_2)
    "Glyptotherium_floridanum",    # extinct glyptodont (Cingulata: Glyptodontidae); Pliocene–Pleistocene North America (outlier_report_2)
    "Glyptotherium_mexicanum",     # extinct glyptodont (Cingulata: Glyptodontidae); Pleistocene Mexico/Central America (outlier_report_2)
    "Xaymaca_fulvopulvis",         # extinct Jamaican spiny rat (Echimyidae); no extant mass data (outlier_report_2)
    "Xenorhinotherium_bahiense",   # extinct South American litoptern (Macraucheniidae); no extant mass data (outlier_report_2)
    "Rhinobrycon_negrensis",        # monotypic characid max 3.9 cm SL; no published mass data; ERRONEOUS_MASS with no recoverable value (AmphiBIO / outlier_report_2)
    "Gaussia_princeps"             # mesopelagic copepod; excluded from dataset
  )

  # Primarily autotrophic taxa erroneously included in heterotroph-focused databases.
  # These are valid species names but are plants, algae, or fungi — not consumers.
  autotrophs <- c(
    "Camelia_sasnqua",            # Theaceae (flowering plant); labelled as arachnid in Brown_etal_2018
    "Drepanocladusex_annulatus",  # aquatic moss (Bryophyta); garbled entry in Brown_etal_2018
    "Nitzschia_pandora"           # diatom (Bacillariophyceae); labelled as bivalve in Brown_etal_2018
  )

  # Match after lowercasing to handle any remaining capitalisation variants.
  dat <- dat[!(tolower(dat$taxon) %in% c(tolower(nontaxa), tolower(invalid), tolower(autotrophs))), ]

  return(dat)
}
