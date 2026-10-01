# Candidate new body-mass sources for TaxonBodyMass_DB

Literature sweep run 2026-09-27 with scite (Smart Citations + full text) and web search.
Every DOI below was retrieved through scite and checked for retraction / correction
notices; the only notice found is flagged in the Notes column. Companion BibTeX:
`candidate_sources_2026-09-27.bib` (entries generated from scite metadata, not memory).

**Scope decisions (2026-09-27):** extinct / fossil taxa and model-estimated (phylogenetically
imputed or predicted) species values are excluded. Sources removed under these rules are listed
at the end. Masses derived from species-specific measured dimensions through a published
allometry or unit conversion are kept but separated into their own tier, because the DB already
uses such values (Froese 2014 length–weight, Santini 2018, Meiri 2010, Feldman 2016).

## Where the DB is thin (TaxonBodyMass.csv, 36,573 species)

| Group | Species in DB | Comment |
|---|---|---|
| Chordata | 32,486 | 89% of DB; birds 10,403, reptiles 9,955, mammals 5,764, ray-finned fish 4,942, amphibians 924 |
| Insecta | 1,002 | largest absolute gap |
| Arachnida | 489 | almost all spiders (WST) |
| Mollusca / Annelida / Echinodermata / Cnidaria | 533 / 180 / 176 / 105 | mostly via SeaLifeBase |
| Nematoda / Platyhelminthes / Rotifera | 40 / 28 / 46 | meiofauna and parasites nearly absent |
| Heterotrophic protists (Ciliophora, Foraminifera, Amoebozoa, Myzozoa, Euglenozoa ...) | ~200 | |
| Bacteria / Archaea | 125 / 1 | |

Note: two existing sources already contribute extinct Late Quaternary species (Smith et al. 2003
MOM; PHYLACINE 1.2 via Faurby et al. 2018). If the no-extinct-taxa rule should apply
retroactively, those rows need a status filter in their parsing scripts.

AVONET (Tobias et al. 2022) is already in the bib but reaches the DB only through the
Google-Sheet override for 5 species; a full ingestion of its 11,009-species mass column is
the cheapest single addition for birds.

## Tier 1: measured body mass, species-level, open data

