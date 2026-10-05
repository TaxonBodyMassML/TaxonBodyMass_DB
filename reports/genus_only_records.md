# Genus-only records -- 2026-10-04 22:03:49

Input records identified to genus only (a cleaned name without an underscore; the sources' rows and the genus-level rows of the lab Sheet, which replace the sources' rows of the same bare name, issue #57) are resolved at genus rank through the enrichment cache and the GBIF backbone (R/library/enrich_genus.r, issue #49), filtered with FilterAutotrophs(), combined as one value per genus and source (geometric mean), de-duplicated with the registry Bib/source_dependencies.csv and combined as one record per genus (arithmetic mean of the independent per-source values) that enters the genus mean of TaxonBodyMass_GenusLevel.csv with the weight of one species. Names resolving above genus and names no stage resolved leave the table; the latter are also listed in reports/warnings_taxonomy.md.

## Totals

| quantity | value |
| --- | ---: |
| genus-only rows | 23657 |
| distinct bare names | 848 |
| names resolved to an accepted genus | 679 |
| ... rows | 14367 |
| distinct accepted genera | 675 |
| names resolved above genus | 167 |
| ... rows | 9249 |
| names unresolved | 2 |
| ... rows | 41 |
| autotroph genera removed | 18 |
| ... rows | 313 |
| genus x source values (after the autotroph filter) | 724 |
| values collapsed as copies | 2 |
| genus-only records (pseudo-taxa) | 657 |
| records more than 1 log10 from the genus's species mean | 47 |

## Resolution by stage

| match_type | outcome | names | rows |
| --- | --- | ---: | ---: |
| cache | genus | 469 | 7418 |
| EXACT | genus | 209 | 6948 |
| EXACT | above genus | 123 | 6558 |
| checklists | above genus | 39 | 2038 |
| curated | above genus | 2 | 411 |
| suffix | above genus | 3 | 242 |
| NONE | unresolved | 2 | 41 |
| FUZZY | genus | 1 | 1 |

## Names resolved above genus (excluded from the genus table)

| taxon | rank | match_type | kingdom | class | rows | sources | geometric_mean_g |
| --- | --- | --- | --- | --- | ---: | --- | --- |
| Oligochaeta | CLASS | EXACT | Animalia | Clitellata | 397 | Brose_2005, Brose_etal_2018 | 0.00378 |
| Trombidiidae | FAMILY | EXACT | Animalia | Arachnida | 377 | Brose_etal_2018 | 0.000695 |
| Tanytarsini | TRIBE | checklists | Animalia | Insecta | 327 | Brose_etal_2018 | 9.86e-05 |
| Anisoptera | SUBORDER | curated |  |  | 253 | Brose_2005, Brose_etal_2018 | 0.185 |
| Araneae | ORDER | EXACT | Animalia | Arachnida | 246 | Brose_2005, Brose_etal_2018 | 0.0109 |
| Staphylinidae | FAMILY | EXACT | Animalia | Insecta | 203 | Brose_2005, Brose_etal_2018 | 0.0111 |
| Tydeidae | FAMILY | EXACT | Animalia | Arachnida | 192 | Brose_etal_2018 | 1.57e-05 |
| Dinoflagellata | PHYLUM | checklists | Chromista |  | 184 | Brose_etal_2018 | 2.53e-09 |
| Chironomidae | FAMILY | EXACT | Animalia | Insecta | 180 | Brose_2005, Brose_etal_2018 | 0.000538 |
| Psychodidae | FAMILY | EXACT | Animalia | Insecta | 177 | Brose_2005, Brose_etal_2018 | 0.000535 |
| Cyanobacteria | PHYLUM | EXACT | Bacteria |  | 176 | Brose_2005, Brose_etal_2018 | 1.29e-11 |
| Ceratopogonidae | FAMILY | EXACT | Animalia | Insecta | 174 | Brose_2005, Brose_etal_2018 | 0.000124 |
| Salticidae | FAMILY | EXACT | Animalia | Arachnida | 171 | Brose_2005, Brose_etal_2018 | 0.00548 |
| Hydracarina | UNRANKED | curated |  |  | 158 | Brose_etal_2018 | 0.000304 |
| Ephydridae | FAMILY | EXACT | Animalia | Insecta | 157 | Brose_2005, Brose_etal_2018 | 0.000545 |
| Sciaridae | FAMILY | checklists | Animalia | Insecta | 157 | Brose_2005, Brose_etal_2018 | 0.000318 |
| Chloropidae | FAMILY | EXACT | Animalia | Insecta | 155 | Brose_2005, Brose_etal_2018 | 0.000836 |
| Mononchidae | FAMILY | EXACT | Animalia | Enoplea | 154 | Brose_etal_2018 | 6.9e-07 |
| Dorylaimoidea | SUPERFAMILY | checklists | Animalia | Enoplea | 149 | Brose_etal_2018 | 1.1e-06 |
| Aphidoidea | SUPERFAMILY | checklists | Animalia | Insecta | 144 | Brose_2005, Brose_etal_2018 | 0.000196 |
| Ichneumonidae | FAMILY | EXACT | Animalia | Insecta | 141 | Brose_2005, Brose_etal_2018 | 0.00215 |
| Zygoptera | SUBORDER | checklists | Animalia | Insecta | 139 | Brose_2005, Brose_etal_2018 | 0.0136 |
| Hybotidae | FAMILY | EXACT | Animalia | Insecta | 129 | Brose_2005, Brose_etal_2018 | 0.000162 |
| Lepidoptera | ORDER | EXACT | Animalia | Insecta | 122 | Brose_2005, Brose_etal_2018 | 0.000399 |
| Odonata | ORDER | EXACT | Animalia | Insecta | 119 | Brose_etal_2018 |  0.4 |
| Gastropoda | CLASS | EXACT | Animalia | Gastropoda | 110 | Brose_etal_2018 | 9.09 |
| Cucujidae | FAMILY | EXACT | Animalia | Insecta | 108 | Brose_etal_2018 | 0.0155 |
| Entedontini | TRIBE | suffix |  |  | 105 | Brose_etal_2018 | 0.000722 |
| Calliphoridae | FAMILY | EXACT | Animalia | Insecta | 99 | Brose_2005, Brose_etal_2018 | 0.0274 |
| Leptoceridae | FAMILY | EXACT | Animalia | Insecta | 99 | Brose_2005, Brose_etal_2018 | 0.000449 |
| Qudsianematidae | FAMILY | EXACT | Animalia | Enoplea | 99 | Brose_etal_2018 | 2.07e-07 |
| Neodiplogasteridae | FAMILY | EXACT | Animalia | Chromadorea | 94 | Brose_etal_2018 | 1.02e-07 |
| Staphylininae | SUBFAMILY | checklists | Animalia | Insecta | 94 | Brose_2005, Brose_etal_2018 | 0.0014 |
| Thornenematinae | SUBFAMILY | checklists | Animalia | Enoplea | 93 | Brose_etal_2018 | 9.92e-07 |
| Saltatoria | ORDER | EXACT | Animalia | Insecta | 90 | Brose_2005, Brose_etal_2018 | 0.0737 |
| Cecidomyiidae | FAMILY | checklists | Animalia | Insecta | 88 | Brose_2005, Brose_etal_2018 | 0.000131 |
| Chrysomelidae | FAMILY | EXACT | Animalia | Insecta | 86 | Brose_2005, Brose_etal_2018 | 0.00916 |
| Lycosidae | FAMILY | EXACT | Animalia | Arachnida | 86 | Brose_2005, Brose_etal_2018 | 0.00957 |
| Eupodidae | FAMILY | EXACT | Animalia | Arachnida | 83 | Brose_etal_2018 | 1.24e-05 |
| Syrphidae | FAMILY | EXACT | Animalia | Insecta | 83 | Brose_etal_2018 | 0.015 |
| Polychaeta | CLASS | checklists | Animalia | Polychaeta | 81 | Brose_etal_2018 | 0.033 |
| Pyraustidae | FAMILY | suffix |  |  | 77 | Brose_etal_2018 | 0.027 |
| Limoniidae | FAMILY | EXACT | Animalia | Insecta | 75 | Brose_2005, Brose_etal_2018 | 0.000996 |
| Delphacidae | FAMILY | EXACT | Animalia | Insecta | 72 | Brose_2005, Brose_etal_2018 | 0.00166 |
| Scydmaenidae | FAMILY | EXACT | Animalia | Insecta | 71 | Brose_etal_2018 | 0.003 |
| Empididae | FAMILY | EXACT | Animalia | Insecta | 69 | Brose_2005, Brose_etal_2018 | 0.00085 |
| Bivalvia | CLASS | EXACT | Animalia | Bivalvia | 68 | Brose_etal_2018 |  6.9 |
| Drosophilidae | FAMILY | EXACT | Animalia | Insecta | 67 | Brose_etal_2018 | 0.000532 |
| Bdellidae | FAMILY | EXACT | Animalia | Arachnida | 66 | Brose_etal_2018 | 2.86e-05 |
| Phoridae | FAMILY | EXACT | Animalia | Insecta | 66 | Brose_2005, Brose_etal_2018 | 0.000304 |
| Cecidomyidae | FAMILY | EXACT | Animalia | Insecta | 65 | Brose_etal_2018 | 0.003 |
| Stigmaeidae | FAMILY | EXACT | Animalia | Arachnida | 65 | Brose_etal_2018 | 6.25e-05 |
| Proctotrupoidea | SUPERFAMILY | checklists | Animalia | Insecta | 64 | Brose_2005, Brose_etal_2018 | 8.63e-05 |
| Amphipoda | ORDER | EXACT | Animalia | Malacostraca | 60 | Brose_etal_2018, Raymond_2011 | 4.35 |
| Pachygnatidae | FAMILY | suffix |  |  | 60 | Brose_etal_2018 | 1.62e-05 |
| Eupterygini | SUBTRIBE | checklists | Animalia | Insecta | 52 | Brose_2005, Brose_etal_2018 | 0.000371 |
| Apidae | FAMILY | checklists | Animalia | Insecta | 49 | Brose_etal_2018 | 0.00167 |
| Cyathocotylidae | FAMILY | EXACT | Animalia | Trematoda | 49 | Brose_etal_2018 | 5.2e-05 |
| Isopoda | ORDER | EXACT | Animalia | Malacostraca | 46 | Brose_etal_2018 | 0.14 |
| Membracidae | FAMILY | EXACT | Animalia | Insecta | 46 | Brose_etal_2018 | 0.0085 |
| Heteroptera | ORDER | checklists | Animalia | Insecta | 44 | Brose_2005, Brose_etal_2018 | 0.00185 |
| Phlaeothripidae | FAMILY | EXACT | Animalia | Insecta | 44 | Brose_2005, Brose_etal_2018 | 0.000631 |
| Gregarinea | CLASS | checklists | Chromista | Conoidasida | 43 | Brose_etal_2018 | 1.13e-06 |
| Tylenchidae | FAMILY | EXACT | Animalia | Chromadorea | 43 | Brose_etal_2018 | 8.18e-08 |
| Cephalobidae | FAMILY | EXACT | Animalia | Chromadorea | 42 | Brose_etal_2018 | 8.11e-08 |
| Plectidae | FAMILY | EXACT | Animalia | Chromadorea | 42 | Brose_etal_2018 | 3.89e-08 |
| Rhabditidae | FAMILY | EXACT | Animalia | Chromadorea | 42 | Brose_etal_2018 | 2.21e-07 |
| Trichoniscidae | FAMILY | EXACT | Animalia | Malacostraca | 41 | Brose_2005, Brose_etal_2018 | 0.00148 |
| Dolichodoridae | FAMILY | EXACT | Animalia | Chromadorea | 40 | Brose_etal_2018 | 1.39e-07 |
| Dorylaimida | ORDER | EXACT | Animalia | Enoplea | 40 | Brose_etal_2018 | 1.17e-06 |
| Libellulidae | FAMILY | EXACT | Animalia | Insecta | 39 | Brose_2005, Brose_etal_2018 | 0.237 |
| Sarcophagidae | FAMILY | EXACT | Animalia | Insecta | 39 | Brose_2005, Brose_etal_2018 | 0.0191 |
| Apocrita | SUBORDER | checklists | Animalia | Insecta | 37 | Brose_etal_2018 | 0.827 |
| Aeshnidae | FAMILY | EXACT | Animalia | Insecta | 36 | Brose_2005, Brose_etal_2018 | 0.244 |
| Poduromorpha | ORDER | EXACT | Animalia | Collembola | 36 | Brose_2005, Brose_etal_2018 | 2.99e-05 |
| Aleocharinae | SUBFAMILY | checklists | Animalia | Insecta | 35 | Brose_2005, Brose_etal_2018 | 0.000249 |
| Onychiuridae | FAMILY | EXACT | Animalia | Collembola | 34 | Brose_etal_2018 | 6.75e-06 |
| Diptera | ORDER | EXACT | Animalia | Insecta | 33 | Brose_2005, Brose_etal_2018 | 0.000864 |
| Limnephilidae | FAMILY | EXACT | Animalia | Insecta | 33 | Brose_2005, Brose_etal_2018 | 0.0131 |
| Helicidae | FAMILY | EXACT | Animalia | Gastropoda | 31 | Brose_2005, Brose_etal_2018 | 0.113 |
| Hemiuridae | FAMILY | EXACT | Animalia | Trematoda | 30 | Brose_etal_2018 | 0.00884 |
| Chromadoridae | FAMILY | EXACT | Animalia | Chromadorea | 29 | Brose_etal_2018 | 2.43e-08 |
| Entomobryomorpha | ORDER | EXACT | Animalia | Collembola | 29 | Brose_2005, Brose_etal_2018 | 3e-05 |
| Sminthuridae | FAMILY | EXACT | Animalia | Collembola | 29 | Brose_2005, Brose_etal_2018 | 3e-05 |
| Opilionida | ORDER | checklists | Animalia | Arachnida | 28 | Brose_2005, Brose_etal_2018 | 0.0111 |
| Cicadoidea | SUPERFAMILY | checklists | Animalia | Insecta | 27 | Brose_2005, Brose_etal_2018 | 0.000285 |
| Fulgoroidea | SUPERFAMILY | checklists | Animalia | Insecta | 27 | Brose_2005, Brose_etal_2018 | 0.000708 |
| Limacidae | FAMILY | EXACT | Animalia | Gastropoda | 27 | Brose_2005, Brose_etal_2018 | 0.303 |
| Philodromidae | FAMILY | EXACT | Animalia | Arachnida | 26 | Brose_2005, Brose_etal_2018 | 0.0131 |
| Thripidae | FAMILY | EXACT | Animalia | Insecta | 26 | Brose_2005, Brose_etal_2018 | 9.01e-05 |
| Jassinae | SUBFAMILY | checklists |  |  | 25 | Brose_2005, Brose_etal_2018 | 0.00442 |
| Microphysidae | FAMILY | EXACT | Animalia | Insecta | 25 | Brose_etal_2018 | 0.000244 |
| Sphaerocidae | FAMILY | checklists | Animalia | Insecta | 25 | Brose_2005, Brose_etal_2018 | 0.000419 |
| Rhinophoridae | FAMILY | EXACT | Animalia | Insecta | 24 | Brose_2005, Brose_etal_2018 | 0.00163 |
| Saproglyphidae | FAMILY | EXACT | Animalia | Arachnida | 24 | Brose_etal_2018 | 0.008 |
| Lumbricidae | FAMILY | EXACT | Animalia | Clitellata | 22 | Brose_2005, Brose_etal_2018 | 0.096 |
| Diapriidae | FAMILY | EXACT | Animalia | Insecta | 21 | Brose_2005, Brose_etal_2018 | 8.19e-05 |
| Plecoptera | ORDER | checklists | Animalia | Insecta | 21 | Brose_etal_2018 | 0.343 |
| Trichoptera | ORDER | EXACT | Animalia | Insecta | 21 | Brose_etal_2018 | 0.0282 |
| Agromyzidae | FAMILY | EXACT | Animalia | Insecta | 20 | Brose_2005, Brose_etal_2018 | 0.00012 |
| Chaoboridae | FAMILY | EXACT | Animalia | Insecta | 20 | Brose_etal_2018 | 0.0506 |
| Sciomyzidae | FAMILY | EXACT | Animalia | Insecta | 20 | Brose_etal_2018 | 0.0282 |
| Corophiidae | FAMILY | EXACT | Animalia | Malacostraca | 19 | Brose_etal_2018 | 0.00573 |
| Eucoilidae | FAMILY | EXACT | Animalia | Insecta | 19 | Brose_2005, Brose_etal_2018 | 0.000182 |
| Otitinae | SUBFAMILY | checklists | Animalia | Insecta | 19 | Brose_etal_2018 | 0.00133 |
| Symphypleona | ORDER | EXACT | Animalia | Collembola | 19 | Brose_etal_2018 | 1.09e-06 |
| Harpacticoida | ORDER | EXACT | Animalia | Copepoda | 18 | Brose_etal_2018 | 5.17e-06 |
| Isotomidae | FAMILY | EXACT | Animalia | Collembola | 18 | Brose_etal_2018 | 3.01e-06 |
| Jassidae | FAMILY | EXACT | Animalia | Malacostraca | 18 | Brose_2005, Brose_etal_2018 | 0.000355 |
| Scaphopoda | CLASS | EXACT | Animalia | Scaphopoda | 18 | Brose_etal_2018 |  4.3 |
| Tachinidae | FAMILY | EXACT | Animalia | Insecta | 18 | Brose_2005, Brose_etal_2018 | 0.00576 |
| Athericidae | FAMILY | EXACT | Animalia | Insecta | 17 | Brose_2005, Brose_etal_2018 | 0.00797 |
| Mycetophilidae | FAMILY | EXACT | Animalia | Insecta | 17 | Brose_2005, Brose_etal_2018 | 0.000962 |
| Blennocampinae | SUBFAMILY | checklists | Animalia | Insecta | 15 | Brose_2005, Brose_etal_2018 | 0.0115 |
| Foraminifera | PHYLUM | EXACT | Chromista |  | 15 | Brose_etal_2018 | 2e-05 |
| Tipulidae | FAMILY | EXACT | Animalia | Insecta | 15 | Brose_etal_2018 | 0.000532 |
| Carabidae | FAMILY | EXACT | Animalia | Insecta | 14 | Brose_2005, Brose_etal_2018 | 0.0131 |
| Trichodoridae | FAMILY | EXACT | Animalia | Enoplea | 14 | Brose_etal_2018 | 2.13e-07 |
| Caelifera | SUBORDER | checklists | Animalia | Insecta | 13 | Brose_2005, Brose_etal_2018 | 0.218 |
| Cyclopoida | ORDER | EXACT | Animalia | Copepoda | 13 | Brose_etal_2018 | 8.28e-06 |
| Oniscidea | SUBORDER | checklists | Animalia | Malacostraca | 12 | Brose_etal_2018 | 0.00243 |
| Longidoridae | FAMILY | EXACT | Animalia | Enoplea | 10 | Brose_etal_2018 | 3.97e-06 |
| Sipunculida | PHYLUM | checklists | Animalia |  | 10 | Brose_etal_2018 | 0.0701 |
| Insecta | CLASS | EXACT | Animalia | Insecta | 9 | Brose_etal_2018 | 0.003 |
| Thalassinidea | INFRAORDER | checklists | Animalia | Malacostraca | 9 | Brose_etal_2018 | 0.000115 |
| Pauropoda | CLASS | EXACT | Animalia | Pauropoda | 8 | Brose_etal_2018 | 0.00139 |
| Tanaidacea | ORDER | EXACT | Animalia | Malacostraca | 8 | Brose_etal_2018 | 0.00173 |
| Enchytraeidae | FAMILY | EXACT | Animalia | Clitellata | 7 | Hrycik_2024 | 0.000408 |
| Oribatida | ORDER | checklists | Animalia | Arachnida | 7 | Brose_etal_2018 | 4.9e-06 |
| Acrididae | FAMILY | EXACT | Animalia | Insecta | 6 | Brose_2005, Brose_etal_2018 | 0.224 |
| Hirudinea | CLASS | checklists | Animalia | Hirudinea | 6 | Brose_2005, Brose_etal_2018 | 0.197 |
| Oribatidae | FAMILY | EXACT | Animalia | Arachnida | 6 | Brose_etal_2018 | 0.000184 |
| Ostracoda | CLASS | EXACT | Animalia | Ostracoda | 6 | Brose_etal_2018 | 3.61e-05 |
| Lumbriculidae | FAMILY | EXACT | Animalia | Clitellata | 5 | Hrycik_2024 | 0.00242 |
| Capitellidae | FAMILY | EXACT | Animalia | Polychaeta | 4 | Brose_etal_2018 | 0.000417 |
| Carabinae | SUBFAMILY | checklists | Animalia | Insecta | 4 | Hirt_etal_2017 | 0.0941 |
| Theridiidae | FAMILY | EXACT | Animalia | Arachnida | 4 | Brose_etal_2018 | 0.000462 |
| Acarina | ORDER | checklists | Animalia | Arachnida | 3 | Brose_etal_2018 | 4.35e-05 |
| Araneidae | FAMILY | EXACT | Animalia | Arachnida | 3 | Brose_etal_2018 | 0.00014 |
| Liocranidae | FAMILY | EXACT | Animalia | Arachnida | 3 | Brose_etal_2018 | 0.000463 |
| Sphaeriidae | FAMILY | EXACT | Animalia | Bivalvia | 3 | Hrycik_2024 | 0.00236 |
| Hesionidae | FAMILY | checklists | Animalia | Polychaeta | 2 | Brose_etal_2018 | 0.0187 |
| Scomberesocidae | FAMILY | EXACT | Animalia |  | 2 | Castro_2025 | 0.0416 |
| Sertulariidae | FAMILY | EXACT | Animalia | Hydrozoa | 2 | Brose_etal_2018 | 0.04 |
| Tettigoniidae | FAMILY | EXACT | Animalia | Insecta | 2 | Brose_etal_2018 | 0.0302 |
| Thomisidae | FAMILY | EXACT | Animalia | Arachnida | 2 | Brose_etal_2018 | 0.000488 |
| Aeschnidae | FAMILY | EXACT | Animalia | Insecta | 1 | Brose_2005 | 0.381 |
| Arthropoda | PHYLUM | checklists | Animalia |  | 1 | Castro_2025 | 9.6e-05 |
| Astigmata | ORDER | checklists | Animalia | Arachnida | 1 | Cohen_2014 | 6.9e-07 |
| Channichthyidae | FAMILY | EXACT | Animalia |  | 1 | Raymond_2011 |   42 |
| Ciliophora | PHYLUM | EXACT | Chromista |  | 1 | Brose_2005 | 5.95e-10 |
| Copepoda | CLASS | EXACT | Animalia | Copepoda | 1 | Raymond_2011 | 0.00241 |
| Cranchiidae | FAMILY | EXACT | Animalia | Cephalopoda | 1 | Raymond_2011 |   62 |
| Crustacea | CLASS | checklists | Animalia | Crustacea | 1 | Raymond_2011 | 14.3 |
| Euphausiacea | ORDER | EXACT | Animalia | Malacostraca | 1 | Brose_etal_2018 |    1 |
| Gammaridae | FAMILY | EXACT | Animalia | Malacostraca | 1 | Hrycik_2024 | 0.00125 |
| Gyrinidae | FAMILY | EXACT | Animalia | Insecta | 1 | Brose_etal_2018 | 0.00376 |
| Linyphiidae | FAMILY | EXACT | Animalia | Arachnida | 1 | Brose_etal_2018 | 0.000497 |
| Macrouridae | FAMILY | EXACT | Animalia |  | 1 | Raymond_2011 |   31 |
| Myctophidae | FAMILY | EXACT | Animalia |  | 1 | Raymond_2011 |  8.8 |
| Nemertea | PHYLUM | EXACT | Animalia |  | 1 | Hrycik_2024 | 0.00295 |
| Nototheniidae | FAMILY | EXACT | Animalia |  | 1 | Raymond_2011 |  2.2 |
| Octopodidae | FAMILY | EXACT | Animalia | Cephalopoda | 1 | Raymond_2011 |  181 |
| Prayidae | FAMILY | EXACT | Animalia | Hydrozoa | 1 | Pata_2025 | 0.554 |
| Prostigmata | ORDER | checklists | Animalia | Arachnida | 1 | Cohen_2014 | 1.23e-06 |
| Teuthida | ORDER | checklists | Animalia | Cephalopoda | 1 | Raymond_2011 | 20.1 |
| Turbellaria | CLASS | EXACT | Animalia | Turbellaria | 1 | Hrycik_2024 | 0.000556 |

## Autotroph genera removed (FilterAutotrophs() on the resolved classification)

| genus | kingdom | phylum | rows | names | sources |
| --- | --- | --- | ---: | --- | --- |
| Gomphonema | Chromista | Ochrophyta | 71 | Gomphonema | Brose_etal_2018 |
| Eunotia | Chromista | Ochrophyta | 49 | Eunotia | Brose_etal_2018 |
| Achnanthes | Chromista | Ochrophyta | 36 | Achnanthes | Brose_etal_2018 |
| Fragilaria | Chromista | Ochrophyta | 35 | Fragilaria | Brose_etal_2018 |
| Ascophyllum | Chromista | Ochrophyta | 29 | Ascophyllum | Brose_etal_2018 |
| Acrosiphonia | Plantae | Chlorophyta | 15 | Acrosiphonia | Brose_etal_2018 |
| Thalassiosira | Chromista | Ochrophyta | 15 | Thalassiosira | Brose_etal_2018 |
| Ulva | Plantae | Chlorophyta | 13 | Enteromorpha | Brose_etal_2018 |
| Synechococcus | Bacteria | Cyanobacteria | 11 | Synechococcus | Castro_2025 |
| Cocconeis | Chromista | Ochrophyta | 7 | Cocconeis | Brose_etal_2018 |
| Entomoneis | Chromista | Ochrophyta | 7 | Entomoneis | Brose_etal_2018 |
| Gymnodinium | Chromista | Myzozoa | 7 | Gymnodinium | Brose_etal_2018 |
| Fragilariopsis | Chromista | Ochrophyta | 6 | Fragilariopsis | Brose_etal_2018 |
| Chaetoceros | Chromista | Ochrophyta | 5 | Chaetoceros | Brose_etal_2018 |
| Coccochloris | Bacteria | Cyanobacteria | 3 | Coccochloris | Makarieva_2008 |
| Synechocystis | Bacteria | Cyanobacteria | 2 | Synechocystis | Makarieva_2008 |
| Aphanocapsa | Bacteria | Cyanobacteria | 1 | Aphanocapsa | Makarieva_2008 |
| Desmarestia | Chromista | Ochrophyta | 1 | Desmarestia | Brown_etal_2018 |

## Fuzzy matches accepted (check by eye)

| taxon | genus | gbif_confidence | kingdom | family | rows | sources |
| --- | --- | ---: | --- | --- | ---: | --- |
| Isozercon | Zercon | 84 | Animalia | Zerconidae | 1 | Cohen_2014 |

## Homonyms and doubtful usages (the choice made; check by eye)

| taxon | genus | rank | kingdom | class | family | rows | note |
| --- | --- | --- | --- | --- | --- | ---: | --- |
| Amoebobacter | Amoebobacter | GENUS | Bacteria | Gammaproteobacteria | Chromatiaceae | 3 | only a DOUBTFUL genus usage |
| Anisoptera |  | SUBORDER |  |  |  | 253 | a group above genus that GBIF carries mostly as a homonymous genus (genus_only_higher_rank_names) |
| Ataxia | Ataxia | GENUS | Animalia | Insecta | Cerambycidae | 66 | homonym across kingdoms (Animalia, Plantae): Animalia preferred |
| Buchholzia | Buchholzia | GENUS | Animalia | Clitellata | Enchytraeidae | 7 | homonym across kingdoms (Animalia, Plantae): Animalia preferred |
| Chaetoderma | Chaetoderma | GENUS | Animalia | Caudofoveata | Chaetodermatidae | 3 | homonym across kingdoms (Animalia, Fungi, Plantae): Animalia preferred |
| Ciliophora |  | PHYLUM | Chromista |  |  | 1 | homonym across kingdoms (Chromista, Fungi): Chromista preferred |
| Cognettia | Cognettia | GENUS | Animalia | Clitellata | Enchytraeidae | 23 | homonym across kingdoms (Animalia, Chromista): Animalia preferred |
| Damaeobelba | Damaeobelba | GENUS | Animalia | Arachnida | Damaeidae | 1 | only a DOUBTFUL genus usage |
| Diptera |  | ORDER | Animalia | Insecta |  | 33 | homonym across kingdoms (Animalia, Plantae): Animalia preferred |
| Dolichorhynchus | Neodolichorhynchus | GENUS | Animalia | Chromadorea | Telotylenchidae | 16 | Dolichorhynchus is a synonym of Neodolichorhynchus; homonym across kingdoms (Animalia, Plantae): Animalia preferred |
| Euchrysia | Euchrysia | GENUS | Animalia | Insecta | Pteromalidae | 37 | only a DOUBTFUL genus usage |
| Hydracarina |  | UNRANKED |  |  |  | 158 | a group above genus that GBIF carries mostly as a homonymous genus (genus_only_higher_rank_names) |
| Lumbrinereis | Lumbrineris | GENUS | Animalia | Polychaeta | Lumbrineridae | 58 | Lumbrinereis is a synonym of Lumbrineris; 2 usages of equal standing in Animalia (Lumbrineridae): the first by usage key taken |
| Oligochaeta |  | CLASS | Animalia | Clitellata |  | 397 | homonym across kingdoms (Animalia, Plantae): Animalia preferred |
| Phyllodoce | Phyllodoce | GENUS | Animalia | Polychaeta | Phyllodocidae | 2 | homonym across kingdoms (Animalia, Plantae): Animalia preferred |
| Placus | Placus | GENUS | Chromista | Prostomatea | Placidae | 2 | homonym in 2 kingdoms settled by the source classification (kingdom=Chromista|phylum=Ciliophora|class=Prostomatea|order=Prorodontida|family=Placidae) |
| Platynothrus | Platynothrus | GENUS | Animalia | Arachnida | Crotoniidae | 1 | only a DOUBTFUL genus usage |
| Pontogeneia | Pontogeneia | GENUS | Animalia | Malacostraca | Pontogeneiidae | 1 | homonym in 2 kingdoms settled by the source classification (kingdom=Animalia|phylum=Arthropoda|class=Malacostraca|order=Amphipoda|family=Pontogeneiidae) |
| Rhabditis | Rhabditis | GENUS | Animalia | Chromadorea | Rhabditidae | 1 | homonym across kingdoms (Animalia, Fungi): Animalia preferred |
| Stenaphorurella | Stenaphorurella | GENUS | Animalia | Collembola | Tullbergiidae | 1 | only a DOUBTFUL genus usage |
| Tracheloraphis | Tracheloraphis | GENUS | Chromista | Karyorelictea | Trachelocercidae | 1 | homonym in 2 kingdoms settled by the source classification (kingdom=Chromista|phylum=Ciliophora|class=Karyorelictea|order=Protostomatida|family=Tracheolocercidae) |

## Genera that the GBIF checklists mostly use for a higher taxon (cross-rank homonyms; check by eye)

The name is an accepted genus (kept as such) but most checklists use it for a group above genus, e.g. Ensifera, the hummingbird genus and the orthopteran suborder; a source without classification hints may mean either.

| taxon | genus | kingdom | class | family | rows | sources | note |
| --- | --- | --- | --- | --- | ---: | --- | --- |
| Ensifera | Ensifera | Animalia | Aves | Trochilidae | 41 | Brose_2005, Brose_etal_2018 | accepted genus of 1 resolved species; also a higher taxon in the checklists: 23 of 78 ranked exact usages above genus (SUBORDER) |

## Synonyms and misspellings folded into the accepted genus

| taxon | genus | gbif_status | kingdom | family | rows | sources |
| --- | --- | --- | --- | --- | ---: | --- |
| Adamaeus | Damaeus | SYNONYM | Animalia | Damaeidae | 1 | Cohen_2014 |
| Anisomeristes | Sericoderus | SYNONYM | Animalia | Corylophidae | 108 | Brose_etal_2018 |
| Beneckea | Vibrio | SYNONYM | Bacteria | Vibrionaceae | 1 | Makarieva_2008 |
| Branhamella | Moraxella | SYNONYM | Bacteria | Moraxellaceae | 2 | Makarieva_2008 |
| Clethrionomys | Myodes | SYNONYM | Animalia | Cricetidae | 1 | vertnet-traits-sept2016 |
| Dendroica | Setophaga | SYNONYM | Animalia | Parulidae | 536 | Brose_etal_2018, vertnet-aves-sept2016 |
| Dolichorhynchus | Neodolichorhynchus | SYNONYM | Animalia | Telotylenchidae | 16 | Brose_etal_2018 |
| Eniochthonius | Hypochthoniella | SYNONYM | Animalia | Eniochthoniidae | 1 | Cohen_2014 |
| Enteromorpha | Ulva | SYNONYM | Plantae | Ulvaceae | 13 | Brose_etal_2018 |
| Ledermuelleria | Eustigmaeus | SYNONYM | Animalia | Stigmaeidae | 1 | Cohen_2014 |
| Lumbrinereis | Lumbrineris | SYNONYM | Animalia | Lumbrineridae | 58 | Brose_etal_2018 |
| Rhagidia | Foveacheles | SYNONYM | Animalia | Rhagidiidae | 1 | Cohen_2014 |
| Speleorchestes | Caenonychus | SYNONYM | Animalia | Nanorchestidae | 1 | Cohen_2014 |
| Thonus | Crassolabium | SYNONYM | Animalia | Dorylaimidae | 1 | Cohen_2014 |

## Names unresolved (dropped; also in warnings_taxonomy.md)

| taxon | rows | sources | note |
| --- | ---: | --- | --- |
| Silicioflagellata | 30 | Brose_etal_2018 | no GBIF usage of this name at any rank and no acceptable fuzzy genus match |
| Flagellatae | 11 | Brose_etal_2018 | no GBIF usage of this name at any rank and no acceptable fuzzy genus match |

## De-duplication of the genus x source values

Values collapsed as copies by the registry or the blind rule (dedupe_sources.r): dropped label, kept label, rule, values.

| dropped | kept | rule | values |
| --- | --- | --- | ---: |
| Makarieva_2008 | Chown_etal_2007 | registry | 1 |
| Brose_etal_2018 | Hechinger_etal_2011 | registry | 1 |

## Genus-only records more than one order of magnitude from the genus's species values

The genus-only record against the arithmetic mean of the genus's species cross-source means (the two enter the genus mean with equal weight). Genus-only records are not range-checked (issue #34); nothing is removed here.

| genus | genus_only_g | species_mean_g | n_species | log10_ratio | sources |
| --- | --- | --- | ---: | ---: | --- |
| Protoperidinium | 2.26e-14 | 9.83e-08 | 9 | -6.64 | Brose_etal_2018 |
| Cephalodiscus |  0.2 | 1.66e+05 | 1 | -5.92 | Brose_etal_2018 |
| Fritillaria | 4.9e-06 | 0.0928 | 1 | -4.28 | Brose_etal_2018 |
| Holoparamecus |    2 | 0.000115 | 1 | 4.24 | Brose_etal_2018 |
| Doliolum | 22.5 | 0.0021 | 1 | 4.03 | Pata_2025 |
| Pseudocalanus | 0.0928 | 5.8e-05 | 2 | 3.2 | Brose_etal_2018 |
| Henricia | 0.0701 | 94.1 | 2 | -3.13 | Brose_etal_2018 |
| Cercopithecus |    5 | 4.03e+03 | 17 | -2.91 | vertnet-mammalia-sept2016 |
| Ensifera | 0.0454 | 10.6 | 1 | -2.37 | Brose_2005; Brose_etal_2018 |
| Coryphaena | 28.3 | 6.25e+03 | 1 | -2.34 | vertnet-fishes-sept2016 |
| Ara |    5 |  785 | 9 | -2.2 | vertnet-aves-sept2016 |
| Xanthocalanus | 2.51e-05 | 0.00387 | 1 | -2.19 | Brose_etal_2018 |
| Spio | 0.00103 | 0.158 | 1 | -2.18 | Brose_etal_2018 |
| Octolasion | 0.0117 | 1.55 | 3 | -2.12 | Cohen_2014 |
| Planorbis | 0.00256 | 0.325 | 1 | -2.1 | Brose_etal_2018 |
| Trachylepis |  0.2 | 19.2 | 81 | -1.98 | vertnet-reptilia-sept2016 |
| Hirundichthys | 0.963 | 84.5 | 5 | -1.94 | vertnet-fishes-sept2016+vertnet-traits-sept2016 |
| Tomocerus | 1.15e-05 | 0.000774 | 12 | -1.83 | Cohen_2014 |
| Salpa | 22.6 | 0.342 | 2 | 1.82 | Pata_2025 |
| Canis |  236 | 1.39e+04 | 6 | -1.77 | vertnet-mammalia-sept2016+vertnet-traits-sept2016 |
| Scytodes | 4.75 | 0.082 | 1 | 1.76 | Brose_etal_2018 |
| Tylenchus | 2.81e-06 | 5e-08 | 1 | 1.75 | Cohen_2014 |
| Galago |    4 |  218 | 4 | -1.74 | vertnet-mammalia-sept2016 |
| Dorylaimus | 2.94e-07 | 1.5e-05 | 1 | -1.71 | Cohen_2014 |
| Trimeresurus | 14.1 |  459 | 42 | -1.51 | vertnet-reptilia-sept2016 |
| Dendrocygna |   26 |  774 | 7 | -1.47 | vertnet-aves-sept2016 |
| Phthiracarus | 5.74e-06 | 0.00017 | 12 | -1.47 | Cohen_2014 |
| Steganacarus | 8.3e-06 | 0.000211 | 3 | -1.41 | Cohen_2014 |
| Lumbricus | 0.199 |    5 | 8 | -1.4 | Cohen_2014 |
| Rana |    1 | 21.5 | 26 | -1.33 | vertnet-traits-sept2016 |
| Neodolichorhynchus | 3.88e-08 | 8.24e-07 | 1 | -1.33 | Brose_etal_2018 |
| Lygosoma | 1.34 | 27.7 | 14 | -1.32 | vertnet-reptilia-sept2016+vertnet-traits-sept2016 |
| Gallus |   44 |  908 | 3 | -1.31 | vertnet-aves-sept2016 |
| Dolomedes | 0.03 | 0.573 | 4 | -1.28 | Brose_etal_2018 |
| Chiromantis | 0.548 | 10.3 | 3 | -1.27 | vertnet-amphibia-sept2016 |
| Eupodes | 3.44e-05 | 2e-06 | 1 | 1.24 | Brose_etal_2018; Cohen_2014 |
| Lagopus | 31.5 |  514 | 2 | -1.21 | vertnet-traits-sept2016 |
| Tyrophagus | 1.73e-05 | 1.17e-06 | 1 | 1.17 | Brose_etal_2018; Cohen_2014 |
| Pelagobia | 0.0253 | 0.0019 | 1 | 1.12 | Pata_2025 |
| Microtritia | 2.08e-06 | 2.74e-05 | 1 | -1.12 | Cohen_2014 |
| Eupelops | 1.07e-05 | 0.000139 | 3 | -1.11 | Cohen_2014 |
| Mononchus | 3.26e-07 | 3.96e-06 | 2 | -1.08 | Brose_etal_2018; Cohen_2014 |
| Strongylura |   37 |  421 | 4 | -1.06 | vertnet-fishes-sept2016 |
| Bufo | 7.96 | 85.5 | 4 | -1.03 | vertnet-amphibia-sept2016 |
| Veigaia | 0.000408 | 3.81e-05 | 5 | 1.03 | Brose_etal_2018; Cohen_2014 |
| Mustela | 55.5 |  577 | 17 | -1.02 | vertnet-mammalia-sept2016+vertnet-traits-sept2016 |
| Sphenomorphus | 1.24 | 12.5 | 107 | -1 | vertnet-reptilia-sept2016+vertnet-traits-sept2016 |

