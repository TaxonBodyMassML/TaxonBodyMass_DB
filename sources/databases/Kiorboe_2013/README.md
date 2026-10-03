# Kiørboe (2013) zooplankton body composition, Table A1 as a body-mass source

Source: Kiørboe, T. (2013) Zooplankton body composition. Limnology and Oceanography 58:1843-1850. https://doi.org/10.4319/lo.2013.58.5.1843
Data: Web Appendix Table A1, parsed copy in `Kiorboe2013_TableA1.csv` (725 records; wet, dry, ash, C and N mass in mg per record; 223 taxon strings). The parsed CSV, its references file (`Kiorboe2013_TableA1_references.csv`) and the raw supplement HTML (`1843a_TableA1_raw.html`) are stored here; a duplicate copy sits under `sources/conversion_factors/Kiorboe_2013/` for the conversion-factor derivation.

Columns used: `Group`, `Species`, `Wet mass (mg)`, `Dry mass (mg)`, `C (mg)`.
Filters: juvenile stages (copepodite CI-CV, Roman-numeral stages below VI, larvae, juv, mysis) dropped; adult/sex/salp-form markers stripped from names; genus-level names dropped; capitalisation fixed ('sagitta elegans', 'Salpa Thompsoni').
Mass type: wet mass where reported (label 'Kiorboe_2013'); otherwise dry mass, then carbon mass, converted with the group factors of R/library/mass_conversion.r (labels 'Kiorboe_2013; Lucas_2011' for gelatinous, 'Kiorboe_2013; MendenDeuer_2000' for protists, 'Kiorboe_2013; Brey_2010' for chaetognaths, molluscs, polychaetes; crustaceans converted with the Kiørboe factor keep the bare label). Protist 'wet mass' is cell volume at density 1; gastropod wet mass includes the shell.
Imputed rows: none flagged in source (per-record measurements from the literature compilation).
