# Weisse (2024) planktonic ciliate mortality compilation

Source: Weisse, T. (2024) Physiological mortality of planktonic ciliates: Estimates, causes, and consequences. Limnology and Oceanography 69:524-532. https://doi.org/10.1002/lno.12503
Data: Dryad https://doi.org/10.5061/dryad.cnp5hqc99 (CC0): `dataset_v2.xlsx` (102 experiments, 65 name strings), `Units_table.xlsx`, `References.xlsx`, and the Dryad README (`README_dryad.md`); downloaded by M. Novak 2026-10-01.
Licence: CC0 1.0 (README, Citation.bib: the Dryad record; https://doi.org/10.5061/dryad.cnp5hqc99). The three xlsx files and the Dryad README are tracked.

Columns used: `species`, `volume` (cell volume, µm³), `order`.
Filters: abbreviated genus names expanded (C. = Colpidium, F. = Favella, H. = Histiobalantium, P. = Parallelostrombidium, R. = Rimostrombidium, S. = Strombidinopsis, Str. = Strombidium, T. = Tintinnopsis, U. = Urotricha, V. = Vorticella; verified against the order column); 'sp.' and 'cf.' entries dropped; 47 species.
Mass type: cell volume converted to wet mass at unit density (1 µm³ = 1e-12 g) with CellVolumeToWetMass(); no literature factor involved, so no conversion CiteID is appended.
Imputed rows: none flagged in source (cell volumes measured in each experiment).
