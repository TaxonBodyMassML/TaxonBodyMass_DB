# Body Mass Outlier Audit Report

**Dataset:** TaxonBodyMass_curated.csv  |  **Records scored:** 38,300
**Flagged by model/Tukey:** 2,082  (CRITICAL: 372, SUSPICIOUS: 1,703, TUKEY_ONLY: 7)
**Records verified in this audit:** 497

## Summary by category

| Category | Count |
|----------|-------|
| PLAUSIBLE | 250 |
| ERRONEOUS_MASS | 123 |
| CONFIRMED | 56 |
| NO_LIT_FOUND | 35 |
| ERRONEOUS_TAXONOMY | 24 |
| REMOVE | 5 |
| BOTH_ERRONEOUS | 4 |

## Summary by recommended action

| Action | Count |
|--------|-------|
| KEEP | 262 |
| CORRECT_MASS | 117 |
| NEEDS_REVIEW | 34 |
| "NEEDS_REVIEW" | 22 |
| CORRECT_TAXONOMY | 21 |
| "KEEP" | 20 |
| REMOVE | 7 |
| "CORRECT_MASS" | 6 |
| CORRECT_BOTH | 3 |
| Class Ophiuroidea correct for this Antarctic basket star (family Gorgonocephalidae); disc up to 6 cm and arms up to 70 cm (NIWA); 575 g may be plausible for a very large specimen but most ophiuroids weigh 1-100 g; no confirmed species-level mass data found — flag for Antarctic benthic ecology specialist | 1 |
| "REMOVE" | 1 |
| Now Novocrania lecointei (Joubin 1901); WoRMS confirms class = Craniata (Menke 1828) within Phylum Brachiopoda subphylum Craniiformea — this is the correct brachiopod class and is NOT the vertebrate subphylum Craniata (Goodrich 1930); taxonomy is correct in brachiopod context; 0.14 mg extremely small — no confirmed species-level mass literature found; flag for brachiopod specialist | 1 |
| Class Calcarea correct for calcareous sponge; no published species-level mass data found; 5 mg plausible for a small Leucosolenia colony but requires expert confirmation | 1 |
| Non-species entry — no valid binomial name; exclude from all analyses | 1 |

## Records requiring correction or removal

