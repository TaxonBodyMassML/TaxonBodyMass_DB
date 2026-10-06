# Citation and provenance warnings -- 2026-10-06 13:32:41

Checks of RunMe.r section 8 (issue #1): bib keys of both files, CiteID rows of both Sheet tabs, the accepted primary references and the per-source coverage of TaxonBodyMass_Provenance.csv.gz.

## Totals

- provenance rows: 211506 (39887 species); distinct primary CiteIDs: 9288; unresolved references (pending / not_found): 968; unverified references: 829
- certain references resting on Crossref alone (verification_mode crossref_only, owner decision 2026-10-06; re-checked in full by the next `--verify` without `--crossref-only`): 3846

## Problems

(none)

## Sheet rows whose Bibcite is in neither bib file

(none)

## Labels in TaxonBodyMass.csv without a CiteID row

(none)

## Per-source coverage

One row per source label: species and record links (species x source x reference rows weighted by records), the share of record links resolved to a primary reference (hop >= 1 with a CiteID), and the reference counts of primary_references.csv by status (`refs_crossref_only`: the certain rows among `refs_resolved` that rest on Crossref alone).

| source_label | class | n_species | n_record_links | pct_resolved | refs_total | refs_resolved | refs_crossref_only | refs_pending | refs_not_found | refs_self | refs_rejected | refs_unverified | unmatched_key_links | uningested_links |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| AmphiBIO | compilation | 560 | 561 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| AnAge | database | 2748 | 2755 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| AndersonGillooly_2017 | compilation | 103 | 316 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Anunciacao_etal_2025 | compilation | 100 | 619 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| AyalaBerdon_2025 | compilation | 39 | 154 | 55.2 | 22 | 20 | 0 | 0 | 0 | 2 | 0 | 0 | 0 | 0 |
| Baach_2026 | compilation | 550 | 1066 | 99.2 | 8 | 7 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 |
| Barnes_2008 | compilation | 79 | 11547 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Brocher_etal_2025 | derived | 1346 | 1351 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Brose_2005 | compilation | 319 | 9258 | 93.2 | 12 | 7 | 0 | 0 | 0 | 0 | 5 | 0 | 0 | 0 |
| Brose_etal_2018 | compilation | 1916 | 183741 | 89.8 | 24 | 22 | 0 | 0 | 0 | 0 | 2 | 0 | 0 | 0 |
| Brown_etal_2018 | compilation | 33 | 33 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Cai_etal_2025 | compilation | 5069 | 5080 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Castro_2025 | compilation | 516 | 1967 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Chown_etal_2007 | compilation | 307 | 550 | 54.4 | 115 | 113 | 0 | 0 | 0 | 2 | 0 | 0 | 0 | 0 |
| DeLong_etal_2010 | compilation | 336 | 425 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| DeLong_etal_2018 | compilation | 164 | 563 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Ehnes_etal_2011 | compilation | 464 | 2654 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Eklof_etal_2017 | primary | 6 | 121 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Ernest_2003 | compilation | 1304 | 1314 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Faurby_etal_2018 | compilation | 5164 | 5900 | 90.8 | 596 | 317 | 216 | 29 | 248 | 0 | 2 | 0 | 0 | 0 |
| Feldman_etal_2016 | derived | 9651 | 9777 | 100 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Fisher_2001 | compilation | 152 | 155 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| GalanAcedo_etal_2026 | compilation | 449 | 562 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Ghaderi_2026 | derived | 221 | 553 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 553 |
| Gillooly_etal_2016 | compilation | 85 | 89 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Gonzalez_2025 | compilation | 233 | 2201 | 78.5 | 50 | 35 | 0 | 0 | 0 | 13 | 2 | 0 | 0 | 0 |
| GuoBailly_2024 | primary | 283 | 283 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Hebert_etal_2016 | compilation | 146 | 742 | 76.5 | 53 | 42 | 0 | 5 | 5 | 0 | 1 | 0 | 0 | 0 |
| Hechinger_etal_2011 | primary | 139 | 264 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Herberstein_etal_2022 | compilation | 1653 | 2693 | 100 | 193 | 193 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Hirt_etal_2017 | compilation | 380 | 513 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Hishi_etal_2019 | derived | 320 | 324 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Hoehler_etal_2023 | compilation | 1764 | 3411 | 100 | 16 | 16 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Hrycik_2024 | primary | 70 | 92 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Hudson_2013 | compilation | 125 | 1371 | 100 | 122 | 122 | 87 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Ikeda_2014 | compilation | 332 | 690 | 99.7 | 37 | 36 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 |
| Jennings_2002 | primary | 31 | 31 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Jones_2009 | compilation | 3444 | 23010 | 57.6 | 3066 | 2452 | 1651 | 578 | 30 | 0 | 6 | 0 | 0 | 0 |
| Kendall_etal_2019 | primary | 424 | 4033 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Killen_etal_2016 | compilation | 35 | 35 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Kinsella_etal_2020 | primary | 92 | 572 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Kiorboe_2013 | compilation | 127 | 324 | 52.5 | 17 | 15 | 0 | 2 | 0 | 0 | 0 | 0 | 0 | 0 |
| Kiorboe_2014 | compilation | 222 | 1524 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Lagrue_etal_2015 | primary | 19 | 115 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Lane_2019 | primary | 10 | 30 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Leahy_2025 | primary | 56 | 1551 | 0 | 1 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 |
| Lemoine_2026 | primary | 55 | 800 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Lislevand_etal_2007 | compilation | 3415 | 7399 | 67.8 | 84 | 81 | 0 | 0 | 0 | 2 | 1 | 0 | 0 | 0 |
| Lukic_2022 | compilation | 42 | 196 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Mahe_2023 | primary | 71 | 14563 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Makarieva_2008 | compilation | 1419 | 2958 | 97.7 | 340 | 299 | 145 | 16 | 6 | 0 | 0 | 19 | 0 | 0 |
| Mathieu_2014 | compilation | 96 | 97 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| McCoy_2008 | compilation | 1050 | 2801 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 2800 |
| Meiri_2018 | derived | 6582 | 46794 | 90.5 | 6233 | 5361 | 1690 | 13 | 10 | 9 | 33 | 807 | 0 | 0 |
| Meiri_2024 | compilation | 1162 | 1162 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Mercer_etal_2001 | primary | 51 | 52 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Mulder_2011 | primary | 103 | 4630 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Mull_etal_2022 | compilation | 18 | 35 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Myhrvold_2015 | compilation | 16326 | 26777 | 67 | 105 | 98 | 57 | 2 | 5 | 0 | 0 | 0 | 0 | 0 |
| Oskyrko_2024 | compilation | 30 | 34 | 91.2 | 22 | 19 | 0 | 0 | 0 | 0 | 0 | 3 | 0 | 0 |
| Pata_2025 | compilation | 117 | 117 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Pekar_etal_2021 | compilation | 99 | 363 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Quaardvark | database | 2372 | 2392 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Raymond_2011 | compilation | 120 | 1743 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Reum_2012 | primary | 22 | 22 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Reum_2013 | primary | 28 | 28 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Sarmiento-Lezcano_2023 | primary | 3 | 99 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Smith_2003 | compilation | 3679 | 5047 | 98.2 | 255 | 244 | 0 | 0 | 0 | 0 | 11 | 0 | 0 | 0 |
| Soria_etal_2021 | compilation | 5529 | 5636 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Tobias_2022 | compilation | 9794 | 10172 | 90.5 | 46 | 43 | 0 | 0 | 0 | 2 | 1 | 0 | 0 | 0 |
| Trochet_2014 | compilation | 51 | 52 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Tsuboi_etal_2018 | compilation | 3633 | 17122 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Tucker_etal_2014a | compilation | 182 | 182 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Tucker_etal_2014b | compilation | 440 | 443 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Uyeda_etal_2017 | compilation | 777 | 780 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Vanni_2017 | compilation | 217 | 5007 | 96.4 | 73 | 67 | 0 | 0 | 0 | 1 | 5 | 0 | 0 | 0 |
| Verberk_2020 | compilation | 214 | 1244 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Wascher_2025 | compilation | 124 | 124 | 100 | 4 | 4 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Weisse_2024 | compilation | 43 | 85 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Wilman_etal_2014 | compilation | 12511 | 14300 | 99.6 | 67 | 42 | 0 | 0 | 19 | 0 | 6 | 0 | 0 | 0 |
| Wisnionski_2026 | compilation | 149 | 150 | 100 | 53 | 53 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| fishbase | live | 2209 | 3153 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| sealifebase | live | 319 | 591 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| vertnet-amphibia-sept2016 | live | 139 | 980 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| vertnet-aves-sept2016 | live | 5807 | 80315 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| vertnet-fishes-sept2016 | live | 146 | 315 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| vertnet-mammalia-sept2016 | live | 833 | 9302 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| vertnet-reptilia-sept2016 | live | 310 | 2108 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| vertnet-traits-sept2016 | live | 5509 | 86681 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
