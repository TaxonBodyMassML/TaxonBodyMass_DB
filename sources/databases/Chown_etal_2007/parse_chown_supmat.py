#!/usr/bin/env python3
"""Parse the Chown et al. (2007, Funct Ecol 21:282) Supporting Information PDF.

The Wiley supplement `fec1245_supmat.pdf` (36 A4 pages) holds three parts:

* Appendix S1 (pages 1-5, portrait): per-individual metabolic rate data for
  eight species of size-polymorphic ants, columns Species | Temperature |
  Mass (mg) | Metabolic rate (uW), no reference marks.
* Appendix S2 (pages 6-30, landscape): the literature compilation of insect
  body masses and metabolic rates, columns Species | Family | Order | Method |
  Wing status | Mass (mg) | Metabolic rate (uW). Every row cites its source
  as a superscript number appended to the species name (`Anax junius^1`), or
  carries a trailing asterisk for the compilers' own unpublished measurements
  (footnote "* Chown lab, unpublished data."). The Wing status cell is blank
  on a few rows.
* References (pages 31-36): the numbered list 1-115 the superscripts refer to.

The PDF is read with PyMuPDF (`fitz`), not `pdftotext`, because only the font
information tells a superscript reference number apart from the species text
(the superscripts are 6.5 pt with the superscript flag set; the body is
10.1 pt), and `pdftotext -layout` additionally wraps long species names onto a
second line and splits numbers ("5686. 9"). In the PDF every table cell is one
text line with its own bounding box, so a table row is the set of cells that
share a baseline (within 3 pt) and the column of a cell is decided by its left
edge against the column edges, which are read from the table's empty spacer
rows (seven blank cells per row, one per column). The reference list is read
line by line: a line starting at the left margin with "N." opens entry N, the
indented lines continue it; the lines of an entry are joined with one space
(no space after a hyphen that breaks a page range, "4309-" + "4315"), runs of
whitespace are collapsed, and the text is otherwise kept verbatim.

Usage: parse_chown_supmat.py [PDF]      (default: fec1245_supmat.pdf next to this script)
Output (next to this script):
  AppendixS1_ant_mass_parsed.csv     Species, Temperature_C, Mass_mg, MetabolicRate_uW
  AppendixS2_insect_mass_parsed.csv  Species, Family, Order, Method, WingStatus, Mass_mg,
                                     MetabolicRate_uW, ref_keys ('; '-joined reference
                                     numbers, '*' for the unpublished Chown-lab rows)
  references.csv                     key, raw_citation (the 115 numbered entries, then key '*'
                                     with the footnote text of the unpublished rows)
Values are kept as printed (whitespace normalised; the species text without its
superscript, the asterisk kept as printed). Counts and every anomaly go to
stderr; the script exits non-zero if a row cannot be assembled, a reference
number is missing or duplicated, or a cited key has no reference.
"""
import csv
import os
import re
import sys
from collections import Counter

try:
    import fitz  # PyMuPDF
except ImportError:  # pragma: no cover
    sys.exit('parse_chown_supmat.py needs PyMuPDF (pip install pymupdf)')

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_PDF = os.path.join(HERE, 'fec1245_supmat.pdf')
OUT_S1 = os.path.join(HERE, 'AppendixS1_ant_mass_parsed.csv')
OUT_S2 = os.path.join(HERE, 'AppendixS2_insect_mass_parsed.csv')
OUT_REFS = os.path.join(HERE, 'references.csv')

ROW_TOL = 3.0            # pt: cells whose top edges differ by less belong to one row
SUP_SIZE = 8.0           # pt: a span smaller than this (and flagged superscript) is a reference mark
NUM_RE = re.compile(r'^-?\d+(?:\.\d+)?$')
REF_START_RE = re.compile(r'^(\d+)\.$')
S1_TITLE = 'Appendix S1.'
S2_TITLE = 'Appendix S2.'
REF_TITLE = 'References'


def log(msg):
    print(msg, file=sys.stderr)


def norm(s):
    return re.sub(r'\s+', ' ', s).strip()


class Cell:
    """One text line of the PDF: its box, its body text and its superscript text."""

    __slots__ = ('x0', 'x1', 'y0', 'text', 'sup', 'raw')

    def __init__(self, line):
        self.x0, self.y0, self.x1 = line['bbox'][0], line['bbox'][1], line['bbox'][2]
        body, sup, raw = [], [], []
        for s in line['spans']:
            raw.append(s['text'])
            if s['size'] < SUP_SIZE and (s['flags'] & 1):
                sup.append(s['text'])
            else:
                body.append(s['text'])
        self.text = norm(''.join(body))
        self.sup = norm(''.join(sup))
        self.raw = ''.join(raw)

    @property
    def blank(self):
        return not self.text and not self.sup


