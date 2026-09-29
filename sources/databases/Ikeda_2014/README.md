# Ikeda (2014) marine metazooplankton dry masses

Source: Ikeda, T. (2014) Respiration and ammonia excretion by marine metazooplankton taxa: synthesis toward a global-bathymetric model. Marine Biology 161:2753-2766. https://doi.org/10.1007/s00227-014-2540-5
Data: Springer Electronic Supplementary Material `227_2014_2540_MOESM1_ESM.pdf` (tables S1 respiration, S2 ammonia excretion, S3 O:N ratio, S4 data codes -> species/stage), downloaded by M. Novak 2026-09-28.

Parsing: `parse_ikeda_esm.py` runs `pdftotext -layout`, splits each table's side-by-side column groups at the header positions, reads them in column order carrying the taxon-group label (COPE, EUPH, AMPH, DECA, MYSI, OSTR, CNID, CTEN, THAL, APPE, CHAE, MOLL, POLY) and species down through blank cells, and resolves 'see S4' codes through table S4. Output `ikeda2014_esm_parsed.csv` (1,101 of ~1,126 records; ~25 malformed lines skipped, e.g. codes '24S'/'24L', decimal depths, a truncated 'Tomopteris carpenteri' line). 'CHNI' in S3 is treated as a typo of CNID.

Columns used: species, stage, taxon_group, dw_mg (individual dry mass, mg).
Filters: copepodite stages C1-C5, juveniles (J) and stage text embedded in the species field (e.g. 'Calanoides acutus C4,5') are dropped; C6 adults, F/M/FG/A, salp aggregate/solitary forms and unstaged records are kept. Genus-level and 'misc' names dropped; subspecies/forms truncated to binomials.
Mass type: dry mass, mg -> g, converted with group factors in R/library/mass_conversion.r: crustacean groups -> crustacean_zooplankton (dry = 0.20 x wet), CNID/CTEN/THAL/APPE -> gelatinous_zooplankton (dry = 0.045 x wet), CHAE/MOLL/POLY -> generic invertebrate (dry = 0.20 x wet, unverified factor).
Source labels: 'Ikeda_2014; Kiorboe_2013' (crustaceans), 'Ikeda_2014; Kiorboe_2013; Lucas_2011' (gelatinous groups), 'Ikeda_2014' (CHAE/MOLL/POLY, generic uncited factor).
