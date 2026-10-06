# FishBase live download

Source: Froese, R., & Pauly, D. (Eds.) (2025) FishBase. World Wide Web electronic publication, www.fishbase.org.
Data: nothing is stored in this folder but the download script `BodyMass_Fishbase.r` and `Citation.bib`; `R/library/data_fishbase.r` downloads the species records through `rfishbase` when `DataFishbase = TRUE` in `R/RunMe.r` and saves the git-ignored frame `sources/Rdata/BodyMass_Fishbase.Rdata`.
Licence: CC BY-NC 4.0 (owner decision 2026-10-06; FishBase site terms, not on disk; https://www.fishbase.org). Nothing is stored here: the records are downloaded at run time through `rfishbase` (`R/library/data_fishbase.r`) into the git-ignored cache. The species means derived from them carry the label `fishbase` and are disclosed as a non-commercial carve-out in sources/LICENSES.md.
Source label: `fishbase`.

Columns used, Filters, Mass type and Imputed rows: this minimal README was written for the licence audit (issue #6, 2026-10-06); the full README in the convention of the other source folders is pending. The parse script `BodyMass_Fishbase.r` documents the columns read and the filters applied.
