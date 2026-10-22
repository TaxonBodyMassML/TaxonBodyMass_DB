# Phase 3 Implementation Plan: VertNet Publisher Attribution
## Branch: `issue-1-phase3-vertnet`

*Written 2026-10-22. Implements Phase 3 of issue #1.*

---

## Scope and current state

Phase 3 adds per-record publisher attribution to the six VertNet source labels. FishBase (2,909 provenance rows, 674 cited refs) and SeaLifeBase (372 rows, 106 cited refs) are **already complete** — their `primary_references.csv` files are fully verified and all citations are present in `BM_primary_citations` and `TaxonBodyMass_PrimaryCitations.bib`. No action is needed for those two sources.

| Source label | Records in Rdata | prov type (current) | `ref_keys` in Rdata | ZIP cached |
|---|---:|---|---|---|
| vertnet-mammalia-sept2016 | 9,783 | `database_record` | ❌ | ✓ `VertNet_Mammalia_Sept2016.zip` |
| vertnet-amphibia-sept2016 | 1,091 | `database_record` | ❌ | ✓ `VertNet_Amphibia_Sept2016.zip` |
| vertnet-reptilia-sept2016 | 2,480 | `database_record` | ❌ | ✓ `VertNet_Reptilia_Sept2016.zip` |
| vertnet-traits-sept2016 | 89,245 | `database_record` | ❌ | ✓ `VertNet_Traits_Sept2016.zip` |
| vertnet-aves-sept2016 | 80,624 | `database_record` | ❌ | ❌ **needs download** |
| vertnet-fishes-sept2016 | 652 | `database_record` | ❌ | ❌ **needs download** |

`BodyMass_VertNetAll.Rdata` currently has columns `taxon, mass_g, class, order, family, n, source_mass` — no `ref_keys` or `gbifdatasetid`. All 12,744 provenance rows have `primary_cite_id = NA`. `data_vertnet.r` already contains the `ref_keys = gbifdatasetid` assignment (lines 150–155) but the cached Rdata predates it.

### What a completed Phase 3 delivers

Every VertNet record will carry a `ref_keys` value (GBIF dataset UUID, or `institutioncode:collectioncode` fallback) that `BuildProvenance()` maps to a publisher dataset citation. The provenance table will gain up to ~12,744 `database_record` rows with `primary_cite_id` set to the institution/collection identifier, and corresponding entries in `TaxonBodyMass_PrimaryCitations.bib` and the `BM_primary_citations` Sheet tab.

---

## Step A — Owner action: download missing ZIPs

Two VertNet snapshots are not cached locally. Before this branch can be fully executed, download:

```
VertNet_Aves_Sept2016.zip     → sources/VertNet/VertNet_Aves_Sept2016.zip
VertNet_Fishes_Sept2016.zip   → sources/VertNet/VertNet_Fishes_Sept2016.zip
```

Source: the CyVerse Data Store at `https://data.cyverse.org/dav-anon/iplant/projects/VertNet/`. The Sept 2016 bird snapshot is `vertnet_latest_birds.csv` (inside the ZIP); fishes is `vertnet_latest_fishes.csv`. The Rdata records counts for these are 80,624 (aves) and 652 (fishes).

**Why this can't be automated**: the download is ~3 GB and requires CyVerse authentication. The other four ZIPs are already in `sources/VertNet/`.

**CRC warning**: Python's `zipfile` module reports CRC-32 errors on the cached ZIPs during reads. Verify with R's `unzip` (which is more permissive) before assuming the files are corrupt. If corrupt, the owner will need to re-download those ZIPs too.

---

## Step B — Patch `BodyMass_VertNetAll.Rdata` with `ref_keys`

Write a one-time R script `tmp/patch_vertnet_rdata.r` that:

1. Loads each VertNet ZIP CSV using `data.table::fread` (same approach as `data_vertnet.r`)
2. Reads the `gbifdatasetid`, `institutioncode`, `collectioncode`, and the species identifier for each record
3. For each source label, constructs `ref_keys` using the same logic as `data_vertnet.r:150–155`:
   - `ref_keys = gbifdatasetid` if non-NA/non-empty
   - Fallback: `ref_keys = paste0(institutioncode, ':', collectioncode)`
4. Aggregates to species × source level (one semicolon-joined `ref_keys` per species × source, matching the existing Rdata rows)
5. Loads `BodyMass_VertNetAll.Rdata` and left-joins `ref_keys` onto the existing frame by `taxon + source_mass`
6. Saves the updated frame back to `sources/Rdata/BodyMass_VertNetAll.Rdata`

The script must NOT be committed (it reads/writes git-ignored files). Keep it in `tmp/` and delete after use.

**After patching**, verify:
```r
load('sources/Rdata/BodyMass_VertNetAll.Rdata')
stopifnot('ref_keys' %in% names(VN))
cat('ref_keys non-NA:', sum(!is.na(VN$ref_keys)), 'of', nrow(VN), '\n')
```

---

## Step C — Enumerate distinct GBIF dataset IDs

