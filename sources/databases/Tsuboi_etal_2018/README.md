# Tsuboi et al. (2018) brain-body allometry dataset

Source: Tsuboi, M. et al. (2018) Breakdown of brain-body allometry and the encephalization of birds and mammals. Nature Ecology & Evolution 2:1492-1500. https://doi.org/10.1038/s41559-018-0632-1
Data: Springer Nature figshare 10.6084/m9.figshare.6803276 (CC0), six xlsx files (teleost, amphibian, bird, mammal, reptile, shark_ray), downloaded 2026-09-27 (figshare file ids 12384077, 12384062, 12384068, 12384065, 12384071, 12384074).

Columns used: `Genus` + `Species` -> taxon; `Body weight (g)` or `Body mass (g)` (name differs by file); `Order`, `Family`; `Age Class`.
Filters: rows labelled Subadult/Sub-adult/Juvenile/Immature are dropped; 'Adult', 'Young adult' and 'unknown' retained for tetrapods. For teleosts and sharks/rays only adult-labelled rows are used (unknown-age fish specimens were systematically ~0.5 log10 lighter than other sources, i.e. mostly juveniles). Rows are individual or pooled observations; RunMe Pass 1 takes the within-source geometric mean per species.
Mass type: wet mass in grams; no conversion.
