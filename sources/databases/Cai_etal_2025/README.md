# Cai et al. (2025) vertebrate life-history traits, Dataset S27

Source: Cai, T., Wen, Z., Jiang, Z., & Zhen, Y. (2025) Distinct latitudinal patterns of molecular rates across vertebrates. PNAS 122:e2423386122. https://doi.org/10.1073/pnas.2423386122
Data: PNAS Supporting Information `Dataset S27.csv` (5,424 species with mitochondrial molecular rates and life-history traits; a title line precedes the header). In the repository since 2026-08-20.
Licence: CC BY-NC-ND 4.0 (owner decision 2026-10-06 after the 2026-10-02 audit of the PNAS licence line, not on disk; https://doi.org/10.1073/pnas.2423386122). `Dataset S27.csv` is tracked as a non-commercial carve-out (verbatim non-commercial redistribution with attribution, as the licence allows), not under the repository licence; the SI appendix PDF is a publisher file kept locally and not committed. See sources/LICENSES.md.

Columns used: `Species`, `BodyMass (g)`, `Ref.BodyMass`, `Class`, `Order`, `Family`.
Filters: rows whose `Ref.BodyMass` is 'Estimated' (no method given), 'Sister species' or 'My' (no source given), or begins 'Average of genus'/'Average of family', are dropped. All other values are compiled from the sources named in `Ref.BodyMass` ('FishBase' 2,445 rows, 'Generation length for mammals' 1,183, 'Ecological drivers of global gradients in avian dispersal inferred from wing morphology' 1,043, AnAge, AmphiBIO, Birds of the World, Body mass of late Quaternary mammals, and others) and are kept, including the 90 amphibian rows marked 'Estimated by total length' (kept as allometry-derived values; owner decision 2026-10-02) and the 217 reptile rows citing 'Body sizes and diversification rates of lizards, snakes, amphisbaenians and the tuatara' (Feldman et al. 2016), which are allometry-derived by inheritance and duplicate the Feldman_etal_2016 source (de-duplication is issue #5).
Mass type: wet mass in grams; no conversion.
Source label: 'Cai_etal_2025'.
Imputed rows: 52 of 5,424 rows dropped (24 Estimated + 16 genus/family averages + 6 Sister species + 6 My); 5,372 kept (logged to audit/imputed_rows.csv).
