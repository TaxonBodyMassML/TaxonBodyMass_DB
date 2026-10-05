# Source de-duplication summary -- 2026-10-04 21:10:10

Values that enter through several compilations are collapsed before the cross-source mean (issue #5): a registry edge collapses a child value into its parent (or a sibling sharing an external parent) when the two agree within the edge tolerance; the blind rule collapses values identical to >= 3 significant digits in any two sources, whatever the registry says about the pair; `provenance_only` edges grant no tolerance-based collapse (their blind collapses are counted below, #31). Registry: `Bib/source_dependencies.csv`; code: `R/library/dedupe_sources.r`.

## Totals

| quantity | value |
| --- | ---: |
| species x source values (Pass-1 rows) | 120115 |
| accepted species | 39737 |
| multi-source species | 25324 |
| within-species value pairs | 256144 |
| pairs identical (|dlog10| <= 1e-06) | 40691 |
| pairs related by the registry and within its tolerance | 61777 |
| pairs identical to >= 3 significant digits (blind rule) | 35227 |
| values collapsed (total) | 41497 |
| values collapsed by a registry edge | 40217 |
| values collapsed by the blind rule only | 1280 |
| ... of which blind-identical to a provenance_only partner (blind (provenance_only edge)) | 2 |
| ... of which joined to a provenance_only partner through a third source (blind (via third source)) | 4 |
| species with at least one collapsed value | 20342 |
| multi-source species left with one independent value | 6949 |

## Registry edges with the parent in the database

shared = species with a value in both; exact = identical within 1e-6 log10; within_tol = within the edge tolerance;
collapsed_into_parent = child values collapsed into this parent; child_collapsed_total = child values collapsed into any kept value.

| child | parent | relation | status | tol_log10 | shared | exact | within_tol | f_exact | collapsed_into_parent | child_collapsed_total |
| --- | --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Hoehler_etal_2023 | Makarieva_2008 | copies | confirmed | 0.000001 | 933 | 722 | 722 | 0.77 | 610 | 1025 |
| DeLong_etal_2010 | Makarieva_2008 | copies | confirmed | 0.000001 | 107 | 55 | 55 | 0.51 | 57 | 129 |
| Ehnes_etal_2011 | Chown_etal_2007 | copies | confirmed | 0.000001 | 269 | 268 | 268 | 1 | 268 | 305 |
| Makarieva_2008 | Chown_etal_2007 | copies | confirmed | 0.000001 | 269 | 256 | 256 | 0.95 | 256 | 268 |
| Ehnes_etal_2011 | Makarieva_2008 | shared_primary | confirmed | 0.000001 | 300 | 281 | 281 | 0.94 | 28 | 305 |
| Hoehler_etal_2023 | Hudson_2013 | copies | confirmed | 0.000001 | 127 | 36 | 36 | 0.28 | 37 | 1025 |
| Herberstein_etal_2022 | Chown_etal_2007 | shared_primary | confirmed | 0.000001 | 152 | 84 | 84 | 0.55 | 87 | 352 |
| Meiri_2018 | Feldman_etal_2016 | derived_same_input | confirmed | 0.0105 | 6169 | 57 | 5388 | 0.01 | 5388 | 5391 |
| Cai_etal_2025 | Feldman_etal_2016 | copies | confirmed | 0.000001 | 239 | 210 | 210 | 0.88 | 214 | 2373 |
| Cai_etal_2025 | AmphiBIO | copies | confirmed | 0.000001 | 62 | 29 | 29 | 0.47 | 28 | 2373 |
| Cai_etal_2025 | Tobias_2022 | via | confirmed | 0.0105 | 1037 | 484 | 998 | 0.47 | 874 | 2373 |
| Myhrvold_2015 | Lislevand_etal_2007 | copies | suspected | 0.000001 | 3114 | 174 | 174 | 0.06 | 200 | 8585 |
| Myhrvold_2015 | Ernest_2003 | copies | suspected | 0.000001 | 1311 | 310 | 310 | 0.24 | 102 | 8585 |
| Myhrvold_2015 | Jones_2009 | via | confirmed | 0.0105 | 3457 | 1559 | 1978 | 0.45 | 710 | 8585 |
| Myhrvold_2015 | AnAge | copies | suspected | 0.000001 | 2452 | 650 | 650 | 0.27 | 873 | 8585 |
| Faurby_etal_2018 | Smith_2003 | copies | confirmed | 0.0105 | 3640 | 2082 | 3323 | 0.57 | 3328 | 3478 |
| Soria_etal_2021 | Myhrvold_2015 | copies | confirmed | 0.0105 | 4408 | 4320 | 4352 | 0.98 | 1976 | 4960 |
| Soria_etal_2021 | Faurby_etal_2018 | copies | confirmed | 0.000001 | 5160 | 989 | 989 | 0.19 | 404 | 4960 |
| Soria_etal_2021 | Smith_2003 | copies | confirmed | 0.000001 | 3643 | 593 | 593 | 0.16 | 1466 | 4960 |
| Soria_etal_2021 | Jones_2009 | copies | confirmed | 0.000001 | 3405 | 1532 | 1532 | 0.45 | 700 | 4960 |
| Jones_2009 | Smith_2003 | copies | confirmed | 0.000001 | 3287 | 629 | 629 | 0.19 | 1708 | 1852 |
| Cai_etal_2025 | Jones_2009 | via | confirmed | 0.0105 | 994 | 410 | 939 | 0.41 | 527 | 2373 |
| Cai_etal_2025 | Smith_2003 | copies | confirmed | 0.000001 | 1029 | 159 | 159 | 0.15 | 416 | 2373 |
| Cai_etal_2025 | AnAge | copies | confirmed | 0.000001 | 1194 | 153 | 153 | 0.13 | 197 | 2373 |
| Cai_etal_2025 | Quaardvark | copies | confirmed | 0.000001 | 1021 | 56 | 56 | 0.05 | 27 | 2373 |
| AnAge | Smith_2003 | copies | confirmed | 0.000001 | 1258 | 178 | 178 | 0.14 | 366 | 617 |
| AnAge | Fisher_2001 | copies | confirmed | 0.000001 | 124 | 49 | 49 | 0.4 | 40 | 617 |
| McCoy_2008 | Smith_2003 | copies | confirmed | 0.001 | 301 | 68 | 166 | 0.23 | 180 | 529 |
| Tucker_etal_2014b | Jones_2009 | via | confirmed | 0.0105 | 444 | 1 | 232 | 0 | 138 | 302 |
| Pata_2025 | Kiorboe_2013 | copies | confirmed | 0.000001 | 54 | 20 | 20 | 0.37 | 18 | 21 |
| Brose_etal_2018 | Hechinger_etal_2011 | copies | confirmed | 0.000001 | 93 | 64 | 64 | 0.69 | 62 | 85 |
| Brose_etal_2018 | Brose_2005 | copies | confirmed | 0.000001 | 251 | 19 | 19 | 0.08 | 19 | 85 |
| Baach_2026 | Chown_etal_2007 | copies | confirmed | 0.000001 | 258 | 258 | 258 | 1 | 258 | 432 |
| Baach_2026 | Wilman_etal_2014 | copies | confirmed | 0.000001 | 152 | 38 | 38 | 0.25 | 1 | 432 |
| Baach_2026 | Tobias_2022 | copies | confirmed | 0.0105 | 153 | 37 | 83 | 0.24 | 89 | 432 |

## Siblings sharing an external parent

Pairs of sources that the registry traces to the same compilation outside the database; collapsed = values of either collapsed into the other.

| external_parent | pair | tol_log10 | shared | exact | within_tol | f_exact | collapsed |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| White_2006 | Hoehler_etal_2023 - Makarieva_2008 | 0.000001 | 933 | 722 | 722 | 0.77 | 610 |
| White_2006 | Hoehler_etal_2023 - Uyeda_etal_2017 | 0.000001 | 704 | 347 | 347 | 0.49 | 182 |
| White_2006 | Makarieva_2008 - Uyeda_etal_2017 | 0.000001 | 356 | 208 | 208 | 0.58 | 209 |
| McKechnie_2004 | Makarieva_2008 - Uyeda_etal_2017 | 0.000001 | 356 | 208 | 208 | 0.58 | 209 |
| Nagy_1999 | Castro_2025 - Hoehler_etal_2023 | 0.000001 | 295 | 43 | 43 | 0.15 | 42 |
| Dunning_2008 | AnAge - McCoy_2008 | 0.001 | 887 | 88 | 117 | 0.1 | 146 |
| Dunning_2008 | AnAge - Myhrvold_2015 | 0.0105 | 2452 | 650 | 1156 | 0.27 | 873 |
| Dunning_2008 | AnAge - Tobias_2022 | 0.000001 | 1134 | 280 | 280 | 0.25 | 640 |
| Dunning_2008 | AnAge - Wilman_etal_2014 | 0.000001 | 1149 | 284 | 284 | 0.25 | 477 |
| Dunning_2008 | McCoy_2008 - Myhrvold_2015 | 0.0105 | 848 | 76 | 326 | 0.09 | 59 |
| Dunning_2008 | McCoy_2008 - Tobias_2022 | 0.001 | 540 | 74 | 128 | 0.14 | 121 |
| Dunning_2008 | McCoy_2008 - Wilman_etal_2014 | 0.001 | 544 | 77 | 131 | 0.14 | 4 |
| Dunning_2008 | Myhrvold_2015 - Tobias_2022 | 0.0105 | 8890 | 2066 | 5858 | 0.23 | 5251 |
| Dunning_2008 | Myhrvold_2015 - Wilman_etal_2014 | 0.0105 | 8636 | 2058 | 5797 | 0.24 | 106 |
| Dunning_2008 | Tobias_2022 - Wilman_etal_2014 | 0.000001 | 8656 | 8415 | 8415 | 0.97 | 7808 |
| CareyJudge_2000 | AnAge - McCoy_2008 | 0.001 | 887 | 88 | 117 | 0.1 | 146 |

## Provenance-only edges (no tolerance-based collapse)

A provenance_only edge documents a relation whose values generally differ and takes no part in the registry closure. Values identical to >= 3 significant digits on such a pair are still collapsed by the blind rule and labelled `blind (provenance_only edge)`; values joined to the partner only through a third source are labelled `blind (via third source)` (#31).

| child | parent | parent_in_db | shared | exact | blind_identical | collapsed_blind_direct | collapsed_via_third_source |
| --- | --- | --- | ---: | ---: | ---: | ---: | ---: |
| Cai_etal_2025 | fishbase | TRUE | 609 | 10 | 2 | 2 | 0 |
| AnAge | fishbase | TRUE | 212 | 0 | 0 | 0 | 0 |
| McCoy_2008 | Brey_2001 | FALSE |  |  |  | 0 | 0 |
| Tucker_etal_2014a | Jones_2009 | TRUE | 190 | 0 | 0 | 0 | 4 |
| Hebert_etal_2016 | Kiorboe_2013 | TRUE | 41 | 0 | 0 | 0 | 0 |

## Multi-source species left with one independent value

6949 multi-source species rest on a single independent value after de-duplication, by number of sources:

| n_sources | species |
| ---: | ---: |
| 2 | 4363 |
| 3 | 1627 |
| 4 | 269 |
| 5 | 526 |
| 6 | 127 |
| 7 | 26 |
| 8 | 8 |
| 9 | 3 |

## Residual identical pairs outside the registry (>= 20 identical species)

Source pairs with no registry relation whose values are identical for many species: candidates for a new registry edge, or shared primary literature. identical_to_3sf = pairs the blind rule collapses; identical_but_round = identical values of one or two significant digits, left alone.

| pair | shared | exact | f_exact | identical_to_3sf | identical_but_round |
| --- | ---: | ---: | ---: | ---: | ---: |
| AnAge - Quaardvark | 1571 | 337 | 0.21 | 172 | 175 |
| AnAge - Ernest_2003 | 881 | 329 | 0.37 | 223 | 148 |
| Ernest_2003 - Faurby_etal_2018 | 1292 | 251 | 0.19 | 126 | 139 |
| Ernest_2003 - Smith_2003 | 1308 | 240 | 0.18 | 140 | 130 |
| Lislevand_etal_2007 - Wilman_etal_2014 | 3103 | 143 | 0.05 | 129 | 60 |
| Lislevand_etal_2007 - Tobias_2022 | 3079 | 140 | 0.05 | 125 | 60 |
| Myhrvold_2015 - Quaardvark | 2156 | 139 | 0.06 | 59 | 91 |
| Faurby_etal_2018 - Tsuboi_etal_2018 | 1348 | 133 | 0.1 | 79 | 62 |
| Herberstein_etal_2022 - Tsuboi_etal_2018 | 1021 | 130 | 0.13 | 82 | 49 |
| Faurby_etal_2018 - Quaardvark | 1423 | 128 | 0.09 | 58 | 82 |
| Ernest_2003 - Quaardvark | 871 | 118 | 0.14 | 62 | 64 |
| Quaardvark - Soria_etal_2021 | 1429 | 117 | 0.08 | 46 | 78 |
| Smith_2003 - Tsuboi_etal_2018 | 1295 | 113 | 0.09 | 87 | 47 |
| Quaardvark - Smith_2003 | 1363 | 84 | 0.06 | 46 | 58 |
| Ernest_2003 - Jones_2009 | 1277 | 70 | 0.05 | 45 | 42 |
| Herberstein_etal_2022 - Uyeda_etal_2017 | 295 | 64 | 0.22 | 53 | 12 |
| Myhrvold_2015 - Uyeda_etal_2017 | 633 | 61 | 0.1 | 46 | 24 |
| Hoehler_etal_2023 - Myhrvold_2015 | 1210 | 58 | 0.05 | 63 | 24 |
| Jones_2009 - Tsuboi_etal_2018 | 1283 | 48 | 0.04 | 42 | 22 |
| Myhrvold_2015 - Tsuboi_etal_2018 | 3268 | 46 | 0.01 | 52 | 20 |
| Soria_etal_2021 - Uyeda_etal_2017 | 425 | 46 | 0.11 | 40 | 14 |
| Hoehler_etal_2023 - Soria_etal_2021 | 657 | 45 | 0.07 | 58 | 14 |
| Soria_etal_2021 - Tsuboi_etal_2018 | 1350 | 42 | 0.03 | 36 | 18 |
| Herberstein_etal_2022 - Myhrvold_2015 | 1326 | 41 | 0.03 | 28 | 22 |
| Faurby_etal_2018 - Herberstein_etal_2022 | 549 | 40 | 0.07 | 23 | 21 |
| Herberstein_etal_2022 - Pekar_etal_2021 | 40 | 38 | 0.95 | 28 | 10 |
| AnAge - Tsuboi_etal_2018 | 1529 | 36 | 0.02 | 19 | 24 |
| AnAge - Makarieva_2008 | 325 | 35 | 0.11 | 26 | 9 |
| Cai_etal_2025 - Ernest_2003 | 560 | 34 | 0.06 | 21 | 17 |
| Faurby_etal_2018 - GalanAcedo_etal_2026 | 409 | 34 | 0.08 | 10 | 26 |
| Castro_2025 - Makarieva_2008 | 283 | 33 | 0.12 | 21 | 14 |
| AnAge - Hoehler_etal_2023 | 765 | 32 | 0.04 | 27 | 8 |
| Ernest_2003 - McCoy_2008 | 258 | 29 | 0.11 | 13 | 18 |
| McCoy_2008 - Quaardvark | 625 | 29 | 0.05 | 15 | 21 |
| Jones_2009 - Quaardvark | 1360 | 25 | 0.02 | 17 | 18 |
| Fisher_2001 - Tsuboi_etal_2018 | 93 | 25 | 0.27 | 6 | 19 |
| AnAge - Herberstein_etal_2022 | 621 | 24 | 0.04 | 13 | 14 |
| Faurby_etal_2018 - Hoehler_etal_2023 | 658 | 23 | 0.03 | 20 | 9 |
| AnAge - Lislevand_etal_2007 | 878 | 23 | 0.03 | 25 | 4 |
| GalanAcedo_etal_2026 - Soria_etal_2021 | 441 | 23 | 0.05 | 6 | 18 |
| Herberstein_etal_2022 - Smith_2003 | 525 | 22 | 0.04 | 23 | 12 |
| Lislevand_etal_2007 - McCoy_2008 | 481 | 21 | 0.04 | 22 | 5 |
| Cai_etal_2025 - Tsuboi_etal_2018 | 1151 | 21 | 0.02 | 19 | 9 |
| Hirt_etal_2017 - Myhrvold_2015 | 333 | 20 | 0.06 | 14 | 9 |

