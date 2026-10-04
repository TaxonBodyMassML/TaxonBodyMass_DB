# audit/

Review documents of the body-mass audits and the register of flagged records.
Nothing in this directory is read by the pipeline.

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

## Other files

- `outlier_report.md`, `outlier_report_2.md`,
  `outlier_corrections_single_source.md`: the 2026-08 review (above).
- `retired_outlier_rules/`: the retired rule files and their staleness audit
  (issue #24).
- `TaxonNameAuditPlan.md`: the plan of the taxon-name audit.
- `candidate_sources_2026-09-27.md`: candidate sources surveyed on 2026-09-27.
