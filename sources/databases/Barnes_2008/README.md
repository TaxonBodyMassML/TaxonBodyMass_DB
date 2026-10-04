# Barnes et al. (2008) predator and prey body sizes in marine food webs

Source: Barnes, C., Bethea, D. M., Brodeur, R. D., Spitz, J., Ridoux, V., Pusineri, C., Chase, B. C., Hunsicker, M. E., Juanes, F., Kellermann, A., et al. (2008) Predator and prey body sizes in marine food webs. Ecology 89:881. Ecological Archives E089-051.
Data: `Predator_and_prey_body_sizes_in_marine_food_webs_vsn4.txt` (data file version 4, 2014-03-05; 34,931 predator-prey records; latin1 tab-delimited) with `metadata.htm` and `default.htm`; downloaded by M. Novak 2026-09-27.

Columns used: `Predator`, `Predator lifestage`, `Individual ID`, `Predator mass` + `Predator mass unit`, `Predator quality of length-mass conversion`; `Prey`, `Prey taxon`, `Prey mass` + `Prey mass unit`, `Prey quality of conversion to mass`.
Filters: predators of adult, female, male or unspecified lifestage, one row per individual (records sharing an Individual ID are one fish with several prey items); prey rows marked as eggs or developmental stages dropped; Latin binomials and 'Genus sp.' names only (common-name and functional-group labels dropped). Conversion quality codes (metadata.htm): 0 = mass measured, 1 = species regression, 2 = genus regression, 3 = family regression, 4 = general shape, 5 = unsatisfactory. Rows with code 4 or 5 are dropped (owner decision 2026-10-02: both codes); codes 1-3 are kept as allometry-derived values.
Mass type: wet mass, g/mg/kg -> g; no conversion factor.
Source label: 'Barnes_2008'.
Imputed rows: 1,596 of 26,857 rows dropped (prey rows of conversion quality 4: 1,594; quality 5: 2; the 17 prey names affected lose all their rows; no predator rows carry codes 4-5 after the lifestage filter); 25,261 kept (logged to audit/imputed_rows.csv).
