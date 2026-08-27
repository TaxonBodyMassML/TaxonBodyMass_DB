# Taxonomy Enrichment Pipeline

## 1. Overview

The enrichment pipeline resolves Linnaean taxonomy for every taxon in the body-mass dataset. Enrichment is performed entirely within `TaxonBodyMass_DB` by the R function `EnrichTaxonomy()` defined in `R/library/enrich_taxonomy.r`. It is called from `R/RunMe.r` after the per-source data frames are compiled and Google Sheet overrides applied.

Each stage queries a different taxonomic authority and fills only the rank fields still `NA` from previous stages. Rows already fully populated for a given rank are skipped. Stage 0 additionally propagates pre-seeded taxonomy columns (see §3) extracted from source ingestion scripts, so many rows arrive at Stage 1 with `family`, `order`, and/or `class` already set.

**Target fields (all stages):** `kingdom`, `phylum`, `class`, `order`, `family`, `genus`, `species`

**Final output:** `TaxonBodyMass_DB/TaxonBodyMass.csv` — deduplicated to one row per resolved species, with full taxonomy and provenance columns. Autotrophic taxa are removed by `FilterAutotrophs()` (see §5) before deduplication.

**Per-stage pass files:** after each stage completes, the full `compiled` data frame is written to `sources/passes/`:

| File | Written after stage |
| --- | --- |
| `TaxonBodyMass_GBIF_pass.csv` | Stage 1 (GBIF) |
| `TaxonBodyMass_NCBI_pass.csv` | Stage 2 (NCBI) |
| `TaxonBodyMass_WoRMS_pass.csv` | Stage 3 (WoRMS) |
| `TaxonBodyMass_COL_pass.csv` | Stage 4 (COL) |
| `TaxonBodyMass_ITIS_pass.csv` | Stage 5 (ITIS) |
| `TaxonBodyMass_Wikidata_pass.csv` | Stage 6 (Wikidata) |

Each pass file contains all rows and all columns (including pre-seeded taxonomy and the provenance columns added by Stage 0). Rows show the cumulative state after that stage — taxa resolved in earlier stages retain their resolved values; taxa not yet resolved have `NA` for `species`. These files allow resumption after a crash and serve as the authoritative record of per-stage yield.

**QC reports:** `TaxonBodyMass_DB/reports/errors.md` and `reports/warnings.md` are written by `check_enriched()` after deduplication.

**Intra-stage checkpoint:** `TaxonBodyMass_DB/tmp/enrich_checkpoint.csv` is written periodically during long per-species stages (every 100 rows for NCBI, COL, ITIS; every batch for WoRMS, Wikidata). This is a rolling file overwritten each checkpoint; the per-stage pass files above are the durable record.

---

## 2. Pre-Seeded Taxonomy from Source Ingestion Scripts

19 of 38 source ingestion scripts (`sources/databases/BodyMass_*.r`) encounter formal Linnean taxonomy columns in their raw data. These are now extracted before the per-source column subset and merged back after the `ddply` aggregation, so the taxonomy columns are present in each source data frame when `bind_rows()` assembles the compiled data.

The `RunMe.r` Step 3 summarise carries pre-seeded values forward using `first(na.omit(col))` per rank, so a taxon appearing in multiple sources gets a source-provided family/order/class if any source has it.

Stage 0 of `EnrichTaxonomy()` normalises these values to ASCII (via `iconv(to = "ASCII//TRANSLIT")`) rather than overwriting them with `NA`.

| Script | Ranks pre-seeded |
| --- | --- |
| `BodyMass_AnAge.r` | kingdom, phylum, class, order, family |
| `BodyMass_Castro_2025.r` | kingdom, phylum, class, order, family |
| `BodyMass_Pata_2025.r` | kingdom, phylum, class, order, family |
| `BodyMass_Cai_etal_2025.r` | class, order, family |
| `BodyMass_AmphiBIO.r` | order, family |
| `BodyMass_Smith_etal_2003.r` | order, family |
| `BodyMass_Faurby_etal_2018.r` | order, family |
| `BodyMass_Killen_etal_2016.r` | order, family |
| `BodyMass_Reum_2013.r` | order, family |
| `BodyMass_Feldman_etal_2016.r` | order, family |
| `BodyMass_Wilman_etal_2014.r` | order, family |
| `BodyMass_GalanAcedo_etal_2026.r` | family |
| `BodyMass_Fisher_2001.r` | family |
| `BodyMass_Lislevand_etal_2007.r` | family |
| `BodyMass_Pekar_etal_2021.r` | family |
| `BodyMass_Makarieva_etal_2008.r` | order, family (from S3/S7; S1a and S4 skipped — informal group columns) |
| `BodyMass_Meiri_2018.r` | family |
| `BodyMass_Eklof_etal_2017.r` | class |