def page_cells(page):
    cells = []
    for block in page.get_text('dict')['blocks']:
        for line in block.get('lines', []):
            cells.append(Cell(line))
    return cells


def group_rows(cells):
    """Cells sharing a baseline (top edge within ROW_TOL) form one row; rows top to bottom."""
    rows = []
    for c in sorted(cells, key=lambda c: (c.y0, c.x0)):
        if rows and abs(c.y0 - rows[-1][0].y0) <= ROW_TOL:
            rows[-1].append(c)
        else:
            rows.append([c])
    return [sorted(r, key=lambda c: c.x0) for r in rows]


def is_page_number(row):
    cells = [c for c in row if not c.blank]
    return len(cells) == 1 and NUM_RE.match(cells[0].text) and cells[0].y0 > 780


def column_edges(rows, n_cols):
    """Left edges of the table columns from the blank spacer rows (n_cols blank cells each)."""
    xs = [c.x0 for r in rows if len(r) == n_cols and all(c.blank for c in r) for c in r]
    if not xs:
        return None
    xs.sort()
    clusters = [[xs[0]]]
    for x in xs[1:]:
        if x - clusters[-1][-1] <= 2.0:
            clusters[-1].append(x)
        else:
            clusters.append([x])
    if len(clusters) != n_cols:
        raise ValueError(f'expected {n_cols} column edges from the spacer rows, found {len(clusters)}: '
                         + ', '.join(f'{min(c):.1f}' for c in clusters))
    return [min(c) for c in clusters]


def assign_columns(row, edges):
    """Map the non-blank cells of a row to column indices by their left edge."""
    out = {}
    for c in row:
        if c.blank:
            continue
        col = max([0] + [i for i, e in enumerate(edges) if c.x0 >= e - 2.0])
        if col in out:
            raise ValueError(f'two cells in column {col}: {out[col].raw!r} and {c.raw!r}')
        out[col] = c
    return out


def split_sup(sup):
    """Reference marks '16', '6,7' or '6-8' -> list of numbers (ranges expanded, logged)."""
    keys = []
    for part in re.split(r'[,;]\s*', sup):
        part = part.strip()
        if not part:
            continue
        m = re.match(r'^(\d+)\s*[-–]\s*(\d+)$', part)
        if m:
            a, b = int(m.group(1)), int(m.group(2))
            log(f'  range superscript {part!r} expanded to {a}-{b}')
            keys.extend(str(k) for k in range(a, b + 1))
        elif part.isdigit():
            keys.append(part)
        else:
            raise ValueError(f'unreadable superscript {sup!r}')
    return keys


def parse_s1(pages, errors):
    rows_out, skipped = [], []
    for pno, page in pages:
        for row in group_rows(page_cells(page)):
            cells = [c for c in row if not c.blank]
            if not cells or is_page_number(row):
                continue
            texts = [c.text for c in cells]
            if texts[0].startswith(S1_TITLE) or texts[0] == 'Species':
                continue
            nums = [t.replace(' ', '') for t in texts[1:]]
            if len(cells) == 4 and all(NUM_RE.match(t) for t in nums):
                if any(c.sup for c in cells):
                    errors.append(f'S1 page {pno}: unexpected superscript on {cells[0].raw!r}')
                if nums != texts[1:]:
                    log(f'  S1 page {pno}: {texts[0]!r}: space inside a number ({texts[1:]}) removed')
                rows_out.append({'Species': texts[0], 'Temperature_C': nums[0],
                                 'Mass_mg': nums[1], 'MetabolicRate_uW': nums[2]})
            else:
                skipped.append((pno, ' | '.join(texts)))
    for pno, t in skipped:
        log(f'  S1 page {pno}: non-data line: {t}')
    return rows_out


