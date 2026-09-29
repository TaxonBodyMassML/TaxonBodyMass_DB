# Hébert et al. (2016) crustacean zooplankton trait compilation

Source: Hébert, M.-P., Beisner, B. E., & Maranger, R. (2016) A compilation of quantitative functional traits for marine and freshwater crustacean zooplankton. Ecology 97:1081. https://doi.org/10.1890/15-1275.1
Data: Wiley Supporting Information (former Ecological Archives data paper): `zooplankton_traits.csv`, `references.csv`, `ecy1337-sup-0001-metadatas1.docx`; downloaded by M. Novak 2026-09-28.

Columns used: `Genus` + `Species`, `Dry.mass` (individual mean body dry mass, mg; semicolon-delimited file with decimal commas), `Group`, `Ref.dm`.
Filters: rows whose dry mass reference includes codes 18 (Culver et al. 1985) or 20 (McCauley 1984) are excluded because those values come from length-weight regressions (the freshwater sub-data set); genus-level rows dropped. Adult (mostly female) individuals by design of the compilation.
Mass type: dry mass, mg -> g, converted with the 'crustacean_zooplankton' factor in R/library/mass_conversion.r (dry = 0.20 x wet; Kiorboe 2013).
Source label: 'Hebert_etal_2016; Kiorboe_2013' (conversion reference appended).
