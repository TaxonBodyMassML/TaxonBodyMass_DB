#!/usr/bin/env python3
"""Build references.csv and literature_cited.csv for Myhrvold_2015 (the Amniote
life-history database, Ecological Archives E096-269) from the retriever cache.

    python3 build_references.py [--cache ~/.retriever/raw_data/amniote-life-hist]

The database publishes its sources in two places of the figshare archive the
retriever caches as `8067269` (a zip; retriever dataset `amniote-life-hist`):

- `Data_Files/Amniote_Database_References_Aug_2015.csv`: one cell per trait
  value with the short names of the sources it comes from (the same layout as
  the data file; `-999` where there is no value). A body-mass cell reads
  "<name>", "<name> from median of n(<name>, <name>, ...)" (the stored value is
  the median of the n raw values listed in the brackets and equals the value
  that <name> reported) or "mean of <name> & <name> from median of n(...)"
  (an even n: the mean of the two middle values); a name may carry the prefix
  "BC Birds - " / "BC mammals - " / "BC Reptiles - " (a batch mark of the
  compilers' data entry, not part of the reference: the same name occurs with
  and without it). The names are the native reference keys of the dataset.
- `Supplemental_Materials/Supplemental_Table_1_Database_Literature_Cited.pdf`:
  the alphabetical literature-cited list (Chicago author-date style, 63 pages,
  no numbering); `Supplemental_Table_2_Reference_Counts.csv`: the 1,003 short
  names with the number of trait values each supports (the vocabulary that
  lets a cell be split into names: a name can contain ", " and " and ").

What the script does:

1. Reads the data csv and the references csv side by side (same row order; the
   retriever's `record_id` of both tables is the row number) and keeps the
   `adult_body_mass_g` cells of the rows with a positive mass (the records
   `R/library/data_retrieve.r` keeps).
2. Splits every cell into its value-providing names with the Table 2
   vocabulary (longest name first, the two non-ASCII names of Table 2 matched
   with their ASCII spelling of the csv); the names in the brackets are counted
   but are not keys (they contributed to the median, the value is not theirs).
   A cell that cannot be split stops the script.
3. Reads the PDF with PyMuPDF: a line starting at the left margin (x = 72)
   opens an entry, an indented line continues it; lines are joined with one
   space, or with nothing after a hyphen or an en dash (a page range or a name
   broken at the line end); a "———." marker (the author block of the previous
   entry) is expanded for the matching and in the written citation, noted.
4. Matches every name to one entry by the folded first surname and the year
   (with its a/b suffix), the second surname deciding between several entries
   of one surname and year; writes `references.csv` with one row per name:
   `key` (a compact key built from the name: first surname, ASCII, and the
   year, 'Dunning_1992', 'deMagalhaes_2009', 'Ricklefs_2010b'; a second name
   giving the same key gets '_2'), `reference_name` (the name verbatim, the
   batch prefix removed), `citation` (the matched entry verbatim; the name
   itself when no entry matches, so that the row has text), `note` (the
   entry's position in the list, the expansion of a marker, the count of
   records), `owner_review` (filled when no entry or several entries match,
   or the match rests on a surname inside the author block).
5. Writes `literature_cited.csv` (`entry`, `citation`): every entry of the
   PDF, numbered in list order, for the owner's check of the matches.
"""
import argparse
import csv
import io
import os
import re
import sys
import unicodedata
import zipfile
from collections import Counter, defaultdict

try:
    import fitz  # PyMuPDF
except ImportError:  # pragma: no cover
    sys.exit('build_references.py needs PyMuPDF (pip install pymupdf)')

HERE = os.path.dirname(os.path.abspath(__file__))
ZIP_NAME = '8067269'
PDF_IN_ZIP = 'Supplemental_Materials/Supplemental_Table_1_Database_Literature_Cited.pdf'
T2_IN_ZIP = 'Supplemental_Materials/Supplemental_Table_2_Reference_Counts.csv'
DATA_CSV = 'Data_Files/Amniote_Database_Aug_2015.csv'
REFS_CSV = 'Data_Files/Amniote_Database_References_Aug_2015.csv'
TRAIT = 'adult_body_mass_g'
PREFIX = re.compile(r'^BC (?:Birds|mammals|Reptiles) - ')
MARKER = re.compile(r'^(?:—|―|–|-){2,}\.?\s*')
ENTRY_X = 72          # left margin of an entry's first line (points)


def fold(s):
    s = unicodedata.normalize('NFKD', s)
    return ''.join(c for c in s if not unicodedata.combining(c))


