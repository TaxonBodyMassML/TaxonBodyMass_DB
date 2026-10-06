# R/library/citations: verified primary-source citations (issue #1)

Tooling that attributes the records of a compilation to the studies that
measured them and lets a new citation enter the bibliography only after
automated verification against Crossref and OpenAlex, or an explicit decision
by the owner. `R/RunMe.r` sources only the offline part (`citations_config.r`,
`normalise_citation.r`, `parse_reflists.r`, `build_bib.r`, `provenance.r`);
everything that talks to a service or to the Google Sheet runs by hand through
`run_citations.r`. No Google Scholar.

## Files

| file | contents |
| --- | --- |
| `citations_config.r` | paths, the column schemas of the tracked files, the controlled vocabularies, the decision thresholds, the polite-pool identity (`CROSSREF_MAILTO` / `OPENALEX_MAILTO`, else git `user.email`), the per-source reference-list specifications `reflist_specs` |
| `normalise_citation.r` | `NormaliseCitationString()`, `ParseCitationString()` (regex parse into `parsed_*` query fields; author-year styles and, through `ParseNatureStyle()`, the Nature style "Authors. Title. Journal volume, pages (year)." of the Chown_etal_2007 list), `TitleSimilarity()` (mean of Jaro-Winkler and token-set Jaccard), the author / container / volume / pages comparisons |
| `parse_reflists.r` | `SplitRefKeys()` for the parse scripts, `ExplodeRefKeys()`, `ParseRefListCSV()` (`csv_sep`, `file_encoding` for a latin1 list such as Hebert's, split author/year/title/journal columns pasted into one citation), `ParseInRowCitations()` (full-text citations carried by the records themselves: the native key is `h:<sha1-8>` of the normalised string, a DOI embedded in the text is `raw_doi`, the record's short in-text form is kept as the reference's `note`), `ExpandSameAuthorMarkers()`, `ParseAuthorYearKey()` and `ReflistFromCrossrefReferences()` (format `crossref_reflist`: the author-year keys of a compilation's tables, 'Ikeda (2013a)', 'Ikeda and Mitchell (1982)', 'Ikeda et al. (2007)', joined deterministically -- first surname with diacritics folded, year and suffix, one / two named / three-plus authors -- to the reference list the compilation's own Crossref record deposits; the deposited `unstructured` text is the citation, the deposited DOI `raw_doi`, the Crossref reference key the `note`; a key matching no or several deposited references is reported unresolved, a deposited book chapter is flagged `owner_review`), `InitPrimaryReferences()`, `MergePrimaryReferences()`; the other formats (xlsx, bib, docx, pdf, html, EndNote) stop until their tier is reached |
| `verify_services.r` | `CachedGET()` (httr2, User-Agent with mailto, one request per second per host enforced by `PaceRequest()` on top of `req_throttle()`, bounded retries on 429/5xx, every raw response cached under `sources/citations_cache/` keyed by sha1 of the URL without the mailto and api_key parameters; a spent quota, HTTP 429 after the retries, raises the classed condition `citations_quota` of `QuotaCondition()` and flags the host for the session), `CrossrefQuery()`, `CrossrefWork()` (with `reference[]`, `update-to`, `updated-by`), `CandidatesFromCompilationReflist()`, `OpenAlexQuery()`, `OpenAlexWork()` (`is_retracted`; `OpenAlexAuth()` appends `OPENALEX_API_KEY` when set), `ReadSciteChecks()` |
| `decide.r` | `ScoreCandidate()`, `DecideMatch()` (the rules below), `VerifyReference()`, `VerifyPrimaryReferences()`, `ApplySciteChecks()`, `WritePendingQueue()`, `ApplyQueueDecisions()` |
| `build_bib.r` | `ReadBibEntries()`, `BibKeyFor()`, `BuildBibEntry()` (Crossref record only), `BuildBibEntryNoDOI()`, `WritePrimaryBib()`, `CheckBibKeysUnique()`, `CheckBibSyntax()` |
| `cite_ids.r` | `CiteIDFor()` |
| `sheet_append.r` | `ReadSheetTab()`, `FormatCitationText()`, `BuildSheetRows()`, `AppendPrimaryCitations()` (dry run by default, idempotent on Bibcite, append-only, snapshots before and after, `BM_primary_citations` only) |
| `provenance.r` | `LoadPrimaryReferences()`, `LoadProvenanceClasses()`, `SplitSourceMass()`, `BuildProvenance()` (with the hop-2 helpers `MatchIntermediateLabel()` and `IntermediateReferences()`), `CheckCitations()`, `WriteCitationsReport()` (sourced by RunMe.r) |
| `run_citations.r` | the command line |
| `tests/fixtures/cache/` | recorded Crossref and OpenAlex responses for the unit tests in `R/library/tests/test_citations_*.R` (no network in tests) |

## Tracked data

- `sources/databases/<Src>/primary_references.csv` (or `primary_references_<Label>.csv` in a folder several labels share, such as `DataRetriever/primary_references_Brose_2005.csv`; the label's `reflist_specs` entry names the folder, the cached frame and the file): one row per native reference key a source's records cite (`raw_citation` verbatim and immutable; `parsed_*` query fields; the resolved `doi`, `bibcite`, `cite_id`; `match_status`, `match_reason`, `services`, the locally computed agreement, `verified_at`, `tool_version`; the owner's `decided_by` / `decided_at`). The owner may edit `role`, `parsed_*`, `notes` and `owner_review` only (`owner_review`, optional in older files, holds the reason a reference must pass through the queue).
- `Bib/source_provenance_classes.csv`: the registry of every `source_mass` label (`class`: primary, compilation, derived, database, live, unknown; `default_provenance_type`: the type a record gets when it carries no resolved primary reference; `equation_bibcite` for allometry-derived sources). RunMe.r stops on an unregistered label.
- `Bib/pending_citations.csv`: the review queue. Rows are appended by `--queue`, never rewritten; approval is a committed `decision` with `decided_by` and `decided_at`: `1|2|3` (that candidate), `doi:10.…` (re-verified), `manual:<Key>` (an entry the owner added to the curated bib), `nodoi` (a DOI-less entry built from the corrected `parsed_*`; `parsed_author1` may then hold the approved author list in BibTeX form, `Ikeda and Hirakawa and Imamura`), `self`, `drop`. A candidate or `doi:` decision may carry `:year=YYYY` (owner decision 2026-10-04): the bib entry and the Citation cell take that year instead of the service record's (a digitised thesis deposited with its scan date), the entry's `note` says so, and the override is kept in `primary_references.csv` (`year_override`). An empty `decision` defers the case: it stays `pending` and is reported as such, not as an error. Every uncertain case is collected and put to the owner in one batch at the end of a round, never settled by a default.
- `Bib/scite_checks.csv`: the retraction / correction screen of accepted DOIs, written in Claude Code sessions from the Scite MCP tools (`checked_by = scite-mcp`; `editorialNotices` read per DOI). When Scite is unavailable, returns nothing or fails on quota or permission, the Consensus MCP tools are the fallback (`checked_by = consensus-mcp`; Consensus has no retraction field, so the row says `notice_type = unchecked` and the DOI relies on the Crossref `update-to` and OpenAlex `is_retracted` flags the R tool consults for every DOI); when neither answers the gap is recorded (`checked_by = none`) and the reference stays pending; the owner may waive the screen of a DOI no service indexes (`checked_by = owner-waiver`, `notice_type = waived`; owner decision 2026-10-05 for the JSTOR-era Mammalian Species accounts of Smith_2003, Scite re-screen due after 2026-11-01): such a row counts as a screen without notice, closes the gap of an earlier `none` row, never turns a status to pending / unscreened, and is superseded by any later `scite-mcp` or `consensus-mcp` row (the latest answering service wins, Scite over Consensus over the waiver). Any notice or retraction turns a certain row back to pending; a screened DOI's `services` gains `;scite-mcp` or `;consensus-mcp`. Neither service ever writes a bib entry or a Sheet row.
- `Bib/TaxonBodyMass_PrimaryCitations.bib`: generated (`%% GENERATED … do not edit`), rebuilt by `--bib` from every source's accepted references and the response cache, keys in byte order; a key present in the curated `Bib/TaxonBodyMass_Citations.bib` as well fails the pipeline.
- `Bib/BM_primary_citations_snapshot.csv`, `Bib/BM_citations_snapshot.csv`: the two Sheet tabs as last read (the offline fallback for section 8 of RunMe.r and the record of every append).
- `TaxonBodyMass_Provenance.csv.gz`: species x source label x reference (see the main README, Outputs). Its `match_status` is the reference's, or `unmatched_key` (a key the source's reference list lacks) or `uningested` (the source keeps `ref_keys` but has no `primary_references.csv` yet).

## Hop 2: a reference that is itself a database source

`BuildProvenance()` recognises a resolved reference (`certain`, `approved`, `nodoi_approved`) that stands for another source label of the database: its `cite_id` is a registered label, or its `bibcite` or `doi` is that of the label's curated bib entry (`MatchIntermediateLabel()`; the DOI route needs the label's entry to carry a `doi` field, which `Chown:2007aa` gained for the Herberstein_etal_2022 pilot). Such a reference is an intermediate compilation, and the record is attributed through it (`IntermediateReferences()` reads the intermediate's own records of the same species and their accepted or self references):

| the intermediate's record of the species | row written | hop | `provenance_type` | `via_cite_id` | `primary_*` |
| --- | --- | --- | --- | --- | --- |
| resolves to a primary reference (one row per reference) | through the intermediate | 2 | `compiled_via_compilation` | the intermediate's CiteID | the intermediate's reference (`match_status` that reference's) |
| is the intermediate's own measurement (role `self`) | the intermediate is the measurement | 1 | `compiled_from` | NA | the intermediate |
| none, keyless, pending, or the intermediate has no `primary_references.csv` yet | the intermediate is the terminal citation (owner decision 2026-10-04) | 1 | `compilation_terminal` | NA | the intermediate (`ref_role = compilation`) |

No third hop is attempted: a reference of the intermediate that is itself a label stays as that label. A record-level `prov_type` override is never changed. The terminal rows become hop-2 (or `compiled_from`) rows by themselves once the intermediate's reference list is ingested; nothing in the source's `primary_references.csv` changes, so `role` stays `measurement` there and the owner may set it to `compilation` if wanted (the hop-2 rule does not depend on it). Herberstein_etal_2022 -> Chown_etal_2007 is the first case: 244 ant records cite Chown et al. 2007, whose Appendix S1 holds the authors' own measurements of those eight species, so they will read `compiled_from` citing Chown once `Chown_etal_2007` is ingested (its S1 keys are `self`); until then they are `compilation_terminal` at Chown.

## Workflow for one source

```
Rscript R/library/citations/run_citations.r --source Kiorboe_2013 --init          # skeleton from the reference list + ref_keys
Rscript R/library/citations/run_citations.r --source Kiorboe_2013 --verify --queue
#   Scite screen of the accepted DOIs in a Claude Code session -> Bib/scite_checks.csv
#   owner fills `decision` in Bib/pending_citations.csv and commits
Rscript R/library/citations/run_citations.r --source Kiorboe_2013 --apply-queue --bib
Rscript R/library/citations/run_citations.r --source Kiorboe_2013 --sheet               # dry run
Rscript R/library/citations/run_citations.r --source Kiorboe_2013 --sheet --no-dry-run
```

Every step writes `reports/citations_<Src>.md`. `--offline` forbids network access (cached responses only); `--force` re-verifies `certain` rows.

Service quotas. Crossref's polite pool is generous; OpenAlex allows 1,000 requests a day without an API key (since 2025; the `x-ratelimit-*` headers count them per day) and answers the rest with 429 and a Retry-After of up to a day. `CachedGET()` does not wait for that: the reference that hit the quota and every later one needing that service are left unverified (status NA, named in the report line `--verify: n reference(s) left unverified`), the decisions taken so far are written, and the next `--verify` (after the reset, or with `OPENALEX_API_KEY` set in the environment) finishes the rest from the cache plus the missing calls. Found on the Herberstein_etal_2022 pilot (2026-10-04), when two pilots ran on one day. A reference needs OpenAlex for the retraction flag of a DOI it carries and for the second service of an open search.

## Decision rules (issue #1, section 2.3)

Service relevance scores are cached with the raw responses but never enter a decision. Candidates of type dataset, component, peer-review, journal issue and the like are dropped before scoring. For each reference:

| condition | status / reason |
| --- | --- |
| `raw_doi` resolves at Crossref and (author and year agree, or `title_sim >= 0.80`) | `certain` / `doi_resolves` |
| `raw_doi` present but unresolvable or disagreeing | `pending` / `doi_mismatch` |
| no candidate at all | `not_found` / `no_candidates` |
| best `title_sim < 0.70` and the citation reads as grey literature (thesis, report, unpublished, …) | `pending` / `grey_literature` |
| best `title_sim < 0.70` otherwise | `not_found` / `below_threshold` |
| a retraction (OpenAlex `is_retracted`, Crossref `update-to` / `updated-by`, Scite) or any editorial notice on the best DOI | `pending` / `retracted` (never auto-certain); a `checked_by = none` screening row gives `pending` / `unscreened` |
| runner-up with a different DOI within 0.05 of the best | `pending` / `ambiguous` |
| best not strong (`title_sim >= 0.93`, author, year within 1, and one of container / volume / pages) | `pending` / `weak_match` |
| strong and Crossref and OpenAlex both return that DOI | `certain` / `two_service_agreement` |
| strong, one service, the candidate comes from the compilation's deposited reference list, `title_sim >= 0.95` | `certain` / `closed_world` |
| strong, one open-search service | `pending` / `single_service` |
| the citation is the compiler's own study or unpublished data | `self`, no service call |
| the reference list (`review_col`) or the owner (`owner_review` in `primary_references.csv`) gives a reason to review the reference (a known alias, a thesis, a book chapter, a work without body sizes) and the services would accept it | `pending` / `owner_review`: queued with its candidates, never auto-certain (the standing rule that theses, books and near-misses always queue) |
| OpenAlex was known to be unavailable when the decision was made (`services` without it; an exhausted quota normally leaves the reference unverified instead, see Service quotas) and the decision would rest on the services' agreement or their joint retraction flags | `pending` / `service_unavailable`: the Crossref candidates are kept, the row is not queued for the owner, and the next `--verify` decides it; a disagreeing source DOI, grey literature, a notice and a self reference are decided as usual |

`weak_match`, `below_threshold`, `no_candidates`, `unscreened` and `service_unavailable` are reason codes added to the issue's list so that every queue row says why it is there (`service_unavailable` rows are not queued). Requests time out after 60 s and a dropped connection is retried like a 5xx.

## Hallucination-robustness rules (issue #1, section 6)

Nothing typed by a person or an LLM reaches a bib file or the Sheet: entries come from `BuildBibEntry()` (a Crossref record) or `BuildBibEntryNoDOI()` (owner-approved fields, with a note saying so); the Sheet's Citation cell from `FormatCitationText()`. `raw_citation` is immutable. Every accepted row stores the services, the similarity and agreement flags, `verified_at` and `tool_version`; every decision stores `decided_by` / `decided_at`. Keys and CiteIDs are reused by DOI before a new one is minted, collisions get suffixes. Sheet writes are append-only, dry-run by default, deduplicated on Bibcite, snapshotted, and go to `BM_primary_citations` only.

## Dependencies

`httr2`, `jsonlite`, `digest`, `stringdist` (title similarity), `RefManageR` (syntax check of the generated bib; optional), `googlesheets4`. `pdftools` and `rvest` are not needed until the pdf / html reference lists of tiers A2 and C.

## Tests

```
for f in R/library/tests/test_citations_*.R; do Rscript "$f"; done
```

Six files in the repository's plain-Rscript pattern: `test_citations_parse.R` (normalisation, the regex parse, the reference lists, the skeleton), `test_citations_services.R` (cache, Crossref / OpenAlex parsers, closed-world candidates, the screening file), `test_citations_decide.R` (every rule of the table above, `VerifyReference()` on four Kiorboe_2013 references, the queue and its decision grammar, `ApplySciteChecks()`), `test_citations_bib.R` (bib reading, key minting, entries from Crossref records of every mapped type, the DOI-less entry, the generated file, CiteIDs), `test_citations_sheet.R` (the Citation cell, the append through a fake Sheet) and `test_citations_provenance.R` (the registry, `SplitSourceMass()`, `LoadPrimaryReferences()`, `BuildProvenance()`, the checks and report, the RunMe wiring). All tests are offline; the service responses they need are the recorded fixtures in `tests/fixtures/cache/` (the cache layout of `CachedGET()`, keyed without the mailto parameter so that they serve any contributor).
