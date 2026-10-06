#!/usr/bin/env python3
"""Build references.csv for Lislevand_etal_2007 from the reference list of the
Ecological Archives metadata page (metadata.htm, E088-096, section Class V F,
"Reference list for data set"; the committed copy of
https://esapubs.org/archive/ecol/E088/096/metadata.htm).

    python3 build_references.py            # writes references.csv next to it

The list is the two-column HTML table that follows the heading "Reference
list for data set" (Reference number | Citation): 87 numbered entries, the
numbers the `References` column of avian_ssd_jan07.txt cites (';'-separated).
Each entry is kept verbatim (tags stripped, entities unescaped, whitespace
collapsed; the bold volume numbers lose their markup). Columns: key, citation.
"""
import csv, html, os, re

here = os.path.dirname(os.path.abspath(__file__))
src = open(os.path.join(here, 'metadata.htm'), encoding='utf-8').read()
start = src.index('Reference list for data set')
table = re.search(r'<table.*?</table>', src[start:], flags=re.S).group(0)
rows = re.findall(r'<tr>(.*?)</tr>', table, flags=re.S)

def cell_text(c):
    return re.sub(r'\s+', ' ', html.unescape(re.sub(r'<[^>]+>', '', c))).strip()

entries = []
for r in rows:
    cells = [cell_text(c) for c in re.findall(r'<td[^>]*>(.*?)</td>', r, flags=re.S)]
    if len(cells) != 2 or not re.fullmatch(r'\d+', cells[0]):
        continue                                   # the header row
    entries.append((cells[0], cells[1]))

keys = [k for k, _ in entries]
assert keys == [str(i) for i in range(1, len(keys) + 1)], 'numbering gap in the list'
assert all(c for _, c in entries), 'empty citation'
with open(os.path.join(here, 'references.csv'), 'w', newline='', encoding='utf-8') as f:
    w = csv.writer(f, lineterminator='\n')
    w.writerow(['key', 'citation'])
    w.writerows(entries)
print(f'{len(entries)} entries -> references.csv')