def tokenize(s, seps, vocab):
    """Split `s` into vocabulary names separated by one of `seps` (greedy,
    longest name first); the batch prefix before a name is dropped. None when
    the string cannot be split."""
    out, i, s = [], 0, s.strip()
    while i < len(s):
        m = PREFIX.match(s[i:])
        if m:
            i += len(m.group(0))
        best = None
        for v in vocab:
            if s.startswith(v, i):
                j = i + len(v)
                if j == len(s) or any(s.startswith(sp, j) for sp in seps):
                    best = v
                    break
        if best is None:
            return None
        out.append(best)
        i += len(best)
        for sp in seps:
            if s.startswith(sp, i):
                i += len(sp)
                break
    return out


def split_cell(cell, vocab):
    """The value-providing names of a cell and the names in its brackets."""
    m = re.fullmatch(r'(.*?)(?: from median of (\d+)\((.*)\))?', cell, flags=re.S)
    head, n, inner = m.group(1), m.group(2), m.group(3)
    # one cell (Iverson et al. 1993, a turtle) writes an empty name: 'mean of  &
    # Iverson, ... from median of 4(, BC Reptiles - Tacutu, ..., Iverson, ...)'
    if head.startswith('mean of '):
        body = head[len('mean of '):]
        if body.startswith(' & ') or body.startswith(' and '):
            body = body.split(' ', 2)[2]
        providers = tokenize(body, [' & ', ' and '], vocab)
    else:
        providers = tokenize(head, [], vocab)
    contributors = tokenize(inner.lstrip(', '), [', '], vocab) if inner is not None else []
    if providers is None or contributors is None:
        return None, None
    return providers, contributors


# ---- the reference-count table: the name vocabulary ----------------------------------
def read_vocabulary(zf, cells_text):
    raw = zf.read(T2_IN_ZIP).decode('latin-1')
    names = [r[0] for r in csv.reader(io.StringIO(raw))][1:]
    vocab = set()
    for n in names:
        if any(ord(c) > 127 for c in n):
            # the table's encoding of its two diacritics is not the csv's; the
            # csv writes the name in ASCII, so the name is found in the cells
            pat = ''.join('.{1,2}' if ord(c) > 127 else re.escape(c) for c in n)
            found = set(re.findall(pat, cells_text))
            vocab |= found
        else:
            vocab.add(n)
    return sorted(vocab, key=len, reverse=True), len(names)


# ---- the literature-cited PDF -------------------------------------------------------
def read_entries(pdf_bytes):
    doc = fitz.open(stream=pdf_bytes, filetype='pdf')
    entries, cur = [], None
    for page in doc:
        for block in page.get_text('dict')['blocks']:
            for line in block.get('lines', []):
                text = ''.join(sp['text'] for sp in line['spans']).strip()
                if not text:
                    continue
                x0 = round(line['bbox'][0])
                if x0 <= ENTRY_X + 2:
                    if text == 'References' and not entries and cur is None:
                        continue
                    if cur is not None:
                        entries.append(cur)
                    cur = text
                else:
                    if cur is None:
                        sys.exit('continuation line before the first entry: ' + text)
                    cur = cur + ('' if cur.endswith(('-', '–')) else ' ') + text
    if cur is not None:
        entries.append(cur)
    entries = [re.sub(r'\s+', ' ', e).strip() for e in entries]
    # the last page ends with a block of in-text citations '(Acharya 1992; ...)'
    # that is no entry
    trailer = [e for e in entries if e.startswith('(')]
    if trailer:
        print('%d block(s) starting with a bracket dropped (the in-text citation block of the last page)'
              % len(trailer), file=sys.stderr)
    entries = [e for e in entries if not e.startswith('(')]
    # expand the same-author markers
    expanded, notes = [], []
    prev_block = None
    for e in entries:
        m = MARKER.match(e)
        if m and prev_block is not None:
            rest = e[m.end():]
            e2 = prev_block + ('' if rest.startswith(('.', ',')) else '. ') + rest
            expanded.append(e2)
            notes.append('author block expanded from a same-author marker of the preceding entry')
        else:
            expanded.append(e)
            notes.append('')
        blk = author_block(expanded[-1])
        if blk:
            prev_block = blk
    return expanded, notes


