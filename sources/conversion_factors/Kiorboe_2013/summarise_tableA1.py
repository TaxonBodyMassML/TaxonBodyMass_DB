#!/usr/bin/env python3
"""Species-level median body-composition ratios by group from Kiørboe (2013,
Limnol. Oceanogr. 58:1843) Web Appendix Table A1 (Kiorboe2013_TableA1.csv, parsed
from the Wiley supplement 1843a.html). Ratios are computed per record (dry/wet,
C/wet, C/dry), averaged within species (name lower-cased, stage/sex suffix kept),
then the group median is taken. Output: tableA1_group_medians.csv."""
import csv, re, statistics, collections
def num(x):
    x = (x or '').replace('−', '-').replace('–', '-').strip()
    try: v = float(x); return v if v > 0 else None
    except ValueError: return None
rows = list(csv.DictReader(open('Kiorboe2013_TableA1.csv', encoding='utf-8')))
per = collections.defaultdict(lambda: collections.defaultdict(list))
for r in rows:
    g, sp = r['Group'].strip(), r['Species'].strip().lower()
    w, d, c = num(r['Wet mass (mg)']), num(r['Dry mass (mg)']), num(r['C (mg)'])
    if w and d: per[(g, sp)]['dw_ww'].append(d / w)
    if w and c: per[(g, sp)]['c_ww'].append(c / w)
    if d and c: per[(g, sp)]['c_dw'].append(c / d)
crust = {'Copepoda', 'Euphausiacea', 'Amphipoda', 'Decapoda', 'Mysidacea', 'Ostracoda', 'Cumacea', 'Isopoda', 'Stomatopoda', 'Tanaidacea'}
gel = {'Cnidaria', 'Ctenophora', 'Tunicata'}
groups = sorted({g for g, _ in per}) + ['ALL_CRUSTACEA', 'ALL_GELATINOUS']
out = []
for g in groups:
    keys = [k for k in per if (k[0] == g) or (g == 'ALL_CRUSTACEA' and k[0] in crust) or (g == 'ALL_GELATINOUS' and k[0] in gel)]
    row = {'group': g, 'n_species': len(keys)}
    for ratio in ['dw_ww', 'c_ww', 'c_dw']:
        m = [statistics.mean(per[k][ratio]) for k in keys if per[k][ratio]]
        row[f'{ratio}_n_species'] = len(m)
        row[f'{ratio}_median'] = round(statistics.median(m), 4) if m else ''
        row[f'{ratio}_q25'] = round(statistics.quantiles(m, n=4)[0], 4) if len(m) >= 4 else ''
        row[f'{ratio}_q75'] = round(statistics.quantiles(m, n=4)[2], 4) if len(m) >= 4 else ''
    out.append(row)
with open('tableA1_group_medians.csv', 'w', newline='') as fh:
    w = csv.DictWriter(fh, fieldnames=list(out[0].keys())); w.writeheader(); w.writerows(out)
for r in out:
    print(f"{r['group']:16s} spp={r['n_species']:3d}  DW/WW {str(r['dw_ww_median']):7s} (n={r['dw_ww_n_species']:3d})  C/WW {str(r['c_ww_median']):7s} (n={r['c_ww_n_species']:3d})  C/DW {str(r['c_dw_median']):7s} (n={r['c_dw_n_species']:3d})")
