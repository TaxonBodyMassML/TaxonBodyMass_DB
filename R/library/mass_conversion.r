# Conversion of dry mass, ash-free dry mass, carbon mass and energy content to
# wet (fresh) mass in grams, for sources that do not report wet mass directly.
#
# Every factor is a ratio of the numerator to the denominator mass type, taken
# from the cited compilation. `verified` records whether the number was read
# from the cited paper's text/tables (TRUE) or is a widely used generic value
# whose primary table could not be checked at the time of writing (FALSE).
# Adjust factors here, never in the per-source scripts.
#
# Sources
#  Kiorboe:2013aa   Kiørboe T. (2013) Zooplankton body composition. Limnol.
#                   Oceanogr. 58:1843-1850. Web Appendix Table A1 (raw per-record wet,
#                   dry and C masses; stored in sources/conversion_factors/Kiorboe_2013,
#                   downloaded 2026-09-30) gives species-level medians computed by
#                   summarise_tableA1.py: all crustacean zooplankton DW/WW 0.214 (n=50
#                   spp), C/WW 0.101 (n=48); gelatinous forms (Cnidaria, Ctenophora,
#                   Tunicata) DW/WW 0.039 (n=11), C/WW 0.0029 (n=7); Protista C/WW
#                   0.149 (n=24; 'wet mass' = cell volume at density 1). The paper's
#                   text ranges (gelatinous 4-5 % dry matter, ~0.5 % C; non-gelatinous
#                   15-25 % and 5-10 %) agree.
#  Lucas:2011aa     Lucas C.H. et al. (2011) What's in a jellyfish? Ecology
#                   92:1704 (Ecological Archives E092-144, body_composition.txt).
#                   Species medians recomputed 2026-09-27: C (%WW) = 0.46 (Cnidaria,
#                   n=10), 0.15 (Ctenophora, n=7), 0.59 (all jellyfish, n=19).
#  Studier:1992aa   Studier E.H. & Sevick S.H. (1992) Comp. Biochem. Physiol. A
#                   103:579-595. Water content of 360 insect species "consistent
#                   in the 60-70% range of live weight" -> dry mass 30-40 % of WW.
#  Menden-Deuer:2000aa  Menden-Deuer S. & Lessard E.J. (2000) Limnol. Oceanogr.
#                   45:569-579. Non-diatom protists: pg C = 0.216 * V^0.939
#                   (V in um^3). With density 1 g cm^-3 this gives C/WW of 0.14 at
#                   10^3 um^3 and 0.09 at 10^6 um^3, consistent with the Kiørboe
#                   Table A1 protist median (0.149) that is used.
#  Brey:2010aa      Brey T., Müller-Wiegmann C., Zittier Z.M.C. & Hagen W. (2010) Body
#                   composition in aquatic organisms - a global data bank of relationships
#                   between mass, elemental composition and energy content. J. Sea Res.
#                   64:334-340. Data bank Conversion04 (2012 update) downloaded 2026-09-30
#                   from thomas-brey.de; species-level medians computed by
#                   sources/conversion_factors/Brey_2010/summarise_conversion04.py
#                   (DM/WM shell-free, AFDM/DM, and record-level C/DM x DM/WM):
#                     fish (Osteichthyes+Chondrichthyes+Agnatha) 0.2415 / 0.8646 / 0.0834
#                     non-gelatinous invertebrates (all)          0.2144 / 0.8293 / 0.0946
#                     Mollusca (shell-free)                        0.1972 / 0.8578 / 0.0624
#                     Annelida                                     0.1769 / 0.8420 / 0.0504
#                     Chaetognatha                                 0.0785 / 0.8333 / 0.0268
#                     Echinodermata                                0.2250 / 0.4510 / 0.0471
#                   Cross-check: Brey Crustacea 0.222 / 0.843 / 0.1006 and Cnidaria
#                   0.044 / - / 0.0037 agree with the Kiørboe 2013 pelagic values used
#                   for crustacean_zooplankton and gelatinous_zooplankton.
#                   Energy branch (from = 'energy'; used for the Brey-data-bank rows of
#                   McCoy_2008, which are kJ per mean individual): the data bank's energy
#                   density 'J / mgWM' (sheet Data, 0-based column 40; J/mg = kJ/g wet
#                   mass, shell-free for molluscs) and the shell ratio 'WM / (WM+Shell)'
#                   (column 25), species-level medians re-derived 2026-10-02 by
#                   sources/conversion_factors/Brey_2010/summarise_conversion04_energy.py
#                   (conversion04_energy_medians.csv): kJ/g wet Bivalvia 3.0574 (44 spp),
#                   Gastropoda 3.9211 (27), Mollusca pooled 3.8817 (117), Echinoidea
#                   1.1609 (8), Ophiuroidea 2.0276 (7), Holothuroidea 1.7935 (11),
#                   Decapoda 3.8962 (134), Amphipoda 3.769 (27), Isopoda 2.2817 (5),
#                   Polychaeta 3.1341 (33), Insecta 4.5745 (13); WM/(WM+Shell) Bivalvia
#                   0.44 (17 spp), Gastropoda 0.40 (5), all Mollusca 0.40 (23). Dividing
#                   by the shell ratio turns the shell-free wet mass of a mollusc into
#                   whole wet mass including the shell, the basis used for molluscs in
#                   this database. Polyplacophora have no energy or shell record in the
#                   data bank (2 species without data), so 'polyplacophoran' borrows the
#                   pooled Mollusca energy density and the gastropod shell ratio
#                   (verified = FALSE). The same shell ratios serve the dry/afdw
#                   branches through ToWetMass(whole = TRUE, shell_group = ...), so
#                   that shelled taxa reported as tissue mass (Eklof_etal_2017) enter
#                   as whole wet mass as well; 'barnacle' holds the gastropod ratio by
#                   analogy because the data bank's 27 Cirripedia records carry no
#                   WM / (WM+Shell) value (verified = FALSE).
#  Horn:2016aa      Horn S. & de la Vega C. (2016) Relationships between fresh weight,
#                   dry weight, ash free dry weight, carbon and nitrogen content for
#                   selected vertebrates. J. Exp. Mar. Biol. Ecol. 481:41-48. The
#                   authors' PANGAEA deposit 894380 (17 Wadden Sea birds of 6 species,
#                   whole-bird wet mass and three subsamples each with wet, dry and
#                   ash-free dry mass and %C; CC BY 3.0, stored in
#                   sources/conversion_factors/Horn_2016, downloaded 2026-10-05) gives
#                   species-level medians computed by summarise_pangaea.py: DW/WW 0.3906
#                   (species means 0.3805-0.4340), AFDW/DW 0.8527, C/WW 0.1677 (the
#                   abstract's "0.16 to 0.22"). The seal deposit (894400) holds tissue
#                   samples only, so no seal group is derived.
#  Rizzuto:2019aa   Rizzuto M. et al. (2019) Patterns and potential drivers of
#                   intraspecific variability in the body C, N, and P composition of a
#                   terrestrial consumer, the snowshoe hare (Lepus americanus). Ecol.
#                   Evol. 9:14453-14464. The authors' figshare deposit (50 hares: whole
#                   wet mass and the wet and dry mass of the carcass homogenate, %C of
#                   dry mass; CC BY 4.0, stored in sources/conversion_factors/Rizzuto_2019)
#                   gives, by summarise_hares.py, DW/WW median 0.2925 (mean 0.2899,
#                   range 0.222-0.357) and C/WW median 0.1290. 'mammal' rests on this
#                   one species (the only mammal source converted, Gonzalez_2025, holds
#                   these very hares); other mammals would use it by analogy.
#  unverified       'helminth' reuses the Brey non-gelatinous invertebrate medians by
#                   analogy (the data bank holds 1 nematode and no flatworm species;
#                   Gonzalez_2025). 'vertebrate' keeps conventional values (Peters 1983,
#                   The Ecological Implications of Body Size) and carries no CiteID: it
#                   serves the reptiles of Gonzalez_2025, for which no citable factor has
#                   been verified, and the fishes and turtles of Vanni_2017, whose dry
#                   masses the compilers derived as DM = 0.25 WM, so that 0.25 is the
#                   exact inverse of their own factor.

