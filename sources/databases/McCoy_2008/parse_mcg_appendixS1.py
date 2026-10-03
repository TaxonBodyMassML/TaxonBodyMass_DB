#!/usr/bin/env python3
"""Parse McCoy & Gillooly (2008, Ecol Lett 11:710) Appendix S1 into a CSV.

Appendix S1 (Wiley supplementary file ELE_1190_sm_AppendixS1, a Word document;
the PDF export read here is tmp/ele_1190_sm_appendixs1.pdf and is not
committed, see README.md) is the 68-page 'Temperature, Body Mass, and
Mortality data with Sources': a table with the columns Group | Species |
Dry mass (g) | Temp. C | *Mortality (y-1) | Ref. on pages 1-66, followed by a
footnote on Fregata magnificens and the numbered list of 29 data references
(pages 66-68). The header note states "Dry mass was calculated as 1/4*wet mass."

We run `pdftotext -layout` and read the pages line by line. Every table row has
exactly one 'number line', the line carrying the dry mass in E-notation. Cells
that wrap are printed on text-only lines centred on that line: a two-line
species cell gives genus / numbers / epithet, a two-line group cell gives
'Multicellular' / numbers / 'plant', and a three-line cell puts its middle line
on the number line. Rows never cross a page break. The parser therefore gives
each number line the k text-only lines before it (those not claimed by the
previous row) and the same number k after it, and joins the group-column and
species-column segments of those lines in order. The group column is the set
of known group words at the left margin; everything else left of the mass is
species text. The numbers right of the mass are assigned to the Temp /
Mortality / Ref columns by horizontal position (column centres taken per page
from the complete rows), which handles blank cells (a missing temperature,
missing mortality rates, one missing reference), and the assignment is
cross-checked against the print format (mortality has three decimals,
temperatures at most two, references are comma lists of integers). A
reference glued to the mortality value (e.g. '0.1655' = 0.165 and ref 5) is
split off after the third decimal.

Usage: parse_mcg_appendixS1.py [PDF | pdftotext -layout dump (.txt)]
       default: ../../../tmp/ele_1190_sm_appendixs1.pdf relative to this script
Output: McCoy_2008_appendixS1.csv next to this script, one row per table row,
columns group, species_printed, dry_mass_g, temp_C, mortality_y, ref, page
(values as printed, whitespace normalised; page = PDF page). Per-group row
counts and every anomaly go to stderr; the script exits non-zero if a page
cannot be assembled into rows.
"""
import csv
import os
import re
import subprocess
import sys
from collections import Counter, OrderedDict

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_PDF = os.path.join(HERE, '..', '..', '..', 'tmp', 'ele_1190_sm_appendixs1.pdf')
OUT_CSV = os.path.join(HERE, 'McCoy_2008_appendixS1.csv')

GROUP_WORDS = ('Bird', 'Fish', 'Invertebrate', 'Mammal', 'Multicellular', 'plant', 'Phytoplankton')
GROUPS = ('Bird', 'Fish', 'Invertebrate', 'Mammal', 'Multicellular plant', 'Phytoplankton')
MASS_RE = re.compile(r'-?\d\.\d{3}E[+-]\d{2}')
RUNNING_HEADER_RE = re.compile(r'^\s*Predicting Mortality Rates\s+McCoy & Gillooly\s*$')
COLUMN_HEADER_RE = re.compile(r'^\s*Group\s+Species\s+Dry mass')
FOOTNOTE_RE = re.compile(r'^\s*Data for Fregata')
TOKEN_RE = re.compile(r'\S+')
REF_RE = re.compile(r'^\d+(?:,\d+)*$')
TEMP_RE = re.compile(r'^-?\d+(?:\.\d{1,2})?$')
MORT_RE = re.compile(r'^\d+\.\d{3}$')
GLUED_RE = re.compile(r'^(\d+\.\d{3})(\d+(?:,\d+)*)$')   # mortality with the reference glued on
N_REFS = 29


def log(msg):
    print(msg, file=sys.stderr)


def load_text(path):
    if path.lower().endswith('.txt'):
        with open(path, encoding='utf-8') as fh:
            return fh.read()
    res = subprocess.run(['pdftotext', '-layout', path, '-'], capture_output=True, text=True, check=True)
    return res.stdout


