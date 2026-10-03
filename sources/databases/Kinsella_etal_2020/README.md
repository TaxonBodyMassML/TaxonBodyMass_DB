# Kinsella et al. (2020) British moth dry masses

Source: Kinsella, R. S. et al. (2020) Unlocking the potential of historical abundance datasets to study biomass change in flying insects. Ecology and Evolution 10:8394-8404. https://doi.org/10.1002/ece3.6546
Data: github.com/CallumJMacgregor/KinsellaBiomass (Zenodo 10.5281/zenodo.3786303), `moth_data.csv` (field-weighed specimens) and `Species_macro.csv` (species list), downloaded 2026-09-27.

Columns used: `BINOMIAL`, `DRY_MASS` (mg), `FAMILY`. Parenthetical subgenera are removed from names.
Filters: measured specimens only; the modelled species estimates in the repository (FinalBiomassEstimates.csv) are not used.
Mass type: dry mass, mg -> g, then converted with the 'insect' factor in R/library/mass_conversion.r.
Source label: 'Kinsella_etal_2020; Studier_1992' (conversion reference appended).
Imputed rows: none; only field-weighed specimens are used (the repository's modelled species estimates are excluded, see Filters).
