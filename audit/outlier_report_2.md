# Body Mass Outlier Audit Report — SUSPICIOUS Tier

**Dataset:** TaxonBodyMass_curated.csv  |  **Records scored:** 38,300
**SUSPICIOUS flagged (abs_residual 1.0–2.0):** 1,703
**Records verified in this audit:** 1683

## Summary by category

| Category | Count |
|----------|-------|
| PLAUSIBLE | 1102 |
| ERRONEOUS_MASS | 214 |
| NO_LIT_FOUND | 183 |
| CONFIRMED | 125 |
| ERRONEOUS_TAXONOMY | 39 |
| NEEDS_REVIEW | 16 |
| BOTH_ERRONEOUS | 4 |

## Summary by recommended action

| Action | Count |
|--------|-------|
| KEEP | 1151 |
| NEEDS_REVIEW | 240 |
| CORRECT_MASS | 208 |
| CORRECT_TAXONOMY | 34 |
| "KEEP" | 19 |
| "NEEDS_REVIEW" | 18 |
| REMOVE | 6 |
| CORRECT_BOTH | 3 |
| "CORRECT_MASS" | 2 |
| https://www.marinespecies.org/aphia.php?p=taxdetails&id=111447 | 1 |
| https://www.marinespecies.org/aphia.php?p=taxdetails&id=111445 | 1 |

## Records requiring correction or removal

