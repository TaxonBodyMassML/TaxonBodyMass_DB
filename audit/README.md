# audit/

Review documents of the body-mass audits, the register of flagged records, and
four pipeline files (owner decision of 2026-10-04: review inputs live here,
run outputs under `reports/`): the extinct-taxa list the pipeline reads
(`extinct_taxa.csv`), the vocabulary of raw-name rules it reads
(`raw_name_patterns.csv`, issue #38), the log of imputed rows it writes
(`imputed_rows.csv`) and the saved entries of the live download frames that
feed that log (`imputed_rows_live.csv`, issue #40). Nothing else in this
directory is read or written by the pipeline.

## `flagged_species.csv`: the register of flagged records

One row per flagged record: a species x source value as it stood when a screen
flagged it. The file is the record of what was flagged, by which method, and
what was decided; it is an input of the range-filter revisit (issue #34) and
is read by no code. Rows are appended, never rewritten: a value corrected or
removed since keeps its row, with the value of its day.

Columns: `taxon` (the cleaned input name, `Genus_species`), `mass_g`,
`source_mass`, `n` (records behind the value), `kingdom` to `family`, `genus`
and `species` (the accepted name), `confidence` (GBIF match confidence),
`form`, `subspecies`, `variety` (empty but for two 2026-08 rows), `log10_mass`,
`log10_pred` (the expectation the method compared the value with),
`residual` = `log10_mass - log10_pred`, `abs_residual`, `class_outlier`,
`severity`, `method` and `note`.

Methods, with their dates and severity rules:

- `model_2026-08-25` (2,082 rows): the outlier screen of 2026-08-25 on
  `TaxonBodyMass_curated.csv` (38,300 records scored). `log10_pred` is a model
  prediction of log10 body mass from the taxonomy; `severity` is `CRITICAL` for
  `abs_residual >= 2`, `SUSPICIOUS` for `1 <= abs_residual < 2` and
  `TUKEY_ONLY` for class-level Tukey outliers (`class_outlier` TRUE) with
  `abs_residual < 1`. The review of these rows is in `outlier_report.md`
  (CRITICAL tier), `outlier_report_2.md` (SUSPICIOUS tier) and
  `outlier_corrections_single_source.md` (per-record corrections; the
  confirmed ones were entered in the lab Sheet). The rule files generated from
  that review were retired on 2026-10-03 (issue #24, `retired_outlier_rules/`,
  whose README lists how many of the 2026-08 values have changed since).
- `cross_source_2026-10-03` (32 rows): the GATEWAy (`Brose_etal_2018`)
  records that survive the per-web unit decisions of issue #14 (PR #32) and
  sit two or more orders of magnitude from every other source, plus the
  Weddell Sea sipunculan, the Mill Stream fish and four species whose
  remaining GATEWAy value is implausible once the tide pools are gone.
  `mass_g` is the Pass-1 geometric mean of the species' `Brose_etal_2018`
  records on the 2026-10-03 frames, computed as `R/RunMe.r` does (cleaning
  chain, then one value per species x source label), `n` its record count;
  `log10_pred` is log10 of the median of the other sources' Pass-1 values
  listed in the note (empty when the species has no other source);
  `severity` is `CRITICAL` when `abs_residual >= 2` or the value is physically
  impossible (*Golfingia margaritacea* at 0.16 mg), `SUSPICIOUS` otherwise,
  including the four species without another source. The note holds the
  per-web GATEWAy values, the other sources' values, the #14 recommendation
  (an override row for the lab Sheet) and the decision. Owner decision of
  2026-10-04 (issue #34): the records are left as they are and the override
  rows are not entered; some of these species fall to the `log10_range > 1`
  filter instead. Three species have a row under both methods (*Anemonia
  sulcata*, *Golfingia margaritacea*, *Hyas coarctatus*); three are overridden
  by the lab Sheet, so their GATEWAy record never reaches the output (said in
  the note).

To add rows: append them with a new `method` label (`<kind>_<date>`), state
the method's severity rule in this file, and leave the existing rows alone.

## `extinct_taxa.csv`: the extinct-taxa list (read by the pipeline)

One row per extinct species: `taxon` (`Genus_species`), `status` (the source's
status code, e.g. `IUCN:EP`, `MOM:historical`, `AVONET:Extinct`) and `source`.
The binomials of extinct, historically extinct and extinct-in-the-wild species
are compiled from the status columns of three sources already in the database
(MOM v10.2 `Status` in {extinct, historical}; PHYLACINE 1.2 `IUCN.Status.1.2`
in {EP, EX, EW}; AVONET `Species.Status == 'Extinct'`, mapped through the
BirdLife-BirdTree crosswalk), MOM's verdict yielding where PHYLACINE lists the
species as extant. Written by `R/library/build_extinct_taxa.r`, a stand-alone
script that `R/RunMe.r` does not source: run it by hand when one of the three
sources changes (`Rscript R/library/build_extinct_taxa.r`, from any directory;
see its header). Read by `RemoveExtinct()`
(`R/library/filter_extinct.r`, sourced by `R/RunMe.r` through `wd_root`), which
in section 2b drops every record of a listed name from every source after
`FixFormatting`. Until 2026-10-04 the file lived at `R/library/extinct_taxa.csv`.

## `raw_name_patterns.csv`: the vocabulary of raw-name rules (read by the pipeline)

The rules by which `FixFormatting()` (`R/library/fix_formatting.r`, pipeline
step 2) reduces a raw taxon name with brackets, three or more parts or
non-alphabetic characters to `Genus_species` or `Genus` (issue #38). One row
per rule: `pattern` (a Perl regex), `scope` (what it is matched against:
`epithet`, the second token of the name, matched case-insensitively, for
placeholders and identification qualifiers; `annotation`, the content of a
`()`, `[]` or `{}` group or a token after the binomial; `name`, the whole raw
name with underscores read as spaces and blanks collapsed), `class`
(`subgenus`, `sex`, `form_strain_region`, `size_class`, `species_group`,
`synonym`, `authority`, `trinomial`: the annotation is removed and the record
kept; `placeholder`, `qualifier`: the record leaves as a `Genus_sp` /
`Genus_cf` marker, or the word as written, which `RemoveNonTaxa()` removes;
`life_stage`, `size_class` for the small classes `{xs}`, `{s}`, `small`, and
`other_drop`: the record is dropped through `DropImputed()` and logged to
`imputed_rows.csv`; `hybrid`, `ambiguous`: the name is cut at the separator,
or before the word `hybrid` written in place of the epithet (issue #48), and
the record credited to the first name written), `action` (`strip`,
`drop`, or `fold`, which cuts a whole name at the first match of the pattern
and keeps the first two tokens before the cut, i.e. the first two tokens of
the whole name when the pattern is anchored at its start; owner decisions of
2026-10-04 on the size classes, species groups, hybrids and alternatives),
`note`
(the evidence: the raw names and sources that motivated the row, what happened
to them before #38) and `added` (date). Rows are tried in file order and the
first match wins; `LoadRawNamePatterns()` validates the columns, the class,
action and scope sets, their combinations and every regex when `R/RunMe.r`
loads the file. The structural rules (encoding, the position of a subgenus,
a genus written twice, the fold of a lowercase third token, the removal of
symbols) are code and are documented in the header of `fix_formatting.r`.

A placeholder marker drops the record and does not feed
`TaxonBodyMass_GenusLevel.csv` as a genus-only record (only a name written as
a bare genus does); the former exception, the six Brose_etal_2018 `Genus spec.`
markers and `Gomphonema type D` that `fix_misspellings.r` renamed to bare
genera, was removed under #43 (2026-10-04). A name written as a bare genus is
resolved at genus rank, filtered, weighted and de-duplicated by
`R/library/enrich_genus.r` (README step 6, issue #49); names of ranks above
genus are dropped and listed in `reports/genus_only_records.md`.

A bracket group or trailing token that no row covers is an error:
`FixFormatting()` leaves the name as it is, `reports/warnings_raw_names.md`
lists it under the class `error`, and `CheckRawNames()`
(`R/library/check_taxon_names.r`) stops the run. To admit a new pattern, add a
row with its class and action (and a note naming the raw names), rerun, and
check the name's entry in the report. The 993 raw names of the 2026-10-04
audit (TaxonBodyMass_DB-scratch/names/) are all covered; the fixtures of
`R/library/tests/test_raw_name_rules.R` pin one example per class and 60
ordinary names whose output must not change.

## `imputed_rows.csv`: the log of rows dropped as imputed (written by the pipeline)

One row per `DropImputed()` call (`R/library/helpers.r`): `source`, `reason`,
`n_dropped`, `n_taxa` (distinct taxon names among the dropped rows) and
`n_kept`. The parse scripts under `sources/databases/` call `DropImputed()` for
the rows a source itself flags as imputed, genus-averaged or copied from
another species, and for the exclusions recorded in their `README.md`
(unverifiable units, duplicated tables, group-level placeholder values);
`R/library/data_retrieve.r` calls it, through `DropPlaceholders()`, for the
Brose_2005 placeholder values of the live DataRetriever download; and
`FixFormatting()` calls it in pipeline step 2 for the records whose raw name
carries a life-stage annotation or a small size class (`{xs}`, `{s}`,
`small`; `raw_name_patterns.csv`, issue #38), one entry per rule class and
source label (the `n_kept` of these entries counts the label's rows in its frame).
Every call appends to the in-memory list `imputed_log`. After
`FixFormatting()`, `R/RunMe.r` merges the list with the rows of
`imputed_rows_live.csv` for the live download frames that were not downloaded
in the run (`MergeImputedLog()`, `R/library/helpers.r`; a frame whose flag was
TRUE has its fresh entries in the list already), orders the rows by source
(C-locale order; the rows of one source keep the order of the calls, so
`n_kept` reads as a running tally through the parse script and step 2), prints
the table and writes it here, but only in a run with `recompile = TRUE` (when
the parse scripts did not run the log would hold the step-2 and saved entries
alone). The file is therefore the same whatever the download flags were, and a
recompile-only run (`recompile = TRUE`, the download flags FALSE) reproduces
the committed file byte for byte (issue #40; before #40 such a run dropped the
`Brose_2005` row, which had to be restored by hand). Each source's `README.md`
states the same decisions in words in its `Imputed rows:` line, which
`R/library/check_source_docs.r` checks at every run. Until 2026-10-04 the file
lived at `reports/imputed_rows.csv`.

## `imputed_rows_live.csv`: the saved entries of the live download frames (written by the download scripts)

The `DropImputed()` calls of the four live download frames run only while the
frame is downloaded (`DataRetrieve`, `DataVertNet` or `DataFishbase` = TRUE in
`R/RunMe.r`), so their entries would be lost to every other run. Each download
script therefore saves its own entries here once it has saved its frame
(`SaveImputedLive()`, `R/library/helpers.r`): `R/library/data_retrieve.r` the
rows of `DataRetrieverAll` (the `Brose_2005` placeholder rows,
`DropPlaceholders()`), `R/library/data_vertnet.r` those of `VertNetAll` and
`R/library/data_fishbase.r` those of `Fishbase` and `Sealifebase` (none of
these three has a drop rule today, so they save no rows). A script replaces
the rows of its own frame and leaves the other frames' rows as they are, so
the file always holds the entries of the last download of each frame; a failed
Fishbase or Sealifebase download leaves the previous rows in place.

Columns: the five of `imputed_rows.csv` (`source`, `reason`, `n_dropped`,
`n_taxa`, `n_kept`), `frame` (the stem of the frame file in `sources/Rdata/`:
`DataRetrieverAll`, `VertNetAll`, `Fishbase` or `Sealifebase`), `written` (the
ISO date of the download) and `frame_md5` (the md5 of the frame file that
download saved). Rows are ordered by frame, each frame's rows in the order of
the calls. `CheckImputedLive()` (`R/library/check_cache.r`, called by
`R/RunMe.r` right after the cache-completeness check) warns when a cached
frame is not the file whose download saved its rows (the md5 differs: the
frame was downloaded again without saving its entries, or the cache was copied
from a run with a different frame; a copy of the same file passes, whatever
its timestamp), and when the file holds rows for a name that is not a live
frame or whose frame file is absent; a live frame without rows is reported
only for `DataRetrieverAll`, as information. The file is not edited by hand
except to seed it: its one row, `Brose_2005`, was transcribed on 2026-10-04
from the `imputed_rows.csv` written by the `DataRetrieve = TRUE` run of PR #32
(commit 11dd2f5), hence `written` 2026-10-03, and `frame_md5` is that of the
`BodyMass_DataRetrieverAll.Rdata` that run saved (`1443be65...`). Exercised
without network access by `Rscript R/library/tests/test_imputed_live.R`.

## Other files

- `outlier_report.md`, `outlier_report_2.md`,
  `outlier_corrections_single_source.md`: the 2026-08 review (above).
- `retired_outlier_rules/`: the retired rule files and their staleness audit
  (issue #24).
- `TaxonNameAuditPlan.md`: the plan of the taxon-name audit.
- `candidate_sources_2026-09-27.md`: candidate sources surveyed on 2026-09-27.
