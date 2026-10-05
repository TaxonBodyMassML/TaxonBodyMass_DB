#!/usr/bin/env python3
"""Parse McCoy & Gillooly (2008, Ecol Lett 11:710) Appendix S1 into a CSV.

Appendix S1 is the 68-page 'Temperature, Body Mass, and Mortality data with
Sources': a table with the columns Group | Species | Dry mass (g) | Temp. C |
*Mortality (y-1) | Ref. on pages 1-66, followed by a footnote on Fregata
magnificens and the numbered list of data references (pages 66-68). The header
note states "Dry mass was calculated as 1/4*wet mass." Two versions exist, both
Wiley supplementary files that are not committed (see README.md):

  ELE_1190_sm_AppendixS1  the original (2008; Word document, exported to PDF as
                          tmp/ele_1190_sm_appendixs1.pdf): 29 data references,
                          table rows never cross a page break;
  ele_1338_sm_appendixs1  the corrected appendix of the 2009 erratum (Ecol Lett
                          12:731-733; publisher PDF, tmp/ele_1338_sm_appendixs1.pdf,
                          the default input): 30 data references (ref 8 replaced,
                          ref 30 added), wrapped rows may straddle a page break.

We run `pdftotext -layout` and read the table pages line by line. Every table
row has exactly one 'number line', the line carrying the dry mass in
E-notation. Cells that wrap are printed on text-only lines centred on that
line: a two-line species cell gives genus / numbers / epithet, a two-line group
cell gives 'Multicellular' / numbers / 'plant', and a three-line cell puts its
middle line on the number line. The parser therefore gives each number line
the k text-only lines before it (those not claimed by the previous row) and
the same number k after it, and joins the group-column and species-column
segments of those lines in order. Lines are assembled across the whole table,
so a row whose number line is the last line of a page is completed by the
first text line(s) of the next page (the erratum PDF has 28 such rows; the
row's `page` is that of its number line). The group column is the set of known
group words at the left margin; everything else left of the mass is species
text. The numbers right of the mass are assigned to the Temp / Mortality / Ref
columns by horizontal position (column centres taken per page from the
complete rows), which handles blank cells (a missing temperature, missing
mortality rates, one missing reference), and the assignment is cross-checked
against the print format (mortality has three decimals, temperatures at most
two, references are comma lists of integers). A reference glued to the
mortality value (e.g. '0.1655' = 0.165 and ref 5) is split off after the third
decimal.

The numbered 'Data References' are read as well (verbatim, whitespace
normalised, line-wrapped hyphens rejoined, two hyperlink-rendering artefacts of
the erratum PDF dropped): their count bounds the reference codes, and each
citation is compared with the `citation` column of appendixS1_references.csv
next to this script, so that a changed reference list is reported (the DOI
column of that file is curated by hand and is not written here).

Usage: parse_mcg_appendixS1.py [PDF | pdftotext -layout dump (.txt)] [output CSV]
       default input: ../../../tmp/ele_1338_sm_appendixs1.pdf relative to this script
Output: McCoy_2008_appendixS1.csv next to this script (or the given path), one
row per table row, columns group, species_printed, dry_mass_g, temp_C,
mortality_y, ref, page (values as printed, whitespace normalised; page = PDF
page of the number line). Per-group row counts, the reference list and every
anomaly go to stderr; the script exits non-zero if the table cannot be
assembled into rows.
"""
import csv
import os
import re
import subprocess
import sys
from collections import Counter, OrderedDict

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_PDF = os.path.join(HERE, '..', '..', '..', 'tmp', 'ele_1338_sm_appendixs1.pdf')
OUT_CSV = os.path.join(HERE, 'McCoy_2008_appendixS1.csv')
REFS_CSV = os.path.join(HERE, 'appendixS1_references.csv')

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
# Reference list: '12.  Author AB, ...' ('30  Taylor, C.C. ...' lacks the period in the erratum).
REF_START_RE = re.compile(r'^\s*(\d{1,2})\.?\s+(\S.*)$')
# A reference number glued to the end of the previous reference ('... 58: 45-52.9. Stephens C,').
REF_GLUED_RE = re.compile(r'(?<=\d\.)\s*(\d{1,2})\.\s+(?=[A-Z][a-z]+ [A-Z]+,)')
REF_ARTEFACT_RE = re.compile(r'^[0-9A-Z]{1,2}$')          # hyperlink glyph remnants ('0U', 'H')


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


