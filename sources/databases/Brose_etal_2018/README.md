# GATEWAy (Brose 2018) global food-web database body masses

Source: Brose, U. (2018) GlobAL daTabasE of traits and food Web Architecture (GATEWAy) version 1.0. iDiv Data Repository dataset 283, version 3 (2018-12-11). https://idata.idiv.de/ddm/Data/ShowData/283
Data: `283_2_FoodWebDataBase_2018_12_10.csv` (222,151 trophic-interaction rows, each with consumer and resource traits), `283_2_FoodWebDatabase_metadata.doc` and the iDiv metadata files; downloaded 2026-08-19.

Columns used: `con.taxonomy`, `con.lifestage`, `con.mass.mean(g)`; `res.taxonomy`, `res.lifestage`, `res.mass.mean(g)`. Consumer and resource rows are stacked as separate records.
Filters: consumer and resource rows whose lifestage is adult, female, male or unspecified (juveniles, larvae, nymphs, nauplii, pupae and eggs dropped); positive masses only. There is one row per trophic link, so a species' mass is repeated across its links and webs; RunMe Pass 1 reduces these to one within-source geometric mean.
Mass type: wet mass in grams (mean mass of the population involved in the interaction, per the metadata); no conversion.
Source label: 'Brose_etal_2018'.
Imputed rows: none flagged in source. `con.size.method` and `res.size.method` describe how body size was obtained ('measurement': field-sampled individuals weighed; 'regression': weight-length regression on measured lengths; 'published account': e.g. field guides; 'expert': expert knowledge), but 183,148 of the 222,151 rows (82%) carry no code and the others are often combined ('measurement published account regression', 11,497 rows), so regression-derived masses cannot be separated record by record; all are kept as reported or allometry-derived values. The 'expert' code does not occur in this version.
