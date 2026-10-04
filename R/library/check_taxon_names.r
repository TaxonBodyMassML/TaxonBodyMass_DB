# Guards on the taxon names (#28, #38, #48).
#
# CheckRawNames() runs right after FixFormatting() in section 2b of R/RunMe.r
# and stops the run when a raw name carried a bracket group or a trailing token
# that no row of audit/raw_name_patterns.csv covers (class 'error' in
# `raw_name_log`, fix_formatting.r). Such a name is left with its brackets, so
# it cannot pass for a binomial, and the owner is asked to classify the new
# pattern (add a row with its class and action) rather than have it folded
# away silently, which is how the 13 Makarieva subgenus names became
# unresolvable binomials (#38). The message lists every offending raw name
# with its sources and row counts. Returns the number of logged names,
# invisibly.
CheckRawNames <- function(log = raw_name_log) {
  tab <- RawNameLogTable(log)
  err <- tab[tab$error, , drop = FALSE]
  if (nrow(err) > 0) {
    by_name <- split(err, err$raw)
    lines <- vapply(by_name, function(e)
      sprintf("  '%s'  (%s)", e$raw[1],
              paste(sprintf('%s: %d row%s', e$source, e$rows, ifelse(e$rows == 1, '', 's')), collapse = ', ')),
      character(1))
    stop(sprintf(paste0(
      '%d raw taxon name(s) carry brackets or trailing tokens that no rule of ',
      'audit/raw_name_patterns.csv covers (see the error class of ',
      'reports/warnings_raw_names.md). Classify each pattern there (class and ',
      'action) or fix the source; nothing is folded away silently:\n%s'),
      length(by_name), paste(lines, collapse = '\n')), call. = FALSE)
  }
  invisible(nrow(tab))
}

# After the section-2b chain of R/RunMe.r (FixFormatting, FixMisspellings,
# RemoveNonTaxa, RemoveExtinct) every taxon must be a single token:
# 'Genus_species' for a species-level record or 'Genus' for a genus-level one,
# because section 3 tells the two apart by grepl('_'). FixFormatting turns
# every space into an underscore and leaves only letters and one underscore,
# so a name that still contains whitespace, a bracket, a digit or a third
# token can only have been written by a later step, i.e. by a replacement
# value of fix_misspellings.r (or another rename table) typed with a space
# instead of an underscore. Such a name fails the species test and is filed
# as a genus: 'Rhytonomus isabellina' sat in TaxonBodyMass_GenusLevel.csv as a
# genus row while the species was missing from TaxonBodyMass.csv (#28). The
# check is strict: `^[A-Z][A-Za-z]*(_[a-z][A-Za-z]*)?$` (the genus capitalised,
# the epithet starting lowercase; mixed case inside a token is allowed because
# FixFormatting only lowercases the first letter of the epithet, e.g.
# Edaphus_blYhweissi before its rename).
#
# CheckTaxonNames(source_list) runs one vectorised grepl over the bound names
# and stops with every offending name and the source labels (first token of
# source_mass) that carry it. NA names are not reported: they are the two
# records whose input name iconv() cannot transliterate in FixFormatting, and
# section 6 drops them as before. Returns the number of names checked,
# invisibly.
cleaned_name_re <- '^[A-Z][A-Za-z]*(_[a-z][A-Za-z]*)?$'

CheckTaxonNames <- function(source_list) {
  taxa <- unlist(lapply(source_list, `[[`, 'taxon'), use.names = FALSE)
  bad  <- !is.na(taxa) & !grepl(cleaned_name_re, taxa)
  if (any(bad)) {
    labels <- unlist(lapply(source_list, function(df)
      trimws(sub(';.*$', '', as.character(df$source_mass)))), use.names = FALSE)
    stopifnot(length(labels) == length(taxa))
    by_name <- tapply(labels[bad], taxa[bad],
                      function(l) paste(sort(unique(l)), collapse = ', '))
    stop(sprintf(paste0(
      '%d cleaned taxon name(s) are not Genus_species or Genus after the section 2b ',
      'cleaning chain (whitespace, brackets, digits, a third token, a lowercase genus ',
      'or an empty name). FixFormatting leaves no such name, so a replacement value in ',
      'R/library/fix_misspellings.r (or another rename table) is malformed:\n%s'),
      length(by_name),
      paste(sprintf("  '%s'  (%s)", names(by_name), by_name), collapse = '\n')),
      call. = FALSE)
  }
  invisible(length(taxa))
}

