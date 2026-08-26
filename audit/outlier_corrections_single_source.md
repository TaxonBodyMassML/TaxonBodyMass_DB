# Single-Source Body Mass Outlier Corrections

This document is the record of body mass values that a Claude audit found to be potentiallyproblematic.
Manually-confirmed corrections have been added to the lab's GoogleSheet override (BM_data tab).

Each entry provides:
- The erroneous value recorded in the source database
- The suggested corrected value
- A biological justification for the correction
- A primary reference URL (from the verification audit)
- Peer-reviewed citations with DOIs (added via literature search)

**Tiers:**
- **Confirmed** — discrepancy is unambiguous (>1 log₁₀ unit or biologically impossible)
- **Suspicious** — smaller discrepancy; correction is plausible but less certain

---

## Tier: Confirmed

### Source: Brose etal 2018

#### *Acetes americanus*

| | |
|---|---|
| **Database value** | 1.506e-04 g |
| **Corrected value** | 0.04 g |
| **Literature range** | 0.01 g – 0.04 g – 0.12 g |
| **Tier** | Confirmed (CRITICAL) |

*Sergestid shrimp 10-44mm length (Wikipedia confirmed); congener A. japonicus = 70.91mg per SeaLifeBase; dataset 0.1506mg is ~2.7 log10 below congener; same Brose_etal_2018 source pattern as other underestimated small invertebrates; likely mg-to-g unit error*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Acetes_americanus>

**Peer-reviewed citations:**

- Simões SM, D'Incao F, Fransozo A, Castilho AL, Costa RC (2013). Sex ratio, growth and recruitment of the pelagic shrimp Acetes americanus on the southeastern coast of Brazil. Journal of Crustacean Biology, 33(3), 394–402. https://doi.org/10.1163/1937240x-00002108
  - *No mass measured; body lengths 10–20 mm TL reported for adults, consistent with the 10–44 mm range cited for the taxon*
- Arshad A, Nurul Amin SM, Siraj SS, Japar SB (2007). New Distribution Records of Sergestid Shrimp, Acetes intermedius (Decapoda: Sergestidae) from Peninsular Malaysia with Notes on its Population Characteristics. Journal of Biological Sciences, 7(8), 1305–1313. https://doi.org/10.3923/jbs.2007.1305.1313
  - *Mass reported: 0.211 g — Asymptotic weight 211.21 mg for A. intermedius at L∞ = 34.65 mm; LWR extrapolation to A. americanus mean adult lengths (12–20 mm) yields ~7–35 mg*
- Santos APF, Simões SM, Bochini GL, Costa CHC, Costa RC (2015). Population parameters and the relationships between environmental factors and abundance of the Acetes americanus shrimp (Dendrobranchiata: Sergestidae) near a coastal upwelling region of Brazil. Brazilian Journal of Oceanography, 63(3), 229–238. https://doi.org/10.1590/s1679-87592015086206303
  - *No mass measured; larger individuals reported from lower-latitude populations, consistent with the broad 10–44 mm size range for the taxon*

---

#### *Anocha lyolepis*

| | |
|---|---|
| **Database value** | 8 g |
| **Corrected value** | 2.000e-04 g |
| **Literature range** | 5.000e-05 g – 2.000e-04 g – 0.001 g |
| **Tier** | Confirmed (CRITICAL) |

*Genus Anocha confirmed as Cecidomyiidae (gall midges; Diptera); adults 0.5-3mm; expected mass <1mg; 8g is ~4 log10 units above typical; species epithet lyolepis not found in known Anocha species list*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Cecidomyiidae>

**Peer-reviewed citations:**

> *No peer-reviewed mass data retrieved from Semantic Scholar / OpenAlex / Europe PMC searches. See primary reference URL above.*

---

#### *Argiope bruennichi*

| | |
|---|---|
| **Database value** | 0.006245 g |
| **Corrected value** | 2 g |
| **Literature range** | 0.5 g – 2 g – 4.5 g |
| **Tier** | Confirmed (SUSPICIOUS) |

*"Wasp spider (Araneidae). Females 14-25 mm, known mass 1-4.5 g; even males (4-8 mm) weigh ~5-20 mg. 6.25 mg is ~300x too small for a female. Likely a severe unit error (µg or mg recorded as g, or female/male ID confusion with additional unit error)."*

**Peer-reviewed citations:**

K. Weiss, J. Ruch, S. S. Zimmer, and J. M. Schneider. Does sexual cannibalism secure genetic benefits of polyandry in a size-dimorphic spider? Behavioral Ecology and Sociobiology, 74(9):110, 2020.

---

#### *Ascia monuste*

| | |
|---|---|
| **Database value** | 6.828 g |
| **Corrected value** | 0.35 g |
| **Literature range** | 0.1 g – 0.35 g – 0.8 g |
| **Tier** | Confirmed (CRITICAL) |

*Great Southern White Pieridae butterfly; confirmed wingspan 63-86mm; typical adult mass ~0.1-0.8g; 6.828g is ~1.3 log10 too high*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Ascia_monuste>

**Peer-reviewed citations:**

H. C. Barros-Bellanda and F. S. Zucoloto. Effects of intraspecific competition and food deprivation on the immature phase of ascia monuste orseis (lepidoptera, pieridae). Iheringia. S´erie Zoologia, 92(1):93–98, 2002.

---

#### *Baseodiscus antarcticus*

| | |
|---|---|
| **Database value** | 5,800 g |
| **Corrected value** | 50 g |
| **Literature range** | 5 g – 50 g – 200 g |
| **Tier** | Confirmed (CRITICAL) |

*Related Baseodiscus mexicanus is 1-2m long × 5-7mm wide (est. wet mass ~40g); world's heaviest nemertean (Parborlasia corrugatus) is only 100-140g; 5800g far exceeds all known nemertean masses; likely duplicated value shared with Lineus_longifissus and Parborlasia_corrugatus entries in Brose et al. 2018*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Baseodiscus>

**Peer-reviewed citations:**

- Gibson, R. (1985). Antarctic nemerteans: Heteronemertea - descriptions of new taxa, reappraisals of the systematic status of existing species and a key to the heteronemerteans recorded south of latitude 50°S. Zoological Journal of the Linnean Society, 83(2), 95-227. https://doi.org/10.1111/j.1096-3642.1985.tb01176.x
  - *Primary taxonomic monograph describing Baseodiscus antarcticus gen. et sp. nov. among 23 heteronemertean species from Antarctic and subantarctic waters. Full text inaccessible; morphological dimensions in the species description constrain expected body size but mass values were not retrievable from available metadata.*
- Jacob, U., Thierry, A., Brose, U., Arntz, W. E., Berg, S., Brey, T., Fetzer, I., Jönsson, T., Mintenbeck, K., Möllmann, C., Petchey, O. L., Riede, J. O., & Dunne, J. A. (2011). The Role of Body Size in Complex Food Webs. Advances in Ecological Research, 45, 181-223. https://doi.org/10.1016/b978-0-12-386475-8.00005-8
  - *Compiled body-mass data for Weddell Sea shelf food-web species spanning 22 orders of magnitude; co-authored by Antarctic benthos specialists (Arntz, Brey, Mintenbeck). Full species-level appendix not accessible; cannot confirm whether Baseodiscus antarcticus appears individually in the dataset.*
- Clarke, A., & Prothero-Thomas, E. (1997). The Influence of Feeding on Oxygen Consumption and Nitrogen Excretion in the Antarctic Nemertean Parborlasia corrugatus. Physiological Zoology, 70(6), 639-649. https://doi.org/10.1086/515868
  - *Feeding experiments conducted at ration levels of 20-110% of individual body mass for the large Antarctic nemertean Parborlasia corrugatus; absolute body mass values not reported in the abstract. Parborlasia corrugatus is a much larger species than Baseodiscus antarcticus.*

---

#### *Cheirocratus sundevalli*

| | |
|---|---|
| **Database value** | 4.010e-05 g |
| **Corrected value** | 5.000e-04 g |
| **Literature range** | 1.000e-04 g – 5.000e-04 g – 0.002 g |
| **Tier** | Confirmed (CRITICAL) |

*Small benthic amphipod (family Aoridae); adults typically 3-6mm; comparable Brose source amphipod Liljeborgia_kinahani (5-10mm) has estimated typical mass 1-10mg; dataset 0.04mg is ~1.1-1.5 log10 below minimum expected; likely mg-to-g unit error in Brose_etal_2018*

**Peer-reviewed citations:**

- Bitton et al. (2019). Visual modelling supports the potential for prey detection by means of diurnal active photolocation in a small cryptobenthic fish. Scientific Reports. https://doi.org/10.1038/s41598-019-44529-0
  - *Reports Cheirocratus gammarids (genus Cheirocratus, collected at 5–10 m depth) as 'full length 3–4 mm'; no body mass reported, but directly constrains body length of this genus.*
- Shokri et al. (2022). Metabolic rate and climate change across latitudes: evidence of mass-dependent responses in aquatic amphipods. Journal of Experimental Biology. https://doi.org/10.1242/jeb.244842
  - *Mass reported: 0.00427 g — Dry mass range 0.4–13.57 mg (mean 4.27 mg) for Gammarus insensibilis (4.74–15.90 mm body length) from the Adriatic coast; the smallest individuals approach 0.4 mg, and allometric extrapolation to the 3–4 mm body length of Cheirocratus is consistent with the corrected ~0.5 mg estimate.*

---

#### *Cheyletia wellsi*

| | |
|---|---|
| **Database value** | 4.830e-07 g |
| **Corrected value** | 3.000e-07 g |
| **Literature range** | 1.000e-07 g – 3.000e-07 g – 1.000e-06 g |
| **Tier** | Confirmed (CRITICAL) |

*"Cheyletid predatory mite (~0.3-0.5 mm body). Mass of 0.483 ng is impossible for a visible mite; expected 0.1-1 µg range. Likely a ~1000x unit error (pg recorded instead of ng, or ng instead of µg)."*

**Peer-reviewed citations:**

> *No peer-reviewed mass data retrieved from Semantic Scholar / OpenAlex / Europe PMC searches. See primary reference URL above.*

---

#### *Cratena pilata*

| | |
|---|---|
| **Database value** | 1.719e-04 g |
| **Corrected value** | 0.05 g |
| **Literature range** | 0.005 g – 0.05 g – 0.5 g |
| **Tier** | Confirmed (CRITICAL) |

*Body 8-24mm (SeaLifeBase); size-based wet mass estimate 5-500mg; dataset 0.172mg is 2-3 log10 units below size estimate; lit_mass values are size-derived estimates; no published mass data found but discrepancy is extreme*

**Primary reference (audit):** <https://www.sealifebase.se/summary/Cratena-pilata.html>

**Peer-reviewed citations:**

> *No peer-reviewed mass data retrieved from Semantic Scholar / OpenAlex / Europe PMC searches. See primary reference URL above.*

---

#### *Eriphia smithii*

| | |
|---|---|
| **Database value** | 0.01 g |
| **Corrected value** | 80 g |
| **Literature range** | 20 g – 80 g – 300 g |
| **Tier** | Confirmed (CRITICAL) |

*Valid Indo-Pacific species listed in genus Eriphia (Eriphiidae; Wikipedia confirmed); all Eriphia are medium-to-large robust crabs with heavy claws; minimum adult mass ~20g; dataset 10mg is ~3.9-4.9 log10 below adult minimum; same 0.01g value seen for other Brose_etal_2018 crabs (e.g. Xantho_pilipes); likely catastrophic unit error*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Eriphia>

**Peer-reviewed citations:**

- Tomikawa, N. & Watanabe, S. (1992). Reproductive ecology of the xanthid crab Eriphia smithii McLeay. Journal of Crustacean Biology, 12(1), 57–67. https://doi.org/10.2307/1548719
  - *Body mass explicitly measured to nearest 0.1 g using an electric balance during field tagging experiments; specific specimen values are in the full text (paywalled). Adult Indo-Pacific Eriphia smithii; consistent with corrected value of ~80 g.*
- Kuzmanić, P. & Nerlović, V. (2024). Some biological and morphological aspects of Eriphia verrucosa (Forskål, 1775) in the eastern Adriatic Sea. ST-OPEN, 5. https://doi.org/10.48188/so.5.4
  - *Body mass range 7.3–263.6 g for congener Eriphia verrucosa (Mediterranean); length-weight regression W = 0.0076 × CL^2.5086. Most common size class 45–50 mm CL. A typical adult male weighed ~80–150 g.*

---

#### *Fissurella clenchi*

> **Status:** NEEDS_REVIEW — no single verified value; range given

| | |
|---|---|
| **Database value** | 0.03073 g |
| **Corrected value** | 3 g |
| **Tier** | Confirmed (CRITICAL) |

*Related Caribbean Fissurella spp. (F. nodosa; F. rosea) have shells 17-44mm; expected total mass ~1-8g; dataset 30.73mg is ~1.5-2.4 log10 units below size-based estimate; no published mass for this species but discrepancy is extreme*

**Primary reference (audit):** <https://www.sealifebase.ca/summary/Fissurella-clenchi.html>

**Peer-reviewed citations:**

> *No peer-reviewed mass data retrieved from Semantic Scholar / OpenAlex / Europe PMC searches. See primary reference URL above.*

---

#### *Fissurella rosea*

> **Status:** NEEDS_REVIEW — no single verified value; range given

| | |
|---|---|
| **Database value** | 0.001356 g |
| **Corrected value** | 2.5 g |
| **Tier** | Confirmed (CRITICAL) |

*Shell 17-40mm (Wikipedia; SeaLifeBase); expected total mass ~1-5g; dataset 1.356mg is ~2.9-3.6 log10 units below size-based estimate; no published mass data but discrepancy is extreme*

**Primary reference (audit):** <https://www.sealifebase.ca/summary/Fissurella-rosea.html>

**Peer-reviewed citations:**

- Hughes, R.N. (1971). Ecological energetics of the keyhole limpet Fissurella barbadensis Gmelin. Journal of Experimental Marine Biology and Ecology, 6(3), 167–178. https://doi.org/10.1016/0022-0981(71)90016-5
  - *Full text not openly accessible; ecological energetics papers of this type invariably report wet or dry body mass. F. barbadensis is a close congener of F. rosea in the same Caribbean/West Atlantic region.*
- Bretos, M. (1980). Age determination in the keyhole limpet Fissurella crassa Lamarck (Archaeogastropoda: Fissurellidae), based on shell growth rings. The Biological Bulletin, 159(3), 606–612. https://doi.org/10.2307/1540826
  - *Full text not openly accessible; shell growth ring study for a congener that likely includes shell-length-at-age data. F. crassa is a well-studied Pacific Fissurella species in the same family.*

---

#### *Glomeris connexa*

| | |
|---|---|
| **Database value** | 3.819e-04 g |
| **Corrected value** | 0.35 g |
| **Literature range** | 0.2 g – 0.35 g – 0.6 g |
| **Tier** | Confirmed (SUSPICIOUS) |

*"Pill millipede (Glomeridae), adults 10-20 mm. 0.38 mg is impossibly small; adult Glomeris species weigh 200-600 mg. This is a ~1000x underestimate, likely a unit error."*

**Peer-reviewed citations:**

- Gromysz-Kalkowska, K. (1974). The effect of some exogenous factors and body weight on oxygen consumption in Glomeris connexa C. L. Koch (Diplopoda). Folia Biologica (Krakow), 22(1), 37-49. PMID: 4819497
  - *Body weight is a primary variable measured for G. connexa across experimental conditions; exact central tendency values not recoverable from abstract alone. Paper indexed in PubMed (PMID 4819497) but predates DOI assignment. Body weight used to derive mass-specific respiration rates.*
- Sustr, V., Chronakova, A., Semanová, S., Tajovsky, K., & Simek, M. (2014). Methane production and methanogenic Archaea in the digestive tracts of millipedes (Diplopoda). PLoS ONE, 9(7), e102659. https://doi.org/10.1371/journal.pone.0102659
  - *Mass reported: 0.2 g — Body mass of Glomeris marginata (congener in Glomerida) explicitly stated as 'about 0.2 g'. Study covered 35 millipede species and weighed all animals post-incubation. Body masses for individual species reported in supplementary Table S2. Paper establishes that Glomerida species with body mass >0.06 g and up to ~0.4 g are typical non-obligate methane producers.*
- Nweze, J. E., Gupta, S., Salcher, M. M., Sustr, V., Horváthová, T., & Angel, R. (2024). Disruption of millipede-gut microbiota in E. pulchripes and G. connexa highlights the limited role of litter fermentation and the importance of litter-associated microbes for nutrition. Communications Biology, 7, 1246. https://doi.org/10.1038/s42003-024-06821-2
  - *Paper directly studies Glomeris connexa. Methods describe the species as 'smaller (10-17 mm) and native to Central Europe' and explicitly monitors 'survival or weight' of G. connexa individuals during experiments. No central body mass value reported in abstract or accessible text, but body length of 10-17 mm is consistent with expected mass of 200-600 mg range for this genus.*

---

#### *Glyptotendipes pallens*

| | |
|---|---|
| **Database value** | 0.0773 g |
| **Corrected value** | 0.002 g |
| **Literature range** | 2.000e-04 g – 0.002 g – 0.005 g |
| **Tier** | Confirmed (CRITICAL) |

*Chironomidae (non-biting midge) confirmed; typical adult chironomid mass 0.2-5mg; 77.3mg is ~1.6 log10 too high*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Glyptotendipes_pallens>

**Peer-reviewed citations:**

- Heinis, F., Timmermans, K. R., & Swain, W. R. (1990). Short-term sublethal effects of cadmium on the filter feeding chironomid larva Glyptotendipes pallens (Meigen) (Diptera). Aquatic Toxicology, 16(1), 73–85. https://doi.org/10.1016/0166-445x(90)90078-4
  - *Full text not accessible via open sources; abstract not indexed in PubMed or Europe PMC. The paper is cited 43 times (OpenAlex) and is the primary peer-reviewed bioassay reference for G. pallens physiology. Explicit larval mass values could not be confirmed from retrieved metadata alone.*
- Mahdy, A., Scharfenberger, U., Adrian, R., & Hilt, S. (2015). Experimental comparison of periphyton removal by chironomid larvae and Daphnia magna. Inland Waters, 5(1), 81–88. https://doi.org/10.5268/iw-5.1.755
  - *Body mass is not stated directly but can be derived from reported individual removal rate (0.12–0.17 mg DW ind.⁻¹ d⁻¹) divided by the implied mass-specific rate (~0.62 mg DW mg⁻¹ d⁻¹), yielding ~0.2 mg DW individual⁻¹. Paper was retrieved in OpenAlex searches for 'Glyptotendipes pallens body mass'.*
- Mocq, J., Dekanová, V., & Boukal, D. S. (2024). Length–mass allometries of the larvae of aquatic dipterans: differences between taxa, morphological traits, and methods. Journal of Insect Science, 24(1), ieae012. https://doi.org/10.1093/jisesa/ieae012
  - *No Glyptotendipes-specific mass values extracted; the paper provides allometric equations applicable across Chironomidae rather than species-level mass tabulations. Chironomidae was the most-covered family in the compiled dataset (N=108 allometries).*

---

#### *Golfingia nordenskojoeldi*

| | |
|---|---|
| **Database value** | 6.300e-07 g |
| **Corrected value** | 0.05 g |
| **Literature range** | 0.001 g – 0.05 g – 0.5 g |
| **Tier** | Confirmed (CRITICAL) |

*6.3e-7 g = 0.63 micrograms is below the mass of a single large cell and physically impossible for any macroscopic worm; off by approximately 5-6 log10 units compared to the expected range for a sipunculan of this genus; cf. congener G. margaritacea at 0.92 g in the same dataset; likely a catastrophic decimal or unit conversion error; species epithet 'nordenskojoeldi' is a dataset variant of nordenskoeldii*

**Primary reference (audit):** <https://www.marinespecies.org/aphia.php?p=search&query=Golfingia+nordenskoeldi>

**Peer-reviewed citations:**

- Kędra, M., & Murina, G.V. (2007). The sipunculan fauna of Svalbard. Polar Research, 26(1), 37–47. https://doi.org/10.1111/j.1751-8369.2007.00005.x
  - *Abstract retrieved; no specific mass values stated. Paper documents species occurrence and depth distribution rather than individual body mass.*
- Amor, A. (1993). Reproductive cycle of Golfingia margaritacea, a bipolar sipunculan, in subantarctic water. Marine Biology, 117(3), 409–414. https://doi.org/10.1007/BF00349316
  - *Bibliographic metadata retrieved from CrossRef; full text paywalled and could not be accessed to extract explicit mass values. Mass value inferred as plausible from species biology.*
- Gibbs, P.E. (1974). Golfingia margaritacea (Sipuncula) in British waters. Journal of the Marine Biological Association of the United Kingdom, 54(4), 871–877. https://doi.org/10.1017/s0025315400057623
  - *Abstract retrieved from Cambridge Journals confirming taxonomic/morphological focus; full text paywalled. No mass value extracted from accessible text.*

---

#### *Grapsus adscensionis*

| | |
|---|---|
| **Database value** | 0.01 g |
| **Corrected value** | 150 g |
| **Literature range** | 50 g – 150 g – 500 g |
| **Tier** | Confirmed (CRITICAL) |

*Littoral rock crab; carapace up to 7.7cm x 8.7cm (Wikipedia confirmed); crab of this carapace size typically 100-400g; dataset 10mg is ~4.2-4.7 log10 below minimum adult mass; same 0.01g value pattern as Eriphia_smithii and other Brose_etal_2018 crabs; likely catastrophic unit error*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Grapsus_adscensionis>

**Peer-reviewed citations:**

- Cisneros-Bejarano F., Muñoz-Pérez J.P., Alarcón-Ruales D., Moreira-Mendieta A., Lewbart G.A., et al. (2026). Microplastic exposure and biological correlates in a key intertidal crab (Grapsus grapsus) from the Galápagos Islands. Marine Pollution Bulletin. https://doi.org/10.1016/j.marpolbul.2026.119688
  - *Scaled mass index used as morphometric variable; explicit mass values not reported in abstract.*

---

#### *Hippolyte pleuracantha*

| | |
|---|---|
| **Database value** | 9.390e-05 g |
| **Corrected value** | 0.01 g |
| **Literature range** | 0.003 g – 0.01 g – 0.03 g |
| **Tier** | Confirmed (CRITICAL) |

*Small caridean shrimp (Hippolytidae); adults ~10-20mm; congener H. varians (same dataset; also Brose source) = 14.65mg; dataset 0.094mg is ~2.0 log10 below congener; Brose_etal_2018 shows same systematic underestimation for small invertebrates; likely mg-to-g unit error*

**Peer-reviewed citations:**

- Shield, P. D. (1978). Larval development of the caridean shrimp, Hippolyte pleuracanthus (Stimpson), reared in the laboratory. Estuaries, 1(1), 85–98. https://doi.org/10.2307/1351497
  - *Body mass not confirmed from abstract; paper reports larval development stages and likely reports adult female total length, but full text was inaccessible.*
- Romero-Rodríguez, J., Román-Contreras, R., Cházaro-Olvera, S., & Martínez-Muñoz, M. A. (2016). Growth of individuals within the parasite-host association Bopyrina abbreviata (Isopoda, Bopyridae) and Hippolyte zostericola (Decapoda, Caridea), and variations in parasite morphology. Invertebrate Biology, 135(1), 17–30. https://doi.org/10.1080/07924259.2015.1126536
  - *Specific body mass values not confirmed from abstract; paper is a growth study and likely contains size measurements (carapace length, total length) but full text was inaccessible.*

---

#### *Liljeborgia kinahani*

| | |
|---|---|
| **Database value** | 1.378e-04 g |
| **Corrected value** | 0.003 g |
| **Literature range** | 0.001 g – 0.003 g – 0.01 g |
| **Tier** | Confirmed (CRITICAL) |

*Liljeborgiid amphipod 5-10 mm adult body length; estimated wet mass 1-10 mg from body volume scaling; 0.0001378 g (0.138 mg) is ~10-30x below expected; log10 diff ~1.2 vs low end; likely unit error (mg vs g) or dry mass transcription error*

**Primary reference (audit):** <https://www.marinespecies.org/aphia.php?p=taxdetails&id=102483>

**Peer-reviewed citations:**

> *No peer-reviewed mass data retrieved from Semantic Scholar / OpenAlex / Europe PMC searches. See primary reference URL above.*

---

#### *Lineus longifissus*

| | |
|---|---|
| **Database value** | 5,800 g |
| **Corrected value** | 10 g |
| **Literature range** | 0.5 g – 10 g – 100 g |
| **Tier** | Confirmed (CRITICAL) |

*Valid species (Hubrecht 1887; subantarctic; reclassified by some authorities to Heteronemertes); no nemertean is known to reach 5800g; all three 5800g entries likely from same duplicated source error in Brose et al. 2018; Lineus are slender worms expected <100g*

**Primary reference (audit):** <https://pubmed.ncbi.nlm.nih.gov/32972088/>

**Peer-reviewed citations:**

- Hookabe, N., & Kajihara, H. (2020). Taxonomic Reappraisal of Lineus longifissus Auct. (Nemertea: Pilidiophora) from Japan for the First Time in 122 Years. Zoological Science, 37(5). https://doi.org/10.2108/zs200001
  - *Taxonomic redescription of Japanese Lineus longifissus specimens (reclassified as Corsoua takakurai sp. nov.); full text not accessible, but as a Zoological Science taxonomic paper it likely contains body-length measurements for intertidal tidal-flat specimens—body size consistent with a small heteronemertean, far below 1 g let alone kg-range.*
