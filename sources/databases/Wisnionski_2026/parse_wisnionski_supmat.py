#!/usr/bin/env python3
"""Parse the Wisnionski et al. (2026, Ecol Evol 16:e74243) Supporting Information PDF.

`ece374243-sup-0001-supinfo.pdf` (22 pages, CC BY 4.0) holds Table S1 (pages 2-5,
landscape): one row per species with body mass (g), mass-specific metabolic rate,
lifespan, each followed by its bracketed reference number ("421 [1]"), the
corticosterone data and, last in the row, the reference of the corticosterone
study; then the numbered reference list 1-132 (pages 6-18), Figure S1, Table S2
and Figure S2. The data files (VertData_*.csv) carry no reference column, so
Table S1 is the only record of where each body mass comes from.

Read with PyMuPDF (`fitz`): every word has a bounding box and the table columns
sit at the same x positions on all four pages (species from x 76; mass right-
aligned ending near x 206; its reference bracket starting at x 217-221; the MSMR
reference at x 286-288; the lifespan reference at x 342). A table row is the set
of words sharing a baseline (within 3 pt); the species name is the run of words
before the first number or bracket, with the juvenile mark `^` and the serum
mark `*` split off. A reference bracket wrapped over three lines ("[56,1" /
"02]" on Thalassarche melanophris) is re-joined from the fragments found in the
mass-reference column of the neighbouring lines. The reference list is read line
by line after dropping the manuscript line numbers in the left margin (x < 60):
a line whose first word is "N." opens entry N, the following lines continue it
(the centred page number at the foot of each page is skipped);
lines are joined with one space, or with nothing when the previous line ends in
a hyphen or en dash (a DOI or a page range broken at the line end), whitespace
is collapsed and the text is otherwise kept verbatim.

Usage: parse_wisnionski_supmat.py [PDF]   (default: ece374243-sup-0001-supinfo.pdf next to this script)
Output (next to this script):
  TableS1_parsed.csv  group, subgroup ('cortisol dominant' / 'CCST dominant' for
                      the mammals), species_pdf, juvenile, serum, mass_g, mass_ref_keys,
                      msmr, msmr_ref_keys, lifespan_yr, lifespan_ref_keys,
                      cort_ref_keys ('; '-joined reference numbers; empty when the
                      cell is blank)
  references.csv      key, citation (the 132 numbered entries, verbatim)
Counts and anomalies go to stderr; the script exits non-zero when a reference
number is missing or duplicated, or when a cited key has no reference.
"""
import csv
import os
import re
import sys
from collections import Counter, defaultdict

try:
    import fitz  # PyMuPDF
except ImportError:  # pragma: no cover
    sys.exit('parse_wisnionski_supmat.py needs PyMuPDF (pip install pymupdf)')

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_PDF = os.path.join(HERE, 'ece374243-sup-0001-supinfo.pdf')
OUT_TABLE = os.path.join(HERE, 'TableS1_parsed.csv')
OUT_REFS = os.path.join(HERE, 'references.csv')

TABLE_PAGES = range(1, 5)   # 0-based: pages 2-5
REF_PAGES = range(5, 18)    # pages 6-18
# x bands of the three "value [ref]" column pairs (points; landscape page 792 wide)
BANDS = {
    'mass':     (160, 212, 212, 240),
    'msmr':     (240, 280, 280, 305),
    'lifespan': (305, 335, 335, 360),
}
CORT_REF_X0 = 735
NUM_RE = re.compile(r'^-?\d+(\.\d+)?$')
BRACKET_RE = re.compile(r'^\[[\d,\s]*\]$')
BRACKET_FRAG_RE = re.compile(r'^\[[\d,]*$|^[\d,]*\]$')
GROUP_RE = re.compile(r'^(Reptiles|Birds|Mammals)')


def lines_of(page, min_x=0):
    """Words of a page grouped by baseline (y0 within 3 pt), left to right."""
    rows = []
    for w in sorted(page.get_text('words'), key=lambda w: (round(w[1]), w[0])):
        if w[0] < min_x:
            continue
        if rows and abs(rows[-1][0] - w[1]) <= 3:
            rows[-1][1].append(w)
        else:
            rows.append([w[1], [w]])
    return [sorted(ws, key=lambda w: w[0]) for _, ws in rows]


def keys_of(bracket):
    inner = bracket.strip('[]').replace(' ', '')
    return '; '.join(k for k in inner.split(',') if k)


