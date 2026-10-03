#!/usr/bin/env python3
"""Parse Ikeda (2014, Mar Biol 161:2753) ESM tables S1-S4 (PDF) into a CSV.

The ESM PDF is laid out in 3-4 side-by-side column groups per table. We run
`pdftotext -layout`, split each line at the header positions of the 'Taxon'/'Taxa'
labels, and read the column groups in reading order (top to bottom, left to
right), carrying the taxon-group label (COPE, EUPH, ...) and, in S4, the species
name down through blank cells. Records in S1-S3 that say 'see S4' are resolved
through the (group, code) -> species/stage table S4. The Reference column of
S1-S3 (author-year key of the primary study) is printed only on the first record
of each run of records from one study; it is validated, canonicalised and filled
down in reading order (also across malformed lines) into the last column, `ref`.
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
# Reference key: author text (no digits or parentheses) followed by '(YYYY)', '(YYYYa)' or
# '(unpublished data)', e.g. 'Ikeda (1974)', 'Ikeda and Bruce (1986)', 'Cetta et al. (1986)',
# 'Ikeda (2013a)'. Anything else in the reference position ('outlier!', footnote fragments) is
# reported and ignored.
ref_re = re.compile(r'^[A-Z][^()\d]*\((?:\d{4}[a-d]?|unpublished data)\)$')
# Typographic variants in the ESM -> the spelling used elsewhere in the tables
ref_canon = {'Ikeda et al. ( 2001)': 'Ikeda et al. (2001)',
             'Lombard et al .(2005)': 'Lombard et al. (2005)',
             'Kaeriyama & Ikeda (2004)': 'Kaeriyama and Ikeda (2004)',
             'Ikeda unpublished data': 'Ikeda (unpublished data)'}
ref_tail_re = re.compile(r'(?P<ref>' + '|'.join(map(re.escape, ref_canon)) +
                         r'|[A-Z][^()\d]*\((?:\d{4}[a-d]?|unpublished data)\))\s*$')

def ref_key(text):
    """Canonical reference key for the text of a reference cell, or None if it is not a valid key."""
    text = ' '.join(text.split())
    text = ref_canon.get(text, text)
    return text if ref_re.match(text) else None

def ref_key_tail(line):
    """Canonical reference key printed at the end of a line that is not a parsed record, or None."""
    m = ref_tail_re.search(line)
    return ref_key(m.group('ref')) if m else None

for tab in ['S1', 'S2', 'S3']:
    block = lines[bounds[tab][0]:bounds[tab][1]]
    hi, offs = header_offsets(block, r'Tax(?:on|a)')
    grp = None; cur_ref = None; n_ok = n_bad = n_ref = n_ref_skip = 0
    for piece in chunks(block, hi, offs):
        if not piece.strip():
            continue
        is_title = piece.strip().startswith(('Tax', 'S1', 'S2', 'S3'))
        m = None if is_title else rec_re.match(piece)
        if not m:
            # A key printed on a line that is not parsed as a record still starts a run of records
            # in the PDF: consume it so that the fill-down below stays in step with the tables.
            key = ref_key_tail(piece)
            if key:
                cur_ref = key; n_ref_skip += 1
            elif re.search(r'[^\d\s]\s*$', piece):
                print(f'{tab}: ignored trailing text', repr(piece.strip()[-45:]), file=sys.stderr)
            if not is_title:
                n_bad += 1
                if n_bad <= 4: print(f'{tab} skipped:', repr(piece.strip()[:90]), file=sys.stderr)
            continue
        if m.group('grp'): grp = {'CHNI': 'CNID'}.get(m.group('grp'), m.group('grp'))  # CHNI is a typo for CNID in S3
        raw_ref = (m.group('ref') or '').strip()
        if raw_ref:
            key = ref_key(raw_ref)
            if key:
                cur_ref = key; n_ref += 1
            else:
                print(f'{tab} {grp} {m.group("code")}: ignored reference text', repr(raw_ref), file=sys.stderr)
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
        if cur_ref is None:
            print(f'{tab} {grp} {m.group("code")}: no reference key yet', file=sys.stderr)
        recs.append(dict(table=tab, taxon_group=grp, code=m.group('code').replace('\u2013', '-'), species=sp, stage=stage,
                         depth_m=t.group('depth'), temp_C=t.group('T'), dw_mg=t.group('dw'),
                         c_mg=t.group('c') or '', n_mg=t.group('n') or '', ref=cur_ref or ''))
        n_ok += 1
    print(f'{tab}: parsed {n_ok}, skipped {n_bad}, explicit refs {n_ref} (+{n_ref_skip} on lines that are not records)', file=sys.stderr)
with open('ikeda2014_esm_parsed.csv', 'w', newline='') as fh:
    w = csv.DictWriter(fh, fieldnames=list(recs[0].keys())); w.writeheader(); w.writerows(recs)
print('S4 entries', len(s4map), 'records', len(recs), 'species', len({r['species'] for r in recs}), file=sys.stderr)
print('groups', collections.Counter(r['taxon_group'] for r in recs), file=sys.stderr)
print('stages', collections.Counter(r['stage'] for r in recs).most_common(15), file=sys.stderr)
refs = collections.Counter(r['ref'] for r in recs)
print(f'records with ref {sum(bool(r["ref"]) for r in recs)}/{len(recs)}, distinct refs {len(refs)}', file=sys.stderr)
print('refs', sorted(refs.items(), key=lambda kv: (-kv[1], kv[0])), file=sys.stderr)
