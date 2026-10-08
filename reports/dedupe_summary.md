# Source de-duplication summary -- 2026-10-08 15:51:25

Values that enter through several compilations are collapsed before the cross-source mean (issue #5): a registry edge collapses a child value into its parent (or a sibling sharing an external parent) when the two agree within the edge tolerance; the blind rule collapses values identical to >= 3 significant digits in any two sources, whatever the registry says about the pair; `provenance_only` edges grant no tolerance-based collapse (their blind collapses are counted below, #31). Registry: `Bib/source_dependencies.csv`; code: `R/library/dedupe_sources.r`.

## Totals

| quantity | value |
| --- | ---: |
| species x source values (Pass-1 rows) | 125243 |
| accepted species | 40202 |
| multi-source species | 25297 |
| within-species value pairs | 290522 |
| pairs identical (|dlog10| <= 1e-06) | 51018 |
| pairs related by the registry and within its tolerance | 75429 |
| pairs identical to >= 3 significant digits (blind rule) | 43590 |
| values collapsed (total) | 46437 |
| values collapsed by a registry edge | 45096 |
| values collapsed by the blind rule only | 1341 |
| ... of which blind-identical to a provenance_only partner (blind (provenance_only edge)) | 13 |
| ... of which joined to a provenance_only partner through a third source (blind (via third source)) | 4 |
| species with at least one collapsed value | 20398 |
| multi-source species left with one independent value | 7047 |

## Registry edges with the parent in the database

shared = species with a value in both; exact = identical within 1e-6 log10; within_tol = within the edge tolerance;
collapsed_into_parent = child values collapsed into this parent; child_collapsed_total = child values collapsed into any kept value.

| child | parent | relation | status | tol_log10 | shared | exact | within_tol | f_exact | collapsed_into_parent | child_collapsed_total |
| --- | --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Hoehler_etal_2023 | Makarieva_2008 | copies | confirmed | 0.000001 | 932 | 742 | 742 | 0.8 | 624 | 1015 |
| DeLong_etal_2010 | Makarieva_2008 | copies | confirmed | 0.000001 | 108 | 56 | 56 | 0.52 | 58 | 131 |
| Ehnes_etal_2011 | Chown_etal_2007 | copies | confirmed | 0.000001 | 307 | 306 | 306 | 1 | 306 | 317 |
| Makarieva_2008 | Chown_etal_2007 | copies | confirmed | 0.000001 | 307 | 294 | 294 | 0.96 | 294 | 306 |
| Ehnes_etal_2011 | Makarieva_2008 | shared_primary | confirmed | 0.000001 | 311 | 292 | 292 | 0.94 | 1 | 317 |
| Herberstein_etal_2022 | Chown_etal_2007 | shared_primary | confirmed | 0.000001 | 166 | 96 | 96 | 0.58 | 99 | 368 |
| Meiri_2018 | Feldman_etal_2016 | derived_same_input | confirmed | 0.0105 | 6170 | 57 | 5389 | 0.01 | 5389 | 5392 |
| Cai_etal_2025 | Feldman_etal_2016 | copies | confirmed | 0.000001 | 239 | 210 | 210 | 0.88 | 214 | 2361 |
| Cai_etal_2025 | AmphiBIO | copies | confirmed | 0.000001 | 62 | 29 | 29 | 0.47 | 28 | 2361 |
| Wilman_etal_2014 | Smith_2003 | copies | confirmed | 0.001 | 3650 | 2503 | 3255 | 0.69 | 3397 | 12145 |
| Wilman_etal_2014 | Jones_2009 | copies | confirmed | 0.000001 | 3457 | 1176 | 1176 | 0.34 | 326 | 12145 |
| Cai_etal_2025 | Tobias_2022 | via | confirmed | 0.0105 | 1037 | 484 | 998 | 0.47 | 879 | 2361 |
| Myhrvold_2015 | Lislevand_etal_2007 | copies | suspected | 0.000001 | 3408 | 895 | 895 | 0.26 | 832 | 8702 |
| Myhrvold_2015 | Ernest_2003 | copies | suspected | 0.000001 | 1312 | 310 | 310 | 0.24 | 98 | 8702 |
| Myhrvold_2015 | Jones_2009 | via | confirmed | 0.0105 | 3457 | 1559 | 1978 | 0.45 | 722 | 8702 |
| Myhrvold_2015 | AnAge | copies | suspected | 0.000001 | 2452 | 649 | 649 | 0.26 | 856 | 8702 |
| Faurby_etal_2018 | Smith_2003 | copies | confirmed | 0.0105 | 3644 | 2084 | 3325 | 0.57 | 3330 | 3559 |
| Soria_etal_2021 | Myhrvold_2015 | copies | confirmed | 0.0105 | 4408 | 4320 | 4352 | 0.98 | 1976 | 4984 |
| Soria_etal_2021 | Faurby_etal_2018 | copies | confirmed | 0.000001 | 5160 | 989 | 989 | 0.19 | 405 | 4984 |
| Soria_etal_2021 | Smith_2003 | copies | confirmed | 0.000001 | 3648 | 593 | 593 | 0.16 | 1466 | 4984 |
| Soria_etal_2021 | Jones_2009 | copies | confirmed | 0.000001 | 3405 | 1532 | 1532 | 0.45 | 711 | 4984 |
| Jones_2009 | Smith_2003 | copies | confirmed | 0.000001 | 3291 | 629 | 629 | 0.19 | 1713 | 1832 |
| Cai_etal_2025 | Jones_2009 | via | confirmed | 0.0105 | 994 | 410 | 939 | 0.41 | 531 | 2361 |
| Cai_etal_2025 | Smith_2003 | copies | confirmed | 0.000001 | 1032 | 159 | 159 | 0.15 | 416 | 2361 |
| Cai_etal_2025 | AnAge | copies | confirmed | 0.000001 | 1194 | 153 | 153 | 0.13 | 188 | 2361 |
| Cai_etal_2025 | Quaardvark | copies | confirmed | 0.000001 | 1021 | 56 | 56 | 0.05 | 27 | 2361 |
| AnAge | Smith_2003 | copies | confirmed | 0.000001 | 1259 | 179 | 179 | 0.14 | 367 | 651 |
| AnAge | Fisher_2001 | copies | confirmed | 0.000001 | 125 | 49 | 49 | 0.39 | 40 | 651 |
| McCoy_2008 | Smith_2003 | copies | confirmed | 0.001 | 301 | 68 | 166 | 0.23 | 180 | 527 |
| Tucker_etal_2014b | Jones_2009 | via | confirmed | 0.0105 | 444 | 1 | 232 | 0 | 138 | 302 |
| Pata_2025 | Kiorboe_2013 | copies | confirmed | 0.000001 | 54 | 20 | 20 | 0.37 | 18 | 21 |
| Brose_etal_2018 | Hechinger_etal_2011 | copies | confirmed | 0.000001 | 94 | 65 | 65 | 0.69 | 63 | 87 |
| Brose_etal_2018 | Brose_2005 | copies | confirmed | 0.000001 | 255 | 19 | 19 | 0.07 | 19 | 87 |
| Baach_2026 | Chown_etal_2007 | copies | confirmed | 0.000001 | 296 | 296 | 296 | 1 | 296 | 453 |
| Baach_2026 | Wilman_etal_2014 | copies | confirmed | 0.000001 | 239 | 66 | 66 | 0.28 | 9 | 453 |
| Baach_2026 | Tobias_2022 | copies | confirmed | 0.0105 | 153 | 37 | 83 | 0.24 | 89 | 453 |
| Wascher_2025 | Tobias_2022 | copies | confirmed | 0.000001 | 119 | 116 | 116 | 0.97 | 116 | 120 |
| Wisnionski_2026 | AnAge | copies | confirmed | 0.0105 | 103 | 31 | 41 | 0.3 | 36 | 96 |
| Oskyrko_2024 | Feldman_etal_2016 | copies | confirmed | 0.001 | 0 | 0 | 0 |  | 0 | 7 |
| Oskyrko_2024 | Meiri_2018 | derived_same_input | confirmed | 0.001 | 0 | 0 | 0 |  | 0 | 7 |
| Gonzalez_2025 | Vanni_2017 | copies | confirmed | 0.001 | 44 | 8 | 10 | 0.18 | 10 | 10 |

## Siblings sharing an external parent

Pairs of sources that the registry traces to the same compilation outside the database; collapsed = values of either collapsed into the other.

| external_parent | pair | tol_log10 | shared | exact | within_tol | f_exact | collapsed |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| White_2006 | Hoehler_etal_2023 - Makarieva_2008 | 0.000001 | 932 | 742 | 742 | 0.8 | 624 |
| White_2006 | Hoehler_etal_2023 - Uyeda_etal_2017 | 0.000001 | 704 | 356 | 356 | 0.51 | 186 |
| White_2006 | Hoehler_etal_2023 - Wisnionski_2026 | 0.000001 | 76 | 2 | 2 | 0.03 | 1 |
| White_2006 | Makarieva_2008 - Uyeda_etal_2017 | 0.000001 | 356 | 208 | 208 | 0.58 | 209 |
| White_2006 | Makarieva_2008 - Wisnionski_2026 | 0.000001 | 44 | 4 | 4 | 0.09 | 3 |
| White_2006 | Uyeda_etal_2017 - Wisnionski_2026 | 0.000001 | 37 | 2 | 2 | 0.05 | 1 |
| McKechnie_2004 | Makarieva_2008 - Uyeda_etal_2017 | 0.000001 | 356 | 208 | 208 | 0.58 | 209 |
| Nagy_1999 | Castro_2025 - Hoehler_etal_2023 | 0.000001 | 261 | 51 | 51 | 0.2 | 45 |
| Dunning_2008 | AnAge - McCoy_2008 | 0.001 | 887 | 88 | 117 | 0.1 | 141 |
| Dunning_2008 | AnAge - Myhrvold_2015 | 0.0105 | 2452 | 649 | 1154 | 0.26 | 856 |
| Dunning_2008 | AnAge - Tobias_2022 | 0.000001 | 1134 | 280 | 280 | 0.25 | 650 |
| Dunning_2008 | AnAge - Wilman_etal_2014 | 0.001 | 2409 | 464 | 670 | 0.19 | 474 |
| Dunning_2008 | AnAge - Wisnionski_2026 | 0.0105 | 103 | 31 | 41 | 0.3 | 36 |
| Dunning_2008 | McCoy_2008 - Myhrvold_2015 | 0.0105 | 848 | 76 | 326 | 0.09 | 44 |
| Dunning_2008 | McCoy_2008 - Tobias_2022 | 0.001 | 540 | 74 | 128 | 0.14 | 111 |
| Dunning_2008 | McCoy_2008 - Wilman_etal_2014 | 0.001 | 844 | 146 | 290 | 0.17 | 2 |
| Dunning_2008 | McCoy_2008 - Wisnionski_2026 | 0.0105 | 70 | 9 | 28 | 0.13 | 11 |
| Dunning_2008 | Myhrvold_2015 - Tobias_2022 | 0.0105 | 8892 | 2067 | 5857 | 0.23 | 4771 |
| Dunning_2008 | Myhrvold_2015 - Wilman_etal_2014 | 0.0105 | 12239 | 2788 | 7200 | 0.23 | 86 |
| Dunning_2008 | Myhrvold_2015 - Wisnionski_2026 | 0.0105 | 155 | 18 | 47 | 0.12 | 17 |
| Dunning_2008 | Tobias_2022 - Wilman_etal_2014 | 0.000001 | 8424 | 8383 | 8383 | 1 | 7289 |
| Dunning_2008 | Tobias_2022 - Wisnionski_2026 | 0.0105 | 80 | 3 | 26 | 0.04 | 12 |
| Dunning_2008 | Wilman_etal_2014 - Wisnionski_2026 | 0.0105 | 112 | 6 | 29 | 0.05 | 0 |
| CareyJudge_2000 | AnAge - McCoy_2008 | 0.001 | 887 | 88 | 117 | 0.1 | 141 |

## Provenance-only edges (no tolerance-based collapse)

A provenance_only edge documents a relation whose values generally differ and takes no part in the registry closure. Values identical to >= 3 significant digits on such a pair are still collapsed by the blind rule and labelled `blind (provenance_only edge)`; values joined to the partner only through a third source are labelled `blind (via third source)` (#31).

| child | parent | parent_in_db | shared | exact | blind_identical | collapsed_blind_direct | collapsed_via_third_source |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: |
| Hoehler_etal_2023 | Hudson_2013 | TRUE | 75 | 3 | 7 | 7 | 0 |
| Cai_etal_2025 | fishbase | TRUE | 609 | 10 | 2 | 2 | 0 |
| AnAge | fishbase | TRUE | 212 | 0 | 0 | 0 | 0 |
| McCoy_2008 | Brey_2001 | FALSE |  |  |  | 0 | 0 |
| Tucker_etal_2014a | Jones_2009 | TRUE | 190 | 0 | 0 | 0 | 4 |
| Hebert_etal_2016 | Kiorboe_2013 | TRUE | 42 | 0 | 0 | 0 | 0 |
| Gonzalez_2025 | Ikeda_2014 | TRUE | 33 | 0 | 0 | 0 | 0 |
| Gonzalez_2025 | Kiorboe_2013 | TRUE | 26 | 0 | 0 | 0 | 0 |
| Vanni_2017 | Ikeda_2014 | TRUE | 91 | 4 | 4 | 4 | 0 |

## Multi-source species left with one independent value

7047 multi-source species rest on a single independent value after de-duplication, by number of sources:

| n_sources | species |
| ---: | ---: |
| 2 | 4347 |
| 3 | 1434 |
| 4 | 508 |
| 5 | 161 |
| 6 | 461 |
| 7 | 100 |
| 8 | 25 |
| 9 | 8 |
| 10 | 3 |

## Residual identical pairs outside the registry (>= 20 identical species)

Source pairs with no registry relation whose values are identical for many species: candidates for a new registry edge, or shared primary literature. identical_to_3sf = pairs the blind rule collapses; identical_but_round = identical values of one or two significant digits, left alone.

| pair | shared | exact | f_exact | identical_to_3sf | identical_but_round |
| --- | ---: | ---: | ---: | ---: | ---: |
| AnAge - Quaardvark | 1571 | 337 | 0.21 | 172 | 175 |
| AnAge - Ernest_2003 | 881 | 329 | 0.37 | 223 | 148 |
| Lislevand_etal_2007 - Wilman_etal_2014 | 3376 | 296 | 0.09 | 313 | 119 |
| Lislevand_etal_2007 - Tobias_2022 | 3368 | 292 | 0.09 | 308 | 119 |
| Ernest_2003 - Faurby_etal_2018 | 1293 | 251 | 0.19 | 126 | 139 |
| Ernest_2003 - Smith_2003 | 1310 | 241 | 0.18 | 141 | 130 |
| Ernest_2003 - Wilman_etal_2014 | 1308 | 235 | 0.18 | 127 | 127 |
| Myhrvold_2015 - Quaardvark | 2156 | 139 | 0.06 | 59 | 91 |
| Herberstein_etal_2022 - Tsuboi_etal_2018 | 1039 | 135 | 0.13 | 87 | 49 |
| Faurby_etal_2018 - Tsuboi_etal_2018 | 1348 | 133 | 0.1 | 79 | 62 |
| Faurby_etal_2018 - Quaardvark | 1423 | 128 | 0.09 | 58 | 82 |
| Tsuboi_etal_2018 - Wilman_etal_2014 | 3167 | 122 | 0.04 | 92 | 44 |
| Ernest_2003 - Quaardvark | 871 | 118 | 0.14 | 62 | 64 |
| Quaardvark - Soria_etal_2021 | 1429 | 117 | 0.08 | 46 | 78 |
| Smith_2003 - Tsuboi_etal_2018 | 1295 | 113 | 0.09 | 87 | 47 |
| Quaardvark - Wilman_etal_2014 | 2037 | 106 | 0.05 | 60 | 66 |
| AnAge - Lislevand_etal_2007 | 930 | 96 | 0.1 | 95 | 20 |
| Quaardvark - Smith_2003 | 1363 | 84 | 0.06 | 46 | 58 |
| Ernest_2003 - Jones_2009 | 1278 | 70 | 0.05 | 45 | 42 |
| Herberstein_etal_2022 - Uyeda_etal_2017 | 297 | 65 | 0.22 | 54 | 12 |
| Myhrvold_2015 - Uyeda_etal_2017 | 633 | 61 | 0.1 | 46 | 24 |
| Hoehler_etal_2023 - Myhrvold_2015 | 1156 | 60 | 0.05 | 66 | 25 |
| Jones_2009 - Tsuboi_etal_2018 | 1283 | 48 | 0.04 | 42 | 22 |
| Herberstein_etal_2022 - Wilman_etal_2014 | 1268 | 48 | 0.04 | 40 | 25 |
| Hoehler_etal_2023 - Soria_etal_2021 | 637 | 47 | 0.07 | 60 | 15 |
| Myhrvold_2015 - Tsuboi_etal_2018 | 3270 | 46 | 0.01 | 52 | 20 |
| Soria_etal_2021 - Uyeda_etal_2017 | 425 | 46 | 0.11 | 40 | 14 |
| Lislevand_etal_2007 - McCoy_2008 | 516 | 42 | 0.08 | 45 | 14 |
| Herberstein_etal_2022 - Myhrvold_2015 | 1347 | 42 | 0.03 | 29 | 22 |
| Soria_etal_2021 - Tsuboi_etal_2018 | 1350 | 42 | 0.03 | 36 | 18 |
| Faurby_etal_2018 - Herberstein_etal_2022 | 564 | 41 | 0.07 | 24 | 21 |
| Herberstein_etal_2022 - Pekar_etal_2021 | 40 | 38 | 0.95 | 28 | 10 |
| AnAge - Tsuboi_etal_2018 | 1529 | 36 | 0.02 | 19 | 24 |
| AnAge - Makarieva_2008 | 326 | 35 | 0.11 | 26 | 9 |
| Cai_etal_2025 - Ernest_2003 | 560 | 34 | 0.06 | 21 | 17 |
| Faurby_etal_2018 - GalanAcedo_etal_2026 | 409 | 34 | 0.08 | 10 | 26 |
| AnAge - Hoehler_etal_2023 | 722 | 33 | 0.05 | 29 | 7 |
| Castro_2025 - Makarieva_2008 | 284 | 33 | 0.12 | 21 | 14 |
| Ernest_2003 - McCoy_2008 | 258 | 29 | 0.11 | 13 | 18 |
| McCoy_2008 - Quaardvark | 625 | 29 | 0.05 | 15 | 21 |
| Hoehler_etal_2023 - Wilman_etal_2014 | 1016 | 27 | 0.03 | 27 | 12 |
| Jones_2009 - Quaardvark | 1360 | 25 | 0.02 | 17 | 18 |
| Fisher_2001 - Tsuboi_etal_2018 | 94 | 25 | 0.27 | 6 | 19 |
| AnAge - Herberstein_etal_2022 | 630 | 24 | 0.04 | 13 | 14 |
| Faurby_etal_2018 - Hoehler_etal_2023 | 638 | 23 | 0.04 | 19 | 9 |
| Cai_etal_2025 - Lislevand_etal_2007 | 546 | 23 | 0.04 | 32 | 6 |
| Herberstein_etal_2022 - Smith_2003 | 536 | 23 | 0.04 | 24 | 12 |
| GalanAcedo_etal_2026 - Soria_etal_2021 | 441 | 23 | 0.05 | 6 | 18 |
| Cai_etal_2025 - Tsuboi_etal_2018 | 1153 | 21 | 0.02 | 19 | 9 |
| Hirt_etal_2017 - Myhrvold_2015 | 333 | 20 | 0.06 | 14 | 9 |

