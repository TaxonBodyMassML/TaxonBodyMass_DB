# Lukić et al. (2022) planktonic ciliate thermal performance compilation

Source: Lukić, D., Limberger, R., Agatha, S., Montagnes, D. J. S., & Weisse, T. (2022) Thermal performance of planktonic ciliates differs between marine and freshwaters: A case study providing guidance for climate change studies. Limnology and Oceanography Letters 7:520-526. https://doi.org/10.1002/lol2.10264
Data: Dryad https://doi.org/10.5061/dryad.ksn02v76k (CC0): `Dataset_v2.xlsx` (221 experiments, 58 ciliate names), `Units_table.xlsx`, `References.xlsx`, `README_file.txt`; downloaded by M. Novak 2026-10-01.

Columns used: `ciliate.species`, `ciliate.volume (µm3)` (cell volume of the ciliates used in each growth experiment).
Filters: species-level names only (42 species); 'sp.', 'cf.' and 'nomen dubium' entries dropped.
Mass type: cell volume converted to wet mass at unit density (1 µm^3 = 1e-12 g) with CellVolumeToWetMass() in R/library/mass_conversion.r; no literature factor is involved, so no conversion CiteID is appended. Mixotrophic ciliates (e.g. Mesodinium rubrum) are retained, consistent with the pipeline's treatment of ciliates as heterotrophic protists.
