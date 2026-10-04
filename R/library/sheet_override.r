# The lab Sheet override (R/RunMe.r section 4; issues #48, #57).
#
# The Sheet (tab BM_data) holds lab-curated body masses that take priority
# over the compiled sources. Its rows are bound after the section-2b cleaning
# chain, checked by CheckSheetTaxa() (check_taxon_names.r) and matched against
# the cleaned source names by equality. Section 3 tells a species-level record
# from a genus-level one by the underscore ('Genus_species' against 'Genus'),
# and the Sheet rows are split by the same rule here (#57). Until then every
# Sheet row entered the species path, so a one-token Sheet taxon resolved to
# no species and was dropped as unresolved or, worse, was resolved to a
# species (ITIS made the genus-level value of Hypopomus a record of Hypopomus
# artedi), and it could not override a source's genus-only rows either.
#
#   species-level rows  replace every compiled record of the species, all
#                       sources, as before: the Sheet value is the species'
#                       only record;
#   genus-level rows    replace the sources' genus-only rows of that bare name
#                       (the rows written as the bare genus, matched by
#                       equality of the cleaned name, exactly as the species
#                       rows replace the compiled records of the species) and
#                       join the genus-only path of section 5b, where they are
#                       resolved at genus rank, filtered, combined per genus
#                       and source and de-duplicated like the sources' rows
#                       (enrich_genus.r, #49). The species-level values of the
#                       genus are not touched: a Sheet row 'Lepidostoma'
#                       replaces the sources' 'Lepidostoma' rows and leaves
#                       'Lepidostoma_hirtum' alone, and the genus mean of
#                       section 6 averages both.
#
# A Sheet taxon that no source carries is simply added. Base R only, so the
# tests (R/library/tests/test_sheet_override.R) run without packages.

sheet_row_columns <- c('taxon', 'mass_g', 'source_mass', 'n', 'kingdom', 'phylum', 'class', 'order', 'family')
sheet_hint_columns <- c('kingdom', 'phylum', 'class', 'order', 'family')

# The two halves of the checked Sheet rows by the rule of section 3: a name
# with an underscore is a species-level record, a name without one is
# genus-level. Row order is kept.
SplitSheetRows <- function(ddat) {
  is_genus <- !grepl('_', as.character(ddat$taxon), fixed = TRUE)
  list(species = ddat[!is_genus, , drop = FALSE], genus = ddat[is_genus, , drop = FALSE])
}

# The Sheet rows as the two paths take them: a plain data frame with the
# columns sheet_row_columns and nothing else (the Sheet's other columns are
# dropped), n = 1 per row and the classification hints kingdom..family NA
# (the Sheet gives none).
SheetRows <- function(ddat) {
  out <- as.data.frame(ddat, stringsAsFactors = FALSE)
  out$taxon       <- as.character(out$taxon)
  out$mass_g      <- as.numeric(out$mass_g)
  out$source_mass <- as.character(out$source_mass)
  if (!'n' %in% names(out)) out$n <- rep(1, nrow(out))
  for (col in sheet_hint_columns)
    if (!col %in% names(out)) out[[col]] <- rep(NA_character_, nrow(out))
  out <- out[, sheet_row_columns, drop = FALSE]
  rownames(out) <- NULL
  out
}

# rbind() for two data frames whose columns differ: a column one side lacks
# is NA in its rows (what dplyr::bind_rows() does; base R so the tests need
# no package). The rows of `a` come first; an empty side returns the other
# unchanged apart from the row names.
BindRowsFill <- function(a, b) {
  a <- as.data.frame(a, stringsAsFactors = FALSE)
  b <- as.data.frame(b, stringsAsFactors = FALSE)
  if (nrow(a) == 0) { rownames(b) <- NULL; return(b) }
  if (nrow(b) == 0) { rownames(a) <- NULL; return(a) }
  cols <- union(names(a), names(b))
  Fill <- function(d) {
    for (col in setdiff(cols, names(d))) d[[col]] <- rep(NA, nrow(d))
    d[, cols, drop = FALSE]
  }
  out <- rbind(Fill(a), Fill(b))
  rownames(out) <- NULL
  out
}

# Apply the override. `ddat`: the Sheet rows with a mass after CheckSheetTaxa()
# and NormaliseSourceLabel() (columns taxon, mass_g, source_mass; n and the
# hints are added by SheetRows()); `adat_raw`: the species-level source rows
# of section 3; `genus_only`: its genus-only rows. Returns
#   adat        the records of the species path: the Sheet's species-level
#               rows, then the source records of every other species;
#   genus_only  the rows of the genus-only path: the Sheet's genus-level rows,
#               then the source rows of every other bare name;
#   species, genus  the two halves of the Sheet as SheetRows() shapes them;
#   n_species_replaced, n_genus_replaced  how many Sheet names of each kind
#               had source rows to replace (the others are additions).
# The untouched source rows keep their order, so the Pass-1 summation order
# of every other name is as without the Sheet (#53).
ApplySheetOverride <- function(ddat, adat_raw, genus_only) {
  need <- c('taxon', 'mass_g', 'source_mass')
  if (!is.data.frame(ddat) || !all(need %in% names(ddat)))
    stop('ApplySheetOverride() needs the Sheet rows with the columns taxon, mass_g and source_mass', call. = FALSE)
  if (!is.data.frame(adat_raw) || !'taxon' %in% names(adat_raw) ||
      !is.data.frame(genus_only) || !'taxon' %in% names(genus_only))
    stop('ApplySheetOverride() needs the species-level and the genus-only source rows (data frames with a taxon column)', call. = FALSE)
  halves  <- SplitSheetRows(ddat)
  species <- SheetRows(halves$species)
  genus   <- SheetRows(halves$genus)
  keep_sp <- !(as.character(adat_raw$taxon)   %in% species$taxon)
  keep_go <- !(as.character(genus_only$taxon) %in% genus$taxon)
  list(adat       = BindRowsFill(species, adat_raw[keep_sp, , drop = FALSE]),
       genus_only = BindRowsFill(genus,   genus_only[keep_go, , drop = FALSE]),
       species    = species,
       genus      = genus,
       n_species_replaced = sum(unique(species$taxon) %in% as.character(adat_raw$taxon)),
       n_genus_replaced   = sum(unique(genus$taxon)   %in% as.character(genus_only$taxon)))
}