For each source label, collect the distinct `gbifdatasetid` values (and their record counts) from the patched Rdata or from the ZIPs directly. This gives the set of `native_key` values for each source's `primary_references.csv`.

Write `tmp/enumerate_gbif_ids.r` to produce a CSV: `source_label, gbifdatasetid, n_records, institutioncode, collectioncode, datasetname`.

---

## Step D — Build `primary_references.csv` for each VertNet source

Each source gets `sources/databases/VertNet/primary_references_<label>.csv` (analogous to `DataRetriever/primary_references_Brose_2005.csv`, which demonstrates the multi-label-per-folder pattern).

### Column values

| column | value |
|---|---|
| `source_label` | e.g. `vertnet-mammalia-sept2016` |
| `native_key` | `gbifdatasetid` UUID (or `institutioncode:collectioncode` if no UUID) |
| `raw_citation` | GBIF dataset citation text from the Registry API |
| `raw_doi` | dataset DOI from GBIF Registry (e.g. `10.15468/ivcidi`) |
| `role` | `database` |
| `n_records` | record count from the Rdata |
| `match_status` | `approved` (owner-waived, since provenance is from the GBIF Registry itself — no Crossref verification needed for institutional dataset DOIs) |
| `decided_by` | `gbif-registry` |
| `doi` | same as `raw_doi` |
| `bibcite` | minted by the bib step |
| `cite_id` | minted by the bib step |

### GBIF Registry lookup script

Write `tmp/build_vertnet_primary_refs.r` (or `.py`) to:

1. Read the `source_label, gbifdatasetid, n_records` enumeration from Step C
2. For each unique `gbifdatasetid`, call `https://api.gbif.org/v1/dataset/{uuid}`:
   - `citation.text` → `raw_citation`
   - `doi` → `raw_doi`
   - Polite rate-limiting: 100 ms between requests
3. Write one `primary_references_<label>.csv` per source label

Sample API response for UUID `f86f5466-8f18-4b83-84d4-d0edab4c0e90`:
```
title:    MVZ Mammal Observations (Arctos)
doi:      10.15468/ivcidi
citation: Conroy C (2026). MVZ Mammal Observations (Arctos). Version 36.110.
          Museum of Vertebrate Zoology. Occurrence dataset
          https://doi.org/10.15468/ivcidi accessed via GBIF.org on 2026-09-xx.
```

Datasets with no DOI get `raw_doi = ''` and `match_status = nodoi_approved`. Datasets that return 404 from the Registry (deleted/deprecated) get `match_status = rejected`.

---

## Step E — Add `reflist_specs` entries to `citations_config.r`

Each VertNet source needs a `reflist_specs` entry so `run_citations.r --source vertnet-mammalia-sept2016 --bib --sheet` works.

VertNet sources share a folder (`sources/databases/VertNet/`) and use the `primary_references_<label>.csv` naming pattern. Example entry (modelled on the Brose_2005 multi-file pattern at `citations_config.r:485`):

```r
`vertnet-mammalia-sept2016` = list(
  format   = 'dataset',          # new format: no native bibliography to parse
  folder   = 'VertNet',
  prim_file = 'primary_references_vertnet-mammalia-sept2016.csv',
  compiler  = 'VertNet'
),
```

The `format = 'dataset'` value signals that there is no `file` (bibliography) to parse — the `primary_references.csv` is the sole input. The `--init` step is skipped; `--bib` and `--sheet` run directly from the existing CSV.

**Implementation note**: `PrimaryReferencesPathForLabel()` in `citations_config.r` already resolves paths from `folder` and `prim_file`. No new path-resolution code is needed — only the new `reflist_specs` entries and a guard in `--init` / `--verify` to skip sources with `format = 'dataset'`.

All six entries follow the same pattern, one per label.

---

## Step F — Run `--bib --sheet` for each source

For each of the six VertNet labels, on this branch in a worktree:

```bash
cd R
Rscript library/citations/run_citations.r --source vertnet-mammalia-sept2016 --bib --sheet --no-dry-run
Rscript library/citations/run_citations.r --source vertnet-amphibia-sept2016 --bib --sheet --no-dry-run
Rscript library/citations/run_citations.r --source vertnet-reptilia-sept2016 --bib --sheet --no-dry-run
Rscript library/citations/run_citations.r --source vertnet-traits-sept2016 --bib --sheet --no-dry-run
Rscript library/citations/run_citations.r --source vertnet-aves-sept2016 --bib --sheet --no-dry-run
Rscript library/citations/run_citations.r --source vertnet-fishes-sept2016 --bib --sheet --no-dry-run
```

This appends entries to `Bib/TaxonBodyMass_PrimaryCitations.bib` and the `BM_primary_citations` Sheet tab, and updates `Bib/TaxonBodyMass_CitationCiteIDs.csv`.

**Prerequisite**: Steps D and E must be complete for the target source. Aves and fishes require Step A (owner ZIP download) first.

---

## Step G — RunMe.r rebuild

After all six sources have `--bib --sheet` applied:

