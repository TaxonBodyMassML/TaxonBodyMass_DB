#!/usr/bin/env python3
"""Dry-to-wet ratio of the snowshoe hares of Rizzuto et al. (2019, Ecol. Evol.
9:14453-14464) from the authors' figshare deposit 10.6084/m9.figshare.7884854
(HH_MorphRawData.csv: whole-hare wet mass `Hare_Weight` and the wet and dry mass
of the carcass homogenate sample, `WeightFinalSample_A` / `SampleDryWeight_A`;
SSH_C_data.csv: %C of dry mass, two replicates per hare). Per hare DW/WW =
SampleDryWeight_A / WeightFinalSample_A (the sample on which the elemental
analysis was made; five hares carry B and C replicates, not used), C/WW = mean
%C / 100 x DW/WW; the group value is the median over the 50 hares. Output:
rizzuto2019_hare_ratios.csv (one row per hare, a HARES_MEDIAN row)."""
import csv, statistics, collections

cpct = collections.defaultdict(list)
for r in csv.DictReader(open('SSH_C_data.csv')):
    cpct[r['SubmitterSampleID']].append(float(r['C']))
out = []
for r in csv.DictReader(open('HH_MorphRawData.csv')):
    if r['SpecimenLabel'].startswith('Test'): continue        # the trial dissection, not a study hare
    dw_ww = float(r['SampleDryWeight_A']) / float(r['WeightFinalSample_A'])
    c = statistics.mean(cpct[r['SpecimenLabel']]) / 100 if cpct[r['SpecimenLabel']] else None
    out.append({'hare': r['SpecimenLabel'], 'wet_mass_g': float(r['Hare_Weight']), 'dw_ww': round(dw_ww, 4),
                'c_ww': round(c * dw_ww, 4) if c is not None else ''})
assert len(out) == 50
med = {k: round(statistics.median(float(r[k]) for r in out if r[k] != ''), 4) for k in ('dw_ww', 'c_ww')}
out.append({'hare': 'HARES_MEDIAN', 'wet_mass_g': round(statistics.median(r['wet_mass_g'] for r in out), 1), **med})
with open('rizzuto2019_hare_ratios.csv', 'w', newline='') as fh:
    w = csv.DictWriter(fh, fieldnames=list(out[0].keys())); w.writeheader(); w.writerows(out)
d = [r['dw_ww'] for r in out[:-1]]
print(f"hares n={len(d)}  DW/WW median {statistics.median(d):.4f} mean {statistics.mean(d):.4f} range {min(d):.3f}-{max(d):.3f}  C/WW median {med['c_ww']:.4f}  wet mass median {out[-1]['wet_mass_g']} g")
