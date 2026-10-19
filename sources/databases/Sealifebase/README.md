# SeaLifeBase live download

Source: Palomares, M. L. D., & Pauly, D. (Eds.) (2025) SeaLifeBase. World Wide Web electronic publication, <https://www.sealifebase.org>. (Palomares:2025aa)
Data: nothing is stored in this folder but the download script `BodyMass_Sealifebase.r` and `Citation.bib`; `R/library/data_fishbase.r` downloads the species records through `rfishbase` when `DataFishbase = TRUE` in `R/RunMe.r` and saves the git-ignored frame `sources/Rdata/BodyMass_Sealifebase.Rdata`.
Licence: CC BY-NC 4.0 (owner decision 2026-10-06; SeaLifeBase site terms, not on disk; <https://www.sealifebase.org>). Nothing is stored here: the records are downloaded at run time through `rfishbase` (`R/library/data_fishbase.r`) into the git-ignored cache. The species means derived from them carry the label `sealifebase` and are disclosed as a non-commercial carve-out in sources/LICENSES.md.
Source label: `sealifebase`.

Columns used: `rfishbase::popchar(server='sealifebase')` columns `Species`, `Wmax` (adult maximum body mass, grams), `PopCharRefNo` (SeaLifeBase reference number for the Wmax measurement); joined to `rfishbase::species_names(server='sealifebase')` on `SpecCode`.
Filters: rows with non-NA `Wmax` only; `Wmax` is the population-characteristic adult maximum body weight in grams.
Mass type: wet mass, g (as given by SeaLifeBase). No conversion applied.
Imputed rows: none; SeaLifeBase `Wmax` values are field measurements reported in the cited literature.

Per-record reference: `PopCharRefNo` is retained as `ref_keys` (Phase 3 of issue #1); `primary_references.csv` maps each `PopCharRefNo` to a verified bibcite via rfishbase::references(). SeaLifeBase RefType is NA for all entries (not filled in SeaLifeBase's database); container parsing relies on vol:pages pattern matching in the Source field.