def tokens(line):
    """(start, end, text) for every whitespace-delimited token of a line."""
    return [(m.start(), m.end(), m.group()) for m in TOKEN_RE.finditer(line)]


def split_line(line):
    """Split a physical line into group tokens, species tokens and number tokens.

    Group tokens are known group words that come before any other text on the
    line (the group column is the leftmost one); number tokens are the mass
    (E-notation) and everything right of it; the rest is species text.
    """
    toks = tokens(line)
    m = MASS_RE.search(line)
    mass_start = m.start() if m else None
    group, species, numbers = [], [], []
    for start, end, text in toks:
        if mass_start is not None and start >= mass_start:
            numbers.append((start, end, text))
        elif text in GROUP_WORDS and not species:
            group.append(text)
        else:
            species.append(text)
    return group, species, numbers


def assemble_rows(page_lines, page_no, errors):
    """Group the lines of one page into table rows (see module docstring)."""
    rows, pending, current, need_below = [], [], None, 0
    for line in page_lines:
        if MASS_RE.search(line):
            if need_below:
                errors.append(f'page {page_no}: row ending {current["num"].strip()[:60]!r} is short '
                              f'{need_below} text line(s) below it')
                need_below = 0
            current = {'above': pending, 'num': line, 'below': [], 'page': page_no}
            rows.append(current)
            pending = []
            need_below = len(current['above'])
        elif need_below:
            current['below'].append(line)
            need_below -= 1
        else:
            pending.append(line)
    if pending or need_below:
        errors.append(f'page {page_no}: {len(pending)} unattached text line(s) at page end '
                      f'{[p.strip() for p in pending]!r}; {need_below} missing below the last row')
    return rows


def classify_numbers(numbers, centres, page_no, species, warnings):
    """Map the tokens right of the mass to temp, mortality and ref by column position."""
    mass = numbers[0][2]
    rest = numbers[1:]
    out = {'temp': '', 'mort': '', 'ref': ''}
    if not rest:
        return mass, out
    if len(rest) > 3:
        warnings.append(f'page {page_no} {species!r}: {len(rest)} tokens after the mass {rest!r}')
        rest = rest[:3]
    if len(rest) == 3:
        assigned = list(zip(('temp', 'mort', 'ref'), rest))
    else:
        assigned = []
        for start, end, text in rest:
            centre = (start + end) / 2
            col = min(centres, key=lambda c: abs(centres[c] - centre))
            assigned.append((col, (start, end, text)))
    for col, (start, end, text) in assigned:
        if out[col]:
            warnings.append(f'page {page_no} {species!r}: two tokens in the {col} column {rest!r}')
        out[col] = text
    # A reference glued to the mortality value (no separate ref token).
    if out['mort'] and not out['ref']:
        g = GLUED_RE.match(out['mort'])
        if g:
            out['mort'], out['ref'] = g.group(1), g.group(2)
            warnings.append(f'page {page_no} {species!r}: split glued reference {g.group(0)!r} -> '
                            f'{out["mort"]} / {out["ref"]}')
    # Cross-check against the print format.
    if out['temp'] and not TEMP_RE.match(out['temp']):
        warnings.append(f'page {page_no} {species!r}: temperature {out["temp"]!r} not in print format')
    if out['mort'] and not MORT_RE.match(out['mort']):
        warnings.append(f'page {page_no} {species!r}: mortality {out["mort"]!r} not in print format')
    if out['ref']:
        if not REF_RE.match(out['ref']):
            warnings.append(f'page {page_no} {species!r}: reference {out["ref"]!r} not in print format')
        elif not all(1 <= int(r) <= N_REFS for r in out['ref'].split(',')):
            warnings.append(f'page {page_no} {species!r}: reference {out["ref"]!r} outside 1-{N_REFS}')
    return mass, out


