#!/usr/bin/env python3
"""Transcribe Appendix S6 of Hudson, Isaac & Reuman (2013, J Anim Ecol 82:1009) to references.csv.

Appendix S6 ('Database references') is the reference list of the 126 doubly-
labelled-water studies whose individuals fill Appendix S5 (the data file
`jane12086-sup-0003-AppendixS5.csv`, column `Study`). It is a separate
supplement file: at Wiley the Appendix S6 PDF of the Supporting Information
(https://doi.org/10.1111/1365-2656.12086), at Europe PMC the open-access copy
`jane0082-1009-sd3.pdf` of PMC3840704 (8 A4 pages, a LaTeX/dvips document).
Neither copy is committed (publisher file); the script reads the one next to it.

Read with PyMuPDF (`fitz`): every text line has a bounding box; an entry starts
at the left margin (x 56.7) and its continuation lines hang indented (x 67.6);
the title and author block above the heading 'Appendix S6. Database references'
on page 1 and the centred page number at the foot of each page (y > 770) are
skipped. Fragments PyMuPDF reports as separate lines on one baseline (within
2 pt) are joined with one space, the lines of an entry with one space, runs of
whitespace are collapsed, the Computer Modern ligatures (fi, fl, ff, ffi) are
expanded and the accents dvips prints as separate glyphs before the letter
('B¨uhrmann', 'Ad´elie') are composed with it (NFC). The text is otherwise kept
verbatim, typographic errors included ('Galpagos', 'Austraila', 'listory',
'Sanson, G.D. & K, J.N.', 'Obst, Bryan, S.', the space before a comma).

The key of an entry is the author-year form of Appendix S5's `Study` column:
'Surname YYYY', 'Surname & Surname YYYY', 'Surname et al YYYY' (first surname;
a particle stays, 'von Helversen & Reyer 1984'). The author block is the text
before '(YYYY)'; its ', '-separated tokens are initials ('J.P.Y.') or surnames.
Six entries need the explicit corrections of KEY_OVERRIDES below, where S5's
key departs from S6's text: Tjørve et al. (printed 2006; S5 and Zoology vol. 110
say 2007), Jönsson (S5 writes 'Jonsson'), the two Nagy et al. (1990) entries
(S5 suffixes a and b in S6's order; S5's species -- a: Setonix brachyurus,
Macropus eugenii -- confirm it), 'Obst, Bryan, S.' and 'LeFebvre, Eugene, A.'
(a given name printed as a surname; two authors each) and 'du Plessis' (S5
capitalises 'Du').

Usage: parse_hudson_s6.py [PDF] [S5.csv]
       (defaults: jane0082-1009-sd3.pdf and jane12086-sup-0003-AppendixS5.csv next to this script)
Output (next to this script): references.csv  key, citation, owner_review (the 126
       entries in S6 order; owner_review is 'book chapter' for an entry citing a
       chapter 'in <editors>, ed(s)., <book>' and 'conference proceedings' for one
       citing a proceedings volume -- Drack et al. 1999, Fleming 1988, Nagy et al.
       1999 -- so that the tooling queues them for the owner; blank otherwise)
Counts and anomalies go to stderr; the script exits non-zero when a key is
duplicated, a `Study` value of Appendix S5 has no entry, or an entry cannot be
keyed.
"""
import csv
import os
import re
import sys
import unicodedata
from collections import Counter

try:
    import fitz  # PyMuPDF
except ImportError:  # pragma: no cover
    sys.exit('parse_hudson_s6.py needs PyMuPDF (pip install pymupdf)')

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_PDF = os.path.join(HERE, 'jane0082-1009-sd3.pdf')
DEFAULT_S5 = os.path.join(HERE, 'jane12086-sup-0003-AppendixS5.csv')
OUT_REFS = os.path.join(HERE, 'references.csv')

HEADING = 'Appendix S6. Database references'
MARGIN_X = 62.0      # pt: a line starting left of this opens an entry (entries at 56.7, hanging lines at 67.6)
FOOT_Y = 770.0       # pt: the page number sits below this
ROW_TOL = 2.0        # pt: fragments whose top edges differ by less sit on one baseline
YEAR_RE = re.compile(r'^(?P<authors>.+?) \((?P<year>\d{4})[a-z]?\) ')
INITIALS_RE = re.compile(r'^(?:[A-Z]\.)+(?:-[A-Z]\.)*$|^[A-Z]$')   # 'J.P.Y.', 'I' (Piersma et al. 2003)
LIGATURES = {'ﬀ': 'ff', 'ﬁ': 'fi', 'ﬂ': 'fl', 'ﬃ': 'ffi', 'ﬄ': 'ffl'}
ACCENTS = {'\u00a8': '\u0308', '\u00b4': '\u0301', '`': '\u0300', '\u02c6': '\u0302',   # diaeresis, acute, grave, circumflex,
           '\u02dc': '\u0303', '\u02da': '\u030a', '\u00b8': '\u0327'}                    # tilde, ring, cedilla
CHAPTER_RE = re.compile(r', in .+\beds?\., .+, pp\. \d+')
PROCEEDINGS_RE = re.compile(r', in (Acta|Proceedings|Proc\.) .+, pp\. \d+')
ACCENT_RE = re.compile('[' + ''.join(map(re.escape, ACCENTS)) + r'](\w)')