def parse_s2(pages, errors):
    rows_out, skipped, footnotes = [], [], {}
    all_rows = [(pno, r) for pno, page in pages for r in group_rows(page_cells(page))]
    edges = column_edges([r for _, r in all_rows], 7)
    if edges is None:
        raise ValueError('S2: no spacer row with seven blank cells found')
    log('  S2 column left edges: ' + ', '.join(f'{e:.1f}' for e in edges))
    for pno, row in all_rows:
        cells = [c for c in row if not c.blank]
        if not cells or is_page_number(row):
            continue
        first = cells[0].text
        if first.startswith(S2_TITLE) or first in ('Species', 'Mass', '(mg)'):
            continue
        try:
            cols = assign_columns(row, edges)
        except ValueError as e:
            errors.append(f'S2 page {pno}: {e}')
            continue
        if not (5 in cols and 6 in cols):          # no mass and metabolic rate: not a data row
            if first.startswith('*'):              # the footnote the asterisk marks refer to
                footnotes['*'] = norm(' '.join(c.text for c in cells)[1:])
            skipped.append((pno, ' | '.join(c.text or c.sup for c in cells)))
            continue
        try:
            sp = cols[0]
            family = cols[1].text
            order = cols[2].text if 2 in cols else ''
            method = cols[3].text if 3 in cols else ''
            wing = cols[4].text if 4 in cols else ''
            mass, mr = cols[5].text, cols[6].text
        except KeyError as e:
            errors.append(f'S2 page {pno}: row {cells[0].raw!r} lacks column {e}')
            continue
        if method not in ('', 'Open', 'Closed'):
            errors.append(f'S2 page {pno}: {cells[0].raw!r}: method {method!r}')
        if not order and len(family.split()) == 2:
            # one row types the order into the family cell ('Austrophasmatidae Mantophasmatodea')
            family, order = family.split()
            log(f'  S2 page {pno}: {sp.text!r}: order {order!r} taken from the family cell')
        for name, val in (('Method', method), ('Order', order)):
            if not val:
                log(f'  S2 page {pno}: {sp.text!r}: blank {name} cell')
        for name, val in (('Mass', mass), ('Metabolic rate', mr)):
            if not NUM_RE.match(val.replace(' ', '')):
                errors.append(f'S2 page {pno}: {cells[0].raw!r}: {name} {val!r} is not a number')
        if ' ' in mass or ' ' in mr:
            log(f'  S2 page {pno}: {sp.text!r}: space inside a number ({mass!r}, {mr!r}) removed')
            mass, mr = mass.replace(' ', ''), mr.replace(' ', '')
        if wing not in ('', '0', '1'):
            errors.append(f'S2 page {pno}: {cells[0].raw!r}: wing status {wing!r}')
        if any(c.sup for i, c in cols.items() if i != 0):
            errors.append(f'S2 page {pno}: superscript outside the species column on {cells[0].raw!r}')
        keys = split_sup(sp.sup) if sp.sup else []
        if sp.text.endswith('*'):
            keys.append('*')
        if not keys:
            errors.append(f'S2 page {pno}: {sp.raw!r} has no reference mark')
        rows_out.append({'Species': sp.text, 'Family': family, 'Order': order, 'Method': method,
                         'WingStatus': wing, 'Mass_mg': mass, 'MetabolicRate_uW': mr,
                         'ref_keys': '; '.join(keys), 'page': pno})
    for pno, t in skipped:
        log(f'  S2 page {pno}: non-data line: {t}')
    if '*' not in footnotes:
        errors.append('S2: footnote for the asterisk marks not found')
    return rows_out, footnotes


def parse_references(pages, errors):
    entries, current = [], None
    for pno, page in pages:
        for row in group_rows(page_cells(page)):
            cells = [c for c in row if not c.blank]
            if not cells or is_page_number(row):
                continue
            if cells[0].text == REF_TITLE and len(cells) == 1:
                continue
            m = REF_START_RE.match(cells[0].text)
            if m and cells[0].x0 < 110:
                current = {'key': m.group(1), 'lines': [norm(''.join(c.raw for c in cells[1:]))], 'page': pno}
                entries.append(current)
            elif current is not None and cells[0].x0 > 110:
                current['lines'].append(norm(''.join(c.raw for c in cells)))
            else:
                errors.append(f'References page {pno}: unexpected line {cells[0].raw!r}')
    out = []
    for e in entries:
        text = ''
        for part in e['lines']:
            if not text:
                text = part
            elif text.endswith('-') and part[:1].isdigit():
                text += part                       # a page range broken at the line end
            else:
                text += ' ' + part
        out.append({'key': e['key'], 'raw_citation': text})
    keys = [int(e['key']) for e in out]
    if keys != list(range(1, len(keys) + 1)):
        dup = [k for k, n in Counter(keys).items() if n > 1]
        missing = sorted(set(range(1, max(keys) + 1)) - set(keys))
        errors.append(f'References: {len(keys)} entries, highest {max(keys)}; duplicated {dup}, missing {missing}')
    return out