def column_centres(rows):
    """Median centre of the temp, mortality and ref columns from the complete rows of a page."""
    acc = {'temp': [], 'mort': [], 'ref': []}
    for row in rows:
        _, _, numbers = split_line(row['num'])
        rest = numbers[1:]
        if len(rest) == 3 and TEMP_RE.match(rest[0][2]) and MORT_RE.match(rest[1][2]) and REF_RE.match(rest[2][2]):
            for col, (start, end, _) in zip(('temp', 'mort', 'ref'), rest):
                acc[col].append((start + end) / 2)
    if not all(acc.values()):
        return None
    return {col: sorted(v)[len(v) // 2] for col, v in acc.items()}


def main(argv):
    path = argv[1] if len(argv) > 1 else DEFAULT_PDF
    if not os.path.exists(path):
        sys.exit(f'input not found: {path}\n(download ELE_1190_sm_AppendixS1 from the Wiley page of '
                 f'doi:10.1111/j.1461-0248.2008.01190.x, export it to PDF and pass the path; see README.md)')
    text = load_text(path)
    pages = text.split('\f')
    log(f'{os.path.basename(path)}: {len(pages)} pages')

    errors, warnings, records = [], [], []
    in_table, done = False, False
    footnote = []
    for page_no, page in enumerate(pages, 1):
        if done:
            break
        lines = []
        for line in page.split('\n'):
            if not line.strip() or RUNNING_HEADER_RE.match(line):
                continue
            if not in_table:
                if COLUMN_HEADER_RE.match(line):
                    in_table = True
                continue
            if FOOTNOTE_RE.match(line):
                done = True
            if done:
                if line.strip().startswith('Data References'):
                    break
                footnote.append(line.strip())
                continue
            lines.append(line)
        if not lines:
            continue
        rows = assemble_rows(lines, page_no, errors)
        centres = column_centres(rows)
        for row in rows:
            group_parts, species_parts = [], []
            for line in row['above'] + [row['num']] + row['below']:
                g, s, _ = split_line(line)
                group_parts += g
                species_parts += s
            group = ' '.join(group_parts)
            species = ' '.join(species_parts)
            _, _, numbers = split_line(row['num'])
            if centres is None and len(numbers) not in (1, 4):
                warnings.append(f'page {page_no} {species!r}: no complete row on the page to place '
                                f'{numbers!r}; left blank')
                mass, vals = numbers[0][2], {'temp': '', 'mort': '', 'ref': ''}
            else:
                mass, vals = classify_numbers(numbers, centres, page_no, species, warnings)
            if group not in GROUPS:
                warnings.append(f'page {page_no} {species!r}: unexpected group {group!r}')
            if not species:
                warnings.append(f'page {page_no}: row {row["num"].strip()!r} has no species text')
            records.append(OrderedDict(group=group, species_printed=species, dry_mass_g=mass,
                                       temp_C=vals['temp'], mortality_y=vals['mort'], ref=vals['ref'],
                                       page=page_no))
    if not in_table:
        errors.append('column header line (Group  Species  Dry mass ...) not found')
    if not done:
        errors.append('footnote line (Data for Fregata ...) not found; table end undetected')

    with open(OUT_CSV, 'w', newline='', encoding='utf-8') as fh:
        w = csv.DictWriter(fh, fieldnames=list(records[0].keys()), lineterminator='\n')
        w.writeheader()
        w.writerows(records)

    counts = Counter(r['group'] for r in records)
    log(f'{len(records)} rows written to {os.path.relpath(OUT_CSV)}')
    for g in GROUPS:
        log(f'  {g:<20s} {counts.get(g, 0):5d}')
    for g in sorted(set(counts) - set(GROUPS)):
        log(f'  {g!r:<20s} {counts[g]:5d}  (unexpected)')
    log(f'  missing temp {sum(1 for r in records if not r["temp_C"])}, '
        f'missing mortality {sum(1 for r in records if not r["mortality_y"])}, '
        f'missing ref {sum(1 for r in records if not r["ref"])}')
    few_words = [r for r in records if r['group'] != 'Phytoplankton' and len(r['species_printed'].split()) < 2]
    if few_words:
        log(f'  {len(few_words)} row(s) with a one-word species: ' +
            '; '.join(f'{r["species_printed"]} (p.{r["page"]})' for r in few_words))
    if footnote:
        log('  footnote: ' + ' '.join(footnote))
    for w_ in warnings:
        log('  WARNING ' + w_)
    for e in errors:
        log('  ERROR ' + e)
    return 1 if errors else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
