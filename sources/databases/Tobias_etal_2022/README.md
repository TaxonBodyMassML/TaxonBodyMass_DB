# AVONET (Tobias et al. 2022)

Source: Tobias, J. A. et al. (2022) AVONET: morphological, ecological and geographical data for all birds. Ecology Letters 25:581-597. https://doi.org/10.1111/ele.13898
Data: figshare 10.6084/m9.figshare.16586228, Supplementary dataset 1 (`AVONET_Supplementary_dataset_1.xlsx`, CC BY 4.0), downloaded 2026-09-27 from https://ndownloader.figshare.com/files/34480856.

Columns used: sheet `AVONET1_BirdLife` (BirdLife taxonomy, 11,009 species): `Species1`, `Mass` (g, species mean body mass), `Order1`, `Family1`.
Filters: rows with `Mass.Source` in {Inferred, EltonTraits_GenAvg, EltonTraits_Model} or with `Traits.inferred` containing "Body Mass" are excluded (inferred or genus-average masses). 10,184 species remain.
Mass type: wet (live) mass in grams; no conversion. Label `Tobias_2022` (shared with the Google-Sheet override rows).