# The first fourteen groups convert dry, ash-free dry and carbon mass; the eleven
# energy groups (bivalve ... aquatic_insect) convert energy content (kJ per
# individual) only and have no dry/AFDW/carbon factors; 'barnacle' carries only a
# shell ratio for ToWetMass(whole = TRUE).
MassConversionFactors <- data.frame(
  group = c('gelatinous_zooplankton', 'crustacean_zooplankton', 'insect', 'protist',
            'fish', 'invertebrate', 'mollusc', 'annelid', 'chaetognath', 'echinoderm',
            'helminth', 'vertebrate', 'bird', 'mammal',
            'bivalve', 'gastropod', 'polyplacophoran', 'echinoid', 'ophiuroid', 'holothurian',
            'decapod', 'amphipod', 'isopod', 'polychaete', 'aquatic_insect', 'barnacle'),
  # dry mass as a fraction of wet mass
  dw_per_ww   = c(0.039, 0.214, 0.35, NA,   0.2415, 0.2144, 0.1972, 0.1769, 0.0785, 0.2250, 0.2144, 0.25,
                  0.3906, 0.2925,
                  rep(NA, 12)),
  # ash-free dry mass as a fraction of dry mass (none measured for the hares)
  afdw_per_dw = c(0.70,  0.85, 0.90, NA,   0.8646, 0.8293, 0.8578, 0.8420, 0.8333, 0.4510, 0.8293, 0.85,
                  0.8527, NA,
                  rep(NA, 12)),
  # carbon mass as a fraction of wet mass (used directly for carbon -> wet);
  # gelatinous 0.004 sits between Kiørboe A1 (0.0029), Brey Cnidaria (0.0037) and
  # Lucas 2011 (0.0046-0.0059)
  c_per_ww    = c(0.004, 0.101, 0.175, 0.149, 0.0834, 0.0946, 0.0624, 0.0504, 0.0268, 0.0471, 0.0946, 0.11,
                  0.1677, 0.1290,
                  rep(NA, 12)),
  # energy density, kJ per g wet mass (Conversion04 'J / mgWM'; shell-free for
  # molluscs), for sources that report energy content per individual (from = 'energy')
  kj_per_g_ww = c(rep(NA, 14),
                  3.0574, 3.9211, 3.8817, 1.1609, 2.0276, 1.7935, 3.8962, 3.769, 2.2817, 3.1341, 4.5745, NA),
  # wet mass as a fraction of whole wet mass including the shell (Conversion04
  # 'WM / (WM+Shell)'); 1 where there is no shell. Applied in the energy branch,
  # whose output is always whole-animal wet mass, and in the dry/afdw/carbon
  # branches only when whole = TRUE (their factors refer to shell-free tissue).
  ww_per_whole = c(rep(NA, 14),
                   0.44, 0.40, 0.40, 1, 1, 1, 1, 1, 1, 1, 1, 0.40),
  citation = c('Kiorboe:2013aa; Lucas:2011aa', 'Kiorboe:2013aa',
               'Studier:1992aa (dw_per_ww); generic (others)', 'Kiorboe:2013aa; Menden-Deuer:2000aa',
               'Brey:2010aa', 'Brey:2010aa', 'Brey:2010aa', 'Brey:2010aa', 'Brey:2010aa', 'Brey:2010aa',
               'Brey:2010aa (non-gelatinous invertebrates, by analogy)', 'generic',
               'Horn:2016aa', 'Rizzuto:2019aa (snowshoe hare carcass homogenate; other mammals by analogy)',
               'Brey:2010aa', 'Brey:2010aa',
               'Brey:2010aa (Mollusca pooled energy density and gastropod shell ratio, by analogy)',
               'Brey:2010aa', 'Brey:2010aa', 'Brey:2010aa', 'Brey:2010aa', 'Brey:2010aa', 'Brey:2010aa',
               'Brey:2010aa', 'Brey:2010aa',
               'Brey:2010aa (gastropod shell ratio, by analogy; no Cirripedia shell record)'),
  # BM_citations CiteIDs appended to source_mass for converted records (see
  # ConversionCiteIDs); empty where only generic, uncited factors are used.
  cite_id = c('Kiorboe_2013; Lucas_2011', 'Kiorboe_2013', 'Studier_1992', 'Kiorboe_2013; MendenDeuer_2000',
              'Brey_2010', 'Brey_2010', 'Brey_2010', 'Brey_2010', 'Brey_2010', 'Brey_2010',
              'Brey_2010', '', 'Horn_2016', 'Rizzuto_2019',
              rep('Brey_2010', 12)),
  verified = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, TRUE, TRUE,
               TRUE, TRUE, FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE),
  stringsAsFactors = FALSE
)