| Source | DOI / access | Taxa | ~n spp with mass | Mass type | Notes |
|---|---|---|---|---|---|
| Tobias et al. 2022 AVONET (full ingestion) | 10.1111/ele.13898; figshare CC-BY | Aves | 11,009 | body mass (g) | Currently 5 spp via Google Sheet only. |
| Cejp & Griebeler 2024, Ecol Evol | 10.1002/ece3.70377; SI CC-BY (mirror 10.25358/openscience-11805) | Amphibia | 2,069 (1,796 frogs, 236 salamanders, 37 caecilians) | adult body mass | Likely +1,000–1,500 amphibians. Check which values are literature vs SVL-converted and keep the measured ones in this tier. |
| Bröcher et al. 2025, Ecology data paper | 10.1002/ecy.70077; JEXIS 10.25829/Q570-JR82, CC-BY | Coleoptera, Hemiptera, Hymenoptera, Orthoptera, Isopoda, Myriapoda, Araneae (German grassland) | up to 1,374 | body mass + body length columns | Largest species-level insect mass table found. Verify in Appendix S1 whether mass is measured or length-regressed. |
| Tsuboi et al. 2018, Nat Ecol Evol | 10.1038/s41559-018-0632-1; Dryad | jawed vertebrates | 4,587 spp (20,213 specimens) | body mass (with brain mass) | +500–1,000 fishes/ectotherms expected. Article closed, data open. |
| Kiørboe & Hirst 2014, Am Nat | 10.1086/675241; PANGAEA 10.1594/PANGAEA.819857 (CC-BY 3.0) | marine pelagic heterotrophs: protists, copepods, euphausiids, gelatinous, salps, fish | several hundred (19,048 rows) | µg C per individual | Columns verified (taxon, mass, rate, reference). Needs C → wet-mass factor (unit conversion). |
| Ikeda 2014, Mar Biol | 10.1007/s00227-014-2540-5; Springer ESM xlsx | 13 metazooplankton groups incl. deep-sea copepods, euphausiids, amphipods, mysids, chaetognaths, medusae, ctenophores, pteropods, salps | 390 | dry mass, C, N per individual | Strong mesopelagic/bathypelagic coverage beyond Donnelly 1993. Same tables in Ikeda's 2007–2014 group papers. |
| Hoehler et al. 2023, PNAS | 10.1073/pnas.2303764120; PNAS Dataset S1 | all life incl. microbes | 2,912 spp | wet/dry/C mass per species | Screen for species absent from DeLong 2010 / Makarieva 2008. |
| Herberstein et al. 2022 AnimalTraits, Sci Data | 10.1038/s41597-022-01364-9; animaltraits.org, Zenodo, CC0 | terrestrial tetrapods, arthropods, molluscs, annelids | >1,700 | body mass, original units retained | Raw observation-level data with R aggregation scripts. |
| Meiri 2024 SquamBase, GEB | 10.1111/geb.13812; xlsx SI | Squamata | 11,744 spp (mass coverage partial) | body mass | Extends Feldman 2016 & Meiri 2018; mostly overlap, but resolves current taxonomy. Exclude any rows flagged as allometric estimates if the tier distinction matters. |
| Uyeda et al. 2017, Am Nat | 10.1086/692326; Dryad 10.5061/dryad.3c6d2 (CC0) | vertebrates (SMR) | 857 | body mass | Cleaned White et al. 2006 + McKechnie & Wolf; +100–300 ectotherms. |
| Kendall et al. 2019 pollimetry, Ecol Evol | 10.1002/ece3.4835; R pkg `pollimetry::pollimetry_dataset` | bees 391 spp, hoverflies 103 spp | 494 | dry mass (mg), 4,434 specimens | Measured, open, sex-resolved. Use the specimen dataset, not the model predictions. |
| Kinsella et al. 2020, Ecol Evol | 10.1002/ece3.6546; Zenodo 10.5281/zenodo.3786303 | British macro-moths + Crambidae/Pyralidae | measured subset of ~900 | dry mass (mg) | Keep only the field-measured records; drop the forewing-model estimates. |
| Ehnes, Rall & Brose 2011, Ecol Lett | 10.1111/j.1461-0248.2011.01660.x; Wiley Appendix S1 (article closed) | soil invertebrates: Collembola, Oribatida, Isopoda, Myriapoda, Insecta, Araneae | 3,661 records, ~415+ spp | fresh (some dry) mass mg | Best mite/springtail mass source; upstream of Blyth 2026. |
| Chown et al. 2007, Funct Ecol | 10.1111/j.1365-2435.2007.01245.x (bronze OA appendix) | Insecta, many orders | 391 | fresh mass with MR | Partial overlap with Makarieva 2008. |
| Hébert, Beisner & Maranger 2016, Ecology data paper | 10.1890/15-1275.1 | Copepoda, Cladocera (201 freshwater + 191 marine taxa) | ~390 | body mass among 13 traits | Article closed; ESA archive. |
| Hechinger et al. 2011, Ecology data paper | 10.1890/10-1383.1; Ecological Archives E092-066 | 3 estuary food webs incl. parasites | several hundred nodes | body mass by species/stage | Free-living + parasite masses. |
| Preston et al. 2012, Ecology data paper | 10.1890/11-2194.1; E093-153 Quick_Pond_Nodes.csv (verified) | pond inverts, amphibians, trematodes | 63 spp | dry mass | Small but clean. |
| Lagrue, Poulin & Cohen 2015, PNAS | 10.1073/pnas.1422475112; SI Appendix | NZ lake littoral metazoans + parasites | ~100+ | mean dry mass | Raw table not confirmed public; Cohen is data contact. |
| Hudson et al. 2013 cheddar R package | 10.1111/2041-210x.12005; CRAN | UK stream inverts (pHWebs, Ledger mesocosms, Benguela) | 100–200 taxa | node body mass | Tuesday Lake/Broadstone/Ythan/Skipwith duplicate Brose 2005. |
| Pawar, Dell & Savage 2012, Nature; Dell, Pawar & Savage 2011, PNAS (BioTraits) | 10.1038/nature11131; 10.1073/pnas.1015178108 | consumers protists → vertebrates | 376 / 309 spp | body mass | SI tables; screen for new inverts/protists. |
| Ribeiro Anunciação et al. 2025 Atlantic dung beetles, BDJ | 10.3897/bdj.13.e170578; figshare CC0 | Scarabaeinae | 137 valid spp + 210 morphospp | "biomass" g (dry vs fresh unspecified) | |
| Aromaa et al. 2019, Proc B | 10.1098/rspb.2019.2398; ESM | Odonata | 86 | fresh mass | Best Odonata source found. |
| Kaspari & Weiser 1999, Funct Ecol | 10.1046/j.1365-2435.1999.00343.x (bronze OA) | Formicidae workers | 135 | dry mass mg | |
| Mercer et al. 2001, Antarctic Science | 10.1017/s0954102001000219 | Marion Island mites, Collembola, insects, spiders | 67 | fresh + dry mass | Tables in paper (closed). |
| Hishi et al. 2019, Ecol Res | 10.1111/1440-1703.12022; JaLTER ERDP-2019-03 | Japanese Collembola | 407 listed; adult body-weight coverage unverified | unknown | Has a 2026 correction notice (10.1111/1440-1703.70039). |
| Huang et al. 2023 Amphibian Traits Database, GEB | 10.1111/geb.13656; SI | Amphibia | 42/27/37 morphological traits | mass column to verify | |
| Soria et al. 2021 COMBINE, Ecology | 10.1002/ecy.3344; Data S1 | Mammalia | 6,234 | body mass | Contains imputed rows: keep only rows flagged as non-imputed. Low new yield; useful as taxonomy harmoniser. |
| Lambden & Johnson 2013, Ecol Evol | 10.1002/ece3.635 (CC-BY) | trematodes, cestodes | 13 | measured dry mass | Small; direct parasite masses. |
| Hengherr et al. 2007, FEBS J | 10.1111/j.1742-4658.2007.06198.x | tardigrades | 8 | dry weight | Only species-level tardigrade masses found. |
| Hatton et al. 2019, PNAS | 10.1073/pnas.1900492116; Dataset S1 | eukaryotes | species-level | mixed | Derivative of DeLong etc.; protists sparse. Low added value. |
| Blyth et al. 2026, Ecol Lett | 10.1111/ele.70330; Zenodo 10.5281/zenodo.17170450 (1.6 GB, CC-BY) | 1,336 genera incl. 552 invertebrate genera | genus-level | fresh mass | Go to upstream Ehnes/Makarieva/White instead. |