- Kajihara, H. (2007). A taxonomic catalogue of Japanese nemerteans (phylum Nemertea). Zoological Science, 24(3), 287–317. https://doi.org/10.2108/zsj.24.287
  - *Catalogue listing Lineus longifissus among Japanese nemerteans, noting its status as uncertain. Establishes the taxonomic context for a small intertidal ribbon worm species.*

---

#### *Lineus ruber*

| | |
|---|---|
| **Database value** | 2.000e-04 g |
| **Corrected value** | 0.5 g |
| **Literature range** | 0.05 g – 0.5 g – 2 g |
| **Tier** | Confirmed (CRITICAL) |

*Common intertidal nemertean; body 7.5-23cm long; estimated wet mass 0.05-2g for adults; dataset 0.0002g (0.2mg) is ~3.4 log units below expected; likely a unit error (mg entered as g) or data entry error*

**Primary reference (audit):** <https://www.gbif.org/species/2508484>

**Peer-reviewed citations:**

> *No peer-reviewed mass data retrieved from Semantic Scholar / OpenAlex / Europe PMC searches. See primary reference URL above.*

---

#### *Liocarcinus arcuatus*

| | |
|---|---|
| **Database value** | 0.0507 g |
| **Corrected value** | 8 g |
| **Literature range** | 2 g – 8 g – 20 g |
| **Tier** | Confirmed (CRITICAL) |

*Portunid swimming crab; carapace width up to 30 mm (MarLIN confirmed); expected adult wet mass 2-20 g based on size-mass scaling for similar portunids; 0.0507 g is ~100x too small; log10 diff 2.2; likely unit error*

**Primary reference (audit):** <https://www.marlin.ac.uk/species/detail/1612>

**Peer-reviewed citations:**

- Aydın, M., Karadurmuş, U., & Erbay, M. (2013). Length-weight relationships and reproduction characteristics of Liocarcinus navigator (Herbst, 1794). Ege Journal of Fisheries and Aquatic Sciences, 29(4), 193-197. https://doi.org/10.12714/egejfas.2012.29.4.08
  - *Reports carapace-width-to-body-weight relationships for L. navigator (= L. arcuatus per WoRMS AphiaID 146912) in the Central Black Sea. Full numerical data not accessible in abstract; title and OpenAlex metadata confirm the study quantified CW-to-wet-weight regressions.*
- Freire, J., Muiño, R., Fernández, L., & González-Gurriarán, E. (1991). Life Cycle of Liocarcinus arcuatus (Brachyura: Portunidae) in the Ría de Arousa (Galicia, NW Spain): Role of Beach and Mussel Raft Culture Areas. Marine Ecology, 12(3), 193-210. https://doi.org/10.1111/j.1439-0485.1991.tb00253.x
  - *Population biology study reporting cohort growth rates across beach and mussel-raft habitats; provides size-at-age context for L. arcuatus but full-text mass values not accessible from abstract.*
- Muiño, R., Fernández, L., & González-Gurriarán, E. (2000). Fecundity of Liocarcinus arcuatus (Decapoda: Brachyura) in the ría de arousa (Galicia, NW Spain). Ophelia, 53(1), 19-26. https://doi.org/10.1080/00785326.2000.10409432
  - *Fecundity study of L. arcuatus; fecundity analyses routinely measure female carapace width and often wet/dry body mass, but specific mass values are not available from the CrossRef abstract record.*

---

#### *Liocarcinus corrugatus*

| | |
|---|---|
| **Database value** | 0.108 g |
| **Corrected value** | 40 g |
| **Literature range** | 10 g – 40 g – 100 g |
| **Tier** | Confirmed (CRITICAL) |

*Portunid swimming crab; carapace width up to 60 mm; expected adult mass 10-100 g; 0.108 g is ~100-400x too small; log10 diff ~2.6; likely unit error (mg vs g) consistent with Brose_etal_2018 source*

**Primary reference (audit):** <https://www.marinespecies.org/aphia.php?p=taxdetails&id=146914>

**Peer-reviewed citations:**

- Demirbas, A., Gozler, A. M., Baytasoglu, H., & Kaya, C. (2021). Heavy metal concentration levels and biometric analysis of Liocarcinus depurator from different locations on the western Black Sea coast of Turkey. Environmental Monitoring and Assessment, 193(6), 346. https://doi.org/10.1007/s10661-021-09113-y
  - *Mass reported: 8.33 g — Male mean wet mass 8.33 g at CW 32.32 mm for congener L. depurator; adult L. corrugatus (CW up to ~60 mm) would scale to approximately 40-50 g.*
- Kim, K. B., & Hong, S. Y. (1999). Larval development of the wrinkled swimming crab Liocarcinus corrugatus (Decapoda: Brachyura: Portunidae) reared in the laboratory. Journal of Crustacean Biology, 19(4), 792-808. https://doi.org/10.1163/193724099X00510
  - *Does not directly report adult body mass; focuses on larval development stages.*
- Kim, K. B., & Hong, S. Y. (2004). Effects of temperature on larval growth and survival in the wrinkled swimming crab (Liocarcinus corrugatus) (Brachyura: Portunidae) reared in the laboratory. Korean Journal of Fisheries and Aquatic Sciences, 37(3), 186-191. https://doi.org/10.5657/kfas.2004.37.3.186
  - *Does not directly report adult body mass; focuses on temperature effects on larval development.*

---

#### *Lysmata wurdemanni*

| | |
|---|---|
| **Database value** | 1.719e-04 g |
| **Corrected value** | 1 g |
| **Literature range** | 0.5 g – 1 g – 2 g |
| **Tier** | Confirmed (CRITICAL) |

*Peppermint shrimp; adult body length 5-7 cm (SeaLifeBase confirmed); expected mass 0.5-2 g; 0.0001719 g is ~3000-10000x too small; log10 diff 3.8; likely mg vs g unit error in Brose_etal_2018 extraction*

**Primary reference (audit):** <https://www.sealifebase.ca/summary/Lysmata-wurdemanni.html>

**Peer-reviewed citations:**

- Díaz-Jiménez, L., Hernández-Vergara, M. P., & Pérez-Rostro, C. I. (2019). Protein and lipid requirement for the growth and reproduction of the peppermint shrimp Lysmata wurdemanni. Aquaculture Research, 50(8), 2281–2288. https://doi.org/10.1111/are.14110
  - *Directly measures body weight gained (g) for adult L. wurdemanni over a 90-day feeding trial (protein/lipid diet study); specific gram values are in the full text (paywalled) but the abstract confirms measurement in grams, consistent with ~1 g adult mass.*
- Díaz-Jiménez, L., Hernández-Vergara, M. P., & Pérez-Rostro, C. I. (2018). The effect of background colour and lighting of the aquarium on the body pigmentation of the peppered shrimp Lysmata wurdemanni. Aquaculture Research. https://doi.org/10.1111/are.13816
  - *Measures weight gain (%) for juvenile L. wurdemanni over 100 days. Survival, weight gain, and carotenoid content assessed; confirms body mass tracked across an experiment starting from juvenile stage, consistent with adult masses in the gram range.*
- Dickson, M. D., Behringer, D. C., & Baeza, J. A. (2020). Life history traits and reproductive performance of the caridean shrimp Lysmata boggessi, an exploited peppermint shrimp of the Florida Keys. PeerJ, 8, e8231. https://doi.org/10.7717/peerj.8231
  - *Reports carapace length 3.9–11.3 mm and uses dry body mass (hermaphrodite dry mass) for reproductive investment calculations in the congener L. boggessi (sister taxon to L. wurdemanni, also called peppermint shrimp). A carapace length of 8–11 mm for adults is consistent with total body lengths of 35–55 mm and wet masses of approximately 0.5–2 g.*

---

#### *Mangora acalypha*

| | |
|---|---|
| **Database value** | 2.573e-04 g |
| **Corrected value** | 0.015 g |
| **Literature range** | 0.005 g – 0.015 g – 0.04 g |
| **Tier** | Confirmed (CRITICAL) |

*"Orb-weaving spider (Araneidae), body 5-8 mm. 0.26 mg is impossible for an adult spider this size; expected 5-40 mg. This is a ~100x underestimate, likely a unit error (µg recorded as g, or mg/1000 conversion error)."*

**Peer-reviewed citations:**

> *No peer-reviewed mass data retrieved from Semantic Scholar / OpenAlex / Europe PMC searches. See primary reference URL above.*

---

#### *Odontesthes argentinensis*

| | |
|---|---|
| **Database value** | 0.01 g |
| **Corrected value** | 80 g |
| **Literature range** | 10 g – 80 g – 400 g |
| **Tier** | Confirmed (CRITICAL) |

*Argentine silverside (Atherinopsidae); FishBase max 42.1cm TL; adults expected ~10-400g; 0.01g (10mg) is ~3.9 log10 units below expected; clearly erroneous*

**Primary reference (audit):** <https://fishbase.se/summary/Odontesthes-argentinensis.html>

**Peer-reviewed citations:**

- Llompart, F., Colautti, D., Maiztegui, T., Cruz-Jiménez, A., & Baigún, C. (2013). Biological traits and growth patterns of pejerrey Odontesthes argentinensis. Journal of Fish Biology, 82(2), 458–474. https://doi.org/10.1111/j.1095-8649.2012.03494.x
  - *Paper specifically characterizes growth patterns and biological indices of O. argentinensis at its southern distribution boundary; adult body mass data expected within but not retrievable from metadata alone. Species reaches ~42 cm, consistent with corrected mass ~80 g.*
- Méndez, E., Albanesi, C., Michiels, M., López-Mañanes, A., & González-Castro, M. (2024). Analyses of body condition and digestive/metabolic parameters of Odontesthes argentinensis (Atherinopsidae) from Mar Chiquita Coastal Lagoon (Argentina) during different phases of ovarian development. Neotropical Ichthyology. https://doi.org/10.1590/1982-0224-2023-0139
  - *Reports total weight and Fulton's condition factor for adult O. argentinensis; total weight increases ~70% during active spawning phase relative to earlier reproductive phases, but absolute values not available from retrieved metadata.*
- Tesser, M. B., & Sampaio, L. A. (2006). Criação de juvenis de peixe-rei (Odontesthes argentinensis) em diferentes taxas de arraçoamento. Ciencia Rural, 36, 1278–1282. https://doi.org/10.1590/S0103-84782006000400036
  - *Mass reported: 0.1 g — Juveniles stocked at 100 mg (0.1 g) initial body mass; study covers the 100–500 mg juvenile size range. Optimal feeding rate reported as 9% of body weight per day. Adult mass would be far greater (literature consistent with ~80 g).*

---

#### *Oithona colcarva*

| | |
|---|---|
| **Database value** | 0.01233 g |
| **Corrected value** | 2.000e-06 g |
| **Literature range** | 5.000e-07 g – 2.000e-06 g – 5.000e-06 g |
| **Tier** | Confirmed (CRITICAL) |

*Valid species (Bowman 1975; WoRMS confirmed); estuarine species of Western Atlantic; as Oithonidae typical dry mass 0.5-5 µg; dataset value 12330 µg is ~2500-25000x too high; log10 difference ~3.8; same mass as O. helgolandica and Onacea borealis suggesting batch data entry or unit error*

**Primary reference (audit):** <https://marinespecies.org/aphia.php?id=353993&p=taxdetails>

**Peer-reviewed citations:**

- Sabatini, M., & Kiørboe, T. (1994). Egg production, growth and development of the cyclopoid copepod *Oithona similis*. *Journal of Plankton Research*, 16(10), 1329–1351. https://doi.org/10.1093/plankt/16.10.1329
  - *Genus-level body size reference; confirms Oithona adults have µg-scale dry mass; 12.33 mg in dataset is ~3 log₁₀ too large.*
- Brun, P., Payne, M.R., & Kiørboe, T. (2017). A trait database for marine copepods. *Earth System Science Data*, 9(1), 99–113. https://doi.org/10.5194/essd-9-99-2017
  - *Marine copepod trait database; body mass data for Oithonidae.*

---

#### *Oithona helgolandica*

| | |
|---|---|
| **Database value** | 0.01233 g |
| **Corrected value** | 2.000e-06 g |
| **Literature range** | 5.000e-07 g – 2.000e-06 g – 5.000e-06 g |
| **Tier** | Confirmed (CRITICAL) |

*Valid species (treated as senior synonym of O. similis Claus 1866); adults <1 mm; typical dry mass 1-3 µg DW; dataset value 12330 µg is ~4000-12000x too high; log10 difference ~3.8; identical mass to O. colcarva and Onacea borealis — likely shared data entry error*

**Primary reference (audit):** <https://www.cambridge.org/core/journals/journal-of-the-marine-biological-association-of-the-united-kingdom/article/abs/development-stages-of-oithona-helgolandica-and-oithona-spinirostris/DA688AA50E62676D6DF58FBAB8189E4B>

**Peer-reviewed citations:**

- Sabatini, M., & Kiørboe, T. (1994). Egg production, growth and development of the cyclopoid copepod *Oithona similis*. *Journal of Plankton Research*, 16(10), 1329–1351. https://doi.org/10.1093/plankt/16.10.1329
  - *Body size and dry mass data for Oithona similis (senior synonym of O. helgolandica); confirms dry mass of individual adults is in the µg range, not mg range.*
- Brun, P., Payne, M.R., & Kiørboe, T. (2017). A trait database for marine copepods. *Earth System Science Data*, 9(1), 99–113. https://doi.org/10.5194/essd-9-99-2017
  - *Copepod trait database including Oithona similis body size and mass; confirms µg-scale dry mass for this genus.*

---

#### *Triconia borealis*

| | |
|---|---|
| **Database value** | — |
| **Corrected value** | 1.000e-05 g |
| **Tier** | Confirmed () |

*Oncaeidae copepod; renamed from Onacea_borealis in fix_misspellings.r*

**Peer-reviewed citations:**

- Skjoldal, H. R. (2021). Species composition of three size fractions of zooplankton used in routine monitoring of the Barents Sea ecosystem. Journal of Plankton Research, 43(5), 762–772. https://doi.org/10.1093/plankt/fbab056
  - *Mass reported: 1e-05 g — 10 µg dry weight is the mean per-individual value for the entire small (<1 mm) size fraction, not an Oncaea-specific measurement; Oncaea spp. (including T. borealis) are explicitly listed as constituents of this fraction.*
- Skjoldal, H. R., & Aarflot, J. M. (2023). Abundance and biomass of copepods and cladocerans in Atlantic and Arctic domains of the Barents Sea ecosystem. Journal of Plankton Research, 45(6), 870–884. https://doi.org/10.1093/plankt/fbad043
  - *Individual dry weight for Triconia borealis is not stated in the main text; community-level Oncaea biomass reported as ~0.02 g dw m⁻²; individual weights were taken from literature and are in supplementary Table S1 only.*

---

#### *Ornitnonyssus bursa*

| | |
|---|---|
| **Database value** | 3.770e-09 g |
| **Corrected value** | 2.000e-06 g |
| **Literature range** | 5.000e-07 g – 2.000e-06 g – 1.000e-05 g |
| **Tier** | Confirmed (CRITICAL) |

*"Ornithonyssus bursa (tropical fowl mite) is correctly Arachnida. Mass of 3.77 ng is impossibly small for a mite (~0.7-1.0 mm body length). Expected range 0.5-10 µg based on body dimensions similar to Dermanyssus gallinae. Likely a ~1000x unit conversion error. Note: taxon name misspelled in dataset (Ornitnonyssus should be Ornithonyssus)."*

**Peer-reviewed citations:**

- Waap, H., Aguin-Pombo, D., & Maia, M. (2020). Case Report: Human Dermatitis Linked to Ornithonyssus bursa (Dermanyssoidea: Macronyssidae) Infestation in Portugal. Frontiers in Veterinary Science, 7, 567902. https://doi.org/10.3389/fvets.2020.567902
  - *Reports body dimensions of approximately 1 mm long by 0.5 mm wide for adult O. bursa females; no direct mass measurement given. From these dimensions, assuming ellipsoidal shape and tissue density ~1 g/cm3, wet mass would be on the order of 50–100 µg (5e-5 to 1e-4 g); dry mass approximately 5–20 µg (5e-6 to 2e-5 g).*
- Bassini-Silva, R., Cruz, L.F.D., Carvalho, J.T., et al. (2025). Sleeping with the enemy II: Expanding the ecological, molecular, and epidemiological knowledge of the tropical fowl mite, Ornithonyssus bursa. Parasitology International, 112, 103226. https://doi.org/10.1016/j.parint.2025.103226
  - *No body mass data reported. Comprehensive ecological and molecular characterization of O. bursa; provides context for the species biology but no morphometric mass values.*
- Garcia-Rejon, J.E., Cab-Cauich, I.Y., Tzuc-Dzul, J.C., et al. (2023). Mites associated with budgerigars and the first report of Ornithonyssus bursa in Mexico. Open Veterinary Journal, 13(1), 20–25. https://doi.org/10.5455/ovj.2023.v13.i1.3
  - *Full text not accessible; no body mass data confirmed from abstract. First geographic record for Mexico with morphological identification, but no quantitative mass measurements retrieved.*

---

#### *Parborlasia corrugatus*

| | |
|---|---|
| **Database value** | 5,800 g |
| **Corrected value** | 100 g |
| **Literature range** | 10 g – 100 g – 140 g |
| **Tier** | Confirmed (CRITICAL) |

*World's heaviest nemertean; literature max 100-140g (1-3m length; 2cm diameter) per HandWiki and Davison & Franklin 2002; dataset 5800g is 1.6 log units above maximum known mass; one of three duplicated 5800g values in dataset*

**Primary reference (audit):** <https://handwiki.org/wiki/Biology:Parborlasia_corrugata>

**Peer-reviewed citations:**

- Heine, J.N., McClintock, J.B., Slattery, M., & Weston, J. (1991). Energetic composition, biomass, and chemical defense in the common Antarctic nemertean *Parborlasia corrugatus* McIntosh. *Journal of Experimental Marine Biology and Ecology*, 153(1), 15–25.
  - *Wet mass up to 140 g reported; confirms body size and mass range. Predates online DOI assignment.*
- Davison, W., & Franklin, C.E. (2002). The Antarctic nemertean *Parborlasia corrugatus*: an example of an extreme oxyconformer. *Polar Biology*, 25(3), 238–240. https://doi.org/10.1007/s003000100333
  - *Explicitly states P. corrugatus reaches at least 100 g body mass; 5800 g in dataset is ~1.6 log₁₀ above this maximum.*

---

#### *Phallusia nigra*

| | |
|---|---|
| **Database value** | 0.01 g |
| **Corrected value** | 50 g |
| **Literature range** | 10 g – 50 g – 200 g |
| **Tier** | Confirmed (CRITICAL) |

*Adult Phallusia nigra is a large solitary ascidian reaching 5-15 cm body length with typical wet mass 10-200 g; dataset value of 0.01 g is approximately 3.7 log10 units too small; likely a decimal place error or unit conversion mistake (possibly mg recorded as g would still be 0.00001 g; could be g recorded as kg so actual mass ~10 g)*

**Primary reference (audit):** <https://www.marinespecies.org/aphia.php?p=search&query=Phallusia+nigra>

**Peer-reviewed citations:**

> *No peer-reviewed mass data retrieved from Semantic Scholar / OpenAlex / Europe PMC searches. See primary reference URL above.*

---

#### *Phoebis agarithe*

| | |
|---|---|
| **Database value** | 5.537 g |
| **Corrected value** | 0.5 g |
| **Literature range** | 0.2 g – 0.5 g – 1 g |
| **Tier** | Confirmed (CRITICAL) |

*Large Orange Sulphur butterfly (Lepidoptera: Pieridae; wingspan ~55-75mm); typical adult Pierid mass ~0.3-0.8g; 5.537g exceeds expected range by ~1 log10 unit; probable data entry error*

**Primary reference (audit):** <https://animaldiversity.org/accounts/Phoebis_agarithe/>

**Peer-reviewed citations:**

- Dudley, R. & Srygley, R. B. (1994). Flight Physiology of Neotropical Butterflies: Allometry of Airspeeds During Natural Free Flight. Journal of Experimental Biology, 191(1), 125-139. https://doi.org/10.1242/jeb.191.1.125
  - *Body mass measured for 270 individuals across 62 Neotropical butterfly species; flight speed positively correlated with body mass, thoracic mass, and wing loading. Phoebis agarithe is among the most abundant large Pieridae in the Panama study area; allometric data constrain expected mass to sub-gram range for this body size class.*
- Dudley, R. & Srygley, R. B. (2008). Airspeed adjustment and lipid reserves in migratory Neotropical butterflies. Functional Ecology, 22(2), 264-270. https://doi.org/10.1111/j.1365-2435.2007.01364.x
  - *Body mass and abdominal lipid content measured for five migratory Pieridae and Nymphalidae species during the rainy-season migration through central Panama. Airspeeds were adjusted for body mass; Phoebis agarithe is one of the most characteristic migratory Pieridae in this migration system.*
- Srygley, R. B. & Chai, P. (1990). Flight morphology of Neotropical butterflies: palatability and distribution of mass to the thorax and abdomen. Oecologia, 84(4), 491-499. https://doi.org/10.1007/bf00328165
  - *Total body mass measured for 45 Neotropical butterfly species (10 male and 9 female lineages); thorax and abdomen together comprise ~75% of total body mass. Mass distribution data for palatable vs. unpalatable lineages; Pieridae are among the palatable lineages studied in Panama.*

---

#### *Porania antarctica*

| | |
|---|---|
| **Database value** | 0.1528 g |
| **Corrected value** | 50 g |
| **Literature range** | 10 g – 50 g – 200 g |
| **Tier** | Confirmed (CRITICAL) |

*Synonym Glabraster antarctica; max radius 70mm (~14cm diameter) robust cushion star per Biological Bulletin; estimated adult wet mass 10-200g; dataset 0.15g is ~2 log units below expected range*

**Primary reference (audit):** <https://www.journals.uchicago.edu/doi/10.2307/1541836>

**Peer-reviewed citations:**

> *No peer-reviewed mass data retrieved from Semantic Scholar / OpenAlex / Europe PMC searches. See primary reference URL above.*

---

#### *Thalassoma pavo*

| | |
|---|---|
| **Database value** | 0.01 g |
| **Corrected value** | 150 g |
| **Literature range** | 80 g – 150 g – 300 g |
| **Tier** | Confirmed (CRITICAL) |

*Ornate wrasse; FishBase max 25 cm SL (common 20 cm); no published weight on FishBase; estimated 80-300 g from length-weight relationships of comparable Labridae; 0.01 g is ~4.2 log units below typical adult mass; source Brose_etal_2018*

**Primary reference (audit):** <https://www.fishbase.se/summary/Thalassoma-pavo.html>

**Peer-reviewed citations:**

- Giusi, G., Facciolo, R.M., Crudo, M., Bernardi, G., Garreffa, G., & Canonaco, M. (2005). Some environmental contaminants influence motor and feeding behaviors in the ornate wrasse (Thalassoma pavo) via distinct cerebral histamine receptor subtypes. Environmental Health Perspectives, 113(11), 1522-1529. https://doi.org/10.1289/ehp.7983
  - *Mass reported: 22.5 g — Methods section reports 32 young female ornate wrasses with body weight 20-25 g at approximately 16-18 cm length, collected from the Tyrrhenian Sea. Value 22.5 g is the midpoint of the 20-25 g reported range for sub-adult females. Full text confirmed via PMC1310913.*
- Macirella, R., Curcio, V., & Brunelli, E. (2020). Morpho-Functional Alterations in the Gills of a Seawater Teleost, the Ornate Wrasse (Thalassoma pavo L.), after Short-Term Exposure to Chlorpyrifos. Toxics, 8(4), 97. https://doi.org/10.3390/toxics8040097
  - *Mass reported: 9.48 g — Methods section reports 48 healthy adults of both sexes with mean body mass of 9.48 +/- 0.45 g, captured near San Lucido, Italy (Tyrrhenian Sea). These appear to be smaller adults. Full text confirmed via PMC7711812.*

---

#### *Xantho incisus*

| | |
|---|---|
| **Database value** | 0.02644 g |
| **Corrected value** | 20 g |
| **Literature range** | 5 g – 20 g – 80 g |
| **Tier** | Confirmed (CRITICAL) |

*Furrowed crab; treated as synonym of Xantho hydrophilus by some authorities; carapace up to 60 mm wide x 25 mm long; expected adult mass 5-80 g; 0.02644 g is ~200-3000x too small; log10 diff 2.9; likely unit error in Brose_etal_2018*

**Primary reference (audit):** <http://ukwildlife.net/marine/furrowcrab.html>

**Peer-reviewed citations:**

- Dyer, E., & Stevens, M. (2024). Behaviourally mediated camouflage in the furrowed crab (Xantho hydrophilus). Evolutionary Ecology. https://doi.org/10.1007/s10682-024-10308-1
  - *No body mass reported; paper studies adult individuals of Xantho hydrophilus (= Xantho incisus per WoRMS) in a camouflage experiment. Adults selected substrates matching their own brightness. Constrains species identity as adult rocky-shore crab amenable to ecological field and lab study.*
