# Bröcher et al. (2025) Jena Experiment arthropod traits

Source: Bröcher, M., Meyer, S. T., Leher, A. G., & Ebeling, A. (2025) Ecological traits for 1374 arthropod species collected in a German grassland. Ecology 106:e70077. https://doi.org/10.1002/ecy.70077
Data: JEXIS dataset 703 v10 (https://doi.org/10.25829/Q570-JR82), downloaded by M. Novak 2026-09-28.
Licence: unknown; owner to check https://doi.org/10.25829/Q570-JR82 (the local json/xml metadata carry no access-policy field, the JEXIS landing page shows no licence and offers login; `terms.txt` is the BEXIS2 sample Terms and Conditions shipped with the download, not the dataset terms; ask M. Broecher or log in to JEXIS). All files are tracked; see sources/LICENSES.md.

Columns used: `Taxa`, `Body mass` (mg), `Class`, `Order`, `Family` from `JExIS_703_v10_data.csv`.
Filters: species-level names only (1,360 species).
Mass type: live body mass in mg -> g. The data-structure metadata states that body mass was calculated from body length with the equations of Sohlström et al. (2018); owner decision 2026-09-29 to include these length-derived masses.
Imputed rows: none flagged as imputed; all masses are length-derived species values (allometry-derived, see Mass type) and are kept.
