# Raymond et al. (2011) Southern Ocean dietary database

Source: Raymond, B. et al. (2011) A Southern Ocean dietary database. Ecology 92:1188. Ecological Archives E092-097. DOI 10.1890/10-1907.1.
Data: fetched at run time by rdataretriever (socean-diet-data dataset; nothing stored in this folder; see `sources/databases/DataRetriever/README.md`).
Licence: repository (CC BY-NC 4.0) for the tracked primary_references.csv (our own working table). The underlying data are CC BY 4.0 (Ecological Archives E092-097; https://esapubs.org/archive/ecol/E092/097/) and covered by the DataRetriever live-row entry in source_files.csv; nothing is stored in this folder.

Columns used: table `diet`: `predator_name` + `predator_mass_mean`, `prey_name` + `prey_mass_mean`.
Filters: positive masses only (predator_mass_mean > 0 or prey_mass_mean > 0, non-NA); Latin binomials from predator_name and prey_name.
Mass type: mean mass in grams (predator_mass_mean, prey_mass_mean), as reported.
Source label: 'Raymond_2011'.
Imputed rows: none (mean mass columns used as reported; no imputation flag in source).
