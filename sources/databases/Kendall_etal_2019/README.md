# pollimetry specimen dataset (Kendall et al. 2019)

Source: Kendall, L. K. et al. (2019) Pollinator size and its consequences: Robust estimates of body size in pollinating insects. Ecology and Evolution 9:1702-1714. https://doi.org/10.1002/ece3.4835
Data: `pollimetry_dataset.rdata` from the pollimetry R package (github.com/liamkendall/pollimetry, data/; package archived from CRAN 2025-07), downloaded 2026-09-27. 4,434 measured bee and hoverfly specimens.

Columns used: `Species` (Genus_species), `Spec.wgt` (specimen dry weight, mg), `Family`.
Filters: none beyond positive mass. The package's allometric (ITD-based) predictions are not used.
Mass type: dry mass, mg -> g, then converted to wet mass with the 'insect' factor in R/library/mass_conversion.r (dry = 0.35 x wet; Studier & Sevick 1992).