## Tier 2: measured cell dimensions or volume, needing a documented volume→mass conversion

| Source | DOI / access | Taxa | ~n spp | Measurement | Notes |
|---|---|---|---|---|---|
| Madin et al. 2020, Sci Data | 10.1038/s41597-020-0497-4; GitHub v1.0.0 / figshare | Bacteria + Archaea | ~15,000 species-aggregated records; cell diameter/length coverage partial | cell dimensions | No newer release exists. |
| BacDive API v2 | api.bacdive.dsmz.de (free since Feb 2026) | Bacteria + Archaea | >100,000 strains | cell length × width ranges | Best raw numeric source for Archaea (DB has 1). |
| Laderrière et al. 2026 BactoTraits, Sci Data | 10.1038/s41597-026-06652-2; 10.24396/ORDAR-182, CC-BY-NC-ND | Bacteria | 97,721 strains, species csv | cell length/width (fuzzy classes; check raw) | BacDive-derived; licence restrictive. |
| Weisse 2024, L&O | 10.1002/lno.12503; Dryad 10.5061/dryad.cnp5hqc99 (CC0) | planktonic ciliates | 48 spp | cell volume µm³ | Convert via Menden-Deuer & Lessard 2000 (10.4319/lo.2000.45.3.0569). |
| Lukić et al. 2022, L&O Letters | 10.1002/lol2.10264; Dryad 10.5061/dryad.ksn02v76k (CC0) | marine + freshwater ciliates | 50–80 spp | cell volume | Overlaps Weisse 2024 partly. |
| Rose & Caron 2007, L&O | 10.4319/lo.2007.52.2.0886 (bronze OA) | heterotrophic protists | 50–100 spp | cell volume | Web appendix; unverified table. |
| Hansen, Bjørnsen & Hansen 1997, L&O | 10.4319/lo.1997.42.4.0687 (bronze OA) | flagellates, ciliates, rotifers, copepods | ~60 spp | body volume | Overlaps FoRAGE/Kiørboe. |
| Brey et al. 2010 body-composition bank | 10.1016/j.seares.2010.05.002; thomas-brey.de virtual handbook | aquatic invertebrates & fish | thousands of records | WM/DM/AFDM/energy ratios and some masses | Mostly conversion factors; mine for species masses and use its factors for the C/DM → WM step elsewhere. |
| Brun, Payne & Kiørboe 2017, ESSD | 10.5194/essd-9-99-2017; PANGAEA 10.1594/PANGAEA.862968 (CC-BY 3.0) | marine pelagic copepods | ~1,000+ with body size | some weight records; mostly length | Take the weight records only for this tier; check overlap with Pata 2025 first. |

