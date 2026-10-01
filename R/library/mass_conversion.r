# Conversion of dry mass, ash-free dry mass and carbon mass to wet (fresh) mass
# in grams, for sources that do not report wet mass directly.
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
#  unverified       'helminth' reuses the Brey non-gelatinous invertebrate medians by
#                   analogy (the data bank holds 1 nematode and no flatworm species);
#                   'vertebrate' (non-fish) keeps conventional values (Peters 1983,
#                   The Ecological Implications of Body Size). Neither is used by any
#                   current source.

MassConversionFactors <- data.frame(
  group = c('gelatinous_zooplankton', 'crustacean_zooplankton', 'insect', 'protist',
            'fish', 'invertebrate', 'mollusc', 'annelid', 'chaetognath', 'echinoderm',
            'helminth', 'vertebrate'),
  # dry mass as a fraction of wet mass
  dw_per_ww   = c(0.039, 0.214, 0.35, NA,   0.2415, 0.2144, 0.1972, 0.1769, 0.0785, 0.2250, 0.2144, 0.25),
  # ash-free dry mass as a fraction of dry mass
  afdw_per_dw = c(0.70,  0.85, 0.90, NA,   0.8646, 0.8293, 0.8578, 0.8420, 0.8333, 0.4510, 0.8293, 0.85),
  # carbon mass as a fraction of wet mass (used directly for carbon -> wet);
  # gelatinous 0.004 sits between Kiørboe A1 (0.0029), Brey Cnidaria (0.0037) and
  # Lucas 2011 (0.0046-0.0059)
  c_per_ww    = c(0.004, 0.101, 0.175, 0.149, 0.0834, 0.0946, 0.0624, 0.0504, 0.0268, 0.0471, 0.0946, 0.11),
  citation = c('Kiorboe:2013aa; Lucas:2011aa', 'Kiorboe:2013aa',
               'Studier:1992aa (dw_per_ww); generic (others)', 'Kiorboe:2013aa; Menden-Deuer:2000aa',
               'Brey:2010aa', 'Brey:2010aa', 'Brey:2010aa', 'Brey:2010aa', 'Brey:2010aa', 'Brey:2010aa',
               'Brey:2010aa (non-gelatinous invertebrates, by analogy)', 'generic'),
  # BM_citations CiteIDs appended to source_mass for converted records (see
  # ConversionCiteIDs); empty where only generic, uncited factors are used.
  cite_id = c('Kiorboe_2013; Lucas_2011', 'Kiorboe_2013', 'Studier_1992', 'Kiorboe_2013; MendenDeuer_2000',
              'Brey_2010', 'Brey_2010', 'Brey_2010', 'Brey_2010', 'Brey_2010', 'Brey_2010',
              'Brey_2010', ''),
  verified = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, FALSE),
  stringsAsFactors = FALSE
)

# Convert a vector of masses (grams) of type `from` to wet grams.
# `from` and `group` are recycled against `value`.
ToWetMass <- function(value, from = c('wet', 'dry', 'afdw', 'carbon'),
                      group = 'invertebrate') {
  from  <- match.arg(tolower(from), c('wet', 'dry', 'afdw', 'carbon'),
                     several.ok = TRUE)
  n     <- length(value)
  from  <- rep_len(from,  n)
  group <- rep_len(group, n)
  bad <- setdiff(unique(group[from != 'wet']), MassConversionFactors$group)
  if (length(bad) > 0)
    stop('ToWetMass(): unknown mass_group: ', paste(bad, collapse = ', '))
  idx  <- match(group, MassConversionFactors$group)
  dw   <- MassConversionFactors$dw_per_ww[idx]
  afdw <- MassConversionFactors$afdw_per_dw[idx]
  cww  <- MassConversionFactors$c_per_ww[idx]
  out  <- value
  sel <- from == 'dry';    out[sel] <- value[sel] / dw[sel]
  sel <- from == 'afdw';   out[sel] <- value[sel] / (afdw[sel] * dw[sel])
  sel <- from == 'carbon'; out[sel] <- value[sel] / cww[sel]
  if (any(is.na(out) & !is.na(value)))
    stop('ToWetMass(): no factor for some from/group combination')
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
# Records converted only with generic (uncited) factors keep the bare label.
LabelWithConversion <- function(label, group) {
  cites <- ConversionCiteIDs(group)
  ifelse(cites == '', label, paste0(label, '; ', cites))
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
