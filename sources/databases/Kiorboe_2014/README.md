# Kiorboe & Hirst (2014) marine pelagic body masses (carbon)

Source: Kiorboe, T. & Hirst, A. G. (2014) Shifts in mass scaling of respiration, feeding, and growth rates across life-form transitions in marine pelagic organisms. American Naturalist 183:E118-E130. https://doi.org/10.1086/675241
Data: PANGAEA 10.1594/PANGAEA.819850 (respiration), 819855 (growth), 819856 (feeding), CC BY 3.0, downloaded 2026-09-27 as tab-delimited text (`?format=textfile`).

Columns used: `Taxa`, `Biom C/ind [ug/#]` (carbon mass per individual).
Filters: fish records (larval stages, micrograms of carbon) are excluded; copepod nauplius/copepodite stage rows are dropped; names flagged '?' or identified only to genus, larval-stage labels (Brachyuran megalopa/zoea, Macruran mysis) and abbreviated names are dropped. 'Sytrombidium conicum' is corrected to Strombidium conicum.
Groups: `taxon_groups.csv` gives the WoRMS classification (AphiaIDs from the files, retrieved 2026-09-27 via the WoRMS REST API) and the mass_group used for conversion: Cnidaria/Ctenophora/Thaliacea/Appendicularia -> gelatinous_zooplankton; Arthropoda -> crustacean_zooplankton; Chordata -> fish; protist phyla and the freshwater protists lacking AphiaIDs -> protist; Chaetognatha -> chaetognath (Brey et al. 2010 data-bank median).
Mass type: carbon mass, ug -> g, converted to wet mass with group-specific carbon:wet ratios in R/library/mass_conversion.r (Kiorboe 2013; Lucas et al. 2011; Menden-Deuer & Lessard 2000). Autotrophic taxa present in the files are removed downstream by filter_autotrophs.r.
Source labels: 'Kiorboe_2014; Kiorboe_2013' (crustaceans), 'Kiorboe_2014; Kiorboe_2013; Lucas_2011' (gelatinous), 'Kiorboe_2014; MendenDeuer_2000' (protists), 'Kiorboe_2014; Brey_2010' (chaetognaths).
