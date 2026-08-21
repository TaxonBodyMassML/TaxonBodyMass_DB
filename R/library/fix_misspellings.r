FixMisspellings <- function(dat) {

  # --- Genus prefix substitutions ---
  # Applied first so that subsequent specific corrections can reference the
  # corrected genus name (e.g. Holmesina_septentriolis rather than
  # Holmesi_septentriolis).

  genus_prefixes <- list(
    c("Aligator_",        "Alligator_"),        # Aligator -> Alligator
    c("Auriparis_",       "Auriparus_"),         # Auriparis_flaviceps
    c("Catjartes_",       "Cathartes_"),         # Catjartes_aura
    c("Chaoborys_",       "Chaoborus_"),         # Chaoborys_punctipennis
    c("Holmesi_",         "Holmesina_"),         # Holmesi__occidentalis etc. (after FixFormatting __ -> _)
    c("Lonchorhi_",       "Lonchorhina_"),       # Lonchorhi__aurita etc. (after FixFormatting)
    c("Mystaci_",         "Mystacina_"),         # Mystaci__robusta etc. (after FixFormatting)
    c("PseudoNitzschia_", "Pseudonitzschia_"),   # PseudoNitzschia_heimii etc.
    c("Strongylocentr_",  "Strongylocentrotus_") # Strongylocentr_droeb etc.
  )

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
    "Coleus_monedula"                 = "Coloeus_monedula",

    # Epithet misspellings (pre-existing)
    "Salmo_rutta"                     = "Salmo_trutta",
    "Daphnia_magma"                   = "Daphnia_magna",
    "Trachinocephalus_trachinus"      = "Trachinocephalus_myops",
    "Tursiops_truncates"              = "Tursiops_truncatus",

    # Duplicate pairs: merge less-accepted spelling to accepted form (pre-existing).
    "Accipiter_cooperi"               = "Accipiter_cooperii",
    "Eolophus_roseicapillus"          = "Eolophus_roseicapilla",
    "Hydrochoeris_hydrochaeris"       = "Hydrochoerus_hydrochaeris",
    "Lagopus_mutus"                   = "Lagopus_muta",
    "Madoqua_kirki"                   = "Madoqua_kirkii",

    # --- Near-duplicate misspellings identified by audit ---

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
    "Holocentrus_ascensionis"         = "Holocentrus_adscensionis"        # squirrelfish; original form with d
  )

  for (old in names(corrections)) {
    dat$taxon[dat$taxon == old] <- corrections[[old]]
  }

  return(dat)
}