# (first surname as printed, year as printed, 1-based index among the entries
# sharing them) -> the key Appendix S5 uses
KEY_OVERRIDES = {
    ('Tjørve', '2006', 1): 'Tjørve et al 2007',
    ('Jönsson', '1996', 1): 'Jonsson et al 1996',
    ('Nagy', '1990', 1): 'Nagy et al 1990a',
    ('Nagy', '1990', 2): 'Nagy et al 1990b',
    ('Nagy', '1992', 1): 'Nagy & Obst 1992',
    ('Utter', '1973', 1): 'Utter & LeFebvre 1973',
    ('Williams', '1996', 1): 'Williams & Du Plessis 1996',
}


def log(msg):
    print(msg, file=sys.stderr)


def clean(s):
    for lig, plain in LIGATURES.items():
        s = s.replace(lig, plain)
    s = ACCENT_RE.sub(lambda m: unicodedata.normalize('NFC', m.group(1) + ACCENTS[m.group(0)[0]]), s)
    return re.sub(r'\s+', ' ', s).strip()


def page_lines(page):
    """Text lines of a page as (y0, x0, text), fragments on one baseline joined."""
    frags = []
    for block in page.get_text('dict')['blocks']:
        for line in block.get('lines', []):
            text = ''.join(s['text'] for s in line['spans'])
            if text.strip():
                frags.append((line['bbox'][1], line['bbox'][0], text))
    frags.sort()
    rows = []
    for y0, x0, text in frags:
        if rows and abs(y0 - rows[-1][0]) <= ROW_TOL:
            rows[-1][2].append((x0, text))
        else:
            rows.append([y0, x0, [(x0, text)]])
    return [(y0, x0, ' '.join(t for _, t in sorted(parts))) for y0, x0, parts in rows]


def read_entries(pdf_path):
    doc = fitz.open(pdf_path)
    entries, started = [], False
    for pno, page in enumerate(doc):
        for y0, x0, text in page_lines(page):
            if y0 > FOOT_Y:
                continue
            if not started:
                if clean(text) == HEADING:
                    started = True
                continue
            if x0 < MARGIN_X:
                entries.append([text])
            elif entries:
                if entries[-1][-1].rstrip().endswith(('-', '–')):
                    log(f'note: line of entry {len(entries)} ends in a dash (page {pno + 1}): {text[:40]!r}')
                entries[-1].append(text)
            else:
                raise ValueError(f'page {pno + 1}: continuation line before the first entry: {text!r}')
    if not started:
        raise ValueError(f'heading {HEADING!r} not found in {pdf_path}')
    return [clean(' '.join(lines)) for lines in entries]


def review_reason(citation):
    if CHAPTER_RE.search(citation):
        return 'book chapter'
    if PROCEEDINGS_RE.search(citation):
        return 'conference proceedings'
    return ''


def author_surnames(block):
    """Surnames of an author block 'A, I.I., B, I. & C, I.' in order."""
    names = []
    for part in re.split(r' & ', block):
        for tok in part.split(', '):
            tok = tok.strip()
            if tok and not INITIALS_RE.match(tok):
                names.append(tok)
    return names


def make_key(citation, seen):
    m = YEAR_RE.match(citation)
    if not m:
        raise ValueError(f'no author block / year in: {citation[:80]!r}')
    year = m.group('year')
    names = author_surnames(m.group('authors'))
    if not names:
        raise ValueError(f'no surname in: {citation[:80]!r}')
    seen[(names[0], year)] += 1
    override = KEY_OVERRIDES.get((names[0], year, seen[(names[0], year)]))
    if override:
        return override, True
    if len(names) == 1:
        return f'{names[0]} {year}', False
    if len(names) == 2:
        return f'{names[0]} & {names[1]} {year}', False
    return f'{names[0]} et al {year}', False


def main(argv):
    pdf_path = argv[1] if len(argv) > 1 else DEFAULT_PDF
    s5_path = argv[2] if len(argv) > 2 else DEFAULT_S5
    citations = read_entries(pdf_path)
    log(f'{len(citations)} entries read from {os.path.basename(pdf_path)}')

    seen, keys, overridden = Counter(), [], 0
    for cit in citations:
        key, forced = make_key(cit, seen)
        keys.append(key)
        overridden += forced
    dup = [k for k, n in Counter(keys).items() if n > 1]
    if dup:
        sys.exit(f'duplicated key(s): {dup}')
    log(f'{overridden} key(s) set by KEY_OVERRIDES')

    with open(OUT_REFS, 'w', newline='', encoding='utf-8') as fh:
        w = csv.writer(fh, lineterminator='\n')
        w.writerow(['key', 'citation', 'owner_review'])
        for key, cit in zip(keys, citations):
            w.writerow([key, cit, review_reason(cit)])
    reasons = Counter(review_reason(c) for c in citations if review_reason(c))
    log(f'{len(keys)} rows written to {os.path.basename(OUT_REFS)}; owner_review set on {dict(reasons)}')

    # every Study value of Appendix S5 must resolve
    with open(s5_path, newline='', encoding='utf-8') as fh:
        study = Counter(r['Study'].strip() for r in csv.DictReader(fh))
    missing = sorted(k for k in study if k not in keys)
    unused = [k for k in keys if k not in study]
    log(f'Appendix S5: {sum(study.values())} rows, {len(study)} distinct Study keys, '
        f'{study.get("", 0)} without a key; {len(unused)} entries cited by no row: {unused}')
    if missing:
        sys.exit(f'{len(missing)} Study key(s) without an entry: {missing}')
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
