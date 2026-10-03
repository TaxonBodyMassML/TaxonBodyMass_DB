# Hechinger et al. (2011) estuary food webs with body sizes

Source: Hechinger, R. F. et al. (2011) Food webs including parasites, biomass, body sizes, and life stages for three California/Baja California estuaries. Ecology 92:791. https://doi.org/10.1890/10-1383.1
Data: Ecological Archives E092-066, `Metaweb_Nodes.txt` (UTF-16 tab-delimited) and `metadata.htm`, downloaded 2026-09-27 from https://esapubs.org/archive/ecol/E092/066/. Data are for non-commercial scientific use.

Columns used: `Genus` + `SpecificEpithet`, `BodySize(g)` (individual fresh mass including hard parts; metadata II.C.2), `BodySizeEstimation`, `Resolution`, `Stage`, Kingdom..Family.
Filters: species-resolution nodes; adult or unstaged rows; BodySizeEstimation 'species' or 'population' only (nodes whose size was approximated from another species are excluded). Values from the three estuaries are averaged by RunMe Pass 1.
Mass type: wet mass in grams; no conversion.
Imputed rows: the 142 nodes whose `BodySizeEstimation` is 'approximation' (size taken from another species) are excluded by the filter above; the source carries no other flag.
