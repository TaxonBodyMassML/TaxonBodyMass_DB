# Plan: Systematic Taxon Name Audit for TaxonBodyMass.csv

## Context

The pipeline in `TaxonBodyMass_DB/R/RunMe.r` applies three fix scripts before producing the final `output/TaxonBodyMass.csv` (39,301 rows, columns: `taxon`, `mass_g`, `source_mass`, `n`). Despite those scripts, unknown numbers of misspellings, truncations, synonym mismatches, and encoding artifacts likely remain in the output. The goal is to discover these remaining errors, document them in a markdown report, and translate confirmed fixes into additions to the existing `fix_*.R` scripts so they are corrected in future pipeline runs.

Existing fix coverage:
- `fix_formatting.r` — encoding, underscore normalization, case, trinomial truncation
- `fix_misspellings.r` — ~200 exact-match corrections + 9 genus-prefix substitutions
- `fix_nontaxa.r` — removes ~22 hardcoded non-taxa and regex-based qualifiers (`_sp`, `_cf`, etc.)

No external taxonomy reference files exist in the project; no automated audit tooling exists.

---

## Phase 0 — Prerequisites (completed)

The following were run once before the workflow and the results persist in `/tmp/taxon_audit/`:

```bash
# Extract unique taxon names from the output CSV
mkdir -p /tmp/taxon_audit
tail -n +2 TaxonBodyMass_DB/output/TaxonBodyMass.csv | cut -d',' -f1 | tr -d '"' | sort -u \
  > /tmp/taxon_audit/unique_taxa.txt
# Result: 39,301 unique names

# Extract wrong-spelling keys already handled by fix_misspellings.r
grep -oE '"[A-Z][a-z]+_[a-z_]+"' TaxonBodyMass_DB/R/library/fix_misspellings.r \
  | tr -d '"' | sort -u > /tmp/taxon_audit/already_corrected.txt
# Result: 362 entries to skip during audit
```

A permission entry was also added to `.claude/settings.json` so GBIF curl calls do not prompt during the headless workflow:

```json
{ "permissions": { "allow": ["Bash(curl -s https://api.gbif.org/*)"] } }
```

---

## Phase 1 — Chunk Creation (completed)

A setup agent split `unique_taxa.txt` into 10 alphabetical chunk files at `/tmp/taxon_audit/chunk_NN.txt` using `grep '^[LETTERS]'`. The actual genus-name distribution in the output CSV is:

| Chunk | Genus prefix range | Actual size |
|-------|--------------------|-------------|
| 01    | A                  | 4,142       |
| 02    | B, D, E            | 4,403       |
| 03    | C                  | 5,219       |
| 04    | F, G, H            | 3,742       |
| 05    | I, J, K, L         | 3,370       |
| 06    | M, N               | 4,079       |
| 07    | O, Q, R            | 2,264       |
| 08    | P                  | 5,225       |
| 09    | S                  | 3,133       |
| 10    | T–Z                | 3,724       |

C and P are the largest letters (~5,200 each). O/Q/R is the smallest chunk (~2,264). The groupings were chosen to balance size while keeping each chunk under ~5,500 names.

---

## Phase 2 — Parallel Audit (10 agents)

Each audit agent receives its chunk file path, the `already_corrected.txt` skip list, and reads `fix_misspellings.r` and `fix_nontaxa.r` for context. Agents perform three passes and write two output files:

- `/tmp/taxon_audit/flags_NN.txt` — raw heuristic output
- `/tmp/taxon_audit/findings_NN.json` — structured findings (written after heuristics, updated after GBIF)

### Pass A — Pattern Heuristics (Python, no network calls)

Each agent writes a Python script to `/tmp/taxon_audit/scan_NN.py` and runs it. The script checks every name in the chunk against these nine heuristics:

| Code | Heuristic | Rule |
|------|-----------|------|
| `epithet_short` | Very short epithet | Epithet ≤ 3 characters — likely truncated |
| `triple_letter` | Repeated-letter anomaly | 3+ identical consecutive letters anywhere |
| `digit` | Digit in name | Any numeral 0–9 |
| `encoding_artifact` | Encoding residual | Any character with `ord > 127` (Latin-1/UTF-8 survivor) |
| `double_underscore` | Doubled underscore | `__` anywhere |
| `unusual_ending` | Non-standard Latin/Greek suffix | Epithet (>3 chars) does not end with a recognized suffix — see full suffix list below. Gender variants (−us/−a/−um) are **not** flagged. |
| `patronymic_single_i` | Single-i patronymic | Epithet ends in consonant+`i` (not `ii`), stem ≥ 5 chars — may need double-i (ICZN patronymic rule) |
| `uppercase_epithet` | Uppercase epithet start | First character of epithet is uppercase |
| `uninominal` | No underscore | Name contains no underscore |

**Accepted suffix list** (non-exhaustive, used for `unusual_ending`): `us, a, um, is, es, e, ii, i, ae, iae, ens, ensis, anus, ana, inus, ina, atus, ata, oides, ella, aster, ifer, iger, cola, phila, formis, vorus, osus, osa, alis, aris, icus, ica, odon, ops, opsis, ichthys, soma, nema, pus, ceps, pes, phagus, phaga, or, ax, ix, ex, ox, ux, ota, on, ys, nus, nia, ia, ida, ini, ium, yn, in, an, en, un, id, ra, ta, na, la, ka, da, ba, ma, fa, ga, ha, ja, pa, sa, va, wa, xa, ya, za`

The script prints one line per flag (`FLAG|taxon|heuristic_code|reason`) and a summary (`SUMMARY|total|flagged`), and saves output to `flags_NN.txt`. The agent writes a preliminary `findings_NN.json` at this point (before GBIF) so downstream phases are never blocked by an incomplete audit agent.

### Pass B — GBIF Name Matching (network calls, flagged names only)

For each flagged name, the agent queries:

```
GET https://api.gbif.org/v1/species/match?name=Genus+species&verbose=true
```

Batches of 10 names, with `sleep 1` between batches. Fields extracted: `matchType`, `canonicalName`, `status`, `confidence`, `acceptedUsage.canonicalName`.

| GBIF result | Action |
|-------------|--------|
| EXACT + ACCEPTED + confidence ≥ 90 | Clear the flag — name is valid |
| FUZZY + canonicalName ≠ queried name | Record suggested spelling |
| SYNONYM | Record accepted name from `acceptedUsage.canonicalName` |
| NONE | High-confidence error; pass to knowledge check |
| confidence < 70 (any matchType) | Flag for expert review |

After GBIF checks the agent updates `findings_NN.json` with the full results.

### Pass C — Taxonomic Knowledge Check

For names where GBIF returned NONE or confidence < 70, the agent applies its own taxonomic knowledge to identify the likely correct spelling, the taxonomic group, and whether this is a genuine misspelling or a legitimately obscure taxon.

### Output schema per finding

```json
{
  "taxon": "Genus_species",
  "heuristic": "epithet_short",
  "issue": "brief description of the problem",
  "gbif_match_type": "FUZZY",
  "gbif_canonical": "Genus_species_correct",
  "gbif_status": "ACCEPTED",
  "gbif_confidence": 95,
  "suggested_correction": "Genus_species_correct",
  "confidence": "HIGH",
  "fix_target": "fix_misspellings",
  "rationale": "Detailed explanation of the error and the evidence"
}
```

`confidence` ∈ {HIGH, MEDIUM, LOW}. `fix_target` ∈ {fix_misspellings, fix_nontaxa, expert_review}.

---

## Phase 3 — Synthesis (1 agent)

The synthesis agent reads all 10 `findings_NN.json` files, merges and deduplicates by `taxon`, cross-checks against `fix_misspellings.r` to remove already-corrected entries, classifies each remaining finding as **confirmed** / **probable** / **expert_review**, assigns an `issue_type`, and writes `/tmp/taxon_audit/synthesis.json`.

Issue types: `misspelling`, `wrong_latin_ending`, `encoding_artifact`, `truncated_epithet`, `synonym`, `invalid_nontaxon`, `other`.

