FixMisspellings <- function(dat) {

  # --- Genus prefix substitutions ---
  # Applied first so that subsequent specific corrections can reference the
  # corrected genus name (e.g. Holmesina_septentriolis rather than
  # Holmesi_septentriolis).

  genus_prefixes <- list(
    c("Aligator_",        "Alligator_"),        # Aligator -> Alligator (multiple species)
    c("Holmesi_",         "Holmesina_"),         # Holmesi__occidentalis etc. (after FixFormatting __ -> _)
    c("Lonchorhi_",       "Lonchorhina_"),       # Lonchorhi__aurita etc. (after FixFormatting)
    c("Mystaci_",         "Mystacina_"),         # Mystaci__robusta etc. (after FixFormatting)
    c("PseudoNitzschia_", "Pseudonitzschia_"),   # PseudoNitzschia_heimii etc. (capitalisation)
    c("Strongylocentr_",  "Strongylocentrotus_") # Strongylocentr_droeb etc. (multiple species)
  )
  # NOTE: single-species genus errors are handled as exact-match corrections below
  # (Auriparis_flaviceps, Catjartes_aura, Chaoborys_punctipennis) to avoid
  # silently renaming any future data that legitimately begins with those prefixes.

  for (fix in genus_prefixes) {
    dat$taxon <- sub(paste0("^", fix[[1]]), fix[[2]], dat$taxon)
  }


  # --- Specific taxon corrections ---
  # Ordered: epithet fixes that depend on the genus prefix corrections above
  # appear after the prefix entries that produce them.

  corrections <- c(

    # Epithet fixes following genus prefix corrections
    "Alligator_mississipiensis"       = "Alligator_mississippiensis",
    "Holmesina_septentriolis"         = "Holmesina_septentrionalis",
    "Strongylocentrotus_droeb"        = "Strongylocentrotus_droebachiensis",

    # Truncated epithet stubs
    "Neisseria_elon"                  = "Neisseria_elongata",
    "Serratia_mar"                    = "Serratia_marcescens",

    # Genus corrections for single-species cases (cannot use prefix substitution
    # without risk of affecting valid plant/other genera with the same name).
    "Auriparis_flaviceps"             = "Auriparus_flaviceps",            # Verdin; demoted from prefix fix — only one species
    "Catjartes_aura"                  = "Cathartes_aura",                 # Turkey Vulture; demoted from prefix fix — only one species
    "Chaoborys_punctipennis"          = "Chaoborus_punctipennis",         # Phantom Midge; demoted from prefix fix — only one species
    "Coleus_monedula"                 = "Coloeus_monedula",

    # Epithet misspellings (pre-existing)
    "Salmo_rutta"                     = "Salmo_trutta",
    "Daphnia_magma"                   = "Daphnia_magna",
    "Trachinocephalus_trachinus"      = "Trachinocephalus_myops",
    "Tursiops_truncates"              = "Tursiops_truncatus",

    # Duplicate pairs: merge less-accepted spelling to accepted form.
    "Accipiter_cooperi"               = "Accipiter_cooperii",
    "Eolophus_roseicapillus"          = "Eolophus_roseicapilla",
    "Hydrochoeris_hydrochaeris"       = "Hydrochoerus_hydrochaeris",
    "Lagopus_mutus"                   = "Lagopus_muta",
    "Madoqua_kirki"                   = "Madoqua_kirkii",


    # Entries correctable to a valid name
    "Aphanocapsa_pCC"                 = "Aphanocapsa",                    # PCC culture code stripped; genus valid
    "Bacillus_megate"                 = "Bacillus_megaterium",            # truncated; restored full epithet
    "Beneckea_na"                     = "Beneckea",                       # truncated epithet stripped; genus valid
    "Candiacervus_spii"               = "Candiacervus",                   # informal sp. II tag stripped; fossil deer genus
    "Cricotopus_i"                    = "Cricotopus",                     # single-letter epithet stripped; genus valid
    "Cricotopus_iI"                   = "Cricotopus",                     # two-letter epithet stripped; genus valid
    "Delftia_acido"                   = "Delftia_acidovorans",            # truncated; restored full epithet
    "Encoptolophus_s"                 = "Encoptolophus",                  # single-letter epithet stripped; genus valid
    "Eumops_bo"                       = "Eumops",                         # truncated epithet stripped; genus valid
    "Formica_sstr"                    = "Formica",                        # sensu stricto tag stripped; genus valid
    "Galaxiidae_anomalus"             = "Galaxias_anomalus",              # family used as genus; correct to Galaxias
    "Galaxiidae_new"                  = "Galaxias",                       # family + placeholder; reduce to genus Galaxias
    "Genus_microvelia"                = "Microvelia",                     # placeholder genus replaced with actual genus
    "Himasthla_b"                     = "Himasthla",                      # single-letter epithet stripped; genus valid
    "Hydrobiosis_type"                = "Hydrobiosis",                    # type placeholder stripped; caddisfly genus valid
    "Lamellibranchia_e"               = "Lamellibranchia",                # single-letter epithet stripped; tubeworm genus valid
    "Larsia_i"                        = "Larsia",                         # single-letter epithet stripped; genus valid
    "Lepidostoma_genus"                   = "Lepidostoma",                # parenthetical tag stripped by FixFormatting → becomes Lepidostoma_genus; caddisfly genus valid
    "Synechocystis_pCC"               = "Synechocystis",                  # PCC culture code stripped; genus valid


# Audit 8/20/2026

    # --- Near-duplicate misspellings  ---

    # A
    "Acanthocercus_annectans"         = "Acanthocercus_annectens",        # Peters 1869 original
    "Acanthostracion_polygonium"      = "Acanthostracion_polygonius",     # Honeycomb Cowfish accepted form
    "Acanthostracion_quadricomis"     = "Acanthostracion_quadricornis",   # missing r
    "Acanthurus_chirugus"             = "Acanthurus_chirurgus",           # Doctorfish; chirugus omits r
    "Acipenser_oxyrhynchus"           = "Acipenser_oxyrinchus",           # Mitchill 1815 original
    "Acrochordus_aradurae"            = "Acrochordus_arafurae",           # Arafura Sea; transposition
    "Aechmophorus_accidentalis"       = "Aechmophorus_occidentalis",      # Western Grebe; phonetic corruption
    "Aeronautes_sexatilis"            = "Aeronautes_saxatalis",           # White-throated Swift; wrong vowels
    "Afroedura_pondolia"              = "Afroedura_pongola",              # Pongola River; transposition
    "Agapornis_fisheri"               = "Agapornis_fischeri",             # Fischer's Lovebird; missing c
    "Amphidinium_cartarae"            = "Amphidinium_carterae",           # honors Ruth Carter; transposition
    "Amphidinium_carteri"             = "Amphidinium_carterae",           # female honoree takes -ae not -i
    "Anolis_bonariensis"              = "Anolis_bonairensis",             # from Bonaire island
    "Anthops_ortus"                   = "Anthops_ornatus",                # corruption of ornatus
    "Aotus_azarai"                    = "Aotus_azarae",                   # Azara's Night Monkey; MSW3/IUCN form
    "Apomys_hylocetes"                = "Apomys_hylocoetes",              # Mearns 1905; missing o
    "Ardea_cinera"                    = "Ardea_cinerea",                  # Grey Heron; missing e
    "Ardea_herodius"                  = "Ardea_herodias",                 # Great Blue Heron; herodius corruption
    "Artedidraco_loennbergi"          = "Artedidraco_lonnbergi",          # honors Lönnberg; umlaut substitution not in original
    "Ascomorpha_eucadis"              = "Ascomorpha_ecaudis",             # rotifer; e-caudis; transposition
    "Aspidoscelis_deppii"             = "Aspidoscelis_deppei",            # Deppe ends in vowel; ICZN Art 31 gives -i
    "Aspidoscelis_sexlinata"          = "Aspidoscelis_sexlineata",        # sexlinata drops e from linea
    "Automeris_jacunda"               = "Automeris_jucunda",              # Latin jucunda (pleasant); wrong vowel
    "Azospirillum_brasiliense"        = "Azospirillum_brasilense",        # Tarrand 1979 original spelling

    # B
    "Barbonymus_schwanefeldii"        = "Barbonymus_schwanenfeldii",      # honors Schwanenfeld; missing n
    "Bathypolypus_articus"            = "Bathypolypus_arcticus",          # Arctic; missing c
    "Bodo_saliens"                    = "Bodo_saltans",                   # O.F. Müller 1786 established saltans
    "Botaurus_lentigosus"             = "Botaurus_lentiginosus",          # American Bittern; missing -ino-
    "Brachionus_calcyiflorus"         = "Brachionus_calyciflorus",        # transposed y and ci
    "Buphagus_erythrorynchus"         = "Buphagus_erythrorhynchus",       # erythrorynchus drops h from rhynchus

    # C
    "Calanus_finnmarchicus"           = "Calanus_finmarchicus",           # Gunnerus 1770 original; spurious double n
    "Candacia_ethiopica"              = "Candacia_aethiopica",            # Dana 1849 original; missing ae
    "Capra_aegaerus"                  = "Capra_aegagrus",                 # Erxleben 1777; missing g
    "Caprimulgus_europeus"            = "Caprimulgus_europaeus",          # Linnaeus 1758; missing a
    "Centropages_abdominaris"         = "Centropages_abdominalis",        # invalid Latin; abdominaris not valid
    "Cercotrichas_coryphoeus"         = "Cercotrichas_coryphaeus",        # Greek koryphaios; coryphoeus garbled
    "Chaetomorpha_gracilaris"         = "Chaetomorpha_gracilis",          # gracilaris invalid Latin form
    "Chalcophaps_inidica"             = "Chalcophaps_indica",             # simple transposition
    "Chaos_carolinensis"              = "Chaos_carolinense",              # Chaos is neuter; -ense not -ensis
    "Chlamydomonas_reinhadri"         = "Chlamydomonas_reinhardii",       # honors Reinhard; missing d + garbled genitive
    "Chodromorpha_xanthotricha"       = "Chondromorpha_xanthotricha",     # Lemoine_2026, 4 rows: the source writes Chondromorpha (Paradoxosomatidae) on its five dry-only rows of the same species; missing n (#76)
    "Cinclosoma_castanotus"           = "Cinclosoma_castanotum",          # -soma is Greek neuter; -um required
    "Circus_macroarus"                = "Circus_macrourus",               # Pallid Harrier; macroarus omits u
    "Clupea_pallassii"                = "Clupea_pallasii",                # honors Pallas; spurious double s
    "Coccyzus_erythrophthalmus"       = "Coccyzus_erythropthalmus",       # Wilson 1811 original spelling
    "Cololabis_aira"                  = "Cololabis_saira",                # Pacific Saury; dropped leading s
    "Corcorax_melanoramphos"          = "Corcorax_melanorhamphos",        # White-winged Chough; missing h in Greek rh
    "Craspedacusta_sowerbyi"          = "Craspedacusta_sowerbii",         # Lankester 1880 original
    "Crocodylus_johnsoni"             = "Crocodylus_johnstoni",           # honors Johnstone not Johnson
    "Cryptoblepharus_cygnatus"        = "Cryptoblepharus_cognatus",       # cygnatus not valid form
    "Cynopterus_titthaecheileus"      = "Cynopterus_titthaecheilus",      # Temminck 1825 original; extra e

    # D
    "Dasyurus_hallacatus"             = "Dasyurus_hallucatus",            # Northern Quoll; transposition a/u
    "Dendrocopus_major"               = "Dendrocopos_major",              # Great Spotted Woodpecker; Dendrocopus not valid; correct genus is Dendrocopos
    "Dendrelaphis_caudolineolatus"    = "Dendrelaphis_caudolineatus",     # caudolineolatus not a recognized form
    "Desmognathus_ochrophaes"         = "Desmognathus_ochrophaeus",       # Dusky Salamander; missing u

    # H
    "Hydraena_homalaena"              = "Hydraena_homolaena",             # vowel substitution
    "Hypsiglena_unaocularus"          = "Hypsiglena_unaocularis",         # wrong 3rd-decl ending -us

    # I
    "Idotea_balthica"                 = "Idotea_baltica",                 # spurious h
    "Isodyctia_steifera"              = "Isodictya_setifera",             # Steifera is a misspelling of setifera

    # K
    "Kerivoula_hardwickei"            = "Kerivoula_hardwickii",           # standard double-i patronymic
    "Kyphosus_sectarix"               = "Kyphosus_sectatrix",             # sectarix wrong form

    # L
    "Lagothrix_lagothricha"           = "Lagothrix_lagotricha",           # Humboldt 1812 original; spurious h
    "Laterallus_jamicensis"           = "Laterallus_jamaicensis",         # Black Rail; missing a
    "Leiostomus_xanthrus"             = "Leiostomus_xanthurus",           # Spot; missing u
    "Lepomis_machrochirus"            = "Lepomis_macrochirus",            # Bluegill; metathesis of r
    "Lepus_pequensis"                 = "Lepus_peguensis",                # named after Pegu (Myanmar)
    "Limnodromus_scilopaceus"         = "Limnodromus_scolopaceus",        # Long-billed Dowitcher; vowel corruption
    "Liza_ramado"                     = "Liza_ramada",                    # spurious o
    "Lonchura_vana"                   = "Lonchura_nana",                  # vana not a recognized species
    "Loxia_pytiopsittacus"            = "Loxia_pytyopsittacus",           # Scopoli 1769 original; pytyopsittacus
    "Loxopholis_guianense"            = "Loxopholis_guianensis",          # wrong ending
    "Lutjanus_mahagoni"               = "Lutjanus_mahogoni",              # wrong vowel
    "Lycodon_rosozonatus"             = "Lycodon_rufozonatus",            # rufo- (reddish) is correct

    # M
    "Margarops_fuscus"                = "Margarops_fuscatus",             # sole species is M. fuscatus; fuscus differs
    "Mazama_gouazoupira"              = "Mazama_gouazoubira",             # p→b transposition
    "Merlangius_merlangius"           = "Merlangius_merlangus",           # merlangius redundantly repeats genus
    "Mesopropithecus_prithecoides"    = "Mesopropithecus_pithecoides",    # metathesis of r
    "Microcalanus_pusillis"           = "Microcalanus_pusillus",          # wrong declension ending

    # N
    "Nanonycteris_veldkmapii"         = "Nanonycteris_veldkampii",        # transposition of a and p
    "Neochoerus_oesopi"               = "Neochoerus_aesopi",              # honors Aesop; non-standard oe
    "Neophoca_cinervea"               = "Neophoca_cinerea",               # Australian Sea Lion; spurious v
    "Neosclerocalyptus_paskoenis"     = "Neosclerocalyptus_paskoensis",   # missing s in -ensis
    "Ningaui_timealyi"                = "Ningaui_timealeyi",              # missing e
    "Ningaui_yvonnae"                 = "Ningaui_yvonneae",               # female genitive requires -ae
    "Nyctalus_geoffroyi"              = "Nyctophilus_geoffroyi",          # AyalaBerdon_2025 ESM table; its two cited papers (Dixon & Rose 2003, Hosken & Withers 1999) concern Nyctophilus geoffroyi; no Nyctalus geoffroyi exists (#71)

    # O
    "Oithona_similus"                 = "Oithona_similis",                # Latin 3rd decl similis; similus not valid
    "Oplophorus_gracilorostris"       = "Oplophorus_gracilirostris",      # wrong linking vowel o→i

    # P
    "Palorchestes_azeal"              = "Palorchestes_azael",             # transposition a/e
    "Pandalus_momtagui"               = "Pandalus_montagui",              # honors Montagu; transposition n/m
    "Pelecanus_conspicullatus"        = "Pelecanus_conspicillatus",       # Australian Pelican; spurious ul
    "Pempheris_schomburki"            = "Pempheris_schomburgkii",         # missing k and i
    "Penelope_purpurescens"           = "Penelope_purpurascens",          # purpurascens correct Latin
    "Perognathus_alticolus"           = "Perognathus_alticola",           # alticola 1st-decl noun; -us invalid
    "Periphylla_peryphylla"           = "Periphylla_periphylla",          # y→i substitution
    "Phalacrocorax_auritas"           = "Phalacrocorax_auritus",          # auritas wrong ending
    "Phalacrocorax_melanoleucas"      = "Phalacrocorax_melanoleucos",     # Greek leukos; spurious -as
    "Phalacrocorax_pygmaeus"          = "Phalacrocorax_pygmeus",          # Pallas 1773 original spelling
    "Phelsuma_vnigra"                 = "Phelsuma_nigra",                 # leading v typo
    "Phyllomedusa_sauvagei"           = "Phyllomedusa_sauvagii",          # Boulenger 1882 original
    "Phyllomys_braziliensis"          = "Phyllomys_brasiliensis",         # Latin brasiliensis vs Portuguese
    "Phylloscopus_sibillatrix"        = "Phylloscopus_sibilatrix",        # Wood Warbler; spurious double l
    "Phyllotis_bonaeriensis"          = "Phyllotis_bonariensis",          # spurious e (bonariensis from Bonaria)
    "Phrynosoma_douglassi"            = "Phrynosoma_douglasii",           # spurious double s
    "Pipistrellus_anchietae"          = "Pipistrellus_anchietai",         # male patronym takes -i not -ae
    "Pipistrellus_pipitrellus"        = "Pipistrellus_pipistrellus",      # AyalaBerdon_2025 ESM table; missing s (the cited Speakman et al. 1989 is on P. pipistrellus) (#71)
    "Pipra_cornuta"                   = "Pipra_coronata",                 # Blue-crowned Manakin; cornuta not recognized
    "Piranga_olivicea"                = "Piranga_olivacea",               # Scarlet Tanager; spurious i
    "Pituophis_melanolecus"           = "Pituophis_melanoleucus",         # Pine Snake; missing u
    "Pleuragramma_antarctica"         = "Pleuragramma_antarcticum",       # Pleuragramma is neuter
    "Ploceus_dicrocephalus"           = "Ploceus_dichrocephalus",         # from dichros (two-colored); missing h
    "Podarcis_raffoneae"              = "Podarcis_raffonei",              # male patronym takes -i
    "Prionace_gluaca"                 = "Prionace_glauca",                # Blue Shark; transposition a/u
    "Procyon_locator"                 = "Procyon_lotor",                  # Raccoon; nonsense insertion
    "Proechimys_trinitatus"           = "Proechimys_trinitatis",          # Trinidad Spiny Rat; correct genitive
    "Prunella_modularls"              = "Prunella_modularis",             # Dunnock; i→l typo
    "Przewalskium_albirostris"        = "Przewalskium_albirostre",        # Przewalskium is neuter; -e required
    "Pseudomonas_natrigiens"          = "Pseudomonas_natriegens",         # transposition ie
    "Pseudoupeneus_macularus"         = "Pseudupeneus_maculatus",         # Maculated Goatfish; macularus not recognized
    "Pycnonotus_jocusus"              = "Pycnonotus_jocosus",             # Red-whiskered Bulbul; vowel transposition
    "Python_curtis"                   = "Python_curtus",                  # Blood Python; i→u

    # R
    "Rhinolophus_yunanensis"          = "Rhinolophus_yunnanensis",        # Yunnan; missing n
    "Rhinopitechus_roxella"           = "Rhinopithecus_roxellana",         # Golden Snub-nosed Monkey; genus and epithet corrected
    "Rousettus_egyptiacus"            = "Rousettus_aegyptiacus",          # from Aegyptus; missing ae
    "Rhizophor_amucronata"            = "Rhizophora_mucronata",          # spurious a
    "Rhytonomus_isobellina"           = "Brachypera_isabellina",          # Chown 2007 S2 'Rhytonomus isobellina' (Heatwole et al. 1986, Tunisia) = Phytonomus isabellinus Boheman 1834, now Brachypera (Antidonus) isabellina (Skuhrovec 2008); GBIF 9257612 (#28; only "isobellina" occurs in the raw sources; the value was once typed with a space, which filed the record as a genus)


    # S
    "Sagitta_elegana"                 = "Sagitta_elegans",                # ns dropped
    "Scarus_iserti"                   = "Scarus_iseri",                   # Striped Parrotfish Bloch 1789; spurious t
    "Scolopocryptos_ferrugineus"      = "Scolopocryptops_ferrugineus",    # Lemoine_2026, 8 rows: Scolopocryptops Newport, 1844 (family Scolopocryptopidae in the same row); missing p (#76)
    "Sceloporus_utiformis"            = "Sceloporus_uniformis",           # n dropped
    "Sebastes_paucipinis"             = "Sebastes_paucispinis",           # Bocaccio; missing s
    "Sebastes_paucispinus"            = "Sebastes_paucispinis",           # -us→-is termination error
    "Sebastes_ruberrinus"             = "Sebastes_ruberrimus",            # Yelloweye Rockfish; superlative -imus
    "Seiurus_novaeboracensis"         = "Seiurus_noveboracensis",         # Northern Waterthrush; spurious a
    "Sericornis_magnirostra"          = "Sericornis_magnirostris",        # 3rd-decl adjective requires -is
    "Sphenodon_punctatum"             = "Sphenodon_punctatus",            # Tuatara; accepted form is punctatus
    "Stegastes_variabillis"           = "Stegastes_variabilis",           # doubled-l typo
    "Strobilidium_iacustris"          = "Strobilidium_lacustris",         # Latin lacustris (of lakes); iacustris invalid
    "Spanioconnus_wetterhali"          = "Euconnus_wetterhali",           # Euconnus is the valid genus; Spanioconnus is a junior synonym

    # T
    "Tamiops_rodolphei"               = "Tamiops_rodolphii",              # standard double-i patronymic
    "Tenebrio_mollitor"               = "Tenebrio_molitor",               # Mealworm Beetle; single-l correct
    "Tetrahymena_pyraformis"          = "Tetrahymena_pyriformis",         # pear-shaped from pyrus; pyra- wrong
    "Thalassarche_melanophrys"        = "Thalassarche_melanophris",       # IOC/BirdLife accepted form
    "Thallasarche_melanophris"        = "Thalassarche_melanophris",       # Black-browed Albatross; transposed l/s in Wisnionski_2026 (#79)
    "Thomasomys_ischyrus"             = "Thomasomys_ischyurus",           # Greek ischys + oura; missing u
    "Thryesphilus_rufalbus"           = "Thryophilus_rufalbus",           # Rufous-and-white Wren; misspelt genus in Wisnionski_2026 (#79)
    "Thunnus_alaunga"                 = "Thunnus_alalunga",               # Albacore; dropped l
    "Thunnus_macoyi"                  = "Thunnus_maccoyii",               # Southern Bluefin; missing c and i
    "Torgos_tracheliotus"             = "Torgos_tracheliotos",            # Lappet-faced Vulture; IOC form
    "Tortanus_discaudalus"            = "Tortanus_discaudatus",           # spurious -al- insertion
    "Trapelus_savignyi"               = "Trapelus_savignii",              # savignyi is an invalid subsequent spelling; GBIF/WoRMS accepted form is T. savignii (Audouin 1809)
    "Trogonophis_weigmanni"           = "Trogonophis_wiegmanni",          # honors Wiegmann; missing i
    "Turdoides_reinwardii"            = "Turdoides_reinwardtii",          # honors Reinwardt; t from surname retained
    "Thalassionema_proschkinae"       = "Minidiscus_proschkinae",      # 
    "Trichomonas_foetus"              = "Tritrichomonas_foetus",           # Tritrichomonas is the valid genus; Trichomonas is a junior synonym
  

    # U
    "Uca_pugnas"                      = "Uca_pugnax",                     # pugnax is adjective; pugnas is verb form
    "Uraeginthus_bengalis"            = "Uraeginthus_bengalus",           # Red-cheeked Cordonbleu; accepted form
    "Urocissa_erythrorhyncha"         = "Urocissa_erythroryncha",         # Gould 1857 original; h insertion unofficial
    "Urocyon_cineroargenteus"         = "Urocyon_cinereoargenteus",       # Gray Fox; cinereo- needs connecting -o-
    "Uromacerina_ricardinii"          = "Cercophis_auratus",              # Uromacerina ricardinii is a junior synonym; accepted name is Cercophis auratus (Colubridae)
    "Uromys_neobritanicus"            = "Uromys_neobritannicus",          # New Britain requires double-n
    "Uronema_marina"                  = "Uronema_marinum",                # Uronema is neuter (-nema); -um required

    # V
    "Vulpes_ruepellii"                = "Vulpes_rueppellii",              # Rüppell's Fox; standard double-p

    # Z
    "Zapus_hudsonicus"                = "Zapus_hudsonius",                # Zimmermann 1780 original
    "Zyzomys_palatilis"               = "Zyzomys_palatalis",              # Carpentarian Rock-rat; -alis not -ilis

    # Additional corrections from chunk 4 review (D–H range)
    "Dictyostelium_discodeum"         = "Dictyostelium_discoideum",       # social amoeba; missing i
    "Dictyostelium_discoideu"         = "Dictyostelium_discoideum",       # truncated; missing final m
    "Diodon_hysterix"                 = "Diodon_hystrix",                 # porcupinefish; spurious e
    "Diomedea_immutablis"             = "Diomedea_immutabilis",           # Laysan Albatross; missing i
    "Emoia_nativittatis"              = "Emoia_nativitatis",              # spurious double t
    "Engraulis_encrasicholus"         = "Engraulis_encrasicolus",         # European Anchovy; spurious h
    "Equus_caballas"                  = "Equus_caballus",                 # domestic horse; wrong ending
    "Euphausia_tricantha"             = "Euphausia_triacantha",           # three-spined krill; missing a in tria-
    "Eutropis_beddomii"               = "Eutropis_beddomei",              # Beddome ends in vowel; ICZN Art 31 -i
    "Galeopterus_variegates"          = "Galeopterus_variegatus",         # Sunda Colugo; English verb vs Latin adj
    "Gallus_lafayettii"               = "Gallus_lafayetii",               # Sri Lanka Junglefowl; Lesson 1831 form
    "Gastrophryne_carolinesis"        = "Gastrophryne_carolinensis",      # Eastern Narrowmouth Toad; missing n
    "Giraffa_cameolopardalis"         = "Giraffa_camelopardalis",         # Giraffe; spurious o
    "Haliastur_sphenarus"             = "Haliastur_sphenurus",            # Whistling Kite; a→u
    "Hemicentetes_nigricepts"         = "Hemicentetes_nigriceps",         # black-headed tenrec; spurious t
    "Herpailurus_yaguarondi"          = "Herpailurus_yagouaroundi",       # Jaguarundi; d'Orbigny 1803 original
    "Heterocapsa_triqueta"            = "Heterocapsa_triquetra",          # dinoflagellate; triquetra missing r
    "Holocentrus_ascensionis"         = "Holocentrus_adscensionis",       # squirrelfish; original form with d

# Audit 8/21/2026

    # A
    "Abatus_shackeltoni"              = "Abatus_shackletoni",             # el/le transposition; Shackleton sea urchin GBIF FUZZY 95
    "Abeomylomys_sevia"               = "Abeomelomys_sevia",              # myl→mel vowel transposition; New Guinea rodent GBIF FUZZY 85
    "Abudefduf_tauru"                 = "Abudefduf_taurus",              # truncated; missing final s; Night Sergeant damselfish GBIF FUZZY 94
    "Acabthodactylus_boskianus"       = "Acanthodactylus_boskianus",      # bt→nth transposition; fringe-toed lizard GBIF FUZZY 85
    "Acanthamoeba_castellani"         = "Acanthamoeba_castellanii",       # single-i patronymic; Castellani ends consonant GBIF FUZZY 96
    "Acerodon_mackloti"               = "Acerodon_macklotii",             # single-i patronymic; Macklot ends consonant GBIF FUZZY 96
    "Achnanthes_lemmermanni"          = "Achnanthes_lemmermannii",        # single-i patronymic; Lemmermann ends consonant GBIF FUZZY 96
    "Afroablepharus_wahlbergi"        = "Afroablepharus_wahlbergii",      # single-i patronymic; Wahlberg ends consonant GBIF FUZZY 96
    "Aglaiocercus_kingi"              = "Aglaiocercus_kingii",            # single-i patronymic; King ends consonant GBIF FUZZY 95
    "Aluterus_schoepfi"               = "Aluterus_schoepfii",             # single-i patronymic; Schoepf ends consonant GBIF FUZZY 96
    "Amazilia_saucerrottei"           = "Amazilia_saucerottei",           # spurious r inserted; Steely-vented Hummingbird GBIF FUZZY 96
    "Amphisbaena_darwini"             = "Amphisbaena_darwinii",           # single-i patronymic; Darwin ends consonant GBIF FUZZY 96
    "Anolis_maynardi"                 = "Anolis_maynardii",               # single-i patronymic; Maynard ends consonant GBIF FUZZY 96
    "Anolis_wattsi"                   = "Anolis_wattsii",                 # single-i patronymic; Watts ends consonant GBIF FUZZY 96
    "Anomalopus_verreauxi"            = "Anomalopus_verreauxii",          # single-i patronymic; Verreaux ends consonant GBIF FUZZY 96
    "Anoplolepis_steinergroeveri"     = "Anoplolepis_steingroeveri",      # er inserted after stein; Steingroever patronymic GBIF FUZZY 93
    "Anotopterus_pharaoh"             = "Anotopterus_pharao",             # English spelling vs Latin pharao; Daggertooth fish GBIF FUZZY 93
    "Aphis_gossypi"                   = "Aphis_gossypii",                 # single-i; genitive of gossypium requires double-i GBIF FUZZY 95
    "Apteryx_haasti"                  = "Apteryx_haastii",                # single-i patronymic; Haast ends consonant GBIF FUZZY 96
    "Archaeoindris_fontoynonti"       = "Archaeoindris_fontoynontii",     # single-i patronymic; Fontoynont ends consonant GBIF FUZZY 96
    "Arctocephalus_philippi"          = "Arctocephalus_philippii",        # single-i; GBIF accepted form uses double-i GBIF FUZZY 95
    "Asplanchna_sieboldi"             = "Asplanchna_sieboldii",           # single-i patronymic; Siebold ends consonant GBIF FUZZY 95
    "Asymblepharus_tragbulense"       = "Asymblepharus_tragbulensis",     # -ense→-ensis; locality adjective requires both n's GBIF FUZZY 96
    "Azomonas_agi"                    = "Azomonas_agilis",                # truncated; agi is first 3 letters of agilis GBIF HIGHERRANK

    # B
    "Bathycalanus_richard"            = "Bathycalanus_richardi",          # truncated; missing genitive -i GBIF FUZZY 96
    "Brosmophycis_marginate"          = "Brosmophycis_marginata",         # English adjective; Latin -a required GBIF FUZZY 96

    # C
    "Cacactua_tenuirostris"           = "Cacatua_tenuirostris",           # doubled c; correct genus Cacatua GBIF FUZZY 85
    "Callophora_rylandi"              = "Callopora_rylandi",              # ph→p; bryozoan genus Callopora not Callophora GBIF FUZZY 85
    "Chrysallida_pellucida"           = "Spiralinella_spiralis",           # Chrysallida pellucida is a junior synonym; accepted name is Spiralinella spiralis (Pyramidellidae)
    "Crithida_fasciculata"            = "Crithidia_fasciculata",          # missing i; protozoan Crithidia not polychaete Crithida GBIF HIGHERRANK; also Makarieva_2008 "Crithida (Strigomonas) fasciculata" once FixFormatting removes the subgenus (#36, #38)
    "Crithidia_oncopelti"             = "Strigomonas_oncopelti",          # Makarieva_2008 "Crithidia (Strigomonas) oncopelti" without its subgenus (#38) and DeLong_etal_2010 'Crithidia oncopelti'; current genus Strigomonas (#36)
    "Crystallodytes_cookie"           = "Crystallodytes_cookei",          # English word vs Latin patronymic; GBIF HIGHERRANK

    # D
    "Dephinapterus_leucas"            = "Delphinapterus_leucas",          # missing l; Beluga Whale GBIF NONE (correct EXACT 99)
    "Diomedia_exulans"                = "Diomedea_exulans",               # i→e substitution; Wandering Albatross GBIF FUZZY 85
    "Diomedea_melanophrys"            = "Diomedea_melanophris",           # phrys→phris; Black-browed Albatross GBIF FUZZY 92

    # E
    "Edaphus_blYhweissi"              = "Edaphus_bluhweissi",             # GATEWAy writes 'Edaphus blŸhweissi': Mac Roman ü (0x9F) decoded as CP1252 Ÿ upstream; Edaphus blühweissi Scheerpeltz, 1936, GBIF EXACT 98, synonym of Edaphus lederi Eppelsheim, 1878 (Staphylinidae), to which enrichment resolves it (#37)
    "Enophrys_taurine"                = "Enophrys_taurina",               # English word; Latin -a required GBIF FUZZY 96

    # G
    "Gabrius_fermoralis"              = "Gabrius_femoralis",              # vowel transposition; femoralis from femur GBIF EXACT 99
    "Gadhus_morhua"                   = "Gadus_morhua",                   # h inserted; Atlantic cod GBIF FUZZY 85
    "Gadus_minitus"                   = "Gadus_minutus",                  # u/i transposition; poor cod GBIF HIGHERRANK
    "Gammarus_insensiblis"            = "Gammarus_insensibilis",          # missing i in -ibilis; amphipod GBIF FUZZY 95
    "Garthia_gaudichaudi"             = "Garthia_gaudichaudii",           # single-i; Gaudichaud ends consonant GBIF FUZZY 96
    "Gerbilliscus_nigricauda"         = "Gerbilliscus_nigricaudus",       # also: Girbilliscus_nigricauda; ir/er + gender fix GBIF FUZZY 85
    "Girbilliscus_nigricauda"         = "Gerbilliscus_nigricaudus",       # ir→er genus transposition + wrong gender GBIF FUZZY 85
    "Glaseria_mira"                   = "Glaeseria_mira",                  # ae diphthong dropped; correct genus is Glaeseria (Rhabditophora: Macrostomorpha)
    "Glossolepis_incisa"              = "Glossolepis_incisus",            # -a→-us gender agreement; masculine genus GBIF FUZZY 96
    "Gonotodes_antillensis"           = "Gonatodes_antillensis",          # o→a substitution; Neotropical gecko GBIF FUZZY 85
    "Gonyosoma_frenatus"              = "Gonyosoma_frenatum",             # -us→-um; -soma is neuter Greek GBIF FUZZY 96
    "Gromphadorihna_portentosa"       = "Gromphadorhina_portentosa",      # extra i; Madagascar hissing cockroach GBIF HIGHERRANK

    # H
    "Haemulon_plumieri"               = "Haemulon_plumierii",             # single-i; Plumier ends consonant GBIF FUZZY 96
    "Haplodrassus_silvstris"          = "Haplodrassus_silvestris",        # missing e; ground spider GBIF FUZZY 95
    "Harmonia_confirmis"              = "Harmonia_conformis",             # o/i vowel swap; large spotted ladybird GBIF FUZZY 95
    "Harmotoe_hartmanae"              = "Harmothoe_hartmanae",            # missing h; polychaete genus Harmothoe GBIF NONE
    "Hipoglossoides_platessoides"     = "Hippoglossoides_platessoides",   # missing p; American plaice GBIF FUZZY 80

    # I
    "Iomys_horsfieldi"                = "Iomys_horsfieldii",              # single-i patronymic; Horsfield ends consonant GBIF FUZZY 96

    # K
    "Klebsiella_pneu"                 = "Klebsiella_pneumoniae",          # truncated stub; pneu = first 4 letters GBIF NONE

    # L
    "Lagotrix_lugens"                 = "Lagothrix_lugens",               # missing h; woolly monkey GBIF FUZZY 84
    "Lagppus_lagopus"                 = "Lagopus_lagopus",                # doubled p; Willow Ptarmigan GBIF FUZZY 85
    "Larua_ridibundus"                = "Larus_ridibundus",               # ua→us transposition; Common Black-headed Gull GBIF FUZZY 84
    "Lepidonotos_squamatus"           = "Lepidonotus_squamatus",          # missing u; polychaete genus Lepidonotus GBIF FUZZY 85
    "Leptonichotes_wedelli"           = "Leptonychotes_weddellii",        # genus y-drop + epithet double errors; Weddell Seal GBIF FUZZY 85
    "Leptonychotes_weddelli"          = "Leptonychotes_weddellii",        # single-i; Weddell ends consonant GBIF FUZZY 96
    "Loligo_forbesi"                  = "Loligo_forbesii",                # single-i patronymic; Forbes ends consonant GBIF FUZZY 96
    "Loxoides_baileui"                = "Loxioides_bailleui",             # genus missing i + epithet missing l; Palila GBIF FUZZY 85

    # M
    "Magliophis_exiguum"              = "Magliophis_exiguus",             # -um→-us gender; masculine -ophis genus GBIF FUZZY 96
    "Meitihreptus_lunatus"            = "Melithreptus_lunatus",           # ei/eli transposition; White-naped Honeyeater GBIF NONE
    "Menmbraiporella_nitida"          = "Membraniporella_nitida",         # nm/mn transposition + ai/ani; bryozoan GBIF NONE
    "Methylobacte_extorquens"         = "Methylobacterium_extorquens",    # truncated genus; Methylobacterium bacterium GBIF NONE
    "Micropterus_dolomieui"           = "Micropterus_dolomieu",           # extra -i; original Lacepède 1802 used dolomieu GBIF EXACT SYNONYM 98
    "Micromesistius_potassou"         = "Micromesistius_poutassou",        # misspelt epithet (Barnes_2008 prey)
    "Modiolis_modiolis"               = "Modiolus_modiolus",              # i→u substitution in both parts; horse mussel GBIF FUZZY 85

    # N
    "Nanonycteris_veldkampi"          = "Nanonycteris_veldkampii",        # single-i; Veldkamp ends consonant GBIF FUZZY 96
    "Neisseria_gon"                   = "Neisseria_gonorrhoeae",          # truncated; gon = first 3 letters GBIF HIGHERRANK
    "Neisseria_mu"                    = "Neisseria_mucosa",               # truncated; mu = first 2 letters GBIF HIGHERRANK
    "Nocardia_coral"                  = "Nocardia_corallina",             # truncated; coral = first 5 letters GBIF HIGHERRANK
    "Nocardia_far"                    = "Nocardia_farcinica",             # truncated; far = first 3 letters GBIF HIGHERRANK

    # P
    "Phaeodactyllum_tricornutum"      = "Phaeodactylum_tricornutum",      # double-l; Greek daktylon has single l GBIF FUZZY 85
    "Phanourios_minutes"              = "Phanourios_minutus",             # English noun; Latin minutus required GBIF HIGHERRANK
    "Phelpsia_inornatus"              = "Phelpsia_inornata",              # -us→-a gender; feminine -ia genus GBIF FUZZY 96
    "Phocartos_hookeri"               = "Phocarctos_hookeri",             # missing c; New Zealand sea lion GBIF FUZZY 85
    "Pholis_ornate"                   = "Pholis_ornata",                  # English adj; Latin -a required GBIF FUZZY 96
    "Phorocantha_recurva"             = "Phoracantha_recurva",            # o→a; eucalyptus longhorn beetle GBIF FUZZY 80
    "Phorocantha_semipunctata"        = "Phoracantha_semipunctata",       # o→a; eucalyptus longhorn borer GBIF FUZZY 80
    "Phoxinys_neogaeus"               = "Phoxinus_neogaeus",              # y→u; Finescale Dace GBIF FUZZY 84
    "Phyloomys_unicolor"              = "Phyllomys_unicolor",             # double-o; South American tree rat GBIF FUZZY 85
    "Pitupophis_catenifer"            = "Pituophis_catenifer",            # extra p; Pacific Gopher Snake GBIF FUZZY 85
    "Pooectes_gramineus"              = "Pooecetes_gramineus",            # missing first e; Vesper Sparrow GBIF FUZZY 85
    "Posidonica_oceanica"             = "Posidonia_oceanica",             # extra c; Mediterranean seagrass GBIF FUZZY 80
    "Potamopurgus_antipodarum"        = "Potamopyrgus_antipodarum",       # purgus→pyrgus; New Zealand mudsnail GBIF FUZZY 85
    "Psamechinus_miliaris"            = "Psammechinus_miliaris",          # single m; Greek psammos requires double-m GBIF FUZZY 83
    "Pseudopleuronecte_americanus"    = "Pseudopleuronectes_americanus",  # missing terminal s; Winter Flounder GBIF FUZZY 85
    "Pterois_lunulate"                = "Pterois_lunulata",               # English adj; Latin -a required GBIF FUZZY 96
    "Ptychorhamphus_aleuticus"        = "Ptychoramphus_aleuticus",        # spurious h; Cassin's Auklet GBIF FUZZY 85

    # R
    "Rhinopithecus_roxella"            = "Rhinopithecus_roxellana",         # English noun; Latin -ana required GBIF FUZZY 96

    # S
    "Salicornia_europea"              = "Salicornia_europaea",            # ae diphthong dropped; glasswort GBIF FUZZY 93
    "Sallinivibrio_costicola"         = "Salinivibrio_costicola",         # double-l; halotolerant bacterium GBIF FUZZY 85
    "Sardinops_caerrula"              = "Sardinops_caerulea",             # double-r + wrong ending; caeruleus GBIF FUZZY 94
    "Scapaloberis_mucronata"          = "Scapholeberis_mucronata",        # ph digraph dropped; cladoceran GBIF NONE
    "Sceloporus_jarrovi"              = "Sceloporus_jarrovii",            # single-i patronymic; Yarrow ends consonant GBIF FUZZY 96
    "Seiurus_aurocapillus"            = "Seiurus_aurocapilla",            # -us→-a gender; Ovenbird original Linnaeus 1766 GBIF FUZZY 96
    "Serolella_bouveri"               = "Serolella_bouvieri",             # missing i; Bouvier genitive = bouvieri GBIF FUZZY 95
    "Sialia_mexicanus"                = "Sialia_mexicana",                # -us→-a gender; feminine genus Sialia GBIF FUZZY 96
    "Sibynomorphis_mikanii"           = "Sibynomorphus_mikanii",          # -phis→-phus; slug-eating snake genus GBIF FUZZY 84
    "Siphonaria_lesoni"               = "Siphonaria_lessonii",            # missing s and i; Lesson patronymic GBIF FUZZY 96
    "Sisiyphys_fasciculatus"          = "Sisyphus_fasciculatus",          # y/ph transposition; dung-beetle genus GBIF NONE
    "Spirontocarus_lilleborgi"        = "Spirontocaris_lilljeborgii",     # genus -carus→-caris + epithet double errors GBIF FUZZY 80
    "Spiziapteryx_circumcinctus"      = "Spiziapteryx_circumcincta",      # -us→-a gender; feminine genus Spiziapteryx GBIF FUZZY 96
    "Synodontis_nigromaculata"        = "Synodontis_nigromaculatus",      # -a→-us gender; masculine genus Synodontis GBIF FUZZY 96

    # T
    "Talorchestia_megalophtalma"      = "Talorchestia_megalophthalma",    # missing h in Greek ophthalmos GBIF FUZZY 96
    "Tapes_philippimarum"             = "Tapes_philippinarum",            # n/m transposition; Manila clam GBIF FUZZY 94
    "Tauraco_schuetti"                = "Tauraco_schuettii",              # single-i patronymic; Schütt ends consonant GBIF FUZZY 96
    "Telespyza_cantans"               = "Telespiza_cantans",              # Telespyza is junior synonym of Telespiza; Laysan Finch GBIF EXACT SYNONYM 98
    "Tetryhymena_pyriformis"          = "Tetrahymena_pyriformis",         # y/a transposition in genus; ciliate GBIF FUZZY 83
    "Thamnodyastes_strigatus"         = "Thamnodynastes_strigatus",       # missing n; Neotropical snake GBIF FUZZY 85
    "Tilesina_gibbose"                = "Tilesina_gibbosa",               # English adj; Latin -a required GBIF FUZZY 96
    "Tudus_viscivorus"                = "Turdus_viscivorus",              # missing r; Mistle Thrush GBIF NONE

    "Stephus_longipes"                = "Stephos_longipes",                # misspelt genus; Stephos Scott, 1892 (Barnes_2008 prey)

    # U
    "Urophysis_chuss"                 = "Urophycis_chuss",                 # misspelt genus; Urophycis Gill, 1863 (Barnes_2008 predator)
    "Urosalpinx_cinere"               = "Urosalpinx_cinerea",             # truncated; missing final -a GBIF FUZZY 95

    # V
    "Varnus_rosenbergi"               = "Varanus_rosenbergi",             # missing a; Heath Monitor GBIF FUZZY 85
    "Viblia_antarctica"               = "Vibilia_antarctica",             # missing i; hyperiid amphipod GBIF FUZZY 85
    "Vibrio_algino"                   = "Vibrio_alginolyticus",           # truncated stub; algino = first 5 letters GBIF FUZZY 93
    "Vibrio_metsch"                   = "Vibrio_metschnikovii",           # truncated stub; metsch = first 5 letters GBIF NONE
    "Vibrio_para"                     = "Vibrio_parahaemolyticus",        # truncated stub; para = first 4 letters GBIF NONE

    # W
    "Warenja_wakefieldi"              = "Warendja_wakefieldi",            # missing d; fossil wombat genus GBIF FUZZY 85

    # Y
    "Yynx_torquilla"                  = "Jynx_torquilla",                 # Y→J substitution; Eurasian Wryneck GBIF NONE

    # Z
    "Zonotricha_querula"              = "Zonotrichia_querula",            # missing i; Harris's Sparrow GBIF FUZZY 85

# Audit outlier review — taxonomy corrections (invalid names / junior synonyms)

    "Carangoides_latus"               = "Caranx_latus",                  # junior synonym; FishBase valid name is Caranx latus (Carangidae)
    "Casurarius_bennetti"             = "Casuarius_bennetti",            # transposed a/u in genus; duplicate entry for dwarf cassowary (Makarieva_2008)
    "Limecoma_balthica"               = "Limecola_balthica",             # Limecoma invalid; WoRMS correct genus is Limecola (formerly Macoma balthica; Tellinidae)
    "Nectarinia_tsavoensis"           = "Cinnyris_tsavoensis",           # Nectarinia is a non-monophyletic grade; IOC accepts Cinnyris tsavoensis (Tsavo sunbird)
    "Notothenia_marmorata"            = "Notothenia_rossii",             # junior synonym; FishBase valid name is Notothenia rossii (marbled notothenia)
    "Octopus_tuberculata"             = "Ocythoe_tuberculata",           # junior synonym; WoRMS accepts Ocythoe tuberculata Rafinesque 1814 as valid
    "Onacea_borealis"                 = "Triconia_borealis",             # Onacea is a misspelling of Oncaea; Oncaea borealis is now Triconia borealis (WoRMS)
    "Pleuromonas_jaculans"            = "Bodo_saltans",                  # Pleuromonas jaculans is a synonym of Bodo saltans (Kinetoplastea; ITIS)
    "Golfingia_nordenskojoeldi"       = "Golfingia_margaritacea",     #
    "Proteus_mor"                     = "Morganella_morganii",           # garbled Proteus morganii; accepted name is Morganella morganii (Enterobacteriaceae)

# Audit SUSPICIOUS tier 2026-08 — synonym / accepted-name corrections

    # BOTH_ERRONEOUS cases (rename only; mass rule retired with #24, a wrong value is handled through the BM_data Sheet override)
    "Momoculodes_scabriculosus"       = "Monoculodes_scabriculosus",    # Momoculodes invalid genus; correct is Monoculodes (Amphipoda: Oedicerotidae)
    "Psenes_whiteleggii"              = "Cubiceps_whiteleggii",          # Psenes whiteleggii is junior synonym of Cubiceps whiteleggii (Carangiformes: Nomeidae)
    "Squalinus_cephalus"              = "Squalius_cephalus",             # Squalinus not valid; correct genus is Squalius (Leuciscidae; European chub)

    # Stonefly epithet correction (trailing i spurious; mass rule retired with #24, a wrong value is handled through the BM_data Sheet override)
    "Stenoperla_prasinia"             = "Stenoperla_prasina",            # prasinia has spurious trailing i; correct is S. prasina (Plecoptera: Eustheniidae)

    # Colubrid junior synonym (mass rule retired with #24, a wrong value is handled through the BM_data Sheet override)
    "Coluber_fuliginosus"             = "Atractus_fuliginosus",          # Coluber fuliginosus is junior synonym of Atractus fuliginosus (Colubridae: Dipsadinae)

    # Amphipod accepted-name updates
    "Corophium_acutum"                = "Apocorophium_acutum",           # WoRMS: unaccepted; accepted is Apocorophium acutum (Corophiidae)
    "Pontogeneia_antarctica"          = "Gondogeneia_antarctica",         # WoRMS: old synonymous genus; accepted is Gondogeneia antarctica (Chevreux 1906)
    "Talorchestia_megalophthalma"     = "Americorchestia_megalophthalma", # WoRMS: old synonymous genus; accepted is Americorchestia megalophthalma (Bate 1862)
    "Paracallisoma_coecus"            = "Pseudocallisoma_coecum",         # WoRMS: unaccepted (new combination); valid is Pseudocallisoma coecum (Holmes 1908)

    # Fish junior synonyms / accepted-name updates
    "Dasyatis_americana"              = "Hypanus_americanus",            # Dasyatis americana junior synonym; FishBase/WoRMS valid: Hypanus americanus (southern stingray)
    "Dasyatis_centroura"              = "Bathytoshia_centroura",          # Dasyatis centroura junior synonym; valid: Bathytoshia centroura (roughtail stingray)
    "Dasyatis_lata"                   = "Bathytoshia_lata",              # Dasyatis lata junior synonym; valid: Bathytoshia lata (brown stingray)
    "Mugil_chelo"                     = "Chelon_labrosus",               # Mugil chelo junior synonym; valid: Chelon labrosus (thicklip grey mullet; Mugilidae)
    "Myxus_capensis"                  = "Pseudomyxus_capensis",          # Myxus capensis synonym; valid: Pseudomyxus capensis (Cape mullet; Mugilidae)
    "Osteochilus_melanopleura"        = "Osteochilus_melanopleurus",      # minor epithet discrepancy; FishBase canonical is O. melanopleurus

    # Pagurid incorrect subsequent spelling
    "Pagurus_prideauxi"               = "Pagurus_prideaux",              # WoRMS: misspelling; accepted is Pagurus prideaux Leach 1815

    # Lepidoptera genus misspellings (class-field errors noted in report; names corrected here)
    "Orgygia_detrita"                 = "Orgyia_detrita",                # Orgygia not valid; correct genus is Orgyia (Erebidae); Orgyia detrita (Guenée 1852)
    "Orygia_pseudotsugata"            = "Orgyia_pseudotsugata",           # Orygia not valid; correct genus is Orgyia (Erebidae); Douglas-fir tussock moth

    # Whale genus misspelling
    "Eschrichtus_robustus"            = "Eschrichtius_robustus",           # Eschrichtus misspelled; valid genus is Eschrichtius (Gray whale; Eschrichtiidae)

    # Odonate reclassification
    "Tetragoneuria_cynosura"          = "Epitheca_cynosura",               # Tetragoneuria now subsumed in Epitheca; accepted name is Epitheca cynosura (common baskettail)

    # Gastropod accepted-name update
    "Mitrella_lunata"                 = "Astyris_lunata",                  # WoRMS: Mitrella lunata is a synonym; accepted is Astyris lunata (Columbellidae)

    # Euphausiid alternate spelling (merge to canonical form; mass rule retired with #24, a wrong value is handled through the BM_data Sheet override)
    "Euphausia_krohni"                = "Euphausia_krohnii",               # alternate spelling of Euphausia krohnii; merge to canonical double-i form

    # Agamid reclassification
    "Celestus_anelpistus"             = "Caribicus_anelpistus",            # Celestus is paraphyletic; southern Caribbean species moved to Caribicus (Diploglossidae; Squamata)

    # Copepod junior synonym
    "Eutemora_hirundoides"            = "Eurytemora_affinis",              # Eutemora hirundoides is a junior synonym of Eurytemora affinis (Temoridae; Hexanauplia)

# Genus mismatch audit 2026-08-30 — accepted-name corrections

    # A
    "Anachalcos_convexus"             = "Chalconotus_convexus",            # Anachalcos is a synonym; accepted is Chalconotus convexus Boheman, 1857 (Tenebrionidae; GBIF)
    "Astasia_longa"                   = "Euglena_longa",                   # Astasia Ehrenberg, 1830 is a synonym of Euglena Ehrenberg, 1830; accepted is Euglena longa (GBIF/AlgaeBase)

    # C
    "Chlamydotherium_humboldtii"      = "Pampatherium_humboldtii",         # Chlamydotherium is a junior synonym of Pampatherium Ameghino, 1875; extinct Pampatheriidae (GBIF)

    # D
    "Dendroica_aestiva"               = "Setophaga_aestiva",               # Dendroica merged into Setophaga following AOU/AOS; American Yellow Warbler (ITIS/GBIF)
    "Diaptomus_oregonensis"           = "Skistodiaptomus_oregonensis",     # Diaptomus is a junior synonym of Skistodiaptomus; Dussart & Defaye, 2002 (WoRMS/GBIF ITIS 85846)

    # F
    "Ferdauia_ferdau"                 = "Carangoides_ferdau",              # Ferdauia is a synonym of Carangoides; Forsskål, 1775 (GBIF/WoRMS AphiaID 218395)

    # H
    "Havilanditermes_atripennis"      = "Nasutitermes_atripennis",         # Havilanditermes Light, 1930 is a junior synonym of Nasutitermes Dudley, 1890 (GBIF)
    "Hipparion_libycum"               = "Eurygnathohippus_libycum",        # Hipparion libycum is an alternate combination; accepted is Eurygnathohippus libycum Pomel, 1897 (Fossilworks/GBIF)
    "Hoplophorus_euphractus"          = "Glyptodon_euphractus",            # Hoplophorus treated as synonym of Glyptodon following Ameghino, 1889 (GBIF/Paleobiology Database)

    # O
    "Ophichthys_cuchia"               = "Monopterus_cuchia",               # Ophichthys is a synonym; accepted is Monopterus cuchia Hamilton, 1822 (GBIF/FishBase/WoRMS)

    # Q
    "Quadricalcarifera_punctatella"   = "Syntypistis_punctatella",         # Quadricalcarifera is a synonym of Syntypistis; Notodontidae; beech caterpillar (GBIF)

    # R
    "Rhynchops_niger"                 = "Rynchops_niger",                  # Rhynchops is an alternate/older spelling; accepted genus is Rynchops Linnaeus, 1758 (ITIS/GBIF/IOC)

    # P (Verberk_2020 writes the grebes as 'Podilymbus (Podiceps) epithet'; once FixFormatting removes the
    # bracketed name (#38) only the pied-billed grebe is a Podilymbus; GBIF matches the other two to the genus alone)
    "Podilymbus_nigricollis"          = "Podiceps_nigricollis",            # black-necked grebe; Podiceps nigricollis Brehm, 1831 accepted (GBIF EXACT 99)
    "Podilymbus_ruficollis"           = "Tachybaptus_ruficollis",          # little grebe; Podiceps ruficollis is the old combination, Tachybaptus ruficollis (Pallas, 1764) accepted (GBIF EXACT 99)

    # S
    "Scyris_indica"                   = "Alectis_indica",                  # Scyris is junior synonym; Alectis Rafinesque, 1815 has priority; Indian threadfish (WoRMS/FishBase)

    # T
    "Tomocerus_flavescens"            = "Pogonognathellus_flavescens",     # Tomocerus is a synonym; accepted is Pogonognathellus flavescens Tullberg, 1871 (GBIF species 4538730)
    "Turrum_fulvoguttatum"            = "Carangoides_fulvoguttatus",       # FishBase/GBIF accept Carangoides fulvoguttatus; WoRMS (Kimura et al. 2022) accepts Turrum — conflict; FishBase/GBIF used here

# One-token names that are misspelt genera (#47, 2026-10-04). A bare genus is
# filed by RunMe section 3 as a genus-level record, so each value is the genus
# alone and the record enters TaxonBodyMass_GenusLevel.csv under the corrected
# name (no species row is created). GBIF: species/match, rank GENUS.

    "Heremodromia"                    = "Hemerodromia",                   # Brose_etal_2018, 105 rows: the five UK stream webs of Gray et al. 2015 / Thompson et al. 2017 (Bure, Loddon, Lyde, Test, Wensum; 3.6e-4 to 6.6e-4 g, listed next to the other aquatic empidid Clinocera); 'er'/'me' transposed; Hemerodromia Meigen, 1822 (Diptera: Empididae), GBIF 1444910 EXACT; the raw spelling matches nothing
    "Telonemus"                       = "Telenomus",                      # Brose_etal_2018, 47 rows: Florida mangrove-island webs E1 and E3 (Simberloff & Wilson 1969 via Piechnik et al. 2008; 9.2e-4 g, the value the web gives the other scelionid, Probaryconus); 'o'/'e' swapped; Telenomus Haliday, 1833 (Hymenoptera: Scelionidae, egg parasitoids), GBIF 1401305 EXACT; the raw spelling matches nothing
    "Tetraluerodes"                   = "Tetraleurodes",                  # Brose_etal_2018, 44 rows: Florida mangrove-island webs E1-E3, taxonomy.level 'genus', common name 'whiteflies' (with Aleurothrixus and Paraleyrodes, all 2.5e-3 g); 'ue'/'eu' transposed; Tetraleurodes Cockerell, 1902 (Hemiptera: Aleyrodidae), GBIF 4404483 EXACT (FUZZY 85 on the raw spelling)
    "Renic"                           = "Renicola",                       # Brose_etal_2018, 24 adult rows of the Carpinteria web (Lafferty et al. 2006), i.e. the Hechinger_etal_2011 node 'renic': family Renicolidae, genus left blank, size 'set equal to congener (renc)' = Renicola cerithidicola, 3.1e-5 g like every Carpinteria Renicola adult (its 'small cyathocotylid' is sized from a 'confamilial', so the authors' wording places renic in Renicola); Renicola Cohn, 1904 (Trematoda: Renicolidae), GBIF 5431622 EXACT; the least certain of the six
    "Amoebobaeter"                    = "Amoebobacter",                   # Makarieva_2008 S1a, 1 row: the valid_name typed for 'Amoebobaeter pendens (5813)' (Overmann & Pfennig 1992, purple sulfur bacteria; 5e-12 g), 'c' read as 'e'; the two sister rows of the table carry 'Amoebobacter'; Amoebobacter Winogradsky, 1888 (Chromatiales: Chromatiaceae), GBIF 9666951 (status DOUBTFUL: its species now sit in Thiocapsa and Lamprocystis); the raw spelling matches nothing
    "Sallinivibrio"                   = "Salinivibrio",                   # Makarieva_2008 S1a, 1 row: the valid_name typed for 'Vibrio costicola (NRCC 37001)' (Kushner et al. 1983; 4e-13 g), doubled 'l'; Salinivibrio Mellado et al., 1996 (Vibrionaceae), GBIF 3222411 EXACT (FUZZY 85 on the raw spelling); the DeLong_etal_2010 and Hoehler_etal_2023 copies of the record are handled by the Sallinivibrio_costicola rule above

# Unresolved names of reports/warnings_taxonomy.md (#85, 2026-10-05). Every
# name below was unresolved by all enrichment stages; each is a misspelling,
# an old combination or a junior synonym of a name the enrichment resolves.
# Targets were checked against the GBIF backbone (species/match: EXACT, rank
# SPECIES; '[accepted X]' when GBIF files the target as a synonym of X) or,
# where GBIF lacks the target, NCBI Taxonomy (Stage 2) as stated. Sources:
# AntCat/AntWiki, World Spider Catalog (WSC), Orthoptera Species File (OSF),
# Catalogue of Life (CoL 3LR), WoRMS, Avibase/IOC for the old bird names.

    # New-source wave (#71-#79)
    "Chelaner_cinctum"                = "Chelaner_rubriceps",              # Leahy_2025, 89 rows: Monomorium rubriceps var. cinctum Wheeler 1917, junior synonym of rubriceps (Heterick 2001: 435; AntCat); Chelaner resurrected by Sparks et al. 2019; GBIF has no Chelaner species, NCBI taxid 3412669 resolves it (as it does Chelaner bihamatus of the same source); CoL 3LR accepted
    "Ochetellus_clarithorax"          = "Ochetellus_glaber",               # Leahy_2025, 10 rows: a subspecies, Ochetellus glaber clarithorax Forel 1902 (AntCat; GBIF 6246425), folded to the species as the trinomial rule does; GBIF 1321647 EXACT 99
    "Lamprichthys_tanganyikae"        = "Lamprichthys_tanganicanus",       # Vanni_2017, 8 rows (McIntyre 2006): the only species of the genus, L. tanganicanus (Boulenger 1898); GBIF 2349709 EXACT
    "Orthellia_caesarion"             = "Neomyia_cornicina",               # Gonzalez_2025, 1 row (Hamback et al. 2009): Musca caesarion Meigen 1826 is a junior synonym of Neomyia cornicina (Fabricius 1781); GBIF files Orthellia as a synonym genus of Neomyia
    "Prionchulus_muscoroum"           = "Prionchulus_muscorum",            # Ghaderi_2026, 2 rows (Ahmad & Jairajpuri 2010): source typo; GBIF 11899764 EXACT
    "Taeniotes_scalaris"              = "Taeniotes_scalatus",              # Baach_2026, 1 row: GBIF holds T. scalaris (Fabricius 1781) only as a synonym of Taeniotes scalatus (Gmelin 1790) (usage 7408799 -> 7806624) among 20 homonymous usages, so species/match falls back to the genus; CoL 3LR 'ambiguous synonym'
    "Taeinotes_scalaris"              = "Taeniotes_scalatus",              # Chown_etal_2007, Ehnes_etal_2011, Herberstein_etal_2022, Makarieva_2008 (4 rows): 'ei' transposed in the genus; same target as above
    # Vanni_2017's six source misspellings (README), fuzzy-matched by GBIF at 84-98; made exact here
    "Serasalmus_rhombeus"             = "Serrasalmus_rhombeus",            # 4 rows: missing r; GBIF 2354124 EXACT
    "Astetheros_alfari"               = "Astatheros_alfari",               # 74 rows: Astatheros alfari (Meek 1907) [accepted Cribroheros alfari, GBIF 9326396]
    "Priapicthys_annectens"           = "Priapichthys_annectens",          # 90 rows: missing h; GBIF 2350416 EXACT
    "Salminus_hilari"                 = "Salminus_hilarii",                # 8 rows: Valenciennes 1850 epithet ends -ii; GBIF 2354779 EXACT (merges with the existing Salminus_hilarii)
    "Symbranchus_marmoratus"          = "Synbranchus_marmoratus",          # 2 rows: Bloch 1795; GBIF 2351980
    "Brachyraphis_parismina"          = "Brachyrhaphis_parismina",         # 31 rows: missing h; GBIF 2350294 EXACT

    # Brose_etal_2018 / Brose_2005
    "Plectophoreus_fischeri"          = "Plectophloeus_fischeri",          # 345 rows: Plectophloeus fischeri (Aube 1833), Staphylinidae: Pselaphinae; GBIF alternative at 75
    "Stoidis_aurata"                  = "Anasaitis_canosa",                # 244 rows: Stoidis aurata (Hentz 1846) is a synonym of Anasaitis canosa (Walckenaer 1837) (WSC); GBIF 2177101 EXACT 99
    "Metacyrba_undata"                = "Platycryptus_undatus",            # 216 rows: Attus undatus De Geer 1778, now Platycryptus undatus (WSC); GBIF 2171189 EXACT 99
    "Conochiloides_unicornis"         = "Conochilus_unicornis",            # 187 rows: Conochilus unicornis Rousselet 1892 (rotifer); GBIF EXACT
    "Conochiloides_hippocrepis"       = "Conochilus_hippocrepis",          # 7 rows: Conochilus hippocrepis (Schrank 1803); GBIF EXACT
    "Fissurella_puhlcra"              = "Fissurella_pulchra",              # 144 rows: 'hl' transposed; G.B. Sowerby I 1834; GBIF 4956275
    "Scleroderma_macrogaster"         = "Sclerodermus_macrogaster",        # 126 rows: Sclerodermus macrogaster (Ashmead 1887), Bethylidae; GBIF alternative at 75 (Scleroderma is a fungus genus)
    "Oiketicus_abbottii"              = "Oiketicus_abbotii",               # 90 rows: Abbot's bagworm, Oiketicus abbotii Grote 1880; GBIF lacks it, NCBI taxid 2680753 (Stage 2)
    "Phalacrocorax_dilophus"          = "Phalacrocorax_auritus",           # 86 rows: Carbo dilophus Vieillot 1817 is the double-crested cormorant, P. auritus (Lesson 1831) [accepted Nannopterum auritum]
    "Cinclodes_nifrofumanus"          = "Cinclodes_nigrofumosus",          # 69 rows: garbled epithet; Cinclodes nigrofumosus (d'Orbigny & Lafresnaye 1838); GBIF 2485053
    "Poecilipa_rhizophorae"           = "Coccotrypes_rhizophorae",         # 68 rows: Poecilips rhizophorae Hopkins 1915, the mangrove bark beetle, now Coccotrypes rhizophorae (Scolytinae); GBIF EXACT
    "Ctenocidaris_gilberti"           = "Ctenocidaris_geliberti",          # 53 rows: Ctenocidaris geliberti (Koehler 1912); GBIF 4341416
    "Paracryptocerus_varians"         = "Cephalotes_varians",              # 41 rows: Paracryptocerus is a junior synonym of Cephalotes (AntCat); Cephalotes varians (Smith 1876); GBIF EXACT
    "Hemistenus_flavipes"             = "Stenus_flavipes",                 # Brose_2005, Brose_etal_2018, 40 rows: Hemistenus is a subgenus of Stenus; Stenus flavipes Stephens 1833; GBIF EXACT
    "Yolida_eightsi"                  = "Yoldia_eightsii",                 # 37 rows: Yoldia eightsii (Jay 1839) [accepted Aequiyoldia eightsii, GBIF 7351954]
    "Crychus_caraboides"              = "Cychrus_caraboides",              # 33 rows: 'ry' transposed; Cychrus caraboides (Linnaeus 1758); GBIF alternative
    "Rhithropanopeus_hermandii"       = "Rhithropanopeus_harrisii",        # 28 rows: the only species of the genus, R. harrisii (Gould 1841); GBIF 2227663
    "Cloacitrema_michiganiensis"      = "Cloacitrema_michiganensis",       # Brose_etal_2018, Hechinger_etal_2011, 25 rows: McIntosh 1938 epithet; GBIF 8805510
    "Anocha_lyolepis"                 = "Anchoa_lyolepis",                 # 23 rows: 'ch'/'oc' transposed; the anchovy Anchoa lyolepis (Evermann & Marsh 1900), not the gall midge genus Anocha GBIF matches; GBIF alternative
    "Polyhydrus_lineatus"             = "Porhydrus_lineatus",              # Brose_2005, Brose_etal_2018, 17 rows: Porhydrus lineatus (Fabricius 1775), Dytiscidae; GBIF alternative
    "Turbularia_indivisa"             = "Tubularia_indivisa",              # 15 rows: spurious r; Linnaeus 1758; GBIF alternative
    "Peridinium_pulsillum"            = "Peridinium_pusillum",             # Brose_2005, Brose_etal_2018, 10 rows: spurious l; (Penard) Lemmermann [accepted Parvodinium pusillum, GBIF 8199367]
    "Arctinula_groenlandica"          = "Similipecten_greenlandicus",      # 2 rows: Arctinula greenlandica (G.B. Sowerby II 1842), now Similipecten greenlandicus (WoRMS); GBIF 4374432
    "Leognathus_equulus"              = "Leiognathus_equulus",             # Brose_2005, 1 row: missing i; (Forsskal 1775); GBIF 5211415
    "Lymnea_peregra"                  = "Lymnaea_peregra",                 # Brose_2005, 1 row: Lymnaea peregra (O.F. Muller 1774) [accepted Peregriana peregra, GBIF 9842003]

    # VertNet Sept-2016 dumps and the old bird/mammal combinations of other sources
    "Alcippe_schaefferi"              = "Alcippe_davidi",                  # vertnet-aves, vertnet-traits, 34 rows: Alcippe davidi schaefferi La Touche 1923, a subspecies of David's fulvetta (Avibase); GBIF 6100899 EXACT 99
    "Trichastoma_fulvescens"          = "Illadopsis_fulvescens",           # 26 rows: Illadopsis fulvescens (Cassin 1859); GBIF EXACT
    "Trichastoma_albipectus"          = "Illadopsis_albipectus",           # 22 rows: Illadopsis albipectus (Reichenow 1887); GBIF EXACT
    "Trichastoma_pyrrhopterum"        = "Illadopsis_pyrrhoptera",          # 12 rows: Illadopsis pyrrhoptera (Reichenow & Neumann 1895); GBIF EXACT
    "Trichastoma_rufipenne"           = "Illadopsis_rufipennis",           # 9 rows: Illadopsis rufipennis (Sharpe 1872); CoL 3LR synonym -> Illadopsis; GBIF EXACT
    "Trichastoma_poliothorax"         = "Kakamega_poliothorax",            # 3 rows: Kakamega poliothorax (Reichenow 1900); GBIF EXACT
    "Trichastoma_sepiarium"           = "Malacocincla_sepiaria",           # 2 rows: Malacocincla sepiaria (Horsfield 1821); GBIF EXACT
    "Erithacus_aequatorialis"         = "Sheppardia_aequatorialis",        # 22 rows: Sheppardia aequatorialis (Jackson 1906); GBIF EXACT
    "Erithacus_erythrothorax"         = "Stiphrornis_erythrothorax",       # 21 rows: Stiphrornis erythrothorax Hartlaub 1855; GBIF EXACT
    "Erithacus_cyornithopsis"         = "Sheppardia_cyornithopsis",        # 2 rows: Sheppardia cyornithopsis (Sharpe 1901); GBIF EXACT
    "Erithacus_gunningi"              = "Sheppardia_gunningi",             # 2 rows: Sheppardia gunningi Haagner 1909; GBIF EXACT
    "Erithacus_sharpei"               = "Sheppardia_sharpei",              # 2 rows: Sheppardia sharpei (Shelley 1903); GBIF EXACT
    "Erithacus_chrysaeus"             = "Tarsiger_chrysaeus",              # vertnet-traits, 2 rows: Tarsiger chrysaeus Hodgson 1845; GBIF EXACT
    "Luscinia_chrysaea"               = "Tarsiger_chrysaeus",              # vertnet-aves, 1 row: same species
    "Anthodiaeta_collaris"            = "Hedydipna_collaris",              # 9 rows: Hedydipna collaris (Vieillot 1819); GBIF EXACT
    "Rhamphococcyx_curvirostris"      = "Phaenicophaeus_curvirostris",     # 9 rows: Phaenicophaeus curvirostris (Shaw 1810) [accepted Zanclostomus curvirostris, GBIF 2496397]
    "Thripophaga_pyrrholeuca"         = "Asthenes_pyrrholeuca",            # 9 rows: Asthenes pyrrholeuca (Vieillot 1817); GBIF EXACT
    "Thripophaga_humicola"            = "Asthenes_humicola",               # 5 rows: Asthenes humicola (Kittlitz 1830); GBIF EXACT
    "Thripophaga_humilis"             = "Asthenes_humilis",                # 5 rows: Asthenes humilis (Cabanis 1873); GBIF EXACT
    "Thripophaga_modesta"             = "Asthenes_modesta",                # 4 rows: Asthenes modesta (Eyton 1852); GBIF EXACT
    "Thripophaga_pudibunda"           = "Asthenes_pudibunda",              # 2 rows: Asthenes pudibunda (Sclater 1874); GBIF EXACT
    "Thripophaga_flammulata"          = "Asthenes_flammulata",             # 1 row: Asthenes flammulata (Jardine 1850); GBIF EXACT
    "Thripophaga_wyatti"              = "Asthenes_wyatti",                 # 1 row: Asthenes wyatti (Sclater & Salvin 1871); GBIF EXACT
    "Phloeoceastes_guatemalensis"     = "Campephilus_guatemalensis",       # 8 rows: Campephilus guatemalensis (Hartlaub 1844); GBIF 2478580
    "Niltava_superba"                 = "Cyornis_superbus",                # 7 rows: Cyornis superbus (Stresemann 1925); GBIF EXACT
    "Niltava_caerulata"               = "Cyornis_caerulatus",              # 4 rows: Cyornis caerulatus (Bonaparte 1857); GBIF EXACT
    "Niltava_concreta"                = "Cyornis_concretus",               # 2 rows: Cyornis concretus (Muller 1836); GBIF EXACT
    "Niltava_herioti"                 = "Cyornis_herioti",                 # 1 row: Cyornis herioti Ramsay 1886; GBIF EXACT
    "Pogoniulus_duchaillui"           = "Buccanodon_duchaillui",           # 6 rows: Buccanodon duchaillui (Cassin 1856); GBIF EXACT
    "Salpinctes_mexicanus"            = "Catherpes_mexicanus",             # 5 rows: canyon wren, Catherpes mexicanus (Swainson 1829); GBIF EXACT
    "Anous_albus"                     = "Gygis_alba",                      # vertnet-aves, vertnet-traits, 4 rows: Sterna alba Sparrman 1786, the white tern Gygis alba; GBIF EXACT
    "Cacomantis_pyrrophanus"          = "Cacomantis_flabelliformis",       # 4 rows: Cuculus pyrrhophanus Vieillot 1817 is a synonym of the fan-tailed cuckoo C. flabelliformis (Latham 1801); GBIF EXACT
    "Ptilinopus_bellus"               = "Ptilinopus_rivoli",               # vertnet-traits, 4 rows: P. rivoli bellus Sclater 1873, a subspecies; GBIF EXACT
    "Remiz_flaviceps"                 = "Auriparus_flaviceps",             # 4 rows: the verdin, Auriparus flaviceps (Sundevall 1850), never a Remiz; GBIF EXACT
    "Caloramphus_parvirostris"        = "Colorhamphus_parvirostris",       # 3 rows: Colorhamphus parvirostris (Darwin 1839), Tyrannidae, not the barbet genus Caloramphus; GBIF alternative at 73
    "Cyanocompsa_cyanea"              = "Cyanocompsa_brissonii",           # 3 rows: Loxia cyanea Linnaeus 1766 is preoccupied; the ultramarine grosbeak is C. brissonii (Lichtenstein 1823) [accepted Cyanoloxia brissonii]
    "Mionectes_mcconnelli"            = "Mionectes_macconnelli",           # 3 rows: Mionectes macconnelli (Chubb 1919); GBIF alternative
    "Petroica_cucullata"              = "Melanodryas_cucullata",           # 3 rows: Melanodryas cucullata (Latham 1801); GBIF EXACT
    "Petroica_vittata"                = "Melanodryas_vittata",             # 1 row: Melanodryas vittata (Quoy & Gaimard 1830); GBIF EXACT
    "Philydor_rufosuperciliatus"      = "Syndactyla_rufosuperciliata",     # 3 rows: Syndactyla rufosuperciliata (Lafresnaye 1832); GBIF EXACT
    "Seisura_inquieta"                = "Myiagra_inquieta",                # 3 rows: Myiagra inquieta (Latham 1801); GBIF EXACT
    "Aegithina_riphia"                = "Aegithina_tiphia",                # 2 rows: 'r' for 't'; (Linnaeus 1758); GBIF 2484096
    "Anthreptes_olivacea"             = "Cyanomitra_olivacea",             # 2 rows: Cyanomitra olivacea (Smith 1840); GBIF EXACT
    "Certhiaxis_erythrops"            = "Cranioleuca_erythrops",           # 2 rows: Cranioleuca erythrops (Sclater 1860); GBIF EXACT
    "Certhiaxis_curtata"              = "Cranioleuca_curtata",             # 1 row: Cranioleuca curtata (Sclater 1870); GBIF EXACT
    "Certhiaxis_pyrrhophia"           = "Cranioleuca_pyrrhophia",          # 1 row: Cranioleuca pyrrhophia (Vieillot 1818); GBIF EXACT
    "Cettia_whiteheadi"               = "Urosphena_whiteheadi",            # 2 rows: Urosphena whiteheadi (Sharpe 1888); GBIF EXACT
    "Cheilopogon_xenopterusgroup"     = "Cheilopogon_xenopterus",          # vertnet-fishes, vertnet-traits, 2 rows: 'Cheilopogon xenopterus group' glued; the nominal species (Gilbert 1890); GBIF 5207992
    "Cissilopha_melanocyanea"         = "Cyanocorax_melanocyaneus",        # Herberstein_etal_2022, vertnet-aves, 2 rows: Cyanocorax melanocyaneus (Hartlaub 1844); GBIF 2482577
    "Cissilopha_beecheii"             = "Cyanocorax_beecheii",             # Herberstein_etal_2022, 1 row: Cyanocorax beecheii (Vigors 1829); GBIF 2482570
    "Emblema_bella"                   = "Stagonopleura_bella",             # 2 rows: Stagonopleura bella (Latham 1801); GBIF EXACT
    "Geositta_excelsior"              = "Cinclodes_excelsior",             # 2 rows: Geositta excelsior Sclater 1860 is the stout-billed cinclodes, Cinclodes excelsior; GBIF EXACT
    "Hypergerus_lepidus"              = "Eminia_lepida",                   # 2 rows: Eminia lepida Hartlaub 1881; GBIF EXACT
    "Leptopterus_madagascarinus"      = "Cyanolanius_madagascarinus",      # 2 rows: Cyanolanius madagascarinus (Linnaeus 1766); GBIF EXACT
    "Meliphaga_plumula"               = "Ptilotula_plumula",               # 2 rows: Ptilotula plumula (Gould 1841); GBIF EXACT
    "Meliphaga_flava"                 = "Stomiopera_flava",                # 1 row: Stomiopera flava (Gould 1843); GBIF EXACT
    "Neositta_chrysoptera"            = "Daphoenositta_chrysoptera",       # vertnet-aves, vertnet-traits, 2 rows: Daphoenositta chrysoptera (Latham 1801); GBIF 2487489
    "Poliopsar_cineraceus"            = "Spodiopsar_cineraceus",           # 2 rows: Spodiopsar cineraceus (Temminck 1835); GBIF EXACT
    "Spreo_hildebrandti"              = "Lamprotornis_hildebrandti",       # 2 rows: Lamprotornis hildebrandti (Cabanis 1878); GBIF 2489078
    "Aegithalos_cocinnus"             = "Aegithalos_concinnus",            # vertnet-traits, 1 row: missing n; (Gould 1855); GBIF 2494998
    "Aglaiocercus_emmae"              = "Aglaiocercus_kingii",             # 1 row: A. kingii emmae (Berlepsch 1892), a subspecies; GBIF EXACT
    "Aimophila_refiaps"               = "Aimophila_ruficeps",              # 1 row: garbled epithet; (Cassin 1852); GBIF 2491961
    "Amoropsittaca_aymara"            = "Psilopsiagon_aymara",             # vertnet-traits, 1 row: CoL 3LR synonym -> Psilopsiagon aymara (d'Orbigny 1839); GBIF EXACT
    "Ampelion_cedrorum"               = "Bombycilla_cedrorum",             # 1 row: Ampelis cedrorum Vieillot 1808, the cedar waxwing, not the cotinga genus Ampelion; GBIF EXACT
    "Apus_andecolus"                  = "Aeronautes_andecolus",            # 1 row: Aeronautes andecolus (d'Orbigny & Lafresnaye 1837); GBIF EXACT
    "Artomyias_fuliginosus"           = "Muscicapa_infuscata",             # 1 row: Artomyias fuliginosa Verreaux 1855 is the sooty flycatcher Muscicapa infuscata (Cassin 1855) (HBW); GBIF EXACT
    "Automolus_ruficollis"            = "Syndactyla_ruficollis",           # vertnet-traits, 1 row: Syndactyla ruficollis (Taczanowski 1884); GBIF EXACT
    "Bradornis_semipartitus"          = "Empidornis_semipartitus",         # 1 row: the silverbird, Empidornis semipartitus (Ruppell 1840); GBIF 2492399
    "Buteo_borealis"                  = "Buteo_jamaicensis",               # 1 row: Falco borealis Gmelin 1788 is the red-tailed hawk B. jamaicensis (Gmelin 1788); GBIF EXACT
    "Calandrella_dunni"               = "Eremalauda_dunni",                # 1 row: Eremalauda dunni (Shelley 1904); GBIF EXACT
    "Carduelis_linaria"               = "Acanthis_flammea",                # 1 row: Fringilla linaria Linnaeus 1758 is the common redpoll; GBIF EXACT
    "Cercococcyx_patulus"             = "Cercococcyx_montanus",            # 1 row: C. montanus patulus Friedmann 1928, a subspecies; GBIF EXACT
    "Ceyx_cristata"                   = "Corythornis_cristatus",           # 1 row: Alcedo cristata Pallas 1764, the malachite kingfisher; GBIF EXACT
    "Chrysococcyx_malayanus"          = "Chrysococcyx_minutillus",         # 1 row: C. minutillus malayanus (Raffles 1822), a subspecies; GBIF EXACT
    "Climacteris_leucophaea"          = "Cormobates_leucophaea",           # 1 row: Cormobates leucophaea (Latham 1801); GBIF EXACT
    "Elaenia_viridicata"              = "Myiopagis_viridicata",            # 1 row: Myiopagis viridicata (Vieillot 1817); GBIF EXACT
    "Eurostopodus_guttatus"           = "Eurostopodus_argus",              # vertnet-traits, 1 row: Caprimulgus guttatus Vigors & Horsfield 1827 is a synonym of the spotted nightjar E. argus Hartert 1892; GBIF EXACT
    "Gabianus_pacificus"              = "Larus_pacificus",                 # 1 row: Larus pacificus Latham 1801; GBIF 2481147
    "Halcyon_recurvirostris"          = "Todiramphus_recurvirostris",      # 1 row: Todiramphus recurvirostris (Lafresnaye 1842); GBIF EXACT
    "Hierococcyx_clamosus"            = "Cuculus_clamosus",                # 1 row: Cuculus clamosus Latham 1801, the black cuckoo; GBIF EXACT
    "Hirundo_erythrogastra"           = "Hirundo_rustica",                 # 1 row: Hirundo erythrogaster Boddaert 1783, CoL 3LR synonym of H. rustica; GBIF EXACT
    "Hylocichla_guttata"              = "Catharus_guttatus",               # 1 row: Catharus guttatus (Pallas 1811); GBIF EXACT
    "Icterus_melanocephalus"          = "Icterus_graduacauda",             # 1 row: Icterus melanocephalus (Wagler 1829) is a synonym of Audubon's oriole I. graduacauda Lesson 1839; GBIF EXACT
    "Lichenostomus_chysops"           = "Caligavis_chrysops",              # 1 row: missing r; Caligavis chrysops (Latham 1801); GBIF 8197121
    "Malacocichla_abbotti"            = "Malacocincla_abbotti",            # vertnet-traits, 1 row: Malacocincla abbotti Blyth 1845; GBIF alternative at 75
    "Margarornis_gutteliger"          = "Premnornis_guttuliger",           # 1 row: Margarornis guttuliger Sclater 1864, now Premnornis guttuliger; GBIF EXACT
    "Meagris_gallopavo"               = "Meleagris_gallopavo",             # 1 row: missing 'le'; GBIF alternative
    "Megascops_flammeolus"            = "Psiloscops_flammeolus",           # 1 row: Psiloscops flammeolus (Kaup 1853); GBIF EXACT
    "Molothrus_aenus"                 = "Molothrus_aeneus",                # vertnet-traits, 1 row: missing e; (Wagler 1829); GBIF 2484404
    "Nectarinia_seperata"             = "Leptocoma_sperata",               # 1 row: Leptocoma sperata (Linnaeus 1766); GBIF EXACT
    "Nectarinia_sericeus"             = "Leptocoma_sericea",               # 1 row: Leptocoma sericea (Lesson 1827); GBIF EXACT
    "Nycitdromus_nigrescens"          = "Nyctipolus_nigrescens",           # vertnet-traits, 1 row: Nyctipolus nigrescens (Cabanis 1849); GBIF EXACT
    "Oreochelidon_murina"             = "Orochelidon_murina",              # 1 row: spurious e; Orochelidon murina (Cassin 1853) [accepted Notiochelidon murina, GBIF 2489177]
    "Pygochelidon_murina"             = "Orochelidon_murina",              # vertnet-traits, 1 row: same species
    "Pachyramphus_alglaiae"           = "Pachyramphus_aglaiae",            # vertnet-traits, 1 row: spurious l; (Lafresnaye 1839); GBIF 5230329
    "Patagioenas_leucomela"           = "Columba_leucomela",               # vertnet-traits, 1 row: the white-headed pigeon Columba leucomela Temminck 1821 (Patagioenas is the New World genus); GBIF EXACT
    "Pediocetes_phasianellus"         = "Tympanuchus_phasianellus",        # vertnet-traits, 1 row: Tympanuchus phasianellus (Linnaeus 1758); GBIF EXACT
    "Petrochelidon_lunifrons"         = "Petrochelidon_pyrrhonota",        # 1 row: Hirundo lunifrons Say 1823 is a synonym of the cliff swallow P. pyrrhonota (Vieillot 1817); GBIF EXACT
    "Pipilo_erythrophthalmusoca"      = "Pipilo_erythrophthalmus",         # vertnet-traits, 1 row: 'erythrophthalmus x ocai' glued; credited to the first name as the hybrid rule does
    "Falco_peregrinusxmexicanus"      = "Falco_peregrinus",                # vertnet-aves, 2 rows: 'peregrinus x mexicanus' glued; credited to the first name as the hybrid rule does
    "Quiscalus_cassidix"              = "Quiscalus_mexicanus",             # 1 row: Cassidix mexicanus; the great-tailed grackle Q. mexicanus (Gmelin 1788); GBIF 9476062
    "Quiscalus_guiscula"              = "Quiscalus_quiscula",              # vertnet-traits, 1 row: 'g' for 'q'; (Linnaeus 1758); GBIF 2484155
    "Rhamphomicron_microrhynchum"     = "Ramphomicron_microrhynchum",      # vertnet-traits, 1 row: Ramphomicron microrhynchum (Boissonneau 1840); GBIF 2476052
    "Spizella_monticola"              = "Spizelloides_arborea",            # 1 row: Fringilla monticola Gmelin 1789 is the American tree sparrow, Spizelloides arborea (Wilson 1810); GBIF EXACT
    "Sterna_fosteri"                  = "Sterna_forsteri",                 # vertnet-traits, 1 row: missing r; Nuttall 1834; GBIF alternative
    "Synallaxis_gularis"              = "Hellmayrea_gularis",              # 1 row: CoL 3LR synonym -> Hellmayrea gularis (Lafresnaye 1843); GBIF EXACT
    "Tchagra_cruenta"                 = "Rhodophoneus_cruentus",           # 1 row: Rhodophoneus cruentus (Hemprich & Ehrenberg 1828) [accepted Telophorus cruentus, GBIF 6100952]
    "Uria_aagle"                      = "Uria_aalge",                      # 1 row: 'gl' transposed; (Pontoppidan 1763); GBIF alternative
    "Vermivora_rubricapilla"          = "Leiothlypis_ruficapilla",         # 1 row: Vermivora rubricapilla (Wilson 1811) is the Nashville warbler, Leiothlypis ruficapilla; GBIF EXACT
    "Zenaida_leucoptera"              = "Zenaida_asiatica",                # 1 row: Melopelia leucoptera; the white-winged dove Z. asiatica (Linnaeus 1758); GBIF EXACT
    "Mabuya_perrotetii"               = "Trachylepis_perrotetii",          # vertnet-traits, 6 rows: Trachylepis perrotetii (Dumeril & Bibron 1839); GBIF EXACT
    "Elaphodus_michianus"             = "Elaphodus_cephalophus",           # vertnet-mammalia, 1 row: E. cephalophus michianus (Swinhoe 1874), a subspecies of the tufted deer; GBIF EXACT
    "Epomophorus_walbergi"            = "Epomophorus_wahlbergi",           # vertnet-mammalia, 1 row: missing h; (Sundevall 1846); GBIF 2432787
    "Microtus_terraenovae"            = "Microtus_pennsylvanicus",         # vertnet-traits, 1 row: M. pennsylvanicus terraenovae (Bangs 1894), the Newfoundland subspecies; GBIF EXACT
    "Tadarida_leonis"                 = "Mops_leonis",                     # vertnet-mammalia, 1 row: Nyctinomus leonis Thomas 1908, the Sierra Leone free-tailed bat [accepted Mops brachypterus, GBIF 2433070]
    "Chilonycteris_parnelli"          = "Pteronotus_parnellii",            # vertnet-traits, 1 row: Pteronotus parnellii (Gray 1843); GBIF 5218620
    "Cheilopogon_callopterus"         = "Cypselurus_callopterus",          # vertnet-traits, 1 row: the ornamented flyingfish Cypselurus callopterus (Gunther 1866); GBIF EXACT
    "Rynchocyclus_olivaceus"          = "Rhynchocyclus_olivaceus",         # vertnet-aves, vertnet-traits, 2 rows: missing h; (Temminck 1820); GBIF alternative
    "Rattus_novergicus"               = "Rattus_norvegicus",               # vertnet-traits, 1 row: 'rv' transposed; GBIF 2439261
    "Thamnophis_collaris"             = "Thamnophis_cyrtopsis",            # vertnet-reptilia, 1 row: Tropidonotus collaris Jan 1863 is T. cyrtopsis collaris, a subspecies of the black-necked gartersnake; GBIF EXACT

    # Herberstein_etal_2022
    "Macacus_mulatta"                 = "Macaca_mulatta",                  # 4 rows: Macacus is a synonym genus (GBIF); Macaca mulatta (Zimmermann 1780); GBIF 2436604
    "Pachygonia_drucei"               = "Pachygonidia_drucei",             # Chown_etal_2007, Ehnes_etal_2011, Herberstein_etal_2022, Makarieva_2008 (4 rows): Pachygonidia drucei (Rothschild & Jordan 1903), Sphingidae; GBIF 1864249
    "Faiditus_elevatus"               = "Argyrodes_elevatus",              # 2 rows: Argyrodes elevatus Taczanowski 1873 stays in Argyrodes (WSC); GBIF EXACT
    "Mustela_arctica"                 = "Mustela_erminea",                 # 2 rows: M. erminea arctica (Merriam 1896), a subspecies; GBIF EXACT
    "Nycticebus_tardigradus"          = "Nycticebus_coucang",              # 2 rows: Lemur tardigradus Linnaeus 1758 as used for the slow loris is N. coucang (Boddaert 1785); GBIF ambiguous between two homonyms, hence HIGHERRANK; GBIF EXACT on the target
    "Trachymyrmex_coniktzi"           = "Trachymyrmex_cornetzi",           # 2 rows: Trachymyrmex cornetzi (Forel 1912); GBIF 1326468
    "Apalone_forex"                   = "Apalone_ferox",                   # 1 row: 'o' for 'e'; (Schneider 1783); GBIF 2442665
    "Canis_lubilus"                   = "Canis_lupus",                     # 1 row: Canis nubilus Say 1823, the plains wolf, a subspecies of C. lupus; GBIF EXACT
    "Cercopithecus_rufoviridis"       = "Chlorocebus_pygerythrus",         # 1 row: Cercopithecus aethiops rufoviridis Geoffroy 1843, a vervet subspecies, now Chlorocebus pygerythrus; GBIF EXACT
    "Chaerophon_ieucostigma"          = "Chaerephon_leucostigma",          # 1 row: 'i' for 'l' and misspelt genus; Chaerephon leucostigma Allen 1918 [accepted Mops leucostigma, GBIF 4266488]
    "Chaerophon_limbatus"             = "Chaerephon_pumilus",              # 1 row: Nyctinomus limbatus Peters 1852 is a synonym of C. pumilus (Cretzschmar 1826); GBIF EXACT
    "Crocidura_occidenlalis"          = "Crocidura_olivieri",              # 1 row: Crocidura occidentalis (Pucheran 1855), a synonym of C. olivieri (Lesson 1827); GBIF EXACT
    "Cryptoglossa_verrucossa"         = "Asbolus_verrucosus",              # 1 row: Cryptoglossa verrucosa LeConte 1851 is the desert ironclad beetle Asbolus verrucosus; GBIF 9670677 EXACT 99
    "Cryptoglossa_verrucosa"          = "Asbolus_verrucosus",              # Baach_2026, Chown_etal_2007, Ehnes_etal_2011, Makarieva_2008 (4 rows): same species
    "Dactylonax_tatei"                = "Dactylopsila_tatei",              # 1 row: Dactylopsila tatei Laurie 1952; GBIF EXACT
    "Dactylonax_trivirgata"           = "Dactylopsila_trivirgata",         # 1 row: Dactylopsila trivirgata Gray 1858; GBIF EXACT
    "Diaemus_rotundus"                = "Desmodus_rotundus",               # 1 row: the common vampire bat Desmodus rotundus (Geoffroy 1810); Diaemus is the white-winged vampire; GBIF EXACT
    "Eulemur_catta"                   = "Lemur_catta",                     # 1 row: ring-tailed lemur Lemur catta Linnaeus 1758; GBIF EXACT
    "Eulemur_rufiventer"              = "Eulemur_rubriventer",             # 1 row: Eulemur rubriventer (Geoffroy 1850); GBIF 2436421
    "Eulemur_variegatus"              = "Varecia_variegata",               # 1 row: Varecia variegata (Kerr 1792); GBIF EXACT
    "Galagoides_crassicaudatus"       = "Otolemur_crassicaudatus",         # 1 row: Otolemur crassicaudatus (Geoffroy 1812); GBIF EXACT
    "Galagoides_senegalensis"         = "Galago_senegalensis",             # 1 row: Galago senegalensis Geoffroy 1796; GBIF EXACT
    "Macrochelys_lacertina"           = "Macrochelys_temminckii",          # 1 row: Chelonura lacertina Schweigger 1812, a synonym of the alligator snapping turtle M. temminckii (Troost 1835); GBIF EXACT
    "Marmosa_mitis"                   = "Marmosa_robinsoni",               # 1 row: Marmosa mitis Bangs 1898, a synonym of M. robinsoni Bangs 1898 (Gardner 2008); GBIF EXACT
    "Midas_ursulus"                   = "Saguinus_ursulus",                # 1 row: Midas ursulus Hoffmannsegg 1807, the black tamarin Saguinus ursulus; GBIF 11011727
    "Parantechinus_macdonnellensis"   = "Pseudantechinus_macdonnellensis", # 1 row: Pseudantechinus macdonnellensis (Spencer 1896); GBIF EXACT
    "Parantechinus_roryi"             = "Pseudantechinus_roryi",           # 1 row: Pseudantechinus roryi Cooper, Aplin & Adams 2000; GBIF EXACT
    "Parantechinus_rosamondae"        = "Dasykaluta_rosamondae",           # 1 row: Dasykaluta rosamondae (Ride 1964); GBIF EXACT
    "Peromyscus_pirrensis"            = "Peromyscus_mexicanus",            # 6 rows: Peromyscus pirrensis Goldman 1912 (Darien) is a synonym of P. mexicanus (Musser & Carleton 2005); GBIF EXACT
    "Pteropus_edwarsi"                = "Pteropus_rufus",                  # 1 row: Pteropus edwardsi Geoffroy 1828 is a synonym of the Madagascan flying fox P. rufus Geoffroy 1803; GBIF EXACT
    "Ptilonorhynchus_maculatus"       = "Chlamydera_maculata",             # 1 row: Chlamydera maculata (Gould 1837); GBIF EXACT
    "Symposiarchus_trivirgatus"       = "Symposiachrus_trivirgatus",       # 1 row: 'rch' for 'chr'; Symposiachrus trivirgatus (Temminck 1826); GBIF 7342258
    "Tachyglossus_setosus"            = "Tachyglossus_aculeatus",          # 1 row: T. aculeatus setosus (Geoffroy 1803), the Tasmanian subspecies; GBIF EXACT
    "Trichomys_apereoides"            = "Thrichomys_apereoides",           # 1 row: missing h; (Lund 1839); GBIF alternative
    "Trichosurus_fuliginosus"         = "Trichosurus_vulpecula",           # 1 row: T. vulpecula fuliginosus (Ogilby 1831), the Tasmanian subspecies; GBIF EXACT

    # Chown_etal_2007 / Ehnes_etal_2011 / Makarieva_2008 / Baach_2026 insects
    "Bootettix_punctatus"             = "Bootettix_argentatus",            # Baach_2026, Chown_etal_2007, Ehnes_etal_2011, Herberstein_etal_2022, Makarieva_2008 (6 rows): Gymnes punctatus Scudder 1890 sunk into B. argentatus Bruner 1889 by Otte 1981 (OSF); GBIF 1708881
    "Forelius_foetidus"               = "Forelius_mccooki",                # same five sources (5 rows): Formica foetida Buckley 1866 is a junior homonym; F. mccooki (McCook 1880) is its replacement name (Bolton 1995; Cuezzo 2000; AntCat); GBIF 1327302
    "Centrioptera_muricata"           = "Cryptoglossa_muricata",           # same five sources (5 rows): Cryptoglossa muricata (LeConte 1851); GBIF 9699773 (Centrioptera a synonym genus)
    "Campalita_chlorostictum"         = "Calosoma_chlorostictum",          # Baach_2026, Chown_etal_2007, Ehnes_etal_2011, Makarieva_2008 (4 rows): Campalita is a subgenus of Calosoma; Calosoma chlorostictum Dejean 1831; GBIF 8084580
    "Chelaner_rothsteini"             = "Monomorium_rothsteini",           # same four sources (4 rows): Monomorium rothsteini Forel 1902 (now Chelaner, Sparks et al. 2019); GBIF has only the Monomorium combination and NCBI lacks the Chelaner one; GBIF EXACT
    "Oedalis_instillatus"             = "Oedaleus_instillatus",            # same four sources (4 rows): Oedaleus instillatus Burr 1900, Acrididae; GBIF alternative at 75
    "Periplaneta_orientalis"          = "Blatta_orientalis",               # same four sources (4 rows): the oriental cockroach Blatta orientalis Linnaeus 1758; GBIF EXACT
    "Apetaloides_firmiana"            = "Apatelodes_firmiana",             # Baach_2026, Chown_etal_2007, Ehnes_etal_2011, Herberstein_etal_2022, Makarieva_2008 (5 rows): Apatelodes firmiana (Stoll 1780), Apatelodidae [accepted Hygrochroa firmiana, GBIF 1868575]
    "Gromphadorhina_chopardi"         = "Elliptorhina_chopardi",           # same five sources (5 rows): CoL 3LR synonym in Elliptorhina; Elliptorhina chopardi (Lefeuvre 1966); GBIF 1994209 EXACT 99
    "Varacosa_terricola"              = "Trochosa_terricola",              # Hirt_etal_2017, 7 rows: Trochosa terricola Thorell 1856 (WSC); GBIF EXACT
    "Phiddipus_johnsoni"              = "Phidippus_johnsoni",              # Ehnes_etal_2011, 1 row: doubled d; (Peckham & Peckham 1883); GBIF alternative at 75

    # Other sources
    "Trachyhampus_serratus"           = "Trachyrhamphus_serratus",         # Tsuboi_etal_2018, 6 rows: missing 'rh'; (Temminck & Schlegel 1850); GBIF alternative at 75
    "Altolamprologus_faciatus"        = "Altolamprologus_fasciatus",       # Tsuboi_etal_2018, 1 row: missing s; (Boulenger 1898) [accepted Neolamprologus fasciatus, GBIF 2371775]
    "Lacerta_muralis"                 = "Podarcis_muralis",                # Tsuboi_etal_2018, 1 row: the European wall lizard, Podarcis muralis (Laurenti 1768); GBIF/CoL ambiguous among homonyms (Blanford 1876 = Darevskia), hence the family fallback
    "Omatophoca_rossi"                = "Ommatophoca_rossii",              # Verberk_2020, 3 rows: missing m and i; Gray 1844; GBIF alternative
    "Athya_affinis"                   = "Aythya_affinis",                  # Hechinger_etal_2011, 2 rows: 'y' dropped; (Eyton 1838); GBIF 2498257
    "Phyllobduris_abdominalis"        = "Phyllodurus_abdominalis",         # Hechinger_etal_2011, 1 row: Phyllodurus abdominalis Stimpson 1857, Bopyridae; GBIF alternative at 75
    "Desulfovibrio_propionicus"       = "Desulfobulbus_propionicus",       # DeLong_etal_2010, 2 rows: the propionate oxidiser Desulfobulbus propionicus Widdel 1981 was never a Desulfovibrio; GBIF EXACT
    "Schizotrypanum_verpertilionis"   = "Trypanosoma_vespertilionis",      # DeLong_etal_2010, Makarieva_2008, 2 rows: subgenus used as genus and 'r' for 's'; Trypanosoma vespertilionis Battaglia 1904; GBIF lacks it, NCBI taxid 89348 (Stage 2)
    "Spirostoma_minus"                = "Spirostomum_minus",               # DeLong_etal_2010, Makarieva_2008, 2 rows: Spirostomum minus Roux 1901 (ciliate), not the snail genus Spirostoma GBIF matches; GBIF alternative at 75
    "Sicyonia_igentis"                = "Sicyonia_ingentis",               # Makarieva_2008, 2 rows: missing n; (Burkenroad 1938); GBIF alternative
    "Catharactus_skua"                = "Catharacta_skua",                 # Makarieva_2008, 1 row: Catharacta skua Brunnich 1764 [accepted Stercorarius skua, GBIF 2481618]
    "Gyrinophilus_porphyrictus"       = "Gyrinophilus_porphyriticus",      # Makarieva_2008, 1 row: missing 'ti'; (Green 1827); GBIF 2431423
    "Halitrehees_maasi"               = "Halitrephes_maasi",               # Makarieva_2008, 1 row: Halitrephes maasi Bigelow 1909; GBIF alternative at 75
    "Parastichopus_japonicus"         = "Apostichopus_japonicus",          # DeLong_etal_2010, 1 row: Apostichopus japonicus (Selenka 1867) (WoRMS); GBIF EXACT
    "Anas_plathyrhynchos"             = "Anas_platyrhynchos",              # Herberstein_etal_2022, 1 row: spurious h; CoL 3LR variant; GBIF 9761484
    "Centengraulis_mysticetus"        = "Cetengraulis_mysticetus",         # McCoy_2008, 1 row: spurious n; (Gunther 1867); GBIF alternative
    "Hiatella_byssifera"              = "Hiatella_arctica",                # McCoy_2008, 1 row: Hiatella byssifera (Fabricius 1780) is a synonym of H. arctica (Linnaeus 1767) (WoRMS); GBIF EXACT
    "Cheironectes_minimus"            = "Chironectes_minimus",             # Fisher_2001, 1 row: the water opossum Chironectes minimus (Zimmermann 1780), not the handfish genus Cheironectes GBIF matches; GBIF alternative
    "Candacia_clombidea"              = "Candacia_columbiae",              # Ikeda_2014, 1 row: garbled epithet; Candacia columbiae Campbell 1929; GBIF 2115100
    "Rincalanus_gigas"                = "Rhincalanus_gigas",               # Ikeda_2014, 1 row: missing h; Brady 1883; GBIF alternative
    "Seosergestes_corniculum"         = "Deosergestes_corniculum",         # Ikeda_2014, 1 row: 'S' for 'D'; Deosergestes corniculum (Kroyer 1855); GBIF EXACT
    "Labidocera_actifrons"            = "Labidocera_acutifrons",           # Hebert_etal_2016, 1 row: missing u; (Dana 1849); GBIF alternative
    "Leucoptera_myricki"              = "Leucoptera_meyricki",             # AndersonGillooly_2017, 1 row: Leucoptera meyricki Ghesquiere 1940, the coffee leaf miner; GBIF alternative
    "Scelopterus_undulatus"           = "Sceloporus_undulatus",            # Brown_etal_2018, 1 row: 'pt' for 'p'; (Bosc & Daudin 1801); GBIF alternative at 75
    "Lasioglossum_qudrinotatum"       = "Lasioglossum_quadrinotatum",      # Kendall_etal_2019, 1 row: missing a; (Kirby 1802); GBIF alternative
    "Melecta_punctata"                = "Melecta_albifrons",               # Kendall_etal_2019, 1 row: Melecta punctata (Fabricius 1775) is a junior synonym of M. albifrons (Forster 1771); CoL 3LR synonym; GBIF EXACT
    "Dixiphia_chloromeros"            = "Ceratopipra_chloromeros",         # Myhrvold_2015, 1 row: Pipra chloromeros Tschudi 1844, now Ceratopipra [GBIF accepted Pipra chloromeros, 2487620]
    "Dixiphia_erythrocephala"         = "Ceratopipra_erythrocephala",      # Myhrvold_2015, 1 row: Pipra erythrocephala Linnaeus 1758, now Ceratopipra [GBIF accepted Pipra erythrocephala, 2487629]
    "Aquila_ayresii"                  = "Hieraaetus_ayresii",              # Myhrvold_2015, 1 row: Hieraaetus ayresii (Gurney 1862); GBIF EXACT
    "Camptorhynchus_histrionicus"     = "Histrionicus_histrionicus",       # Myhrvold_2015, 1 row: the harlequin duck Histrionicus histrionicus (Linnaeus 1758); Camptorhynchus is the extinct Labrador duck's genus (and a weevil genus GBIF matches); GBIF EXACT
    "Peltohyas_cinctus"               = "Erythrogonys_cinctus",            # Myhrvold_2015, 1 row: Erythrogonys cinctus Gould 1838; GBIF EXACT
    "Phacellodomus_berlepschi"        = "Phacellodomus_dorsalis",          # Myhrvold_2015, 1 row: Phacellodomus berlepschi Hellmayr 1925 is the chestnut-backed thornbird P. dorsalis Salvin 1895; GBIF EXACT
    "Psephotus_haematogaster"         = "Northiella_haematogaster",        # Myhrvold_2015, 1 row: Northiella haematogaster (Gould 1838); GBIF EXACT
    "Camaroptera_undosa"              = "Calamonastes_undosus",            # Wilman_etal_2014, 1 row: Calamonastes undosus (Reichenow 1882); GBIF EXACT
    "Spermophilus_nayaritensis"       = "Sciurus_nayaritensis",            # Ernest_2003, 1 row: the Mexican fox squirrel Sciurus nayaritensis Allen 1890 was never a ground squirrel; GBIF EXACT
    "Rhinopitechus_avunculus"         = "Rhinopithecus_avunculus",         # Smith_2003, 1 row: missing h; Dollman 1912; GBIF alternative at 75
    "Rhinopitechus_bieti"             = "Rhinopithecus_bieti",             # Smith_2003, 1 row: Milne-Edwards 1897; GBIF alternative at 75
    "Rhinopitechus_brelichi"          = "Rhinopithecus_brelichi",          # Smith_2003, 1 row: Thomas 1903; GBIF alternative at 75
    "Procolobus_foai"                 = "Piliocolobus_foai",               # Smith_2003, 1 row: Piliocolobus foai (de Pousargues 1899); GBIF EXACT
    "Stenomys_omlichodes"             = "Rattus_omichlodes",               # Smith_2003, 1 row: 'li' transposed and Stenomys a synonym genus; Rattus omichlodes Misonne 1979; GBIF 4264917
    "Holopristis_ocellifera"          = "Hemigrammus_ocellifer",           # fishbase, 1 row: Holopristis is a synonym genus; Hemigrammus ocellifer (Steindachner 1882); GBIF 2354330
    "Hoplisoma_lacrimostigmata"       = "Corydoras_lacrimostigmata",       # fishbase, 1 row: Hoplisoma (Corydoradinae revision, Dias et al. 2024) is not in the GBIF backbone; Corydoras lacrimostigmata Tencatt, Lima & Britto 2019; GBIF EXACT
    "Hoplisoma_lymnades"              = "Corydoras_lymnades",              # fishbase, 1 row: Corydoras lymnades Tencatt, Vera-Alcaraz, Britto & Pavanelli 2013; GBIF EXACT
    "Paracapoeta_erhani"              = "Capoeta_erhani",                  # fishbase, 1 row: Paracapoeta Turan et al. 2022 holds only P. trutta in the GBIF backbone; Capoeta erhani Turan, Kottelat & Ekmekci 2008; GBIF EXACT
    "Paracapoeta_mandica"             = "Capoeta_mandica",                 # fishbase, 1 row: Capoeta mandica Bektas, Turan, Aksu & Kaya 2019; GBIF EXACT
    "Lobella_cavicola"                = "Lobellina_cavicola",              # Hishi_etal_2019, 1 row: Lobellina cavicola (Yosii 1956); GBIF alternative at 75
    "Lobella_kitazawai"               = "Lobellina_kitazawai",             # Hishi_etal_2019, 1 row: Lobellina kitazawai (Yosii 1969); GBIF alternative at 75
    "Lobella_roseola"                 = "Lobellina_roseola",               # Hishi_etal_2019, 1 row: Lobellina roseola (Yosii 1954); GBIF alternative at 75
    "Oik_opleura"                     = "Oikopleura"                       # Ikeda_2014, 3 rows: the genus Oikopleura split at a line break; a bare genus, filed as a genus-level record (Oikopleura Mertens 1831, GBIF 2332548 EXACT)
  )

  for (old in names(corrections)) {
    dat$taxon[dat$taxon == old] <- corrections[[old]]
  }

  return(dat)
}
