# FoRAGE (DeLong & Uiterwaal 2018) functional-response database body masses

Source: DeLong, J. P., & Uiterwaal, S. F. (2018) The FoRAGE (Functional Responses from Around the Globe in all Ecosystems) database: a compilation of functional responses for consumers and parasitoids. Knowledge Network for Biocomplexity. https://doi.org/10.5063/F17H1GTQ
Data: `FoRAGE_db_12_19_18_data_set.csv` (data set version 2018-12-19; 2,682 functional-response data sets, one row each; latin1-encoded, read with `fileEncoding = 'latin1'`). In the repository since its import from FracFeed_DB (2026-08-20).

Columns used: `Predator scientific name`, `Predator type`, `Predator mass (mg)`, `Predator mass source code`; `Prey scientific name`, `Prey type`, `Prey mass (mg)`, `Prey mass source code`. Predator and prey rows are stacked as separate records.
Filters: predator and prey rows whose type is adult, female, male or unspecified (juvenile and larval stages dropped). Rows whose mass source code begins 'alternate'/'alternative' (mass, length or volume taken from another species, genus, family, order or a generic zooplankter), '%' (a fraction of adult or predator mass) or 'average genus'/'average order' (taxon averages) are dropped. Codes beginning 'original' (the study's own mass, or its own measured length, volume or carbon content through a regression) and 'average species' are kept; the length-derived values are allometry-derived.
Mass type: wet mass, mg -> g; no conversion factor.
Source label: 'DeLong_etal_2018'.
Imputed rows: 1,097 of 1,973 rows dropped (1,073 alternate-taxon masses, lengths or volumes, 21 genus/order averages, 3 % adult mass); 876 kept (logged to reports/imputed_rows.csv). Until 2026-10-01 the pipeline used a stale cached frame of 757 rows because the parser failed silently in a UTF-8 locale (issue #8).