def author_block(entry):
    """The text before the year of a Chicago author-date entry."""
    m = re.search(r'\.\s+(\d{4}[a-z]?)\.\s', entry)
    if m:
        return entry[:m.start()].strip()
    m = re.search(r'\s(\d{4}[a-z]?)\.\s', entry)   # 'Author. 1990. ...' without a period before the year
    if m:
        return entry[:m.start()].strip()
    m = re.search(r'\.\s+[A-Z“]', entry)             # an undated entry: the authors are its first sentence
    return entry[:m.start()].strip() if m else None


def entry_year(entry):
    m = re.search(r'\.\s+(\d{4}[a-z]?)\.\s', entry) or re.search(r'\s(\d{4}[a-z]?)\.\s', entry)
    return m.group(1) if m else None


def entry_surnames(entry):
    """The surnames of an entry's author block: the first author is written
    'Surname, Given', the others 'Given Surname' (Chicago)."""
    blk = author_block(entry)
    if not blk:
        return []
    blk = re.sub(r'\.$', '', blk)
    parts = [p.strip() for p in re.split(r',\s*(?:and\s+)?|\s+and\s+', blk) if p.strip()]
    if not parts:
        return []
    out = [parts[0]]                       # the inverted first author: surname before the comma
    for p in parts[2:]:                    # parts[1] is the first author's given names
        w = p.split()
        if w:
            out.append(w[-1])
    return [fold(s).lower() for s in out]


# ---- the names ------------------------------------------------------------------
def name_parts(name):
    """(first surname, second surname or None, year or None) of a short name."""
    m = re.search(r'(\d{4}[a-z]?)\s*$', name)
    year = m.group(1) if m else None
    body = name[:m.start()].strip().rstrip(',').strip() if m else name.strip()
    body = re.sub(r'\bet\s+al\.?,?', ' ', body)
    toks = [t.strip() for t in re.split(r',\s*|\s+and\s+|\s+&\s+', body) if t.strip()]
    toks = [t for t in toks if not re.fullmatch(r'(?:[A-Z]\.?\s*-?)+', t)]   # initials only
    surn = []
    for t in toks:
        w = [x for x in t.split() if not re.fullmatch(r'(?:[A-Z][\.\-]?)+', x)]   # 'P.W. Sherman' -> Sherman
        if w:
            surn.append(' '.join(w) if re.match(r'^(de|van|von|del|da)\b', t, flags=re.I) else w[-1])
    first = surn[0] if surn else body
    second = surn[1] if len(surn) > 1 else None
    return first, second, year


