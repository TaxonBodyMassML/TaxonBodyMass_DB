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
#                   Oceanogr. 58:1843-1850. Results/Table 1: gelatinous forms
#                   (cnidarians, ctenophores, pelagic tunicates) converge on dry
#                   matter 4-5 % and C ~0.5 % of live weight; non-gelatinous
#                   zooplankton 15-25 % dry matter and 5-10 % C of live weight.
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
#                   10^3 um^3 and 0.09 at 10^6 um^3; 0.12 is used as the mid-value.
#  generic          Values marked verified = FALSE are the conventional ratios
#                   (dry mass ~20-25 % of wet mass in soft-bodied aquatic
#                   invertebrates and fish, ~45-50 % C in dry mass) used
#                   throughout the size-spectrum literature (e.g. Peters 1983,
#                   The Ecological Implications of Body Size; Brey et al. 2010
#                   J. Sea Res. 64:334 data bank). Replace with data-bank means
#                   once checked.

MassConversionFactors <- data.frame(
  group = c('gelatinous_zooplankton', 'crustacean_zooplankton', 'insect',
            'protist', 'fish', 'invertebrate', 'helminth', 'vertebrate'),
  # dry mass as a fraction of wet mass
  dw_per_ww = c(0.045, 0.20, 0.35, NA,   0.22, 0.20, 0.20, 0.25),
  # ash-free dry mass as a fraction of dry mass
  afdw_per_dw = c(0.70, 0.85, 0.90, NA,  0.85, 0.85, 0.85, 0.85),
  # carbon mass as a fraction of wet mass (used directly for carbon -> wet)
  c_per_ww = c(0.005, 0.075, 0.175, 0.12, 0.10, 0.09, 0.09, 0.11),
  citation = c('Kiorboe:2013aa; Lucas:2011aa', 'Kiorboe:2013aa',
               'Studier:1992aa (dw_per_ww); generic (others)',
               'Menden-Deuer:2000aa', 'generic', 'generic', 'generic', 'generic'),
  verified = c(TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE),
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
