# TaxonBodyMass_DB

A compiled, harmonized database of species body masses (in grams) drawn from many published sources spanning the full diversity of heterotrophic life — from microbes to large vertebrates. Developed in support of [FracFeed_DB](https://github.com/marknovak/FracFeed_DB) and [TaxonBodyMassML](https://github.com/TaxonBodyMassML/TaxonBodyMassML).

## Data Sources

Body mass data are compiled from primary sources and databases covering organisms across all major taxonomic groups, including bacteria, protists, marine zooplankton and invertebrates, spiders, fish, amphibians, reptiles, birds, and mammals (modern and fossil). Sources include both ecological databases (food-web, metabolic-scaling, predator-prey, movement) and taxonomic trait databases (life-history, body size). Live downloads from [FishBase](https://www.fishbase.org) and [SeaLifeBase](https://www.sealifebase.ca) are supported via the `rfishbase` package.

Bibliographic information for all sources is in `Bib/TaxonBodyMass_Citations.bib`.

## Data Licences

The repository `LICENSE` is CC BY-NC 4.0 and covers what the lab wrote: the pipeline code, the per-source parse scripts and READMEs, the parsed and transcribed tables, and the compiled outputs, to the extent the lab holds rights in them. It does not relicense any third-party file: every raw source file kept under `sources/databases/` and `sources/conversion_factors/` stays under the terms of its licensor, recorded in the `Licence:` line of the folder README and in the tracked manifest `sources/source_files.csv`. Full licence details, attribution texts and carve-outs are in [`sources/LICENSES.md`](sources/LICENSES.md).

## Pipeline

The pipeline is written in R and orchestrated by `R/RunMe.r`. It proceeds through seven steps: per-source parsing, taxon name cleaning, lab Sheet override, taxonomy enrichment and autotroph removal, merging and de-duplication, genus-level aggregation, and citation/provenance linking.

See [docs/pipeline.md](docs/pipeline.md) for full documentation of each step, the source dependency registry and run-stop conditions.

## Primary Outputs

The compiled tables are tracked at the repository root and can be used directly without running the pipeline.

| File | Description |
| --- | --- |
| `TaxonBodyMass.csv` | One row per accepted species with body mass (g), taxonomy, source labels and provenance metadata |
| `TaxonBodyMass_GenusLevel.csv` | One row per accepted genus: arithmetic mean of the species cross-source means and any genus-only records |
| `TaxonBodyMass_Provenance.csv.gz` | One row per species × source × reference, linking each species to the study that measured it (where ingested) |

See [docs/outputs.md](docs/outputs.md) for the complete list of all output files, including bibliographies, pipeline support files, audit logs and per-run reports.

## Usage

### Prerequisites

Install the required R packages:

```r
install.packages(c("plyr", "dplyr", "googlesheets4", "stringr", "readxl"))
install.packages("rfishbase")
install.packages("rdataretriever")
```

The `rdataretriever` package requires Python and the [`retriever`](https://retriever.readthedocs.io) Python package. It is used only when `DataRetrieve = TRUE` in `RunMe.r`. `RunMe.r` points reticulate at a dedicated venv at `~/.local/share/r-rdataretriever` pinned to Python 3.11 and `retriever` 2.4.0. Create it once with [uv](https://docs.astral.sh/uv/) (`brew install uv`):

```bash
uv venv --python 3.11 ~/.local/share/r-rdataretriever
uv pip install --python ~/.local/share/r-rdataretriever "retriever==2.4.0" "setuptools<70"
```

`retriever` 2.4.0 fails on import with `packaging.version.InvalidVersion: Invalid version: ''` when any cached dataset script has an empty minimum-version field. Fix it by adding an `and mod_ver` guard in the venv's `retriever/lib/scripts.py`:

```bash
sed -i '' 's/if hasattr(module, "retriever_minimum_version"):/if hasattr(module, "retriever_minimum_version") and mod_ver:/' \
  ~/.local/share/r-rdataretriever/lib/python3.11/site-packages/retriever/lib/scripts.py
```

A message such as `tidycensus is supported by Retriever version 3.0.1-dev` on load is harmless.

### Reproduce the database

To regenerate all per-source `.Rdata` files and recompile the database from scratch, set `recompile = TRUE` at the top of `R/RunMe.r` before running it. The download flags `DataRetrieve`, `DataVertNet` and `DataFishbase` control the four live-download frames; `DataSheets` controls whether the lab Google Sheet is imported (`TRUE` downloads its three tabs and refreshes the tracked copies; `FALSE`, the committed default, reads the copies without a Google token, so a fresh clone runs as it is).

Contact mark.novak@oregonstate.edu to contribute new sources or curated values.

### Use the compiled output

`TaxonBodyMass.csv` and `TaxonBodyMass_GenusLevel.csv` are tracked at the repository root and can be used directly without running the pipeline, or use the R and Python packages associated with [TaxonBodyMassML](https://github.com/TaxonBodyMassML/TaxonBodyMassML).

## Reproducibility

Steps 3 and 7 of the pipeline take the lab-curated mass overrides and the citation maps from a lab-internal Google Sheet. The three tabs the pipeline reads are tracked in this repository as CSV copies, and the pipeline reads the copies whatever `DataSheets` is set to, so the full pipeline is reproducible offline from a fresh clone with `DataSheets = FALSE` (the committed default) and without access to the Sheet. `DataSheets = TRUE` is for the lab: it downloads the tabs with the lab's Google token, rewrites the copies, and reports the rows added, removed and changed; the refreshed copies are committed together with the outputs they produce (issue #118).

## Citation

Pasquantonio GM, Prater H, Pendurti AC, Novak M (2026). *TaxonBodyMassML: Taxonomy-informed prediction of body mass using gradient-boosted trees.* EcoEvoRxiv. [https://doi.org/10.32942/X2BX01](https://doi.org/10.32942/X2BX01)
