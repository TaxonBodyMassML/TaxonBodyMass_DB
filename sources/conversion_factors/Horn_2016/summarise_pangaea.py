#!/usr/bin/env python3
"""Species-level body-composition ratios of the Wadden Sea birds of Horn & de la
Vega (2016, J. Exp. Mar. Biol. Ecol. 481:41-48) from the authors' PANGAEA deposit
894380 (PANGAEA_894380_birds.tab: 17 birds of 6 species, whole-bird wet mass and
three subsamples each with wet, dry, ash and ash-free dry mass, %C and %N of dry
mass). Per bird DW/WW = sum of the subsample dry masses / sum of their wet masses
(the paper fits linear relationships through the origin), AFDW/DW likewise, C/WW =
C fraction of dry mass x DW/WW; per species the mean over its birds; the group
value is the median over the six species (as for Kiørboe 2013 and Brey 2010).
Output: horn2016_species_ratios.csv (one row per species, a BIRDS_MEDIAN row).
The seal deposit 894400 (PANGAEA_894400_seals.tab) holds tissue samples of three
harbour seals and no whole-body dry mass; its tissue-pooled ratios are printed
for the record only."""
import csv, statistics, collections

def table(path):
    body = open(path, encoding='utf-8').read().split('*/\n', 1)[1].splitlines()
    hdr = body[0].split('\t')
    return hdr, [l.split('\t') for l in body[1:] if l.strip()]

hdr, rows = table('PANGAEA_894380_birds.tab')
assert hdr[9] == 'Wet m [g] (of bird)' and hdr[23].startswith('TC [%]') and hdr[24].startswith('TN [%]')
per = collections.defaultdict(list)
for r in rows:
    wets = [float(r[10 + 4 * i]) for i in range(3)]
    drys = [float(r[11 + 4 * i]) for i in range(3)]
    afdm = [float(r[13 + 4 * i]) for i in range(3)]
    dw_ww = sum(drys) / sum(wets)
    per[r[0]].append({'wet_bird_g': float(r[9]), 'dw_ww': dw_ww, 'afdw_dw': sum(afdm) / sum(drys),
                      'c_ww': float(r[23]) * dw_ww, 'n_ww': float(r[24]) * dw_ww})
out = []
for sp in sorted(per):
    b = per[sp]
    out.append({'species': sp, 'n_birds': len(b),
                'wet_mass_min_g': min(x['wet_bird_g'] for x in b), 'wet_mass_max_g': max(x['wet_bird_g'] for x in b),
                **{k: round(statistics.mean(x[k] for x in b), 4) for k in ('dw_ww', 'afdw_dw', 'c_ww', 'n_ww')}})
med = {k: round(statistics.median(r[k] for r in out), 4) for k in ('dw_ww', 'afdw_dw', 'c_ww', 'n_ww')}
out.append({'species': 'BIRDS_MEDIAN', 'n_birds': sum(r['n_birds'] for r in out), 'wet_mass_min_g': '', 'wet_mass_max_g': '', **med})
with open('horn2016_species_ratios.csv', 'w', newline='') as fh:
    w = csv.DictWriter(fh, fieldnames=list(out[0].keys())); w.writeheader(); w.writerows(out)
for r in out:
    print(f"{r['species']:28s} n={r['n_birds']:2d}  DW/WW {r['dw_ww']:.4f}  AFDW/DW {r['afdw_dw']:.4f}  C/WW {r['c_ww']:.4f}  N/WW {r['n_ww']:.4f}")

hdr, rows = table('PANGAEA_894400_seals.tab')
assert hdr[11].startswith('Wet m [g]') and hdr[12].startswith('Dry m [g]') and hdr[14].startswith('afdm [g]')
seal = collections.defaultdict(lambda: [0.0, 0.0, 0.0])
for r in rows:
    if len(r) > 14 and r[11].strip():
        for j, k in enumerate((11, 12, 14)): seal[r[1]][j] += float(r[k])
for k, (w, d, a) in sorted(seal.items()):
    print(f'Phoca vitulina {k} (tissue-pooled, not a whole-body value): DW/WW {d / w:.3f}  AFDW/DW {a / d:.3f}')
