# Sharkipedia traits export (Mull et al. 2022)

Source: Mull, C. G. et al. (2022) Sharkipedia: a curated open access database of shark and ray life history traits and abundance time-series. Scientific Data 9:559. https://doi.org/10.1038/s41597-022-01655-1
Data: `Sharkipedia-Traits-v1.0-22-01-25.csv` (sharkipedia.org traits export, v1.0, 2025-01-22), downloaded by M. Novak 2026-09-29.

Columns used: `species_name`, `trait_name` == 'Body Mass', `value`, `standard_name` (unit: g or kg), `dubious`.
Filters: 'Offspring mass' and all length/age/reproduction traits excluded; records flagged dubious excluded. All value types (max, mean, min, raw) retained; RunMe Pass 1 averages within species. 20 species.
Mass type: wet mass; kg -> g where needed.