1. In a dedicated worktree (copy live Rdata files as usual):
   - Set `DataSheets = TRUE` for one run to refresh tracked Sheet copies
   - Ensure the patched `BodyMass_VertNetAll.Rdata` (with `ref_keys`) is in the worktree's `sources/Rdata/`
2. Run `Rscript R/RunMe.r` (with `DataSheets = TRUE` once, then `FALSE`)
3. Verify in the rebuilt `TaxonBodyMass_Provenance.csv.gz`:
   - VertNet `primary_cite_id` values are non-NA
   - `provenance_type` remains `database_record`
4. Update `audit/provenance_rounds.md` with a dated entry for this round
5. Regenerate `sources/source_files.csv` via `Rscript R/library/licence_manifest.r`
6. Update the Provenance paragraph in each affected source README

---

## Step H — Tests

Run the standard citation test suite:

```bash
cd R
Rscript -e "testthat::test_file('library/tests/test_citations_vertnet.R')"
Rscript -e "testthat::test_file('library/tests/test_licence_docs.R')"
Rscript -e "testthat::test_file('library/tests/test_recompile_guard.R')"
```

If `test_citations_vertnet.R` does not yet exist, write it to cover:
- `primary_references_vertnet-mammalia-sept2016.csv` has no `pending` rows
- `BM_primary_citations` snapshot contains the expected VertNet CiteIDs
- The provenance table has no `unknown` rows for VertNet sources

---

## Step I — PR and merge

1. Commit on this branch (`issue-1-phase3-vertnet`):
   - `sources/databases/VertNet/primary_references_vertnet-*.csv` (6 files)
   - `R/library/citations/citations_config.r` (new `reflist_specs` entries)
   - `Bib/TaxonBodyMass_PrimaryCitations.bib` (appended entries)
   - `Bib/BM_primary_citations_snapshot.csv` (updated snapshot)
   - `Bib/TaxonBodyMass_CitationCiteIDs.csv` (updated)
   - `TaxonBodyMass_Provenance.csv.gz` (rebuilt)
   - `TaxonBodyMass.csv` (CiteID column updated)
   - `audit/provenance_rounds.md` (round entry)
   - `sources/source_files.csv` (regenerated)
   - Per-source README Provenance paragraphs

2. Session-lead review: diff, tests, output deltas (provenance row counts, bib entry counts), secret scan
3. Merge under the 2026-10-06 standing waiver

---

## Merge-back checklist

Before merging `issue-1-phase3-vertnet` → `main`:

- [ ] Step A complete (aves + fishes ZIPs present and readable)
- [ ] `BodyMass_VertNetAll.Rdata` has `ref_keys` non-NA for ≥ 12,000 rows
- [ ] All six `primary_references_vertnet-*.csv` files present, no `pending` rows
- [ ] `reflist_specs` entries added for all six labels
- [ ] `--bib --sheet` run for all six sources, no warnings in `reports/warnings_citations.md`
- [ ] RunMe.r rebuilt provenance: VertNet `primary_cite_id` non-NA count ≥ 12,000
- [ ] `TaxonBodyMass_Provenance.csv.gz` `unknown` count unchanged or reduced
- [ ] All three test files pass
- [ ] `audit/provenance_rounds.md` updated
- [ ] `sources/source_files.csv` regenerated (hash updated for new files)
- [ ] Session-lead review reported to owner

---

## Known risks and gotchas

1. **CRC-32 errors in cached ZIPs**: Python's `zipfile` raises CRC errors on these files; R's `unzip` is more tolerant. Test `unzip -t sources/VertNet/VertNet_Mammalia_Sept2016.zip` before the patch script.

2. **GBIF Registry DOIs vs. dataset-level DOIs**: GBIF datasets sometimes have a DOI at the dataset level (`dataset.doi`) AND a separate DOI for each published occurrence dataset version. Use the top-level `dataset.doi` (e.g. `10.15468/ivcidi`), not the version-specific one, for the bib entry.

3. **Deprecated / merged datasets**: Some older GBIF dataset UUIDs may return 301 redirects or 404s from the Registry. Log these as `rejected` in `primary_references.csv` with a note.

4. **Traits ZIP species overlap**: `vertnet-traits-sept2016` contributes 89,245 records to the Rdata but many species also appear in the taxon-specific ZIPs. `BuildProvenance()` handles this correctly via the species × source_label grouping — no deduplication is needed here.

5. **`format = 'dataset'` guard in `run_citations.r`**: The `--init` and `--verify` steps must skip sources whose `reflist_specs` entry has `format = 'dataset'`. Add a guard at the start of those steps (a one-line `if (spec$format == 'dataset') return(invisible(NULL))`).

6. **Sheet row deletions**: If any `--sheet` run appends rows that the owner later needs to delete (e.g. a rejected dataset entry), follow the standard procedure: list CiteID + `\citep{}` cell + "No DOI." marker (per `feedback_sheet_row_deletions.md`).

7. **No Scite screening needed**: GBIF institutional dataset DOIs are not retracted scientific papers. The selective Scite policy (CLAUDE.md) does not apply to these registry entries.
