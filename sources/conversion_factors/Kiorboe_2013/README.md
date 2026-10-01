# Kiørboe (2013) zooplankton body composition, Web Appendix Table A1

Source: Kiørboe, T. (2013) Zooplankton body composition. Limnology and Oceanography 58:1843-1850. https://doi.org/10.4319/lo.2013.58.5.1843
Data: Web Appendix Table A1 (`1843a_TableA1_raw.html`, Wiley supplement file 1843a.html, downloaded 2026-09-30), parsed to `Kiorboe2013_TableA1.csv` (725 records: Group, Species, Wet mass, Dry mass, Ash, C, N in mg, Reference) with `Kiorboe2013_TableA1_references.csv` (the 18 numbered sources). Scientific-notation values use Unicode minus/en-dash signs, normalised in the summary script.

`summarise_tableA1.py` computes per-record dry/wet, C/wet and C/dry ratios, averages them within species and writes group medians to `tableA1_group_medians.csv`. These supply the `crustacean_zooplankton`, `gelatinous_zooplankton` and `protist` rows of `R/library/mass_conversion.r`. Caveats from the paper: protist 'wet mass' is cell volume at density 1; gastropod wet mass includes the shell; gelatinous dry masses are inflated by bound water and salt.

Not a body-mass source: no BodyMass_*.r script reads this folder.
