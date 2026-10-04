# Guard on the cleaned taxon names (#28).
#
# After the section-2b chain of R/RunMe.r (FixFormatting, FixMisspellings,
# RemoveNonTaxa, RemoveExtinct) every taxon must be a single token:
# 'Genus_species' for a species-level record or 'Genus' for a genus-level one,
# because section 3 tells the two apart by grepl('_'). FixFormatting turns
# every space into an underscore, so a name that still contains whitespace can
# only have been written by a later step, i.e. by a replacement value of
# fix_misspellings.r (or another rename table) typed with a space instead of
# an underscore. Such a name fails the species test and is filed as a genus:
# 'Rhytonomus isabellina' sat in TaxonBodyMass_GenusLevel.csv as a genus row
# while the species was missing from TaxonBodyMass.csv. On the 2026-10-03
# frames no name legitimately carries whitespace at this stage (0 of 610,901
# rows once that value is fixed), so the check is strict.
#
# CheckTaxonNames(source_list) runs one vectorised grepl over the bound names
# and stops with every offending name (whitespace or empty) and the source
# labels (first token of source_mass) that carry it. NA names are not
# reported: they are the two records whose input name iconv() cannot
# transliterate in FixFormatting, and section 6 drops them as before. Returns
# the number of names checked, invisibly.
CheckTaxonNames <- function(source_list) {
  taxa <- unlist(lapply(source_list, `[[`, 'taxon'), use.names = FALSE)
  bad  <- !is.na(taxa) & !grepl('^[^[:space:]]+$', taxa)
  if (any(bad)) {
    labels <- unlist(lapply(source_list, function(df)
      trimws(sub(';.*$', '', as.character(df$source_mass)))), use.names = FALSE)
    stopifnot(length(labels) == length(taxa))
    by_name <- tapply(labels[bad], taxa[bad],
                      function(l) paste(sort(unique(l)), collapse = ', '))
    stop(sprintf(paste0(
      '%d cleaned taxon name(s) are not a single token after the section 2b ',
      'cleaning chain (whitespace or empty). Every name must be Genus_species ',
      'or Genus, so a replacement value in R/library/fix_misspellings.r (or ',
      'another rename table) is malformed:\n%s'),
      length(by_name),
      paste(sprintf("  '%s'  (%s)", names(by_name), by_name), collapse = '\n')),
      call. = FALSE)
  }
  invisible(length(taxa))
}
