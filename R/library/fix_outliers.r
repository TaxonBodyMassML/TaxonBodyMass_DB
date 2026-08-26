FixOutliers <- function(dat) {

  # Single-source deletions only
  # Taxa with suspect values appearing in exactly one source.
  # Split into highly suspect (outlier_report.md)
  #  and suspicious (outlier_report_2.md) tiers.

  ##########################################################################
  # 1. Highly suspect values (see "outlier_report.md")
  ##########################################################################

  # --- Brose_etal_2018 ---
  # 1.506e-04 g → 0.04 g; sergestid shrimp 10-44 mm; 0.00015 g ~265x too
  #   small
  dat <- RemoveRecord(dat, "Acetes_americanus", "Brose_etal_2018")
  # 8 g → 2.000e-04 g; Cecidomyiidae adult <1 mg; 8 g ~4 log10 units too
  #   large
  dat <- RemoveRecord(dat, "Anocha_lyolepis", "Brose_etal_2018")
  # 0.006245 g → 2 g; wasp spider females 14-25 mm; 6.25 mg ~300x too small
  dat <- RemoveRecord(dat, "Argiope_bruennichi", "Brose_etal_2018")
  # 6.828 g → 0.35 g; Pieridae adult ~0.1-0.8 g; 6.83 g ~1.3 log10 too high
  dat <- RemoveRecord(dat, "Ascia_monuste", "Brose_etal_2018")
  # 5,800 g → 50 g; nemertean; world max 140 g; 5.8 kg too large
  dat <- RemoveRecord(dat, "Baseodiscus_antarcticus", "Brose_etal_2018")
  # 4.010e-05 g → 5.000e-04 g; small Aoridae amphipod 3-6 mm; 0.0000401 g ~1
  #   log10 too small
  dat <- RemoveRecord(dat, "Cheirocratus_sundevalli", "Brose_etal_2018")
  # 4.830e-07 g → 3.000e-07 g; cheyletid mite ~0.4 mm; 0.483 ng impossible;
  #   ~0.1-1 µg expected
  dat <- RemoveRecord(dat, "Cheyletia_wellsi", "Brose_etal_2018")
  # 1.719e-04 g → 0.05 g; nudibranch 8-24 mm; 0.172 mg ~2-3 log10 too small
  dat <- RemoveRecord(dat, "Cratena_pilata", "Brose_etal_2018")
  # 0.01 g → 80 g; Indo-Pacific xanthid crab; medium-large; 0.01 g too small
  dat <- RemoveRecord(dat, "Eriphia_smithii", "Brose_etal_2018")
  # 0.03073 g → 3 g; shell 17-44 mm; expected ~1-8 g; 30.7 mg too small;
  dat <- RemoveRecord(dat, "Fissurella_clenchi", "Brose_etal_2018")
  # 0.001356 g → 2.5 g; shell 17-40 mm; expected ~1-5 g; 1.36 mg too small;
  dat <- RemoveRecord(dat, "Fissurella_rosea", "Brose_etal_2018")
  # 3.819e-04 g → 0.35 g; pill millipede 10-20 mm; 0.38 mg impossible;
  #   200-600 mg expected
  dat <- RemoveRecord(dat, "Glomeris_connexa", "Brose_etal_2018")
  # 0.0773 g → 0.002 g; chironomid adult; typical 0.2-5 mg; 77.3 mg ~1.6
  #   log10 too high
  dat <- RemoveRecord(dat, "Glyptotendipes_pallens", "Brose_etal_2018")
  # 6.300e-07 g → 0.05 g; sipunculan worm; 0.63 µg below single-cell mass;
  #   impossible
  dat <- RemoveRecord(dat, "Golfingia_nordenskojoeldi", "Brose_etal_2018")
  # 0.01 g → 150 g; littoral rock crab CW up to 8.7 cm; 0.01 g ~4 log10 too
  #   small
  dat <- RemoveRecord(dat, "Grapsus_adscensionis", "Brose_etal_2018")
  # 9.390e-05 g → 0.01 g; small caridean shrimp 10-20 mm; 0.0000939 g ~100x
  #   too small
  dat <- RemoveRecord(dat, "Hippolyte_pleuracantha", "Brose_etal_2018")
  # 1.378e-04 g → 0.003 g; liljeborgiid amphipod 5-10 mm; 0.138 µg ~10-100x
  #   too small
  dat <- RemoveRecord(dat, "Liljeborgia_kinahani", "Brose_etal_2018")
  # 5,800 g → 10 g; subantarctic nemertean; max nemertean ~140 g; 5.8 kg too
  #   large
  dat <- RemoveRecord(dat, "Lineus_longifissus", "Brose_etal_2018")
  # 2.000e-04 g → 0.5 g; intertidal nemertean 7.5-23 cm; 0.0002 g (~0.2 mg)
  #   too small
  dat <- RemoveRecord(dat, "Lineus_ruber", "Brose_etal_2018")
  # 0.0507 g → 8 g; portunid crab CW up to 30 mm; 0.051 g ~2 log10 too small
  dat <- RemoveRecord(dat, "Liocarcinus_arcuatus", "Brose_etal_2018")
  # 0.108 g → 40 g; portunid crab CW up to 60 mm; 0.108 g ~2-3 log10 too
  #   small
  dat <- RemoveRecord(dat, "Liocarcinus_corrugatus", "Brose_etal_2018")
  # 1.719e-04 g → 1 g; peppermint shrimp 5-7 cm; 0.000172 g ~3000-10000x too
  #   small
  dat <- RemoveRecord(dat, "Lysmata_wurdemanni", "Brose_etal_2018")
  # 2.573e-04 g → 0.015 g; orb-weaver 5-8 mm; 0.257 mg impossible; 5-40 mg
  #   expected
  dat <- RemoveRecord(dat, "Mangora_acalypha", "Brose_etal_2018")
  # 0.01 g → 80 g; Argentine silverside max 42 cm; 0.01 g ~3.9 log10 too
  #   small
  dat <- RemoveRecord(dat, "Odontesthes_argentinensis", "Brose_etal_2018")
  # 0.01233 g → 2.000e-06 g; Oithonidae copepod typical dry mass 1-3 µg;
  #   12.33 mg ~3 log10 too large
  dat <- RemoveRecord(dat, "Oithona_colcarva", "Brose_etal_2018")
  # 0.01233 g → 2.000e-06 g; O. similis senior synonym; adults <1 mm; 12.33
  #   mg ~3 log10 too large
  dat <- RemoveRecord(dat, "Oithona_helgolandica", "Brose_etal_2018")
  # — → 1.000e-05 g; Oncaeidae copepod; renamed from Onacea_borealis in
  #   fix_misspellings.r
  dat <- RemoveRecord(dat, "Triconia_borealis", "Brose_etal_2018")
  # 3.770e-09 g → 2.000e-06 g; tropical fowl mite; 3.77 ng impossible;
  #   ~0.7-1 µg expected
  dat <- RemoveRecord(dat, "Ornitnonyssus_bursa", "Brose_etal_2018")
  # 5,800 g → 100 g; world's heaviest nemertean; max 140 g; 5.8 kg too large
  dat <- RemoveRecord(dat, "Parborlasia_corrugatus", "Brose_etal_2018")
  # 0.01 g → 50 g; large solitary ascidian 5-15 cm; 0.01 g ~4 log10 too
  #   small
  dat <- RemoveRecord(dat, "Phallusia_nigra", "Brose_etal_2018")
  # 5.537 g → 0.5 g; large Orange Sulphur butterfly; typical Pierid 0.3-0.8
  #   g; 5.54 g ~1 log10 too high
  dat <- RemoveRecord(dat, "Phoebis_agarithe", "Brose_etal_2018")
  # 0.1528 g → 50 g; cushion star max radius 70 mm; 0.153 g ~2.5 log10 too
  #   small
  dat <- RemoveRecord(dat, "Porania_antarctica", "Brose_etal_2018")
  # 0.01 g → 150 g; ornate wrasse max 25 cm; 0.01 g ~4 log10 too small
  dat <- RemoveRecord(dat, "Thalassoma_pavo", "Brose_etal_2018")
  # 0.02644 g → 20 g; furrowed crab CW up to 60 mm; 0.026 g ~3 log10 too
  #   small
  dat <- RemoveRecord(dat, "Xantho_incisus", "Brose_etal_2018")
  # 0.01 g → 8 g; small xanthid crab 2-4 cm CW; 0.01 g ~3 log10 too small
  dat <- RemoveRecord(dat, "Xantho_pilipes", "Brose_etal_2018")
  # 3.094e-05 g; Plecoptera Austroperlidae adult stonefly; adults ≥1 mg
  #   (model predicts ~1.2 mg); 0.031 mg ~650x too small; likely early instar
  #   larva; |log10 diff| = 2.81
  dat <- RemoveRecord(dat, "Austroperla_cyrene", "Brose_etal_2018")
  # 0.1472 g; Chironomidae adult midge 2-10 mm; adult 0.2-5 mg, larvae 2-20
  #   mg; 147.2 mg exceeds all life stages; probable unit error or wrong
  #   species/stage; abs_residual 1.887
  dat <- RemoveRecord(dat, "Chironomus_dorsalis", "Brose_etal_2018")
  # 0.01183 g; spirorbid polychaete (Serpulidae) in coiled tube ~1-2 mm;
  #   expected <0.2 mg; 11.83 mg ~60-100x too high; likely mg→g unit error
  dat <- RemoveRecord(dat, "Circeis_armoricana", "Brose_etal_2018")
  # 1.026e-04 g; Empididae dance fly 3-7 mm body; expected 0.5-5 mg; 0.103
  #   mg ~10x too small; possible dry mass or very small female; abs_residual
  #   1.608
  dat <- RemoveRecord(dat, "Clinocera_stagnalis", "Brose_etal_2018")
  # 0.0086 g; tiny Orthocladiinae chironomid 0.5-1.5 mm; expected 1-50 µg;
  #   8.6 mg ~2.93 log10 too high; probable species confusion or decimal error;
  #   abs_residual 1.857
  dat <- RemoveRecord(dat, "Corynoneura_scutellata", "Brose_etal_2018")
  # 6.63e-05 g; Trichoptera Hydrobiosidae adult caddisfly; smallest
  #   Trichoptera >0.5 mg; 0.066 mg too small; |log10 diff| = 1.48; dataset also
  #   has wrong family (Philopotamidae in dataset, should be Hydrobiosidae)
  dat <- RemoveRecord(dat, "Hydrobiosella_stenocera", "Brose_etal_2018")
  # 0.7813 g; emerald damselfly (Odonata) 35-38 mm; typical adult 30-120 mg;
  #   781.3 mg ~1.05 log10 above typical 70 mg; probable mg/g unit confusion or
  #   wrong life stage
  dat <- RemoveRecord(dat, "Lestes_sponsa", "Brose_etal_2018")
  # 0.8076 g; Limnephilidae caddisfly 10-18 mm; typical adult 15-120 mg;
  #   807.6 mg ~1.2 log10 above typical 50 mg; probable mg→g unit error or
  #   larval case mass included
  dat <- RemoveRecord(dat, "Limnephilus_marmoratus", "Brose_etal_2018")
  # 2.91 g; piure tunicate (Urochordata) 10-15 cm; typical wet mass 100-1500
  #   g; 2.91 g ~2.1 log10 too small; possible juvenile fragment or mg/g unit
  #   error
  dat <- RemoveRecord(dat, "Pyura_chilensis", "Brose_etal_2018")
  # 0.01538 g; large Arctic crangonid shrimp TL 100-120 mm; typical 3-30 g;
  #   |log10 diff| = 2.89; 15.4 mg vs congeneric S. ferox = 13 g; likely decimal
  #   shift or unit error
  dat <- RemoveRecord(dat, "Sclerocrangon_boreas", "Brose_etal_2018")
  # 4 g; water boatman (Corixidae) 5-10 mm; typical adult 2-15 mg; 4 g ~2.75
  #   log10 too high; mg entered as g; probable true mass ~4-10 mg
  dat <- RemoveRecord(dat, "Sigara_lateralis", "Brose_etal_2018")
  # 9.213e-05 g; Gripopterygidae adult stonefly (NZ); any adult stonefly ≥1
  #   mg; 0.092 mg too small
  dat <- RemoveRecord(dat, "Stenoperla_prasina", "Brose_etal_2018")

  # --- Brown_etal_2018 ---
  # 18,250 g → 130 g; Dall's pika; all Ochotona 70-300 g; 18.25 kg ~2 log10
  #   too large
  dat <- RemoveRecord(dat, "Ochotona_dalli", "Brown_etal_2018")

  # --- Cai_etal_2025 ---
  # 185.6 g → 15 g; medium hylid; 5-35 g typical; 185.6 g ~5-10x too high
  dat <- RemoveRecord(dat, "Bokermannohyla_alvarengai", "Cai_etal_2025")
  # 1.3 g → 150 g; Gila chub reaching 25+ cm; 1.3 g ~2 log10 too small
  dat <- RemoveRecord(dat, "Gila_conspersa", "Cai_etal_2025")
  # 1 g → 30 g; Taiwan big-head chub max 16 cm; 1 g ~1.5 log10 too small
  dat <- RemoveRecord(dat, "Opsariichthys_pachycephalus", "Cai_etal_2025")
  # 143.4 g → 25 g; Algerian ribbed newt; congener P. waltl 15-40 g; 143 g
  #   ~4-5x too high
  dat <- RemoveRecord(dat, "Pleurodeles_poireti", "Cai_etal_2025")
  # 3,663 g → 3 g; max TL only 5.8 cm; 3663 g physically impossible
  dat <- RemoveRecord(dat, "Rhinogobius_brunneus", "Cai_etal_2025")

  # --- Davidson_1987 ---
  # 7,419 g → 400 g; NZ paddle crab; literature max ~700 g; 7419 g ~1.3
  #   log10 too large
  dat <- RemoveRecord(dat, "Ovalipes_catharus", "Davidson_1987")

  # --- DeLong_etal_2010 ---
  # 71.4 g → 2.000e-04 g; chydorid 50-500 µg DW; 71.4 g = 71.4 µg stored as
  #   g
  dat <- RemoveRecord(dat, "Eurycercus_longirostris", "DeLong_etal_2010")
  # 70 g → 2.000e-04 g; same family/size as E. longirostris; 70 g = 70 µg
  #   stored as g
  dat <- RemoveRecord(dat, "Eurycercus_vernalis", "DeLong_etal_2010")
  # 22.7 g → 5.000e-06 g; small chydorid ~0.5-1 mm; 22.7 g = 22.7 µg stored
  #   as g
  dat <- RemoveRecord(dat, "Pleuroxus_denticulatis", "DeLong_etal_2010")

  # --- DeLong_etal_2018 ---
  # 5.327e-07 g → 2.000e-05 g; silverleaf whitefly ~0.9 mm; 0.53 µg ~1.6
  #   log10 too small
  dat <- RemoveRecord(dat, "Bemisia_tabaci", "DeLong_etal_2018")
  # 4.310e-05 g → 0.5 g; monarch butterfly; adult 270-750 mg; 0.043 mg ~3.85
  #   log10 too small
  dat <- RemoveRecord(dat, "Danaus_plexippus", "DeLong_etal_2018")
  # 2.572e-04 g → 0.01 g; carob moth wingspan 22-30 mm; 0.26 mg ~1.6 log10
  #   too small
  dat <- RemoveRecord(dat, "Ectomyelois_ceratoniae", "DeLong_etal_2018")
  # 1.160e-06 g → 0.007 g; Mediterranean flour moth; adult 3-15 mg; 1.16 µg
  #   ~3.8 log10 too small
  dat <- RemoveRecord(dat, "Ephestia_kuehniella", "DeLong_etal_2018")
  # 0.00541 g → 5.000e-05 g; cyclopoid copepod DW 5-100 µg; 5.41 mg
  #   ~54-1000x too large
  dat <- RemoveRecord(dat, "Eucyclops_subterraneus", "DeLong_etal_2018")
  # 0.135 g → 15 g; wrasse max 13 cm; LWR yields ~26 g; 0.135 g ~200x too
  #   small
  dat <- RemoveRecord(dat, "Halichoeres_pictus", "DeLong_etal_2018")
  # 1.120e-05 g → 0.1 g; cotton bollworm adult 50-300 mg; 11.2 µg ~3.95
  #   log10 too small
  dat <- RemoveRecord(dat, "Helicoverpa_armigera", "DeLong_etal_2018")
  # 2.680e-06 g → 0.15 g; corn earworm adult 80-300 mg; 2.68 µg ~4.75 log10
  #   too small
  dat <- RemoveRecord(dat, "Helicoverpa_zea", "DeLong_etal_2018")
  # 2.378e-05 g → 0.08 g; tobacco budworm adult 40-150 mg; 23.78 µg ~3.5
  #   log10 too small
  dat <- RemoveRecord(dat, "Heliothis_virescens", "DeLong_etal_2018")
  # 6.630e-05 g → 0.005 g; hyperiid amphipod 10-20 mm; 0.066 mg ~2 log10 too
  #   small
  dat <- RemoveRecord(dat, "Hyperoche_medusarum", "DeLong_etal_2018")
  # 0.03628 g → 3,000 g; blue king crab max published 4500 g; 0.036 g
  #   ~60000x too small
  dat <- RemoveRecord(dat, "Paralithodes_platypus", "DeLong_etal_2018")
  # 0.154 g → 700 g; kelp rockfish max 42 cm; IGFA record 910 g; 0.154 g
  #   ~3.7 log10 too small
  dat <- RemoveRecord(dat, "Sebastes_atrovirens", "DeLong_etal_2018")
  # 1.641e-05 g → 0.003 g; Angoumois grain moth adult 1-5 mg; 16.4 µg ~3.8
  #   log10 too small
  dat <- RemoveRecord(dat, "Sitotroga_cerealella", "DeLong_etal_2018")
  # 4.050e-07 g → 5.000e-04 g; tomato leaf miner wingspan 7-8 mm; 0.405 µg
  #   ~3 log10 too small
  dat <- RemoveRecord(dat, "Tuta_absoluta", "DeLong_etal_2018")

  # --- DosSantos_2022 ---
  # 0.53 g → 10 g; medium hylid; adults 3-30 g; 0.53 g too small
  dat <- RemoveRecord(dat, "Pseudis_limellum", "DosSantos_2022")

  # --- Faurby_etal_2018 ---
  # 404.3 g → 250,000 g; PHYLACINE flags 404 g as erroneous; extinct
  #   megacerine ~250 kg
  dat <- RemoveRecord(dat, "Sinomegaceros_ordosianus", "Faurby_etal_2018")
  # 540 g; dusky elephant shrew (Macroscelididae) typical adult 25-75 g; 540
  #   g ~10x too high; log10 diff = 1.03; likely 54 g with extra zero (data
  #   entry error)
  dat <- RemoveRecord(dat, "Elephantulus_fuscus", "Faurby_etal_2018")

  # --- Feldman_etal_2016 ---
  # 44,780 g → 50 g; small Yapen Island homalopsid; only 4 known specimens;
  #   44780 g impossible
  dat <- RemoveRecord(dat, "Calamophis_jobiensis", "Feldman_etal_2016")
  # 1.2 g → 150 g; Tay Ninh mud snake; congener E. jagorii 65-390 g; 1.2 g
  #   too small
  dat <- RemoveRecord(dat, "Enhydris_innominata", "Feldman_etal_2016")
  # 0.5 g → 80 g; New Guinea keelback; sister T. novaeguineae ~82 cm; 0.5 g
  #   too small
  dat <- RemoveRecord(dat, "Tropidonophis_dolasii", "Feldman_etal_2016")

  # --- fishbase ---
  # 108 g → 100,000 g; bignose shark 282 cm ~168 kg; 108 g ~3 log10 too
  #   small
  dat <- RemoveRecord(dat, "Carcharhinus_altimus", "fishbase")
  # 30,400 g → 15 g; glass headstander; FishBase max 30.4 g; 30400 g = 1000x
  #   kg→g error
  dat <- RemoveRecord(dat, "Charax_gibbosus", "fishbase")
  # 73,000 g → 150 g; W African lefteye flounder max ~30 cm; 73 kg ~2.7
  #   log10 too large
  dat <- RemoveRecord(dat, "Citharichthys_stampflii", "fishbase")
  # 468,000 g → 200 g; sole; largest soles <2 kg; 468 kg impossible
  dat <- RemoveRecord(dat, "Dagetichthys_lusitanica", "fishbase")
  # 45 g → 3,000 g; Australian thornback skate; adult expected several kg;
  #   45 g too small
  dat <- RemoveRecord(dat, "Dentiraja_australis", "fishbase")
  # 45 g → 3,000 g; eastern shovelnose skate; adult expected several kg; 45
  #   g too small
  dat <- RemoveRecord(dat, "Dipturus_australis", "fishbase")
  # 110 g → 7,000 g; large S American/S Ocean skate ~100 cm TL; 110 g too
  #   small
  dat <- RemoveRecord(dat, "Dipturus_trachyderma", "fishbase")
  # 20 g → 6,000 g; Dakar stingray disc up to ~100 cm; 20 g ~2.5 log10 too
  #   small
  dat <- RemoveRecord(dat, "Fontitrygon_margarita", "fishbase")
  # 63,000 g → 30 g; FishBase max weight 63.6 g; 63000 g = 63 kg ~990x too
  #   large
  dat <- RemoveRecord(dat, "Lycodes_rossi", "fishbase")
  # 65 g → 8,000 g; bullnose ray wingspan ~100 cm; adult 4-10 kg; 65 g ~2
  #   log10 too small
  dat <- RemoveRecord(dat, "Myliobatis_freminvillei", "fishbase")
  # 0.0114 g → 15 g; lanternfish max 21 cm; adults ~3-60 g; 0.0114 g too
  #   small
  dat <- RemoveRecord(dat, "Nannobrachium_regale", "fishbase")
  # 6.5 g; bay whiff flatfish max 36.8 cm TL (FishBase max weight 597 g);
  #   typical adult 100-300 g; |log10 diff| = 1.49; 6.5 g corresponds to ~10 cm
  #   juvenile
  dat <- RemoveRecord(dat, "Citharichthys_spilopterus", "fishbase")
  # 76 g; bramble shark max ~310 cm TL; adult 20-200 kg; |log10 diff| =
  #   2.82; even neonates >200 g; likely 76 kg misrecorded as 76 g
  dat <- RemoveRecord(dat, "Echinorhinus_brucus", "fishbase")
  # 14700 g; Schmidt's codling max TL ~43 cm; gadiform LWR yields ~300-600
  #   g; 14.7 kg ~1.69 log10 too high; single FishBase source (n=1); factor-10
  #   to 100 data entry error
  dat <- RemoveRecord(dat, "Lepidion_schmidti", "fishbase")

  # --- Gillooly_etal_2016 ---
  # 21 g → 2,000 g; synonym of P. lineatus; FishBase max 7.2 kg; 21 g =
  #   juvenile
  dat <- RemoveRecord(dat, "Prochilodus_scrofa", "Gillooly_etal_2016")

  # --- Hirt_etal_2017 ---
  # 19,540 g → 500 g; Carassius_leucas: class listed as Magnoliopsida
  #   (wrong; should be Actinopterygii) — class unfixable in pipeline;
  #   freshwater fish ~19.5 kg in dataset; typical Carassius adult ~500 g
  dat <- RemoveRecord(dat, "Carassius_leucas", "Hirt_etal_2017")

  # --- Killen_etal_2016 ---
  # 6.19 g → 20,000 g; bighead carp typical 2-40 kg; 6.19 g ~3200x too small
  dat <- RemoveRecord(dat, "Aristichthys_nobilis", "Killen_etal_2016")

  # --- Makarieva_2008 ---
  # 1.965 g → 0.01 g; Cicadellidae leafhopper; adult ~10 mg; 1.97 g ~2 log10
  #   too large
  dat <- RemoveRecord(dat, "Brasilanus_batus", "Makarieva_2008")
  # 0.117 g → 120 g; black-eyed squid; adults reach 12-18 cm ML; 0.117 g too
  #   small
  dat <- RemoveRecord(dat, "Gonatus_onyx", "Makarieva_2008")
  # 0.672 g → 0.04 g; Limoniidae crane fly; typical adult 5-100 mg; 672 mg
  #   ~1.2 log10 too high
  dat <- RemoveRecord(dat, "Helius_waiti", "Makarieva_2008")
  # 0.07 g → 800 g; pilotfish max 70 cm; adults ~200-3000 g; 0.07 g ~4 log10
  #   too small
  dat <- RemoveRecord(dat, "Naucrates_ductor", "Makarieva_2008")
  # 0.096 g → 125 g; East Pacific red octopus; typical 100-150 g; 0.096 g ~3
  #   log10 too small
  dat <- RemoveRecord(dat, "Octopus_rubescens", "Makarieva_2008")
  # 0.294 g → 15 g; skittering frog (Euphlyctis cyanophlyctis); typical 5-40
  #   g; 0.294 g too small
  dat <- RemoveRecord(dat, "Rana_cyanophlyctis", "Makarieva_2008")
  # 0.66 g; green toad (Anaxyrus debilis) typical adult 4-20 g; 0.66 g ~1
  #   log10 too small
  dat <- RemoveRecord(dat, "Bufo_debilus", "Makarieva_2008")

  # --- Oliveira_2017 ---
  # 24 g → 4 g; Johnstone's whistling frog; adults 2-8 g; 24 g ~5x too high
  dat <- RemoveRecord(dat, "Eleutherodactylus_johnstonei", "AmphiBIO")

  # --- Pappantoniou_1984 ---
  # 0.75 g → 40 g; cutlips minnow max ~20 cm; adult 20-100 g; 0.75 g too
  #   small
  dat <- RemoveRecord(dat, "Exoglossum_maxillingua", "Pappantoniou_1984")

  # --- Pauly_2024 ---
  # 0.4 g → 6 g; crescent gunnel max 13 cm; expected 2-20 g; 0.4 g too small
  dat <- RemoveRecord(dat, "Pholis_clemensi", "Pauly_2024")
  # 1.1 g → 100 g; leopard searobin max 25 cm; adults ~20-400 g; 1.1 g too
  #   small
  dat <- RemoveRecord(dat, "Prionotus_scitulus", "Pauly_2024")
  # 1.6 g → 200 g; Easter Island scorpionfish; Scorpaena typically 50-500+
  #   g; 1.6 g too small
  dat <- RemoveRecord(dat, "Scorpaena_pascuensis", "Pauly_2024")
  # 0.7 g → 80 g; sauro lizardfish max 27 cm; congeners up to 900 g; 0.7 g
  #   too small
  dat <- RemoveRecord(dat, "Synodus_lacertinus", "Pauly_2024")
  # 1.5 g; longfin sculpin max TL 15 cm; Bayesian LWR gives 18.2 g at max;
  #   1.5 g ~6.7 cm juvenile; 1.08 log10 below expected; food-web model likely
  #   used juvenile mean
  dat <- RemoveRecord(dat, "Jordania_zonope", "Pauly_2024")

  # --- Quaardvark ---
  # 25 g → 0.35 g; western black widow; known mass 0.18-0.87 g; 25 g
  #   impossible
  dat <- RemoveRecord(dat, "Latrodectus_hesperus", "Quaardvark")
  # 17.5 g; starlet sea anemone (model organism) 10-35 mm body; typical wet
  #   mass 1-30 mg; 17.5 g ~3.5 log10 too high; Quaardvark non-standard
  #   aggregator; data entry error or unit confusion
  dat <- RemoveRecord(dat, "Nematostella_vectensis", "Quaardvark")

  # --- sealifebase ---
  # 3.175 g → 1,500 g; Sepia pharaonis synonym; max 5 kg; typical 500-5000
  #   g; 3.175 g too small
  dat <- RemoveRecord(dat, "Acanthosepion_pharaonis", "sealifebase")
  # 166,000 g → 0.005 g; pterobranche colonial zooids 0.5-3 mm; 166 kg
  #   impossible
  dat <- RemoveRecord(dat, "Cephalodiscus_gilchristi", "sealifebase")

  # --- Viana_2016 ---
  # 81.9 g → 2,640 g; bar jack; FishBase max 8.2 kg at 73 cm; 81.9 g ~1.5
  #   log10 too small
  dat <- RemoveRecord(dat, "Caranx_ruber", "Viana_2016")
  # 1.5 g → 500 g; lane snapper; FishBase max 3.5 kg; 1.5 g ~3 log10 too
  #   small
  dat <- RemoveRecord(dat, "Lutjanus_synagris", "Viana_2016")

  # --- Wilman_etal_2014 ---
  # 11.77 g → 54 g; blue-rumped parrot; documented 40-60 g; 11.77 g ~4x too
  #   light
  dat <- RemoveRecord(dat, "Psittinus_cyanurus", "Wilman_etal_2014")


  ##########################################################################
  # 2. Suspicious values (see "outlier_report_2.md")
  ##########################################################################

  # --- AmphiBIO ---
  # 80 g → 20 g; large Craugastor rarely >50 g; 80 g ~2x too high
  dat <- RemoveRecord(dat, "Craugastor_laticeps", "AmphiBIO")
  # 75 g → 15 g; typical adult 5-40 g; 75 g implausibly high
  dat <- RemoveRecord(dat, "Craugastor_rugulosus", "AmphiBIO")
  # 0.18 g → 1.5 g; smallest Eleutherodactylus >0.5 g; 0.18 g too low
  dat <- RemoveRecord(dat, "Eleutherodactylus_cubanus", "AmphiBIO")
  # 95 g → 25 g; Boana faber adults 10-50 g; 95 g ~2x too high
  dat <- RemoveRecord(dat, "Hypsiboas_faber", "AmphiBIO")
  # 93 g → 25 g; Boana rosenbergi adults 10-50 g; 93 g ~2x too high
  dat <- RemoveRecord(dat, "Hypsiboas_rosenbergi", "AmphiBIO")
  # 19 g → 3 g; 'parva' (small); genus 1-8 g; 19 g ~5x too high
  dat <- RemoveRecord(dat, "Ischnocnema_parva", "AmphiBIO")
  # 561 g → 180 g; largest congener max ~250 g; 561 g too high
  dat <- RemoveRecord(dat, "Leptodactylus_labyrinthicus", "AmphiBIO")
  # 1,000 g → 100 g; largest congener ~250 g; 1000 g ~4-5x too high
  dat <- RemoveRecord(dat, "Leptodactylus_vastus", "AmphiBIO")

  # --- Brose_etal_2018 ---
  # 0.004046 g → 0.1 g; snapping shrimp 20-25 mm TL; 4 mg ~25x too small
  dat <- RemoveRecord(dat, "Alpheus_normanni", "Brose_etal_2018")
  # 0.01 g → 4 g; Antarctic naticid shell 29 mm; 10 mg ~400x too small
  dat <- RemoveRecord(dat, "Amauropsis_rossiana", "Brose_etal_2018")
  # 0.81 g → 0.02 g; tube-building amphipod 7-12 mm; 810 mg too large
  dat <- RemoveRecord(dat, "Ampelisca_richardsoni", "Brose_etal_2018")
  # 0.005048 g → 1 g; large scavenging amphipod 30-55 mm; 5 mg ~200x too
  #   small
  dat <- RemoveRecord(dat, "Anonyx_nugax", "Brose_etal_2018")
  # 0.007402 g → 0.15 g; scavenging amphipod 20-40 mm; 7.4 mg ~20x too small
  dat <- RemoveRecord(dat, "Anonyx_sarsi", "Brose_etal_2018")
  # 0.9319 g → 80 g; Forbes sea star arm 7-12 cm; 0.93 g ~100x too small
  dat <- RemoveRecord(dat, "Asterias_forbesi", "Brose_etal_2018")
  # 0.04064 g → 1 g; Arctic muricid snail shell ~15 mm; 41 mg too small
  dat <- RemoveRecord(dat, "Boreotrophon_truncatus", "Brose_etal_2018")
  # 0.03662 g → 2 g; striped hermit crab shield 10-25 mm; 37 mg too small
  dat <- RemoveRecord(dat, "Clibanarius_vittatus", "Brose_etal_2018")
  # 0.01735 g → 0.001 g; now Apocorophium acutum; mud amphipod 5-10 mm; 17
  #   mg too large
  dat <- RemoveRecord(dat, "Corophium_acutum", "Brose_etal_2018")
  # — → 0.001 g; corrected name; same value as above
  dat <- RemoveRecord(dat, "Apocorophium_acutum", "Brose_etal_2018")
  # 57 g → 2 g; polynoid scale worm <10 cm; 57 g far too large
  dat <- RemoveRecord(dat, "Eunoe_hartmanae", "Brose_etal_2018")
  # 0.001707 g → 0.05 g; mesopelagic krill 12-22 mm; 1.7-4 mg too small
  #   (covers merged krohni too)
  dat <- RemoveRecord(dat, "Euphausia_krohnii", "Castro_2025")
  # 0.001177 g → 0.1 g; estuarine amphipod 15-25 mm; 1.18 mg too small
  dat <- RemoveRecord(dat, "Gammarus_daiberi", "Brose_etal_2018")
  # 0.001177 g → 0.05 g; freshwater scud 10-23 mm; 1.18 mg too small
  dat <- RemoveRecord(dat, "Gammarus_fasciatus", "Brose_etal_2018")
  # 0.001177 g → 0.02 g; small estuarine amphipod 5-12 mm; 1.18 mg too small
  dat <- RemoveRecord(dat, "Gammarus_mucronatus", "Brose_etal_2018")
  # 0.001177 g → 0.03 g; invasive amphipod 8-15 mm; 1.18 mg too small
  dat <- RemoveRecord(dat, "Gammarus_tigrinus", "Brose_etal_2018")
  # 0.225 g → 30 g; toad crab CL up to 65 mm; 225 mg too small
  dat <- RemoveRecord(dat, "Hyas_coarctatus", "Brose_etal_2018")
  # 0.01563 g → 0.15 g; small chiton 10-30 mm; 15.6 mg AFDW too small
  dat <- RemoveRecord(dat, "Ischnochiton_striolatus", "Brose_etal_2018")
  # 0.0418 g → 2.000e-04 g; Pontellidae copepod; 41.8 mg ~200x too large
  dat <- RemoveRecord(dat, "Labidocera_jollae", "Makarieva_2008")
  # 0.59 g → 0.005 g; liljeborgiid amphipod 5-12 mm; 590 mg too large
  dat <- RemoveRecord(dat, "Liljeborgia_georgiana", "Brose_etal_2018")
  # 0.319 g → 15 g; xanthid crab CW 3-6 cm; 319 mg too small
  dat <- RemoveRecord(dat, "Lophozozymus_incisus", "Brose_etal_2018")
  # 0.3675 g → 500 g; large NE Atlantic sea star arm 40 cm; 367 mg too small
  dat <- RemoveRecord(dat, "Marthasterias_glacialis", "Brose_etal_2018")
  # 100 g → 5 g; small cushion star max 6 cm; 100 g ~20x too large
  dat <- RemoveRecord(dat, "Meridiastra_gunnii", "Brose_etal_2018")
  # 0.184 g → 10 g; penaeid shrimp; typical 5-30 g; 184 mg too small
  dat <- RemoveRecord(dat, "Metapenaeus_pruinosus", "Makarieva_2008")
  # 0.001177 g → 0.1 g; now Astyris lunata (Columbellidae) shell 7-12 mm;
  #   1.18 mg too small
  dat <- RemoveRecord(dat, "Mitrella_lunata", "Brose_etal_2018")
  # — → 0.1 g; corrected name; same value
  dat <- RemoveRecord(dat, "Astyris_lunata", "Brose_etal_2018")
  # 0.01 g → 1 g; coral reef muricid shell 15-30 mm; 10 mg too small
  dat <- RemoveRecord(dat, "Morula_uva", "Brose_etal_2018")
  # 0.04447 g → 5 g; sting winkle shell 25-60 mm; 44.5 mg too small
  dat <- RemoveRecord(dat, "Ocenebra_erinaceus", "Brose_etal_2018")
  # 0.01 g → 15 g; large brittle star disc 25 mm arms 12 cm; 10 mg too small
  dat <- RemoveRecord(dat, "Ophiocomina_nigra", "Brose_etal_2018")
  # 0.77627 g → 5 g; brittle star disc 10 mm arms 50 mm; 776 mg AFDW too
  #   small
  dat <- RemoveRecord(dat, "Ophiothrix_fragilis", "Brose_etal_2018")
  # 1.401 g → 30 g; jellyfish bell 3-12 cm; 1.4 g DW too small
  dat <- RemoveRecord(dat, "Pelagia_noctiluca", "DeLong_etal_2018")
  # 6.300e-07 g → 0.01 g; sipunculan worm 5-30 mm; 0.63 µg sub-cellular
  dat <- RemoveRecord(dat, "Phascolion_strombi", "Brose_etal_2018")
  # 0.1018 g → 1 g; shore crab CW 15-25 mm; 102 mg too small
  dat <- RemoveRecord(dat, "Pirimela_denticulata", "Brose_etal_2018")
  # 15 g → 0.05 g; Antarctic scale worm ~2-3 cm; 15 g too large
  dat <- RemoveRecord(dat, "Polyeunoa_laevis", "Brose_etal_2018")
  # 5.498 g → 5,000 g; large jellyfish bell 30-45 cm; 5.5 g too small
  dat <- RemoveRecord(dat, "Rhopilema_verrilli", "Brose_etal_2018")
  # 0.07009 g → 5 g; Arctic muricid shell 30-60 mm; 70 mg too small
  dat <- RemoveRecord(dat, "Trophon_clathratus", "Brose_etal_2018")

  # --- Cai_etal_2025 ---
  # 116,900 g → 20,000 g; Indian carp FishBase max 38.6 kg; 116.9 kg too
  #   large
  dat <- RemoveRecord(dat, "Catla_catla", "Cai_etal_2025")
  # 33,500 g → 3,000 g; Ecuadorian white-fronted capuchin; all Cebus <5 kg;
  #   33.5 kg impossible
  dat <- RemoveRecord(dat, "Cebus_yuracus", "GalanAcedo_etal_2026")
  # 8,977 g → 400 g; topmouth culter FishBase max 600 g; 8977 g ~15x too
  #   large
  dat <- RemoveRecord(dat, "Culter_alburnus", "Cai_etal_2025")
  # 246,200 g → 100,000 g; Malabar grouper FishBase max ~150 kg; 246.2 kg
  #   too large
  dat <- RemoveRecord(dat, "Epinephelus_malabaricus", "Cai_etal_2025")
  # 779.2 g → 100 g; sucker fish FishBase Wmax 779 g is outlier; use 100 g
  dat <- RemoveRecord(dat, "Garra_gotyla", "fishbase")
  # 522.4 g → 40 g; East African stream cyprinid; 522 g extreme outlier
  dat <- RemoveRecord(dat, "Garra_imberba", "Cai_etal_2025")
  # 30,000 g → 1,000 g; Thomas's barb 40-60 cm; 30 kg physically impossible
  dat <- RemoveRecord(dat, "Hypselobarbus_thomassi", "fishbase")
  # 24.65 g → 400 g; diamond turbot FishBase max ~1400 g; 24.6 g too small
  dat <- RemoveRecord(dat, "Hypsopsetta_guttulata", "Brose_etal_2018")
  # 3.95 g → 200 g; banded leporinus max 30 cm; adults 100-400 g; 3.95 g too
  #   small
  dat <- RemoveRecord(dat, "Leporinus_fasciatus", "Makarieva_2008")
  # 12.2 g → 3,000 g; mutton snapper; AnAge adult weight 8580 g; 12.2 g too
  #   small
  dat <- RemoveRecord(dat, "Lutjanus_analis", "Viana_2016")
  # 39.7 g → 800 g; king weakfish max 65-70 cm; typical adult 300-2000 g;
  #   39.7 g too small
  dat <- RemoveRecord(dat, "Macrodon_ancylodon", "Viana_2016")
  # 0.13 g → 3 g; small tetra max 5 cm; FishBase LWR max ~1.6 g; 130 mg too
  #   small
  dat <- RemoveRecord(dat, "Moenkhausia_ceros", "fishbase")
  # 311.5 g → 1 g; glass bloodfin tetra max 5.7 cm; 312 g impossible
  dat <- RemoveRecord(dat, "Prionobrama_filigera", "fishbase")
  # 118.6 g → 5 g; torrent minnow max 9.4 cm SL; 119 g too large
  dat <- RemoveRecord(dat, "Psilorhynchus_homaloptera", "Cai_etal_2025")
  # 24.1 g → 500 g; Borneo mahseer; even small Tor >100 g as adults; 24.1 g
  #   juvenile
  dat <- RemoveRecord(dat, "Tor_barakae", "Cai_etal_2025")
  # 7.19 g → 100 g; banded tilapia max ~22 cm; typical 50-300 g; 7.19 g
  #   juvenile
  dat <- RemoveRecord(dat, "Tilapia_sparrmanii", "DeLong_etal_2018")
  # 1,120 g → 100 g; warty-back mussel shell 60-110 mm; 1120 g ~7-100x too
  #   large
  dat <- RemoveRecord(dat, "Tritogonia_verrucosa", "Quaardvark")

  # --- Castro_2025 ---
  # 70.12 g → 4,000 g; West African tenpounder max ~100 cm; adults 2-10 kg;
  #   70.1 g too small
  dat <- RemoveRecord(dat, "Elops_lacerta", "Dienye_2021")

  # --- DeLong_etal_2018 ---
  # 8.750e-05 g → 0.002 g; adult female wet mass 1.5-2.5 mg; 87.5 µg too
  #   small
  dat <- RemoveRecord(dat, "Aedes_aegypti", "DeLong_etal_2018")
  # 1.200e-04 g → 0.005 g; Notonectidae backswimmer 8-16 mm; 0.12 mg too
  #   small
  dat <- RemoveRecord(dat, "Enithares_sobria", "DeLong_etal_2018")
  # 2.050e-04 g → 0.006 g; western tarnished plant bug adult 5-6 mm; 0.205
  #   mg too small
  dat <- RemoveRecord(dat, "Lygus_hesperus", "DeLong_etal_2018")
  # 0.00391 g → 0.3 g; cabbage moth adult wingspan 35-45 mm; 3.91 mg too
  #   small
  dat <- RemoveRecord(dat, "Mamestra_brassicae", "DeLong_etal_2018")
  # 7.222e-04 g → 5.000e-04 g; gregarious eulophid wasp; adult body <2 mm;
  #   0.72 mg too large
  dat <- RemoveRecord(dat, "Melittobia_chalybii", "Brose_etal_2018")
  # 0.02768 g → 0.002 g; minute pirate bug adult 1-2 mm; 27.7 mg too large
  dat <- RemoveRecord(dat, "Orius_sauteri", "DeLong_etal_2018")
  # 0.296 g → 0.01 g; pink bollworm adult 8-12 mm; 296 mg too large
  dat <- RemoveRecord(dat, "Pectinophora_gossypiella", "DeLong_etal_2018")
  # 4.183e-05 g → 0.001 g; lesser grain borer 2-3 mm; 41.8 µg too small
  dat <- RemoveRecord(dat, "Rhyzopertha_dominica", "DeLong_etal_2018")

  # --- Feldman_etal_2016 ---
  # 2.1 g → 100 g; large blindsnake ~65-70 cm SVL; 2.1 g too small
  dat <- RemoveRecord(dat, "Afrotyphlops_fornasinii", "Feldman_etal_2016")
  # 965.5 g → 100 g; Mozambique large-scaled blindsnake 70-100 cm; 966 g too
  #   large
  dat <- RemoveRecord(dat, "Afrotyphlops_mucruso", "Feldman_etal_2016")
  # 403.3 g → 5 g; eastern blindsnake 30-65 cm; extremely slender; 403 g
  #   impossible
  dat <- RemoveRecord(dat, "Anilios_nigrescens", "Feldman_etal_2016")
  # 403.3 g → 8 g; proximate blindsnake ~60 cm; 403 g impossible
  dat <- RemoveRecord(dat, "Anilios_proximus", "Feldman_etal_2016")
  # 312.6 g → 5 g; hook-snouted blindsnake 25-45 cm; 313 g impossible
  dat <- RemoveRecord(dat, "Anilios_unguirostris", "Feldman_etal_2016")
  # 176.9 g → 10 g; Waite's blindsnake 40-65 cm; 177 g impossible
  dat <- RemoveRecord(dat, "Anilios_waitii", "Feldman_etal_2016")
  # 1.6 g → 30 g; small homalopsid from Ambon Island; 1.6 g too small
  dat <- RemoveRecord(dat, "Brachyorrhos_albus", "Feldman_etal_2016")
  # 6.2 g → 150 g; Bohme's horned viper 40-60 cm; 6.2 g too small
  dat <- RemoveRecord(dat, "Cerastes_boehmei", "Feldman_etal_2016")
  # 5.7 g → 72 g; Ethiopian egg-eater 80-120 cm; congener D. scabra ~72 g;
  #   5.7 g too small
  dat <- RemoveRecord(dat, "Dasypeltis_abyssina", "Feldman_etal_2016")
  # 142.5 g → 5 g; Persian dwarf racer max 37.1 cm; 142.5 g impossible
  dat <- RemoveRecord(dat, "Eirenis_persicus", "Feldman_etal_2016")
  # 2.5 g → 80 g; Dunger's file snake; 2.5 g below all other Gonionotophis
  #   in dataset
  dat <- RemoveRecord(dat, "Gonionotophis_egbensis", "Feldman_etal_2016")
  # 4,068 g → 80 g; Cyprus whip snake adults 70-90 cm; 4070 g too large
  dat <- RemoveRecord(dat, "Hierophis_cypriensis", "Feldman_etal_2016")
  # 2,252 g → 200 g; black-bellied puff-faced water snake; 2250 g too large
  dat <- RemoveRecord(dat, "Homalopsis_nigroventralis", "Feldman_etal_2016")
  # 10.1 g → 200 g; Webb's kingsnake; largest specimen 75 cm; 10.1 g too
  #   small
  dat <- RemoveRecord(dat, "Lampropeltis_webbi", "Feldman_etal_2016")
  # 2.5 g → 30 g; small Malagasy Pseudoxyrhophiidae; 2.5 g too small
  dat <- RemoveRecord(dat, "Liopholidophis_oligolepis", "Feldman_etal_2016")
  # 2.7 g → 50 g; wolf snake; typical adult 20-120 g; 2.7 g too small
  dat <- RemoveRecord(dat, "Lycodon_kundui", "Feldman_etal_2016")
  # 638.8 g → 150 g; wolf snake adults typically 50-300 g; 639 g too large
  dat <- RemoveRecord(dat, "Lycodon_meridionale", "Feldman_etal_2016")
  # 176.9 g → 15 g; Malagasy blindsnake; typhlopids rarely >30 g; 177 g
  #   impossible
  dat <- RemoveRecord(dat, "Madatyphlops_decorsei", "Feldman_etal_2016")
  # 66.3 g → 15 g; Malagasy blindsnake; typical 5-30 g; 66.3 g too large
  dat <- RemoveRecord(dat, "Madatyphlops_madagascariensis", "Feldman_etal_2016")
  # 58.7 g → 10 g; Malaysian blindsnake; typical typhlopid 1-20 g; 58.7 g
  #   too large
  dat <- RemoveRecord(dat, "Malayotyphlops_koekkoeki", "Feldman_etal_2016")
  # 7.6 g → 200 g; South American racer adults typically 80-500 g; 7.6 g too
  #   small
  dat <- RemoveRecord(dat, "Mastigodryas_heathii", "Feldman_etal_2016")
  # 1,246 g → 120 g; false coral snake; other Oxyrhopus 24.9-354.5 g; 1250 g
  #   too large
  dat <- RemoveRecord(dat, "Oxyrhopus_petolarius", "Feldman_etal_2016")
  # 1,407 g → 50 g; slender dipsadid colubrid; 1410 g too large
  dat <- RemoveRecord(dat, "Paraphimophis_rusticus", "Feldman_etal_2016")
  # 528.2 g → 15 g; small dipsadid; max specimen 350 mm SVL; 528 g
  #   impossible
  dat <- RemoveRecord(dat, "Phalotris_mertensi", "Feldman_etal_2016")
  # 2,801 g → 200 g; Mexican garter snake adults 100-400 g; 2800 g too large
  dat <- RemoveRecord(dat, "Thamnophis_eques", "Feldman_etal_2016")
  # 1,497 g → 50 g; ribbon snake — smallest, most slender Thamnophis; 1500 g
  #   impossible
  dat <- RemoveRecord(dat, "Thamnophis_saurita", "Pinos_estimated")
  # 58.7 g → 5 g; Jamaican blindsnake; adults rarely >30 g; 58.7 g too large
  dat <- RemoveRecord(dat, "Typhlops_jamaicensis", "Feldman_etal_2016")
  # 3.2 g → 50 g; Shemakha viper 40-55 cm TL; smallest adult viper; 3.2 g
  #   too small
  dat <- RemoveRecord(dat, "Vipera_shemakhensis", "Feldman_etal_2016")

  # 148.9 g → 50,000 g; roughtail stingray FishBase disc width >150 cm; 149
  #   g too small
  dat <- RemoveRecord(dat, "Bathytoshia_centroura", "fishbase")
  # 2,000 g → 20 g; exquisite fairy wrasse max ~12 cm; 2000 g physically
  #   impossible
  dat <- RemoveRecord(dat, "Cirrhilabrus_exquisitus", "Quaardvark")
  # 124.6 g → 5 g; spined loach; Cobitis max typically 5-15 g; 125 g too
  #   large
  dat <- RemoveRecord(dat, "Cobitis_granoei", "Cai_etal_2025")
  # 1.539 g → 100 g; redbelly tilapia max 300 g; 1.54 g too small
  dat <- RemoveRecord(dat, "Coptodon_zillii", "Castro_2025")
  # 4.3 g → 40 g; plain helmet gurnard max 9.5 cm SL; 4.3 g too small
  dat <- RemoveRecord(dat, "Dactyloptena_tiltoni", "Cai_etal_2025")
  # 6.102 g → 150 g; Caribbean sleeper max 32 cm; 6.1 g too small
  dat <- RemoveRecord(dat, "Eleotris_amblyopsis", "fishbase")
  # 10 g → 1,000 g; South American grunt; Haemulidae adults 100-5000 g; 10 g
  #   too small
  dat <- RemoveRecord(dat, "Genyatremus_cavifrons", "fishbase")
  # 588 g → 30 g; bluntnose knifefish genus-only; type species H.
  #   brevirostris ~30 g; 588 g too large
  dat <- RemoveRecord(dat, "Hypopomus", "fishbase")
  # 0.01 g → 3 g; Delalande's blenny max 8-10 cm; 10 mg too small
  dat <- RemoveRecord(dat, "Malacoctenus_delalandii", "Brose_etal_2018")
  # 27.5 g → 300 g; leatherjacket FishBase max 900 g at 50 cm; 27.5 g too
  #   small
  dat <- RemoveRecord(dat, "Oligoplites_saliens", "fishbase")
  # 7.1 g → 400 g; leopard toadfish max 38 cm; LWR yields ~688 g; 7.1 g too
  #   small
  dat <- RemoveRecord(dat, "Opsanus_pardus", "Pauly_2024")
  # 1.6 g → 18 g; snubnose sculpin max 14 cm; typical cottid LWR 12-25 g;
  #   1.6 g too small
  dat <- RemoveRecord(dat, "Orthonopias_triacis", "Pauly_2024")
  # 1,293 g → 80 g; striped Raphael catfish FishBase Wmax ~113 g; 1290 g too
  #   large
  dat <- RemoveRecord(dat, "Platydoras_armatulus", "Cai_etal_2025")
  # 10,670 g → 100 g; blotched driftfish max ~40 cm; 10700 g far too large
  dat <- RemoveRecord(dat, "Psenes_pellucidus", "Cai_etal_2025")
  # 215,400 g → 30,000 g; oilfish FishBase max 63.5 kg; 215 kg too large
  dat <- RemoveRecord(dat, "Ruvettus_pretiosus", "Cai_etal_2025")
  # 8.2 g → 300 g; rockfish max SL 40 cm; Bayesian LWR typical 250-380 g;
  #   8.2 g too small
  dat <- RemoveRecord(dat, "Sebastes_itinus", "Pauly_2024")
  # 2.461 g → 38 g; FishBase Bayesian LWR gives ~38 g at 18 cm; 2.46 g too
  #   small
  dat <- RemoveRecord(dat, "Securicula_gora", "fishbase")
  # 2.2 g → 42 g; puffer max 22.6 cm; Bayesian LWR gives ~42 g at common
  #   length; 2.2 g too small
  dat <- RemoveRecord(dat, "Sphoeroides_greeleyi", "Viana_2016")
  # 26.6 g → 800 g; guaguanche barracuda FishBase max ~1.8 kg; 26.6 g too
  #   small
  dat <- RemoveRecord(dat, "Sphyraena_guachancho", "Viana_2016")
  # 11.64 g → 100 g; Norway pout max 35 cm; max weight ~300-440 g; 11.6 g
  #   too small
  dat <- RemoveRecord(dat, "Trisopterus_esmarkii", "Brown_etal_2018")
  # 145 g → 20,000 g; spotted gully shark; South African endemic reaching
  #   170 cm; 145 g impossible
  dat <- RemoveRecord(dat, "Triakis_megalopterus", "fishbase")

  # --- Makarieva_2008 ---
  # 0.0506 g → 1 g; crangonid sand shrimp; congener C. crangon typical 1-10
  #   g; 51 mg too small
  dat <- RemoveRecord(dat, "Crangon_affinis", "Makarieva_2008")
  # 3 g → 80 g; jewel cichlid adults 10-14 cm; typical 50-120 g; 3 g too
  #   small
  dat <- RemoveRecord(dat, "Hemichromis_bimaculatus", "Makarieva_2008")
  # 1.613 g → 0.015 g; aquatic oligochaete worm; typical 3-50 mg; 1.61 g
  #   ~100x too large
  dat <- RemoveRecord(dat, "Lumbriculus_variegatus", "Brose_etal_2018")

  # --- Quaardvark ---
  # 14 g → 1,000 g; Aruba Island Rattlesnake; literature adult mass 900-1400
  #   g; 14 g too small
  dat <- RemoveRecord(dat, "Crotalus_unicolor", "Quaardvark")
  # 5.138e-04 g → 0.1 g; European lesser glow-worm 10-15 mm; 0.51 mg too
  #   small
  dat <- RemoveRecord(dat, "Lamprohiza_splendidula", "Brose_etal_2018")

  # --- Viana_2016 ---
  # 39.2 g → 2,000 g; green weakfish max ~80 cm; typical adults 1-5 kg; 39.2
  #   g too small
  dat <- RemoveRecord(dat, "Cynoscion_virescens", "Viana_2016")
  # 3.6 g → 60 g; fringed flounder max 20-23 cm; typical 30-100 g; 3.6 g too
  #   small
  dat <- RemoveRecord(dat, "Etropus_crossotus", "Viana_2016")
  # 0.5064 g → 4 g; blenny max 12 cm; Bayesian LWR gives ~4-13 g; 506 mg too
  #   small
  dat <- RemoveRecord(dat, "Parablennius_parvicornis", "Brose_etal_2018")

  # --- Bojsen_2005 ---
  # 213.1 g → 1.8 g; seminole killifish max 5.5 cm; congeneric F. carpio =
  #   1.8 g; 213 g impossible
  dat <- RemoveRecord(dat, "Floridichthys_polyommus", "fishbase")

  return(dat)
}
