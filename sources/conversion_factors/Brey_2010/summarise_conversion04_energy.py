#!/usr/bin/env python3
"""Species-level median energy density and shell ratio by class/order from Brey
et al. (2010) Conversion04 data bank (thomas-brey.de, 2012 update), for the
energy branch of R/library/mass_conversion.r (from = 'energy').

Reads sheet 'Data' of Conversion04.xlsm (unzipped from Conversion04.zip), averages
records within species, then takes group medians. Columns used (0-based):
2 species, 6 order, 7 class, 8 major taxon, 9 regnum, 25 WM / (WM+Shell) (wet
mass as a fraction of whole wet mass including the shell), 40 J / mgWM (energy
density per mg wet mass, shell-free for molluscs; J/mg = kJ/g), 44 J / mgAFDM
(for reference). Output: conversion04_energy_medians.csv. Polyplacophora have
no energy or shell record (2 species without data), which is why
mass_conversion.r borrows the pooled Mollusca energy density and the gastropod
shell ratio for them.
"""
import csv, statistics, collections, zipfile, io, warnings
import openpyxl
warnings.filterwarnings('ignore')
with zipfile.ZipFile('Conversion04.zip') as z:
    data = z.read('Conversion04.xlsm')
wb = openpyxl.load_workbook(io.BytesIO(data), read_only=True, data_only=True)
rows = list(wb['Data'].iter_rows(values_only=True))[5:]
def num(x):
    try:
        v = float(x); return v if v > 0 else None
    except Exception:
        return None
rec = [dict(sp=str(r[2]).strip(), order=str(r[6] or '').strip(), cls=str(r[7] or '').strip(),
            major=str(r[8] or '').strip(), reg=str(r[9] or '').strip(),
            shell=num(r[25]), jwm=num(r[40]), jafdm=num(r[44]))
       for r in rows if len(r) > 44 and r[2]]
anim = [x for x in rec if x['reg'] == 'Animalia']
groups = collections.OrderedDict([
    ('bivalve',         ('class Bivalvia',        lambda x: x['cls'] == 'Bivalvia')),
    ('gastropod',       ('class Gastropoda',      lambda x: x['cls'] == 'Gastropoda')),
    ('polyplacophoran', ('class Polyplacophora',  lambda x: x['cls'] == 'Polyplacophora')),
    ('mollusca_pooled', ('major taxon Mollusca',  lambda x: x['major'] == 'Mollusca')),
    ('echinoid',        ('class Echinoidea',      lambda x: x['cls'] == 'Echinoidea')),
    ('ophiuroid',       ('class Ophiuroidea',     lambda x: x['cls'] == 'Ophiuroidea')),
    ('holothurian',     ('class Holothuroidea',   lambda x: x['cls'] == 'Holothuroidea')),
    ('decapod',         ('order Decapoda',        lambda x: x['order'] == 'Decapoda')),
    ('amphipod',        ('order Amphipoda',       lambda x: x['order'] == 'Amphipoda')),
    ('isopod',          ('order Isopoda',         lambda x: x['order'] == 'Isopoda')),
    ('polychaete',      ('class Polychaeta',      lambda x: x['cls'] == 'Polychaeta')),
    ('aquatic_insect',  ('major taxon Insecta',   lambda x: x['major'] == 'Insecta')),
])
def spmed(sub, key):
    d = collections.defaultdict(list)
    for x in sub:
        if x[key] is not None:
            d[x['sp']].append(x[key])
    m = [statistics.mean(v) for v in d.values()]
    return (round(statistics.median(m), 4) if m else '', len(m), sum(len(v) for v in d.values()))
out = []
for g, (label, f) in groups.items():
    sub = [x for x in anim if f(x)]
    j, nj, rj = spmed(sub, 'jwm'); ja, nja, rja = spmed(sub, 'jafdm'); s, ns, rs = spmed(sub, 'shell')
    out.append({'group': g, 'selector': label, 'n_records': len(sub),
                'kj_per_g_ww_median': j, 'kj_per_g_ww_n_species': nj, 'kj_per_g_ww_n_records': rj,
                'kj_per_g_afdw_median': ja, 'kj_per_g_afdw_n_species': nja,
                'ww_per_whole_median': s, 'ww_per_whole_n_species': ns, 'ww_per_whole_n_records': rs})
with open('conversion04_energy_medians.csv', 'w', newline='') as fh:
    w = csv.DictWriter(fh, fieldnames=list(out[0].keys()), lineterminator='\n'); w.writeheader(); w.writerows(out)
for r in out:
    print(f"{r['group']:16s} {r['selector']:24s} kJ/gWM {str(r['kj_per_g_ww_median']):7s} (n={r['kj_per_g_ww_n_species']:3d} spp)  "
          f"kJ/gAFDM {str(r['kj_per_g_afdw_median']):8s} (n={r['kj_per_g_afdw_n_species']:3d})  WM/(WM+Shell) {str(r['ww_per_whole_median']):5s} (n={r['ww_per_whole_n_species']:2d} spp)")