def key_for(name):
    first, _, year = name_parts(name)
    stem = re.sub(r'[^A-Za-z]', '', fold(first))
    return stem + ('_' + year if year else '')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--cache', default=os.path.expanduser('~/.retriever/raw_data/amniote-life-hist'))
    args = ap.parse_args()
    zf = zipfile.ZipFile(os.path.join(args.cache, ZIP_NAME))
    data = list(csv.DictReader(open(os.path.join(args.cache, DATA_CSV), encoding='utf-8', newline='')))
    refs = list(csv.DictReader(open(os.path.join(args.cache, REFS_CSV), encoding='utf-8', newline='')))
    if len(data) != len(refs):
        sys.exit('data and references csv differ in length')
    for d, r in zip(data, refs):
        if (d['genus'], d['species']) != (r['genus'], r['species']):
            sys.exit('data and references csv are not row-aligned')
    cells = [r[TRAIT] for d, r in zip(data, refs)
             if d[TRAIT] not in ('', '-999') and float(d[TRAIT]) > 0]
    vocab, n_t2 = read_vocabulary(zf, '\n'.join(cells))

    providers, contributors, nprov, prefixed, bad = Counter(), Counter(), Counter(), 0, []
    for c in cells:
        p, k = split_cell(c, vocab)
        if p is None:
            bad.append(c)
            continue
        nprov[len(p)] += 1
        prefixed += len(PREFIX.findall(c))
        for x in p:
            providers[x] += 1
        for x in k:
            contributors[x] += 1
    if bad:
        sys.exit('%d cell(s) could not be split into names: %s' % (len(bad), bad[:5]))
    print('%d body-mass cells (%d of the %d rows); value-providing names per cell: %s; %d distinct names '
          '(%d names in the brackets); %d batch prefixes removed; Table 2 lists %d names'
          % (len(cells), len(cells), len(data), dict(sorted(nprov.items())), len(providers),
             len(contributors), prefixed, n_t2), file=sys.stderr)

    entries, marker_notes = read_entries(zf.read(PDF_IN_ZIP))
    print('%d entries in the literature-cited PDF (%d with a same-author marker expanded)'
          % (len(entries), sum(1 for n in marker_notes if n)), file=sys.stderr)
    with open(os.path.join(HERE, 'literature_cited.csv'), 'w', newline='', encoding='utf-8') as f:
        w = csv.writer(f, lineterminator='\n')
        w.writerow(['entry', 'citation'])
        for i, e in enumerate(entries, 1):
            w.writerow([i, e])

    by_sy = defaultdict(list)     # (first surname, year) -> entry numbers
    years, surnames = [], []
    for i, e in enumerate(entries, 1):
        y, s = entry_year(e), entry_surnames(e)
        years.append(y)
        surnames.append(s)
        if s and y:
            by_sy[(s[0], y)].append(i)

    rows, keys_seen = [], Counter()
    n_matched = n_unmatched = n_ambiguous = n_loose = 0
    for name in sorted(providers, key=lambda n: fold(n).lower()):
        first, second, year = name_parts(name)
        f1 = fold(first).lower()
        cands = by_sy.get((f1, year), []) if year else []
        how = 'first surname and year'
        if not cands and year and re.search(r'[a-z]$', year):
            # 'Kratochvil and Frynta, 2006a': the list does not letter its entries
            cands = by_sy.get((f1, year[:-1]), [])
            how = 'first surname and year without the letter suffix'
        if not year:
            # 'Lanicci, R.': an undated name matches an undated entry of that surname
            cands = [i for i, (y, s) in enumerate(zip(years, surnames), 1) if y is None and s and s[0] == f1]
            how = 'first surname, both undated'
        if not cands and year:
            # the surname anywhere in the author block (an entry not inverted, or
            # a name citing a later author), the year equal
            cands = [i for i, (y, s) in enumerate(zip(years, surnames), 1)
                     if y == year and f1 in s]
            how = 'surname inside the author block and year'
        if len(cands) > 1 and second:
            f2 = fold(second).lower()
            narrowed = [i for i in cands if f2 in surnames[i - 1]]
            if len(narrowed) >= 1:
                cands = narrowed
                how += ', second surname'
        if len(cands) > 1 and second is None:
            # a one-author name: prefer single-author entries
            narrowed = [i for i in cands if len(surnames[i - 1]) == 1]
            if len(narrowed) == 1:
                cands = narrowed
                how += ', single-author entry'
        note, review = [], ''
        if len(cands) == 1:
            i = cands[0]
            citation = entries[i - 1]
            note.append('Supplemental Table 1 entry %d (matched by %s)' % (i, how))
            if marker_notes[i - 1]:
                note.append(marker_notes[i - 1])
            if how.startswith('surname inside'):
                review = 'matched by a surname inside the author block, not the first author: check entry %d' % i
                n_loose += 1
            n_matched += 1
        elif len(cands) > 1:
            citation = name
            note.append('Supplemental Table 1 entries %s share the surname and year' % ', '.join(map(str, cands)))
            review = 'several entries of Supplemental Table 1 match the name: %s' % ', '.join(map(str, cands))
            n_ambiguous += 1
        else:
            citation = name
            same = [i for i, s in enumerate(surnames, 1) if s and s[0] == f1]
            note.append('no entry of Supplemental Table 1 matches the name' + ('' if year else ' (no year in the name)')
                        + ('; entries of that surname: %s' % ', '.join('%d (%s)' % (i, years[i - 1]) for i in same) if same else ''))
            review = 'no entry of Supplemental Table 1 matches the reference name'
            n_unmatched += 1
        key = key_for(name)
        keys_seen[key] += 1
        if keys_seen[key] > 1:
            key = '%s_%d' % (key, keys_seen[key])
        note.append('%d body-mass records' % providers[name])
        rows.append([key, name, citation, '; '.join(note), review])
    with open(os.path.join(HERE, 'references.csv'), 'w', newline='', encoding='utf-8') as f:
        w = csv.writer(f, lineterminator='\n')
        w.writerow(['key', 'reference_name', 'citation', 'note', 'owner_review'])
        w.writerows(rows)
    print('%d names -> references.csv: %d matched to one entry (%d of them by a surname inside the author '
          'block), %d ambiguous, %d unmatched' % (len(rows), n_matched, n_loose, n_ambiguous, n_unmatched),
          file=sys.stderr)
    for r in rows:
        if r[4]:
            print('  review: %s | %s | %s' % (r[0], r[1], r[4]), file=sys.stderr)
    dup = [k for k, c in keys_seen.items() if c > 1]
    if dup:
        print('  key(s) shared by several names, suffixed: %s' % ', '.join(dup), file=sys.stderr)


if __name__ == '__main__':
    main()