---

## 3. Enrichment Stages

Stages run sequentially inside `EnrichTaxonomy()`. Each stage receives the same `compiled` data frame, which is updated in-place. Only taxa with `is.na(species)` are queried in Stages 2–6; Stage 1 (GBIF) queries all taxa to initialise all columns including `gbif_family` and `gbif_order`.

### Stage summary

| # | R package / function | API | Batch size | Sleep | Checkpoint |
| --- | --- | --- | --- | --- | --- |
| 0 | — (in-process) | — | — | — | — |
| 1 | `rgbif::name_backbone_checklist()` | GBIF name backbone (batch POST) | 1,000 | none | — |
| 2 | `taxize::classification(db="ncbi")` | NCBI Entrez (esearch + efetch) | 1 (sequential) | 0.34 s | every 100 rows |
| 3 | `worrms::wm_records_names()` | WoRMS AphiaRecordsByMatchNames | 50 | 0.5 s | every 500 rows |
| 4 | `taxize::classification(db="col")` | COL ChecklistBank | 1 (sequential) | 0.5 s | every 100 rows |
| 5 | `ritis::search_scientific()` + `ritis::hierarchy_full()` | ITIS JSON service | 1 (sequential) | 0.5 s | every 100 rows |
| 6 | `httr2::request()` (SPARQL) | Wikidata query service | 10 | 1.0 s | every 100 rows |

All stages handle transient errors with `tryCatch`; failed taxa fall through to the next stage. Stage 1 retries failed chunks up to 3 times with delays of 5 s, 15 s, 45 s.

---

### Stage 0 — Preserve input name; normalise pre-seeded taxonomy

Runs on the full `compiled` data frame before any API call.

- Saves `taxon_provided`: the taxon string as it appeared in the source data, with underscores converted to spaces. This is the name submitted to each API.
- Initialises `species_changed = FALSE` and `taxonomy_source = NA`.
- For each of the seven target rank columns: if the column is absent it is initialised to `NA_character_`; if it is present (pre-seeded from a source script) it is ASCII-normalised via `iconv(to = "ASCII//TRANSLIT")`.
- Initialises `gbif_confidence`, `gbif_status`, `gbif_family`, `gbif_order` as NA columns.

---

### Stage 1 — GBIF (`rgbif::name_backbone_checklist()`)

**API:** GBIF name backbone, `name_backbone_checklist()` endpoint (batch POST, up to 1,000 names per request)

**Fields added:** `kingdom`, `phylum`, `class`, `order`, `family`, `genus`, `species`, `gbif_confidence`, `gbif_status`

**Additional columns captured before the NA-fill loop:**
- `gbif_family` — GBIF-returned family for every row, preserved regardless of whether `family` was already populated from a source script
- `gbif_order` — same for order

These two columns are used by `check_enriched()` Check 10 to flag source-vs-GBIF family/order mismatches as potential misresolutions.

**Confidence threshold:** results with `confidence < 75` have their `species` field zeroed out before the NA-fill loop; they fall through to Stage 2. Results with `75 ≤ confidence < 90` are filled but flagged in `reports/warnings.md`.

**Chunking and retry:** all taxa are sent in chunks of 1,000. Each chunk is retried up to 3 times (delays: 5 s, 15 s, 45 s) before emitting a warning and allowing affected taxa to fall through.

---

### Stage 2 — NCBI (`taxize::classification(db="ncbi")`)

**API:** NCBI Taxonomy via Entrez esearch + efetch

**Fields added:** any of the seven standard ranks still `NA` after GBIF.

Queries taxa one at a time. Parses the ranked lineage returned by `classification()` to extract rank/name pairs matching the seven target fields.

Normalises kingdom: NCBI returns `"Metazoa"` for animals; the stage remaps this to `"Animalia"` after the loop.

Rate limit: `Sys.sleep(0.34)` after each lookup (~3 req/s without an API key; set `ENTREZ_KEY` in `.Renviron` for 10 req/s).

---

### Stage 3 — WoRMS (`worrms::wm_records_names()`)

**API:** WoRMS AphiaRecordsByMatchNames (batches of 50, `marine_only = FALSE`)

**Fields added:** `kingdom`, `phylum`, `class`, `order`, `family`, `genus`, `species`

Accepted match types: `exact`, `phonetic`, `near_1`. Records with other match types are skipped. Within each batch result, records with `status == "accepted"` are preferred; the first record is used as a fallback. Species name is taken from `scientificname` when the WoRMS record rank is `"species"`. Particularly effective for marine invertebrates, fish, and other aquatic taxa.