def parse_table(doc):
    out, group, subgroup, log = [], None, '', []
    for pno in TABLE_PAGES:
        lines = lines_of(doc[pno])
        # fragments of a bracket wrapped over several lines, by line index
        frags = {}
        for i, ws in enumerate(lines):
            for w in ws:
                if BANDS['mass'][2] <= w[0] < BANDS['mass'][3] and BRACKET_FRAG_RE.match(w[4]) \
                        and not BRACKET_RE.match(w[4]):
                    frags[i] = w[4]
        for i, ws in enumerate(lines):
            text = ' '.join(w[4] for w in ws)
            m = GROUP_RE.match(text)
            if m and ws[0][0] < 80:
                group, subgroup = m.group(1), text[len(m.group(1)):].strip(', ')
                continue
            # a data row starts at the species column and holds a reference bracket
            if ws[0][0] > 80 or not any(BRACKET_RE.match(w[4]) or BRACKET_FRAG_RE.match(w[4]) for w in ws):
                continue
            name_words = []
            for w in ws:
                if NUM_RE.match(w[4]) or w[4].startswith('[') or w[0] >= BANDS['mass'][0]:
                    break
                name_words.append(w[4])
            species = ' '.join(name_words)
            if not species:
                continue
            juvenile = '^' in species
            serum = '*' in species
            species = species.replace('^', '').replace('*', '').strip()
            rec = {'group': group, 'subgroup': subgroup, 'species_pdf': species,
                   'juvenile': 'TRUE' if juvenile else 'FALSE',
                   'serum': 'TRUE' if serum else 'FALSE'}
            for col, (vx0, vx1, rx0, rx1) in BANDS.items():
                val = [w[4] for w in ws if vx0 <= w[0] < vx1 and NUM_RE.match(w[4])]
                ref = [w[4] for w in ws if rx0 <= w[0] < rx1 and (BRACKET_RE.match(w[4]) or BRACKET_FRAG_RE.match(w[4]))]
                if col == 'mass' and not ref and any(abs(j - i) <= 1 for j in frags):
                    # the bracket is wrapped over the lines above and below this one
                    pieces = [frags[j] for j in sorted(frags) if abs(j - i) <= 1]
                    joined = ''.join(pieces)
                    log.append(f'{species}: mass reference joined from fragments {pieces} -> {joined}')
                    ref = [joined]
                if len(val) > 1 or len(ref) > 1:
                    log.append(f'{species}: several {col} tokens {val} {ref}')
                rec[{'mass': 'mass_g', 'msmr': 'msmr', 'lifespan': 'lifespan_yr'}[col]] = val[0] if val else ''
                rec[f'{col}_ref_keys'] = keys_of(ref[0]) if ref else ''
            cort = [w[4] for w in ws if w[0] >= CORT_REF_X0 and (BRACKET_RE.match(w[4]) or BRACKET_FRAG_RE.match(w[4]))]
            if not cort and any(w[0] >= CORT_REF_X0 and BRACKET_FRAG_RE.match(w[4])
                                for j in (i - 1, i + 1) if 0 <= j < len(lines) for w in lines[j]):
                pieces = []
                for j in (i - 1, i, i + 1):
                    if 0 <= j < len(lines):
                        pieces += [w[4] for w in lines[j] if w[0] >= CORT_REF_X0 and BRACKET_FRAG_RE.match(w[4])]
                cort = [''.join(pieces)]
                log.append(f'{species}: corticosterone reference joined -> {cort[0]}')
            rec['cort_ref_keys'] = keys_of(cort[0]) if cort else ''
            out.append(rec)
    return out, log


def parse_refs(doc):
    entries, cur = {}, None
    opener = re.compile(r'^(\d{1,3})\.$')
    for pno in REF_PAGES:
        for ws in lines_of(doc[pno], min_x=60):
            words = [w[4] for w in ws]
            if words == ['References'] or (len(words) == 1 and words[0].isdigit() and ws[0][0] > 90):
                continue   # the heading, or the centred page number at the foot of the page
            m = opener.match(words[0]) if ws[0][0] < 90 else None
            if m:
                cur = int(m.group(1))
                if cur in entries:
                    sys.exit(f'reference {cur} opened twice')
                entries[cur] = ' '.join(words[1:])
            elif cur is not None:
                text = ' '.join(words)
                sep = '' if entries[cur].endswith(('-', '–')) else ' '
                entries[cur] = entries[cur] + sep + text
    for k in entries:
        entries[k] = re.sub(r'\s+', ' ', entries[k]).strip()
    return entries


def main():
    pdf = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_PDF
    doc = fitz.open(pdf)
    table, log = parse_table(doc)
    refs = parse_refs(doc)
    for line in log:
        print('note:', line, file=sys.stderr)
    nums = sorted(refs)
    missing = [n for n in range(1, nums[-1] + 1) if n not in refs]
    if missing:
        sys.exit(f'reference numbers missing: {missing}')
    cited = Counter()
    for rec in table:
        for col in ('mass_ref_keys', 'msmr_ref_keys', 'lifespan_ref_keys', 'cort_ref_keys'):
            for k in rec[col].split('; '):
                if k:
                    cited[k] += 1
    unknown = sorted(k for k in cited if int(k) not in refs)
    if unknown:
        sys.exit(f'cited keys without a reference: {unknown}')
    groups = Counter(r['group'] for r in table)
    print(f'Table S1: {len(table)} rows ({dict(groups)}); with mass {sum(1 for r in table if r["mass_g"])}; '
          f'mass reference keys {len(set(k for r in table for k in r["mass_ref_keys"].split("; ") if k))}; '
          f'references {len(refs)} (1-{nums[-1]}), cited {len(cited)}', file=sys.stderr)
    cols = ['group', 'subgroup', 'species_pdf', 'juvenile', 'serum', 'mass_g', 'mass_ref_keys', 'msmr', 'msmr_ref_keys',
            'lifespan_yr', 'lifespan_ref_keys', 'cort_ref_keys']
    with open(OUT_TABLE, 'w', newline='', encoding='utf-8') as fh:
        w = csv.DictWriter(fh, fieldnames=cols)
        w.writeheader()
        for rec in table:
            w.writerow({c: rec.get(c, '') for c in cols})
    with open(OUT_REFS, 'w', newline='', encoding='utf-8') as fh:
        w = csv.writer(fh)
        w.writerow(['key', 'citation'])
        for n in nums:
            w.writerow([str(n), refs[n]])


if __name__ == '__main__':
    main()