MAX_SPECIES_WORDS = 4   # 'Tropical Atlantic phytoplankton communities', 'Sula (= Morus) bassanus'


def row_text(row, extra_below=()):
    """(group, species) of a row from its text lines, in reading order."""
    group_parts, species_parts = [], []
    for line in row['above'] + [row['num']] + row['below'] + list(extra_below):
        g, s, _ = split_line(line)
        group_parts += g
        species_parts += s
    return ' '.join(group_parts), ' '.join(species_parts)


def row_plausible(row, extra_below=()):
    """A correctly assembled row has a known group and a species of 1-4 words."""
    group, species = row_text(row, extra_below)
    return group in GROUPS and 0 < len(species.split()) <= MAX_SPECIES_WORDS


def assemble_page(lines, page_no, need_below):
    """Group the text lines of one page into rows (see the module docstring).

    The first `need_below` lines complete the row that ended the previous page.
    Returns (lines taken for that row, rows started on this page, how many
    lines the last row still needs from the next page, text lines left
    unattached at the page end, number of rows found short of text lines).
    """
    rows, pending, current, carry_lines, short = [], [], None, [], 0
    for line in lines:
        if MASS_RE.search(line):
            if need_below:
                short += 1
                need_below = 0
            current = {'above': pending, 'num': line, 'below': [], 'page': page_no, 'pages': {page_no}}
            rows.append(current)
            pending = []
            need_below = len(current['above'])
        elif need_below:
            if current is None:
                carry_lines.append(line)
            else:
                current['below'].append(line)
            need_below -= 1
        else:
            pending.append(line)
    return carry_lines, rows, need_below, pending, short


def assemble_rows(table_lines, errors, warnings):
    """Group the table lines, given as (page, line) in reading order, into rows.

    Pages are assembled one by one under the symmetric rule. In the erratum PDF
    a wrapped row may straddle a page break: either its number line (with the
    lines above it) ends the page and the lines below follow on the next page,
    which the symmetric rule handles by carrying the row over, or the first line
    of a wrapped cell is printed on the number line at the foot of the page and
    the remaining line(s) open the next page ('Mammal  Babyrousa  2.500E+04 ...'
    / 'babyrussa'; 'Multicellular  Acacia victoriae ...' / 'plant'; 'Phytoplankton
    Tropical Atlantic ...' / 'phytoplankton' / 'communities'), which the symmetric
    rule cannot see. After a page that ends in a number line, the next page is
    therefore assembled under the hypotheses that 0, 1 or 2 of its leading text
    lines belong to that last row, and the hypotheses are searched across the
    pages (depth first, fewest lines first) for the assignment in which no row is
    short of text lines, no line is left unattached, every row has a known group
    and a species of 1-4 words, and the table ends complete: a wrong count
    cascades through the page and breaks one of these conditions, sometimes only
    on the next page. The original 2008 PDF, whose rows never straddle a page,
    assembles with 0 extra lines everywhere. A row is placed on the page of its
    number line.
    """
    pages = OrderedDict()
    for page_no, line in table_lines:
        pages.setdefault(page_no, []).append(line)
    pages = list(pages.items())

    def search(i, last_row, need_below, carried_pending):
        """Per-page (j, carry_lines, rows, pending) decisions from page i on, or None."""
        # A row whose number line ends the page is checked once the next page is seen.
        deferred = last_row is not None and (need_below > 0 or (not last_row['below'] and not carried_pending))
        if i == len(pages):
            if carried_pending or need_below or (deferred and not row_plausible(last_row)):
                return None
            return []
        page_no, lines = pages[i]
        page_lines = carried_pending + lines
        open_ended = deferred and need_below == 0
        for j in ((0, 1, 2) if open_ended else (0,)):
            head = page_lines[:j]
            if len(head) < j or any(MASS_RE.search(l) for l in head):
                continue
            carry_lines, rows, nb, pending, short = assemble_page(page_lines[j:], page_no, need_below)
            carry_lines = head + carry_lines
            if short:
                continue
            if deferred and not row_plausible(last_row, carry_lines):
                continue
            complete = rows[:-1] if rows and (nb or (not rows[-1]['below'] and not pending)) else rows
            if not all(row_plausible(r) for r in complete):
                continue
            rest = search(i + 1, rows[-1] if rows else last_row, nb, pending)
            if rest is not None:
                return [(page_no, j, carry_lines, rows, pending)] + rest
        return None

    decisions = search(0, None, 0, [])
    if decisions is None:
        warnings.append('no consistent assembly of the table found; falling back to the symmetric rule '
                        'without lines carried across page breaks')
        decisions, last_row, need_below, carried_pending = [], None, 0, []
        for page_no, lines in pages:
            page_lines = carried_pending + lines
            carry_lines, rows, nb, pending, short = assemble_page(page_lines, page_no, need_below)
            if short:
                errors.append(f'page {page_no}: {short} row(s) short of text lines below them')
            decisions.append((page_no, 0, carry_lines, rows, pending))
            last_row, need_below, carried_pending = (rows[-1] if rows else last_row), nb, pending
        if carried_pending or need_below:
            errors.append(f'{len(carried_pending)} unattached text line(s) at the table end '
                          f'{[l.strip() for l in carried_pending]!r}; {need_below} missing below the last row')

    all_rows, straddled, last_row = [], 0, None
    for page_no, j, carry_lines, rows, pending in decisions:
        if carry_lines:
            last_row['below'] += carry_lines
            last_row['pages'].add(page_no)
            straddled += 1
            if j:
                warnings.append(f'page {page_no}: first {j} line(s) {[l.strip() for l in carry_lines[:j]]!r} '
                                f'complete the last row of page {last_row["page"]}')
        if pending:
            warnings.append(f'page {page_no}: {len(pending)} text line(s) at the page end carried to the next page')
        all_rows += rows
        if rows:
            last_row = rows[-1]
    return all_rows, straddled


