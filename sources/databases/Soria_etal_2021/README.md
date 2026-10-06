# COMBINE (Soria et al. 2021)

Source: Soria, C. D. et al. (2021) COMBINE: a coalesced mammal database of intrinsic and extrinsic traits. Ecology 102:e03344. https://doi.org/10.1002/ecy.3344
Data: figshare 10.6084/m9.figshare.13028255 (CC BY 4.0), file `trait_data_reported.csv` (reported values only; the imputed file is deliberately not used), downloaded 2026-09-27 from https://ndownloader.figshare.com/files/27703263.
Licence: CC BY 4.0 (README, Citation.bib: the figshare record; https://doi.org/10.6084/m9.figshare.13028255). The csv is tracked.

Columns used: `iucn2020_binomial`, `adult_mass_g`, `order`, `family`.
Filters: rows with a binomial and a positive `adult_mass_g`; no other filter in the script. The 260 rows whose `iucn2020_binomial` is 'Not recognised' (taxa the IUCN 2020 list does not recognise) are removed by `R/library/fix_nontaxa.r` (issue #44).
Mass type: wet mass in grams; no conversion.
Imputed rows: none; only `trait_data_reported.csv` is read (COMBINE's imputed file is not used). Values inherited from the parent of a taxonomic split (flagged in figshare `trait_data_sources.csv`) and the 26 rows that reproduce PHYLACINE imputed or sister-species values are kept for now; their treatment is deferred to issue #5.
