RemoveNonTaxa <- function(dat) {

  # Family-level entries from Brose_etal_2018 (genus field is literally "Family").
  dat <- dat[!grepl("^Family_", dat$taxon), ]

  # Placeholder identification qualifiers used in place of species epithets.
  # Since #38 FixFormatting() writes them explicitly: a raw epithet that is a
  # placeholder (sp., spp., spec., indet., 'sp2', 'lassp8', 'species A', ...)
  # or an identification qualifier (cf., aff., nr., c.f.) leaves it as Genus_<word>, the word as written when it is one of those
  # below and sp / cf otherwise (audit/raw_name_patterns.csv, epithet-scope
  # rows); these suffixes then remove the record.
  # _sp    = species indeterminate (most common) and every morphospecies code
  # _spp   = species plural (unresolved group)
  # _spec  = spec. (six Brose_etal_2018 genera are mapped to genus-level
  #          records by fix_misspellings.r before this step and are kept)
  # _indet = indeterminate
  # _cf    = confer (compare; identification uncertain)
  # _aff   = affinis (close to the named species)
  # _nr    = near (closely related to but not identical to the named species)
  # _unk   = unknown species
  # _spX   = informal morphospecies code (e.g., spA, spB, spC, spD)
  dat <- dat[!grepl("_sp$",     dat$taxon, ignore.case = FALSE), ]
  dat <- dat[!grepl("_spp$",    dat$taxon, ignore.case = FALSE), ]
  dat <- dat[!grepl("_spec$",   dat$taxon, ignore.case = FALSE), ]
  dat <- dat[!grepl("_indet$",  dat$taxon, ignore.case = FALSE), ]
  dat <- dat[!grepl("_cf$",     dat$taxon, ignore.case = FALSE), ]
  dat <- dat[!grepl("_aff$",    dat$taxon, ignore.case = FALSE), ]
  dat <- dat[!grepl("_nr$",     dat$taxon, ignore.case = FALSE), ]
  dat <- dat[!grepl("_unk$",    dat$taxon, ignore.case = FALSE), ]
  dat <- dat[!grepl("_sp[A-Z]$", dat$taxon), ]
  dat <- dat[!grepl("^Order_",  dat$taxon, ignore.case = TRUE),  ]

  # Fragment and immature labels of groups identified above genus level
  # (Hrycik_2024: 'Oligochaeta Fragments' 9 rows, 'Tubificid fragment' 7,
  # 'Naidid fragment' 1, 'Oligochaeta immature' 1; its SpeciesList.csv also
  # names 'Enchytraeid fragment', 'Lumbriculid fragment' and 'Immature
  # lumbriculid', which carry no weight row). Body fragments weighed as a lot
  # and immatures sorted to a family are not adult records of any taxon (#44).
  # _fragment(s)  = fragments of a family- or class-level group
  # _immature(s)  = immatures of such a group ('immature tubificid with hairs'
  #                 is dropped earlier by the life-stage rule of #38)
  # Immature_     = the same label with the stage word first
  dat <- dat[!grepl("_fragments?$", dat$taxon), ]
  dat <- dat[!grepl("_immatures?$", dat$taxon), ]
  dat <- dat[!grepl("^Immatures?_", dat$taxon), ]

  # Uninformative genus-level unknown placeholders ('Unidentified 1' and
  # 'Unid. Chironomidae' arrive as Unidentified_sp / Unid_sp since #38; the
  # bare VertNet labels 'Undefinable' (5 rows) and 'Unidentifiable' (4 rows)
  # would otherwise enter the genus-level output as genera, #44).
  dat <- dat[!grepl('^(Unk|Unknown|Unid|Unidentified|Unidentifiable|Undefinable)($|_)', dat$taxon), ]

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
    "Oligochaeta_indet",               # class + indeterminate qualifier; not a species
    "Oligochaeta_type",                # class + morphotype qualifier; not a species
    "Oligochaete_type",                # spelling variant of Oligochaeta_type
    "Copepd_nauplii",                  # OCR corruption of "Copepod nauplii"
    "Copepod_nauplii",                 # DeLong_etal_2018 (capitalised form caught by FixFormatting)
    "Copepoda_nauplii",                # OCR corruption of "Copepoda nauplii"
    "Cyclopoid_copepodites",           # Order-level functional group"
    "Fish_eggs",
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
    "Predacious_nematodes",           # predatory nematode functional group
    "Scirtid_broad",                  # morphological functional label
    "Pergamasinae",                   # subfamily (Mesostigmata), not a genus; 'Pergamasinae (male)' once the sex mark is stripped (#38)
    "Pacific_herring",                # common name: 'Pacific herring, Clupea palasi' cut at the comma (Brown_etal_2018, #38)
    "Skate",                          # common name: 'Skate, Raja orinacea' cut at the comma (Brown_etal_2018, #38)
    "Diptera_larvae",                 # order + life-stage label: 'Diptera larvae/pupae' cut at the slash (Brose_etal_2018, #38)
    "Scyllarid_lobsters",             # family-level common name
    "Sea_birds",                      # common name for multiple taxa, not a binomial
    "Sea_fan",                        # common name for gorgonian corals, not a binomial
    "Sea_turtles",                    # common name for multiple taxa, not a binomial
    "Sipunculid_worms",               # phylum-level common name
    "Spiny_lobsters",                 # common name for multiple taxa, not a binomial
    "Stony_corals",                   # common name for order Scleractinia, not a binomial
    "Benthic_algae",                  # benthic algal community descriptor, not a taxon (Brose_etal_2018)
    "Other_algae",                    # catch-all algae category, not a taxon (Brose_etal_2018)
    "Symbiotic_algae",                # functional role descriptor, not a species
    "Tropical_atlantic",              # geographic+functional label, not a binomial
    "Unclassified_flagellates",       # classification label used in food-web databases
    "Unclassified_microflagellates",  # classification label used in food-web databases
    "UnID_chrysomonad",               # unidentified chrysophyte functional label
    "UNID_kinetoplastid",             # unidentified kinetoplastid functional label
    "Appendicularians_house",         # larvacean mucus house, not a taxon (Barnes_2008 prey)
    "Hatchet_fish",                   # common name for Sternoptychidae (Barnes_2008 prey)
    "Unidentified_crustacean"         # no valid species identifier (Barnes_2008 prey)
  )

  # Entries that cannot be linked to a valid genus or species binomial.
  invalid <- c(
    "Crayvertebrate_cambarus",     # malformed entry in Brown_etal_2018
    "Not_recognised",              # Soria_etal_2021 (COMBINE): iucn2020_binomial 'Not recognised' on 260 rows of taxa the IUCN 2020 list does not recognise; a placeholder, not a name (#44)
    # Makarieva_2008's "Crithidia (Strigomonas) oncopelti" and "Crithida (Strigomonas)
    # fasciculata" lose their subgenus in FixFormatting (#38) and reach fix_misspellings.r as
    # Crithidia_oncopelti and Crithida_fasciculata, mapped there to Strigomonas_oncopelti and
    # Crithidia_fasciculata (#36); they are not dropped here (an earlier "Crithidia strigomonas"
    # entry, with a space, never matched; #28).
    "Euschides_luctata",           
    "Glossotherium_myloides",      # historical grouping of extinct ground sloths
    "Hebridae_indet",              # family + indeterminate qualifier; not a species
    "Homo_spdenisova",             # Denisovans have no formal binomial
    "Larsia_iI",                   # two-letter placeholder epithet; not a species name
    "Magistrate_armhook",          # not a real taxon in Brown_etal_2018
    "Naia_io",                     # OCR corruption of unknown Naja species
    "Tanytarsini_i",               # Tanytarsini is a tribe name, not a genus; i not a valid epithet
    "Tanytarsini_iI",              # same
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

  # One-token functional-group labels and common names used as names in the
  # food-web compilations (#44). A cleaned name without an underscore is filed
  # as a genus-level record in RunMe.r section 3 and never reaches the
  # enrichment, so these words entered TaxonBodyMass_GenusLevel.csv as genera.
  # Row counts are records in the cached frames (main ab9af69). None is a
  # genus in the GBIF backbone; the three with a GBIF genus homonym are noted.
  # Latin names of ranks above genus (Oligochaeta, Chironomidae, Araneae,
  # Cyanobacteria, ...) are taxa and are left for a separate decision.
  functional_groups <- c(
    # microbial, planktonic and benthic resource groups
    "Algae",                       # Brose_etal_2018, 48 rows ('algae' of the Digel et al. 2014 soil webs, 'Algae' of the Florida island webs)
    "Amoebae",                     # Brose_etal_2018, 568 rows (Dutch microfauna webs); vernacular plural, not the genus Amoeba
    "Bacteria",                    # Brose_etal_2018, 1053 rows ('bacteria' 1016, 'Bacteria' 37); kingdom label used as a resource group
    "Ciliates",                    # Brose_etal_2018, 748 rows
    "Cryptophyte",                 # DeLong_etal_2018, 1 row; vernacular for a cryptophyte alga
    "Diatoms",                     # Brose_etal_2018, 261 rows
    "Eubactaria",                  # DeLong_etal_2018, 1 row; misspelt 'Eubacteria', a domain label
    "Flagellates",                 # Brose_etal_2018, 568 rows
    "Fungi",                       # Brose_etal_2018, 87 rows (Florida island and Iceland stream webs); kingdom label used as a resource group
    "Microfauna",                  # Brose_etal_2018, 106 rows (Caribbean reef web, Opitz 1996)
    "Microphytobenthos",           # Brose_etal_2018, 38 rows (Lough Hyne web, Jacob et al. 2015)
    "Nanoflagellates",             # Brose_etal_2018, 204 rows
    "Phytoplankton",               # Brose_etal_2018, 12 rows
    "PhytoP",                      # Brose_etal_2018, 82 rows; 'PhytoP' with common name 'PhytoPlamcton' (Mendonca et al. 2018 webs); GBIF parses it as the fly genus Phyto, a spurious match
    "Plankton",                    # Brose_etal_2018, 53 rows (Chilean intertidal webs, Kefi et al. 2015)
    "Scuticociliate",              # DeLong_etal_2010, 1 row; ciliate functional group (Scuticociliatia), described as removed in the source README
    "Zooplankton",                 # Brose_etal_2018, 25 rows
    # invertebrate group names (Brose_etal_2018 unless stated)
    "Arthropods",                  # 29 rows
    "Asteroids",                   # 27 rows; sea stars
    "Barnacles",                   # 12 rows
    "Bryozoan",                    # 1 row
    "Bryozoans",                   # 12 rows
    "Chitons",                     # 36 rows
    "Copepod",                     # 25 rows (Carpinteria web, Lafferty et al. 2006)
    "Crabs",                       # 128 rows
    "Echinoids",                   # 50 rows
    "Echiuroids",                  # 6 rows
    "Hemichordates",               # 10 rows
    "Holothurians",                # 17 rows
    "Hydrozoans",                  # 21 rows
    "Insect",                      # Hirt_etal_2017, 3 rows
    "Nematodes",                   # 6 rows (Ythan Estuary web, Cohen et al. 2009); the worms as a group, not the eucnemid beetle genus Nematodes that GBIF matches
    "Nemertean",                   # 25 rows
    "NonOribatida",                # 1 row; the non-oribatid mites of a soil web, a residual group
    "Octopuses",                   # 36 rows
    "Ophiuroids",                  # 43 rows
    "Ostracods",                   # 7 rows
    "Polychaetes",                 # 99 rows
    "Priapuloids",                 # 2 rows
    "Pycnogonids",                 # 9 rows
    "Rotifers",                    # 176 rows
    "Shrimps",                     # 129 rows
    "Sponges",                     # 30 rows
    "Squids",                      # 25 rows
    "Stomatopods",                 # 58 rows
    "Tanaids",                     # 21 rows
    "Tunicates",                   # 23 rows
    # vertebrate group names
    "Fish",                        # Raymond_2011, 1 row
    "Herring",                     # Brose_2005, 1 row
    "Lemmings",                    # Brose_etal_2018, 65 rows (Arctic tundra webs, Legagneux et al. 2014; taxonomy level 'family')
    "Passerines",                  # Brose_etal_2018, 34 rows (Legagneux et al. 2014)
    "Shorebirds",                  # Brose_etal_2018, 23 rows (Legagneux et al. 2014)
    "Waterfowl",                   # Brose_etal_2018, 41 rows (Legagneux et al. 2014)
    # Chichewa common names of the Lake Malawi web (Nsiku 1999) in Brose_etal_2018
    "Bombe",                       # 11 rows
    "Chambo",                      # 6 rows
    "Chilunguni",                  # 6 rows
    "Chisawasawa",                 # 10 rows
    "Kambuzi",                     # 8 rows
    "Kampango",                    # 8 rows
    "Matemba",                     # 16 rows
    "Mbuna",                       # 14 rows; GBIF holds 'Mbuna' only as a DOUBTFUL genus in Cichlidae, an artefact of the vernacular
    "Mcheni",                      # 8 rows
    "Mlamba",                      # 15 rows
    "Mpasa",                       # 4 rows
    "Nchila",                      # 4 rows
    "Ndunduma",                    # 12 rows
    "Nkholokolo",                  # 7 rows
    "Nkhono",                      # 14 rows; common-name column 'molluscs'
    "Nkunga",                      # 7 rows
    "Samwamowa",                   # 15 rows
    "Sanjika",                     # 4 rows
    "Usipa",                       # 10 rows
    "Utaka"                        # 12 rows
  )

  # Match after lowercasing to handle any remaining capitalisation variants.
  dat <- dat[!(tolower(dat$taxon) %in% c(tolower(nontaxa), tolower(invalid), tolower(autotrophs),
                                         tolower(functional_groups))), ]

  return(dat)
}
