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

    # Encoding-corruption residuals (ISO-8859-1 / UTF-8 mojibake)
    # The literal multi-byte characters here match what R writes to the CSV.
    "NausithoÃ_rubra"                 = "Nausithoe_rubra",
    "Felimida_purpureaÃÂ"             = "Felimida_purpurea",
    "Ophiactis_savignyiÃÂ"            = "Ophiactis_savignyi",

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
    "Falco_spec"                      = "Falco",                          # spec placeholder stripped; genus valid
    "Formica_sstr"                    = "Formica",                        # sensu stricto tag stripped; genus valid
    "Galaxiidae_anomalus"             = "Galaxias_anomalus",              # family used as genus; correct to Galaxias
    "Galaxiidae_new"                  = "Galaxias",                       # family + placeholder; reduce to genus Galaxias
    "Genus_microvelia"                = "Microvelia",                     # placeholder genus replaced with actual genus
    "Geotrupes_spec"                  = "Geotrupes",                      # spec placeholder stripped; genus valid
    "Gomphonema_type"                 = "Gomphonema",                     # type placeholder stripped; genus valid
    "Himasthla_b"                     = "Himasthla",                      # single-letter epithet stripped; genus valid
    "Hydrobiosis_type"                = "Hydrobiosis",                    # type placeholder stripped; caddisfly genus valid
    "Lagopus_spec"                    = "Lagopus",                        # spec placeholder stripped; genus valid
    "Lamellibranchia_e"               = "Lamellibranchia",                # single-letter epithet stripped; tubeworm genus valid
    "Larsia_i"                        = "Larsia",                         # single-letter epithet stripped; genus valid
    "Larus_spec"                      = "Larus",                          # spec placeholder stripped; genus valid
    "Lepidostoma_(genus_in_Opisthokonta)" = "Lepidostoma",                # parenthetical tag stripped; caddisfly genus valid
    "Leucocarbo_phal"                 = "Leucocarbo",                     # truncated epithet stripped; shag genus valid
    "Phalacrocorax_spec"              = "Phalacrocorax",                  # spec placeholder stripped; genus valid
    "Stercocarius_spec"               = "Stercorarius",                   # genus misspelling fixed; spec placeholder stripped
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
    "Dendrelaphis_caudolineolatus"    = "Dendrelaphis_caudolineatus",     # caudolineolatus not a recognized form
    "Desmognathus_ochrophaes"         = "Desmognathus_ochrophaeus",       # Dusky Salamander; missing u

    # H
    "Hydraena_homalaena"              = "Hydraena_homolaena",             # vowel substitution
    "Hypsiglena_unaocularus"          = "Hypsiglena_unaocularis",         # wrong 3rd-decl ending -us

    # I
    "Idotea_balthica"                 = "Idotea_baltica",                 # spurious h

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
    "Pycnonotus_jocusus"              = "Pycnonotus_jocosus",             # Red-whiskered Bulbul; vowel transposition
    "Python_curtis"                   = "Python_curtus",                  # Blood Python; i→u

    # R
    "Rhinolophus_yunanensis"          = "Rhinolophus_yunnanensis",        # Yunnan; missing n
    "Rousettus_egyptiacus"            = "Rousettus_aegyptiacus",          # from Aegyptus; missing ae

    # S
    "Sagitta_elegana"                 = "Sagitta_elegans",                # ns dropped
    "Scarus_iserti"                   = "Scarus_iseri",                   # Striped Parrotfish Bloch 1789; spurious t
    "Sceloporus_utiformis"            = "Sceloporus_uniformis",           # n dropped
    "Sebastes_paucipinis"             = "Sebastes_paucispinis",           # Bocaccio; missing s
    "Sebastes_paucispinus"            = "Sebastes_paucispinis",           # -us→-is termination error
    "Sebastes_ruberrinus"             = "Sebastes_ruberrimus",            # Yelloweye Rockfish; superlative -imus
    "Seiurus_novaeboracensis"         = "Seiurus_noveboracensis",         # Northern Waterthrush; spurious a
    "Sericornis_magnirostra"          = "Sericornis_magnirostris",        # 3rd-decl adjective requires -is
    "Sphenodon_punctatum"             = "Sphenodon_punctatus",            # Tuatara; accepted form is punctatus
    "Stegastes_variabillis"           = "Stegastes_variabilis",           # doubled-l typo
    "Strobilidium_iacustris"          = "Strobilidium_lacustris",         # Latin lacustris (of lakes); iacustris invalid

    # T
    "Tamiops_rodolphei"               = "Tamiops_rodolphii",              # standard double-i patronymic
    "Tenebrio_mollitor"               = "Tenebrio_molitor",               # Mealworm Beetle; single-l correct
    "Tetrahymena_pyraformis"          = "Tetrahymena_pyriformis",         # pear-shaped from pyrus; pyra- wrong
    "Thalassarche_melanophrys"        = "Thalassarche_melanophris",       # IOC/BirdLife accepted form
    "Thomasomys_ischyrus"             = "Thomasomys_ischyurus",           # Greek ischys + oura; missing u
    "Thunnus_alaunga"                 = "Thunnus_alalunga",               # Albacore; dropped l
    "Thunnus_macoyi"                  = "Thunnus_maccoyii",               # Southern Bluefin; missing c and i
    "Torgos_tracheliotus"             = "Torgos_tracheliotos",            # Lappet-faced Vulture; IOC form
    "Tortanus_discaudalus"            = "Tortanus_discaudatus",           # spurious -al- insertion
    "Trapelus_savignii"               = "Trapelus_savignyi",              # honors Savigny; patronymic form
    "Trogonophis_weigmanni"           = "Trogonophis_wiegmanni",          # honors Wiegmann; missing i
    "Turdoides_reinwardii"            = "Turdoides_reinwardtii",          # honors Reinwardt; t from surname retained

    # U
    "Uca_pugnas"                      = "Uca_pugnax",                     # pugnax is adjective; pugnas is verb form
    "Uraeginthus_bengalis"            = "Uraeginthus_bengalus",           # Red-cheeked Cordonbleu; accepted form
    "Urocissa_erythrorhyncha"         = "Urocissa_erythroryncha",         # Gould 1857 original; h insertion unofficial
    "Urocyon_cineroargenteus"         = "Urocyon_cinereoargenteus",       # Gray Fox; cinereo- needs connecting -o-
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
    "Crithida_fasciculata"            = "Crithidia_fasciculata",          # missing i; protozoan Crithidia not polychaete Crithida GBIF HIGHERRANK
    "Crithida_strigomonas"            = "Crithidia_strigomonas",          # missing i; same genus error as Crithida_fasciculata GBIF HIGHERRANK
    "Crystallodytes_cookie"           = "Crystallodytes_cookei",          # English word vs Latin patronymic; GBIF HIGHERRANK

    # D
    "Dephinapterus_leucas"            = "Delphinapterus_leucas",          # missing l; Beluga Whale GBIF NONE (correct EXACT 99)
    "Diomedia_exulans"                = "Diomedea_exulans",               # i→e substitution; Wandering Albatross GBIF FUZZY 85
    "Diomedea_melanophrys"            = "Diomedea_melanophris",           # phrys→phris; Black-browed Albatross GBIF FUZZY 92

    # E
    "Edaphus_blÃhweissi"         = "Edaphus_bluhweissi",             # UTF-8 encoding artifact U+00C3 replacing ü GBIF FUZZY 94
    "Enophrys_taurine"                = "Enophrys_taurina",               # English word; Latin -a required GBIF FUZZY 96

    # F
    "Felimida_purpureaÃÃ"   = "Felimida_purpurea",              # trailing 0xC3 0xC3 double-encoding artifact GBIF EXACT 99

    # G
    "Gabrius_fermoralis"              = "Gabrius_femoralis",              # vowel transposition; femoralis from femur GBIF EXACT 99
    "Gadhus_morhua"                   = "Gadus_morhua",                   # h inserted; Atlantic cod GBIF FUZZY 85
    "Gadus_minitus"                   = "Gadus_minutus",                  # u/i transposition; poor cod GBIF HIGHERRANK
    "Gammarus_insensiblis"            = "Gammarus_insensibilis",          # missing i in -ibilis; amphipod GBIF FUZZY 95
    "Garthia_gaudichaudi"             = "Garthia_gaudichaudii",           # single-i; Gaudichaud ends consonant GBIF FUZZY 96
    "Gerbilliscus_nigricauda"         = "Gerbilliscus_nigricaudus",       # also: Girbilliscus_nigricauda; ir/er + gender fix GBIF FUZZY 85
    "Girbilliscus_nigricauda"         = "Gerbilliscus_nigricaudus",       # ir→er genus transposition + wrong gender GBIF FUZZY 85
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
    "Trachytes_pauperiors"            = "Trachytes_pauperior",            # spurious -s; comparative pauperior is undeclined GBIF FUZZY 95
    "Tudus_viscivorus"                = "Turdus_viscivorus",              # missing r; Mistle Thrush GBIF NONE

    # U
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
    "Zonotricha_querula"              = "Zonotrichia_querula"             # missing i; Harris's Sparrow GBIF FUZZY 85
  )

  for (old in names(corrections)) {
    dat$taxon[dat$taxon == old] <- corrections[[old]]
  }

  return(dat)
}