# Convert a vector of masses (grams) of type `from` to wet grams; with
# from = 'energy' the input is energy content in kJ per individual and the result
# is whole-animal wet grams (kJ / kj_per_g_ww / ww_per_whole). The dry, afdw and
# carbon factors refer to shell-free tissue; `whole = TRUE` divides that tissue
# wet mass by the shell ratio ww_per_whole of `shell_group` (default `group`),
# giving whole wet mass including the shell, so shell_group must be a group with
# a shell ratio (bivalve, gastropod, polyplacophoran, barnacle).
# `from`, `group`, `whole` and `shell_group` are recycled against `value`.
ToWetMass <- function(value, from = c('wet', 'dry', 'afdw', 'carbon', 'energy'),
                      group = 'invertebrate', whole = FALSE, shell_group = group) {
  from  <- match.arg(tolower(from), c('wet', 'dry', 'afdw', 'carbon', 'energy'),
                     several.ok = TRUE)
  n     <- length(value)
  from  <- rep_len(from,  n)
  group <- rep_len(group, n)
  whole <- rep_len(as.logical(whole), n)
  shell_group <- rep_len(shell_group, n)
  bad <- setdiff(unique(group[from != 'wet']), MassConversionFactors$group)
  if (length(bad) > 0)
    stop('ToWetMass(): unknown mass_group: ', paste(bad, collapse = ', '))
  idx   <- match(group, MassConversionFactors$group)
  dw    <- MassConversionFactors$dw_per_ww[idx]
  afdw  <- MassConversionFactors$afdw_per_dw[idx]
  cww   <- MassConversionFactors$c_per_ww[idx]
  kj    <- MassConversionFactors$kj_per_g_ww[idx]
  whole_ratio <- MassConversionFactors$ww_per_whole[idx]
  out  <- value
  sel <- from == 'dry';    out[sel] <- value[sel] / dw[sel]
  sel <- from == 'afdw';   out[sel] <- value[sel] / (afdw[sel] * dw[sel])
  sel <- from == 'carbon'; out[sel] <- value[sel] / cww[sel]
  sel <- from == 'energy'; out[sel] <- value[sel] / kj[sel] / whole_ratio[sel]
  if (any(is.na(out) & !is.na(value)))
    stop('ToWetMass(): no factor for some from/group combination')
  if (any(whole & from == 'energy'))
    stop("ToWetMass(): from = 'energy' already returns whole wet mass; do not combine it with whole = TRUE")
  sel <- whole & from %in% c('dry', 'afdw', 'carbon')
  if (any(sel)) {
    ratio <- MassConversionFactors$ww_per_whole[match(shell_group[sel], MassConversionFactors$group)]
    if (any(is.na(ratio)))
      stop('ToWetMass(): no shell ratio (ww_per_whole) for shell_group: ',
           paste(unique(shell_group[sel][is.na(ratio)]), collapse = ', '))
    out[sel] <- out[sel] / ratio
  }
  out
}

