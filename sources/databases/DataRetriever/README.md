# rdataretriever sources (six Ecological Archives data papers)

Source: six data papers fetched live through the Python `retriever` package (rdataretriever) by `R/library/data_retrieve.r` when `DataRetrieve = TRUE` in `R/RunMe.r`, and saved together as `sources/Rdata/BodyMass_DataRetrieverAll.Rdata`. No raw files are stored in this folder.
Data: retriever datasets `mammal-life-hist`, `bird-size`, `predator-prey-body-ratio`, `pantheria`, `amniote-life-hist` and `socean-diet-data`, downloaded at each run (see the main README, Prerequisites, for the retriever venv).

| retriever dataset | Source label | Reference | Columns used |
|---|---|---|---|
| mammal-life-hist | Ernest_2003 | Ernest, S. K. M. (2003) Life history characteristics of placental nonvolant mammals. Ecology 84:3402 (Ecological Archives E084-093) | `genus` + `species`, `mass_g`, `family` |
| bird-size | Lislevand_etal_2007 | Lislevand, T., Figuerola, J., & Szekely, T. (2007) Avian body sizes in relation to fecundity, mating system, display behavior, and resource sharing. Ecology 88:1605 (E088-096) | `species_name`, `m_mass` (male body mass, g) |
| predator-prey-body-ratio | Brose_2005 | Brose, U. et al. (2005) Body sizes of consumers and their resources. Ecology 86:2545 (E086-135) | `taxonomy_consumer` + `mean_mass_g_consumer`, `taxonomy_resource` + `mean_mass_g_resource` |
| pantheria | Jones_2009 | Jones, K. E. et al. (2009) PanTHERIA: a species-level database of life history, ecology, and geography of extant and recently extinct mammals. Ecology 90:2648 (E090-184) | `msw05_binomial`, `adultbodymass_g`, `msw05_order`, `msw05_family` |
| amniote-life-hist | Myhrvold_2015 | Myhrvold, N. P. et al. (2015) An amniote life-history database to perform comparative analyses with birds, mammals, and reptiles. Ecology 96:3109 (E096-269) | `genus` + `species`, `trait_value` where `trait == 'adult_body_mass_g'`, `classes`, `ordered`, `family` |
| socean-diet-data | Raymond_2011 | Raymond, B. et al. (2011) A Southern Ocean dietary database. Ecology 92:1188 (E092-097) | table `diet`: `predator_name` + `predator_mass_mean`, `prey_name` + `prey_mass_mean` |

Filters: positive masses only; `FixFormatting`, `FixMisspellings` and `RemoveNonTaxa` are applied in the script and records of the same taxon within a dataset are reduced to their geometric mean before saving. The `bird-size` data also enter through the `Lislevand_etal_2007` folder (same label; mean of male, female and unsexed masses there), so RunMe Pass 1 merges the two under one label.
Mass type: wet mass in grams as reported by each compilation; no conversion.
Source labels: 'Ernest_2003', 'Lislevand_etal_2007', 'Brose_2005', 'Jones_2009', 'Myhrvold_2015', 'Raymond_2011'.
Imputed rows: none flagged in source; none of the six datasets carries a method or imputation flag for body mass. PanTHERIA's `adultbodymass_g` holds reported values only (the extrapolated `adultbodymass_g_ext` column is not read) and Myhrvold's `adult_body_mass_g` is a compiled literature value.