## Tier 3: species-specific measured dimensions converted through a published allometry

Same category of value as Froese 2014 / Santini 2018 / Meiri 2010 already in the DB. Include only if that
practice is to continue; otherwise drop this tier.

| Source | DOI / access | Taxa | ~n spp | Basis | Notes |
|---|---|---|---|---|---|
| Nemaplex body-mass table (Ferris, UC Davis) | nemaplex.ucdavis.edu/Ecology/nematode_weights.htm (xlsx; licence unstated) | soil/freshwater Nematoda | 11,344 species × sex records, ~1,117 genera | measured L and D per species → Andrássy W = L·D²/1.6e6 | DB has 40 nematodes. Female-based; ask Ferris re licence/citation. |
| Benesh, Lafferty & Kuris 2017, Ecology data paper | 10.1002/ecy.1680; Wiley SI CSV | Acanthocephala, Cestoda, Nematoda (trophically transmitted) | 973 spp; 7,660 size records by stage | length × width per stage → biovolume, density ~1.1 | Largest parasite pool; use adult stage. |
| Mulder & Vonk 2011, Ecology data paper | 10.1890/11-0546.1; E092-171 txt | soil nematodes | 193 taxa (mostly genus) | dry mass from measured dimensions | Genus-level for most. |
| Cohen & Mulder 2014 SIZEWEB, Ecology data paper | 10.1890/13-1337.1; E095-051 | nematodes, mites, Collembola, myriapods, enchytraeids, earthworms | 258 taxa | dry mass | esapubs link 404; look on Wiley/figshare. |
| Bottinelli et al. 2020 Table S1 (Bouché 1972), Geoderma | 10.1016/j.geoderma.2020.114361 (bronze OA) | Lumbricidae | ~180 spp | measured length + diameter → mass via regression | Earthworm species. |
| Brun, Payne & Kiørboe 2017 (length records) | as above | marine copepods | ~1,000+ | prosome length → C via Kiørboe 2013 | |
| Lucas et al. 2011 "What's in a jellyfish?", Ecology data paper | 10.1890/11-0302.1; E092-144 | medusae, siphonophores, ctenophores, salps, doliolids, pyrosomes | 102 spp | species-specific length–mass regressions × measured size range | Gelatinous gap-filler. |
| Mull et al. 2022 Sharkipedia, Sci Data | 10.1038/s41597-022-01655-1; sharkipedia.org | Elasmobranchii | 170 spp | measured lengths + species allometries | Modest yield. |
| Miličić et al. 2026 SAFEGUARD, Sci Data | 10.1038/s41597-026-07513-8; Zenodo 10.5281/zenodo.18032357, CC-BY-NC-ND | 2,139 European bees, 913 hoverflies | ~2,000 | measured intertegular distance → dry mass via pollimetry allometry | Restrictive licence. |
| GABiP (Pincheira-Donoso lab; see correction 10.1111/geb.70188) | data by request | Amphibia | >7,000 max SVL | SVL → mass via Santini 2018 (already in DB) | Potentially +6,000 amphibians; not open. |
| Gossner et al. 2015, Sci Data | 10.1038/sdata.2015.13; Dryad CC0; `traitdataform::arthropodtraits` | 1,230 German arthropods | 1,230 | body length → mass via Sohlström 2018 / Potapov 2021 regressions | Largely superseded by Bröcher 2025. |
| Baranowski 2019 | 10.1594/PANGAEA.901825 | planktonic foraminifera | 36 | test diameter → volume; needs cytoplasm/density factor | New group. |

