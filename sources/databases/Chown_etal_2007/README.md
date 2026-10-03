# Chown et al. (2007) insect metabolic rate compilation

Source: Chown, S. L., Marais, E., Terblanche, J. S., Klok, C. J., Lighton, J. R. B., & Blackburn, T. M. (2007) Scaling of insect metabolic rate is inconsistent with the nutrient supply network model. Functional Ecology 21:282-290. https://doi.org/10.1111/j.1365-2435.2007.01245.x
Data: Wiley Supporting Information `fec1245_supmat.doc` (Appendix S1: eight size-polymorphic ant species; Appendix S2: literature compilation of insect body masses and metabolic rates); downloaded by M. Novak 2026-09-28. Parsed with `textutil -convert txt` and a Python parser anchored on the Method/Wing-status columns into `AppendixS1_ant_mass_parsed.csv` (244 ant records) and `AppendixS2_insect_mass_parsed.csv` (347 records, 338 taxa; EndNote field codes stripped).

Columns used: Species, Mass (mg), Family, Order.
Filters: unidentified taxa ('Species 1', 'sp.', 'nr.') dropped; subspecies truncated.
Mass type: live body mass (mg -> g), as used in the paper's metabolic-scaling analysis; no conversion.
Imputed rows: none flagged in source (measured masses of the metabolic-rate specimens).
