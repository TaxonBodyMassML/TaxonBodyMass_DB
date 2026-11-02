# VertNet September 2016 snapshots — primary reference metadata

Source: Bloom D, Wieczorek J, Russell L (2016). VertNet. CyVerse Data Commons. Six occurrence dumps (amphibia, aves, fishes, mammalia, reptilia, vertebrate traits), September 2016. (Bloom:2016aa–af)
Data: nothing is stored in this folder but the six `primary_references_vertnet-*.csv` files; the six dump ZIPs are git-ignored at `sources/VertNet/`; `R/library/data_vertnet.r` reads them at run time when they are present.
Licence: per-record licences (CC0, CC BY 4.0, CC BY-NC 4.0) carried by individual institution occurrence datasets hosted via GBIF; the VertNet dump ZIPs are git-ignored; only the primary_references CSVs (bibliographic metadata derived from the GBIF Registry API, CC0) are stored here. See `sources/LICENSES.md` and `sources/VertNet/` for the per-record licence norms.
Source labels: `vertnet-amphibia-sept2016`, `vertnet-aves-sept2016`, `vertnet-fishes-sept2016`, `vertnet-mammalia-sept2016`, `vertnet-reptilia-sept2016`, `vertnet-traits-sept2016`.

Filters: occurrence records where `dynamicproperties` contains a parseable body mass value in grams (parsed by `R/library/data_vertnet.r`); records flagged as fossils excluded; no records below 1 mg removed (VertNet contains microbe / protist measurements that pass the parser).
Mass type: wet mass, g (as reported in VertNet occurrence records; units parsed from `dynamicproperties`).
Imputed rows: none; VertNet records are individual specimen measurements reported by contributing institutions.

Per-record reference: `gbifdatasetid` (or `institutioncode:collectioncode` as fallback) is retained as `ref_keys` (Phase 3 of issue #1); `primary_references_vertnet-*.csv` maps each GBIF dataset UUID to a bibliographic entry via the GBIF Registry API.