Tools for this tier: Potapov et al. 2021 Appendix S3 (10.1002/ecy.3421) soil-fauna length–mass regressions;
Benke et al. 1999 (10.2307/1468447) and Méthot 2012, Burgherr & Meyer 1997, Towers 1994, Mährlein 2016,
Bottrell 1976 freshwater-invertebrate regressions; Kiørboe 2013 (10.4319/lo.2013.58.5.1843) and
Menden-Deuer & Lessard 2000 carbon:volume factors.

## Excluded by scope decision (extinct taxa or model-estimated values)

| Source | DOI | Reason |
|---|---|---|
| Moura et al. 2024 TetrapodTraits | 10.1371/journal.pbio.3002658 | phylogenetically imputed masses; non-imputed rows come from sources already in DB |
| Thorson et al. 2017 FishLife | 10.1002/eap.1606 | predicted asymptotic mass for >32,000 fishes |
| Carmona et al. 2021 | 10.1126/sciadv.abf2675 | imputed tetrapod/fish masses |
| Gearty, McClain & Payne 2018 | 10.1073/pnas.1712629115 | 2,999 fossil mammals; the 3,859 extant overlap PHYLACINE/PanTHERIA |
| Alroy 1998 / PBDB fossil mammals | 10.1126/science.280.5364.731 | fossil |
| NOW database | Zenodo 10.5281/zenodo.4268068 | fossil |
| Benson et al. 2018 dinosaurs | 10.1111/pala.12329 | fossil |
| Slavenko et al. 2016 | 10.1111/geb.12491 | extinct Late Quaternary reptiles |
| Lundgren et al. 2021 HerbiTraits | 10.1038/s41597-020-00788-5 | Late Quaternary incl. extinct; extant species already covered |
| Faurby, Morlo & Werdelin 2021 CarniFOSS | 10.1111/geb.13369 | fossil |
| Smith et al. 2018 MOM update | 10.1126/science.aao5987 | extinct-heavy; PHYLACINE overlap |
| Kinsella 2020 forewing-model records; pollimetry predicted values; Cejp & Griebeler SVL-converted rows | see Tier 1 | keep measured subsets only |

## Checked and not usable (with reason)

GRIT (10.1111/icad.70035): proposal only, no data. GlobalAnts (10.1111/icad.12211): Weber's length, data-sharing agreement. BETSI (10.1371/journal.pone.0108985; portail.betsi.cnrs.fr): 44,413 spp but registration + request, mostly length. #GlobalCollembola (10.1038/s41597-023-02784-x): occurrences only; 1,384-taxon length table unpublished. carabids.org (10.1111/icad.12045): length only, no bulk download. Edaphobase: occurrence-only. Gilbert 2011 (10.1653/024.094.0433): method paper. Sohlström et al. 2018 (10.1002/ece3.4702): 6,212 individuals but order/family IDs. Ricciardi & Bourget 1998, Kiørboe 2013: conversion factors only. Polytraits, freshwaterecology.info, Twardochleb 2021, DISPERSE, Poff 2006: size classes. Cook et al. 2022, Middleton-Welling 2020, Shirey 2022 LepTraits, Karagkouni 2016: wingspan/length only with no species-specific regression path. Sylt, Flensburg, Otago Harbour parasite webs (10.1890/11-0351.1, 11-0374.1, 11-0371.1): metadata state no body size. Riede et al. 2011 (10.1111/j.1461-0248.2010.01568.x): no public raw data, overlaps Brose 2005. Hechinger 2011 Science (10.1126/science.1204337): same estuaries as the Ecology data paper. Kempes 2012 (10.1073/pnas.1115585109): reuses DeLong 2010. Dunning 2008: book, not open. TetraDENSITY: no mass column. FishTraits, FISHMORPH, Beukhof 2019: length/ratios only. Sheard 2020, Pigot 2020, Bird 2020, Cooke 2019, Etard 2020, Healy 2014/2019, Hudson 2013, Wilkinson & Adams 2019: masses drawn from AVONET/PanTHERIA/AnAge/EltonTraits. Slavenko 2019: duplicates Feldman/Meiri/SquamBase. Pacifici 2013, Genoud 2018, Trites & Pauly 1998: masses already covered. MarNemaFunDiv 2025: omits body size. sWorm/Phillips 2019: site-level biomass. Dumack 2020 / Freudenthal 2025 protist traits: genus-level categorical. Rotifers: only Pauli 1989 (12 spp, closed). Oribatida: no open species-level mass compilation (Noske 2024 uses 57 lengths). EOL TraitBank / Wikidata P2067: aggregators of existing sources with weak provenance.

