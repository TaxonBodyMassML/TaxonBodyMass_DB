# Brown, Hall & Sibly (2018) equal fitness paradigm: energy-content table

Source: Brown, J. H., Hall, C. A. S., & Sibly, R. M. (2018) Equal fitness paradigm explained by a trade-off between generation time and energy production rate. Nature Ecology & Evolution 2:262-268. https://doi.org/10.1038/s41559-017-0430-1
Data: Nature Ecology & Evolution Supplementary Information `41559_2017_430_MOESM2_ESM.csv` (Supplementary Table 2: body mass and ash-free energy content of 74 taxa). In the repository since 2023-01-12 (FracFeed_DB). Supplementary Table 1 (`41559_2017_430_MOESM3_ESM.csv`, natural mortality rate, generation time and body dry mass, 2,041 records) is the Appendix S1 data set of McCoy, M. W., & Gillooly, J. F. (2008) Predicting natural mortality rates of plants and animals. Ecology Letters 11:710-716, reproduced row for row without its reference column; it was read from this folder from 2023-01-12 to 2026-10-02 and is now the source `McCoy_2008` (`../McCoy_2008/`), parsed from the appendix itself (issue #7). The file stays here for reference and for the validation of that parse (`../McCoy_2008/README.md`) but is not read.
Licence: publisher file (README; https://doi.org/10.1038/s41559-017-0430-1). The two Springer Nature supplementary csv files are copyright of the publisher, tracked for reproducibility of the parser and not covered by the repository licence; see sources/LICENSES.md.

Columns used: Table 2 `Taxon2` (scientific name after the colon), `Body mass g`.
Filters: rows with missing or non-positive mass are dropped (none in the current file). Names are taken as written; the pipeline resolves or drops the common-name, genus-level ('Lumbricus sp', 'Cladonia spp.') and misspelt entries.
Mass type: wet mass (`Body mass g`; Mus musculus 40 g, Passer domesticus 22 g), used unconverted.
Source label: 'Brown_etal_2018'.
Imputed rows: none flagged in source.
