# FishBase live download

Source: Froese, R., & Pauly, D. (Eds.) (2025) FishBase. World Wide Web electronic publication, <https://www.fishbase.org>. (Froese:2025aa)
Data: nothing is stored in this folder but the download script `BodyMass_Fishbase.r` and `Citation.bib`; `R/library/data_fishbase.r` downloads the species records through `rfishbase` when `DataFishbase = TRUE` in `R/RunMe.r` and saves the git-ignored frame `sources/Rdata/BodyMass_Fishbase.Rdata`.
Licence: CC BY-NC 4.0 (owner decision 2026-10-06; FishBase site terms, not on disk; <https://www.fishbase.org>). Nothing is stored here: the records are downloaded at run time through `rfishbase` (`R/library/data_fishbase.r`) into the git-ignored cache. The species means derived from them carry the label `fishbase` and are disclosed as a non-commercial carve-out in sources/LICENSES.md.
Source label: `fishbase`.

Columns used: `rfishbase::popchar()` columns `Species`, `Wmax` (adult maximum body mass, grams), `PopCharRefNo` (FishBase reference number for the Wmax measurement); joined to `rfishbase::species_names()` on `SpecCode`.
Filters: rows with non-NA `Wmax` only; `Wmax` is the population-characteristic adult maximum body weight in grams.
Mass type: wet mass, g (as given by FishBase). No conversion applied.
Imputed rows: none; FishBase `Wmax` values are field measurements reported in the cited literature.

Per-record reference: `PopCharRefNo` is retained as `ref_keys` (Phase 3 of issue #1); `primary_references.csv` maps each `PopCharRefNo` to a verified bibcite via rfishbase::references(). FishBase RefNo 106043 is absent from rfishbase::references() and is not included in `primary_references.csv`.
