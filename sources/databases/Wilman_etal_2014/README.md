# EltonTraits 1.0 (Wilman et al. 2014) bird body masses

Source: Wilman, H., Belmaker, J., Simpson, J., de la Rosa, C., Rivadeneira, M. M., & Jetz, W. (2014) EltonTraits 1.0: Species-level foraging attributes of the world's birds and mammals. Ecology 95:2027. https://doi.org/10.1890/13-1917.1
Data: Ecological Archives E095-178, `BirdFuncDat.txt` (9,993 bird species) with `BirdFuncDatSources.txt` and `metadata.htm`; `MamFuncDat.txt` and `MamFuncDatSources.txt` (mammals) are present but not parsed. In the repository since its import from FracFeed_DB (2026-08-20).

Columns used: `Scientific`, `BodyMass-Value` (g; for source Dunning08 the geometric mean of the sex-specific averages), `BodyMass-Source`, `BodyMass-SpecLevel`, `BodyMass-Comment`, `IOCOrder`, `BLFamilyLatin`.
Filters: rows with `BodyMass-Source` 'GenAvg' (genus or family typical value, `BodyMass-SpecLevel` 0) and rows whose `BodyMass-Comment` begins 'Copied' (value copied from another species) are dropped. The 484 'PrimScale' rows (a measured length of the species through a family-level mass-length relationship) are kept as allometry-derived values. The 273 records whose `Record-Comment` is 'DataFromSplit' (record created by a taxonomic split; 262 of them carry species-level masses) are kept; their treatment is deferred to issue #5 together with the COMBINE split-inherited values.
Mass type: wet mass in grams; no conversion.
Source label: 'Wilman_etal_2014'.
Imputed rows: 877 of 9,993 rows dropped (870 GenAvg genus/family averages + 7 copied from another species); 9,116 kept (logged to audit/imputed_rows.csv).