def classify_numbers(numbers, centres, page_no, species, warnings, n_refs):
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
        elif not all(1 <= int(r) <= n_refs for r in out['ref'].split(',')):
            warnings.append(f'page {page_no} {species!r}: reference {out["ref"]!r} outside 1-{n_refs}')
    return mass, out


def column_centres(rows):
    """Median centre of the temp, mortality and ref columns from the complete rows given."""
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


def parse_references(lines, warnings):
    """Join the numbered 'Data References' (verbatim, whitespace normalised)."""
    refs, cur = OrderedDict(), None
    for line in lines:
        text = line.strip()
        if not text:
            continue
        if REF_ARTEFACT_RE.match(text):
            warnings.append(f'reference list: dropped artefact line {text!r}')
            continue
        m = REF_START_RE.match(line)
        if m and (cur is None or int(m.group(1)) == cur + 1):
            cur = int(m.group(1))
            refs[cur] = m.group(2).strip()
        elif cur is None:
            warnings.append(f'reference list: text before the first reference {text!r}')
        else:
            refs[cur] += ' ' + text
        # The next reference number glued to the end of the text ('... 58: 45-52.9. Stephens C,').
        if cur is not None:
            g = REF_GLUED_RE.search(refs[cur])
            if g and int(g.group(1)) == cur + 1:
                head, tail = refs[cur][:g.start()], refs[cur][g.end():]
                refs[cur] = head
                cur += 1
                refs[cur] = tail
                warnings.append(f'reference list: split reference {cur} off the end of reference {cur - 1}')
    out = OrderedDict()
    for k in sorted(refs):
        t = refs[k]
        t = re.sub(r'(http://\S+)- (\S+)', r'\1-\2', t)      # URL wrapped at a hyphen
        t = re.sub(r'(\d)- (\d)', r'\1-\2', t)               # page range wrapped at the hyphen
        t = re.sub(r'\.html\.\s+H$', '.html.', t)            # trailing hyperlink glyph (erratum, ref 25)
        out[k] = ' '.join(t.split())
    if sorted(out) != list(range(1, len(out) + 1)):
        warnings.append(f'reference list: numbers are not 1..n: {sorted(out)}')
    return out


def compare_references(refs, warnings):
    """Report differences between the parsed citations and appendixS1_references.csv."""
    if not os.path.exists(REFS_CSV):
        warnings.append(f'{os.path.basename(REFS_CSV)} not found; reference list not compared')
        return
    with open(REFS_CSV, newline='', encoding='utf-8') as fh:
        committed = {int(r['ref']): r['citation'] for r in csv.DictReader(fh)}
    for k in sorted(set(refs) | set(committed)):
        if k not in committed:
            warnings.append(f'reference {k} is not in {os.path.basename(REFS_CSV)}: {refs[k]!r}')
        elif k not in refs:
            warnings.append(f'reference {k} of {os.path.basename(REFS_CSV)} is not in the PDF')
        elif ' '.join(refs[k].split()) != ' '.join(committed[k].split()):
            warnings.append(f'reference {k} differs from {os.path.basename(REFS_CSV)}:\n'
                            f'      PDF: {refs[k]}\n      CSV: {committed[k]}')