---

### Stage 4 — COL (`taxize::classification(db="col")`)

**API:** COL ChecklistBank (dataset 3 — the full Catalogue of Life checklist)

**Fields added:** `kingdom`, `phylum`, `class`, `order`, `family`, `genus`, `species`

Queries taxa one at a time. When a classification is returned, the queried name is assigned directly as `species`. Particularly effective for Squamata because COL sources directly from the Reptile Database.

---

### Stage 5 — ITIS (`ritis::search_scientific()` + `ritis::hierarchy_full()`)

**API:** ITIS JSON web service (`searchByScientificName`, `getFullHierarchyFromTSN`)

**Fields added:** any of the seven standard ranks still `NA` after COL.

Retrieves the first TSN from `search_scientific()`, then walks the full hierarchy from `hierarchy_full()`. Rank names from ITIS (e.g. `"Kingdom"`, `"Family"`) are matched case-insensitively against the target fields. Particularly effective for vertebrates.

---

### Stage 6 — Wikidata (`httr2` SPARQL)

**API:** `https://query.wikidata.org/sparql` (SPARQL 1.1)

**Fields added:** any of the seven standard ranks still `NA` after ITIS.

Sends batches of 10 names per SPARQL query using a `VALUES` clause. The query traverses `wdt:P171*` (parent taxon, transitive) and retrieves `wdt:P225` (taxon name) and `wdt:P105` (taxon rank) for each ancestor, filtering for English rank labels matching the seven target fields. First match per rank wins.

Rate limit: `Sys.sleep(1.0)` between batches per Wikidata's fair-use policy. Requests include a `User-Agent: TaxonBodyMassDB/1.0` header. Retried up to 3 times via `httr2::req_retry()` with a 15 s backoff.

---

## 4. Output Columns Added by EnrichTaxonomy()

| Column | Type | Description |
| --- | --- | --- |
| `taxon_provided` | character | Input taxon string (underscores → spaces) submitted to APIs |
| `species_changed` | logical | `TRUE` if GBIF/fallback resolved to a different accepted species |
| `taxonomy_source` | character | First stage that resolved `species` (GBIF, NCBI, WoRMS, COL, ITIS, Wikidata) |
| `gbif_confidence` | numeric | GBIF match confidence score (0–100; `NA` if not resolved by GBIF) |
| `gbif_status` | character | GBIF taxonomic status (ACCEPTED, SYNONYM, DOUBTFUL, `NA`) |
| `gbif_family` | character | Family returned by GBIF (regardless of pre-seeded value) |
| `gbif_order` | character | Order returned by GBIF (regardless of pre-seeded value) |

---

## 5. Autotroph Filter (`FilterAutotrophs()`)

**Function:** `R/library/filter_autotrophs.r`  
**Called from:** `R/RunMe.r` after `EnrichTaxonomy()`, before deduplication.

Removes taxa whose enriched `kingdom` is `"Plantae"` or `"Fungi"`, and taxa whose enriched `phylum` belongs to a list of predominantly photosynthetic lineages that fall outside those kingdoms (Ochrophyta, Haptophyta, Cryptophyta, Dinoflagellata, Chlorophyta, Rhodophyta, Charophyta, Glaucophyta). Rows with `NA` kingdom or phylum are retained.

This is more conservative than the prior `filter_kingdoms.py`, which removed `Chromista` and `Viridiplantae` as entire kingdoms. The phylum-level list targets only the photosynthetic lineages within those kingdoms, preserving heterotrophic members (e.g. fungal-like oomycetes in Chromista).

---

## 6. QC and Deduplication (`check_enriched()`, `RunMe.r` Step 5)

After enrichment and autotroph filtering, `RunMe.r` deduplicates the data to one row per resolved `species` (geometric mean of `mass_g` in log space across all source records resolving to the same accepted species). The resulting `enriched` data frame is passed to `check_enriched()`.

`check_enriched()` writes `reports/errors.md` (blocking issues) and `reports/warnings.md` (advisories) covering:

1. Non-positive or non-finite `mass_g`
2. Missing taxonomy at each rank after all 6 stages
3. Duplicate `genus + species` after deduplication (should be empty)
4. Species names not matching `^[A-Z][a-z]+ [a-z]+$`
5. Genus column not matching species prefix
6. Low GBIF confidence (75–89)
7. GBIF status `DOUBTFUL`
8. Species name changed during enrichment (synonym collapses, misresolutions)
9. High mass disagreement: `log10(max/min)` > 2.0 across source records collapsed to the same species
10. Source-provided family or order differs from GBIF-returned family or order (potential misresolution flag)

---