- Edwards, M., Coates, C. J., & Rowley, A. F. (2019). Host Range of the Mikrocytid Parasite Paramikrocytos canceri in Decapod Crustaceans. Pathogens, 8(4), 252. https://doi.org/10.3390/pathogens8040252
  - *No body mass reported. Abstract confirms Xantho hydrophilus ('Montagu's crabs') is co-collected with Cancer pagurus, Carcinus maenas (typical adults 20–100 g), and Necora puber from UK intertidal sites, placing the species in the same size guild as crabs in the tens-of-grams range.*
- Peternac, B., & Legović, T. (1986). Uptake, distribution and loss of Cr in the crab Xantho hydrophilus. Marine Biology, 91(4), 467–471. https://doi.org/10.1007/bf00392597
  - *Abstract not publicly accessible; body mass value could not be confirmed from retrieved metadata. Trace element bioaccumulation studies in marine crustaceans routinely report individual wet body mass as an experimental descriptor; the paper likely contains such data for Xantho hydrophilus (= Xantho incisus).*

---

#### *Xantho pilipes*

| | |
|---|---|
| **Database value** | 0.01 g |
| **Corrected value** | 8 g |
| **Literature range** | 2 g – 8 g – 25 g |
| **Tier** | Confirmed (CRITICAL) |

*Small xanthid crab from NE Atlantic/Mediterranean; adults 2-4 cm CW; expected mass 2-25 g; 0.01 g is ~200-800x too small; log10 diff 2.9; likely unit error in Brose_etal_2018 consistent with other xanthid entries*

**Primary reference (audit):** <https://www.marinespecies.org/aphia.php?p=taxdetails&id=146876>

**Peer-reviewed citations:**

- Patel, K., Patel, H., Gosavi, S., Vachhrajani, K., & Trivedi, J. (2024). Population structure and fecundity of the Xanthid crab Leptodius exaratus (H. Milne Edwards, 1834) on the rocky shore of Gujarat state, India. PeerJ, 12, e16916. https://doi.org/10.7717/peerj.16916
  - *Wet weight measured but specific values not reported in the abstract; carapace width range (5–30 mm) is smaller than Xantho pilipes (20–40 mm CW), suggesting Xantho pilipes body mass would exceed values in this study.*

---

#### *Austroperla cyrene*

> **Status:** Pending — correct value not yet confirmed

| | |
|---|---|
| **Database value** | 3.094e-05 g |
| **Literature range** | 0.005 g – 0.02 g – 0.06 g |
| **Tier** | Confirmed (SUSPICIOUS) |

*Plecoptera Austroperlidae; adult stonefly with aposematic coloration described in Wikipedia; any adult stonefly should weigh at minimum 1–5 mg; even the model's own prediction is ~1.2 mg; dataset value 0.03094 mg is ~650x smaller than typical adult mass; likely represents an extremely early instar larva; Brose 2018 source; |log10(0.00003094/0.02)| = 2.81*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Austroperla>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Chironomus dorsalis*

> **Status:** Pending — correct value not yet confirmed

| | |
|---|---|
| **Database value** | 0.1472 g |
| **Literature range** | 2.000e-04 g – 0.001 g – 0.005 g |
| **Tier** | Confirmed (SUSPICIOUS) |

*Diptera: Chironomidae; Chironomus adults are small non-biting midges 2-10mm body length with typical adult wet mass 0.2-5mg; mature larvae reach 2-20mg; dataset value 147.2mg exceeds all life stages by 1-2 orders of magnitude; probable unit error or wrong life-stage/species entry; abs_residual 1.887; source Brose_etal_2018*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Chironomus>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Circeis armoricana*

> **Status:** Pending — correct value not yet confirmed

| | |
|---|---|
| **Database value** | 0.01183 g |
| **Literature range** | 1.000e-06 g – 5.000e-05 g – 2.000e-04 g |
| **Tier** | Confirmed (SUSPICIOUS) |

*Circeis armoricana is a spirorbid serpulid worm living in a coiled calcareous tube ~1-2mm diameter; the entire animal is very small; expected adult wet mass well under 0.2mg; dataset value 11.83mg is approximately 60-100x too high; likely a unit error (mg entered as g) or data transcription error; taxonomy class correct (Polychaeta; family Serpulidae or Spirorbidae)*

**Primary reference (audit):** <https://www.marinespecies.org/aphia.php?p=search&target=taxa&searchtype=contains&query=Circeis+armoricana>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Clinocera stagnalis*

> **Status:** Pending — correct value not yet confirmed

| | |
|---|---|
| **Database value** | 1.026e-04 g |
| **Literature range** | 3.000e-04 g – 0.001 g – 0.005 g |
| **Tier** | Confirmed (SUSPICIOUS) |

*Diptera: Empididae (dance flies); Clinocera are aquatic-larva predatory flies with adult body length ~3-7mm; expected adult wet mass 0.5-5mg; dataset 0.103mg is ~10x below the low end of expected range (|log10 diff| vs 1mg typical = 1.0); could represent a dry mass measurement or very small female; abs_residual 1.608; source Brose_etal_2018*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Empididae>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Corynoneura scutellata*

> **Status:** Pending — correct value not yet confirmed

| | |
|---|---|
| **Database value** | 0.0086 g |
| **Literature range** | 1.000e-06 g – 1.000e-05 g – 5.000e-05 g |
| **Tier** | Confirmed (SUSPICIOUS) |

*Diptera: Chironomidae (Orthocladiinae); Corynoneura is among the smallest chironomid genera with adult body length 0.5-1.5mm; expected wet mass ~1-50 micrograms (0.000001-0.00005g); dataset 8.6mg is 3-4 orders of magnitude too high; |log10(0.0086) - log10(0.00001)| = 2.93 log10 units; probable species confusion with a larger organism or data entry error by 3-4 decimal places; abs_residual 1.857; source Brose_etal_2018*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Chironomidae>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Hydrobiosella stenocera*

> **Status:** Pending — correct value not yet confirmed

| | |
|---|---|
| **Database value** | 6.630e-05 g |
| **Literature range** | 5.000e-04 g – 0.002 g – 0.008 g |
| **Tier** | Confirmed (SUSPICIOUS) |

*Caddisfly (Trichoptera: Hydrobiosidae); 0.066mg is far too small for any adult or late-instar caddisfly; |log10(0.0000663)-log10(0.002)| = 1.48; even the smallest adult Trichoptera exceed 0.5mg; Brose 2018 source; also note family-level taxonomy error in dataset: listed as Philopotamidae but Hydrobiosella belongs to Hydrobiosidae; recommend correcting mass and family; ERRONEOUS_MASS*

**Primary reference (audit):** <https://www.catalogueoflife.org/data/taxon/Hydrobiosella>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Lestes sponsa*

> **Status:** Pending — correct value not yet confirmed

| | |
|---|---|
| **Database value** | 0.7813 g |
| **Literature range** | 0.03 g – 0.07 g – 0.12 g |
| **Tier** | Confirmed (SUSPICIOUS) |

*Taxonomy correct: Odonata (Zygoptera); Lestidae; Lestes sponsa (emerald damselfly) confirmed; adult body length 35-38 mm; typical adult wet mass 30-120 mg; dataset 781.3 mg is ~1.05 log10 units above typical 70 mg; probable data entry error (unit confusion mg/g) or wrong life stage; Brose et al 2018 source*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Lestes_sponsa>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Limnephilus marmoratus*

> **Status:** Pending — correct value not yet confirmed

| | |
|---|---|
| **Database value** | 0.8076 g |
| **Literature range** | 0.015 g – 0.05 g – 0.12 g |
| **Tier** | Confirmed (SUSPICIOUS) |

*Taxonomy correct: Trichoptera; Limnephilidae; Limnephilus marmoratus confirmed; adult body length 10-18 mm; typical adult wet mass 15-120 mg; dataset 807.6 mg is ~1.2 log10 units above typical 50 mg; probable unit error (mg recorded as g) or larval case mass recorded instead of adult; Brose et al 2018 source*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Limnephilus_marmoratus>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Pyura chilensis*

> **Status:** Pending — correct value not yet confirmed

| | |
|---|---|
| **Database value** | 2.91 g |
| **Literature range** | 100 g – 400 g – 1,500 g |
| **Tier** | Confirmed (SUSPICIOUS) |

*Large commercially harvested tunicate (piure) from Chile and Peru; adults 10-15 cm body length; typical wet mass 100-1500 g; dataset 2.91 g is ~2.1 log10 units below typical; possible juvenile fragment or unit error (mg vs g?); taxonomy correct*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Pyura_chilensis>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Sclerocrangon boreas*

> **Status:** Pending — correct value not yet confirmed

| | |
|---|---|
| **Database value** | 0.01538 g |
| **Literature range** | 3 g – 12 g – 30 g |
| **Tier** | Confirmed (SUSPICIOUS) |

*Large Arctic crangonid shrimp (Decapoda: Crangonidae); one of the largest crangonids; TL up to 100-120 mm; adult wet mass 3-30 g (typical ~12 g); 0.01538 g = 15.4 mg is approximately 3 log10 units below expected typical; |log10(0.01538)-log10(12)| = 2.89; severe mass error — likely decimal shift or unit error (possibly recorded as kg or as dry mass per individual in a sample); compare with congeneric S. ferox (13 g in same dataset) which is biologically plausible*

**Primary reference (audit):** <https://www.sealifebase.ca/summary/Sclerocrangon-boreas.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Sigara lateralis*

> **Status:** Pending — correct value not yet confirmed

| | |
|---|---|
| **Database value** | 4 g |
| **Literature range** | 0.002 g – 0.007 g – 0.015 g |
| **Tier** | Confirmed (SUSPICIOUS) |

*Water boatman (Hemiptera: Corixidae; body length 5-10mm); typical adult wet mass 2-15mg; dataset value 4g (4000mg) is ~2.75 log10 units above expected; almost certainly a units error - mass in mg entered as g; probable true adult mass ~0.004-0.010g (4-10mg); taxonomy Insecta:Hemiptera:Corixidae is correct*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Sigara_lateralis>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Stenoperla prasina*

> **Status:** Pending — correct value not yet confirmed

| | |
|---|---|
| **Database value** | — |
| **Tier** | Confirmed () |

*9.213e-05 g; TODO verify correct mass*

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

### Source: Brown etal 2018

#### *Ochotona dalli*

| | |
|---|---|
| **Database value** | 18,250 g |
| **Corrected value** | 130 g |
| **Literature range** | 95 g – 130 g – 170 g |
| **Tier** | Confirmed (CRITICAL) |

*Dall's pika; all Ochotona species weigh 70-300g; ADW lists general pika range 125-200g; 18250g (18.25kg) is ~2.1 log10 units above typical; likely a data entry error (possible confusion with another taxon or erroneous source record)*

**Primary reference (audit):** <https://animaldiversity.org/accounts/Ochotonidae/>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

### Source: Cai etal 2025

#### *Bokermannohyla alvarengai*

| | |
|---|---|
| **Database value** | 185.6 g |
| **Corrected value** | 15 g |
| **Literature range** | 5 g – 15 g – 35 g |
| **Tier** | Confirmed (SUSPICIOUS) |

*Bokermannohyla are medium-sized hylids typically 5-35 g; 185.6 g is ~5-10x too high and inconsistent with the genus. Residual +1.37 flags this strongly.*

**Primary reference (audit):** <https://amphibiaweb.org/species/573>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Gila conspersa*

| | |
|---|---|
| **Database value** | 1.3 g |
| **Corrected value** | 150 g |
| **Literature range** | 20 g – 150 g – 500 g |
| **Tier** | Confirmed (CRITICAL) |

*Gila chub (Cyprinidae); medium cyprinid reaching 25+ cm; adult typically 50-500g; 1.3g is ~2.1 log units below typical adult mass; likely juvenile or data error*

**Primary reference (audit):** <https://www.fishbase.se/summary/Gila-conspersa.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Opsariichthys pachycephalus*

| | |
|---|---|
| **Database value** | 1 g |
| **Corrected value** | 30 g |
| **Literature range** | 10 g – 30 g – 80 g |
| **Tier** | Confirmed (CRITICAL) |

*Taiwan big-head chub (Cyprinidae); FishBase max 16cm TL; typical adult cyprinid of that size expected ~10-80g; 1g is ~1.5 log10 units below expected*

**Primary reference (audit):** <https://fishbase.se/summary/Opsariichthys-pachycephalus.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Pleurodeles poireti*

| | |
|---|---|
| **Database value** | 143.4 g |
| **Corrected value** | 25 g |
| **Literature range** | 10 g – 25 g – 50 g |
| **Tier** | Confirmed (SUSPICIOUS) |

*Algerian ribbed newt; congener P. waltl is typically 15-40 g and P. poireti is similar or smaller. 143.4 g is ~4-5x too high; likely an outlier source inflated the average.*

**Primary reference (audit):** <https://amphibiaweb.org/species/3851>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Rhinogobius brunneus*

| | |
|---|---|
| **Database value** | 3,663 g |
| **Corrected value** | 3 g |
| **Literature range** | 1 g – 3 g – 7 g |
| **Tier** | Confirmed (CRITICAL) |

*Max TL only 5.8 cm; congener R. duospilus FishBase max weight 6.4 g; 3663 g is physically impossible for a 5.8 cm goby; probable decimal placement error (should be ~3.663 g) or incorrect species entry; log10 diff ~2.8 vs typical adult*

**Primary reference (audit):** <https://www.fishbase.se/summary/Rhinogobius-brunneus>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

### Source: Davidson 1987

#### *Ovalipes catharus*

| | |
|---|---|
| **Database value** | 7,419 g |
| **Corrected value** | 400 g |
| **Literature range** | 200 g – 400 g – 700 g |
| **Tier** | Confirmed (CRITICAL) |

*New Zealand paddle crab; literature max ~700 g for large males (CW up to 150 mm; NZ Fisheries report and SeaLifeBase); 7419 g is ~10x above maximum known mass; log10 diff 1.06; possible decimal shift error (741.9 g would be plausible)*

**Primary reference (audit):** <https://www.sealifebase.se/summary/Ovalipes-catharus.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

### Source: DeLong etal 2010

#### *Eurycercus longirostris*

| | |
|---|---|
| **Database value** | 71.4 g |
| **Corrected value** | 2.000e-04 g |
| **Literature range** | 5.000e-05 g – 2.000e-04 g – 5.000e-04 g |
| **Tier** | Confirmed (CRITICAL) |

*Larger chydorid (benthic/littoral); expected dry weight 50-500 µg per Dumont et al. 1975 allometric framework; dataset value 71.4 g represents 71.4 µg stored as g (factor 1e6 unit error from DeLong source); log10 difference ~5.5*

**Primary reference (audit):** <https://link.springer.com/article/10.1007/BF00377592>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Eurycercus vernalis*

| | |
|---|---|
| **Database value** | 70 g |
| **Corrected value** | 2.000e-04 g |
| **Literature range** | 5.000e-05 g – 2.000e-04 g – 5.000e-04 g |
| **Tier** | Confirmed (CRITICAL) |

*Same family and size class as E. longirostris; expected dry weight 50-500 µg; dataset value 70 g represents 70 µg stored as g (factor 1e6 unit error from DeLong source); log10 difference ~5.5*

**Primary reference (audit):** <https://link.springer.com/article/10.1007/BF00377592>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Pleuroxus denticulatis*

| | |
|---|---|
| **Database value** | 22.7 g |
| **Corrected value** | 5.000e-06 g |
| **Literature range** | 1.000e-06 g – 5.000e-06 g – 2.000e-05 g |
| **Tier** | Confirmed (CRITICAL) |

*Small chydorid ~0.5-1 mm; dry weight ~1-20 µg per Dumont et al. 1975 framework; dataset value 22.7 g represents 22.7 µg stored as g (factor 1e6 unit error); log10 difference ~7.1; species epithet likely misspelled (denticulatis should be denticulatus)*

**Primary reference (audit):** <https://link.springer.com/article/10.1007/BF00377592>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

### Source: DeLong etal 2018

#### *Bemisia tabaci*

| | |
|---|---|
| **Database value** | 5.327e-07 g |
| **Corrected value** | 2.000e-05 g |
| **Literature range** | 1.000e-05 g – 2.000e-05 g – 4.000e-05 g |
| **Tier** | Confirmed (CRITICAL) |

*Adult silverleaf whitefly confirmed ~0.9mm; typical adult mass 10-40µg; dataset 0.53µg is ~1.6 log10 too low*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Bemisia_tabaci>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Danaus plexippus*

| | |
|---|---|
| **Database value** | 4.310e-05 g |
| **Corrected value** | 0.5 g |
| **Literature range** | 0.27 g – 0.5 g – 0.75 g |
| **Tier** | Confirmed (CRITICAL) |

*Monarch butterfly; well-established adult mass 270-750mg; dataset 0.043mg is ~3.85 log10 too low; likely larval or per-individual metabolic measurement rather than adult mass*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Monarch_butterfly>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Ectomyelois ceratoniae*

| | |
|---|---|
| **Database value** | 2.572e-04 g |
| **Corrected value** | 0.01 g |
| **Literature range** | 0.005 g – 0.01 g – 0.03 g |
| **Tier** | Confirmed (CRITICAL) |

*Carob moth (Pyralidae); wingspan ~22-30mm; typical adult moth mass 5-30mg; dataset 0.26mg is ~1.6 log10 too low*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Ectomyelois_ceratoniae>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Ephestia kuehniella*

| | |
|---|---|
| **Database value** | 1.160e-06 g |
| **Corrected value** | 0.007 g |
| **Literature range** | 0.003 g – 0.007 g – 0.015 g |
| **Tier** | Confirmed (CRITICAL) |

*Mediterranean flour moth (Pyralidae); typical adult mass ~3-15mg; dataset 1.16µg is ~3.8 log10 too low*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Ephestia_kuehniella>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Eucyclops subterraneus*

| | |
|---|---|
| **Database value** | 0.00541 g |
| **Corrected value** | 5.000e-05 g |
| **Literature range** | 5.000e-06 g – 5.000e-05 g – 1.000e-04 g |
| **Tier** | Confirmed (CRITICAL) |

*Cyclopoid copepod; typical adult dry weight 5-100 µg; dataset value 5410 µg (5.41 mg) is ~54-1000x above expected range; log10 difference ~2.0; probable factor-of-1000 unit error (µg stored as mg then as g) in DeLong_etal_2018 aggregation*

**Primary reference (audit):** <https://schweizerbart.de/papers/fal/detail/172/56953>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Halichoeres pictus*

| | |
|---|---|
| **Database value** | 0.135 g |
| **Corrected value** | 15 g |
| **Literature range** | 5 g – 15 g – 30 g |
| **Tier** | Confirmed (CRITICAL) |

*FishBase LWR (a=0.00955; b=3.09) yields ~26 g at max 13 cm TL; dataset 0.135 g is ~200x below typical adult; difference >2 log10 units*

**Primary reference (audit):** <https://www.fishbase.se/summary/halichoeres-pictus.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Helicoverpa armigera*

| | |
|---|---|
| **Database value** | 1.120e-05 g |
| **Corrected value** | 0.1 g |
| **Literature range** | 0.05 g – 0.1 g – 0.3 g |
| **Tier** | Confirmed (CRITICAL) |

*Cotton bollworm (Noctuidae); confirmed adult wingspan 30-40mm; adult mass ~50-300mg; dataset 11.2µg is ~3.95 log10 too low*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Helicoverpa_armigera>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Helicoverpa zea*

| | |
|---|---|
| **Database value** | 2.680e-06 g |
| **Corrected value** | 0.15 g |
| **Literature range** | 0.08 g – 0.15 g – 0.3 g |
| **Tier** | Confirmed (CRITICAL) |

*Corn earworm (Noctuidae); confirmed adult wingspan 32-45mm; adult mass ~80-300mg; dataset 2.68µg is ~4.75 log10 too low*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Helicoverpa_zea>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Heliothis virescens*

| | |
|---|---|
| **Database value** | 2.378e-05 g |
| **Corrected value** | 0.08 g |
| **Literature range** | 0.04 g – 0.08 g – 0.15 g |
| **Tier** | Confirmed (CRITICAL) |

*Tobacco budworm (Noctuidae); confirmed adult wingspan 28-35mm; adult mass ~40-150mg; dataset 23.78µg is ~3.5 log10 too low*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Heliothis_virescens>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Hyperoche medusarum*

| | |
|---|---|
| **Database value** | 6.630e-05 g |
| **Corrected value** | 0.005 g |
| **Literature range** | 0.001 g – 0.005 g – 0.02 g |
| **Tier** | Confirmed (CRITICAL) |

*Hyperiid amphipod (family Hyperiidae); adults 10-20mm; expected wet mass for a 15mm hyperiid ~1-20mg; dataset 0.066mg is ~1.9 log10 below minimum expected; source DeLong_etal_2018 shows similar unit errors for small invertebrates; likely mg-to-g unit error*

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Paralithodes platypus*

| | |
|---|---|
| **Database value** | 0.03628 g |
| **Corrected value** | 3,000 g |
| **Literature range** | 1,000 g – 3,000 g – 8,200 g |
| **Tier** | Confirmed (CRITICAL) |

*Blue king crab; SeaLifeBase max published mass 4500 g; reports up to 8200 g (18 lb); 0.03628 g is ~60000-200000x too small; log10 diff 4.7; catastrophic unit error in DeLong_etal_2018 extraction (possibly g vs kg or mg vs g)*

**Primary reference (audit):** <https://www.sealifebase.org/summary/Paralithodes-platypus.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Sebastes atrovirens*

| | |
|---|---|
| **Database value** | 0.154 g |
| **Corrected value** | 700 g |
| **Literature range** | 400 g – 700 g – 910 g |
| **Tier** | Confirmed (CRITICAL) |

*Kelp rockfish; FishBase max 42 cm TL; IGFA world record 910 g; typical adult 400-910 g; 0.154 g is ~3.7 log units below typical adult mass; source DeLong_etal_2018 likely used very small/young specimens*

**Primary reference (audit):** <https://fishbase.se/summary/sebastes-atrovirens>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Sitotroga cerealella*

| | |
|---|---|
| **Database value** | 1.641e-05 g |
| **Corrected value** | 0.003 g |
| **Literature range** | 8.000e-04 g – 0.003 g – 0.008 g |
| **Tier** | Confirmed (CRITICAL) |

*Angoumois grain moth (Lepidoptera: Gelechiidae; wingspan ~12-18mm); adult mass typically ~1-5mg; dataset value 16.4 micrograms is ~1.8 log10 units below expected; likely represents egg or larval mass erroneously used as adult mass*

**Primary reference (audit):** <https://www.cabi.org/isc/datasheet/50510>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Tuta absoluta*

| | |
|---|---|
| **Database value** | 4.050e-07 g |
| **Corrected value** | 5.000e-04 g |
| **Literature range** | 2.000e-04 g – 5.000e-04 g – 0.002 g |
| **Tier** | Confirmed (CRITICAL) |

*Tomato leaf miner moth (Lepidoptera: Gelechiidae; wingspan ~7-8mm); adult mass typically ~0.3-1mg; dataset value 0.405 micrograms is ~3 log10 units below expected; likely represents egg mass or single-larva biomass erroneously used as adult mass*

**Primary reference (audit):** <https://www.cabi.org/isc/datasheet/49260>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

### Source: DosSantos 2022

#### *Pseudis limellum*

| | |
|---|---|
| **Database value** | 0.53 g |
| **Corrected value** | 10 g |
| **Literature range** | 3 g – 10 g – 30 g |
| **Tier** | Confirmed (SUSPICIOUS) |

*Pseudis frogs are medium-sized hylids; adults typically 3-30 g. 0.53 g is implausibly low for any adult Pseudis species.*

**Primary reference (audit):** <https://amphibiaweb.org/species/3999>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

### Source: Faurby etal 2018

#### *Sinomegaceros ordosianus*

| | |
|---|---|
| **Database value** | 404.3 g |
| **Corrected value** | 250,000 g |
| **Literature range** | 100,000 g – 250,000 g – 500,000 g |
| **Tier** | Confirmed (CRITICAL) |

*Extinct megacerine deer (Cervidae); PHYLACINE database itself flags this exact 404.3g value as erroneous in GitHub issue #5; comparable giant deer estimated 100-500kg; 404.3g is ~2.8 log10 units below expected; almost certainly a units error (404.3 kg not converted to g would give ~404300g)*

**Primary reference (audit):** <https://github.com/MegaPast2Future/PHYLACINE_1.2/issues/5>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Elephantulus fuscus*

> **Status:** Pending — correct value not yet confirmed

| | |
|---|---|
| **Database value** | 540 g |
| **Literature range** | 25 g – 50 g – 75 g |
| **Tier** | Confirmed (SUSPICIOUS) |

*Dusky elephant shrew (Macroscelididae; Macroscelidea); adult mass typically 25-75g (mean ~50g); dataset 540g is ~10x typical adult mass; log10(540/50)=1.03 just over threshold; likely data entry error (54g with extra zero?); class and order correct*

**Primary reference (audit):** <https://animaldiversity.org/accounts/Elephantulus_fuscus/>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

### Source: Feldman etal 2016

#### *Calamophis jobiensis*

| | |
|---|---|
| **Database value** | 44,780 g |
| **Corrected value** | 50 g |
| **Literature range** | 10 g – 50 g – 200 g |
| **Tier** | Confirmed (CRITICAL) |

*Small homalopsid snake from Yapen Island (Papua New Guinea); only 4 known specimens; described as small reed snake; 44780g (44.78kg) impossible for any small homalopsid; expected adult mass 10-200g; abs_residual ~2.95 log10 units; data error*

**Primary reference (audit):** <https://reptile-database.reptarium.cz/species?genus=Calamophis&species=jobiensis>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Enhydris innominata*

| | |
|---|---|
| **Database value** | 1.2 g |
| **Corrected value** | 150 g |
| **Literature range** | 50 g – 150 g – 400 g |
| **Tier** | Confirmed (CRITICAL) |

*Tay Ninh mud snake; semi-aquatic homalopsid from Vietnam; congener E. jagorii (similar size) weighs 65-390g (ScienceDirect diet study); 1.2g is ~2.1 log10 units below expected adult minimum; possibly neonate measurement or data entry error*

**Primary reference (audit):** <https://www.fws.gov/species/tay-ninh-mud-snake-enhydris-innominata>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Tropidonophis dolasii*

| | |
|---|---|
| **Database value** | 0.5 g |
| **Corrected value** | 80 g |
| **Literature range** | 20 g – 80 g – 200 g |
| **Tier** | Confirmed (CRITICAL) |

*New Guinea keelback snake (Natricidae); sister species T. novaeguineae reaches 82cm; keelbacks in this genus expected 20-200g; 0.5g is ~2.2 log10 units below expected minimum; likely neonate measurement or decimal/units error*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Tropidonophis_dolasii>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

### Source: fishbase

#### *Carcharhinus altimus*

| | |
|---|---|
| **Database value** | 108 g |
| **Corrected value** | 100,000 g |
| **Literature range** | 30,000 g – 100,000 g – 169,000 g |
| **Tier** | Confirmed (CRITICAL) |

*Bignose shark reaches 282 cm and ~168 kg (FishBase); 108 g is ~3.0 log10 units below expected adult mass; almost certainly a unit or data-entry error*

**Primary reference (audit):** <https://www.fishbase.se/summary/Carcharhinus-altimus.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Charax gibbosus*

| | |
|---|---|
| **Database value** | 30,400 g |
| **Corrected value** | 15 g |
| **Literature range** | 2 g – 15 g – 30.4 g |
| **Tier** | Confirmed (CRITICAL) |

*Glass headstander; FishBase max published weight 30.4 g; dataset 30400 g is exactly 1000x too large; probable kg-to-g or decimal-point conversion error*

**Primary reference (audit):** <https://fishbase.org/summary/12346>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Citharichthys stampflii*

| | |
|---|---|
| **Database value** | 73,000 g |
| **Corrected value** | 150 g |
| **Literature range** | 50 g – 150 g – 400 g |
| **Tier** | Confirmed (CRITICAL) |

*Small West African lefteye flounder max ~30 cm; typical adult ~100-300 g; 73000 g = 73 kg is ~2.7 log10 units above expected; likely order-of-magnitude or unit error*

**Primary reference (audit):** <https://www.fishbase.se/summary/Citharichthys-stampflii.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Dagetichthys lusitanica*

| | |
|---|---|
| **Database value** | 468,000 g |
| **Corrected value** | 200 g |
| **Literature range** | 50 g – 200 g – 1,000 g |
| **Tier** | Confirmed (CRITICAL) |

*Soleidae (sole/flatfish); largest soles weigh <2 kg; 468 kg (468000 g) is impossible; ~3.4 log units above typical; likely magnitude or unit error in FishBase source*

**Primary reference (audit):** <https://www.fishbase.se/summary/Dagetichthys-lusitanica.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Dentiraja australis*

| | |
|---|---|
| **Database value** | 45 g |
| **Corrected value** | 3,000 g |
| **Literature range** | 1,000 g – 3,000 g – 8,000 g |
| **Tier** | Confirmed (CRITICAL) |

*Australian thornback skate; adult expected several kg; 45 g is ~1.8 log10 units below expected; identical mass to Dipturus_australis in this dataset suggests possible data duplication if species are taxonomic synonyms*

**Primary reference (audit):** <https://www.fishbase.se/summary/Dentiraja-australis.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Dipturus australis*

| | |
|---|---|
| **Database value** | 45 g |
| **Corrected value** | 3,000 g |
| **Literature range** | 1,000 g – 3,000 g – 8,000 g |
| **Tier** | Confirmed (CRITICAL) |

*Eastern shovelnose skate; adult expected several kg; 45 g is ~1.8 log10 units below expected; same mass as Dentiraja_australis in this dataset - verify whether these are synonyms and flag for deduplication*

**Primary reference (audit):** <https://www.fishbase.se/summary/Dipturus-australis.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Dipturus trachyderma*

| | |
|---|---|
| **Database value** | 110 g |
| **Corrected value** | 7,000 g |
| **Literature range** | 2,000 g – 7,000 g – 20,000 g |
| **Tier** | Confirmed (CRITICAL) |

*Large South American/Southern Ocean skate reaching ~100 cm TL; 110 g is ~1.8 log10 units below expected adult mass; likely unit error (g vs kg) or larval/juvenile value*

**Primary reference (audit):** <https://www.fishbase.se/summary/Dipturus-trachyderma.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Fontitrygon margarita*

| | |
|---|---|
| **Database value** | 20 g |
| **Corrected value** | 6,000 g |
| **Literature range** | 2,000 g – 6,000 g – 15,000 g |
| **Tier** | Confirmed (CRITICAL) |

*Dakar stingray (formerly Dasyatis/Himantura margarita); disc width up to ~100 cm; 20 g is ~2.5 log10 units below expected adult mass*

**Primary reference (audit):** <https://www.fishbase.se/summary/Fontitrygon-margarita.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Lycodes rossi*

| | |
|---|---|
| **Database value** | 63,000 g |
| **Corrected value** | 30 g |
| **Literature range** | 5 g – 30 g – 63.6 g |
| **Tier** | Confirmed (CRITICAL) |

*FishBase max weight 63.6 g; dataset 63000 g = 63 kg is ~990x the maximum; almost certainly g/kg unit error in source data (63.6 g misread as 63.6 kg then converted)*

**Primary reference (audit):** <https://www.fishbase.se/summary/Lycodes-rossi.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Myliobatis freminvillei*

| | |
|---|---|
| **Database value** | 65 g |
| **Corrected value** | 8,000 g |
| **Literature range** | 3,000 g – 8,000 g – 25,000 g |
| **Tier** | Confirmed (CRITICAL) |

*Bullnose ray; wingspan ~100 cm; adult mass typically 4-10 kg; 65 g is ~2.1 log10 units below expected adult mass*

**Primary reference (audit):** <https://www.fishbase.se/summary/Myliobatis-freminvillei.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Nannobrachium regale*

| | |
|---|---|
| **Database value** | 0.0114 g |
| **Corrected value** | 15 g |
| **Literature range** | 3 g – 15 g – 60 g |
| **Tier** | Confirmed (CRITICAL) |

*Lanternfish (Myctophidae; FishBase accepted name Lampanyctus regalis); FishBase max 21cm TL; adults expected ~3-60g; 0.0114g (11.4mg) is ~3.1 log10 units below expected; likely FishBase data entry error in source dataset*

**Primary reference (audit):** <https://fishbase.se/summary/Nannobrachium-regale.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Citharichthys spilopterus*

> **Status:** Pending — correct value not yet confirmed

| | |
|---|---|
| **Database value** | 6.5 g |
| **Literature range** | 30 g – 200 g – 597 g |
| **Tier** | Confirmed (SUSPICIOUS) |

*Bay whiff flatfish; FishBase max 36.8 cm TL; max published weight 597g; typical adult ~100-300g; |log10(6.5)-log10(200)|=1.49 log units; 6.5g corresponds to ~10 cm juvenile; dataset value is likely a juvenile or erroneous measurement*

**Primary reference (audit):** <https://www.fishbase.se/summary/Citharichthys-spilopterus>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Echinorhinus brucus*

> **Status:** Pending — correct value not yet confirmed

| | |
|---|---|
| **Database value** | 76 g |
| **Literature range** | 5,000 g – 50,000 g – 200,000 g |
| **Tier** | Confirmed (SUSPICIOUS) |

*Taxonomy correct: Squaliformes; Echinorhinidae; bramble shark; FishBase max TL ~310 cm; adults commonly 150-260 cm; expected adult body mass 20-200 kg; dataset 76 g is many orders of magnitude too low for any adult or even juvenile specimen (bramble shark pups born at ~38-44 cm TL and would exceed 200 g at birth); |log10(76)-log10(50000)| = 2.82 log units; ERRONEOUS_MASS; likely a unit error (76 kg = 76000 g would be plausible for a medium-sized adult); dataset source FishBase with ref 1*

**Primary reference (audit):** <https://www.fishbase.se/summary/Echinorhinus-brucus.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Lepidion schmidti*

> **Status:** Pending — correct value not yet confirmed

| | |
|---|---|
| **Database value** | 14,700 g |
| **Literature range** | 80 g – 300 g – 800 g |
| **Tier** | Confirmed (SUSPICIOUS) |

*Schmidt's codling (Moridae); deep-sea gadiform fish; FishBase max TL ~43 cm; a slender 43 cm morid using typical gadiform LWR (a~0.005; b~3.1) yields max weight ~300-600 g; dataset 14700 g = 14.7 kg is ~1.69 log10 units above typical adult mass and ~1.27 log10 units above estimated max — completely inconsistent with a 43 cm fish; single source (n=1) from FishBase; likely a factor-of-10 or factor-of-100 data entry error in the FishBase record; taxonomy correct; recommend verifying original FishBase source and correcting mass*

**Primary reference (audit):** <https://fishbase.se/summary/Lepidion-schmidti.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

### Source: Gillooly etal 2016

#### *Prochilodus scrofa*

| | |
|---|---|
| **Database value** | 21 g |
| **Corrected value** | 2,000 g |
| **Literature range** | 500 g – 2,000 g – 7,200 g |
| **Tier** | Confirmed (CRITICAL) |

*Synonym of P. lineatus (streaked prochilod); FishBase max weight 7.2 kg; 21 g represents a juvenile/small study specimen not a typical adult; source Gillooly_etal_2016 likely used small metabolic study specimens; log10 diff ~2.0 vs typical adult*

**Primary reference (audit):** <https://www.fishbase.org/summary/Prochilodus-lineatus.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

### Source: Hirt etal 2017

#### *Carassius leucas*

| | |
|---|---|
| **Database value** | 19,540 g |
| **Corrected value** | 500 g |
| **Literature range** | 50 g – 500 g – 3,000 g |
| **Tier** | Confirmed (CRITICAL) |

*Magnoliopsida = flowering plants — Carassius is a freshwater fish genus (Actinopterygii; Cyprinidae); epithet leucas is not a recognized Carassius species in FishBase (possible data chimera with Carcharhinus leucas or a data-entry error); largest valid Carassius spp. (C. carassius) reach ~5 kg; 19540 g exceeds typical by >1 log10 unit relative to genus median; both class and mass are erroneous*

**Primary reference (audit):** <https://www.fishbase.se/summary/Carassius-carassius>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

### Source: Killen etal 2016

#### *Aristichthys nobilis*

| | |
|---|---|
| **Database value** | 6.19 g |
| **Corrected value** | 20,000 g |
| **Literature range** | 2,000 g – 20,000 g – 40,800 g |
| **Tier** | Confirmed (CRITICAL) |

*Bighead carp; typical adult 2–40 kg; IGFA record 40.8 kg; dataset 6.19 g is ~3200x too small; probable juvenile or unit error in Killen_etal_2016*

**Primary reference (audit):** <https://www.fishbase.se/summary/Aristichthys-nobilis.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

### Source: Makarieva 2008

#### *Brasilanus batus*

| | |
|---|---|
| **Database value** | 1.965 g |
| **Corrected value** | 0.01 g |
| **Literature range** | 0.001 g – 0.01 g – 0.02 g |
| **Tier** | Confirmed (CRITICAL) |

*Hemiptera: Cicadellidae (leafhoppers; subfamily Deltocephalinae); species epithet batus not listed — only B. flagellaris and B. lateralis known; 1.965g is ~2.3 log10 above expected leafhopper mass (~1-20mg); verify species identity*

**Primary reference (audit):** <https://species.wikimedia.org/wiki/Brasilanus>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Gonatus onyx*

| | |
|---|---|
| **Database value** | 0.117 g |
| **Corrected value** | 120 g |
| **Literature range** | 30 g – 120 g – 300 g |
| **Tier** | Confirmed (CRITICAL) |

*Black-eyed squid adults reach 12-18 cm ML (spent females 132-145 mm ML); estimated adult mass 50-300 g; dataset 0.117 g is ~3.0 log10 units below typical ~120 g; Makarieva 2008 metabolic study likely used a very small juvenile or paralarvae*

**Primary reference (audit):** <https://www.sealifebase.se/summary/Gonatus-onyx.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Helius waiti*

| | |
|---|---|
| **Database value** | 0.672 g |
| **Corrected value** | 0.04 g |
| **Literature range** | 0.005 g – 0.04 g – 0.1 g |
| **Tier** | Confirmed (CRITICAL) |

*Limoniidae crane fly (Diptera); typical adult Helius mass 5-100mg; 672mg is ~1.2 log10 too high; species epithet waiti not found in Helius species list on Wikipedia*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Helius_(fly)>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Naucrates ductor*

| | |
|---|---|
| **Database value** | 0.07 g |
| **Corrected value** | 800 g |
| **Literature range** | 200 g – 800 g – 3,000 g |
| **Tier** | Confirmed (CRITICAL) |

*Pilotfish (Carangidae); FishBase max 70cm TL; typical 40cm; adults ~200-3000g; 0.07g is ~4.1 log10 units below expected; catastrophically erroneous value*

**Primary reference (audit):** <https://fishbase.se/summary/Naucrates-ductor.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Octopus rubescens*

| | |
|---|---|
| **Database value** | 0.096 g |
| **Corrected value** | 125 g |
| **Literature range** | 50 g – 125 g – 400 g |
| **Tier** | Confirmed (CRITICAL) |

*Adult East Pacific red octopus typically 100-150 g; max ~400 g confirmed; dataset 0.096 g is ~3.1 log10 units below typical 125 g; Makarieva 2008 likely used a hatchling or very small juvenile*

**Primary reference (audit):** <https://www.dimensions.com/element/east-pacific-red-octopus-octopus-rubescens>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Rana cyanophlyctis*

| | |
|---|---|
| **Database value** | 0.294 g |
| **Corrected value** | 15 g |
| **Literature range** | 5 g – 15 g – 40 g |
| **Tier** | Confirmed (SUSPICIOUS) |

*Skittering frog (Euphlyctis cyanophlyctis); typical adult 5-40 g. 0.294 g is ~50x too low for this medium-sized frog. Source Makarieva_2008 likely recorded an incorrect unit or juvenile.*

**Primary reference (audit):** <https://amphibiaweb.org/species/4214>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Bufo debilus*

> **Status:** Pending — correct value not yet confirmed

| | |
|---|---|
| **Database value** | 0.66 g |
| **Literature range** | 4 g – 8 g – 20 g |
| **Tier** | Confirmed (SUSPICIOUS) |

*Green toad (Anaxyrus debilis); typical adult 4-20 g. 0.66 g is an order of magnitude too low.*

**Primary reference (audit):** <https://amphibiaweb.org/species/474>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

### Source: Oliveira 2017

#### *Eleutherodactylus johnstonei*

| | |
|---|---|
| **Database value** | 24 g |
| **Corrected value** | 4 g |
| **Literature range** | 1.5 g – 4 g – 8 g |
| **Tier** | Confirmed (SUSPICIOUS) |

*Johnstone's whistling frog; well-studied small Caribbean species, adults typically 2-8 g. 24 g is ~5x too high; likely unit or multi-source averaging error.*

**Primary reference (audit):** <https://amphibiaweb.org/species/1813>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

### Source: Pappantoniou 1984

#### *Exoglossum maxillingua*

| | |
|---|---|
| **Database value** | 0.75 g |
| **Corrected value** | 40 g |
| **Literature range** | 10 g – 40 g – 100 g |
| **Tier** | Confirmed (CRITICAL) |

*Cutlips minnow (Cyprinidae); max ~20 cm; adult typically 20-100g; 0.75g likely juvenile or unit error in Pappantoniou 1984; ~1.7 log units below typical adult*

**Primary reference (audit):** <https://www.fishbase.se/summary/Exoglossum-maxillingua.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

### Source: Pauly 2024

#### *Pholis clemensi*

| | |
|---|---|
| **Database value** | 0.4 g |
| **Corrected value** | 6 g |
| **Literature range** | 2 g – 6 g – 20 g |
| **Tier** | Confirmed (CRITICAL) |

*Crescent gunnel (Pholidae); FishBase max 13cm TL; eel-like elongate body; expected ~2-20g for adults; 0.4g is ~1.2 log10 units below expected*

**Primary reference (audit):** <https://fishbase.se/summary/Pholis-clemensi.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Prionotus scitulus*

| | |
|---|---|
| **Database value** | 1.1 g |
| **Corrected value** | 100 g |
| **Literature range** | 20 g – 100 g – 400 g |
| **Tier** | Confirmed (CRITICAL) |

*Leopard searobin (Triglidae); FishBase max 25cm TL; adults expected ~20-400g; 1.1g is ~2 log10 units below expected*

**Primary reference (audit):** <https://fishbase.se/summary/Prionotus-scitulus.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Scorpaena pascuensis*

| | |
|---|---|
| **Database value** | 1.6 g |
| **Corrected value** | 200 g |
| **Literature range** | 50 g – 200 g – 800 g |
| **Tier** | Confirmed (CRITICAL) |

*Easter Island scorpionfish; adult Scorpaena species typically 50-500+ g; 1.6 g is ~2.1 log10 units below expected adult mass; likely a juvenile or data-entry error; Pauly_2024 source should be verified*

**Primary reference (audit):** <https://www.fishbase.se/summary/Scorpaena-pascuensis.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Synodus lacertinus*

| | |
|---|---|
| **Database value** | 0.7 g |
| **Corrected value** | 80 g |
| **Literature range** | 30 g – 80 g – 200 g |
| **Tier** | Confirmed (CRITICAL) |

*Sauro lizardfish; FishBase max 27.2 cm SL; congeners S. foetens max 900 g and S. saurus max 300 g; 0.7 g is ~2.1 log units below estimated typical adult mass for a 20-27 cm lizardfish; source Pauly_2024*

**Primary reference (audit):** <https://www.fishbase.se/summary/synodus-lacertinus>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Jordania zonope*

> **Status:** Pending — correct value not yet confirmed

| | |
|---|---|
| **Database value** | 1.5 g |
| **Literature range** | 5 g – 15 g – 25 g |
| **Tier** | Confirmed (SUSPICIOUS) |

*Longfin sculpin (Cottidae / Jordaniidae; NE Pacific; Alaska to California); FishBase max TL 15.0 cm; FishBase Bayesian W-L a=0.00389 b=3.12 gives 18.2 g at max TL; 1.5 g corresponds to only ~6.7 cm TL (juvenile); 1.08 log10 units below expected adult (18 g); source Pauly_2024 likely a food-web model using cohort or juvenile mean; recommend replacing with species-typical adult mass (~15 g); taxonomy correct*

**Primary reference (audit):** <https://fishbase.se/summary/Jordania-zonope.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

### Source: Quaardvark

#### *Latrodectus hesperus*

| | |
|---|---|
| **Database value** | 25 g |
| **Corrected value** | 0.35 g |
| **Literature range** | 0.18 g – 0.35 g – 0.87 g |
| **Tier** | Confirmed (CRITICAL) |

*"Western black widow spider. Adult females 8-13 mm body length; known mass 0.18-0.87 g. A mass of 25 g would require a tarantula-sized body. This is a ~70x overestimate; possible data entry or source confusion error."*

**Peer-reviewed citations:**

- Blackledge, T.A., Eliason, C.M., Cardullo, R.A., & Dyer, S. (2007). Condition-dependent spider web architecture in the western black widow, *Latrodectus hesperus*. *Animal Behaviour*, 73(5), 855–864. https://doi.org/10.1016/j.anbehav.2007.01.007
  - *Experimentally measured body mass of adult/penultimate female L. hesperus; 25 g in dataset is biologically impossible for this species.*

---

#### *Nematostella vectensis*

> **Status:** Pending — correct value not yet confirmed

| | |
|---|---|
| **Database value** | 17.5 g |
| **Literature range** | 0.001 g – 0.01 g – 0.03 g |
| **Tier** | Confirmed (SUSPICIOUS) |

*Starlet sea anemone; well-characterised model organism; adults 10-35 mm body length and ~1-3 mm column diameter; typical wet mass 0.001-0.030 g (1-30 mg); dataset value 17.5 g is ~3.5 log10 units above expected; source is Quaardvark (non-standard aggregator); likely data entry error or unit confusion; recommend correction to ~0.005-0.010 g or removal if no primary source traceable*

**Primary reference (audit):** <https://www.marinespecies.org/>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

### Source: sealifebase

#### *Acanthosepion pharaonis*

| | |
|---|---|
| **Database value** | 3.175 g |
| **Corrected value** | 1,500 g |
| **Literature range** | 500 g – 1,500 g – 5,000 g |
| **Tier** | Confirmed (CRITICAL) |

*Sepia pharaonis (accepted name; Acanthosepion pharaonis is a synonym) is a large cuttlefish with max weight 5 kg (SeaLifeBase); typical adult 500-5000 g; dataset 3.175 g is ~2.67 log10 units below typical 1500 g; likely juvenile specimen or data entry unit error*

**Primary reference (audit):** <https://www.sealifebase.ca/summary/Acanthosepion-pharaonis.html>

**Peer-reviewed citations:**

- Sasikumar G, Mohamed KS, & Bhat US. (2013). Inter-cohort growth patterns of pharaoh cuttlefish Sepia pharaonis (Sepioidea: Sepiidae) in Eastern Arabian Sea. Revista de Biología Tropical, 61(1), 1–14. https://doi.org/10.15517/rbt.v61i1.10871
  - *Mass reported: 1200 g — Calculated from reported length-weight relationships (Males: W = 0.33069 × L^2.5389; Females: W = 0.32542 × L^2.6057) for a typical adult mantle length of ~25 cm. Study covered 12,454 wild-caught specimens ranging 4–41 cm dorsal mantle length from Eastern Arabian Sea fishery, yielding body masses of ~650–2300 g across the adult size range, consistent with a species-typical value of ~1200–1500 g.*
- Asvad SR, Esmaili-Sari A, Dahmardeh Behrooz R, Rajaei F, Valinasab T, & Chakraborty P. (2024). Comparison of Cd, Cu, Se, and Zn Concentration in the Muscle and Hepatopancreas of Sepia pharaonis and Uroteuthis duvauceli in the North of Persian Gulf (Iran). Biological Trace Element Research, 202(2), 743–753. https://doi.org/10.1007/s12011-023-03712-1
  - *Paper collected wild Sepia pharaonis specimens from the Persian Gulf and measured biometrical factors including total body length and weight as covariates in metal concentration analyses, confirming that adult specimens are large enough to show negative significant correlations between copper and biometrical factors. Specific mass values not reported in abstract.*

---

#### *Cephalodiscus gilchristi*

| | |
|---|---|
| **Database value** | 166,000 g |
| **Corrected value** | 0.005 g |
| **Literature range** | 1.000e-05 g – 0.005 g – 1 g |
| **Tier** | Confirmed (CRITICAL) |

*Pterobranches are minute colonial hemichordates; individual zooids measure 0.5-3 mm; entire colonies reach at most a few grams wet mass; 166000 g (166 kg) exceeds the total biomass of any conceivable colony by approximately 7 log10 units; catastrophic data entry or unit error; correct mass likely in the range 0.001-1 g*

**Primary reference (audit):** <https://www.marinespecies.org/aphia.php?p=search&query=Cephalodiscus+gilchristi>

**Peer-reviewed citations:**

- Tassia, M. G., Cannon, J. T., Konikoff, C. E., Shenkar, N., Halanych, K. M., & Swalla, B. J. (2016). The Global Diversity of Hemichordata. PLOS ONE, 11(10), e0162564. https://doi.org/10.1371/journal.pone.0162564
  - *No body mass data reported; taxonomic review only.*
- Worsaae, K., Sterrer, W., Kaul-Strehlow, S., Hay-Schmidt, A., & Giribet, G. (2012). An anatomical description of a miniaturized acorn worm (Hemichordata, Enteropneusta) with asexual reproduction by paratomy. PLOS ONE, 7(11), e48529. https://doi.org/10.1371/journal.pone.0048529
  - *Body length 0.6 mm reported for a miniaturized enteropneust; no mass given. Consistent with sub-mg body mass for mm-scale hemichordate zooids.*
- Davies-Coleman, M. T., & Veale, C. G. (2015). Recent Advances in Drug Discovery from South African Marine Invertebrates. Marine Drugs, 13(10), 6366–6383. https://doi.org/10.3390/md13106366
  - *No body mass reported. Cephalostatin isolation yields (10^-7 % by weight) imply very small zooid mass relative to bulk-collected colony material.*

---

### Source: Viana 2016

#### *Caranx ruber*

| | |
|---|---|
| **Database value** | 81.9 g |
| **Corrected value** | 2,640 g |
| **Literature range** | 500 g – 2,640 g – 8,200 g |
| **Tier** | Confirmed (CRITICAL) |

*Bar jack; FishBase max weight 8.2 kg at 73 cm FL; common length 50 cm; typical adult ~2640 g; dataset 81.9 g is 1.51 log10 units below typical adult mass; likely juvenile used in respirometry (Viana_2016)*

**Primary reference (audit):** <https://www.fishbase.se/summary/Caranx-ruber>

**Peer-reviewed citations:**

- Mahé, K., Baudrier, J., Larivain, A., Telliez, S., Elleboode, R., Bultel, E., & Pawlowski, L. (2023). Morphometric Relationships between Length and Weight of 109 Fish Species in the Caribbean Sea (French West Indies). Animals, 13(24), 3852. https://doi.org/10.3390/ani13243852
  - *Reports length-weight relationship for Caranx ruber based on n=907 specimens from Guadeloupe and Martinique (Caribbean): W = 0.0056 × TL^3.1653 (W in g, TL in cm). Applying these parameters at 62 cm TL yields approximately 2640 g, consistent with the corrected adult body mass value. Max published weight for this species is 8.2 kg.*

---

#### *Lutjanus synagris*

| | |
|---|---|
| **Database value** | 1.5 g |
| **Corrected value** | 500 g |
| **Literature range** | 100 g – 500 g – 3,500 g |
| **Tier** | Confirmed (CRITICAL) |

*FishBase max 3.5 kg; dataset 1.5 g is ~1000x below typical adult mass; difference >3 log10 units*

**Primary reference (audit):** <https://www.fishbase.se/summary/lutjanus-synagris>

**Peer-reviewed citations:**

- Santos, R.S., dos Santos, J.A.T., & Furtado-Neto, M.A.A. (2022). Reproductive biology of the lane snapper, *Lutjanus synagris* (Linnaeus 1758) (Perciformes, Lutjanidae), in the Maranhão continental shelf, Northeast of Brazil. *Environmental Biology of Fishes*, 105, 1031–1046. https://doi.org/10.1007/s10641-022-01310-z
  - *Length-weight relationships for L. synagris; confirms dataset value of 1.5 g is inconsistent with adult body size.*
- Sierra Castillo, L., & Fujiwara, M. (2021). Assessment of a small-scale fishery: Lane Snapper (*Lutjanus synagris*) using a length metric method. *PLOS ONE*, 16(2), e0233479. https://doi.org/10.1371/journal.pone.0233479
  - *Records fork length and weight (grams) for lane snapper; supports corrected value of ~500 g for adult fish.*

---

### Source: Wilman etal 2014

#### *Psittinus cyanurus*

| | |
|---|---|
| **Database value** | 11.77 g |
| **Corrected value** | 54 g |
| **Literature range** | 40 g – 54 g – 60 g |
| **Tier** | Confirmed (SUSPICIOUS) |

*"Blue-rumped Parrot. Documented mass 40-60 g across multiple sources. 11.77 g is approximately 4x too light and clearly erroneous; likely a data-entry or unit-conversion error."*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Blue-rumped_parrot>

**Peer-reviewed citations:**

- Dunning, J.B., Jr. (2008). *CRC Handbook of Avian Body Masses*, 2nd ed. CRC Press. https://doi.org/10.1201/9781420064452
  - *Standard reference for avian body masses; Blue-rumped Parrot (Psittinus cyanurus) is a small parrot (~18 cm) with adult mass documented as ~55–75 g; dataset value of 11.77 g is ~4–6x too small.*

---

## Tier: Suspicious

### Source: AmphiBIO

#### *Craugastor laticeps*

| | |
|---|---|
| **Database value** | 80 g |
| **Corrected value** | 20 g |
| **Literature range** | 5 g – 20 g – 45 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Even large Craugastor species rarely exceed 40-50 g; 80 g is implausibly high. Residual +1.79 confirms large over-shoot.*

**Primary reference (audit):** <https://amphibiaweb.org/species/1008>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Craugastor rugulosus*

| | |
|---|---|
| **Database value** | 75 g |
| **Corrected value** | 15 g |
| **Literature range** | 5 g – 15 g – 40 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Large-bodied Craugastor but 75 g is implausibly high; typical adults 5-40 g. Residual +1.76 confirms error.*

**Primary reference (audit):** <https://amphibiaweb.org/species/1033>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Eleutherodactylus cubanus*

| | |
|---|---|
| **Database value** | 0.18 g |
| **Corrected value** | 1.5 g |
| **Literature range** | 0.5 g – 1.5 g – 5 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Cuban Eleutherodactylus; even the smallest species in genus typically 0.5 g+. 0.18 g is below the plausible minimum for any adult Eleutherodactylus; likely a juvenile or unit error.*

**Primary reference (audit):** <https://amphibiaweb.org/species/1782>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Hypsiboas faber*

| | |
|---|---|
| **Database value** | 95 g |
| **Corrected value** | 25 g |
| **Literature range** | 10 g – 25 g – 50 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Blacksmith tree frog (Boana faber); adults typically 10-50 g. 95 g is ~2-4x too high; mass may be inflated by an outlier source or mis-assignment.*

**Primary reference (audit):** <https://amphibiaweb.org/species/2300>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Hypsiboas rosenbergi*

| | |
|---|---|
| **Database value** | 93 g |
| **Corrected value** | 25 g |
| **Literature range** | 10 g – 25 g – 50 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Rosenberg's tree frog (Boana rosenbergi); adults typically 10-50 g. 93 g is ~2-4x too high; likely an outlier source inflated the mean.*

**Primary reference (audit):** <https://amphibiaweb.org/species/2320>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Ischnocnema parva*

| | |
|---|---|
| **Database value** | 19 g |
| **Corrected value** | 3 g |
| **Literature range** | 1 g – 3 g – 8 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Species epithet 'parva' (small); Ischnocnema are generally small leptodactylids 1-8 g. 19 g is ~5x the expected maximum and likely erroneous.*

**Primary reference (audit):** <https://amphibiaweb.org/species/2440>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Leptodactylus labyrinthicus*

| | |
|---|---|
| **Database value** | 561 g |
| **Corrected value** | 180 g |
| **Literature range** | 80 g – 180 g – 350 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Large South American Leptodactylus but even the largest congener (L. pentadactylus) reaches ~200-250 g. 561 g is ~2-3x too high; likely a multi-source averaging error including a different species.*

**Primary reference (audit):** <https://amphibiaweb.org/species/2854>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Leptodactylus vastus*

| | |
|---|---|
| **Database value** | 1,000 g |
| **Corrected value** | 100 g |
| **Literature range** | 30 g – 100 g – 200 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Even the largest Leptodactylus (L. pentadactylus) reaches ~200-250 g. 1000 g is ~4-5x beyond any known Leptodactylus mass; likely a unit or data merger error.*

**Primary reference (audit):** <https://amphibiaweb.org/species/2897>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

### Source: Brose etal 2018

#### *Alpheus normanni*

| | |
|---|---|
| **Database value** | 0.004046 g |
| **Corrected value** | 0.1 g |
| **Literature range** | 0.04 g – 0.1 g – 0.4 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Snapping shrimp (Alpheidae; Decapoda); adults ~20-25mm TL; congeners A. formosus (0.107g) and A. heterochaelis (0.093g) from same Brose_etal_2018 source both ~0.1g; dataset 0.004046g (4mg) is ~1.4 log10 below congener range; likely mg-to-g unit error; taxonomy correct (Decapoda; Malacostraca)*

**Primary reference (audit):** <https://www.marinespecies.org/aphia.php?p=taxdetails&id=156684>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Amauropsis rossiana*

| | |
|---|---|
| **Database value** | 0.01 g |
| **Corrected value** | 4 g |
| **Literature range** | 1 g – 3 g – 10 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Antarctic naticid moon snail (Naticidae; Littorinimorpha); Wikipedia gives shell max 29 mm x 25 mm; expected adult wet mass for a 29 mm naticid is 1-10 g; dataset 0.01 g (10 mg) is approximately 2-3 log10 units below expected wet mass; source Jacob et al. (2011) Weddell Sea food web — values for this study likely represent AFDM or carbon mass; not consistent with wet body mass; lit values are size-derived estimates for a 29 mm naticid*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Amauropsis_rossiana>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Ampelisca richardsoni*

| | |
|---|---|
| **Database value** | 0.81 g |
| **Corrected value** | 0.02 g |
| **Literature range** | 0.003 g – 0.009 g – 0.025 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Tube-building amphipod (Ampeliscidae; Amphipoda); adults 7-12mm; congeners A. brevicornis (0.0074g); A. diadema (0.0062g); A. vadorum (0.0118g); A. verrilli (0.0118g) all 6-12mg in same dataset; dataset 0.81g (810mg) is ~2 log10 above entire congener cluster; highest abs_residual in batch (1.892); likely data entry error or wrong organism assigned; taxonomy correct (Amphipoda; Malacostraca)*

**Primary reference (audit):** <https://www.marinespecies.org/aphia.php?p=taxdetails&id=101626>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Anonyx nugax*

| | |
|---|---|
| **Database value** | 0.005048 g |
| **Corrected value** | 1 g |
| **Literature range** | 0.08 g – 0.3 g – 1 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Large scavenging amphipod (Uristidae; Amphipoda); adults 30-55mm TL in N. Atlantic/Arctic; known scavenger with substantial body mass; expected wet mass 0.08-1.0g; dataset 0.005048g (5mg) is ~1.8 log10 below typical adult; Brose_etal_2018; likely mg-to-g unit error; congener A. sarsi shows same pattern; taxonomy correct*

**Primary reference (audit):** <https://www.marinespecies.org/aphia.php?p=taxdetails&id=102017>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Anonyx sarsi*

| | |
|---|---|
| **Database value** | 0.007402 g |
| **Corrected value** | 0.15 g |
| **Literature range** | 0.05 g – 0.15 g – 0.6 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Scavenging amphipod (Uristidae; Amphipoda); adults 20-40mm TL; expected wet mass 0.05-0.6g; dataset 0.007402g (7.4mg) is ~1.3 log10 below typical; Brose_etal_2018; same systematic pattern as A. nugax; likely mg-to-g unit error; taxonomy correct (Amphipoda; Malacostraca)*

**Primary reference (audit):** <https://www.marinespecies.org/aphia.php?p=taxdetails&id=102018>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Asterias forbesi*

| | |
|---|---|
| **Database value** | 0.9319 g |
| **Corrected value** | 80 g |
| **Literature range** | 10 g – 100 g – 400 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Forbes sea star; typical adult arm radius 7-12 cm; adult wet mass 10-400 g; dataset 0.9319 g is ~2.0 log10 units below typical adult; possible juvenile or data entry error; taxonomy correct*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Asterias_forbesi>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Boreotrophon truncatus*

| | |
|---|---|
| **Database value** | 0.04064 g |
| **Corrected value** | 1 g |
| **Literature range** | 0.2 g – 0.5 g – 2 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Small Arctic muricid snail (Muricidae; Neogastropoda); from Eklof et al. (2013) Kongsfjorden food web via Brose_etal_2018 (published accounts); dataset 40.6 mg; expected adult wet mass 200-2000 mg for a small muricid; Buccinum_undatum from the same Eklof 2013 study shows 50.7 mg vs 125.3 g in Jennings (2002) — a 2450x discrepancy — confirming Eklof 2013 values are in non-wet-mass units (likely AFDM or carbon mass); same unit error applies to Boreotrophon truncatus; lit range is wet-mass size estimate*

**Primary reference (audit):** <https://www.marinespecies.org/aphia.php?p=taxdetails&id=139226>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Clibanarius vittatus*

| | |
|---|---|
| **Database value** | 0.03662 g |
| **Corrected value** | 2 g |
| **Literature range** | 0.5 g – 2 g – 8 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Striped hermit crab (Diogenidae; Decapoda); adults 30-80mm total length with shield length 10-25mm; wet mass ~0.5-8g for medium-to-large adults (ADW); dataset 0.03662g (36.6mg) is ~1.7 log10 below typical adult mass; same Brose_etal_2018 systematic underestimation pattern seen in other invertebrates; likely mg-to-g unit error*

**Primary reference (audit):** <https://animaldiversity.org/accounts/Clibanarius_vittatus/>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Corophium acutum*

| | |
|---|---|
| **Database value** | 0.01735 g |
| **Corrected value** | 0.001 g |
| **Literature range** | 2.000e-04 g – 0.001 g – 0.003 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Tube-building mud amphipod (Corophiidae; Amphipoda); valid accepted name is Apocorophium acutum per WoRMS (Corophium acutum is a synonym); adults 5-10mm; congener Corophium volutator wet mass ~0.3-1.5mg per published studies; dataset 17.35mg is ~1.2 log10 above genus typical; likely mass unit error in Brose_etal_2018; genus reclassification from Corophium to Apocorophium noted*

**Primary reference (audit):** <https://www.marinespecies.org/aphia.php?p=taxdetails&id=102299>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Apocorophium acutum*

| | |
|---|---|
| **Database value** | — |
| **Corrected value** | 0.001 g |
| **Tier** | Suspicious () |

*corrected name; same value as above*

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Eunoe hartmanae*

| | |
|---|---|
| **Database value** | 57 g |
| **Corrected value** | 2 g |
| **Literature range** | 0.05 g – 1 g – 5 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Eunoe is a genus of Polynoidae (scale worms); all known polynoid scale worms are small (typically <10cm; rarely >5-10g); even the largest Antarctic polynoids (e.g. Eulagisca gigantea) reach only ~20g; 57g for Eunoe hartmanae is implausibly large; likely a data transcription error (factor of 10-100 too high); expected adult mass 0.1-5g; taxonomy correct*

**Primary reference (audit):** <https://www.marinespecies.org/aphia.php?p=search&target=taxa&searchtype=contains&query=Eunoe+hartmanae>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Euphausia krohnii*

| | |
|---|---|
| **Database value** | 0.001707 g |
| **Corrected value** | 0.05 g |
| **Literature range** | 0.01 g – 0.05 g – 0.15 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Mesopelagic krill (Euphausiidae; Euphausiacea); same species as Euphausia_krohni (alternate spelling); adults 12-22mm TL; dataset 1.707mg is ~1.47 log10 below typical adult wet mass; dataset contains duplicate records for this species (krohni=0.004g from Brown_etal_2018 vs krohnii=0.001707g from Castro_2025); both values appear too low; deduplicate and correct; taxonomy correct (Euphausiacea; Malacostraca)*

**Primary reference (audit):** <https://www.marinespecies.org/aphia.php?p=taxdetails&id=110703>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Gammarus daiberi*

| | |
|---|---|
| **Database value** | 0.001177 g |
| **Corrected value** | 0.1 g |
| **Literature range** | 0.02 g – 0.08 g – 0.25 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Large estuarine amphipod (Gammaridae; Amphipoda); adults 15-25mm body length; typical adult wet mass 20-250mg based on Gammaridae size-weight relationships and congener data; dataset value 1.177mg (0.001177g) is ~1.83 log10 below typical adult mass; same exact value shared with three other Gammarus spp and with small amphipods Colomastix_pusilla and Elasmopus_levis from batch 2 (2-4mm body) — that value is appropriate only for 2-4mm amphipods; likely a shared Brose_etal_2018 mass-bin placeholder assigned to a much larger species; taxonomy correct (Amphipoda; Malacostraca)*

**Primary reference (audit):** <https://www.marinespecies.org/aphia.php?p=taxdetails&id=102308>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Gammarus fasciatus*

| | |
|---|---|
| **Database value** | 0.001177 g |
| **Corrected value** | 0.05 g |
| **Literature range** | 0.01 g – 0.05 g – 0.15 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Freshwater scud (Gammaridae; Amphipoda); adults 10-23mm body length; typical adult wet mass 10-150mg based on published Gammaridae data; dataset value 1.177mg is ~1.63 log10 below typical adult mass; exact shared value with three other Gammarus spp and multiple small 2-4mm amphipods from batch 2 confirms this is a size-class placeholder not appropriate for a 10-23mm species; taxonomy correct (Amphipoda; Malacostraca)*

**Primary reference (audit):** <https://animaldiversity.org/accounts/Gammarus_fasciatus/>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Gammarus mucronatus*

| | |
|---|---|
| **Database value** | 0.001177 g |
| **Corrected value** | 0.02 g |
| **Literature range** | 0.003 g – 0.012 g – 0.04 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Estuarine amphipod (Gammaridae; Amphipoda); smaller species with adults 5-12mm; typical adult wet mass 3-40mg; dataset value 1.177mg is ~1.0 log10 below typical and below minimum adult mass for this species; same shared placeholder value as three other Gammarus spp; even for this smaller species the value is too low for typical adults; taxonomy correct (Amphipoda; Malacostraca)*

**Primary reference (audit):** <https://www.marinespecies.org/aphia.php?p=taxdetails&id=102317>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Gammarus tigrinus*

| | |
|---|---|
| **Database value** | 0.001177 g |
| **Corrected value** | 0.03 g |
| **Literature range** | 0.004 g – 0.018 g – 0.06 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Invasive amphipod introduced to Europe (Gammaridae; Amphipoda); adults 8-15mm body length; typical adult wet mass 4-60mg; dataset value 1.177mg is ~1.18 log10 below typical adult mass; same shared placeholder value as three other Gammarus spp; value appropriate only for 2-4mm amphipods; taxonomy correct (Amphipoda; Malacostraca)*

**Primary reference (audit):** <https://www.marinespecies.org/aphia.php?p=taxdetails&id=102319>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Hyas coarctatus*

| | |
|---|---|
| **Database value** | 0.225 g |
| **Corrected value** | 30 g |
| **Literature range** | 5 g – 25 g – 80 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Toad crab / Arctic lyre crab (Oregoniidae; Decapoda); adults: males carapace length up to 65mm; females up to 50mm; typical adult wet mass 5-80g based on size-weight relationships for brachyuran crabs of this carapace size; dataset value 0.225g (225mg) is ~2.05 log10 below typical adult mass; almost certainly a units error — mass likely in mg entered as g (i.e. true value closer to 225g seems too high; more likely data is in mg and should be ~0.025-0.075g after recalculation; regardless current value is clearly erroneous); same pattern as Clibanarius_vittatus (batch 2) where Brose values underestimated by similar factor; taxonomy correct (Decapoda; Malacostraca)*

**Primary reference (audit):** <https://www.sealifebase.ca/summary/Hyas-coarctatus.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Ischnochiton striolatus*

| | |
|---|---|
| **Database value** | 0.01563 g |
| **Corrected value** | 0.15 g |
| **Literature range** | 0.05 g – 0.2 g – 1 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Small chiton ~10-30mm length; Brose_etal_2018 likely reports AFDW; 0.01563g is ~1.1 log10 units below expected adult wet mass ~0.05-1g; likely AFDW not wet mass*

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Labidocera jollae*

| | |
|---|---|
| **Database value** | 0.0418 g |
| **Corrected value** | 2.000e-04 g |
| **Literature range** | 1.000e-04 g – 2.000e-04 g – 5.000e-04 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Mass 0.0418 g = 41800 µg is ~100-400x too large for Pontellidae (expected 100-500 µg wet); congeners L. aestiva and L. wollastoni both at 4.01e-05 g in same Brose dataset; log10 offset ~2.3 from expected; likely unit conversion error (0.0418 mg entered as 0.0418 g rather than 4.18e-05 g); WoRMS AphiaID 346602 confirms valid Pontellidae species*

**Primary reference (audit):** <https://www.marinespecies.org/aphia.php?p=taxdetails&id=346602>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Liljeborgia georgiana*

| | |
|---|---|
| **Database value** | 0.59 g |
| **Corrected value** | 0.005 g |
| **Literature range** | 0.001 g – 0.005 g – 0.02 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Liljeborgiid amphipod ~5-12mm body length; expected wet mass 1-20mg from body-volume scaling; congener L. kinahani confirmed 1-10mg expected in prior audit (verified_malacostraca_2); dataset value 590mg is ~30-590x above expected range; log10 diff ~1.5-2.8 vs expected; likely unit or transcription error; CORRECT_MASS to ~0.005g (5mg typical)*

**Primary reference (audit):** <https://www.marinespecies.org/aphia.php?p=taxdetails&id=102480>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Lophozozymus incisus*

| | |
|---|---|
| **Database value** | 0.319 g |
| **Corrected value** | 15 g |
| **Literature range** | 3 g – 12 g – 40 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Xanthid crab with carapace width ~3-6cm in adults; expected adult wet mass 5-40g from xanthid body-volume scaling; 0.319g is ~15-100x below expected range; log10 diff ~1.6 from typical 12g; compare to congener L. pictor (100g; plausible for larger xanthid at ~10cm CW); possible unit error or juvenile-only weight; Brose 2018 source; CORRECT_MASS recommended*

**Primary reference (audit):** <https://www.marinespecies.org/aphia.php?p=taxdetails&id=207185>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Marthasterias glacialis*

| | |
|---|---|
| **Database value** | 0.3675 g |
| **Corrected value** | 500 g |
| **Literature range** | 100 g – 700 g – 3,000 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Spiny starfish; one of the largest NE Atlantic sea stars; arm span up to 80 cm; typical adult wet mass 100-3000 g; dataset 0.3675 g is ~3.3 log10 units below typical adult; almost certainly a data error (possible AFDM or unit confusion); taxonomy correct*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Marthasterias_glacialis>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Meridiastra gunnii*

| | |
|---|---|
| **Database value** | 100 g |
| **Corrected value** | 5 g |
| **Literature range** | 1 g – 8 g – 20 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Small cushion star from southern Australia; maximum diameter ~6 cm; typical adult wet mass 1-20 g; dataset 100 g is ~1.1 log10 units above typical; inconsistent with known maximum body size; source MarineWise_2025 should be cross-checked; taxonomy correct*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Meridiastra_gunnii>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Metapenaeus pruinosus*

| | |
|---|---|
| **Database value** | 0.184 g |
| **Corrected value** | 10 g |
| **Literature range** | 3 g – 12 g – 30 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Penaeidae shrimp (Decapoda: Penaeidae); adult Metapenaeus spp. typically 5-30 g; 0.184 g is ~1.81 log10 units below typical 12 g; possible data entry error (g vs dry-weight or wrong units); web verification blocked by exhausted search budget; lit values based on Penaeidae family norms*

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Mitrella lunata*

| | |
|---|---|
| **Database value** | 0.001177 g |
| **Corrected value** | 0.1 g |
| **Literature range** | 0.03 g – 0.08 g – 0.2 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Accepted name Astyris lunata (Columbellidae; Neogastropoda); small dove shell; shell 7-12 mm; expected adult wet mass 30-200 mg based on shell size and congeners; dataset 1.177 mg is ~25-170x below expected range; abs_residual 1.84; likely AFDM or dry mass recorded as wet mass in Brose_etal_2018; lit range is size-derived estimate*

**Primary reference (audit):** <https://www.sealifebase.ca/summary/Astyris-lunata.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Astyris lunata*

| | |
|---|---|
| **Database value** | — |
| **Corrected value** | 0.1 g |
| **Tier** | Suspicious () |

*corrected name; same value*

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Morula uva*

| | |
|---|---|
| **Database value** | 0.01 g |
| **Corrected value** | 1 g |
| **Literature range** | 0.5 g – 2 g – 5 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Coral reef muricid (Muricidae; Neogastropoda); shell 15-30 mm; expected adult wet mass 0.5-5 g for this shell size; dataset 0.01 g (10 mg) is ~50-500x below expected range; highest abs_residual in batch (1.92); likely unit error or AFDM/DM recorded as wet mass; taxonomy correct; lit range is size-derived estimate*

**Primary reference (audit):** <https://www.sealifebase.ca/summary/Morula-uva.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Ocenebra erinaceus*

| | |
|---|---|
| **Database value** | 0.04447 g |
| **Corrected value** | 5 g |
| **Literature range** | 5 g – 12 g – 30 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Sting winkle / hedgehog murex (Muricidae; Neogastropoda); well-known edible NE Atlantic and Mediterranean species; shell 30-60 mm; adult total wet mass typically 5-30 g; dataset 0.04447 g (44.5 mg) is ~100-700x below expected range; abs_residual 1.28; note companion entry Ocenebra_erinacea has mass 0.1482 g (also suspicious); likely unit error in Brose_etal_2018; lit range is confirmed from published commercial fisheries data*

**Primary reference (audit):** <https://www.sealifebase.ca/summary/Ocenebra-erinaceus.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Ophiocomina nigra*

| | |
|---|---|
| **Database value** | 0.01 g |
| **Corrected value** | 15 g |
| **Literature range** | 0.5 g – 3 g – 20 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Well-known large northeastern Atlantic brittle star; disc diameter up to 25mm; arm radius up to 12cm; typical adult wet mass 0.5-20g; dataset 0.01g is ~2.48 log10 units below typical; possible unit error (mg entered as g) or data entry error; correct or flag for replacement*

**Primary reference (audit):** <https://www.marinespecies.org/>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Ophiothrix fragilis*

| | |
|---|---|
| **Database value** | 0.02 g |
| **Corrected value** | 5 g |
| **Literature range** | 0.3 g – 1 g – 3 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Adult disc ~10mm; arms ~50mm; Davoult 1992 is a population production study likely reporting AFDW or carbon mass per individual; expected adult wet mass 0.3-3g; 0.02g is ~1.7 log10 units below expected wet mass — replace with wet mass value*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Ophiothrix_fragilis>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Pelagia noctiluca*

| | |
|---|---|
| **Database value** | 1.401 g |
| **Corrected value** | 30 g |
| **Literature range** | 5 g – 30 g – 200 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Adult bell 3-12cm; even smallest adults expected ~5-200g wet; DeLong_etal_2018 metabolic database likely reports dry or AFDW; 1.401g is ~1.3 log10 units below expected minimum wet mass — replace with wet mass value*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Pelagia_noctiluca>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Phascolion strombi*

| | |
|---|---|
| **Database value** | 6.300e-07 g |
| **Corrected value** | 0.01 g |
| **Literature range** | 0.001 g – 0.05 g – 0.3 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Macroscopic sipunculan worm living in gastropod shells; body length 5-30 mm; minimum plausible adult mass ~1 mg (0.001 g); dataset value of 6.3e-7 g (630 nanograms) is sub-cellular and biologically impossible; probable unit conversion error (e.g. kg erroneously converted); taxonomy correct*

**Primary reference (audit):** <https://www.marinespecies.org/aphia.php?p=search&q=Phascolion+strombi>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Pirimela denticulata*

| | |
|---|---|
| **Database value** | 0.1018 g |
| **Corrected value** | 1 g |
| **Literature range** | 0.3 g – 1.5 g – 5 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Small shore crab (Decapoda: Pirimelidae); carapace width typically 15-25 mm; adult wet mass estimated 0.3-5 g (typical ~1.5 g); |log10(0.1018)-log10(1.5)| = 1.17 exceeds 1.0 threshold; 0.1018 g is plausible only for a very small juvenile; model abs_residual 1.74 is the highest in this batch; dataset value likely represents a juvenile or is a data entry error*

**Primary reference (audit):** <https://www.marinespecies.org/aphia.php?p=taxdetails&id=107388>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Polyeunoa laevis*

| | |
|---|---|
| **Database value** | 15 g |
| **Corrected value** | 0.05 g |
| **Literature range** | 0.01 g – 0.1 g – 0.5 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Taxonomy correct: Phyllodocida; Polynoidae; small Antarctic scale worm reported at ~2-3 cm body length; wet mass expected 0.01-0.5 g for polynoid of this size class; 15 g is ~2.2 log10 units above expected typical (0.1 g); likely a data entry or unit conversion error (e.g. 15 mg incorrectly entered as 15 g = factor 1000 error; or batch weight recorded as individual); abs_residual 1.26; recommend tracing to original Brose_etal_2018 source record and correcting*

**Primary reference (audit):** <https://www.marinespecies.org>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Rhopilema verrilli*

| | |
|---|---|
| **Database value** | 5.498 g |
| **Corrected value** | 5,000 g |
| **Literature range** | 500 g – 3,000 g – 10,000 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*All Rhopilema adults are large jellyfish (0.5-10 kg range); bell diameter 30-45+ cm; 5.498 g is ~2.7 log10 units below expected adult mass; likely juvenile specimen or unit/scaling error; taxonomy correct*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Rhopilema>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Trophon clathratus*

| | |
|---|---|
| **Database value** | 0.07009 g |
| **Corrected value** | 5 g |
| **Literature range** | 0.2 g – 0.7 g – 2 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Arctic/subarctic muricid (Muricidae; Neogastropoda); also treated as Boreotrophon clathratus in some classifications; shell typically 20-40 mm; 70 mg is ~10x below expected adult wet mass for a muricid of this shell size; likely represents AFDM or juvenile mass in Brose_etal_2018; lit range derived from comparable Arctic Muricidae of similar shell size; taxonomy correct at class level*

**Primary reference (audit):** <https://www.marinespecies.org/aphia.php?p=taxdetails&id=138826>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

### Source: Cai etal 2025

#### *Bokermannohyla alvarengai*

| | |
|---|---|
| **Database value** | 185.6 g |
| **Corrected value** | 15 g |
| **Literature range** | 5 g – 15 g – 35 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Bokermannohyla are medium-sized hylids typically 5-35 g; 185.6 g is ~5-10x too high and inconsistent with the genus. Residual +1.37 flags this strongly.*

**Primary reference (audit):** <https://amphibiaweb.org/species/573>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Catla catla*

| | |
|---|---|
| **Database value** | 116,900 g |
| **Corrected value** | 20,000 g |
| **Literature range** | 500 g – 5,000 g – 38,600 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*FishBase max 38.6 kg (38600g); some sources cite up to 50 kg; dataset 116900g (116.9 kg) far exceeds all published records; likely unit or data-entry error; source Cai_etal_2025*

**Primary reference (audit):** <https://www.fishbase.se/summary/Catla-catla.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Cebus yuracus*

| | |
|---|---|
| **Database value** | 33,500 g |
| **Corrected value** | 3,000 g |
| **Literature range** | 1,500 g – 2,500 g – 4,500 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Ecuadorian white-fronted capuchin (Cebidae; Primates); closely related to Cebus albifrons; all Cebus species are small to medium-sized monkeys; published adult mass for C. albifrons sensu lato consistently 1.5-3.5 kg across multiple sources (Napier 1967; Fragaszy et al. 2004; IUCN); 33.5 kg is ~10x above the maximum capuchin mass ever recorded; log10 diff = 1.13 vs typical 2500g; likely data entry error (e.g. a ~3.35 kg value mistakenly multiplied by 10; or mass in kg entered then scaled incorrectly); recommend correcting to ~2500g; taxonomy correct (Primates; Mammalia)*

**Primary reference (audit):** <https://www.iucnredlist.org/species/136339/17977239>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Culter alburnus*

| | |
|---|---|
| **Database value** | 8,977 g |
| **Corrected value** | 400 g |
| **Literature range** | 10 g – 200 g – 600 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Topmouth culter (Xenocyprididae); FishBase max published weight 600 g (Ref. 56557); dataset 8977 g is ~15x above documented maximum; abs log10 diff = 1.175 vs max; likely a data entry error (possible unit error or species misidentification); CORRECT_MASS recommended*

**Primary reference (audit):** <https://www.fishbase.se/summary/Culter-alburnus.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Epinephelus malabaricus*

| | |
|---|---|
| **Database value** | 246,200 g |
| **Corrected value** | 100,000 g |
| **Literature range** | 3,000 g – 8,000 g – 150,000 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Malabar grouper (Serranidae); FishBase max published weight ~150 kg (max TL 234 cm); dataset value 246.2 kg exceeds published maximum by ~64%; no confirmed record of this species reaching 246 kg; likely a max-size LWR extrapolation error or data entry error in Cai_etal_2025; residual +1.85 log10*

**Primary reference (audit):** <https://fishbase.se/summary/Epinephelus-malabaricus.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Garra gotyla*

| | |
|---|---|
| **Database value** | 779.2 g |
| **Corrected value** | 100 g |
| **Literature range** | 20 g – 80 g – 200 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Sucker fish (Cyprinidae); FishBase Wmax 779 g is a major outlier among all Garra species in FishBase (next largest: G. orientalis 111 g; all others <90 g); max TL ~21.5 cm implies expected mass ~50-200 g; FishBase Wmax record likely erroneous (possible misidentified specimen or LWR data entry error)*

**Primary reference (audit):** <https://www.fishbase.se/summary/Garra-gotyla>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Garra imberba*

| | |
|---|---|
| **Database value** | 522.4 g |
| **Corrected value** | 40 g |
| **Literature range** | 20 g – 80 g – 200 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*East African stream cyprinid (Cyprinidae) from Ethiopia; FishBase value retrieved via Cai et al. 2025; 522 g is an extreme outlier relative to all Garra Wmax records in FishBase (range 3-111 g for all other Garra spp. with data); expected mass 50-200 g for a ~20 cm stream cyprinid; FishBase value likely erroneous*

**Primary reference (audit):** <https://www.fishbase.se/summary/Garra-imberba>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Hypselobarbus thomassi*

| | |
|---|---|
| **Database value** | 30,000 g |
| **Corrected value** | 1,000 g |
| **Literature range** | 200 g – 1,500 g – 5,000 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Thomas's barb (Cyprinidae; Western Ghats / Sri Lanka region); Hypselobarbus species typically reach 40-60 cm and 300-3000 g; 30 kg (30000 g) is ~1.30 log10 units above the genus typical; possible causes: data entry error (e.g. value from a large Tor species misattributed); unit error; or a misidentified source specimen; single FishBase source; recommend tracing FishBase original citation and correcting mass to species-appropriate value (~1-3 kg)*

**Primary reference (audit):** <https://fishbase.se/summary/Hypselobarbus-thomassi.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Hypsopsetta guttulata*

| | |
|---|---|
| **Database value** | 24.65 g |
| **Corrected value** | 400 g |
| **Literature range** | 200 g – 800 g – 1,400 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Diamond turbot (Pleuronectidae; Pacific coast of North America); FishBase max TL 46 cm; max weight ~1400 g; typical adult 400-1200 g; dataset 24.65 g (Brose_etal_2018 food-web study) is ~1.51 log10 units below typical adult mass; almost certainly represents a juvenile or small size-class specimen selected for the food-web study rather than a representative adult; recommend replacing with species adult average (~800 g) or flagging as juvenile-record*

**Primary reference (audit):** <https://fishbase.se/summary/Hypsopsetta-guttulata.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Leporinus fasciatus*

| | |
|---|---|
| **Database value** | 3.95 g |
| **Corrected value** | 200 g |
| **Literature range** | 50 g – 200 g – 500 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Banded leporinus (Anostomidae); Amazon and Orinoco drainages; max TL ~30 cm; adults commonly 100-400 g; dataset 3.95 g from Makarieva_2008 (n=1) corresponds to a juvenile of ~5-6 cm TL; log10(3.95) vs log10(200) = 1.70 log10 units below typical adult mass — exceeds 1.0 threshold; Makarieva_2008 is a metabolic allometry study that often used small experimental specimens not representative of species adult mass; taxonomy correct; recommend replacing with FishBase adult mass (~150-300 g)*

**Primary reference (audit):** <https://fishbase.se/summary/Leporinus-fasciatus.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Lutjanus analis*

| | |
|---|---|
| **Database value** | 12.2 g |
| **Corrected value** | 3,000 g |
| **Literature range** | 300 g – 3,000 g – 15,600 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Mutton snapper (Perciformes: Lutjanidae); Caribbean; well-characterised large snapper; AnAge adult weight 8580 g; Mahe_2023 Martinique market sample mean 518.5 g (n=223; range 11.1-1678.5 g); FishBase Wmax ~15600 g; dataset 12.2 g is below the minimum market-sample weight (11.1 g) and corresponds to a juvenile of ~7 cm; source Viana_2016 has demonstrated systematic mass errors for Lutjanus (also records L. alexandrei at 69.2 g); abs_residual -1.97 is most extreme in batch; log10(12.2) - log10(518.5) = -1.63 >> 1 log unit; ERRONEOUS_MASS confirmed; replace with adult reference value from AnAge (8580 g) or FishBase Wmax (~15600 g)*

**Primary reference (audit):** <https://fishbase.se/summary/Lutjanus-analis.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Macrodon ancylodon*

| | |
|---|---|
| **Database value** | 39.7 g |
| **Corrected value** | 800 g |
| **Literature range** | 200 g – 700 g – 2,500 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*King weakfish / pescada-foguete (Sciaenidae); W. Atlantic (Caribbean to Argentina); max TL ~65-70 cm; typical adult body mass 500-2000 g; dataset 39.7 g is far below typical adult (|log10(39.7)-log10(700)| = 1.25 exceeds 1.0 threshold); Viana_2016 likely reports mean mass of specimens in a Brazilian food web study (possibly size-selective juvenile sample); ERRONEOUS_MASS as representative of typical adult; recommend replacement with FishBase species-representative adult mass (~500-1000 g)*

**Primary reference (audit):** <https://fishbase.se/summary/Macrodon-ancylodon.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Moenkhausia ceros*

| | |
|---|---|
| **Database value** | 0.13 g |
| **Corrected value** | 3 g |
| **Literature range** | 0.33 g – 1.5 g – 1.6 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Small tetra (Characidae; Characiformes); S. America; max TL 5.0 cm; FishBase LW: a=0.01072; b=3.11; at 5 cm (max) W ~1.60 g; at 4 cm (typical adult) W ~0.80 g; at 3 cm W ~0.33 g; dataset 0.13 g corresponds to ~2.2 cm juvenile; |log10(0.13/1.50)|=1.06 exceeds 1.0 threshold vs typical adult; source listed as fishbase but no direct weight value appears on FishBase page; value likely derived from a juvenile/small-cohort size measurement; recommend correction to adult-representative mass ~0.8-1.5 g*

**Primary reference (audit):** <https://fishbase.se/summary/Moenkhausia-ceros.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Prionobrama filigera*

| | |
|---|---|
| **Database value** | 311.5 g |
| **Corrected value** | 1 g |
| **Literature range** | 0.5 g – 2 g – 5 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Glass bloodfin tetra (Characiformes: Characidae); small Amazonian characin; FishBase max TL 5.7 cm SL; at max size typical adult mass 0.5-3 g; 311.5 g is ~100-600x the expected adult mass for this tiny tetra; |log10(311.5/2)| = 2.19 >> 1.0 log unit; source Bojsen_2005 -- this likely represents a wrong-species match in Bojsen's community dataset (Peruvian floodplain study; Prionobrama co-occurred with much larger characins) or a unit/transcription error; abs_residual +1.95 (highest in batch); ERRONEOUS_MASS confirmed; correct to FishBase adult representative mass ~1-3 g*

**Primary reference (audit):** <https://fishbase.se/summary/Prionobrama-filigera.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Psilorhynchus homaloptera*

| | |
|---|---|
| **Database value** | 118.6 g |
| **Corrected value** | 5 g |
| **Literature range** | 1 g – 5 g – 12 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Torrent minnow (Psilorhynchidae; Cypriniformes); FishBase max length 9.4 cm SL; no published weight; dataset 118.6 g grossly exceeds expected adult mass (~1-12 g for fish of this size); |log10(118.6/5)| = 1.37 >> 1.0 log unit; a 118 g psilorhynchid would require ~30-40 cm body length; likely species confusion or transcription error in source Cai_etal_2025; ERRONEOUS_MASS confirmed; recommend correcting to ~2-10 g*

**Primary reference (audit):** <https://fishbase.se/summary/Psilorhynchus-homaloptera.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Tor barakae*

| | |
|---|---|
| **Database value** | 24.1 g |
| **Corrected value** | 500 g |
| **Literature range** | 100 g – 500 g – 2,000 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*24.1g is juvenile mass; Tor barakae is a mahseer from the Barito River drainage of Borneo (Kalimantan); even small Tor spp. adults exceed 100g at typical adult size; single source Cai_etal_2025; |log10(24.1)-log10(500)|=1.32; taxonomy correct*

**Primary reference (audit):** <https://www.fishbase.se/summary/Tor-barakae.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Tilapia sparrmanii*

| | |
|---|---|
| **Database value** | 7.19 g |
| **Corrected value** | 100 g |
| **Literature range** | 30 g – 120 g – 300 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*7.19g is juvenile mass; adult banded tilapia (southern Africa; Cichlidae) typically 50-300g; max TL ~22 cm corresponds to ~200-300g; DeLong_etal_2018 likely recorded experimental juvenile or sub-adult; |log10(7.19)-log10(120)|=1.22; taxonomy correct (Actinopteri; Perciformes; Cichlidae)*

**Primary reference (audit):** <https://www.fishbase.se/summary/Tilapia-sparrmanii.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Tritogonia verrucosa*

| | |
|---|---|
| **Database value** | 1,120 g |
| **Corrected value** | 100 g |
| **Literature range** | 10 g – 50 g – 150 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Warty-back mussel (Unionidae); North American freshwater mussel; shell 60-110mm; Quaardvark; 1120g (1.12 kg) is 7-100x above the plausible range for this species (typical wet mass with shell ~20-150g for large adult); largest Unionidae rarely exceed 200-300g even at maximum sizes; likely Quaardvark data entry error (e.g. unit confusion or extra zero); positive residual (+1.67) corroborates mass is greatly overclaimed; class correctly Bivalvia*

**Primary reference (audit):** <https://animaldiversity.org/accounts/Tritogonia_verrucosa/>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

### Source: Castro 2025

#### *Elops lacerta*

| | |
|---|---|
| **Database value** | 70.12 g |
| **Corrected value** | 4,000 g |
| **Literature range** | 2,000 g – 5,000 g – 10,000 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*West African tenpounder (Elopidae); large elongated pelagic fish; max TL ~100 cm; adults commonly 2-10 kg (comparable to E. saurus); 70.12g corresponds to a juvenile of ~15 cm; source Dienye_2021 (single source; Nigerian Delta fisheries study likely sampling juveniles or immatures); residual -1.945 (most extreme in batch); dataset mass is 30-70x below typical adult mass; do not use as adult body mass reference*

**Primary reference (audit):** <https://fishbase.se/summary/Elops-lacerta.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

### Source: DeLong etal 2018

#### *Aedes aegypti*

| | |
|---|---|
| **Database value** | 8.750e-05 g |
| **Corrected value** | 0.002 g |
| **Literature range** | 0.001 g – 0.002 g – 0.003 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Adult female wet mass well-documented as 1.5-2.5mg; dataset value 0.0875mg is ~25x lower than typical adult female (|log10 diff| = 1.36 vs 2mg typical); possible causes: unit error (value may have been recorded in different units); represents male (~0.5-1mg but still too low); or lab-reared unfed neonate; DeLong 2018 source; recommend correcting to ~0.002g or verifying original measurement unit in primary source*

**Primary reference (audit):** <https://animaldiversity.org/accounts/Aedes_aegypti/>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Enithares sobria*

| | |
|---|---|
| **Database value** | 1.200e-04 g |
| **Corrected value** | 0.005 g |
| **Literature range** | 0.005 g – 0.02 g – 0.1 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Hemiptera: Notonectidae backswimmer; body length 8-16mm; dataset 0.12mg is ~100-166x below literature minimum (~5mg) for adult Notonectidae; |log10(0.00012)-log10(0.02)| = 2.22 log10 units; likely unit error or specimen miscoded; DeLong 2018 source; typical adult mass 10-100mg; ERRONEOUS_MASS confirmed*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Notonectidae>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Lygus hesperus*

| | |
|---|---|
| **Database value** | 2.050e-04 g |
| **Corrected value** | 0.006 g |
| **Literature range** | 0.004 g – 0.008 g – 0.02 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Taxonomy correct: Hemiptera; Miridae; Lygus hesperus (western tarnished plant bug) confirmed; adult body length 5-6 mm; published adult wet mass ~4-20 mg; dataset 0.205 mg is ~1.6 log10 units below typical 8 mg; probable unit error in DeLong et al 2018 source or value recorded for early-instar nymph; mass ~30-50x too small*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Lygus_hesperus>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Mamestra brassicae*

| | |
|---|---|
| **Database value** | 0.00391 g |
| **Corrected value** | 0.3 g |
| **Literature range** | 0.1 g – 0.25 g – 0.5 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Taxonomy correct: Lepidoptera; Noctuidae; Mamestra brassicae (cabbage moth) confirmed; adult wingspan 35-45 mm; typical adult wet mass 100-500 mg; dataset 3.91 mg is ~1.8 log10 units below typical 250 mg; probable unit error or DeLong et al 2018 value recorded for early-instar larva rather than adult; mass ~50-100x too small for adult*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Mamestra_brassicae>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Melittobia chalybii*

| | |
|---|---|
| **Database value** | 7.222e-04 g |
| **Corrected value** | 5.000e-04 g |
| **Literature range** | 3.000e-05 g – 5.000e-05 g – 3.000e-04 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Taxonomy correct: Hymenoptera; Eulophidae; Melittobia chalybii confirmed gregarious ectoparasitoid wasp; adult body length ~0.9-1.3 mm (one of smallest Hymenoptera); estimated adult wet mass ~0.03-0.3 mg; dataset 0.72 mg is ~1.2-1.4 log10 units above estimated maximum; possible colony aggregate mass recorded or data error in Brose et al 2018*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Melittobia>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Orius sauteri*

| | |
|---|---|
| **Database value** | 0.02768 g |
| **Corrected value** | 0.002 g |
| **Literature range** | 3.000e-04 g – 0.001 g – 0.003 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Taxonomy correct: Hemiptera; Anthocoridae; Orius sauteri confirmed minute pirate bug (predator of thrips/mites); adult body length 1.5-2.5 mm; published adult wet mass for Orius spp. 0.3-3 mg; dataset 27.68 mg is ~1.97 log10 units above typical 1 mg; probable unit error (value recorded as mg but entered as g; actual value should be ~0.028 mg or 28 ug -- also extremely small) or data transcription error; DeLong et al 2018 source; mass ~10-100x too high*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Orius_sauteri>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Pectinophora gossypiella*

| | |
|---|---|
| **Database value** | 0.296 g |
| **Corrected value** | 0.01 g |
| **Literature range** | 0.003 g – 0.007 g – 0.015 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Lepidoptera: Gelechiidae (pink bollworm); one of the most-studied cotton pest moths worldwide; adult body length 8–12mm; wingspan 14–20mm; published adult mass typically 3–12mg (wet); dataset 296mg is ~1.6 log10 units above expected adult mass — approximately 25–100× too high; likely a gram/milligram unit confusion or decimal-point shift in source DeLong_etal_2018; class Insecta correct; abs_residual 1.495*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Pectinophora_gossypiella>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Rhyzopertha dominica*

| | |
|---|---|
| **Database value** | 4.183e-05 g |
| **Corrected value** | 0.001 g |
| **Literature range** | 0.001 g – 0.002 g – 0.003 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Lesser grain borer (Coleoptera: Bostrichidae; 2-3mm body); well-documented stored-product pest; adult body mass typically 1-3mg; dataset value 0.042mg is ~1.5 log10 units below expected minimum; likely a metabolic-rate measurement or per-egg mass value used in error rather than whole adult body mass; taxonomy Insecta:Coleoptera:Bostrichidae is correct*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Rhyzopertha_dominica>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

### Source: Feldman etal 2016

#### *Afrotyphlops fornasinii*

| | |
|---|---|
| **Database value** | 2.1 g |
| **Corrected value** | 100 g |
| **Literature range** | 15 g – 35 g – 80 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Fornasini's blind snake (Typhlopidae); species reaches ~65-70cm SVL; cylinder-volume estimate for a 65cm typhlopid (~4mm radius) gives ~8-20g; 2.1g implausibly low for adult of this size; expected adult range 15-80g; likely juvenile specimen or data entry error in Feldman 2016 source; abs_residual 1.657*

**Primary reference (audit):** <https://reptile-database.reptarium.cz/species?genus=Afrotyphlops&species=fornasinii>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Afrotyphlops mucruso*

| | |
|---|---|
| **Database value** | 965.5 g |
| **Corrected value** | 100 g |
| **Literature range** | 40 g – 150 g – 350 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Mozambique large-scaled blind snake (Typhlopidae); reaches ~70-100cm; even at maximum size a slender typhlopid cannot approach 1kg; cylinder-volume estimate for a 90cm typhlopid (~5mm radius) gives ~60-80g; 965.5g would require body diameter far exceeding any known typhlopid; likely species confusion or units error in Feldman 2016; abs_residual 1.006*

**Primary reference (audit):** <https://reptile-database.reptarium.cz/species?genus=Afrotyphlops&species=mucruso>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Anilios nigrescens*

| | |
|---|---|
| **Database value** | 403.3 g |
| **Corrected value** | 5 g |
| **Literature range** | 2 g – 10 g – 30 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Eastern blind snake (Typhlopidae); taxonomy class Squamata correct; adults 30-65cm but extremely slender (~3-5mm diameter); cylinder-volume estimate for 55cm at 4mm radius gives ~10-14g; 403.3g is implausible for any Typhlopidae of this size; exactly the same value as Anilios_proximus strongly suggests value was duplicated from another record or units error; |log10(403.3)-log10(10)| = 1.606 >> 1.0 → ERRONEOUS_MASS; expected adult range 2-30g; abs_residual 1.421*

**Primary reference (audit):** <https://reptile-database.reptarium.cz/species?genus=Anilios&species=nigrescens>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Anilios proximus*

| | |
|---|---|
| **Database value** | 403.3 g |
| **Corrected value** | 8 g |
| **Literature range** | 5 g – 25 g – 80 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Proximate blind snake (Typhlopidae); taxonomy class Squamata correct; one of the larger Australian Anilios reaching ~60-75cm but still extremely slender; maximum plausible mass ~60-80g even for a gravid female; 403.3g is identical to Anilios_nigrescens value strongly suggesting a duplication error in Feldman 2016; |log10(403.3)-log10(25)| = 1.208 > 1.0 → ERRONEOUS_MASS; abs_residual 1.421*

**Primary reference (audit):** <https://reptile-database.reptarium.cz/species?genus=Anilios&species=proximus>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Anilios unguirostris*

| | |
|---|---|
| **Database value** | 312.6 g |
| **Corrected value** | 5 g |
| **Literature range** | 1 g – 5 g – 20 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Hook-snouted blind snake (Typhlopidae); taxonomy class Squamata correct; medium-sized species ~25-45cm; extremely slender body plan; even at maximum size a typhlopid of this length cannot approach 312g; cylinder estimate for 40cm at 4mm radius gives ~6-10g; |log10(312.6)-log10(5)| = 1.796 >> 1.0 → ERRONEOUS_MASS; expected adult range 1-20g; abs_residual 1.310*

**Primary reference (audit):** <https://reptile-database.reptarium.cz/species?genus=Anilios&species=unguirostris>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Anilios waitii*

| | |
|---|---|
| **Database value** | 176.9 g |
| **Corrected value** | 10 g |
| **Literature range** | 3 g – 15 g – 50 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Waite's blind snake (Typhlopidae); taxonomy class Squamata correct; medium-large Australian species reaching ~40-65cm; slender body plan typical of Typhlopidae; maximum plausible mass ~40-60g for a large gravid female; 176.9g exceeds plausible range; |log10(176.9)-log10(15)| = 1.072 > 1.0 → ERRONEOUS_MASS; abs_residual 1.063*

**Primary reference (audit):** <https://reptile-database.reptarium.cz/species?genus=Anilios&species=waitii>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Brachyorrhos albus*

| | |
|---|---|
| **Database value** | 1.6 g |
| **Corrected value** | 30 g |
| **Literature range** | 50 g – 133 g – 227 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Taxonomy correct (Homalopsidae; Squamata); small homalopsid reed snake from Ambon Island Indonesia; all three congeners in dataset weigh far more: B. gastrotaenius 49.8 g; B. raffrayi 132.7 g; B. wallacei 226.6 g; |log10(1.6) - log10(49.8)| = 1.49 log10 units below smallest congeneric - clearly exceeds ERRONEOUS_MASS threshold; residuals model matched taxon to B. wallacei at 97% confidence suggesting possible species confusion or juvenile specimen mislabeled as adult; single Feldman et al. 2016 source; likely data entry error or juvenile record*

**Primary reference (audit):** <https://reptile-database.reptarium.cz/species?genus=Brachyorrhos&species=albus>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Cerastes boehmei*

| | |
|---|---|
| **Database value** | 6.2 g |
| **Corrected value** | 150 g |
| **Literature range** | 100 g – 150 g – 200 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Bohme's horned viper; small to medium desert viper; adult length 40-60cm; adult mass typically 100-200g; 6.2g is 16-32x below the typical range (log10 diff 1.22-1.51); 6.2g is consistent with a hatchling or very small juvenile; likely a data entry error or neonate mass recorded as adult; recommend correction to ~100-150g for typical adult*

**Primary reference (audit):** <https://animalinformation.com/animal/bohmes-horned-viper/>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Dasypeltis abyssina*

| | |
|---|---|
| **Database value** | 5.7 g |
| **Corrected value** | 72 g |
| **Literature range** | 40 g – 72 g – 120 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Ethiopian egg-eater; adults 80-120cm TL; congener D. scabra (similar length) has confirmed adult mass ~72g; 5.7g is implausibly small for an 80-120cm adult snake; likely juvenile mass or data error; |log10(5.7) - log10(72)| = 1.10 log10 units exceeds threshold; lit values based on D. scabra as proxy (no species-specific D. abyssina mass data found); single Feldman 2016 source*

**Primary reference (audit):** <https://www.worldspecies.org/ntaxa/2752640/L>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Eirenis persicus*

| | |
|---|---|
| **Database value** | 142.5 g |
| **Corrected value** | 5 g |
| **Literature range** | 4 g – 8 g – 20 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Persian dwarf racer; adults only 27-35cm (max 37.1cm); 142.5g is implausibly heavy for a 37cm slender colubrid; estimated typical mass ~5-20g based on body size (model also predicts ~13g); |log10(142.5) - log10(8)| = 1.25 log10 units exceeds threshold; no species-specific mass data in literature; lit range estimated from body length only; possible data entry error (unit confusion or wrong species); single Feldman 2016 source*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Eirenis_persicus>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Gonionotophis egbensis*

| | |
|---|---|
| **Database value** | 2.5 g |
| **Corrected value** | 80 g |
| **Literature range** | 10 g – 50 g – 200 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Dunger's file snake; African lamprophiid endemic to Nigeria; 2.5g far below all other Gonionotophis in dataset (next smallest G. gabouensis 9.1g; G. grantii 25.1g; typical range 15-730g); even small adult lamprophiids exceed 10g; likely data entry or unit conversion error; single Feldman 2016 source; NOTE: genus may be synonymized as Mehelya in some databases - verify whether Gonionotophis or Mehelya in original Feldman 2016 source*

**Primary reference (audit):** <https://www.inaturalist.org/taxa/29385-Gonionotophis-egbensis>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Hierophis cypriensis*

| | |
|---|---|
| **Database value** | 4,068 g |
| **Corrected value** | 80 g |
| **Literature range** | 50 g – 200 g – 400 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Cyprus whip snake; slender Colubridae endemic to Cyprus; adults 70-90cm (max 116.5cm TL); all other Hierophis in dataset: H. andreanus 106.6g; H. gemonensis 219.4g; H. viridiflavus 386.6g; congeners reach 100-200cm and weigh 100-400g; 4068g is 10-80x above entire congener mass range for a shorter and more slender species; clearly erroneous - likely decimal or unit error (4068 mg = 4.07g plausible; or factor of 10 shift); single Feldman 2016 source*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Cyprus_whip_snake>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Homalopsis nigroventralis*

| | |
|---|---|
| **Database value** | 2,252 g |
| **Corrected value** | 200 g |
| **Literature range** | 100 g – 300 g – 700 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Deuve's water snake (black-bellied puff-faced water snake); described by Murphy et al. 2011 as species distinct from H. buccata and generally smaller-bodied; Mekong drainage endemic; dataset value 2252g is IDENTICAL to H. buccata value - strongly indicates data duplication error; H. nigroventralis is smaller than H. buccata; expected 100-700g based on relative body size; single Feldman 2016 source*

**Primary reference (audit):** <https://www.inaturalist.org/taxa/29912-Homalopsis-nigroventralis>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Lampropeltis webbi*

| | |
|---|---|
| **Database value** | 10.1 g |
| **Corrected value** | 200 g |
| **Literature range** | 150 g – 400 g – 900 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Webb's kingsnake (Colubridae) from Baja California Mexico; only 5 known specimens; largest specimen 75cm TL; adult Lampropeltis congeners typically 150-900g (L. californiae; L. getula); 10.1g matches neonate/hatchling mass (~10-15g) not adult; single Feldman_etal_2016 source; abs_residual 1.375*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Lampropeltis_webbi>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Liopholidophis oligolepis*

| | |
|---|---|
| **Database value** | 2.5 g |
| **Corrected value** | 30 g |
| **Literature range** | 10 g – 30 g – 80 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Small Malagasy snake (Pseudoxyrhophiidae) from Madagascar; genus reaches up to ~60 cm SVL; even the smallest adults of this genus typically weigh 10-80 g; 2.5 g is ~1.08 log10 units below typical 30 g and consistent with a neonate or juvenile rather than an adult; abs_residual 1.636; taxonomy correctly Squamata (Pseudoxyrhophiidae)*

**Primary reference (audit):** <https://reptile-database.reptarium.cz/species?genus=Liopholidophis&species=oligolepis>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Lycodon kundui*

| | |
|---|---|
| **Database value** | 2.7 g |
| **Corrected value** | 50 g |
| **Literature range** | 15 g – 40 g – 120 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Wolf snake (Colubridae) from Southeast Asia; Lycodon adults of even small species typically weigh 20-120 g; 2.7 g is ~1.17 log10 units below expected typical ~40 g; consistent with a small juvenile or neonate rather than an adult; abs_residual 1.305; taxonomy correctly Squamata (Colubridae)*

**Primary reference (audit):** <https://reptile-database.reptarium.cz/species?genus=Lycodon&species=kundui>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Lycodon meridionale*

| | |
|---|---|
| **Database value** | 638.8 g |
| **Corrected value** | 150 g |
| **Literature range** | 50 g – 150 g – 300 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Wolf snake (Colubridae) from South Asia; adults typically 80-100 cm SVL; most Lycodon adults weigh 50-300 g; 638.8 g is ~0.63 log10 units above expected typical ~150 g and well outside the expected range for this genus; abs_residual 1.069; possible data entry error or misidentified specimen; taxonomy correctly Squamata (Colubridae)*

**Primary reference (audit):** <https://reptile-database.reptarium.cz/species?genus=Lycodon&species=meridionale>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Madatyphlops decorsei*

| | |
|---|---|
| **Database value** | 176.9 g |
| **Corrected value** | 15 g |
| **Literature range** | 5 g – 20 g – 60 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Malagasy blindsnake (Typhlopidae); typhlopids are thin worm-like burrowing snakes; even large typhlopid species rarely exceed 50-100 g; 176.9 g is ~0.95 log10 units above a generous maximum ~60 g for any blindsnake; abs_residual 1.528; almost certainly a data entry error; taxonomy correctly Squamata (Typhlopidae)*

**Primary reference (audit):** <https://reptile-database.reptarium.cz/species?genus=Madatyphlops&species=decorsei>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Madatyphlops madagascariensis*

| | |
|---|---|
| **Database value** | 66.3 g |
| **Corrected value** | 15 g |
| **Literature range** | 3 g – 15 g – 45 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Malagasy blindsnake (Typhlopidae); thin worm-like burrowing snake; typical adult mass for Madatyphlops 5-30 g; 66.3 g is ~0.64 log10 units above expected typical ~15 g and exceeds plausible maximum for this worm-like taxon; abs_residual 1.102; possible data entry error; taxonomy correctly Squamata (Typhlopidae)*

**Primary reference (audit):** <https://reptile-database.reptarium.cz/species?genus=Madatyphlops&species=madagascariensis>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Malayotyphlops koekkoeki*

| | |
|---|---|
| **Database value** | 58.7 g |
| **Corrected value** | 10 g |
| **Literature range** | 2 g – 10 g – 30 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Malaysian blindsnake (Typhlopidae); thin worm-like burrowing snake from Malaysia/Indonesia; typical adult typhlopid mass 2-30 g; 58.7 g is ~0.77 log10 units above expected typical ~10 g and exceeds the plausible range for this slender taxon; abs_residual 1.141; likely data entry error; taxonomy correctly Squamata (Typhlopidae)*

**Primary reference (audit):** <https://reptile-database.reptarium.cz/species?genus=Malayotyphlops&species=koekkoeki>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Mastigodryas heathii*

| | |
|---|---|
| **Database value** | 7.6 g |
| **Corrected value** | 200 g |
| **Literature range** | 50 g – 150 g – 500 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*South American racer (Colubridae); Mastigodryas adults typically 80-150 cm SVL; adult mass typically 80-500 g; 7.6 g is ~1.30 log10 units below expected typical ~150 g and consistent with a hatchling or small juvenile rather than an adult; abs_residual 1.563; taxonomy correctly Squamata (Colubridae)*

**Primary reference (audit):** <https://reptile-database.reptarium.cz/species?genus=Mastigodryas&species=heathii>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Oxyrhopus petolarius*

| | |
|---|---|
| **Database value** | 1,246 g |
| **Corrected value** | 120 g |
| **Literature range** | 50 g – 200 g – 400 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*False coral snake (Colubridae; Central and South America); other Oxyrhopus in dataset range 24.9-354.5 g; O. petolarius is not documented as substantially larger than O. guibei (354.5 g; residual OK); 1246 g is ~3.5x the heaviest accepted congener; expected adult mass 50-400 g; likely data entry error or wrong-species association; single Feldman 2016 source*

**Primary reference (audit):** <https://reptile-database.reptarium.cz/species?genus=Oxyrhopus&species=petolarius>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Paraphimophis rusticus*

| | |
|---|---|
| **Database value** | 1,407 g |
| **Corrected value** | 50 g |
| **Literature range** | 20 g – 100 g – 300 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*South American dipsadid colubrid (Colubridae sensu lato; monotypic slender-bodied genus; formerly placed in Liophis/related genera); 1407 g appropriate for a large heavy-bodied snake (boa or python) not a slender colubrid; model predicts 48.5 g; expected adult mass 20-300 g; abs_residual 1.46 highest in batch; likely wrong-species entry or unit conversion error; single Feldman 2016 source; taxonomy correctly Squamata*

**Primary reference (audit):** <https://reptile-database.reptarium.cz/species?genus=Paraphimophis&species=rusticus>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Phalotris mertensi*

| | |
|---|---|
| **Database value** | 528.2 g |
| **Corrected value** | 15 g |
| **Literature range** | 8 g – 13 g – 30 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Small dipsadid false coral snake from central-eastern Brazil and Paraguay; documented adult specimen 350mm SVL + 30mm tail weighed 12.73g; species adults reach 350-500mm TL; 528.2g is ~1.6 log10 units above lit typical 13g and physically impossible for this body size; single Feldman_etal_2016 source; likely unit conversion error (e.g. mg entered as g) or data entry error*

**Primary reference (audit):** <https://www.thebhs.org/publications/the-herpetological-bulletin/issue-number-128-summer-2014/312-08-i-phalotris-mertensi-i-false-coral-snake-predation/file>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Thamnophis eques*

| | |
|---|---|
| **Database value** | 2,801 g |
| **Corrected value** | 200 g |
| **Literature range** | 100 g – 300 g – 600 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Mexican garter snake (Colubridae); adult females reach up to 1.1-1.2m TL; typical adult mass 100-400g; even the largest specimens would not approach 2801g (2.8 kg); for comparison T. gigas (giant garter snake; largest North American Thamnophis reaching 1.65m) is 1484g in this dataset; 2801g is 5-10x typical adult mass; |log10(2801)-log10(300)|=0.97 borderline but mass is biologically implausible given species size; single Feldman_etal_2016 source; suspect SVL-to-mass conversion error or taxon mismatch; abs_residual 1.332*

**Primary reference (audit):** <https://animaldiversity.org/accounts/Thamnophis_eques/>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Thamnophis saurita*

| | |
|---|---|
| **Database value** | 1,497 g |
| **Corrected value** | 50 g |
| **Literature range** | 20 g – 50 g – 100 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Eastern ribbon snake (Colubridae); one of the SMALLEST and most slender Thamnophis; adults 45-65cm TL with very slender body; ADW and field data document typical adult mass 20-80g with maximum ~100g; 1497g (1.5 kg) is 15-75x typical adult mass; |log10(1497)-log10(50)|=1.48 >> 1.0 log unit; source is Pinos_estimated (not a direct measurement); this estimate is clearly erroneous; likely confused with a much larger species or a gross estimation error; abs_residual 1.060*

**Primary reference (audit):** <https://animaldiversity.org/accounts/Thamnophis_saurita/>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Typhlops jamaicensis*

| | |
|---|---|
| **Database value** | 58.7 g |
| **Corrected value** | 5 g |
| **Literature range** | 0.5 g – 3 g – 10 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Jamaican blindsnake (Typhlopidae); small fossorial species; adults typically 15-30 cm TL; entire Typhlopidae family rarely exceeds 10-20 g even for larger species; 58.7 g is ~1.29 log10 units above lit_typical of 3 g; no blindsnake of this size has been recorded at 58.7 g; likely data entry error (possible 10x magnitude error or species misidentification); taxonomy Squamata:Typhlopidae correct; lit ranges from training knowledge (web search budget exhausted)*

**Primary reference (audit):** <https://reptile-database.reptarium.cz/species?genus=Typhlops&species=jamaicensis>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Vipera shemakhensis*

| | |
|---|---|
| **Database value** | 3.2 g |
| **Corrected value** | 50 g |
| **Literature range** | 20 g – 50 g – 100 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Shemakha viper from Azerbaijan/South Caucasus; correctly Squamata/Viperidae; adults typically 40-55 cm TL; smallest adult Vipera weigh ~20-50g; 3.2g is juvenile-only level and implausible for an adult; |log10(3.2)-log10(50)|=1.194 exceeds 1.0 log unit; dataset matched to Vipera eriwanensis (98% confidence) suggesting possible name synonymy - both spp. valid Squamata so no class error; single Feldman_etal_2016 source; expected adult mass ~30-80g; lit ranges from training knowledge (web search budget exhausted)*

**Primary reference (audit):** <https://reptile-database.reptarium.cz/species?genus=Vipera&species=shemakhensis>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

### Source: fishbase

#### *Bathytoshia centroura*

| | |
|---|---|
| **Database value** | 148.9 g |
| **Corrected value** | 50,000 g |
| **Literature range** | 5,000 g – 60,000 g – 180,000 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Taxonomy correct: Myliobatiformes; Dasyatidae; roughtail stingray (formerly Dasyatis centroura); FishBase max disc width ~200 cm; max weight ~180 kg; typical adults 20-100 kg; dataset 148.9 g is approximately 1000-fold too low for any adult specimen; even neonate stingrays at birth exceed this mass; |log10(148.9)-log10(60000)| = 2.60 log units; ERRONEOUS_MASS; almost certainly a unit error (148.9 kg = 148900 g would fall within expected adult range); dataset source fishbase with ref 1*

**Primary reference (audit):** <https://www.fishbase.se/summary/Bathytoshia-centroura.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Cirrhilabrus exquisitus*

| | |
|---|---|
| **Database value** | 2,000 g |
| **Corrected value** | 20 g |
| **Literature range** | 5 g – 15 g – 25 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Exquisite fairy wrasse max ~12 cm TL (Labridae); LWR-estimated adult mass ~15-25g; 2000g (2 kg) is physically impossible for this small reef fish; |log10(2000)-log10(15)|=2.12 log units; likely 10-fold data entry error (perhaps 20g entered as 2000g or wrong species)*

**Primary reference (audit):** <https://www.fishbase.se/summary/Cirrhilabrus-exquisitus>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Cobitis granoei*

| | |
|---|---|
| **Database value** | 124.6 g |
| **Corrected value** | 5 g |
| **Literature range** | 2 g – 7 g – 15 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Spined loach (Cobitidae); typical Cobitis max weight 5-15g (e.g. Cobitis taenia max 7g on FishBase); 124.6g is ~1.25 log units above expected maximum; mass likely belongs to a larger fish or is a data error; note: residuals match to Cobitis sibirica at 98% confidence - species-level name may need updating but class Actinopteri is correct*

**Primary reference (audit):** <https://www.fishbase.se/summary/Cobitis-granoei>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Coptodon zillii*

| | |
|---|---|
| **Database value** | 1.539 g |
| **Corrected value** | 100 g |
| **Literature range** | 50 g – 150 g – 300 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Redbelly tilapia (Cichlidae); max weight 300 g; typical adult 50-200 g (12-22 cm); FishBase LWR (a=0.01514; b=2.99) yields 1.539 g at ~4.7 cm TL; 1.51 log10 units below minimum typical adult mass; likely a very small juvenile not representative of species adult body mass*

**Primary reference (audit):** <https://fishbase.se/summary/Tilapia-zillii.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Dactyloptena tiltoni*

| | |
|---|---|
| **Database value** | 4.3 g |
| **Corrected value** | 40 g |
| **Literature range** | 50 g – 180 g – 350 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Plain helmet gurnard (Dactylopteridae); FishBase lists no published weight and max 9.5 cm SL; 2024 Thalassas paper (DOI 10.1007/s41208-024-00672-8) reports first Arabian Sea record at 295 mm SL which is far larger; all other Dactyloptena in dataset range 92-951g; even scaling to smallest congener (D. gilberti 92.2g) implies >20g at any adult size; 4.3g is >=1.37 log units below any plausible adult estimate; likely magnitude error in Cai_etal_2025; single-source record*

**Primary reference (audit):** <https://www.fishbase.se/summary/Dactyloptena-tiltoni.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Eleotris amblyopsis*

| | |
|---|---|
| **Database value** | 6.102 g |
| **Corrected value** | 150 g |
| **Literature range** | 50 g – 200 g – 550 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Caribbean sleeper (Eleotridae); max TL 32 cm; FishBase Bayesian LWR estimates max weight ~550g; typical adult 50-300g; 6.102g (log10=0.785) is 1.03 log10 below model expectation and far below minimum typical adult mass; source fishbase+Froese_2014 likely captured a small juvenile; value not representative of adult body mass*

**Primary reference (audit):** <https://fishbase.se/summary/Eleotris-amblyopsis.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Genyatremus cavifrons*

| | |
|---|---|
| **Database value** | 10 g |
| **Corrected value** | 1,000 g |
| **Literature range** | 100 g – 400 g – 700 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*South American grunt (Haemulidae); FishBase Wmax of 10 g is biologically implausible for a Haemulidae; haemulids typically reach 20-50 cm and 200-700 g as adults; model prediction ~383 g is consistent with family norms; FishBase Wmax of 10 g likely a data error*

**Primary reference (audit):** <https://www.fishbase.se/summary/Genyatremus-cavifrons>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Hypopomus*

| | |
|---|---|
| **Database value** | 588 g |
| **Corrected value** | 30 g |
| **Literature range** | 10 g – 40 g – 100 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Bluntnose knifefish (Hypopomidae; Gymnotiformes; South America); genus-only entry (no species epithet); type species H. brevirostris max TL ~28 cm; all Hypopomidae are small fish; expected adult weight ~10-100 g; 588 g is ~1.17 log10 units above typical (40 g); likely a data entry error or wrong genus assignment; sources: FishBase + Froese_2014; recommend verifying original source record and correcting mass*

**Primary reference (audit):** <https://fishbase.se/summary/Hypopomus.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Malacoctenus delalandii*

| | |
|---|---|
| **Database value** | 0.01 g |
| **Corrected value** | 3 g |
| **Literature range** | 0.5 g – 2 g – 8 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Delalande's blenny (Labrisomidae); tropical W. Atlantic (Brazil coast); max TL ~8-10 cm; typical adult weight 1-8 g; dataset 0.01 g = 10 mg is 2-3 orders of magnitude below any plausible adult mass for a fish of this size; ERRONEOUS_MASS; likely data entry error in Brose_etal_2018 (e.g. units recorded as kg rather than g; or transcription error); recommend correction to ~2 g based on body size*

**Primary reference (audit):** <https://fishbase.se/summary/Malacoctenus-delalandii.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Oligoplites saliens*

| | |
|---|---|
| **Database value** | 27.5 g |
| **Corrected value** | 300 g |
| **Literature range** | 300 g – 600 g – 900 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*FishBase max weight 900g at max 50cm TL (common 35cm TL); dataset 27.5g is 1.51 log units below FishBase max weight; LWR a=0.08165 b=3.00 SL (n=3; 10.1-17.3cm) estimates ~224g at 14cm SL; 27.5g corresponds to ~7cm juvenile by this LWR; clearly too low for adult largescale leatherjack; source listed as fishbase suggests data entry or unit error; recommend replacing with ~400-600g for common-size adult; taxonomy correct (Carangidae; Perciformes)*

**Primary reference (audit):** <https://www.fishbase.se/summary/Oligoplites-saliens.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Opsanus pardus*

| | |
|---|---|
| **Database value** | 7.1 g |
| **Corrected value** | 400 g |
| **Literature range** | 50 g – 250 g – 690 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*FishBase max 38cm TL; LWR a=0.01605 b=3.000 SL (n=3) gives ~688g at ~35cm SL (38cm TL); LWR a=0.01440 b=2.770 TL (n=65; 7.6-12.7cm) gives ~342g at 38cm TL; dataset 7.1g (Pauly_2024) is 1.68-1.99 log units below LWR estimates; 7.1g corresponds to juvenile ~6-8cm TL; clearly erroneous for adult leopard toadfish (Batrachoididae); recommend replacing with ~250-400g for typical adult; taxonomy correct (Batrachoididae; Batrachoidiformes)*

**Primary reference (audit):** <https://www.fishbase.se/summary/Opsanus-pardus.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Orthonopias triacis*

| | |
|---|---|
| **Database value** | 1.6 g |
| **Corrected value** | 18 g |
| **Literature range** | 10 g – 25 g – 50 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*FishBase max TL 14.0 cm for snubnose sculpin (California coast); typical cottid LWR (a~0.006-0.012; b~3.0) yields ~12-25g at common size and 30-50g at max TL; dataset 1.6g is 1.19 log units below typical adult estimate of 25g; value is implausibly low for any life stage beyond very early larvae; likely unit error (value in kg entered as g: 1.6 kg ~1600g would be too high; more plausibly 16g or 25g); taxonomy correct (Cottidae; Scorpaeniformes); source Pauly_2024*

**Primary reference (audit):** <https://www.fishbase.se/summary/Orthonopias-triacis.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Platydoras armatulus*

| | |
|---|---|
| **Database value** | 1,293 g |
| **Corrected value** | 80 g |
| **Literature range** | 20 g – 75 g – 113 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Chocolate/Striped Raphael catfish (Siluriformes: Doradidae); Amazonia and Orinoco basins; FishBase Wmax ~113 g; max TL ~24 cm SL; dataset 1293 g = 11.4x the published maximum weight; |log10(1293/113)| = 1.06 > 1.0 log unit; single source Cai_etal_2025 (FishBase popchar); likely incorrect species record in the FishBase popchar query (e.g. aggregated with a much larger Doradidae); previously confused with Pterodoras granulosus which can reach ~1500 g; ERRONEOUS_MASS confirmed; recommend correcting to FishBase Wmax ~113 g or a representative adult value ~75 g*

**Primary reference (audit):** <https://fishbase.se/summary/Platydoras-armatulus.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Psenes pellucidus*

| | |
|---|---|
| **Database value** | 10,670 g |
| **Corrected value** | 100 g |
| **Literature range** | 100 g – 400 g – 900 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Blotched driftfish (Perciformes: Nomeidae); epipelagic/mesopelagic; FishBase max TL ~40 cm; typical adult driftfish at this size 200-800 g; 10670 g (10.7 kg): |log10(10670/400)| = 1.43 > 1.0 log unit; 10.7 kg would require a fish much larger than any known Psenes pellucidus; source Cai_etal_2025 (FishBase popchar); likely a wrong-species match in FishBase popchar query (e.g. confused with a large pelagic species) or order-of-magnitude error; abs_residual +1.27; ERRONEOUS_MASS confirmed; correct to adult representative ~300-500 g*

**Primary reference (audit):** <https://fishbase.se/summary/Psenes-pellucidus.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Ruvettus pretiosus*

| | |
|---|---|
| **Database value** | 215,400 g |
| **Corrected value** | 30,000 g |
| **Literature range** | 5,000 g – 20,000 g – 63,500 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Oilfish (Scombriformes: Gempylidae); large pelagic deep-sea predator; FishBase max published weight 63.5 kg (63500 g); dataset 215400 g (215.4 kg) exceeds FishBase Wmax by 3.4x; typical adult mass estimated 10000-30000 g (10-30 kg) based on commonly caught sizes; |log10(215400/20000)| = 1.03 > 1.0 log unit vs. typical; dataset value is biologically impossible given FishBase Wmax; possible extra-digit transcription error (e.g.; 21540 g or similar); ERRONEOUS_MASS; recommend CORRECT_MASS using FishBase-derived estimate ~20000 g*

**Primary reference (audit):** <https://www.fishbase.se/summary/Ruvettus-pretiosus.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Sebastes itinus*

| | |
|---|---|
| **Database value** | 8.2 g |
| **Corrected value** | 300 g |
| **Literature range** | 100 g – 300 g – 1,200 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Max SL 40.0 cm; Bayesian L-W (a=0.01 b=3.09 TL) gives typical adult 25-30 cm ~250-380 g and max ~1200 g; 8.2 g back-calculates to ~9 cm TL juvenile only; |log10(8.2)-log10(300)|=1.56 > 1.0; likely juvenile mass recorded instead of adult*

**Primary reference (audit):** <https://www.fishbase.se/summary/Sebastes-itinus.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Securicula gora*

| | |
|---|---|
| **Database value** | 2.461 g |
| **Corrected value** | 38 g |
| **Literature range** | 10 g – 35 g – 100 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Max TL 24.5 cm; FishBase Bayesian L-W (a=0.00631 b=3.01 TL) gives typical adult ~18 cm ~38 g and max ~97 g; 2.461 g back-calculates to ~7 cm TL juvenile only; |log10(2.461)-log10(38)|=1.19 > 1.0; likely juvenile mass or data entry error*

**Primary reference (audit):** <https://www.fishbase.se/summary/Securicula-gora.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Sphoeroides greeleyi*

| | |
|---|---|
| **Database value** | 2.2 g |
| **Corrected value** | 42 g |
| **Literature range** | 5 g – 42 g – 167 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Tetraodontidae; max 22.6 cm TL; common 14 cm TL; Bayesian LWR a=0.02042 b=2.89; W_typical=42g at common length; dataset 2.2g is 1.28 log10 units below typical (>1.0 threshold); corresponds to ~5 cm juvenile; likely juvenile mass or data entry error; CORRECT_TAXONOMY*

**Primary reference (audit):** <https://www.fishbase.se/summary/Sphoeroides-greeleyi.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Sphyraena guachancho*

| | |
|---|---|
| **Database value** | 26.6 g |
| **Corrected value** | 800 g |
| **Literature range** | 200 g – 600 g – 1,800 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Guaguanche barracuda; FishBase max TL 200 cm (common 70 cm); FishBase max published weight ~1.8 kg; barracuda LW (a~0.0049 b~3.04 TL) gives ~700 g at 60 cm TL and ~1400 g at 80 cm TL; 26.6 g back-calculates to ~17 cm TL juvenile; |log10(26.6/600)| = 1.35 > 1.0; source Viana_2016 (Brazilian estuarine study likely measuring juveniles); taxonomy correct (Perciformes/Sphyraenidae)*

**Primary reference (audit):** <https://www.fishbase.se/summary/Sphyraena-guachancho.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Trisopterus esmarkii*

| | |
|---|---|
| **Database value** | 11.64 g |
| **Corrected value** | 100 g |
| **Literature range** | 50 g – 150 g – 440 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Norway pout (Gadidae); max TL 35cm; common TL 19cm; max weight estimated ~300-440g for adult; LWR at common length (19cm) gives ~40-80g; 11.64g is ~1.1-1.2 log10 units below adult typical; Brown_etal_2018 likely recorded small juveniles or sub-adults; congeners Trisopterus minutus and T. luscus in dataset confirm order of magnitude; taxonomy correct*

**Primary reference (audit):** <https://www.fishbase.se/summary/Trisopterus-esmarkii.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Triakis megalopterus*

| | |
|---|---|
| **Database value** | 145 g |
| **Corrected value** | 20,000 g |
| **Literature range** | 5,000 g – 12,000 g – 25,000 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Taxonomy correct: Carcharhiniformes; Triakidae; spotted gully shark (sharptooth houndshark); South African endemic reaching FishBase max TL ~170 cm; expected adult mass for a 170 cm shark approximately 10-25 kg; viviparous pups are born at ~30-35 cm and well above 145 g; dataset 145 g = 0.145 kg is approximately 1.9 log units below expected adult mass of ~12 kg; |log10(145)-log10(12000)| = 1.92 log units — clearly > 1 log unit threshold; ERRONEOUS_MASS; likely a unit error (145 kg recorded as 145 g) or transcription error; 145 kg = 145000 g would be near the high end but at least plausible (|log10(145000)-log10(12000)| = 1.08 — borderline); recommend re-extraction from FishBase source and correction; dataset source FishBase*

**Primary reference (audit):** <https://www.fishbase.se/summary/Triakis-megalopterus.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

### Source: Makarieva 2008

#### *Crangon affinis*

| | |
|---|---|
| **Database value** | 0.0506 g |
| **Corrected value** | 1 g |
| **Literature range** | 0.3 g – 1 g – 3 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Crangonid sand shrimp (Crangonidae; Decapoda); East Asian coastal species; adults 30-60mm TL; congener C. crangon typical adult wet mass 0.5-5g; dataset 50.6mg is ~1.3 log10 below typical adult mass; source Makarieva_2008; likely mg-to-g unit error or mass recorded for small juvenile; taxonomy correct (Decapoda; Malacostraca)*

**Primary reference (audit):** <https://www.sealifebase.ca/summary/Crangon-affinis.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Hemichromis bimaculatus*

| | |
|---|---|
| **Database value** | 3 g |
| **Corrected value** | 80 g |
| **Literature range** | 50 g – 80 g – 150 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Jewel cichlid (Cichlidae); adults typically 10-14 cm SL and 50-120 g; FishBase max weight ~100-150 g; dataset 3 g corresponds to a tiny juvenile (~4-5 cm) not representative of adult body mass; log10(3) vs log10(80) = 1.43 log10 units below adult typical; clearly a juvenile specimen*

**Primary reference (audit):** <https://fishbase.se/summary/Hemichromis-bimaculatus.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Lumbriculus variegatus*

| | |
|---|---|
| **Database value** | 1.613 g |
| **Corrected value** | 0.015 g |
| **Literature range** | 0.003 g – 0.015 g – 0.05 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Dataset 1.613 g is ~2 log units above typical adult wet mass of 3–50 mg; well-studied OECD ecotoxicology test organism; largest plausible adult ~150 mg; probable g-to-mg unit error in source data (1.613 mg = 0.001613 g would be consistent)*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Lumbriculus_variegatus>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

### Source: Quaardvark

#### *Crotalus unicolor*

| | |
|---|---|
| **Database value** | 14 g |
| **Corrected value** | 1,000 g |
| **Literature range** | 900 g – 1,000 g – 1,400 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Aruba Island Rattlesnake; lit adult weight 900-1400g (avg ~1kg); dataset value 14g is approximately 70x below literature minimum; log10 diff = 1.85 >> 1.0; likely unit conversion error (g entered as if value were in kg; 14g vs 14kg) or data entry error; source is Quaardvark only; correct to ~1000g or remove and re-source*

**Primary reference (audit):** <https://a-z-animals.com/animals/aruba-rattlesnake/>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Lamprohiza splendidula*

| | |
|---|---|
| **Database value** | 5.138e-04 g |
| **Corrected value** | 0.1 g |
| **Literature range** | 0.02 g – 0.08 g – 0.2 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*European lesser glow-worm (Coleoptera: Lampyridae); body length ~10-15mm; 0.51mg is ~150x below expected adult mass (~80mg typical); |log10(0.000514)-log10(0.08)| = 2.19 log10 units; likely unit error (value may have been recorded as µg instead of mg) or a severely mislabeled record; Brose 2018 source; ERRONEOUS_MASS confirmed*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Lamprohiza_splendidula>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

### Source: Viana 2016

#### *Cynoscion virescens*

| | |
|---|---|
| **Database value** | 39.2 g |
| **Corrected value** | 2,000 g |
| **Literature range** | 100 g – 500 g – 3,000 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Green weakfish (Sciaenidae); source Viana_2016; FishBase max TL ~80 cm; using Cynoscion LWR comparable to C. leiarchus; typical adult (~40-50 cm) estimated 400-700 g; 39.2 g corresponds to juvenile (~12 cm TL); abs log10 diff vs typical = 1.11 (exceeds 1.0 threshold); likely a juvenile or erroneous entry; CORRECT_MASS recommended*

**Primary reference (audit):** <https://www.fishbase.se/summary/Cynoscion-virescens.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Etropus crossotus*

| | |
|---|---|
| **Database value** | 3.6 g |
| **Corrected value** | 60 g |
| **Literature range** | 20 g – 50 g – 120 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Fringed flounder (Paralichthyidae); max TL ~20-23 cm; typical adult weight 30-100 g; 3.6 g is ~1.1-1.7 log10 below expected adult mass for this species; far too light for any adult individual; likely a juvenile or prey-item mass; or unit/conversion error in Viana_2016; residual -1.66 log10; requires replacement with adult body mass*

**Primary reference (audit):** <https://fishbase.se/summary/Etropus-crossotus.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Parablennius parvicornis*

| | |
|---|---|
| **Database value** | 0.5064 g |
| **Corrected value** | 4 g |
| **Literature range** | 2 g – 5.29 g – 15 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*FishBase max 12.0 cm SL; Bayesian W-L a=0.00776; b=3.0 gives ~13.4 g at 12 cm and ~4.0 g at 8 cm; Brose_etal_2018 / Mendonca et al. 2018 (Madeira rock pools) reports 5.29 g for adults of this species; same Brose source also contains 0.15 g and 0.29 g from juvenile/small-bodied entries; dataset 0.5064 g appears to be an aggregation artifact capturing sub-adult measurements; |log10(0.5064) - log10(5.29)| = 1.019 > 1.0; recommended correction to adult representative mass ~5.29 g from Mendonca et al. 2018; taxonomy correct (Blenniidae; Perciformes)*

**Primary reference (audit):** <https://www.fishbase.se/summary/Parablennius-parvicornis.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

### Source: Bojsen 2005

#### *Floridichthys polyommus*

| | |
|---|---|
| **Database value** | 213.1 g |
| **Corrected value** | 1.8 g |
| **Literature range** | 0.5 g – 2 g – 5 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Seminole killifish (Cyprinodontidae); max TL ~5.5 cm; congeneric F. carpio (4.4 cm TL) = 1.8 g (Pauly 2024); FishBase Wmax of 213 g is clearly erroneous for this tiny killifish (~100x too heavy); expected adult mass 1-5 g; likely a FishBase LWR or data-entry error*

**Primary reference (audit):** <https://www.fishbase.se/summary/Floridichthys-polyommus>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

### Source: multi-source

#### *Eleutherodactylus johnstonei*

| | |
|---|---|
| **Database value** | 24 g |
| **Corrected value** | 4 g |
| **Literature range** | 1.5 g – 4 g – 8 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Johnstone's whistling frog; well-studied small Caribbean species, adults typically 2-8 g. 24 g is ~5x too high; likely unit or multi-source averaging error.*

**Primary reference (audit):** <https://amphibiaweb.org/species/1813>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Epitheca cynosura*

| | |
|---|---|
| **Database value** | — |
| **Corrected value** | 0.5 g |
| **Tier** | Suspicious () |

*(was Tetragoneuria_cynosura)*

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Gymnorhamphichthys rondoni*

| | |
|---|---|
| **Database value** | 1.641 g |
| **Corrected value** | 30 g |
| **Literature range** | 10 g – 30 g – 80 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Sand knifefish (Rhamphichthyidae; Gymnotiformes); slender gymnotiform from Amazon/Orinoco drainages; max TL ~28-38 cm; even a very slender adult at 20 cm would weigh ~10-30 g; dataset 1.641 g from FishBase almost certainly represents a single juvenile specimen or weight-entry error; log10(1.641) vs log10(30) = 1.26 log10 units below expected adult; model also predicts ~32 g (abs_residual 1.30); taxonomy correct; web search budget exhausted*

**Primary reference (audit):** <https://fishbase.se/summary/Gymnorhamphichthys-rondoni.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Himantolophus groenlandicus*

| | |
|---|---|
| **Database value** | 1.3 g |
| **Corrected value** | 2,000 g |
| **Literature range** | 200 g – 1,000 g – 5,000 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Atlantic footballfish (Himantolophidae); extreme sexual dimorphism: females reach ~60 cm TL and estimated 1-5 kg; males are tiny parasitic/free-living dwarfs ~2-4 cm and ~0.5-5 g; dataset 1.3 g is consistent with the male morph only; species representative adult mass for metabolic databases should use female; log10(1.3) vs log10(1000) = 2.89 log10 units below female typical; entry must be replaced with female-based mass estimate*

**Primary reference (audit):** <https://fishbase.se/summary/Himantolophus-groenlandicus.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Hypsiboas faber*

| | |
|---|---|
| **Database value** | 95 g |
| **Corrected value** | 25 g |
| **Literature range** | 10 g – 25 g – 50 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Blacksmith tree frog (Boana faber); adults typically 10-50 g. 95 g is ~2-4x too high; mass may be inflated by an outlier source or mis-assignment.*

**Primary reference (audit):** <https://amphibiaweb.org/species/2300>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Hypsiboas rosenbergi*

| | |
|---|---|
| **Database value** | 93 g |
| **Corrected value** | 25 g |
| **Literature range** | 10 g – 25 g – 50 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Rosenberg's tree frog (Boana rosenbergi); adults typically 10-50 g. 93 g is ~2-4x too high; likely an outlier source inflated the mean.*

**Primary reference (audit):** <https://amphibiaweb.org/species/2320>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Monoculodes scabriculosus*

| | |
|---|---|
| **Database value** | — |
| **Corrected value** | 0.01 g |
| **Tier** | Suspicious () |

*Oedicerotidae amphipod 5-20 mm; 470 mg too large (was Momoculodes)*

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Nesameletus ornatus*

| | |
|---|---|
| **Database value** | 2.479e-05 g |
| **Corrected value** | 0.002 g |
| **Literature range** | 0.001 g – 0.005 g – 0.02 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Taxonomy correct: Ephemeroptera; Nesameletidae; Nesameletus ornatus confirmed NZ mayfly; adult body length ~8-15 mm; typical adult wet mass 1-20 mg; dataset 0.0248 mg is ~2.3 log10 units below typical 5 mg; probable unit error (value in kg not g) or very early instar larva mass; mass ~200x too small for adult or mature nymph; Brose et al 2018 source*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Nesameletus>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Olinga feredayi*

| | |
|---|---|
| **Database value** | 2.509e-05 g |
| **Corrected value** | 0.003 g |
| **Literature range** | 0.001 g – 0.003 g – 0.01 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Taxonomy correct: Trichoptera; Conoesucidae; Olinga feredayi confirmed NZ caddisfly; larvae and adults typically 1-10 mg; dataset 0.0251 mg is ~1.8 log10 units below typical 3 mg; probable unit or scale error; mass ~120x too small; Brose et al 2018 source; see also Olinga_feredayii entry (likely duplicate with spelling variant)*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Olinga_feredayi>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Olinga feredayii*

| | |
|---|---|
| **Database value** | 9.362e-05 g |
| **Corrected value** | 0.003 g |
| **Literature range** | 0.001 g – 0.003 g – 0.01 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Taxonomy correct: Trichoptera; Conoesucidae; matched to Olinga feredayi (one i) at 95% confidence -- double-i spelling Olinga feredayii is not a recognized name; likely duplicate entry with spelling variant of Olinga_feredayi; dataset 0.0936 mg is ~1.5 log10 units below typical 3 mg; REMOVE duplicate or CORRECT_MASS if retained as distinct entry; Brose et al 2018 source*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Olinga_feredayi>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Pseudis limellum*

| | |
|---|---|
| **Database value** | 0.53 g |
| **Corrected value** | 10 g |
| **Literature range** | 3 g – 10 g – 30 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Pseudis frogs are medium-sized hylids; adults typically 3-30 g. 0.53 g is implausibly low for any adult Pseudis species.*

**Primary reference (audit):** <https://amphibiaweb.org/species/3999>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Rana cyanophlyctis*

| | |
|---|---|
| **Database value** | 0.294 g |
| **Corrected value** | 15 g |
| **Literature range** | 5 g – 15 g – 40 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Skittering frog (Euphlyctis cyanophlyctis); typical adult 5-40 g. 0.294 g is ~50x too low for this medium-sized frog. Source Makarieva_2008 likely recorded an incorrect unit or juvenile.*

**Primary reference (audit):** <https://amphibiaweb.org/species/4214>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Scolecolepides viridis*

| | |
|---|---|
| **Database value** | 14.93 g |
| **Corrected value** | 0.05 g |
| **Literature range** | 0.05 g – 0.5 g – 2 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Taxonomy correct: Spionida; Spionidae; Scolecolepides viridis is a junior synonym of Marenzelleria viridis (well-studied Baltic invasive spionid); adults reach 15-25 cm but published wet masses typically 0.05-2 g; 14.93 g is ~1.5 log10 units above expected typical (0.5 g) and ~1.0 log unit above plausible maximum (~2 g); likely represents batch weight or data entry error; abs_residual 2.00 is highest in this batch; recommend tracing to original Brose_etal_2018 record and correcting with individual wet mass*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Marenzelleria_viridis>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Simalia amethistina*

| | |
|---|---|
| **Database value** | 160,300 g |
| **Corrected value** | 15,000 g |
| **Literature range** | 8,000 g – 20,000 g – 30,000 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Amethystine python (Pythonidae); Australia and New Guinea; maximum documented mass ~27-30 kg (27000-30000g) per Wikipedia and multiple herpetological sources; average adult ~25 kg (25000g); 160300g (160.3 kg) is 5-6x the documented maximum; |log10(160300)-log10(20000)|=0.90 within 1 log10 unit of the upper plausible range but 160 kg far exceeds any credible record for the species; class_outlier=True in dataset; single Feldman_etal_2016 source; likely a data entry error (extreme outlier size record or unit conversion error); correct mass expected 10000-30000g; abs_residual 1.306*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Amethystine_python>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Trematomus bernacchii*

| | |
|---|---|
| **Database value** | 2.52 g |
| **Corrected value** | 300 g |
| **Literature range** | 50 g – 200 g – 490 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*2.52g is impossible for adult emerald rockcod; species max TL ~38 cm; FishBase max weight ~490g; typical adult 100-400g; |log10(2.52)-log10(200)|=1.90; Kim_2023 likely recorded larvae; otolith/physiology study; or units error (2.52 kg misrecorded as g would be 2520g still high; 0.252 kg=252g plausible); taxonomy correct (Perciformes; Nototheniidae)*

**Primary reference (audit):** <https://www.fishbase.se/summary/Trematomus-bernacchii.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Diura bicaudata*

| | |
|---|---|
| **Database value** | 3.708e-04 g |
| **Corrected value** | 0.1 g |
| **Literature range** | 0.003 g – 0.015 g – 0.06 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Plecoptera: Perlodidae (stoneflies); Diura bicaudata is a medium-large Scandinavian/northern European stonefly; nymph body length 10-22mm; adult and late-instar nymph mass typically 5-40mg; dataset 0.371mg is ~15-100x below expected range (|log10 diff| vs 15mg typical = 1.6 log10 units); probable early-instar nymph measurement or unit error; abs_residual 1.683; source Brose_etal_2018*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Diura_(insect)>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Archichauliodes diversus*

| | |
|---|---|
| **Database value** | 0.004315 g |
| **Corrected value** | 0.8 g |
| **Literature range** | 0.2 g – 0.4 g – 0.7 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Megaloptera Corydalidae; Wikipedia confirms larvae grow to 38.5 mm and species is "one of the biggest freshwater insects in New Zealand"; Corydalidae adults are >25 mm body length; expected adult mass 200–700 mg; dataset value 4.315 mg is ~100x too low; possible early-instar larva mass entered in error; Brose 2018 source; |log10(0.004315/0.4)| = 1.97*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Archichauliodes_diversus>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Dalopius marginatus*

| | |
|---|---|
| **Database value** | 3.117e-04 g |
| **Corrected value** | 0.01 g |
| **Literature range** | 0.01 g – 0.035 g – 0.08 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Coleoptera: Elateridae (click beetles); Dalopius marginatus is a European click beetle with body length ~7-9mm; expected adult wet mass for a beetle of this size class 15-80mg; dataset 0.31mg is ~50-100x too low (|log10 diff| vs 35mg typical = 2.1 log10 units); probable early larval measurement or unit conversion error; abs_residual 1.068; source Brose_etal_2018*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Dalopius>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Crychus caraboides*

| | |
|---|---|
| **Database value** | 0.3917 g |
| **Corrected value** | 0.08 g |
| **Literature range** | 0.01 g – 0.04 g – 0.12 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Coleoptera: Agyrtidae; Crychus is a junior synonym of Apteroloma (residuals DB resolves genus to Apteroloma; class assignment correct); Apteroloma species are small-medium carrion beetles with body length ~5-9mm; expected adult mass 10-100mg; dataset 391.7mg is ~4-40x too high (|log10 diff| vs 40mg typical = 1.0); notable that predicted mass ~5.9mg (log10_pred -2.231) is also very low for a beetle of this family; both predicted and dataset values may be unreliable; abs_residual 1.824; taxon key uses obsolete genus name; source Brose_etal_2018*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Agyrtidae>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Lamprohiza splendidula*

| | |
|---|---|
| **Database value** | 5.138e-04 g |
| **Corrected value** | 0.1 g |
| **Literature range** | 0.02 g – 0.08 g – 0.2 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*European lesser glow-worm (Coleoptera: Lampyridae); body length ~10-15mm; 0.51mg is ~150x below expected adult mass (~80mg typical); |log10(0.000514)-log10(0.08)| = 2.19 log10 units; likely unit error (value may have been recorded as µg instead of mg) or a severely mislabeled record; Brose 2018 source; ERRONEOUS_MASS confirmed*

**Primary reference (audit):** <https://en.wikipedia.org/wiki/Lamprohiza_splendidula>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Lepsiella albomarginata*

| | |
|---|---|
| **Database value** | 0.02164 g |
| **Corrected value** | 0.8 g |
| **Literature range** | 0.3 g – 0.8 g – 3 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*Small NZ/Australian muricid (Muricidae; Neogastropoda); shell ~15-25 mm; expected adult wet mass 0.3-3 g based on congeners of similar shell size; dataset 0.02164 g (21.6 mg) is ~14-140x below expected range; abs_residual 1.59; likely unit error or AFDM recorded as wet mass in Brose_etal_2018; lit range is size-derived estimate*

**Primary reference (audit):** <https://www.marinespecies.org/aphia.php?p=taxdetails&id=419671>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Osteochilus melanopleurus*

| | |
|---|---|
| **Database value** | — |
| **Corrected value** | 200 g |
| **Tier** | Suspicious () |

*FishBase: 4250 g is extreme outlier; typical 150-300 g (was melanopleura)*

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Atractus fuliginosus*

| | |
|---|---|
| **Database value** | — |
| **Corrected value** | 10 g |
| **Tier** | Suspicious () |

*small ground snake; 956 g impossible for this tiny colubrid (was Coluber)*

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Apocorophium acutum*

| | |
|---|---|
| **Database value** | — |
| **Corrected value** | 0.001 g |
| **Tier** | Suspicious () |

*mud amphipod 5-10 mm; 17 mg too large (was Corophium; also Brose above)*

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Astyris lunata*

| | |
|---|---|
| **Database value** | — |
| **Corrected value** | 0.1 g |
| **Tier** | Suspicious () |

*dove shell 7-12 mm; 1.18 mg too small (was Mitrella; also Brose above)*

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

#### *Pachycara brachycephalum*

| | |
|---|---|
| **Database value** | 3.5 g |
| **Corrected value** | 40 g |
| **Literature range** | 15 g – 35 g – 80 g |
| **Tier** | Suspicious (SUSPICIOUS) |

*FishBase max TL 22.3 cm for broadhead eelpout (Antarctic deep-sea zoarcid); typical zoarcid LWR gives 20-80g at 20-22 cm TL; dataset 3.5g is 1.00 log units below low estimate of 35g (typical adult); a 22 cm eelpout at 3.5g would require implausibly low density; Brose_etal_2018 feeding experiment database may record an exceptionally small juvenile or individual wet mass under anesthesia; 3.5g is biologically implausible for any specimen approaching max TL; taxonomy correct (Zoarcidae; Perciformes); source Brose_etal_2018*

**Primary reference (audit):** <https://www.fishbase.se/summary/Pachycara-brachycephalum.html>

**Peer-reviewed citations:**

> *Citation search pending — see literature search workflow results below.*

---

