#!/usr/bin/env python3
"""Parse Ikeda (2014, Mar Biol 161:2753) ESM tables S1-S4 (PDF) into a CSV.

The ESM PDF is laid out in 3-4 side-by-side column groups per table. We run
`pdftotext -layout`, split each line at the header positions of the 'Taxon'/'Taxa'
labels, and read the column groups in reading order (top to bottom, left to
right), carrying the taxon-group label (COPE, EUPH, ...) and, in S4, the species
name down through blank cells. Records in S1-S3 that say 'see S4' are resolved
through the (group, code) -> species/stage table S4.
Output: ikeda2014_esm_parsed.csv (one row per S1-S3 record with a dry mass).
"""
import re, subprocess, csv, sys, collections
pdf = '227_2014_2540_MOESM1_ESM.pdf'
txt = subprocess.run(['pdftotext', '-layout', pdf, '-'], capture_output=True, text=True).stdout
lines = txt.split('\n')
sec = {k: next(i for i, l in enumerate(lines) if l.lstrip('\f').startswith(f'{k}.')) for k in ['S1', 'S2', 'S3', 'S4']}
order = ['S1', 'S2', 'S3', 'S4']
bounds = {k: (sec[k], sec[order[i + 1]] if i + 1 < 4 else len(lines)) for i, k in enumerate(order)}

def header_offsets(block, label_re):
    for i, l in enumerate(block):
        offs = [m.start() for m in re.finditer(label_re, l)]
        if len(offs) >= 2:
            return i, offs
    raise RuntimeError('header not found')

def chunks(block, hi, offs):
    """Yield column chunks in reading order: column by column."""
    cols = [[] for _ in offs]
    for l in block[hi + 1:]:
        if l.startswith('\f') or not l.strip():
            continue
        for c, start in enumerate(offs):
            end = offs[c + 1] if c + 1 < len(offs) else None
            cols[c].append(l[start:end])
    for c in cols:
        for piece in c:
            yield piece

# ---- S4: code table
s4 = lines[bounds['S4'][0]:bounds['S4'][1]]
hi, offs = header_offsets(s4, r'Taxon')
s4map = {}
grp = sp = None
pat4 = re.compile(r'^\s*(?P<grp>[A-Z]{4})?\s*(?P<code>[A-Z]{0,2}[\u2013-]?\d+[a-z]?)\s+(?P<rest>.*?)\s*$')
stage_re = re.compile(r'^(?P<sp>.*?)\s*(?P<stage>C\d[FM]?|FG|F|M|J|A)?$')
for piece in chunks(s4, hi, offs):
    if not piece.strip():
        continue
    m = pat4.match(piece)
    if not m:
        print('S4 unparsed:', repr(piece), file=sys.stderr); continue
    if m.group('grp'): grp = m.group('grp')
    rest = m.group('rest')
    st = stage_re.match(rest)
    sp_txt, stage = st.group('sp').strip(), (st.group('stage') or '')
    if sp_txt: sp = sp_txt
    s4map[(grp, m.group('code').replace('\u2013', '-'))] = (sp, stage)

# ---- S1-S3: data tables
recs = []
# Right-anchored record pattern: <group?> <code> <species/stage text> depth T rate DW [C] [N] [reference]
rec_re = re.compile(r'^\s*(?P<grp>[A-Z]{4})?\s*(?P<code>[A-Z]{0,2}[\u2013-]?\d+[a-z]?)\s+(?P<sp>see S4|[A-Z][^\s].*?)\s+'
                    r'(?P<depth>\d+)\s+(?P<T>-?\d+(?:\.\d+)?)\s+(?P<rate>-?\d+(?:\.\d+)?)\s+(?P<dw>\d+(?:\.\d+)?)'
                    r'(?:\s+(?P<c>\d+(?:\.\d+)?))?(?:\s+(?P<n>\d+(?:\.\d+)?))?\s*(?P<ref>[A-Z].*)?$')
for tab in ['S1', 'S2', 'S3']:
    block = lines[bounds[tab][0]:bounds[tab][1]]
    hi, offs = header_offsets(block, r'Tax(?:on|a)')
    grp = None; n_ok = n_bad = 0
    for piece in chunks(block, hi, offs):
        if not piece.strip() or piece.strip().startswith(('Tax', 'S1', 'S2', 'S3')):
            continue
        m = rec_re.match(piece)
        if not m:
            n_bad += 1
            if n_bad <= 4: print(f'{tab} skipped:', repr(piece.strip()[:90]), file=sys.stderr)
            continue
        if m.group('grp'): grp = {'CHNI': 'CNID'}.get(m.group('grp'), m.group('grp'))  # CHNI is a typo for CNID in S3
        t = m
        sp = m.group('sp').strip()
        stage = ''
        if sp == 'see S4':
            sp, stage = s4map.get((grp, m.group('code').replace('\u2013', '-')), (None, ''))
            if sp is None:
                print(f'{tab}: unresolved code {grp} {m.group("code")}', file=sys.stderr); n_bad += 1; continue
        else:
            ms = re.match(r'^([A-Z][a-z]+ [a-z]+)\s*(.*)$', sp)
            if ms: sp, stage = ms.group(1), ms.group(2).strip()
        recs.append(dict(table=tab, taxon_group=grp, code=m.group('code').replace('\u2013', '-'), species=sp, stage=stage,
                         depth_m=t.group('depth'), temp_C=t.group('T'), dw_mg=t.group('dw'),
                         c_mg=t.group('c') or '', n_mg=t.group('n') or ''))
        n_ok += 1
    print(f'{tab}: parsed {n_ok}, skipped {n_bad}', file=sys.stderr)
with open('ikeda2014_esm_parsed.csv', 'w', newline='') as fh:
    w = csv.DictWriter(fh, fieldnames=list(recs[0].keys())); w.writeheader(); w.writerows(recs)
print('S4 entries', len(s4map), 'records', len(recs), 'species', len({r['species'] for r in recs}), file=sys.stderr)
print('groups', collections.Counter(r['taxon_group'] for r in recs), file=sys.stderr)
print('stages', collections.Counter(r['stage'] for r in recs).most_common(15), file=sys.stderr)
