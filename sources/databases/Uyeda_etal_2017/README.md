# Uyeda et al. (2017) vertebrate SMR data set

Source: Uyeda, J. C., Pennell, M. W., Miller, E. T., Maia, R., & McClain, C. R. (2017) The evolution of energetic scaling across the vertebrate tree of life. American Naturalist 190:185-199. https://doi.org/10.1086/692326
Data: Dryad https://doi.org/10.5061/dryad.3c6d2 (CC0), `vertData.csv` (857 species: lnBMR, lnMass, endo flag) plus tree files; downloaded by M. Novak 2026-09-28.

Columns used: row names (Genus_species), `lnMass` (natural log of body mass in g), `endo`.
Filters: fishes (ectotherms whose genus occurs in the FishBase cache) are dropped because the fish records are small/juvenile individuals from metabolic studies (median 0.4 log10 below other sources).
Mass type: wet mass; exp(lnMass) g.
