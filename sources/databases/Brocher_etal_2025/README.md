# Bröcher et al. (2025) Jena Experiment arthropod traits -- NOT INGESTED

Source: Bröcher, M., Meyer, S. T., Leher, A. G., & Ebeling, A. (2025) Ecological traits for 1374 arthropod species collected in a German grassland. Ecology 106:e70077. https://doi.org/10.1002/ecy.70077
Data: JEXIS dataset 703 v10 (https://doi.org/10.25829/Q570-JR82), downloaded by M. Novak 2026-09-28.

Decision (2026-09-29): excluded from the database. The data-structure metadata states that "Body mass was calculated based on body length values using the equations published in Sohlström et al. (2018)", i.e. every mass is an allometric estimate from body length rather than a measurement, which falls under the no-model-estimated-values rule. The body-length column (mm) is measured and could be used if length-derived masses are ever admitted (Tier 3 in audit/candidate_sources_2026-09-27.md). No BodyMass_*.r script exists for this directory, so RunMe.r ignores it.
