# Grimm et al. (2014) European reptile life-history trait database

Source: Grimm, A., Prieto Ramírez, A. M., Moulherat, S., Reynaud, J., & Henle, K. (2014). Life-history trait database of European reptile species. Nature Conservation 9:45–67. <https://doi.org/10.3897/natureconservation.9.8908> (Grimm:2014aa)
Data: `Grimm_2014_body_mass.csv` (131 rows; Morphometry table extracted from `Grimm_etal_Reptile_DB_Update_2015.accdb`, a 2015 update of the database published with the article; body mass rows extracted by `extract_body_mass.py`; the Access DB is not tracked — only the extracted CSV is).
Licence: CC BY 4.0 (Nature Conservation/Pensoft open-access article and database supplement; <https://doi.org/10.3897/natureconservation.9.8908>). See sources/LICENSES.md.
Source label: `Grimm_2014`.

Columns used: `current_species_name` (taxon), `mass_mean_g` (mean body mass in grams; `mass_min_g` and `mass_max_g` used as fallback for 3 adult rows without a mean), `who` (life stage), `ref_abbr` (per-record reference key).
Filters: Adult mass only (`who` in "adults", "adult females", "adult males"); eggs, hatchlings, clutch, and juvenile rows excluded. European reptile species only (144 species in the database).
Mass type: wet mass, g (as published in the database; `mass_mean_g` column; no conversion applied).
Imputed rows: none; all mass values are field measurements reported in the cited literature.

Per-record reference: `ref_abbr` is retained as `ref_keys` (Phase 3 of issue #1); `primary_references.csv` maps each key to a verified bibcite via Crossref/OpenAlex.