# The lab Sheet (R/RunMe.r section 4, tab BM_data) is bound after the
# section-2b chain and after CheckTaxonNames(), so a Sheet taxon passes
# neither FixFormatting() nor the guard above: the cell
# 'Lepidostoma_(genus_in_Opisthokonta)' reached the enrichment with its
# brackets and was listed as unresolved (#48). Every Sheet taxon must already
# be a cleaned name, 'Genus_species' or 'Genus', because the override of
# section 4 matches Sheet names against the cleaned source names by equality:
# a cell with brackets, whitespace, a digit, a lowercase genus or no name at
# all overrides nothing and enters as a malformed name (one with a space has
# no underscore and would be filed as a genus).
#
# CheckSheetTaxa(ddat) takes the Sheet rows that carry a mass (columns taxon,
# mass_g, source_mass) and returns them. A three-part name,
# 'Genus_species_subspecies' ('Osmerus_mordax_dentex' stood in BM_data until
# 2026-10-04), is folded to the species, as the raw-name rules fold the
# trinomials of the sources (audit/raw_name_patterns.csv, class trinomial),
# with a warning that names the row: the override is keyed by the species
# name, so the owner is asked to write the species in the Sheet. Every other
# malformed taxon stops the run with the offending rows (taxon, mass_g,
# source_mass) and a request to correct the Sheet; nothing is folded away
# silently (#38). fold_trinomials = FALSE makes a three-part name an error too.
sheet_trinomial_re <- '^([A-Z][A-Za-z]*_[a-z][A-Za-z]*)_[a-z][A-Za-z]*$'

CheckSheetTaxa <- function(ddat, fold_trinomials = TRUE) {
  need <- c('taxon', 'mass_g', 'source_mass')
  if (!is.data.frame(ddat) || !all(need %in% names(ddat)))
    stop('CheckSheetTaxa() needs the Sheet rows with the columns taxon, mass_g and source_mass', call. = FALSE)
  taxa <- as.character(ddat$taxon)
  Row  <- function(i, name = taxa[i]) sprintf("  taxon '%s'  mass_g %s  source_mass '%s'",
                                              ifelse(is.na(name), '<empty>', name),
                                              format(ddat$mass_g[i], trim = TRUE, digits = 6),
                                              ifelse(is.na(ddat$source_mass[i]), '<empty>', as.character(ddat$source_mass[i])))
  if (fold_trinomials) {
    tri <- !is.na(taxa) & grepl(sheet_trinomial_re, taxa, perl = TRUE)
    if (any(tri)) {
      folded <- sub(sheet_trinomial_re, '\\1', taxa[tri], perl = TRUE)
      warning(sprintf(paste0(
        '%d lab Sheet (BM_data) taxon name(s) have three parts and were folded to the species, as the raw-name ',
        'rules fold the trinomials of the sources; write the species name in the Sheet, which is what the ',
        'override is keyed by:\n%s'), sum(tri),
        paste(sprintf("%s  -> '%s'", vapply(which(tri), Row, character(1)), folded), collapse = '\n')),
        call. = FALSE, immediate. = TRUE)
      taxa[tri]  <- folded
      ddat$taxon <- taxa
    }
  }
  bad <- is.na(taxa) | !grepl(cleaned_name_re, taxa)
  if (any(bad)) {
    stop(sprintf(paste0(
      '%d row(s) of the lab Sheet (BM_data) carry a taxon that is not Genus_species or Genus (brackets, ',
      'whitespace, digits, a lowercase genus, a capitalised epithet, a third part that is not a lowercase ',
      'epithet, or an empty cell). The Sheet bypasses FixFormatting(), and the override matches Sheet names ',
      'against the cleaned source names by equality, so such a row overrides nothing and enters as a malformed ',
      "name. Correct the Sheet (e.g. 'Lepidostoma_(genus_in_Opisthokonta)' -> 'Lepidostoma', or delete the ",
      'row) and rerun:\n%s'), sum(bad), paste(vapply(which(bad), Row, character(1)), collapse = '\n')),
      call. = FALSE)
  }
  ddat
}
