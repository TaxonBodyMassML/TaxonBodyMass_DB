#!/usr/bin/env python3
"""Species-level median conversion ratios by taxon group from Brey et al. (2010)
Conversion04 data bank (thomas-brey.de, 2012 update). Reads sheet 'Data' of
Conversion04.xlsm (unzipped from Conversion04.zip), averages records within species,
then takes group medians. Columns used (0-based): 2 species, 7 class, 8 major taxon,
9 regnum, 28 DM/WM (shell-free), 29 AFDM/DM, 34 C/DM. C/WM is the record-level
product C/DM x DM/WM where both are present. Output: conversion04_group_medians.csv.
"""
import csv, statistics, collections, zipfile, io, openpyxl
with zipfile.ZipFile('Conversion04.zip') as z:
    data = z.read('Conversion04.xlsm')
wb = openpyxl.load_workbook(io.BytesIO(data), read_only=True, data_only=True)
rows = list(wb['Data'].iter_rows(values_only=True))[5:]
def num(x):
    try: v = float(x); return v if v > 0 else None
    except Exception: return None
rec = [dict(sp=str(r[2]).strip(), cls=str(r[7] or '').strip(), major=str(r[8] or '').strip(),
            reg=str(r[9] or '').strip(), dmwm=num(r[28]), afdm=num(r[29]), cdm=num(r[34]))
       for r in rows if len(r) > 40 and r[2]]
anim = [x for x in rec if x['reg'] == 'Animalia']
fish_major = ('Osteichthyes', 'Chondrichthyes', 'Agnatha')
gel_major = ('Cnidaria', 'Ctenophora', 'Tunicata')
groups = collections.OrderedDict([
    ('fish',            lambda x: x['major'] in fish_major),
    ('crustacea',       lambda x: x['major'] == 'Crustacea'),
    ('insecta_aquatic', lambda x: x['major'] == 'Insecta'),
    ('mollusca_shellfree', lambda x: x['major'] == 'Mollusca'),
    ('annelida',        lambda x: x['major'] == 'Annelida'),
    ('chaetognatha',    lambda x: x['major'] == 'Chaetognatha'),
    ('echinodermata',   lambda x: x['major'] == 'Echinodermata'),
    ('cnidaria',        lambda x: x['major'] == 'Cnidaria'),
    ('ctenophora',      lambda x: x['major'] == 'Ctenophora'),
    ('tunicata',        lambda x: x['major'] == 'Tunicata'),
    ('nematoda',        lambda x: x['major'] == 'Nemata'),
    ('platyhelminthes', lambda x: x['major'] == 'Plathelminthes'),
    ('nongelatinous_invertebrates', lambda x: x['major'] not in fish_major + gel_major + ('Cephalochordata',)),
])
def spmeans(sub, key):
    d = collections.defaultdict(list)
    for x in sub:
        if x[key] is not None: d[x['sp']].append(x[key])
    return [statistics.mean(v) for v in d.values()]
out = []
for g, f in groups.items():
    sub = [x for x in anim if f(x)]
    row = {'group': g, 'n_records': len(sub)}
    for key, name in [('dmwm', 'dm_per_wm'), ('afdm', 'afdm_per_dm'), ('cdm', 'c_per_dm')]:
        m = spmeans(sub, key)
        row[f'{name}_n_species'] = len(m)
        row[f'{name}_median'] = round(statistics.median(m), 4) if m else ''
        row[f'{name}_q25'] = round(statistics.quantiles(m, n=4)[0], 4) if len(m) >= 4 else ''
        row[f'{name}_q75'] = round(statistics.quantiles(m, n=4)[2], 4) if len(m) >= 4 else ''
    both = [x['cdm'] * x['dmwm'] for x in sub if x['cdm'] and x['dmwm']]
    row['c_per_wm_n_records'] = len(both)
    row['c_per_wm_median'] = round(statistics.median(both), 4) if both else ''
    out.append(row)
with open('conversion04_group_medians.csv', 'w', newline='') as fh:
    w = csv.DictWriter(fh, fieldnames=list(out[0].keys())); w.writeheader(); w.writerows(out)
for r in out:
    print(f"{r['group']:28s} DM/WM {str(r['dm_per_wm_median']):7s} (n={r['dm_per_wm_n_species']:4d})  AFDM/DM {str(r['afdm_per_dm_median']):7s}  C/DM {str(r['c_per_dm_median']):7s} (n={r['c_per_dm_n_species']:3d})  C/WM {str(r['c_per_wm_median']):7s} (n={r['c_per_wm_n_records']})")