def main(argv):
    path = argv[1] if len(argv) > 1 else DEFAULT_PDF
    out_csv = argv[2] if len(argv) > 2 else OUT_CSV
    if not os.path.exists(path):
        sys.exit(f'input not found: {path}\n(download the appendix from the Wiley page of '
                 f'doi:10.1111/j.1461-0248.2009.01338.x (erratum) or doi:10.1111/j.1461-0248.2008.01190.x '
                 f'(original, a Word file to export to PDF) and pass the path; see README.md)')
    text = load_text(path)
    pages = text.split('\f')
    log(f'{os.path.basename(path)}: {len(pages)} pages')

    errors, warnings, records = [], [], []
    in_table, done = False, False
    table_lines, footnote, ref_lines = [], [], []
    in_refs = False
    for page_no, page in enumerate(pages, 1):
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
                if in_refs:
                    ref_lines.append(line)
                elif line.strip().startswith('Data References'):
                    in_refs = True
                else:
                    footnote.append(line.strip())
                continue
            table_lines.append((page_no, line))
    if not in_table:
        errors.append('column header line (Group  Species  Dry mass ...) not found')
    if not done:
        errors.append('footnote line (Data for Fregata ...) not found; table end undetected')

    refs = parse_references(ref_lines, warnings)
    n_refs = len(refs)
    if not refs:
        warnings.append('no Data References found; reference codes not bounded')
        n_refs = 99
    compare_references(refs, warnings)

    rows, straddled = assemble_rows(table_lines, errors, warnings)
    by_page = {}
    for row in rows:
        by_page.setdefault(row['page'], []).append(row)
    for page_no, page_rows in by_page.items():
        centres = column_centres(page_rows)
        for row in page_rows:
            group, species = row_text(row)
            _, _, numbers = split_line(row['num'])
            if centres is None and len(numbers) not in (1, 4):
                warnings.append(f'page {page_no} {species!r}: no complete row on the page to place '
                                f'{numbers!r}; left blank')
                mass, vals = numbers[0][2], {'temp': '', 'mort': '', 'ref': ''}
            else:
                mass, vals = classify_numbers(numbers, centres, page_no, species, warnings, n_refs)
            if group not in GROUPS:
                warnings.append(f'page {page_no} {species!r}: unexpected group {group!r}')
            if not species:
                warnings.append(f'page {page_no}: row {row["num"].strip()!r} has no species text')
            records.append(OrderedDict(group=group, species_printed=species, dry_mass_g=mass,
                                       temp_C=vals['temp'], mortality_y=vals['mort'], ref=vals['ref'],
                                       page=page_no))

    with open(out_csv, 'w', newline='', encoding='utf-8') as fh:
        w = csv.DictWriter(fh, fieldnames=list(records[0].keys()), lineterminator='\n')
        w.writeheader()
        w.writerows(records)

    counts = Counter(r['group'] for r in records)
    log(f'{len(records)} rows written to {os.path.relpath(out_csv)}')
    for g in GROUPS:
        log(f'  {g:<20s} {counts.get(g, 0):5d}')
    for g in sorted(set(counts) - set(GROUPS)):
        log(f'  {g!r:<20s} {counts[g]:5d}  (unexpected)')
    log(f'  missing temp {sum(1 for r in records if not r["temp_C"])}, '
        f'missing mortality {sum(1 for r in records if not r["mortality_y"])}, '
        f'missing ref {sum(1 for r in records if not r["ref"])}')
    log(f'  {straddled} row(s) wrapped across a page break')
    few_words = [r for r in records if r['group'] != 'Phytoplankton' and len(r['species_printed'].split()) < 2]
    if few_words:
        log(f'  {len(few_words)} row(s) with a one-word species: ' +
            '; '.join(f'{r["species_printed"]} (p.{r["page"]})' for r in few_words))
    if footnote:
        log('  footnote: ' + ' '.join(footnote))
    log(f'  {n_refs} data references' + (': ' if refs else ''))
    for k, t in refs.items():
        log(f'    {k:2d}. {t}')
    for w_ in warnings:
        log('  WARNING ' + w_)
    for e in errors:
        log('  ERROR ' + e)
    return 1 if errors else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
