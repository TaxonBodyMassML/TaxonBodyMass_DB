# Jones_2009 (PanTHERIA): reference list and primary references

The data of this label are fetched live by `R/library/data_retrieve.r` (retriever dataset `pantheria`, Ecological Archives E090-184; `sources/Rdata/BodyMass_DataRetrieverAll.Rdata`) and are described, with the filters, the `ref_keys` rule and the Provenance paragraph of the label, in `sources/databases/DataRetriever/README.md`. This folder holds only the files of the primary-source attribution of issue #1 (Stage 2, round of 2026-10-06).

Filters: see `sources/databases/DataRetriever/README.md` (positive `adultbodymass_g` only; nothing is filtered here).
Mass type: see the DataRetriever README (wet mass in grams as compiled by PanTHERIA).
Imputed rows: none (the extrapolated `adultbodymass_g_ext` column is not read; see the DataRetriever README).
Licence: repository (CC BY-NC 4.0) (the files here are our own working tables: the reference list transcribed from the archive's `metadata.htm` and the tool's `primary_references.csv`; no raw file is stored. The data paper's terms -- `metadata.htm`: "Copyright restrictions: None. Proprietary restrictions: None. Costs: None, the authors believe that scientific data collated using public funds should be free for scientific use."; https://doi.org/10.1890/08-1494.1 -- apply to the data fetched at run time, see the DataRetriever README).

| file | contents |
| --- | --- |
| `build_references.py` | writes `references.csv` from the archive's `metadata.htm` in the retriever cache (`~/.retriever/raw_data/pantheria/5604752`, a zip): the numbered list "Reference list for the data set" (Class V, Section B), one entry per `<br />`-separated line, tags stripped, entities unescaped, whitespace collapsed; stops on a numbering gap |
| `references.csv` | `key` (the entry number 1-3143), `citation` (the entry verbatim; the archive page declares ISO-8859-1 and a few entries carry its own mangled diacritics, 'Lùpez-Forment', kept as they are) |
| `primary_references.csv` | the tool's working file (`run_citations.r --source Jones_2009 --init`; `reflist_specs$Jones_2009`, frame `DataRetrieverAll`): 3,066 keys cited by the 3,542 records with a mass; `role` set by the owner's rule (63 `compilation`, see the DataRetriever README) |

**Lislevand caveat**: the `References` column of the data file cites the numbers for the whole species row -- every trait of PanTHERIA (longevity, density, diet, range, metabolic rate, ...), not body mass alone -- so a body-mass record carries the references of its other traits as well and a reference linked to a record need not be the source of its mass (as for `Lislevand_etal_2007`, whose numbers cover egg mass and clutch size too); 6.6 references per record, up to 61. Verification runs in slices (`--verify --min-records 2` first, the singletons later; owner's rule 2026-10-06); 18 cells glue two four-digit numbers (`30483049`), split by `data_retrieve.r`. Citation of the compilation: `Jones:2009aa` in `Bib/TaxonBodyMass_Citations.bib` (doi 10.1890/08-1494.1).
