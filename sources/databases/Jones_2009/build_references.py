#!/usr/bin/env python3
"""Build references.csv for Jones_2009 (PanTHERIA, Ecological Archives E090-184)
from the reference list of the archive's metadata page in the retriever cache.

    python3 build_references.py [--cache ~/.retriever/raw_data/pantheria]

The retriever dataset `pantheria` caches the archive as the zip `5604752`,
whose `metadata.htm` (Class V, Section B) carries the list under the heading
"Reference list for the data set: References are given as indexed values in
accordance with the following reference list." -- one numbered entry per
line ("N.&nbsp;...<br />", 1 to 3143), the numbers the `References` column of
`PanTHERIA_1-0_WR05_Aug2008.txt` cites ';'-separated for the whole species row
(every trait, not body mass alone). Each entry is kept verbatim (tags
stripped, entities unescaped, whitespace collapsed; the bold volume numbers
lose their markup). Columns: key, citation. The script stops on a numbering
gap or an empty entry.
"""
import argparse
import csv
import html
import os
import re
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
ZIP_NAME = '5604752'
START = 'Reference list for the data set'
END = 'LITERATURE CITED'


def cell_text(c):
    return re.sub(r'\s+', ' ', html.unescape(re.sub(r'<[^>]+>', '', c))).strip()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--cache', default=os.path.expanduser('~/.retriever/raw_data/pantheria'))
    args = ap.parse_args()
    with zipfile.ZipFile(os.path.join(args.cache, ZIP_NAME)) as zf:
        src = zf.read('metadata.htm').decode('latin-1')
    seg = src[src.index(START):src.index(END)]
    entries = []
    for item in re.split(r'<br\s*/?>', seg):
        # the first item carries the heading paragraph before entry 1, the last
        # the following section after entry 3143: the entry is the piece between
        # paragraph tags that starts with a number
        for piece in re.split(r'</?p[^>]*>', item):
            m = re.match(r'(\d+)\.\s*(.*)$', cell_text(piece), flags=re.S)
            if m:
                entries.append((int(m.group(1)), m.group(2).strip()))
    nums = [n for n, _ in entries]
    if nums != list(range(1, len(nums) + 1)):
        sys.exit('numbering gap or duplicate in the list: %d entries, first %s, last %s'
                 % (len(nums), nums[:1], nums[-1:]))
    if not all(c for _, c in entries):
        sys.exit('empty citation')
    with open(os.path.join(HERE, 'references.csv'), 'w', newline='', encoding='utf-8') as f:
        w = csv.writer(f, lineterminator='\n')
        w.writerow(['key', 'citation'])
        w.writerows(entries)
    print('%d entries -> references.csv' % len(entries), file=sys.stderr)


if __name__ == '__main__':
    main()
