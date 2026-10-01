# Ehnes, Rall & Brose (2011) terrestrial invertebrate respiration data set

Source: Ehnes, R. B., Rall, B. C., & Brose, U. (2011) Phylogenetic grouping, curvature and metabolic scaling in terrestrial invertebrates. Ecology Letters 14:993-1000. https://doi.org/10.1111/j.1461-0248.2011.01660.x
Data: Wiley supplementary material `ele_1660_sm_meta-scaling-appendix.pdf` (Appendix a: 3,661-record data set; b: respiration methods; c: analyses without Chown et al. 2007), downloaded by M. Novak 2026-10-01.

Parsing: `parse_ehnes_appendix.py` runs `pdftotext -layout` and reads each record from the right (J/h, weight, temperature) with the species as the Latin name before the numbers; output `ehnes2011_appendix_a.csv` (3,645 records; the 16 unparsed rows are unidentified taxa such as 'Species 1'). A 'PSeudophonus' typo is corrected.

Columns used: `sp` (species), `mg` (individual body weight, mg), group.1-4 (phylum, class/subclass, order, family).
Filters: species-level names only; 'sp.', 'cf.' and 'juv.' records dropped. 496 species. Individual records are averaged within species by RunMe Pass 1. About 200 records originate from Chown et al. 2007 (already a separate source); the cross-source range filter handles the overlap.
Mass type: live (fresh) body mass, mg -> g; no conversion.