## Suggested ingestion order

1. AVONET full ingestion (trivial; already in bib).
2. Cejp & Griebeler 2024 amphibians (measured rows); Bröcher 2025 arthropods; Tsuboi 2018 vertebrates.
3. Zooplankton block: Kiørboe & Hirst 2014, Ikeda 2014, Hébert 2016 (C/DM → WM factors from Brey 2010 / Kiørboe 2013).
4. Cross-taxon tables: Hoehler 2023, AnimalTraits, Uyeda 2017, Pawar 2012 / Dell 2011, SquamBase, COMBINE (non-imputed rows).
5. Insect specialists: pollimetry specimens, Kinsella 2020 measured records, Ehnes 2011, Chown 2007, Odonata, ants, dung beetles, Mercer 2001.
6. Parasite / food-web block: Hechinger 2011, Preston 2012, Lagrue 2015, cheddar pHWebs.
7. Microbes / protists (Tier 2) once a cell-volume → wet-mass conversion is documented: Madin 2020, BacDive/BactoTraits, Weisse 2024, Lukić 2022, Rose & Caron 2007, Hansen 1997.
8. Tier 3 (allometry-derived) only if that practice is confirmed: Nemaplex and Benesh 2017 would be the big wins (nematodes, helminths).

Existing pipeline conventions that matter for ingestion: one `sources/databases/<Name>/BodyMass_<Name>.r` per source, wet mass in grams (dry mass and carbon mass need documented conversion factors, as done for existing zooplankton sources), and a CiteID → Bibcite row in the BM_citations sheet for every new `source_mass` label.

## Implementation notes (2026-09-27, Tier 1 ingestion)

Re-screened against the raw files and metadata while writing the parsing scripts:

- **Dell et al. 2013 (BioTraits)**: removed. Metadata states that when a source gave no mass, wet mass was assigned by an algorithm "based on taxonomic relatedness to published size estimates and length-mass regressions", with no flag column. Fails the no-model-estimates rule.
- **Preston et al. 2012**: moved to Tier 3. Body sizes are dry masses mostly obtained from published length-mass regressions (metadata II.C.2.vi); only 39 species-level nodes.
- **Aromaa et al. 2019**: moved to Tier 3. Table 1 gives "estimated fresh body mass" derived from wing length.
- **Lambden & Johnson 2013**: removed. All adult rows are genus-level ("sp."); species-level rows are larval stages only.
- **cheddar pHWebs (Layer et al. 2010)**: moved to Tier 3. Node masses are length-regression estimates.
- **Hishi et al. 2019**: moved to Tier 3 (family-level length-weight equations). **Huang et al. 2023**: removed (no mass column).
- **SquamBase**: only the measured `mean female mass (g)` column (1,211 spp) is ingested; allometry-derived columns skipped.
- **AVONET**: rows with inferred, genus-average or modelled mass (Mass.Source Inferred / EltonTraits_GenAvg / EltonTraits_Model, or Traits.inferred containing Body Mass) are excluded (10,184 spp remain).
- **Kiørboe & Hirst 2014**: carbon masses converted with group-specific carbon:wet ratios; groups from WoRMS classification (`sources/databases/Kiorboe_2014/taxon_groups.csv`).
- **Hechinger et al. 2011**: only nodes with BodySizeEstimation 'species' or 'population' used; 'approximation' (size set equal to another species) excluded.

Ingested in this round (scripts in `sources/databases/`): Tobias_etal_2022 (label Tobias_2022), Tsuboi_etal_2018, Meiri_2024, Soria_etal_2021, Herberstein_etal_2022, Kendall_etal_2019, Kinsella_etal_2020, Hechinger_etal_2011, Kiorboe_2014.
Awaiting owner download: Uyeda_etal_2017, Brocher_etal_2025, Hoehler_etal_2023, Cejp_2024, Ikeda_2014, Ehnes_etal_2011, Chown_etal_2007, Hebert_etal_2016, Kaspari_1999, Mercer_etal_2001, Hengherr_etal_2007, RibeiroAnunciacao_etal_2025.

## Round 2 (2026-09-29): owner-downloaded sources