| Taxon | mass_g (dataset) | Category | Recommended action | Notes |
|-------|-----------------|----------|-------------------|-------|
| Lepadogaster_zebrina | 0.01 | BOTH_ERRONEOUS | REMOVE | FISH not gastropod; Lepadogaster is a clingfish genus (family Gobiesocidae; order Gobiesociformes; phylum Chordata); res |
| Momoculodes_scabriculosus | 0.47 | BOTH_ERRONEOUS | CORRECT_BOTH | TAXONOMY: "Momoculodes" is not a recognized valid genus; probable misspelling of "Monoculodes" (Amphipoda: Oedicerotidae |
| Psenes_whiteleggii | 1.3 | BOTH_ERRONEOUS | CORRECT_BOTH | TAXONOMY: Psenes whiteleggii is a junior synonym of Cubiceps whiteleggii (Whitelegge 1889) -- residuals file confirms au |
| Squalinus_cephalus | 1.5 | BOTH_ERRONEOUS | CORRECT_BOTH | Squalius cephalus is the European chub - a cyprinid freshwater fish (Actinopterygii:Cypriniformes:Cyprinidae); dataset i |
| Hydrobiosella_stenocera | 6.63e-05 | ERRONEOUS_MASS | CORRECT_MASS | Caddisfly (Trichoptera: Hydrobiosidae); 0.066mg is far too small for any adult or late-instar caddisfly; /log10(0.000066 |
| Lycodon_kundui | 2.7 | ERRONEOUS_MASS | CORRECT_MASS | Wolf snake (Colubridae) from Southeast Asia; Lycodon adults of even small species typically weigh 20-120 g; 2.7 g is ~1. |
| Lycodon_meridionale | 639 | ERRONEOUS_MASS | CORRECT_MASS | Wolf snake (Colubridae) from South Asia; adults typically 80-100 cm SVL; most Lycodon adults weigh 50-300 g; 638.8 g is  |
| Lygosoma_corpulentum | 186 | ERRONEOUS_MASS | CORRECT_MASS | Skink (Scincidae) from Southeast Asia; epithet corpulentum means fat-bodied but Lygosoma adults even in heavy-bodied spe |
| Lygus_hesperus | 0.000205 | ERRONEOUS_MASS | CORRECT_MASS | Taxonomy correct: Hemiptera; Miridae; Lygus hesperus (western tarnished plant bug) confirmed; adult body length 5-6 mm;  |
| Macrodon_ancylodon | 39.7 | ERRONEOUS_MASS | CORRECT_MASS | King weakfish / pescada-foguete (Sciaenidae); W. Atlantic (Caribbean to Argentina); max TL ~65-70 cm; typical adult body |
| Madatyphlops_decorsei | 177 | ERRONEOUS_MASS | CORRECT_MASS | Malagasy blindsnake (Typhlopidae); typhlopids are thin worm-like burrowing snakes; even large typhlopid species rarely e |
| Madatyphlops_madagascariensis | 66.3 | ERRONEOUS_MASS | CORRECT_MASS | Malagasy blindsnake (Typhlopidae); thin worm-like burrowing snake; typical adult mass for Madatyphlops 5-30 g; 66.3 g is |
| Malacoctenus_delalandii | 0.01 | ERRONEOUS_MASS | CORRECT_MASS | Delalande's blenny (Labrisomidae); tropical W. Atlantic (Brazil coast); max TL ~8-10 cm; typical adult weight 1-8 g; dat |
| Malayotyphlops_koekkoeki | 58.7 | ERRONEOUS_MASS | CORRECT_MASS | Malaysian blindsnake (Typhlopidae); thin worm-like burrowing snake from Malaysia/Indonesia; typical adult typhlopid mass |
| Mamestra_brassicae | 0.00391 | ERRONEOUS_MASS | CORRECT_MASS | Taxonomy correct: Lepidoptera; Noctuidae; Mamestra brassicae (cabbage moth) confirmed; adult wingspan 35-45 mm; typical  |
| Marthasterias_glacialis | 0.367 | ERRONEOUS_MASS | CORRECT_MASS | Spiny starfish; one of the largest NE Atlantic sea stars; arm span up to 80 cm; typical adult wet mass 100-3000 g; datas |
| Mastigodryas_heathii | 7.6 | ERRONEOUS_MASS | CORRECT_MASS | South American racer (Colubridae); Mastigodryas adults typically 80-150 cm SVL; adult mass typically 80-500 g; 7.6 g is  |
| Tetragoneuria_cynosura | 0.000662 | ERRONEOUS_MASS | CORRECT_MASS | Now classified as Epitheca cynosura (common baskettail; Odonata:Corduliidae; body 38-46mm; wingspan 60-73mm); typical ad |
| Melittobia_chalybii | 0.000722 | ERRONEOUS_MASS | CORRECT_MASS | Taxonomy correct: Hymenoptera; Eulophidae; Melittobia chalybii confirmed gregarious ectoparasitoid wasp; adult body leng |
| Menura_alberti | 528 | ERRONEOUS_MASS | CORRECT_MASS | "Albert's Lyrebird. Males typically 900-1070 g, females 700-780 g. 527.5 g is below the known minimum for either sex and |
| Meridiastra_gunnii | 100 | ERRONEOUS_MASS | CORRECT_MASS | Small cushion star from southern Australia; maximum diameter ~6 cm; typical adult wet mass 1-20 g; dataset 100 g is ~1.1 |
| Metapenaeus_pruinosus | 0.184 | ERRONEOUS_MASS | CORRECT_MASS | Penaeidae shrimp (Decapoda: Penaeidae); adult Metapenaeus spp. typically 5-30 g; 0.184 g is ~1.81 log10 units below typi |
| Mitrella_lunata | 0.00118 | ERRONEOUS_MASS | CORRECT_MASS | Accepted name Astyris lunata (Columbellidae; Neogastropoda); small dove shell; shell 7-12 mm; expected adult wet mass 30 |
| Moenkhausia_ceros | 0.13 | ERRONEOUS_MASS | CORRECT_MASS | Small tetra (Characidae; Characiformes); S. America; max TL 5.0 cm; FishBase LW: a=0.01072; b=3.11; at 5 cm (max) W ~1.6 |
| Rhyzopertha_dominica | 4.18e-05 | ERRONEOUS_MASS | CORRECT_MASS | Lesser grain borer (Coleoptera: Bostrichidae; 2-3mm body); well-documented stored-product pest; adult body mass typicall |
| Morula_uva | 0.01 | ERRONEOUS_MASS | CORRECT_MASS | Coral reef muricid (Muricidae; Neogastropoda); shell 15-30 mm; expected adult wet mass 0.5-5 g for this shell size; data |
| Lutjanus_analis | 12.2 | ERRONEOUS_MASS | CORRECT_MASS | Mutton snapper (Perciformes: Lutjanidae); Caribbean; well-characterised large snapper; AnAge adult weight 8580 g; Mahe_2 |
| Lumbriculus_variegatus | 1.61 | ERRONEOUS_MASS | CORRECT_MASS | Dataset 1.613 g is ~2 log units above typical adult wet mass of 3–50 mg; well-studied OECD ecotoxicology test organism;  |
| Lophozozymus_incisus | 0.319 | ERRONEOUS_MASS | CORRECT_MASS | Xanthid crab with carapace width ~3-6cm in adults; expected adult wet mass 5-40g from xanthid body-volume scaling; 0.319 |
| Liopholidophis_oligolepis | 2.5 | ERRONEOUS_MASS | CORRECT_MASS | Small Malagasy snake (Pseudoxyrhophiidae) from Madagascar; genus reaches up to ~60 cm SVL; even the smallest adults of t |
| Hypopomus | 588 | ERRONEOUS_MASS | CORRECT_MASS | Bluntnose knifefish (Hypopomidae; Gymnotiformes; South America); genus-only entry (no species epithet); type species H.  |
| Hypselobarbus_thomassi | 3e+04 | ERRONEOUS_MASS | CORRECT_MASS | Thomas's barb (Cyprinidae; Western Ghats / Sri Lanka region); Hypselobarbus species typically reach 40-60 cm and 300-300 |
| Hypsiboas_faber | 95 | ERRONEOUS_MASS | CORRECT_MASS | Blacksmith tree frog (Boana faber); adults typically 10-50 g. 95 g is ~2-4x too high; mass may be inflated by an outlier |
| Hypsiboas_rosenbergi | 93 | ERRONEOUS_MASS | CORRECT_MASS | Rosenberg's tree frog (Boana rosenbergi); adults typically 10-50 g. 93 g is ~2-4x too high; likely an outlier source inf |
| Homalopsis_nigroventralis | 2.25e+03 | ERRONEOUS_MASS | CORRECT_MASS | Deuve's water snake (black-bellied puff-faced water snake); described by Murphy et al. 2011 as species distinct from H.  |
| Hypsopsetta_guttulata | 24.6 | ERRONEOUS_MASS | CORRECT_MASS | Diamond turbot (Pleuronectidae; Pacific coast of North America); FishBase max TL 46 cm; max weight ~1400 g; typical adul |
| Ischnochiton_striolatus | 0.0156 | ERRONEOUS_MASS | CORRECT_MASS | Small chiton ~10-30mm length; Brose_etal_2018 likely reports AFDW; 0.01563g is ~1.1 log10 units below expected adult wet |
| Ischnocnema_parva | 19 | ERRONEOUS_MASS | CORRECT_MASS | Species epithet 'parva' (small); Ischnocnema are generally small leptodactylids 1-8 g. 19 g is ~5x the expected maximum  |
| Jordania_zonope | 1.5 | ERRONEOUS_MASS | CORRECT_MASS | Longfin sculpin (Cottidae / Jordaniidae; NE Pacific; Alaska to California); FishBase max TL 15.0 cm; FishBase Bayesian W |
| Thamnophis_eques | 2.8e+03 | ERRONEOUS_MASS | CORRECT_MASS | Mexican garter snake (Colubridae); adult females reach up to 1.1-1.2m TL; typical adult mass 100-400g; even the largest  |
| Hyas_coarctatus | 0.225 | ERRONEOUS_MASS | CORRECT_MASS | Toad crab / Arctic lyre crab (Oregoniidae; Decapoda); adults: males carapace length up to 65mm; females up to 50mm; typi |
| Knodus_gamma | 661 | ERRONEOUS_MASS | CORRECT_MASS | Knodus are tiny South American stream characins (Characidae); TL typically 3-6 cm; maximum adult mass ~3 g; 661 g exceed |
| Lamprohiza_splendidula | 0.000514 | ERRONEOUS_MASS | CORRECT_MASS | European lesser glow-worm (Coleoptera: Lampyridae); body length ~10-15mm; 0.51mg is ~150x below expected adult mass (~80 |
| Lampropeltis_webbi | 10.1 | ERRONEOUS_MASS | CORRECT_MASS | Webb's kingsnake (Colubridae) from Baja California Mexico; only 5 known specimens; largest specimen 75cm TL; adult Lampr |
| Lepidion_schmidti | 1.47e+04 | ERRONEOUS_MASS | CORRECT_MASS | Schmidt's codling (Moridae); deep-sea gadiform fish; FishBase max TL ~43 cm; a slender 43 cm morid using typical gadifor |
| Leporinus_fasciatus | 3.95 | ERRONEOUS_MASS | CORRECT_MASS | Banded leporinus (Anostomidae); Amazon and Orinoco drainages; max TL ~30 cm; adults commonly 100-400 g; dataset 3.95 g f |
| Lepsiella_albomarginata | 0.0216 | ERRONEOUS_MASS | CORRECT_MASS | Small NZ/Australian muricid (Muricidae; Neogastropoda); shell ~15-25 mm; expected adult wet mass 0.3-3 g based on congen |
| Leptodactylus_labyrinthicus | 561 | ERRONEOUS_MASS | CORRECT_MASS | Large South American Leptodactylus but even the largest congener (L. pentadactylus) reaches ~200-250 g. 561 g is ~2-3x t |
| Leptodactylus_vastus | 1e+03 | ERRONEOUS_MASS | CORRECT_MASS | Even the largest Leptodactylus (L. pentadactylus) reaches ~200-250 g. 1000 g is ~4-5x beyond any known Leptodactylus mas |
| Lestes_sponsa | 0.781 | ERRONEOUS_MASS | CORRECT_MASS | Taxonomy correct: Odonata (Zygoptera); Lestidae; Lestes sponsa (emerald damselfly) confirmed; adult body length 35-38 mm |
| Liljeborgia_georgiana | 0.59 | ERRONEOUS_MASS | CORRECT_MASS | Liljeborgiid amphipod ~5-12mm body length; expected wet mass 1-20mg from body-volume scaling; congener L. kinahani confi |
| Stenoperla_prasinia | 9.21e-05 | ERRONEOUS_MASS | CORRECT_MASS | Stenoperla prasina (correct spelling; dataset appends spurious trailing 'i') is one of the world's largest stoneflies (P |
| Labidocera_jollae | 0.0418 | ERRONEOUS_MASS | CORRECT_MASS | Mass 0.0418 g = 41800 µg is ~100-400x too large for Pontellidae (expected 100-500 µg wet); congeners L. aestiva and L. w |
| Limnephilus_marmoratus | 0.808 | ERRONEOUS_MASS | CORRECT_MASS | Taxonomy correct: Trichoptera; Limnephilidae; Limnephilus marmoratus confirmed; adult body length 10-18 mm; typical adul |
| Sphyraena_guachancho | 26.6 | ERRONEOUS_MASS | CORRECT_MASS | Guaguanche barracuda; FishBase max TL 200 cm (common 70 cm); FishBase max published weight ~1.8 kg; barracuda LW (a~0.00 |
| Sphoeroides_greeleyi | 2.2 | ERRONEOUS_MASS | CORRECT_MASS | Tetraodontidae; max 22.6 cm TL; common 14 cm TL; Bayesian LWR a=0.02042 b=2.89; W_typical=42g at common length; dataset  |
| Parablennius_parvicornis | 0.506 | ERRONEOUS_MASS | CORRECT_MASS | FishBase max 12.0 cm SL; Bayesian W-L a=0.00776; b=3.0 gives ~13.4 g at 12 cm and ~4.0 g at 8 cm; Brose_etal_2018 / Mend |
| Paraphimophis_rusticus | 1.41e+03 | ERRONEOUS_MASS | CORRECT_MASS | South American dipsadid colubrid (Colubridae sensu lato; monotypic slender-bodied genus; formerly placed in Liophis/rela |
| Pectinophora_gossypiella | 0.296 | ERRONEOUS_MASS | CORRECT_MASS | Lepidoptera: Gelechiidae (pink bollworm); one of the most-studied cotton pest moths worldwide; adult body length 8–12mm; |
| Pelagia_noctiluca | 1.4 | ERRONEOUS_MASS | CORRECT_MASS | Adult bell 3-12cm; even smallest adults expected ~5-200g wet; DeLong_etal_2018 metabolic database likely reports dry or  |
| Periphylla_periphylla | 12.1 | ERRONEOUS_MASS | CORRECT_MASS | Wikipedia reports average wet weight 540g for this species; bell up to 30cm; 12.09g is ~1.65 log10 units below average;  |
| Phalotris_mertensi | 528 | ERRONEOUS_MASS | CORRECT_MASS | Small dipsadid false coral snake from central-eastern Brazil and Paraguay; documented adult specimen 350mm SVL + 30mm ta |
| Phascolion_strombi | 6.3e-07 | ERRONEOUS_MASS | CORRECT_MASS | Macroscopic sipunculan worm living in gastropod shells; body length 5-30 mm; minimum plausible adult mass ~1 mg (0.001 g |
| Pirimela_denticulata | 0.102 | ERRONEOUS_MASS | CORRECT_MASS | Small shore crab (Decapoda: Pirimelidae); carapace width typically 15-25 mm; adult wet mass estimated 0.3-5 g (typical ~ |
| Platydoras_armatulus | 1.29e+03 | ERRONEOUS_MASS | CORRECT_MASS | Chocolate/Striped Raphael catfish (Siluriformes: Doradidae); Amazonia and Orinoco basins; FishBase Wmax ~113 g; max TL ~ |
| Pleurodeles_poireti | 143 | ERRONEOUS_MASS | CORRECT_MASS | Algerian ribbed newt; congener P. waltl is typically 15-40 g and P. poireti is similar or smaller. 143.4 g is ~4-5x too  |
| Polyeunoa_laevis | 15 | ERRONEOUS_MASS | CORRECT_MASS | Taxonomy correct: Phyllodocida; Polynoidae; small Antarctic scale worm reported at ~2-3 cm body length; wet mass expecte |
| Sclerocrangon_boreas | 0.0154 | ERRONEOUS_MASS | CORRECT_MASS | Large Arctic crangonid shrimp (Decapoda: Crangonidae); one of the largest crangonids; TL up to 100-120 mm; adult wet mas |
| Prionobrama_filigera | 312 | ERRONEOUS_MASS | CORRECT_MASS | Glass bloodfin tetra (Characiformes: Characidae); small Amazonian characin; FishBase max TL 5.7 cm SL; at max size typic |
| Pristipomoides_aquilonaris | 93.4 | ERRONEOUS_MASS | CORRECT_MASS | Wenchman snapper (Perciformes: Lutjanidae); Caribbean and Gulf of Mexico reef fish; FishBase max TL ~67 cm; Wmax ~3.6 kg |
| Psenes_pellucidus | 1.07e+04 | ERRONEOUS_MASS | CORRECT_MASS | Blotched driftfish (Perciformes: Nomeidae); epipelagic/mesopelagic; FishBase max TL ~40 cm; typical adult driftfish at t |
| Pseudis_limellum | 0.53 | ERRONEOUS_MASS | CORRECT_MASS | Pseudis frogs are medium-sized hylids; adults typically 3-30 g. 0.53 g is implausibly low for any adult Pseudis species. |
| Psilorhynchus_homaloptera | 119 | ERRONEOUS_MASS | CORRECT_MASS | Torrent minnow (Psilorhynchidae; Cypriniformes); FishBase max length 9.4 cm SL; no published weight; dataset 118.6 g gro |
| Psittinus_cyanurus | 11.8 | ERRONEOUS_MASS | CORRECT_MASS | "Blue-rumped Parrot. Documented mass 40-60 g across multiple sources. 11.77 g is approximately 4x too light and clearly  |
| Python_bivittatus | 1.98e+05 | ERRONEOUS_MASS | CORRECT_MASS | 197700g (197.7kg) exceeds heaviest Burmese python ever reliably documented (~182800g captive; wild max ~97000g); typical |
| Pyura_chilensis | 2.91 | ERRONEOUS_MASS | CORRECT_MASS | Large commercially harvested tunicate (piure) from Chile and Peru; adults 10-15 cm body length; typical wet mass 100-150 |
| Rana_cyanophlyctis | 0.294 | ERRONEOUS_MASS | CORRECT_MASS | Skittering frog (Euphlyctis cyanophlyctis); typical adult 5-40 g. 0.294 g is ~50x too low for this medium-sized frog. So |
| Rhinobrycon_negrensis | 39 | ERRONEOUS_MASS | REMOVE | Monotypic characid (Characiformes: Characidae) from Rio Negro basin; FishBase max length 3.9 cm SL; no weight data on Fi |
| Rhopilema_verrilli | 5.5 | ERRONEOUS_MASS | CORRECT_MASS | All Rhopilema adults are large jellyfish (0.5-10 kg range); bell diameter 30-45+ cm; 5.498 g is ~2.7 log10 units below e |
| Palaeoloxodon_naumanni | 3.14e+04 | ERRONEOUS_MASS | CORRECT_MASS | Naumann's elephant (Proboscidea: Elephantidae); full-sized Pleistocene elephant from East Asia (Japan/China/Korea); esti |
| Scolecolepides_viridis | 14.9 | ERRONEOUS_MASS | CORRECT_MASS | Taxonomy correct: Spionida; Spionidae; Scolecolepides viridis is a junior synonym of Marenzelleria viridis (well-studied |
| Pachycara_brachycephalum | 3.5 | ERRONEOUS_MASS | CORRECT_MASS | FishBase max TL 22.3 cm for broadhead eelpout (Antarctic deep-sea zoarcid); typical zoarcid LWR gives 20-80g at 20-22 cm |
| Oxyrhopus_petolarius | 1.25e+03 | ERRONEOUS_MASS | CORRECT_MASS | False coral snake (Colubridae; Central and South America); other Oxyrhopus in dataset range 24.9-354.5 g; O. petolarius  |
| Nematostella_vectensis | 17.5 | ERRONEOUS_MASS | CORRECT_MASS | Starlet sea anemone; well-characterised model organism; adults 10-35 mm body length and ~1-3 mm column diameter; typical |
| Nesameletus_ornatus | 2.48e-05 | ERRONEOUS_MASS | CORRECT_MASS | Taxonomy correct: Ephemeroptera; Nesameletidae; Nesameletus ornatus confirmed NZ mayfly; adult body length ~8-15 mm; typ |
| Notarius_grandicassis | 58.3 | ERRONEOUS_MASS | CORRECT_MASS | FishBase max 63cm TL (common 40cm); Bayesian LWR a=0.00631 b=3.14 TL gives 677g at 40cm and 2818g at 63cm; dataset 58.3g |
| Notonecta_glauca | 0.772 | ERRONEOUS_MASS | CORRECT_MASS | Taxonomy correct: Hemiptera; Notonectidae; Notonecta glauca (common backswimmer) confirmed; adult body length 14-16 mm;  |
| Ocenebra_erinaceus | 0.0445 | ERRONEOUS_MASS | CORRECT_MASS | Sting winkle / hedgehog murex (Muricidae; Neogastropoda); well-known edible NE Atlantic and Mediterranean species; shell |
| Oligoplites_saliens | 27.5 | ERRONEOUS_MASS | CORRECT_MASS | FishBase max weight 900g at max 50cm TL (common 35cm TL); dataset 27.5g is 1.51 log units below FishBase max weight; LWR |
| Oligosoma_northlandi | 219 | ERRONEOUS_MASS | CORRECT_MASS | Northland skink (Scincidae; New Zealand; threatened); all other Oligosoma in dataset weigh 2.4-73.3 g; 219 g is ~3x the  |
| Olinga_feredayi | 2.51e-05 | ERRONEOUS_MASS | CORRECT_MASS | Taxonomy correct: Trichoptera; Conoesucidae; Olinga feredayi confirmed NZ caddisfly; larvae and adults typically 1-10 mg |
| Olinga_feredayii | 9.36e-05 | ERRONEOUS_MASS | NEEDS_REVIEW | Taxonomy correct: Trichoptera; Conoesucidae; matched to Olinga feredayi (one i) at 95% confidence -- double-i spelling O |
| Omanosaura_jayakari | 177 | ERRONEOUS_MASS | CORRECT_MASS | Jayakar's lacertid (Lacertidae; Oman/Yemen); congeneric O. cyanura weighs 5.1 g (residual OK); O. jayakari is the larger |
| Simalia_amethistina | 1.6e+05 | ERRONEOUS_MASS | CORRECT_MASS | Amethystine python (Pythonidae); Australia and New Guinea; maximum documented mass ~27-30 kg (27000-30000g) per Wikipedi |
| Hierophis_cypriensis | 4.07e+03 | ERRONEOUS_MASS | CORRECT_MASS | Cyprus whip snake; slender Colubridae endemic to Cyprus; adults 70-90cm (max 116.5cm TL); all other Hierophis in dataset |
| Oneirodes_acanthias | 4.2 | ERRONEOUS_MASS | CORRECT_MASS | FishBase max weight 370g at max 20cm TL; dataset 4.2g is 1.95 log units below FishBase max; Oneirodidae exhibit extreme  |
| Ophiocomina_nigra | 0.01 | ERRONEOUS_MASS | CORRECT_MASS | Well-known large northeastern Atlantic brittle star; disc diameter up to 25mm; arm radius up to 12cm; typical adult wet  |
| Ophiothrix_fragilis | 0.02 | ERRONEOUS_MASS | CORRECT_MASS | Adult disc ~10mm; arms ~50mm; Davoult 1992 is a population production study likely reporting AFDW or carbon mass per ind |
| Opsanus_pardus | 7.1 | ERRONEOUS_MASS | CORRECT_MASS | FishBase max 38cm TL; LWR a=0.01605 b=3.000 SL (n=3) gives ~688g at ~35cm SL (38cm TL); LWR a=0.01440 b=2.770 TL (n=65;  |
| Sigara_lateralis | 4 | ERRONEOUS_MASS | CORRECT_MASS | Water boatman (Hemiptera: Corixidae; body length 5-10mm); typical adult wet mass 2-15mg; dataset value 4g (4000mg) is ~2 |
| Shinisaurus_crocodilurus | 918 | ERRONEOUS_MASS | CORRECT_MASS | Chinese crocodile lizard (Shinisauridae); peer-reviewed PMC/Frontiers study (captivity gut microbiota; Frontiers in Micr |
| Securicula_gora | 2.46 | ERRONEOUS_MASS | CORRECT_MASS | Max TL 24.5 cm; FishBase Bayesian L-W (a=0.00631 b=3.01 TL) gives typical adult ~18 cm ~38 g and max ~97 g; 2.461 g back |
| Orius_sauteri | 0.0277 | ERRONEOUS_MASS | CORRECT_MASS | Taxonomy correct: Hemiptera; Anthocoridae; Orius sauteri confirmed minute pirate bug (predator of thrips/mites); adult b |
| Orthonopias_triacis | 1.6 | ERRONEOUS_MASS | CORRECT_MASS | FishBase max TL 14.0 cm for snubnose sculpin (California coast); typical cottid LWR (a~0.006-0.012; b~3.0) yields ~12-25 |
| Sebastes_itinus | 8.2 | ERRONEOUS_MASS | CORRECT_MASS | Max SL 40.0 cm; Bayesian L-W (a=0.01 b=3.09 TL) gives typical adult 25-30 cm ~250-380 g and max ~1200 g; 8.2 g back-calc |
| Osmerus_eperlanus | 462 | ERRONEOUS_MASS | CORRECT_MASS | FishBase max TL 35.0 cm; max published weight 75g (Muus & Dahlstrom 1978); typical adult European smelt 10-40g; dataset  |
| Osteochilus_melanopleura | 4.25e+03 | ERRONEOUS_MASS | CORRECT_MASS | FishBase name Osteochilus melanopleurus (dataset has melanopleura; 95% match score suggesting minor epithet discrepancy) |
| Oocatochus_rufodorsatus | 2.1 | ERRONEOUS_MASS | CORRECT_MASS | Red-backed ratsnake (Colubridae; China; Korea; Russia Far East); adults typically 50-90 cm TL; 2.1 g is biologically imp |
| Hemichromis_bimaculatus | 3 | ERRONEOUS_MASS | CORRECT_MASS | Jewel cichlid (Cichlidae); adults typically 10-14 cm SL and 50-120 g; FishBase max weight ~100-150 g; dataset 3 g corres |
| Himantolophus_groenlandicus | 1.3 | ERRONEOUS_MASS | CORRECT_MASS | Atlantic footballfish (Himantolophidae); extreme sexual dimorphism: females reach ~60 cm TL and estimated 1-5 kg; males  |
| Gonionotophis_egbensis | 2.5 | ERRONEOUS_MASS | CORRECT_MASS | Dunger's file snake; African lamprophiid endemic to Nigeria; 2.5g far below all other Gonionotophis in dataset (next sma |
| Brachyorrhos_albus | 1.6 | ERRONEOUS_MASS | CORRECT_MASS | Taxonomy correct (Homalopsidae; Squamata); small homalopsid reed snake from Ambon Island Indonesia; all three congeners  |
| Varanus_exanthematicus | 1.59e+04 | ERRONEOUS_MASS | CORRECT_MASS | Savannah monitor (Varanidae); sub-Saharan Africa; adults ~80-130 cm TL; published maximum body mass ~5.4 kg (12 lb); 158 |
| Bufo_debilus | 0.66 | ERRONEOUS_MASS | CORRECT_MASS | Green toad (Anaxyrus debilis); typical adult 4-20 g. 0.66 g is an order of magnitude too low. |
| Casuarius_bennetti | 3.08e+04 | ERRONEOUS_MASS | CORRECT_MASS | "Dwarf Cassowary is the SMALLEST cassowary. Published mass range 17.6-26 kg. 30.75 kg exceeds all known records and like |
| Typhlops_jamaicensis | 58.7 | ERRONEOUS_MASS | CORRECT_MASS | Jamaican blindsnake (Typhlopidae); small fossorial species; adults typically 15-30 cm TL; entire Typhlopidae family rare |
| Catla_catla | 1.17e+05 | ERRONEOUS_MASS | CORRECT_MASS | FishBase max 38.6 kg (38600g); some sources cite up to 50 kg; dataset 116900g (116.9 kg) far exceeds all published recor |
| Cebus_yuracus | 3.35e+04 | ERRONEOUS_MASS | CORRECT_MASS | Ecuadorian white-fronted capuchin (Cebidae; Primates); closely related to Cebus albifrons; all Cebus species are small t |
| Trophon_clathratus | 0.0701 | ERRONEOUS_MASS | CORRECT_MASS | Arctic/subarctic muricid (Muricidae; Neogastropoda); also treated as Boreotrophon clathratus in some classifications; sh |
| Cephalorhynchus_commersonii | 4e+06 | ERRONEOUS_MASS | CORRECT_MASS | Commerson's dolphin (Delphinidae; Cetacea); one of the smallest cetaceans; typical adult mass 40-86 kg (40000-86000g) co |
| Cerastes_boehmei | 6.2 | ERRONEOUS_MASS | CORRECT_MASS | Bohme's horned viper; small to medium desert viper; adult length 40-60cm; adult mass typically 100-200g; 6.2g is 16-32x  |
| Chaetopleura_apiculata | 0.0118 | ERRONEOUS_MASS | CORRECT_MASS | Small chiton ~20mm length; Brose_etal_2018 sourced from invertebrate physiology literature that commonly reports AFDW; 0 |
| Boreotrophon_truncatus | 0.0406 | ERRONEOUS_MASS | CORRECT_MASS | Small Arctic muricid snail (Muricidae; Neogastropoda); from Eklof et al. (2013) Kongsfjorden food web via Brose_etal_201 |
| Chironomus_dorsalis | 0.147 | ERRONEOUS_MASS | CORRECT_MASS | Diptera: Chironomidae; Chironomus adults are small non-biting midges 2-10mm body length with typical adult wet mass 0.2- |
| Circeis_armoricana | 0.0118 | ERRONEOUS_MASS | CORRECT_MASS | Circeis armoricana is a spirorbid serpulid worm living in a coiled calcareous tube ~1-2mm diameter; the entire animal is |
| Cirrhilabrus_exquisitus | 2e+03 | ERRONEOUS_MASS | CORRECT_MASS | Exquisite fairy wrasse max ~12 cm TL (Labridae); LWR-estimated adult mass ~15-25g; 2000g (2 kg) is physically impossible |
| Citharichthys_spilopterus | 6.5 | ERRONEOUS_MASS | CORRECT_MASS | Bay whiff flatfish; FishBase max 36.8 cm TL; max published weight 597g; typical adult ~100-300g; /log10(6.5)-log10(200)/ |
| Clibanarius_vittatus | 0.0366 | ERRONEOUS_MASS | CORRECT_MASS | Striped hermit crab (Diogenidae; Decapoda); adults 30-80mm total length with shield length 10-25mm; wet mass ~0.5-8g for |
| Clinocera_stagnalis | 0.000103 | ERRONEOUS_MASS | CORRECT_MASS | Diptera: Empididae (dance flies); Clinocera are aquatic-larva predatory flies with adult body length ~3-7mm; expected ad |
| Cobitis_granoei | 125 | ERRONEOUS_MASS | CORRECT_MASS | Spined loach (Cobitidae); typical Cobitis max weight 5-15g (e.g. Cobitis taenia max 7g on FishBase); 124.6g is ~1.25 log |
| Coluber_fuliginosus | 956 | ERRONEOUS_MASS | CORRECT_MASS | Coluber fuliginosus (Hallowell 1845) is a junior synonym of Atractus fuliginosus; A. fuliginosus is a small ground snake |
| Coptodon_zillii | 1.54 | ERRONEOUS_MASS | CORRECT_MASS | Redbelly tilapia (Cichlidae); max weight 300 g; typical adult 50-200 g (12-22 cm); FishBase LWR (a=0.01514; b=2.99) yiel |
| Corophium_acutum | 0.0174 | ERRONEOUS_MASS | CORRECT_MASS | Tube-building mud amphipod (Corophiidae; Amphipoda); valid accepted name is Apocorophium acutum per WoRMS (Corophium acu |
| Corydalus_cornutus | 0.01 | ERRONEOUS_MASS | CORRECT_MASS | Megaloptera: Corydalidae; Corydalus cornutus is the Eastern Dobsonfly; one of the largest aquatic insects in North Ameri |
| Corynoneura_scutellata | 0.0086 | ERRONEOUS_MASS | CORRECT_MASS | Diptera: Chironomidae (Orthocladiinae); Corynoneura is among the smallest chironomid genera with adult body length 0.5-1 |
| Chodsigoa_smithii | 137 | ERRONEOUS_MASS | CORRECT_MASS | Smith's shrew (Soricidae; Soricomorpha); small shrew from montane forests of Sichuan and Yunnan (China) and adjacent Mya |
| Gymnorhamphichthys_rondoni | 1.64 | ERRONEOUS_MASS | CORRECT_MASS | Sand knifefish (Rhamphichthyidae; Gymnotiformes); slender gymnotiform from Amazon/Orinoco drainages; max TL ~28-38 cm; e |
| Bokermannohyla_alvarengai | 186 | ERRONEOUS_MASS | CORRECT_MASS | Bokermannohyla are medium-sized hylids typically 5-35 g; 185.6 g is ~5-10x too high and inconsistent with the genus. Res |
| Beroe_cucumis | 0.0679 | ERRONEOUS_MASS | NEEDS_REVIEW | Ctenophore class Nuda (Beroida) correct; however 0.068g is ~1.47 log10 units below typical wet mass; adults typically 5- |
| Aedes_aegypti | 8.75e-05 | ERRONEOUS_MASS | CORRECT_MASS | Adult female wet mass well-documented as 1.5-2.5mg; dataset value 0.0875mg is ~25x lower than typical adult female (/log |
| Afrotyphlops_fornasinii | 2.1 | ERRONEOUS_MASS | CORRECT_MASS | Fornasini's blind snake (Typhlopidae); species reaches ~65-70cm SVL; cylinder-volume estimate for a 65cm typhlopid (~4mm |
| Afrotyphlops_mucruso | 966 | ERRONEOUS_MASS | CORRECT_MASS | Mozambique large-scaled blind snake (Typhlopidae); reaches ~70-100cm; even at maximum size a slender typhlopid cannot ap |
| Alpheus_normanni | 0.00405 | ERRONEOUS_MASS | CORRECT_MASS | Snapping shrimp (Alpheidae; Decapoda); adults ~20-25mm TL; congeners A. formosus (0.107g) and A. heterochaelis (0.093g)  |
| Amauropsis_rossiana | 0.01 | ERRONEOUS_MASS | CORRECT_MASS | Antarctic naticid moon snail (Naticidae; Littorinimorpha); Wikipedia gives shell max 29 mm x 25 mm; expected adult wet m |
| Ampelisca_richardsoni | 0.81 | ERRONEOUS_MASS | CORRECT_MASS | Tube-building amphipod (Ampeliscidae; Amphipoda); adults 7-12mm; congeners A. brevicornis (0.0074g); A. diadema (0.0062g |
| Vipera_shemakhensis | 3.2 | ERRONEOUS_MASS | CORRECT_MASS | Shemakha viper from Azerbaijan/South Caucasus; correctly Squamata/Viperidae; adults typically 40-55 cm TL; smallest adul |
| Anilios_nigrescens | 403 | ERRONEOUS_MASS | CORRECT_MASS | Eastern blind snake (Typhlopidae); taxonomy class Squamata correct; adults 30-65cm but extremely slender (~3-5mm diamete |
| Anilios_proximus | 403 | ERRONEOUS_MASS | CORRECT_MASS | Proximate blind snake (Typhlopidae); taxonomy class Squamata correct; one of the larger Australian Anilios reaching ~60- |
| Anilios_unguirostris | 313 | ERRONEOUS_MASS | CORRECT_MASS | Hook-snouted blind snake (Typhlopidae); taxonomy class Squamata correct; medium-sized species ~25-45cm; extremely slende |
| Anilios_waitii | 177 | ERRONEOUS_MASS | CORRECT_MASS | Waite's blind snake (Typhlopidae); taxonomy class Squamata correct; medium-large Australian species reaching ~40-65cm; s |
| Blicca_bjoerkna | 2.32e+03 | ERRONEOUS_MASS | CORRECT_MASS | White bream (Leuciscidae); FishBase max published weight 1000 g; European angling record 1480 g; maximum in optimum cond |
| Anonyx_nugax | 0.00505 | ERRONEOUS_MASS | CORRECT_MASS | Large scavenging amphipod (Uristidae; Amphipoda); adults 30-55mm TL in N. Atlantic/Arctic; known scavenger with substant |
| Archichauliodes_diversus | 0.00432 | ERRONEOUS_MASS | CORRECT_MASS | Megaloptera Corydalidae; Wikipedia confirms larvae grow to 38.5 mm and species is "one of the biggest freshwater insects |
| Archosargus_rhomboidalis | 5.9 | ERRONEOUS_MASS | CORRECT_MASS | Western Atlantic seabream (Sparidae); FishBase max 550g; typical adult at 20 cm ~100-200g; 5.9g is ~1.3-1.5 log units be |
| Argiope_bruennichi | 0.00624 | ERRONEOUS_MASS | "CORRECT_MASS" | "Wasp spider (Araneidae). Females 14-25 mm, known mass 1-4.5 g; even males (4-8 mm) weigh ~5-20 mg. 6.25 mg is ~300x too |
| Arion_distinctus | 0.011 | ERRONEOUS_MASS | CORRECT_MASS | Small terrestrial slug (Arionidae; Stylommatophora); Wikipedia states body extends to about 40 mm; expected adult wet ma |
| Arion_hortensis | 0.022 | ERRONEOUS_MASS | CORRECT_MASS | Garden slug (Arionidae; Stylommatophora); Wikipedia body length 30-50 mm (exceptionally to 50 mm); expected adult wet ma |
| Arion_subfuscus | 0.0311 | ERRONEOUS_MASS | CORRECT_MASS | Dusky slug (Arionidae; Stylommatophora); body typically 40-70 mm when adult; expected adult wet mass 500-5000 mg; datase |
| Asterias_forbesi | 0.932 | ERRONEOUS_MASS | CORRECT_MASS | Forbes sea star; typical adult arm radius 7-12 cm; adult wet mass 10-400 g; dataset 0.9319 g is ~2.0 log10 units below t |
| Atlantoraja_cyclophora | 55 | ERRONEOUS_MASS | CORRECT_MASS | Taxonomy correct: Rajiformes; Arhynchobatidae; eyespot skate; FishBase max TL 68.5 cm; adult specimens at 50-68 cm TL ex |
| Aurelia_aurita | 5 | ERRONEOUS_MASS | CORRECT_MASS | Adult bell 25-40cm; expected adult wet mass 200-2000g (95-96% water); Hirst 1998 is a metabolic-rate study that likely r |
| Austroperla_cyrene | 3.09e-05 | ERRONEOUS_MASS | CORRECT_MASS | Plecoptera Austroperlidae; adult stonefly with aposematic coloration described in Wikipedia; any adult stonefly should w |
| Bathytoshia_centroura | 149 | ERRONEOUS_MASS | CORRECT_MASS | Taxonomy correct: Myliobatiformes; Dasyatidae; roughtail stingray (formerly Dasyatis centroura); FishBase max disc width |
| Anonyx_sarsi | 0.0074 | ERRONEOUS_MASS | CORRECT_MASS | Scavenging amphipod (Uristidae; Amphipoda); adults 20-40mm TL; expected wet mass 0.05-0.6g; dataset 0.007402g (7.4mg) is |
| Craugastor_laticeps | 80 | ERRONEOUS_MASS | CORRECT_MASS | Even large Craugastor species rarely exceed 40-50 g; 80 g is implausibly high. Residual +1.79 confirms large over-shoot. |
| Crangon_affinis | 0.0506 | ERRONEOUS_MASS | CORRECT_MASS | Crangonid sand shrimp (Crangonidae; Decapoda); East Asian coastal species; adults 30-60mm TL; congener C. crangon typica |
| Crotalus_unicolor | 14 | ERRONEOUS_MASS | CORRECT_MASS | Aruba Island Rattlesnake; lit adult weight 900-1400g (avg ~1kg); dataset value 14g is approximately 70x below literature |
| Enithares_sobria | 0.00012 | ERRONEOUS_MASS | CORRECT_MASS | Hemiptera: Notonectidae backswimmer; body length 8-16mm; dataset 0.12mg is ~100-166x below literature minimum (~5mg) for |
| Entelurus_aequoreus | 432 | ERRONEOUS_MASS | CORRECT_MASS | Snake pipefish (Syngnathidae); extremely slender body form; max TL ~60 cm but cross-section only ~6-8 mm; FishBase Bayes |
| Epinephelus_malabaricus | 2.46e+05 | ERRONEOUS_MASS | CORRECT_MASS | Malabar grouper (Serranidae); FishBase max published weight ~150 kg (max TL 234 cm); dataset value 246.2 kg exceeds publ |
| Epinephelus_tauvina | 1.41e+05 | ERRONEOUS_MASS | CORRECT_MASS | Greasy grouper (Serranidae); FishBase max published weight ~44 kg (max TL 94 cm); dataset value 141.4 kg is ~3.2x the pu |
| Etropus_crossotus | 3.6 | ERRONEOUS_MASS | CORRECT_MASS | Fringed flounder (Paralichthyidae); max TL ~20-23 cm; typical adult weight 30-100 g; 3.6 g is ~1.1-1.7 log10 below expec |
| Eunoe_hartmanae | 57 | ERRONEOUS_MASS | CORRECT_MASS | Eunoe is a genus of Polynoidae (scale worms); all known polynoid scale worms are small (typically <10cm; rarely >5-10g); |
| Euphausia_krohni | 0.004 | ERRONEOUS_MASS | CORRECT_MASS | Mesopelagic krill (Euphausiidae; Euphausiacea); valid species name is Euphausia krohnii (Brandt 1851); krohni is alterna |
| Euphausia_krohnii | 0.00171 | ERRONEOUS_MASS | CORRECT_MASS | Mesopelagic krill (Euphausiidae; Euphausiacea); same species as Euphausia_krohni (alternate spelling); adults 12-22mm TL |
| Tor_putitora | 1.26e+05 | ERRONEOUS_MASS | CORRECT_MASS | 126500g (126.5 kg) exceeds FishBase published max of 54 kg by 2.3-fold; typical large golden mahseer adult 5-20 kg; /log |
| Floridichthys_polyommus | 213 | ERRONEOUS_MASS | CORRECT_MASS | Seminole killifish (Cyprinodontidae); max TL ~5.5 cm; congeneric F. carpio (4.4 cm TL) = 1.8 g (Pauly 2024); FishBase Wm |
| Gallotia_simonyi | 1.86e+03 | ERRONEOUS_MASS | CORRECT_MASS | El Hierro giant lizard; extant but critically endangered; SVL approximately 19-22cm; total length ~51-60cm; multiple sou |
| Gammarus_daiberi | 0.00118 | ERRONEOUS_MASS | CORRECT_MASS | Large estuarine amphipod (Gammaridae; Amphipoda); adults 15-25mm body length; typical adult wet mass 20-250mg based on G |
| Gammarus_fasciatus | 0.00118 | ERRONEOUS_MASS | CORRECT_MASS | Freshwater scud (Gammaridae; Amphipoda); adults 10-23mm body length; typical adult wet mass 10-150mg based on published  |
| Gammarus_mucronatus | 0.00118 | ERRONEOUS_MASS | CORRECT_MASS | Estuarine amphipod (Gammaridae; Amphipoda); smaller species with adults 5-12mm; typical adult wet mass 3-40mg; dataset v |
| Gammarus_tigrinus | 0.00118 | ERRONEOUS_MASS | CORRECT_MASS | Invasive amphipod introduced to Europe (Gammaridae; Amphipoda); adults 8-15mm body length; typical adult wet mass 4-60mg |
| Garra_gotyla | 779 | ERRONEOUS_MASS | CORRECT_MASS | Sucker fish (Cyprinidae); FishBase Wmax 779 g is a major outlier among all Garra species in FishBase (next largest: G. o |
| Garra_imberba | 522 | ERRONEOUS_MASS | CORRECT_MASS | East African stream cyprinid (Cyprinidae) from Ethiopia; FishBase value retrieved via Cai et al. 2025; 522 g is an extre |
| Genyatremus_cavifrons | 10 | ERRONEOUS_MASS | CORRECT_MASS | South American grunt (Haemulidae); FishBase Wmax of 10 g is biologically implausible for a Haemulidae; haemulids typical |
| Glomeris_connexa | 0.000382 | ERRONEOUS_MASS | "CORRECT_MASS" | "Pill millipede (Glomeridae), adults 10-20 mm. 0.38 mg is impossibly small; adult Glomeris species weigh 200-600 mg. Thi |
| Tor_barakae | 24.1 | ERRONEOUS_MASS | CORRECT_MASS | 24.1g is juvenile mass; Tor barakae is a mahseer from the Barito River drainage of Borneo (Kalimantan); even small Tor s |
| Tilapia_sparrmanii | 7.19 | ERRONEOUS_MASS | CORRECT_MASS | 7.19g is juvenile mass; adult banded tilapia (southern Africa; Cichlidae) typically 50-300g; max TL ~22 cm corresponds t |
| Thamnophis_saurita | 1.5e+03 | ERRONEOUS_MASS | CORRECT_MASS | Eastern ribbon snake (Colubridae); one of the SMALLEST and most slender Thamnophis; adults 45-65cm TL with very slender  |
| Gonatus_pyros | 3.84 | ERRONEOUS_MASS | NEEDS_REVIEW | Gonatid squid (family Gonatidae); Cephalopoda correct; even small Gonatus spp. adults typically 20-500 g; 3.84 g is ~1.4 |
| Craugastor_rugulosus | 75 | ERRONEOUS_MASS | CORRECT_MASS | Large-bodied Craugastor but 75 g is implausibly high; typical adults 5-40 g. Residual +1.76 confirms error. |
| Elops_lacerta | 70.1 | ERRONEOUS_MASS | CORRECT_MASS | West African tenpounder (Elopidae); large elongated pelagic fish; max TL ~100 cm; adults commonly 2-10 kg (comparable to |
| Engraulis_japonicus | 180 | ERRONEOUS_MASS | CORRECT_MASS | Japanese anchovy (Engraulidae); small pelagic schooling fish; max TL ~20 cm; FishBase Bayesian LWR max weight ~49g; typi |
| Eleutherodactylus_cubanus | 0.18 | ERRONEOUS_MASS | CORRECT_MASS | Cuban Eleutherodactylus; even the smallest species in genus typically 0.5 g+. 0.18 g is below the plausible minimum for  |
| Crychus_caraboides | 0.392 | ERRONEOUS_MASS | CORRECT_MASS | Coleoptera: Agyrtidae; Crychus is a junior synonym of Apteroloma (residuals DB resolves genus to Apteroloma; class assig |
| Culter_alburnus | 8.98e+03 | ERRONEOUS_MASS | CORRECT_MASS | Topmouth culter (Xenocyprididae); FishBase max published weight 600 g (Ref. 56557); dataset 8977 g is ~15x above documen |
| Triturus_vulgaris | 73.5 | ERRONEOUS_MASS | CORRECT_MASS | Smooth newt (Lissotriton vulgaris); typical adult 1-6 g. 73.48 g is ~15-20x too high; likely a data-entry or unit conver |
| Cynoscion_virescens | 39.2 | ERRONEOUS_MASS | CORRECT_MASS | Green weakfish (Sciaenidae); source Viana_2016; FishBase max TL ~80 cm; using Cynoscion LWR comparable to C. leiarchus;  |
| Dactyloptena_tiltoni | 4.3 | ERRONEOUS_MASS | CORRECT_MASS | Plain helmet gurnard (Dactylopteridae); FishBase lists no published weight and max 9.5 cm SL; 2024 Thalassas paper (DOI  |
| Dalopius_marginatus | 0.000312 | ERRONEOUS_MASS | CORRECT_MASS | Coleoptera: Elateridae (click beetles); Dalopius marginatus is a European click beetle with body length ~7-9mm; expected |
| Tritogonia_verrucosa | 1.12e+03 | ERRONEOUS_MASS | CORRECT_MASS | Warty-back mussel (Unionidae); North American freshwater mussel; shell 60-110mm; Quaardvark; 1120g (1.12 kg) is 7-100x a |
| Trisopterus_esmarkii | 11.6 | ERRONEOUS_MASS | CORRECT_MASS | Norway pout (Gadidae); max TL 35cm; common TL 19cm; max weight estimated ~300-440g for adult; LWR at common length (19cm |
| Triakis_megalopterus | 145 | ERRONEOUS_MASS | CORRECT_MASS | Taxonomy correct: Carcharhiniformes; Triakidae; spotted gully shark (sharptooth houndshark); South African endemic reach |
| Dasypeltis_abyssina | 5.7 | ERRONEOUS_MASS | CORRECT_MASS | Ethiopian egg-eater; adults 80-120cm TL; congener D. scabra (similar length) has confirmed adult mass ~72g; 5.7g is impl |
| Diaphus_coeruleus | 0.1 | ERRONEOUS_MASS | CORRECT_MASS | Blue lanternfish (Myctophidae); max 13.7 cm TL; Diaphus spp. LWR gives ~5-13g for typical adult (a~0.0044; b~3.13); othe |
| Eleutherodactylus_johnstonei | 24 | ERRONEOUS_MASS | CORRECT_MASS | Johnstone's whistling frog; well-studied small Caribbean species, adults typically 2-8 g. 24 g is ~5x too high; likely u |
| Diaphus_knappi | 0.1 | ERRONEOUS_MASS | CORRECT_MASS | Small lanternfish (Myctophidae); max 17.3 cm TL; Diaphus spp. LWR gives ~10-25g for adults at this max size; 0.1g is 2.1 |
| Dicranota_exclusa | 0.000375 | ERRONEOUS_MASS | CORRECT_MASS | Diptera: Pediciidae (hairy-eyed crane flies); Dicranota are medium-sized crane flies with aquatic predatory larvae; adul |
| Diodon_hystrix | 1.15e+04 | ERRONEOUS_MASS | CORRECT_MASS | FishBase max published weight 2800 g at max 91 cm TL; common length 40 cm corresponds to ~200-500 g by LWR; dataset 1148 |
| Diura_bicaudata | 0.000371 | ERRONEOUS_MASS | CORRECT_MASS | Plecoptera: Perlodidae (stoneflies); Diura bicaudata is a medium-large Scandinavian/northern European stonefly; nymph bo |
| Echinorhinus_brucus | 76 | ERRONEOUS_MASS | CORRECT_MASS | Taxonomy correct: Squaliformes; Echinorhinidae; bramble shark; FishBase max TL ~310 cm; adults commonly 150-260 cm; expe |
| Trematomus_bernacchii | 2.52 | ERRONEOUS_MASS | CORRECT_MASS | 2.52g is impossible for adult emerald rockcod; species max TL ~38 cm; FishBase max weight ~490g; typical adult 100-400g; |
| Eirenis_persicus | 142 | ERRONEOUS_MASS | CORRECT_MASS | Persian dwarf racer; adults only 27-35cm (max 37.1cm); 142.5g is implausibly heavy for a 37cm slender colubrid; estimate |
| Eleotris_amblyopsis | 6.1 | ERRONEOUS_MASS | CORRECT_MASS | Caribbean sleeper (Eleotridae); max TL 32 cm; FishBase Bayesian LWR estimates max weight ~550g; typical adult 50-300g; 6 |
| Elephantulus_fuscus | 540 | ERRONEOUS_MASS | CORRECT_MASS | Dusky elephant shrew (Macroscelididae; Macroscelidea); adult mass typically 25-75g (mean ~50g); dataset 540g is ~10x typ |
| Eleutherodactylus_coqui | 44.8 | ERRONEOUS_MASS | CORRECT_MASS | Puerto Rican coqui; iconic small frog, adults typically 2-5 g. 44.78 g is ~10x too high; possibly multi-source average c |
| Diaphus_theta | 0.17 | ERRONEOUS_MASS | CORRECT_MASS | California headlightfish (Myctophidae); max 11.4 cm TL; maturity ~6 cm; Diaphus spp. LWR gives ~2-7g for adults; 0.17g i |
| Ruvettus_pretiosus | 2.15e+05 | ERRONEOUS_MASS | CORRECT_MASS | Oilfish (Scombriformes: Gempylidae); large pelagic deep-sea predator; FishBase max published weight 63.5 kg (63500 g); d |
| Tetraphyllidean_larva | 8.52e-05 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Tetraphyllidea is an order of parasitic cestodes (tapeworms; phylum Platyhelminthes; class Cestoda); entirely unrelated  |
| Trapelus_savignyi | 49.7 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Sand agama (Agamidae); Middle East (Egypt; Jordan; Israel; Syria); in the residuals database this taxon entry is filed u |
| Scleroderma_macrogaster | 0.0023 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Taxonomy lookup matched to Ichneumonidae genus Syrphoctonus which is incorrect; Scleroderma macrogaster is family Bethyl |
| Talorchestia_megalophthalma | 0.204 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Record stored under old synonymous genus; current accepted name is Americorchestia megalophthalma (Bate; 1862) per WoRMS |
| Sphaerotilus_natans | 6.5e-12 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | "Sphaerotilus natans is a filamentous sheathed bacterium in family Comamonadaceae, order Burkholderiales, class Betaprot |
| Achromobacter_ruhlandii | 2e-13 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | "Achromobacter ruhlandii (family Alcaligenaceae, order Burkholderiales) is class Betaproteobacteria, not Gammaproteobact |
| Pontogeneia_antarctica | 0.005 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Record stored under old synonymous genus; current accepted name is Gondogeneia antarctica (Chevreux; 1906) per WoRMS; ge |
| Amphisbaena_neglecta | 1.19 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | taxon_class_dataset is Eubacteriales which is a bacterial order (phylum Firmicutes/Bacillota) — not a reptile class; Amp |
| Brachyuran_larvae | 0.009 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | "Brachyuran larvae are decapod crustacean larvae (order Decapoda, class Malacostraca). Actinomycetes is a bacterial clas |
| Casurarius_bennetti | 1.76e+04 | ERRONEOUS_TAXONOMY | REMOVE | "'Casurarius' is a misspelling of 'Casuarius'. This is a duplicate/misspelled entry for Casuarius bennetti, which alread |
| Celestus_anelpistus | 600 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | TAXONOMY ERROR: taxon_class listed as Coleoptera (insect order — beetles) but this is a diploglossid lizard (Squamata);  |
| Cyclodomorphus_maximus | 326 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Giant Slender Bluetongue (Scincidae) from Western Australia; taxon_class field = Squamata which is CORRECT; however the  |
| Dasyatis_americana | 9.48e+04 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Taxonomy ERRONEOUS: Dasyatis americana is a junior synonym of Hypanus americanus (southern stingray); genus Dasyatis sen |
| Dasyatis_centroura | 1.59e+05 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Taxonomy ERRONEOUS: Dasyatis centroura is a junior synonym of Bathytoshia centroura (roughtail stingray); genus Dasyatis |
| Dasyatis_lata | 2.9e+05 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Taxonomy ERRONEOUS: Dasyatis lata is a junior synonym of Bathytoshia lata (brown stingray); genus Dasyatis was revised a |
| Edaphus_bluhweissi | 6.53e-05 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Coleoptera: Staphylinidae (Pselaphinae rove beetles); residuals DB resolves this entry to species Edaphus lederi (confid |
| Eschrichtus_robustus | 3.18e+07 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Genus name misspelled: Eschrichtus should be Eschrichtius; DB canonical correctly shows Eschrichtius robustus; dataset m |
| Eutemora_hirundoides | 6.96e-05 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Eutemora (Eurytemora) hirundoides is a calanoid copepod (Crustacea: Hexanauplia: Temoridae); not an insect; dataset orde |
| Glyptotherium_cylindricum | 5.63e+05 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Database corruption: order stored as Solanales (plant order) and family as Solanaceae (plant family); correct order is C |
| Glyptotherium_floridanum | 1.1e+06 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Database corruption: order stored as Agaricales (fungal order) and family as Entolomataceae (fungal family); correct ord |
| Glyptotherium_mexicanum | 1.1e+06 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Database corruption: order stored as Decapoda (crustacean order) and family as Porcellanidae (porcelain crabs); correct  |
| Scarabaeus_striatum | 0.79 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Taxonomy lookup layer assigned family Epitoniidae (genus Epitonium) which is a marine gastropod family (Mollusca:Caenoga |
| Kampylaster_incurvatus | 0.061 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Kampylaster incurvatus is an ophiuroid (brittle star; class Ophiuroidea); incorrectly listed as Asteroidea; mass 0.061 g |
| Melicerita_obliqua | 0.69 | ERRONEOUS_TAXONOMY | https://www.marinespecies.org/aphia.php?p=taxdetails&id=111445 | CORRECT_TAXONOMY,Melicerita (family Meliceritidae) is a cyclostome bryozoan; Order Cyclostomata belongs to Class Stenola |
| Mugil_chelo | 4.91e+03 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Mugil chelo is a junior synonym; current valid name is Chelon labrosus (thicklip grey mullet; Mugilidae); residuals pipe |
| Myxus_capensis | 1.8e+03 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Myxus capensis is a synonym; current valid name is Pseudomyxus capensis (Cape mullet / freshwater springer; Mugilidae);  |
| Neisseria_elongata | 2e-13 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | "Neisseria elongata (family Neisseriaceae) is class Betaproteobacteria, not Gammaproteobacteria. Mass 0.2 pg plausible f |
| Neisseria_flava | 2e-13 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | "Neisseria flava (family Neisseriaceae) is class Betaproteobacteria, not Gammaproteobacteria. Mass 0.2 pg plausible for  |
| Neisseria_gonorrhoeae | 2e-13 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | "Neisseria gonorrhoeae (family Neisseriaceae, order Neisseriales) is class Betaproteobacteria in NCBI taxonomy, not Gamm |
| Neisseria_mucosa | 2e-13 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | "Neisseria mucosa (family Neisseriaceae) is class Betaproteobacteria, not Gammaproteobacteria. Mass 0.2 pg plausible for |
| Omnivorous_nematodes | 6.02e-05 | ERRONEOUS_TAXONOMY | REMOVE | NOT an insect: nematodes (roundworms) belong to Phylum Nematoda; not Insecta or Coleoptera/Eucnemidae as classified; als |
| Order_coleoptera | 0.000665 | ERRONEOUS_TAXONOMY | REMOVE | NOT a valid species name: Order_coleoptera is an order-level descriptor not a species; classifier incorrectly assigned t |
| Order_isopoda |  | ERRONEOUS_TAXONOMY | REMOVE | Not a valid binomial species name; Isopoda is a taxonomic Order-rank label within Malacostraca; likely a data-entry erro |
| Orgygia_detrita | 0.314 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Genus name misspelled in dataset: Orgygia is not valid; correct genus is Orgyia (family Erebidae; Lepidoptera); Orgyia d |
| Orygia_pseudotsugata | 0.145 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Genus name misspelled in dataset: Orygia is not valid; correct genus is Orgyia (family Erebidae; Lepidoptera); Orgyia ps |
| Pagurus_prideauxi |  | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | WoRMS status: misspelling (incorrect subsequent spelling); accepted name is Pagurus prideaux Leach 1815; Decapoda; Pagur |
| Paracallisoma_coecus |  | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | WoRMS: unaccepted name (new combination); valid name is Pseudocallisoma coecum (Holmes 1908); Amphipoda; Scopelocheirida |
| Xaymaca_fulvopulvis | 160 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Database assigns family Heptaxodontidae (large extinct hutias weighing 5-20 kg); however Faurby_etal_2018 source (PHYLAC |
| Xenorhinotherium_bahiense | 9.41e+05 | ERRONEOUS_TAXONOMY | CORRECT_TAXONOMY | Order field in database reads Xylariales (an Ascomycete fungal order) — clearly erroneous; correct order is Litopterna p |

## Sources with systematic errors in SUSPICIOUS tier (≥2 erroneous records)

| Source | n_erroneous_records | Taxa |
|--------|--------------------|----|
| Brose_etal_2018 | 72 | Alpheus_normanni; Amauropsis_rossiana; Ampelisca_richardsoni; Anonyx_nugax; Anonyx_sarsi; Archichaul |
| Feldman_etal_2016 | 37 | Afrotyphlops_fornasinii; Afrotyphlops_mucruso; Anilios_nigrescens; Anilios_proximus; Anilios_unguiro |
| Cai_etal_2025 | 26 | Blicca_bjoerkna; Bokermannohyla_alvarengai; Casuarius_bennetti; Catla_catla; Cephalorhynchus_commers |
| fishbase | 22 | Atlantoraja_cyclophora; Bathytoshia_centroura; Blicca_bjoerkna; Echinorhinus_brucus; Engraulis_japon |
| Makarieva_2008 | 15 | Bufo_debilus; Crangon_affinis; Eleutherodactylus_coqui; Engraulis_japonicus; Gonatus_pyros; Hemichro |
| DeLong_etal_2018 | 11 | Aedes_aegypti; Enithares_sobria; Lygus_hesperus; Mamestra_brassicae; Notonecta_glauca; Orius_sauteri |
| Quaardvark | 9 | Casuarius_bennetti; Cephalorhynchus_commersonii; Cirrhilabrus_exquisitus; Crotalus_unicolor; Diodon_ |
| AmphiBIO | 8 | Craugastor_laticeps; Craugastor_rugulosus; Eleutherodactylus_cubanus; Hypsiboas_faber; Hypsiboas_ros |
| Viana_2016 | 8 | Archosargus_rhomboidalis; Citharichthys_spilopterus; Cynoscion_virescens; Etropus_crossotus; Lutjanu |
| Meiri_2018 | 6 | Gallotia_simonyi; Lygosoma_corpulentum; Oligosoma_northlandi; Omanosaura_jayakari; Shinisaurus_croco |
| Brown_etal_2018 | 4 | Cephalorhynchus_commersonii; Engraulis_japonicus; Euphausia_krohni; Trisopterus_esmarkii |
| Castro_2025 | 4 | Beroe_cucumis; Coptodon_zillii; Euphausia_krohnii; Oneirodes_acanthias |
| Pauly_2024 | 4 | Jordania_zonope; Opsanus_pardus; Orthonopias_triacis; Sebastes_itinus |
| Smith_2003 | 3 | Cephalorhynchus_commersonii; Chodsigoa_smithii; Palaeoloxodon_naumanni |
| AnAge | 3 | Casuarius_bennetti; Cephalorhynchus_commersonii; Varanus_exanthematicus |
| Faurby_etal_2018 | 3 | Cephalorhynchus_commersonii; Chodsigoa_smithii; Elephantulus_fuscus |
| Wilman_etal_2014 | 3 | Casuarius_bennetti; Menura_alberti; Psittinus_cyanurus |
| CalCOFI | 3 | Diaphus_coeruleus; Diaphus_knappi; Diaphus_theta |
| Hirt_etal_2017 | 2 | Gallotia_simonyi; Squalinus_cephalus |
| fishbase; Froese_2014 | 2 | Eleotris_amblyopsis; Hypopomus |
| Bojsen_2005 | 2 | Knodus_gamma; Prionobrama_filigera |

---
_Generated by scripts/audit_synthesis_suspicious.py_