---

## Phase 4 — Report Generation (1 agent)

The report agent reads `synthesis.json` and writes `TaxonBodyMass_DB/output/audit/TaxonNameAudit.md` with this structure:

```
# Taxon Name Audit Report
**Date / File audited / Counts**

## Summary Table
Issue type × (Confirmed | Probable | Expert review | Total)

## Section 1: Confirmed Corrections
### 1.1 Misspellings
### 1.2 Wrong Latin Endings
### 1.3 Encoding Artifacts
### 1.4 Truncated Epithets
### 1.5 Synonyms / Superseded Names
### 1.6 Invalid / Non-taxon Entries

## Section 2: Probable Corrections (needs verification)

## Section 3: Needs Expert Review

## Section 4: Methodology

## Verification  ← appended by the Verify agent
```

---

## Phase 5 — Script Updates (1 agent, generate + apply combined)

A single agent reads `synthesis.json` and the current `fix_misspellings.r` / `fix_nontaxa.r`, determines what to add, then applies edits directly using the Edit tool:

**`fix_misspellings.r` — corrections vector** (one binomial fixes):
```r
"Wrong_spelling"              = "Correct_spelling",            # rationale
```
Entries are inserted maintaining strict alphabetical order of the wrong-spelling key, aligned with surrounding entries in the same letter section.

**`fix_misspellings.r` — genus_prefixes list** (when the same wrong genus prefix affects 3+ species):
```r
c("WrongPrefix_",  "CorrectPrefix_"),       # explanation
```

**`fix_nontaxa.r` — invalid or nontaxa vectors**:
```r
"name_to_remove",  # reason
```

After editing, the agent runs:
```r
Rscript -e "source('fix_misspellings.r'); source('fix_nontaxa.r'); cat('Syntax OK\n')"
```
and fixes any syntax errors before finishing.

---

## Phase 6 — Verification (1 agent)

Because `RunMe.r` requires Google Sheets OAuth, the full pipeline is not re-run. Instead the agent:

1. Syntax-checks both edited scripts with `Rscript -e source(...)`.
2. For 5–10 confirmed corrections, checks whether the wrong spelling is present in the existing CSV with `grep -c`. A count > 0 means the fix will take effect on the next pipeline run; count = 0 means it was already fixed or was never in the data.
3. Reports line counts for both edited scripts.
4. Appends a **Verification** section to `TaxonNameAudit.md` with the syntax check result, spot-check table, and a note that wrong spellings still present in the CSV will be corrected on the next `Rscript TaxonBodyMass_DB/R/RunMe.r` run.

---

## Implementation Notes

**Total agents (v2 run):** 10 (audit) + 1 (synthesis) + 1 (report) + 1 (updates) + 1 (verify) = **14 agents** (setup already completed in a prior run).

**Why string concatenation, not template literals:** The workflow script builds each audit agent prompt using JavaScript string concatenation (`'...' + variable + '...'`) rather than template literals. Template literals caused a parse error when the prompt contained Python regex quantifiers (`{2,}`) and backtick-fenced code blocks, both of which conflict with the JS template literal syntax.

**Why findings are written early:** In the first workflow attempt the 10 audit agents were stopped before writing `findings_NN.json`. Synthesis then ran against empty files and produced an empty report. In v2, each agent writes its findings file immediately after the heuristic pass (before GBIF queries complete) and updates it afterwards, so synthesis always has something to work with.

**Why GBIF curl needed explicit permission:** The first workflow run was blocked because individual GBIF `curl` calls triggered permission prompts in the headless workflow environment. Adding `Bash(curl -s https://api.gbif.org/*)` to `.claude/settings.json` auto-allows all GBIF Species Match API queries.

**Workflow script path:**
```
.claude/projects/.../workflows/scripts/taxon-audit-v2-wf_ff22c464-d24.js
```
To resume or iterate: `Workflow({scriptPath: '<path>', resumeFromRunId: 'wf_ff22c464-d24'})`.