Files supplied by the owner for 8 of the 12 requested sources (Cejp 2024, Ehnes 2011, Kaspari 1999 and Hengherr 2007 judged not useful / unobtainable).

- **Ingested**: Uyeda_etal_2017 (fishes excluded: juvenile SMR specimens), Hebert_etal_2016 (dry mass; freshwater length-weight rows excluded), Hoehler_etal_2023 (wet mass; fishes, autotrophs and fungi excluded), Chown_etal_2007 (appendices parsed from the Word supplement), Mercer_etal_2001 (adult rows hand-transcribed from the scanned PDF), Ikeda_2014 (ESM PDF tables parsed by column position; adults only).
- **Excluded**: Brocher_etal_2025 -- JEXIS metadata states body mass was calculated from body length with Sohlström et al. (2018) equations (model-estimated).
- **Ingested after owner decision**: Anunciacao_etal_2025 dung beetles -- 'Biomass (g)' is not stated as dry or fresh; owner chose to treat it as fresh mass (100 species).

## Round 3 (2026-09-29): owner review of Tier 3 / held sources

Owner decisions: Benesh 2017, Nemaplex (not a citable publication), Preston 2012, Miličić 2026 and Bottinelli 2020 are not used. Length-derived masses are admitted where the owner judged the source useful.

- **Ingested**: Brocher_etal_2025 (1,360 arthropods; length-derived live mass, mg), Mull_etal_2022 (Sharkipedia 'Body Mass' records only, 20 species, g/kg converted), Hishi_etal_2019 (380 Japanese Collembola; trait and taxon tables joined on spID1/spID2; dry ug -> wet with the insect factor), Mathieu_2014 (97 French earthworms, maximum fresh mass from Bouché 1972), Cohen_2014 (SIZEWEB, 206 soil invertebrate genera; log10 ug dry mass, wet recovered with the source's own 0.20 ratio; genus-level output only), Mulder_2011 (104 soil nematode species, adults; dry ug from Andrássy volume, wet recovered with the source's own 0.20 ratio).
- Offsets vs existing DB values: Brocher +0.03 (n=192), Mull -0.18 (9), Mathieu +0.35 (10; maxima), Mulder +0.50 (13), Hishi +0.81 (18) log10.

## Round 4 (2026-10-01)

- Wang & Zhao (2026, Biology 15:84) Table S1 was screened for its sources only (owner did not want its data): Ehnes et al. 2011, White et al. 2006, Makarieva et al. 2008 and FishBase. Only Ehnes 2011 was absent from the DB; White 2006 enters through Uyeda 2017.
- **Ingested**: Ehnes_etal_2011 (Wiley supplement Appendix a, parsed from PDF; 494 species of soil invertebrates, live mass; median offset 0.00 against 293 overlapping DB species).
- Kiorboe_2013 Table A1 was also ingested as a body-mass source (159 species, mostly already present).

## Round 5 (2026-10-01): protist volumes, Lagrue 2014/2015, BacDive assessment

- **Ingested**: Lukic_2022 (42 ciliate species) and Weisse_2024 (46 ciliate species; abbreviated genus names expanded) with cell volume -> wet mass at unit density; median offsets -0.03 and -0.01 log10 against 32-34 overlapping species. Lagrue_etal_2014 (PNAS 2015 Dataset S1; 24 adult species of New Zealand lake fish, invertebrates and parasites; wet mass).
- Kiorboe_2013 data files now duplicated inside sources/databases/Kiorboe_2013 (copy retained under sources/conversion_factors).
- RunMe.r: enrichment-cache merge made type-safe after a GBIF outage aborted a run (character vs numeric gbif_usageKey).
- **BacDive** (api.bacdive.dsmz.de, CC BY 4.0, no login as of 2026): no mass or volume field. Cell morphology holds `cell length` / `cell width` as text ranges in um (e.g. '1.5-6.0 um') plus `cell shape`; roughly 6% of ~100,000 strains carry both dimensions (several thousand species, mostly type strains). Mass would require parsing the ranges, a shape-based volume (spherocylinder for rods, sphere for cocci) and a density (~1.1 g cm^-3); Madin et al. 2020 already merged these dimensions as diameter/length bounds, so starting from Madin's species table is the cheaper route. No published precedent converts BacDive dimensions to mass.
