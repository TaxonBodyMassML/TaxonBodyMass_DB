#!/usr/bin/env python3
"""Parse Appendix a) of Ehnes, Rall & Brose (2011, Ecol. Lett. 14:993) from the
Wiley supplement PDF (ele_1660_sm_meta-scaling-appendix.pdf) into a CSV.
Runs `pdftotext -layout`; each data row is: no., group.1-4, Metastudy, original
study, Species, J/h, weight [mg], Temperature [C]. The record is parsed from the
right (three numbers), with the species taken as the capitalised Latin name
(optionally followed by epithet / 'sp.' / 'juv.') immediately before the numbers.
Output: ehnes2011_appendix_a.csv."""
import re, subprocess, csv, sys, collections
txt = subprocess.run(['pdftotext', '-layout', 'ele_1660_sm_meta-scaling-appendix.pdf', '-'],
                     capture_output=True, text=True).stdout
pat = re.compile(r'^\s*(?P<no>\d+)\s+(?P<g1>\S+)\s+(?P<g2>\S+)\s+(?P<g3>\S+)\s+(?P<g4>\S+)\s+(?P<studies>.*?)\s+'
                 r'(?P<sp>[A-Z][A-Za-z]+(?:\s+(?:[a-z]+|sp\.|spp\.|cf\.|juv\.))*)\s+'
                 r'(?P<jh>[\d.]+)\s+(?P<mg>[\d.]+)\s+(?P<temp>-?[\d.]+)\s*$')
rows, bad = [], []
for line in txt.split('\n'):
    if 'Appendix b)' in line: break           # only the data set (Appendix a)
    if not re.match(r'^\s*\d+\s+\S', line): continue
    m = pat.match(line)
    if m: rows.append(m.groupdict())
    elif re.search(r'\d+\.\d+\s+\d+\.\d+\s+-?\d+\.\d+\s*$', line): bad.append(line.strip()[:120])
for r in rows:
    r['sp'] = re.sub(r'\s+', ' ', r['sp']).strip()
    r['sp'] = r['sp'][0] + r['sp'][1:].lower() if ' ' not in r['sp'] else r['sp'].split(' ')[0][0] + r['sp'].split(' ')[0][1:].lower() + ' ' + ' '.join(r['sp'].split(' ')[1:])
with open('ehnes2011_appendix_a.csv', 'w', newline='') as fh:
    w = csv.DictWriter(fh, fieldnames=['no', 'g1', 'g2', 'g3', 'g4', 'studies', 'sp', 'jh', 'mg', 'temp'])
    w.writeheader(); w.writerows(rows)
print(f'parsed {len(rows)} records; unparsed data lines: {len(bad)}', file=sys.stderr)
for b in bad[:10]: print('  unparsed:', b, file=sys.stderr)
ids = {int(r['no']) for r in rows}; print('missing record numbers:', sorted(set(range(1, max(ids) + 1)) - ids)[:40], file=sys.stderr)
