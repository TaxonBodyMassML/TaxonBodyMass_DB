# Japanese Collembola trait data (Hishi et al. 2019)

Source: Hishi, T., Fujii, S., Saitoh, S., Yoshida, T., & Hasegawa, M. (2019) Taxonomy, distribution and trait data sets of Japanese Collembola. Ecological Research 34:8. https://doi.org/10.1111/1440-1703.12022 (correction: 10.1111/1440-1703.70039)
Data: JaLTER ERDP-2019-03, files `ERDP_2019_03_5_1_D_trait.csv` (traits) and `ERDP_2019_03_2_1_A_sptaxon.csv` (taxonomy), plus EML metadata; downloaded by M. Novak 2026-09-29.

Columns used: trait file `spID1`, `spID2`, `body_mass`; joined on (spID1, spID2) to the taxon file's `Genus`, `Specific_name`, `Family`.
Filters: species-level names only (380 species). body_mass is adult dry body mass in micrograms, calculated in the source from body length with family-level length-weight equations (owner decision 2026-09-29 to include).
Mass type: dry mass, ug -> g, converted with the insect (hexapod) factor of R/library/mass_conversion.r (dry = 0.35 x wet; Studier & Sevick 1992). Source label: 'Hishi_etal_2019; Studier_1992'.