| Taxon | mass_g (dataset) | Category | Recommended action | Notes |
|-------|-----------------|----------|-------------------|-------|
| Camelia_sasnqua | 3.51e+05 | BOTH_ERRONEOUS | "REMOVE" | "Camellia sasanqua is a Japanese flowering shrub (Theaceae), not an arachnid. Mass of 351 kg is also impossible for any  |
| Onacea_borealis | 0.0123 | BOTH_ERRONEOUS | CORRECT_BOTH | Genus Onacea does not exist — misspelling of Oncaea (family Oncaeidae); correct name Oncaea borealis Sars 1918 (currentl |
| Carassius_leucas | 1.95e+04 | BOTH_ERRONEOUS | CORRECT_BOTH | Magnoliopsida = flowering plants — Carassius is a freshwater fish genus (Actinopterygii; Cyprinidae); epithet leucas is  |
| Saguinus_caffer | 1.17e+05 | BOTH_ERRONEOUS | CORRECT_BOTH | Saguinus caffer not a recognized valid species (treated as synonym or subspecies of S. geoffroyi; ~499g); 117300g (117.3 |
| Lineus_longifissus | 5.8e+03 | ERRONEOUS_MASS | CORRECT_MASS | Valid species (Hubrecht 1887; subantarctic; reclassified by some authorities to Heteronemertes); no nemertean is known t |
| Lineus_ruber | 0.0002 | ERRONEOUS_MASS | CORRECT_MASS | Common intertidal nemertean; body 7.5-23cm long; estimated wet mass 0.05-2g for adults; dataset 0.0002g (0.2mg) is ~3.4  |
| Liocarcinus_arcuatus | 0.0507 | ERRONEOUS_MASS | CORRECT_MASS | Portunid swimming crab; carapace width up to 30 mm (MarLIN confirmed); expected adult wet mass 2-20 g based on size-mass |
| Liocarcinus_corrugatus | 0.108 | ERRONEOUS_MASS | CORRECT_MASS | Portunid swimming crab; carapace width up to 60 mm; expected adult mass 10-100 g; 0.108 g is ~100-400x too small; log10  |
| Acanthosepion_pharaonis | 3.17 | ERRONEOUS_MASS | CORRECT_MASS | Sepia pharaonis (accepted name; Acanthosepion pharaonis is a synonym) is a large cuttlefish with max weight 5 kg (SeaLif |
| Lycodes_rossi | 6.3e+04 | ERRONEOUS_MASS | CORRECT_MASS | FishBase max weight 63.6 g; dataset 63000 g = 63 kg is ~990x the maximum; almost certainly g/kg unit error in source dat |
| Lysmata_wurdemanni | 0.000172 | ERRONEOUS_MASS | CORRECT_MASS | Peppermint shrimp; adult body length 5-7 cm (SeaLifeBase confirmed); expected mass 0.5-2 g; 0.0001719 g is ~3000-10000x  |
| Mangora_acalypha | 0.000257 | ERRONEOUS_MASS | "CORRECT_MASS" | "Orb-weaving spider (Araneidae), body 5-8 mm. 0.26 mg is impossible for an adult spider this size; expected 5-40 mg. Thi |
| Menura_alberti | 528 | ERRONEOUS_MASS | CORRECT_MASS | "Albert's Lyrebird. Males typically 900-1070 g, females 700-780 g. 527.5 g is below the known minimum for either sex and |
| Myliobatis_freminvillei | 65 | ERRONEOUS_MASS | CORRECT_MASS | Bullnose ray; wingspan ~100 cm; adult mass typically 4-10 kg; 65 g is ~2.1 log10 units below expected adult mass |
| Nannobrachium_regale | 0.0114 | ERRONEOUS_MASS | CORRECT_MASS | Lanternfish (Myctophidae; FishBase accepted name Lampanyctus regalis); FishBase max 21cm TL; adults expected ~3-60g; 0.0 |
| Liljeborgia_kinahani | 0.000138 | ERRONEOUS_MASS | CORRECT_MASS | Liljeborgiid amphipod 5-10 mm adult body length; estimated wet mass 1-10 mg from body volume scaling; 0.0001378 g (0.138 |
| Lutjanus_synagris | 1.5 | ERRONEOUS_MASS | CORRECT_MASS | FishBase max 3.5 kg; dataset 1.5 g is ~1000x below typical adult mass; difference >3 log10 units |
| Leuciscus_leuciscus | 2.3e+06 | ERRONEOUS_MASS | CORRECT_MASS | FishBase max weight 1.0 kg; dataset 2300 kg is ~2300x the maximum recorded weight; likely catastrophic unit or transcrip |
| Leptodactylus_vastus | 1e+03 | ERRONEOUS_MASS | CORRECT_MASS | Even the largest Leptodactylus (L. pentadactylus) reaches ~200-250 g. 1000 g is ~4-5x beyond any known Leptodactylus mas |
| Grapsus_adscensionis | 0.01 | ERRONEOUS_MASS | CORRECT_MASS | Littoral rock crab; carapace up to 7.7cm x 8.7cm (Wikipedia confirmed); crab of this carapace size typically 100-400g; d |
| Halichoeres_pictus | 0.135 | ERRONEOUS_MASS | CORRECT_MASS | FishBase LWR (a=0.00955; b=3.09) yields ~26 g at max 13 cm TL; dataset 0.135 g is ~200x below typical adult; difference  |
| Helicoverpa_armigera | 1.12e-05 | ERRONEOUS_MASS | CORRECT_MASS | Cotton bollworm (Noctuidae); confirmed adult wingspan 30-40mm; adult mass ~50-300mg; dataset 11.2µg is ~3.95 log10 too l |
| Helicoverpa_zea | 2.68e-06 | ERRONEOUS_MASS | CORRECT_MASS | Corn earworm (Noctuidae); confirmed adult wingspan 32-45mm; adult mass ~80-300mg; dataset 2.68µg is ~4.75 log10 too low |
| Heliothis_virescens | 2.38e-05 | ERRONEOUS_MASS | CORRECT_MASS | Tobacco budworm (Noctuidae); confirmed adult wingspan 28-35mm; adult mass ~40-150mg; dataset 23.78µg is ~3.5 log10 too l |
| Helius_waiti | 0.672 | ERRONEOUS_MASS | CORRECT_MASS | Limoniidae crane fly (Diptera); typical adult Helius mass 5-100mg; 672mg is ~1.2 log10 too high; species epithet waiti n |
| Naucrates_ductor | 0.07 | ERRONEOUS_MASS | CORRECT_MASS | Pilotfish (Carangidae); FishBase max 70cm TL; typical 40cm; adults ~200-3000g; 0.07g is ~4.1 log10 units below expected; |
| Hippoglossoides_platessoides | 4.62e+07 | ERRONEOUS_MASS | CORRECT_MASS | FishBase max weight 6.4 kg; dataset 46170 kg is ~7200x the maximum recorded weight; likely catastrophic unit or transcri |
| Hyperoche_medusarum | 6.63e-05 | ERRONEOUS_MASS | CORRECT_MASS | Hyperiid amphipod (family Hyperiidae); adults 10-20mm; expected wet mass for a 15mm hyperiid ~1-20mg; dataset 0.066mg is |
| Hypsiboas_faber | 95 | ERRONEOUS_MASS | CORRECT_MASS | Blacksmith tree frog (Boana faber); adults typically 10-50 g. 95 g is ~2-4x too high; mass may be inflated by an outlier |
| Hypsiboas_rosenbergi | 93 | ERRONEOUS_MASS | CORRECT_MASS | Rosenberg's tree frog (Boana rosenbergi); adults typically 10-50 g. 93 g is ~2-4x too high; likely an outlier source inf |
| Ischnocnema_parva | 19 | ERRONEOUS_MASS | CORRECT_MASS | Species epithet 'parva' (small); Ischnocnema are generally small leptodactylids 1-8 g. 19 g is ~5x the expected maximum  |
| Latrodectus_hesperus | 25 | ERRONEOUS_MASS | "CORRECT_MASS" | "Western black widow spider. Adult females 8-13 mm body length; known mass 0.18-0.87 g. A mass of 25 g would require a t |
| Leptodactylus_labyrinthicus | 561 | ERRONEOUS_MASS | CORRECT_MASS | Large South American Leptodactylus but even the largest congener (L. pentadactylus) reaches ~200-250 g. 561 g is ~2-3x t |
| Xantho_incisus | 0.0264 | ERRONEOUS_MASS | CORRECT_MASS | Furrowed crab; treated as synonym of Xantho hydrophilus by some authorities; carapace up to 60 mm wide x 25 mm long; exp |
| Ochotona_dalli | 1.82e+04 | ERRONEOUS_MASS | CORRECT_MASS | Dall's pika; all Ochotona species weigh 70-300g; ADW lists general pika range 125-200g; 18250g (18.25kg) is ~2.1 log10 u |
| Oithona_colcarva | 0.0123 | ERRONEOUS_MASS | CORRECT_MASS | Valid species (Bowman 1975; WoRMS confirmed); estuarine species of Western Atlantic; as Oithonidae typical dry mass 0.5- |
| Odontesthes_argentinensis | 0.01 | ERRONEOUS_MASS | CORRECT_MASS | Argentine silverside (Atherinopsidae); FishBase max 42.1cm TL; adults expected ~10-400g; 0.01g (10mg) is ~3.9 log10 unit |
| Tuta_absoluta | 4.05e-07 | ERRONEOUS_MASS | CORRECT_MASS | Tomato leaf miner moth (Lepidoptera: Gelechiidae; wingspan ~7-8mm); adult mass typically ~0.3-1mg; dataset value 0.405 m |
| Tropidonophis_dolasii | 0.5 | ERRONEOUS_MASS | CORRECT_MASS | New Guinea keelback snake (Natricidae); sister species T. novaeguineae reaches 82cm; keelbacks in this genus expected 20 |
| Triturus_vulgaris | 73.5 | ERRONEOUS_MASS | CORRECT_MASS | Smooth newt (Lissotriton vulgaris); typical adult 1-6 g. 73.48 g is ~15-20x too high; likely a data-entry or unit conver |
| Thalassoma_pavo | 0.01 | ERRONEOUS_MASS | CORRECT_MASS | Ornate wrasse; FishBase max 25 cm SL (common 20 cm); no published weight on FishBase; estimated 80-300 g from length-wei |
| Synodus_lacertinus | 0.7 | ERRONEOUS_MASS | CORRECT_MASS | Sauro lizardfish; FishBase max 27.2 cm SL; congeners S. foetens max 900 g and S. saurus max 300 g; 0.7 g is ~2.1 log uni |
| Sitotroga_cerealella | 1.64e-05 | ERRONEOUS_MASS | CORRECT_MASS | Angoumois grain moth (Lepidoptera: Gelechiidae; wingspan ~12-18mm); adult mass typically ~1-5mg; dataset value 16.4 micr |
| Sinomegaceros_ordosianus | 404 | ERRONEOUS_MASS | CORRECT_MASS | Extinct megacerine deer (Cervidae); PHYLACINE database itself flags this exact 404.3g value as erroneous in GitHub issue |
| Sebastes_atrovirens | 0.154 | ERRONEOUS_MASS | CORRECT_MASS | Kelp rockfish; FishBase max 42 cm TL; IGFA world record 910 g; typical adult 400-910 g; 0.154 g is ~3.7 log units below  |
| Scorpaena_pascuensis | 1.6 | ERRONEOUS_MASS | CORRECT_MASS | Easter Island scorpionfish; adult Scorpaena species typically 50-500+ g; 1.6 g is ~2.1 log10 units below expected adult  |
| Rhinogobius_brunneus | 3.66e+03 | ERRONEOUS_MASS | CORRECT_MASS | Max TL only 5.8 cm; congener R. duospilus FishBase max weight 6.4 g; 3663 g is physically impossible for a 5.8 cm goby;  |
| Rana_cyanophlyctis | 0.294 | ERRONEOUS_MASS | CORRECT_MASS | Skittering frog (Euphlyctis cyanophlyctis); typical adult 5-40 g. 0.294 g is ~50x too low for this medium-sized frog. So |
| Psittinus_cyanurus | 11.8 | ERRONEOUS_MASS | CORRECT_MASS | "Blue-rumped Parrot. Documented mass 40-60 g across multiple sources. 11.77 g is approximately 4x too light and clearly  |
| Pseudis_limellum | 0.53 | ERRONEOUS_MASS | CORRECT_MASS | Pseudis frogs are medium-sized hylids; adults typically 3-30 g. 0.53 g is implausibly low for any adult Pseudis species. |
| Prochilodus_scrofa | 21 | ERRONEOUS_MASS | CORRECT_MASS | Synonym of P. lineatus (streaked prochilod); FishBase max weight 7.2 kg; 21 g represents a juvenile/small study specimen |
| Prionotus_scitulus | 1.1 | ERRONEOUS_MASS | CORRECT_MASS | Leopard searobin (Triglidae); FishBase max 25cm TL; adults expected ~20-400g; 1.1g is ~2 log10 units below expected |
| Porania_antarctica | 0.153 | ERRONEOUS_MASS | CORRECT_MASS | Synonym Glabraster antarctica; max radius 70mm (~14cm diameter) robust cushion star per Biological Bulletin; estimated a |
| Pleuroxus_denticulatis | 22.7 | ERRONEOUS_MASS | CORRECT_MASS | Small chydorid ~0.5-1 mm; dry weight ~1-20 µg per Dumont et al. 1975 framework; dataset value 22.7 g represents 22.7 µg  |
| Pleurodeles_poireti | 143 | ERRONEOUS_MASS | CORRECT_MASS | Algerian ribbed newt; congener P. waltl is typically 15-40 g and P. poireti is similar or smaller. 143.4 g is ~4-5x too  |
| Pimephales_promelas | 3.54e+05 | ERRONEOUS_MASS | CORRECT_MASS | Fathead minnow (Cyprinidae); FishBase max 10.1cm; typical 7.3cm; adults ~1-10g; 354000g (354kg) is ~5 log10 units above  |
| Pholis_clemensi | 0.4 | ERRONEOUS_MASS | CORRECT_MASS | Crescent gunnel (Pholidae); FishBase max 13cm TL; eel-like elongate body; expected ~2-20g for adults; 0.4g is ~1.2 log10 |
| Phoebis_agarithe | 5.54 | ERRONEOUS_MASS | CORRECT_MASS | Large Orange Sulphur butterfly (Lepidoptera: Pieridae; wingspan ~55-75mm); typical adult Pierid mass ~0.3-0.8g; 5.537g e |
| Phallusia_nigra | 0.01 | ERRONEOUS_MASS | CORRECT_MASS | Adult Phallusia nigra is a large solitary ascidian reaching 5-15 cm body length with typical wet mass 10-200 g; dataset  |
| Parborlasia_corrugatus | 5.8e+03 | ERRONEOUS_MASS | CORRECT_MASS | World's heaviest nemertean; literature max 100-140g (1-3m length; 2cm diameter) per HandWiki and Davison & Franklin 2002 |
| Paralithodes_platypus | 0.0363 | ERRONEOUS_MASS | CORRECT_MASS | Blue king crab; SeaLifeBase max published mass 4500 g; reports up to 8200 g (18 lb); 0.03628 g is ~60000-200000x too sma |
| Ovalipes_catharus | 7.42e+03 | ERRONEOUS_MASS | CORRECT_MASS | New Zealand paddle crab; literature max ~700 g for large males (CW up to 150 mm; NZ Fisheries report and SeaLifeBase); 7 |
| Ornitnonyssus_bursa | 3.77e-09 | ERRONEOUS_MASS | "CORRECT_MASS" | "Ornithonyssus bursa (tropical fowl mite) is correctly Arachnida. Mass of 3.77 ng is impossibly small for a mite (~0.7-1 |
| Opsariichthys_pachycephalus | 1 | ERRONEOUS_MASS | CORRECT_MASS | Taiwan big-head chub (Cyprinidae); FishBase max 16cm TL; typical adult cyprinid of that size expected ~10-80g; 1g is ~1. |
| Oithona_helgolandica | 0.0123 | ERRONEOUS_MASS | CORRECT_MASS | Valid species (treated as senior synonym of O. similis Claus 1866); adults <1 mm; typical dry mass 1-3 µg DW; dataset va |
| Gonatus_onyx | 0.117 | ERRONEOUS_MASS | CORRECT_MASS | Black-eyed squid adults reach 12-18 cm ML (spent females 132-145 mm ML); estimated adult mass 50-300 g; dataset 0.117 g  |
| Octopus_rubescens | 0.096 | ERRONEOUS_MASS | CORRECT_MASS | Adult East Pacific red octopus typically 100-150 g; max ~400 g confirmed; dataset 0.096 g is ~3.1 log10 units below typi |
| Golfingia_nordenskojoeldi | 6.3e-07 | ERRONEOUS_MASS | CORRECT_MASS | 6.3e-7 g = 0.63 micrograms is below the mass of a single large cell and physically impossible for any macroscopic worm;  |
| Hippolyte_pleuracantha | 9.39e-05 | ERRONEOUS_MASS | CORRECT_MASS | Small caridean shrimp (Hippolytidae); adults ~10-20mm; congener H. varians (same dataset; also Brose source) = 14.65mg;  |
| Glyptotendipes_pallens | 0.0773 | ERRONEOUS_MASS | CORRECT_MASS | Chironomidae (non-biting midge) confirmed; typical adult chironomid mass 0.2-5mg; 77.3mg is ~1.6 log10 too high |
| Dagetichthys_lusitanica | 4.68e+05 | ERRONEOUS_MASS | CORRECT_MASS | Soleidae (sole/flatfish); largest soles weigh <2 kg; 468 kg (468000 g) is impossible; ~3.4 log units above typical; like |
| Craugastor_rugulosus | 75 | ERRONEOUS_MASS | CORRECT_MASS | Large-bodied Craugastor but 75 g is implausibly high; typical adults 5-40 g. Residual +1.76 confirms error. |
| Gobio_gobio | 2.31e+06 | ERRONEOUS_MASS | CORRECT_MASS | Gudgeon (Cyprinidae); max ~20 cm; typical adult 10-100g; 2308 kg is ~4.9 log units above typical; catastrophic magnitude |
| Craugastor_laticeps | 80 | ERRONEOUS_MASS | CORRECT_MASS | Even large Craugastor species rarely exceed 40-50 g; 80 g is implausibly high. Residual +1.79 confirms large over-shoot. |
| Cratena_pilata | 0.000172 | ERRONEOUS_MASS | CORRECT_MASS | Body 8-24mm (SeaLifeBase); size-based wet mass estimate 5-500mg; dataset 0.172mg is 2-3 log10 units below size estimate; |
| Coregonus_fera | 0.11 | ERRONEOUS_MASS | CORRECT_MASS | Lake Geneva lavaret (whitefish); adults typically 300-800 g; 0.11 g is ~3.7 log10 units below expected; likely a larval- |
| Citharichthys_stampflii | 7.3e+04 | ERRONEOUS_MASS | CORRECT_MASS | Small West African lefteye flounder max ~30 cm; typical adult ~100-300 g; 73000 g = 73 kg is ~2.7 log10 units above expe |
| Chydorus_sphaericus | 10 | ERRONEOUS_MASS | CORRECT_MASS | Body size 170-490 µm; dry weight 0.1-1.5 µg per Dumont et al. 1975; dataset value 10 g represents 10 µg stored as g (fac |
| Cheyletia_wellsi | 4.83e-07 | ERRONEOUS_MASS | "CORRECT_MASS" | "Cheyletid predatory mite (~0.3-0.5 mm body). Mass of 0.483 ng is impossible for a visible mite; expected 0.1-1 µg range |
| Cheirocratus_sundevalli | 4.01e-05 | ERRONEOUS_MASS | CORRECT_MASS | Small benthic amphipod (family Aoridae); adults typically 3-6mm; comparable Brose source amphipod Liljeborgia_kinahani ( |
| Charax_gibbosus | 3.04e+04 | ERRONEOUS_MASS | CORRECT_MASS | Glass headstander; FishBase max published weight 30.4 g; dataset 30400 g is exactly 1000x too large; probable kg-to-g or |
| Ceriodaphnia_dubia | 16.8 | ERRONEOUS_MASS | CORRECT_MASS | Adult dry mass 1-5 µg per Dumont et al. 1975; dataset value 16.8 g almost certainly represents 16.8 µg stored as g (fact |
| Cephalodiscus_gilchristi | 1.66e+05 | ERRONEOUS_MASS | CORRECT_MASS | Pterobranches are minute colonial hemichordates; individual zooids measure 0.5-3 mm; entire colonies reach at most a few |
| Casuarius_bennetti | 3.08e+04 | ERRONEOUS_MASS | CORRECT_MASS | "Dwarf Cassowary is the SMALLEST cassowary. Published mass range 17.6-26 kg. 30.75 kg exceeds all known records and like |
| Carcharhinus_altimus | 108 | ERRONEOUS_MASS | CORRECT_MASS | Bignose shark reaches 282 cm and ~168 kg (FishBase); 108 g is ~3.0 log10 units below expected adult mass; almost certain |
| Caranx_ruber | 81.9 | ERRONEOUS_MASS | CORRECT_MASS | Bar jack; FishBase max weight 8.2 kg at 73 cm FL; common length 50 cm; typical adult ~2640 g; dataset 81.9 g is 1.51 log |
| Calamophis_jobiensis | 4.48e+04 | ERRONEOUS_MASS | CORRECT_MASS | Small homalopsid snake from Yapen Island (Papua New Guinea); only 4 known specimens; described as small reed snake; 4478 |
| Bufo_debilus | 0.66 | ERRONEOUS_MASS | CORRECT_MASS | Green toad (Anaxyrus debilis); typical adult 4-20 g. 0.66 g is an order of magnitude too low. |
| Brasilanus_batus | 1.97 | ERRONEOUS_MASS | CORRECT_MASS | Hemiptera: Cicadellidae (leafhoppers; subfamily Deltocephalinae); species epithet batus not listed — only B. flagellaris |
| Bokermannohyla_alvarengai | 186 | ERRONEOUS_MASS | CORRECT_MASS | Bokermannohyla are medium-sized hylids typically 5-35 g; 185.6 g is ~5-10x too high and inconsistent with the genus. Res |
| Bemisia_tabaci | 5.33e-07 | ERRONEOUS_MASS | CORRECT_MASS | Adult silverleaf whitefly confirmed ~0.9mm; typical adult mass 10-40µg; dataset 0.53µg is ~1.6 log10 too low |
| Baseodiscus_antarcticus | 5.8e+03 | ERRONEOUS_MASS | CORRECT_MASS | Related Baseodiscus mexicanus is 1-2m long × 5-7mm wide (est. wet mass ~40g); world's heaviest nemertean (Parborlasia co |
| Ascia_monuste | 6.83 | ERRONEOUS_MASS | CORRECT_MASS | Great Southern White Pieridae butterfly; confirmed wingspan 63-86mm; typical adult mass ~0.1-0.8g; 6.828g is ~1.3 log10  |
| Aristichthys_nobilis | 6.19 | ERRONEOUS_MASS | CORRECT_MASS | Bighead carp; typical adult 2–40 kg; IGFA record 40.8 kg; dataset 6.19 g is ~3200x too small; probable juvenile or unit  |
| Argiope_bruennichi | 0.00624 | ERRONEOUS_MASS | "CORRECT_MASS" | "Wasp spider (Araneidae). Females 14-25 mm, known mass 1-4.5 g; even males (4-8 mm) weigh ~5-20 mg. 6.25 mg is ~300x too |
| Antarctomysis_maxima | 3.76 | ERRONEOUS_MASS | CORRECT_MASS | Order Mysida (true mysids); allometric scaling for Mysida shows max mass ~0.5g even for 50mm body length; 3.758g would r |
| Anocha_lyolepis | 8 | ERRONEOUS_MASS | CORRECT_MASS | Genus Anocha confirmed as Cecidomyiidae (gall midges; Diptera); adults 0.5-3mm; expected mass <1mg; 8g is ~4 log10 units |
| Alburnus_alburnus | 1.38e+06 | ERRONEOUS_MASS | CORRECT_MASS | Common bleak; FishBase max weight 60 g; dataset 1384 kg is ~23000x too large; probable unit or data-entry error |
| Acetes_americanus | 0.000151 | ERRONEOUS_MASS | CORRECT_MASS | Sergestid shrimp 10-44mm length (Wikipedia confirmed); congener A. japonicus = 70.91mg per SeaLifeBase; dataset 0.1506mg |
| Danaus_plexippus | 4.31e-05 | ERRONEOUS_MASS | CORRECT_MASS | Monarch butterfly; well-established adult mass 270-750mg; dataset 0.043mg is ~3.85 log10 too low; likely larval or per-i |
| Daphnia_magna | 0.183 | ERRONEOUS_MASS | CORRECT_MASS | Adult dry weight ~0.3 mg (ResearchGate/MDPI lit); wet weight ~1-3 mg; dataset value 0.1829 g (182.9 mg wet equivalent) i |
| Xantho_pilipes | 0.01 | ERRONEOUS_MASS | CORRECT_MASS | Small xanthid crab from NE Atlantic/Mediterranean; adults 2-4 cm CW; expected mass 2-25 g; 0.01 g is ~200-800x too small |
| Dipturus_australis | 45 | ERRONEOUS_MASS | CORRECT_MASS | Eastern shovelnose skate; adult expected several kg; 45 g is ~1.8 log10 units below expected; same mass as Dentiraja_aus |
| Ephestia_kuehniella | 1.16e-06 | ERRONEOUS_MASS | CORRECT_MASS | Mediterranean flour moth (Pyralidae); typical adult mass ~3-15mg; dataset 1.16µg is ~3.8 log10 too low |
| Eriphia_smithii | 0.01 | ERRONEOUS_MASS | CORRECT_MASS | Valid Indo-Pacific species listed in genus Eriphia (Eriphiidae; Wikipedia confirmed); all Eriphia are medium-to-large ro |
| Dentiraja_australis | 45 | ERRONEOUS_MASS | CORRECT_MASS | Australian thornback skate; adult expected several kg; 45 g is ~1.8 log10 units below expected; identical mass to Diptur |
| Etheostoma_spectabile | 2.69e+05 | ERRONEOUS_MASS | CORRECT_MASS | Orangethroat darter (Percidae); max ~9 cm; typical adult 1-4g; 269 kg is ~5.1 log units above typical; catastrophic magn |
| Eucyclops_subterraneus | 0.00541 | ERRONEOUS_MASS | CORRECT_MASS | Cyclopoid copepod; typical adult dry weight 5-100 µg; dataset value 5410 µg (5.41 mg) is ~54-1000x above expected range; |
| Eurycercus_longirostris | 71.4 | ERRONEOUS_MASS | CORRECT_MASS | Larger chydorid (benthic/littoral); expected dry weight 50-500 µg per Dumont et al. 1975 allometric framework; dataset v |
| Eurycercus_vernalis | 70 | ERRONEOUS_MASS | CORRECT_MASS | Same family and size class as E. longirostris; expected dry weight 50-500 µg; dataset value 70 g represents 70 µg stored |
| Enhydris_innominata | 1.2 | ERRONEOUS_MASS | CORRECT_MASS | Tay Ninh mud snake; semi-aquatic homalopsid from Vietnam; congener E. jagorii (similar size) weighs 65-390g (ScienceDire |
| Exoglossum_maxillingua | 0.75 | ERRONEOUS_MASS | CORRECT_MASS | Cutlips minnow (Cyprinidae); max ~20 cm; adult typically 20-100g; 0.75g likely juvenile or unit error in Pappantoniou 19 |
| Filinia_terminalis | 0.125 | ERRONEOUS_MASS | CORRECT_MASS | Certain unit error: same as F. pejleri; 0.125 g is ~5.8 log10 units above typical Filinia mass; source value was 0.125 µ |
| Fissurella_clenchi | 0.0307 | ERRONEOUS_MASS | CORRECT_MASS | Related Caribbean Fissurella spp. (F. nodosa; F. rosea) have shells 17-44mm; expected total mass ~1-8g; dataset 30.73mg  |
| Fissurella_rosea | 0.00136 | ERRONEOUS_MASS | CORRECT_MASS | Shell 17-40mm (Wikipedia; SeaLifeBase); expected total mass ~1-5g; dataset 1.356mg is ~2.9-3.6 log10 units below size-ba |
| Fontitrygon_margarita | 20 | ERRONEOUS_MASS | CORRECT_MASS | Dakar stingray (formerly Dasyatis/Himantura margarita); disc width up to ~100 cm; 20 g is ~2.5 log10 units below expecte |
| Gadus_morhua | 1.25e+09 | ERRONEOUS_MASS | CORRECT_MASS | Atlantic cod; typical adult 3-15 kg; confirmed max ~96 kg; 1.25e9 g = 1250 tonnes is physically impossible; ~5.2 log uni |
| Gila_conspersa | 1.3 | ERRONEOUS_MASS | CORRECT_MASS | Gila chub (Cyprinidae); medium cyprinid reaching 25+ cm; adult typically 50-500g; 1.3g is ~2.1 log units below typical a |
| Glomeris_connexa | 0.000382 | ERRONEOUS_MASS | "CORRECT_MASS" | "Pill millipede (Glomeridae), adults 10-20 mm. 0.38 mg is impossibly small; adult Glomeris species weigh 200-600 mg. Thi |
| Filinia_pejleri | 0.125 | ERRONEOUS_MASS | CORRECT_MASS | Certain unit error: 0.125 g is ~5.8 log10 units above typical Filinia mass (~0.1 µg = 1e-7 g); rotifers are microscopic  |
| Eleutherodactylus_johnstonei | 24 | ERRONEOUS_MASS | CORRECT_MASS | Johnstone's whistling frog; well-studied small Caribbean species, adults typically 2-8 g. 24 g is ~5x too high; likely u |
| Etheostoma_flabellare | 3.08e+05 | ERRONEOUS_MASS | CORRECT_MASS | Fantail darter (Percidae); max ~9 cm; typical adult 1-5g; 307.5 kg is ~5.2 log units above typical; catastrophic magnitu |
| Dipturus_trachyderma | 110 | ERRONEOUS_MASS | CORRECT_MASS | Large South American/Southern Ocean skate reaching ~100 cm TL; 110 g is ~1.8 log10 units below expected adult mass; like |
| Eleutherodactylus_coqui | 44.8 | ERRONEOUS_MASS | CORRECT_MASS | Puerto Rican coqui; iconic small frog, adults typically 2-5 g. 44.78 g is ~10x too high; possibly multi-source average c |
| Dytiscus_marginalis | 17.5 | ERRONEOUS_MASS | CORRECT_MASS | Great diving beetle; confirmed adult body length 27-35mm; typical adult mass ~1-2.5g; 17.51g is ~1.1 log10 too high |
| Ectomyelois_ceratoniae | 0.000257 | ERRONEOUS_MASS | CORRECT_MASS | Carob moth (Pyralidae); wingspan ~22-30mm; typical adult moth mass 5-30mg; dataset 0.26mg is ~1.6 log10 too low |
| Eleutherodactylus_cubanus | 0.18 | ERRONEOUS_MASS | CORRECT_MASS | Cuban Eleutherodactylus; even the smallest species in genus typically 0.5 g+. 0.18 g is below the plausible minimum for  |
| Notothenia_marmorata | 8.6e+03 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Marbled rockcod (Nototheniidae); Antarctic demersal fish; reported up to 60 cm; 8.6kg is within plausible range for a la |
| Nitzschia_pandora | 3e-09 | ERRONEOUS_TAXONOMY | REMOVE | Nitzschia is a diatom genus (class Bacillariophyceae; phylum Ochrophyta) - not a bivalve; mass of 3e-9 g (3 ng) is consi |
| Neisseria_mucosa | 2e-13 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | "Neisseria mucosa (family Neisseriaceae) is class Betaproteobacteria, not Gammaproteobacteria. Mass 0.2 pg plausible for |
| Neisseria_gonorrhoeae | 2e-13 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | "Neisseria gonorrhoeae (family Neisseriaceae, order Neisseriales) is class Betaproteobacteria in NCBI taxonomy, not Gamm |
| Macropus_piltonesis | 3e+04 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Extinct macropod marsupial (Diprotodontia/Macropodidae); 30kg is plausible for an extinct macropod; correct class is Mam |
| Neisseria_elongata | 2e-13 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | "Neisseria elongata (family Neisseriaceae) is class Betaproteobacteria, not Gammaproteobacteria. Mass 0.2 pg plausible f |
| Trigonodops_lopesi | 2.3e+06 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Extinct Pleistocene South American bovid (Artiodactyla); 2295kg is at the extreme upper limit for any bovid but not impo |
| Actinocyclus_spiritus | 1.64e-11 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Actinocyclus is a genus of centric diatoms (Bacillariophyta; class Coscinodiscophyceae); mass 1.64e-11g consistent with  |
| Achromobacter_ruhlandii | 2e-13 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | "Achromobacter ruhlandii (family Alcaligenaceae, order Burkholderiales) is class Betaproteobacteria, not Gammaproteobact |
| Trypanosoma_lewisi | 5.8e-11 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Trypanosoma lewisi is a flagellate protozoan (class Kinetoplastea; order Trypanosomatida); obligate parasite of rats; co |
| Nectarinia_tsavoensis | 6.8 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Magnoliopsida = flowering plants — Nectarinia tsavoensis (= Cinnyris tsavoensis; Tsavo sunbird; Nectariniidae) is a bird |
| Sphaerotilus_natans | 6.5e-12 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | "Sphaerotilus natans is a filamentous sheathed bacterium in family Comamonadaceae, order Burkholderiales, class Betaprot |
| Neisseria_flava | 2e-13 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | "Neisseria flava (family Neisseriaceae) is class Betaproteobacteria, not Gammaproteobacteria. Mass 0.2 pg plausible for  |
| Octopus_tuberculata | 1.21 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Octopus tuberculata is an invalid species name; WoRMS confirms it is a junior synonym of Ocythoe tuberculata Rafinesque  |
| Drepanocladusex_annulatus | 0.0176 | ERRONEOUS_TAXONOMY | REMOVE | Drepanocladus is a genus of aquatic mosses (Bryophyta); taxon name is also garbled (fused string). Not an amphibian. Sou |
| Brachyuran_larvae | 0.009 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | "Brachyuran larvae are decapod crustacean larvae (order Decapoda, class Malacostraca). Actinomycetes is a bacterial clas |
| Proteus_mor | 4e-13 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Proteus is a genus of Gram-negative bacteria (Enterobacterales: Morganellaceae); correct class is Gammaproteobacteria; c |
| Lugubria_strigata | 584 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Note records source=FishBase; no insect genus Lugubria is known; likely a deepwater fish entry (possibly Epigonus lugubr |
| Carangoides_latus | 6.25e+03 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Monogenea = parasitic flatworms — Carangoides latus is a carangid fish (Actinopterygii); correct class is Actinopterygii |
| Pleuromonas_jaculans | 3.02e-11 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Flagellate protozoan (Bodonida / Kinetoplastea); correct class is Kinetoplastea (or Protozoa broadly); completely misass |
| Luciella_masanensis | 9.07e-10 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Mass ~0.9 nanograms is 6+ orders of magnitude below any known gastropod (smallest snails >1 microgram); Luciella not a r |
| Elephas_namadicus | 1.3e+07 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Extinct proboscidean elephant (Palaeoloxodon namadicus); confirmed Mammalia/Proboscidea; mass ~13 tonnes consistent with |
| Casurarius_bennetti | 1.76e+04 | ERRONEOUS_TAXONOMY | REMOVE | "'Casurarius' is a misspelling of 'Casuarius'. This is a duplicate/misspelled entry for Casuarius bennetti, which alread |
| Limecoma_balthica | 0.00784 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Genus name "Limecoma" is invalid; correct name is Limecola balthica (formerly Macoma balthica; Tellinidae); class assign |
| Order_hemiptera | 0.000739 | REMOVE | REMOVE | Taxonomic order; not a species-level entry; no species-specific mass can be meaningfully assigned; must be removed from  |
| Unidentified_amoeba | 7.2e-11 | REMOVE | Non-species entry — no valid binomial name; exclude from all analyses |  |
| Unidentified_bacterium | 6e-13 | REMOVE | REMOVE | "Generic label 'Unidentified_bacterium' is not a real species identifier. Cannot verify taxonomy or mass. Rule: non-spec |
| Benthic_algae | 1e-10 | REMOVE | REMOVE | Not a species; benthic algal community term; entirely non-animal entry; must be removed |
| Other_algae | 5.95e-08 | REMOVE | REMOVE | Catch-all non-species algae category; not a taxon; no valid species identity or mass assignment; must be removed |

## Sources with systematic errors (≥2 erroneous records)

| Source | n_erroneous_records | Taxa |
|--------|--------------------|----|
| Brose_etal_2018 | 47 | Acetes_americanus; Anocha_lyolepis; Antarctomysis_maxima; Argiope_bruennichi; Ascia_monuste; Baseodi |
| DeLong_etal_2010 | 18 | Alburnus_alburnus; Ceriodaphnia_dubia; Chydorus_sphaericus; Daphnia_magna; Etheostoma_flabellare; Et |
| DeLong_etal_2018 | 18 | Bemisia_tabaci; Ceriodaphnia_dubia; Chydorus_sphaericus; Danaus_plexippus; Daphnia_magna; Ectomyeloi |
| Makarieva_2008 | 18 | Alburnus_alburnus; Antarctomysis_maxima; Brasilanus_batus; Bufo_debilus; Coregonus_fera; Daphnia_mag |
| fishbase | 13 | Alburnus_alburnus; Carcharhinus_altimus; Charax_gibbosus; Citharichthys_stampflii; Dagetichthys_lusi |
| Cai_etal_2025 | 13 | Alburnus_alburnus; Bokermannohyla_alvarengai; Casuarius_bennetti; Etheostoma_flabellare; Etheostoma_ |
| AmphiBIO | 8 | Craugastor_laticeps; Craugastor_rugulosus; Eleutherodactylus_cubanus; Hypsiboas_faber; Hypsiboas_ros |
| Brown_etal_2018 | 8 | Camelia_sasnqua; Daphnia_magna; Filinia_pejleri; Filinia_terminalis; Gadus_morhua; Hippoglossoides_p |
| Quaardvark | 6 | Casuarius_bennetti; Dytiscus_marginalis; Eleutherodactylus_coqui; Gadus_morhua; Latrodectus_hesperus |
| AnAge | 4 | Casuarius_bennetti; Gadus_morhua; Hippoglossoides_platessoides; Leuciscus_leuciscus |
| Pauly_2024 | 4 | Pholis_clemensi; Prionotus_scitulus; Scorpaena_pascuensis; Synodus_lacertinus |
| Hirt_etal_2017 | 4 | Alburnus_alburnus; Carassius_leucas; Gadus_morhua; Leuciscus_leuciscus |
| Castro_2025 | 4 | Antarctomysis_maxima; Coregonus_fera; Etheostoma_flabellare; Gadus_morhua |
| Feldman_etal_2016 | 3 | Calamophis_jobiensis; Enhydris_innominata; Tropidonophis_dolasii |
| Wilman_etal_2014 | 3 | Casuarius_bennetti; Menura_alberti; Psittinus_cyanurus |
| Killen_etal_2016 | 2 | Aristichthys_nobilis; Gadus_morhua |
| Viana_2016 | 2 | Caranx_ruber; Lutjanus_synagris |
| sealifebase | 2 | Acanthosepion_pharaonis; Cephalodiscus_gilchristi |

## TUKEY_ONLY records (class-level outlier, model residual < 1.0) — for user review

| Taxon | mass_g | taxon_class | abs_residual |
|-------|--------|------------|-------------|
| Eunectes_murinus | 1.99e+05 | Squamata | 0.925 |
| Gigantocypris_agassizii | 5.7 | Ostracoda | 0.899 |
| Malayopython_reticulatus | 2.47e+05 | Squamata | 0.572 |
| Gigantocypris_mulleri | 1.2 | Ostracoda | 0.222 |
| Tomocerus_flavescens | 0.000282 | Collembola | 0.184 |
| Polyxenus_lagurus | 2.78e-05 | Diplopoda | 0.058 |
| Balistes_carolinensis | 6.15e+03 | Chromadorea | 0.013 |

---
_Generated by scripts/audit_synthesis.py_
