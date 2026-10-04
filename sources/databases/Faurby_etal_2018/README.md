# PHYLACINE 1.2 (Faurby et al. 2018) mammal body masses

Source: Faurby, S., Davis, M., Pedersen, R. Ø., Schowanek, S. D., Antonelli, A., & Svenning, J.-C. (2018) PHYLACINE 1.2: The Phylogenetic Atlas of Mammal Macroecology. Ecology 99:2626. https://doi.org/10.1002/ecy.2443
Data: `Trait_data.csv` of the PHYLACINE 1.2 release (github.com/MegaPast2Future/PHYLACINE_1.2; 5,831 species). In the repository since its import from FracFeed_DB (2026-08-20).

Columns used: `Binomial.1.2`, `Mass.g`, `Mass.Method`, `IUCN.Status.1.2`, `Order.1.2`, `Family.1.2`.
Filters: extinct species (IUCN status EP, EX, EW) are dropped, leaving 5,477 extant species with a mass (the pipeline's extinct-taxon list also draws on this column). Rows with `Mass.Method` 'Imputed' (phylogenetic imputation) or 'As relative of suggested similar size' (value of a related species) are dropped. 'Reported' values (4,585) are kept, as are the 685 'Assumed isometric based on <dimension>' and 3 'Estimated based on equation from <dimension>' values (a measured dimension of the species scaled to mass), the latter two groups as allometry-derived values.
Mass type: wet mass in grams; no conversion.
Source label: 'Faurby_etal_2018'.
Imputed rows: 204 of 5,477 extant rows dropped (186 Imputed + 18 As relative of suggested similar size); 5,273 kept (logged to audit/imputed_rows.csv).