def find_sections(doc):
    """Page index ranges of S1, S2 and the reference list from their headings."""
    starts = {}
    for i, page in enumerate(doc):
        text = page.get_text()
        for key, title in (('s1', S1_TITLE), ('s2', S2_TITLE), ('refs', REF_TITLE)):
            found = re.search('^' + re.escape(title) + (r'\s*$' if key == 'refs' else ''), text, re.M)
            if key not in starts and found:
                starts[key] = i
    if set(starts) != {'s1', 's2', 'refs'} or not starts['s1'] < starts['s2'] < starts['refs']:
        raise ValueError(f'section headings not found in order: {starts}')
    return starts


def write_csv(path, rows, fields):
    with open(path, 'w', newline='', encoding='utf-8') as fh:
        w = csv.DictWriter(fh, fieldnames=fields, extrasaction='ignore', lineterminator='\n')
        w.writeheader()
        w.writerows(rows)


def main(argv):
    pdf = argv[1] if len(argv) > 1 else DEFAULT_PDF
    doc = fitz.open(pdf)
    starts = find_sections(doc)
    pages = [(i + 1, doc[i]) for i in range(len(doc))]
    errors = []
    log(f'{os.path.basename(pdf)}: {len(doc)} pages; S1 from page {starts["s1"] + 1}, '
        f'S2 from page {starts["s2"] + 1}, references from page {starts["refs"] + 1}')

    s1 = parse_s1(pages[starts['s1']:starts['s2']], errors)
    s2, footnotes = parse_s2(pages[starts['s2']:starts['refs']], errors)
    refs = parse_references(pages[starts['refs']:], errors)
    n_numbered = len(refs)
    if '*' in footnotes:                  # the unpublished rows' key, after the numbered list
        refs.append({'key': '*', 'raw_citation': footnotes['*']})

    # cross-checks between the table and the reference list
    ref_keys = {r['key'] for r in refs}
    cited = Counter(k for r in s2 for k in r['ref_keys'].split('; ') if k)
    unknown = sorted((k for k in cited if k != '*' and k not in ref_keys), key=int)
    if unknown:
        errors.append(f'S2 cites reference number(s) without an entry: {unknown}')
    unused = sorted((k for k in ref_keys if k not in cited), key=int)
    first_seen, order_ok = [], True
    for r in s2:
        for k in r['ref_keys'].split('; '):
            if k and k != '*' and k not in first_seen:
                if first_seen and int(k) < int(first_seen[-1]):
                    order_ok = False
                first_seen.append(k)

    log(f'S1: {len(s1)} records, {len(Counter(r["Species"] for r in s1))} species: '
        + ', '.join(f'{sp} {n}' for sp, n in sorted(Counter(r['Species'] for r in s1).items())))
    log(f'S2: {len(s2)} records, {len(set(r["Species"] for r in s2))} distinct species strings; '
        f'{sum(1 for r in s2 if not r["WingStatus"])} blank wing-status cell(s); '
        f'{cited.get("*", 0)} unpublished (*) rows; '
        f'{sum(1 for r in s2 if len(r["ref_keys"].split("; ")) > 1)} rows with more than one mark')
    log(f'S2 orders: ' + ', '.join(f'{o} {n}' for o, n in Counter(r['Order'] for r in s2).most_common()))
    log(f'References: {n_numbered} numbered entries (1-{refs[n_numbered - 1]["key"] if n_numbered else "?"})'
        f' + {len(refs) - n_numbered} footnote key(s) {sorted(footnotes)}; '
        f'{len(cited) - (1 if "*" in cited else 0)} distinct numbers cited; unused: {unused or "none"}; '
        f'first citations in numerical order: {order_ok}')
    for e in errors:
        log('ERROR ' + e)
    if errors:
        return 1
    write_csv(OUT_S1, s1, ['Species', 'Temperature_C', 'Mass_mg', 'MetabolicRate_uW'])
    write_csv(OUT_S2, s2, ['Species', 'Family', 'Order', 'Method', 'WingStatus', 'Mass_mg',
                           'MetabolicRate_uW', 'ref_keys'])
    write_csv(OUT_REFS, refs, ['key', 'raw_citation'])
    log(f'wrote {os.path.basename(OUT_S1)}, {os.path.basename(OUT_S2)}, {os.path.basename(OUT_REFS)}')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