# CiteIDs of the conversion references used for a mass_group (vectorised).
ConversionCiteIDs <- function(group) {
  idx <- match(group, MassConversionFactors$group)
  if (any(is.na(idx))) stop('ConversionCiteIDs(): unknown mass_group: ',
                            paste(unique(group[is.na(idx)]), collapse = ', '))
  MassConversionFactors$cite_id[idx]
}

# Source label with the conversion CiteIDs appended ('Label; Kiorboe_2013'),
# so that the references behind a converted body mass are cited with the taxon.
# Further group vectors (e.g. the shell_group of a whole-mass conversion) add
# their CiteIDs once each, in order. Records converted only with generic
# (uncited) factors keep the bare label.
LabelWithConversion <- function(label, group, ...) {
  groups <- list(group, ...)
  n      <- max(length(label), lengths(groups))
  label  <- rep_len(label, n)
  cites  <- lapply(groups, function(g) rep_len(ConversionCiteIDs(g), n))
  vapply(seq_len(n), function(i) {
    ids <- unlist(strsplit(vapply(cites, `[`, character(1), i), ';\\s*'))
    ids <- unique(ids[nzchar(ids)])
    if (length(ids) == 0) label[i] else paste(c(label[i], ids), collapse = '; ')
  }, character(1))
}

# Cell volume (um^3) to wet mass (g) assuming unit density.
CellVolumeToWetMass <- function(vol_um3, density_g_cm3 = 1) {
  vol_um3 * 1e-12 * density_g_cm3
}

# Cell volume (um^3) to carbon mass (g), Menden-Deuer & Lessard (2000).
CellVolumeToCarbon <- function(vol_um3, taxon = c('protist', 'diatom')) {
  taxon <- match.arg(taxon)
  pgC <- if (taxon == 'protist') 0.216 * vol_um3^0.939 else 0.288 * vol_um3^0.811
  pgC * 1e-12
}
