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

  # Uninformative genus-level unknown placeholders.
  dat <- dat[!grepl('^(Unk|Unknown)($|_)', dat$taxon), ]

  # Placeholder "species" token as genus or epithet.
  dat <- dat[!grepl('(^|_)[Ss]pecies($|_)', dat$taxon), ]

  # Functional-group labels used as taxon names in food-web databases.
  nontaxa <- c(
    "Acari_phyto",
    "Acari_pred",
    "Bacterivorous_nematodes",
    "Calanoid_copepods",
    "Calanoid_nauplii",               # DeLong_etal_2018 (capitalised form caught by FixFormatting)
    "Fish_eggs",
    "Fish_eggslarvae",
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
    "Symbiotic_algae",                # functional role descriptor, not a species
    "Tropical_atlantic",              # geographic+functional label, not a binomial
    "Unclassified_flagellates",       # classification label used in food-web databases
    "Unclassified_microflagellates",  # classification label used in food-web databases
    "UnID_chrysomonad",               # unidentified chrysophyte functional label
    "UNID_kinetoplastid"              # unidentified kinetoplastid functional label
  )

  # Entries that cannot be linked to a valid genus or species binomial.
  invalid <- c(
    "Crayvertebrate_cambarus",     # malformed entry in Brown_etal_2018
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
    "Entomobryidae_juv",           # family + life-stage qualifier; not a species
    "Linyphiidae_juv",             # family + life-stage qualifier; not a species
    "Lumbricidae_undiff",          # family + undifferentiated qualifier; not a species
    "Macrochelidae_juv",           # family + life-stage qualifier; not a species
    "Mesoveliidae_indet",          # family + indeterminate qualifier; not a species
    "Muscidae_copro",              # family + ecological qualifier (coprophilous)
    "Muscidae_flor",               # family + ecological qualifier (floricole)
    "Mytilid_e",                   # malformed single-letter suffix; not a valid binomial
    "Naucoridae_indet",            # family + indeterminate qualifier; not a species
    "Parasitidae_juv",             # family + life-stage qualifier; not a species
    "Pergamasinae_juv",            # subfamily + life-stage qualifier; not a species
    "Pergamasinae_male",           # subfamily + sex qualifier; not a species
    "Phaoniinae_indet",            # subfamily + indeterminate qualifier; not a species
    "Phlaeothripidae_phyto",       # family + ecological qualifier (phytophagous)
    "Phlaeothripidae_pred",        # family + ecological qualifier (predaceous)
    "Scirtidae_larvae",            # family + life-stage qualifier; not a species
    "Sminthuridae_juv",            # family + life-stage qualifier; not a species
    "Staphylinidae_spec",          # spec placeholder; family-level only
    "Tanytarsus_bruchonidae",      # family-group suffix in epithet; malformed
    "Vesicomyid_e"                 # adjectival stub; not a valid binomial
  )

  # Match after lowercasing to handle any remaining capitalisation variants.
  dat <- dat[!(tolower(dat$taxon) %in% c(tolower(nontaxa), tolower(invalid))), ]

  return(dat)
}
