# Shared helpers for the per-study unit audits of food-web compilations
# (issue #14: sources/databases/Brose_etal_2018/foodweb_units_analysis.r and
# sources/databases/DataRetriever/brose2005_units_analysis.r). Nothing here is
# used by RunMe.r.
#
# The audits reproduce what the parse scripts and RunMe.r sections 2b-5 let
# through (name cleaning, species resolution through sources/enrich_cache.Rdata,
# autotroph filter), take a within-study geometric mean per accepted species and
# compare it with the median of the Pass-1 (species x source label) geometric
# means of all other cached sources. Conversion CiteIDs appended by
# LabelWithConversion() ('Eklof_etal_2017; Brey_2010') are stripped before the
# label is read, so one source is never counted twice.

suppressPackageStartupMessages(library(dplyr))

# Source the pipeline helpers into the global environment (filter_extinct.r
# needs `wd_root` there) and load the enrichment cache once.
UnitAuditInit <- function(wd_root) {
  assign('wd_root', wd_root, envir = .GlobalEnv)
  for (f in c('helpers.r', 'mass_conversion.r', 'foodweb_units.r', 'fix_formatting.r',
              'fix_misspellings.r', 'fix_nontaxa.r', 'filter_extinct.r', 'filter_autotrophs.r'))
    source(file.path(wd_root, 'R', 'library', f), local = FALSE)
  e <- new.env(); load(file.path(wd_root, 'sources', 'enrich_cache.Rdata'), envir = e)
  ec <- e$enrich_cache[, c('taxon', 'species', 'genus', 'kingdom', 'phylum', 'class', 'order', 'family')]
  assign('unit_audit_enrich', ec[!duplicated(ec$taxon), ], envir = .GlobalEnv)
  conv <- unique(trimws(unlist(strsplit(MassConversionFactors$cite_id, ';'))))
  assign('unit_audit_conv_ids', conv[nzchar(conv)], envir = .GlobalEnv)
  invisible(TRUE)
}

# RunMe.r 2b-5 for a frame with columns taxon, mass_g, source_mass (+ anything):
# returns the rows that resolve to an accepted, non-autotroph species, with the
# enrichment columns attached.
CleanResolve <- function(df) {
  df <- FixFormatting(df)
  df$source_mass <- NormaliseSourceLabel(df$source_mass)
  df <- FixMisspellings(df)
  df <- RemoveNonTaxa(df)
  df <- RemoveExtinct(df)
  df <- df[grepl('_', df$taxon, fixed = TRUE), ]            # species-level names only
  df <- df[, setdiff(names(df), c('kingdom', 'phylum', 'class', 'order', 'family', 'genus', 'species'))]
  df <- merge(df, unit_audit_enrich, by = 'taxon', all.x = TRUE)
  df <- FilterAutotrophs(df)
  df[!is.na(df$species), ]
}

# Data-source label of a source_mass string, conversion CiteIDs removed.
BaseLabel <- function(s) {
  u <- unique(s)
  b <- vapply(u, function(x) {
    toks <- trimws(strsplit(x, ';', fixed = TRUE)[[1]])
    toks <- toks[!toks %in% unit_audit_conv_ids]
    if (length(toks) == 0) NA_character_ else toks[1]
  }, character(1))
  unname(b[match(s, u)])
}

# Pass-1 table (species, label, lg = log10 geometric mean, n) over every cached
# frame except `exclude_files`; labels in `exclude_labels` are dropped.
LoadOtherPass1 <- function(wd_rdata, exclude_files = character(0), exclude_labels = character(0)) {
  rd  <- list.files(wd_rdata, pattern = '\\.Rdata$', full.names = TRUE)
  rd  <- rd[basename(rd) %!in% exclude_files]
  oth <- bind_rows(lapply(rd, function(f) {
    e <- new.env(); load(f, envir = e)
    df <- as.data.frame(get(ls(e)[1], envir = e))
    df <- df[, intersect(c('taxon', 'mass_g', 'source_mass'), names(df))]
    df$taxon <- as.character(df$taxon); df$source_mass <- as.character(df$source_mass)
    df$mass_g <- suppressWarnings(as.numeric(df$mass_g))
    df[!is.na(df$mass_g) & df$mass_g > 0 & !is.na(df$taxon), ]
  }))
  oth$label <- BaseLabel(oth$source_mass)
  oth <- oth[!is.na(oth$label), ]
  oth <- CleanResolve(oth)
  p1  <- oth %>% group_by(species, label) %>%
    summarise(lg = mean(log10(mass_g)), n = n(), .groups = 'drop')
  p1[p1$label %!in% exclude_labels, ]
}

# Per-species reference value: median over labels of the Pass-1 log10 means.
OtherSummary <- function(p1, exclude = character(0)) {
  p1 %>% filter(label %!in% exclude) %>% group_by(species) %>%
    summarise(other_lg = median(lg), other_min = min(lg), other_max = max(lg),
              n_other = n(), other_labels = paste(label, collapse = '|'), .groups = 'drop')
}

# Mass values that several species of one study share are group-level defaults
# ("placeholders"), not species measurements. Returns, per study, the set of
# values carried by >= min_species species (species with one value only).
PlaceholderValues <- function(d, study_col, min_species = 5) {
  d %>% filter(n_values == 1) %>% mutate(mass = signif(10^web_lg, 4)) %>%
    group_by(.data[[study_col]], mass) %>%
    summarise(n_spp = n_distinct(species), .groups = 'drop') %>%
    filter(n_spp >= min_species)
}

MetabGroup <- function(metab) ifelse(metab %in% 'invertebrate', 'inv',
                               ifelse(grepl('(ectotherm|endotherm) vertebrate', metab), 'vert', 'other'))
ModeOf <- function(x) { x <- x[!is.na(x) & x != '']; if (length(x) == 0) NA_character_ else names(which.max(table(x))) }

# Summary of one study (or web) from its species rows (web_lg, ratio, n_rows,
# species, grp, placeholder, size_method).
RatioSummary <- function(d) {
  r  <- d$ratio[!is.na(d$ratio)]
  np <- d[!d$placeholder & !is.na(d$ratio), ]
  med <- function(x) if (length(x)) round(median(x), 2) else NA_real_
  tibble(
    n_rows          = sum(d$n_rows),
    n_species       = n_distinct(d$species),
    n_inv           = n_distinct(d$species[d$grp == 'inv']),
    n_vert          = n_distinct(d$species[d$grp == 'vert']),
    n_placeholder   = n_distinct(d$species[d$placeholder]),
    mass_q10        = signif(10^quantile(d$web_lg, 0.10, names = FALSE), 3),
    mass_med        = signif(10^median(d$web_lg), 3),
    mass_q90        = signif(10^quantile(d$web_lg, 0.90, names = FALSE), 3),
    frac_lt_1mg     = round(mean(d$web_lg < -3), 3),
    n_shared        = length(r),
    median_log10_ratio = med(r),
    iqr_log10_ratio    = if (length(r) > 1) round(IQR(r), 2) else NA_real_,
    q25_ratio       = if (length(r)) round(quantile(r, 0.25, names = FALSE), 2) else NA_real_,
    q75_ratio       = if (length(r)) round(quantile(r, 0.75, names = FALSE), 2) else NA_real_,
    frac_ratio_mg   = if (length(r)) round(mean(r < -2), 2) else NA_real_,
    frac_ratio_dry  = if (length(r)) round(mean(r >= -1.5 & r < -0.4), 2) else NA_real_,
    frac_ratio_ok   = if (length(r)) round(mean(r >= -0.4 & r <= 0.6), 2) else NA_real_,
    frac_ratio_high = if (length(r)) round(mean(r > 0.6), 2) else NA_real_,
    n_shared_np     = nrow(np),
    med_ratio_np    = med(np$ratio),
    n_shared_inv    = sum(!is.na(d$ratio) & d$grp == 'inv'),
    med_ratio_inv   = med(d$ratio[d$grp == 'inv' & !is.na(d$ratio)]),
    n_shared_vert   = sum(!is.na(d$ratio) & d$grp == 'vert'),
    med_ratio_vert  = med(d$ratio[d$grp == 'vert' & !is.na(d$ratio)]),
    n_regression    = n_distinct(d$species[!is.na(d$size_method) & d$size_method == 'regression']),
    med_ratio_regression = med(d$ratio[!is.na(d$size_method) & d$size_method == 'regression' & !is.na(d$ratio)]),
    lowest_species  = paste(head(sprintf('%s %.2g (%.1f)', d$species[!is.na(d$ratio)],
                                         10^d$web_lg[!is.na(d$ratio)], d$ratio[!is.na(d$ratio)]), 4), collapse = '; ')
  )
}

# Merge a hand-made decisions table (columns: <key>, optional <subkey>,
# unit_class, proposed_action, factor, evidence, refs, and the owner's
# action, mass_group, log_reason) into the evidence table. Rows with an empty
# <subkey> apply to every sub-unit of <key>; rows with a <subkey> override them.
decision_columns <- c('unit_class', 'proposed_action', 'factor', 'evidence', 'refs',
                      'action', 'mass_group', 'log_reason')
MergeDecisions <- function(ev, dec_file, key, subkey = NULL) {
  dec_cols <- decision_columns
  for (col in dec_cols) ev[[col]] <- NA_character_
  if (!file.exists(dec_file)) return(ev)
  dec <- read.csv(dec_file, stringsAsFactors = FALSE, na.strings = c('', 'NA'), strip.white = TRUE)
  dec_cols <- intersect(dec_cols, names(dec))
  sub <- subkey %||% '.sub'
  if (sub %!in% names(dec)) dec[[sub]] <- NA_character_
  dec[[sub]][is.na(dec[[sub]])] <- ''
  dec_key <- dec[dec[[sub]] == '', ]
  dec_sub <- dec[dec[[sub]] != '', ]
  stopifnot(!anyDuplicated(dec_key[[key]]), !anyDuplicated(dec_sub[[sub]]))
  # keys are compared trimmed: two GATEWAy citations carry a trailing space
  i <- match(trimws(ev[[key]]), trimws(dec_key[[key]]))
  for (col in dec_cols) ev[[col]][!is.na(i)] <- dec_key[[col]][i[!is.na(i)]]
  if (nrow(dec_sub) && !is.null(subkey)) {
    j <- match(trimws(ev[[subkey]]), trimws(dec_sub[[subkey]]))
    for (col in dec_cols) ev[[col]][!is.na(j)] <- dec_sub[[col]][j[!is.na(j)]]
  }
  missing <- unique(ev[[key]][is.na(ev$proposed_action)])
  if (length(missing)) message('No decision row for: ', paste(missing, collapse = '; '))
  ev$unit_class[is.na(ev$unit_class)]           <- 'undetermined'
  ev$proposed_action[is.na(ev$proposed_action)] <- 'undecided'
  ev$action[is.na(ev$action)]                   <- 'keep'
  ev
}

# Taxon-level conversion groups for the convert_dry studies: one row per
# (key_col, TaxonKey(taxon)) among the stacked rows `dat` of those studies. Ranks
# come from the resolved species (`resolved` = CleanResolve() output that kept
# the raw name in `taxon_raw`), else from the enrichment cache entries of the
# same genus when they agree on phylum and class, else the group falls back to
# the source's metabolic type. `exclude(tab)` returns list(flag, note) for taxa
# whose values stay unconverted (owner decisions).
BuildGroupsTable <- function(dat, resolved, convert_keys, key_col,
                             exclude = function(tab) list(flag = rep(FALSE, nrow(tab)), note = rep('', nrow(tab)))) {
  d <- dat[trimws(dat[[key_col]]) %in% trimws(convert_keys), ]
  d$taxon_key <- TaxonKey(d$taxon)
  tab <- d %>% group_by(.data[[key_col]], taxon_key) %>%
    summarise(taxon = first(taxon), metab = ModeOf(metab), n_rows = n(), .groups = 'drop')
  r <- resolved
  r$taxon_key <- TaxonKey(r$taxon_raw)
  r <- r %>% group_by(taxon_key) %>%
    summarise(species = first(species), phylum = first(phylum), class = first(class), order = first(order),
              family = first(family), .groups = 'drop')
  tab <- left_join(tab, r, by = 'taxon_key')
  tab$basis <- ifelse(!is.na(tab$species), 'enrichment phylum/class of the resolved species', NA_character_)
  un <- is.na(tab$species)
  if (any(un)) {
    genus <- gsub('[^A-Za-z]', '', sub('\\s.*$', '', trimws(tab$taxon[un])))
    one <- function(x) if (n_distinct(na.omit(x)) == 1) na.omit(x)[1] else NA_character_
    ec <- unit_audit_enrich %>% filter(!is.na(genus)) %>% group_by(genus) %>%
      summarise(phylum = one(phylum), class = one(class), order = one(order), family = one(family), .groups = 'drop')
    m <- match(genus, ec$genus)
    hit <- !is.na(m) & !is.na(ec$phylum[m])
    tab$phylum[un][hit] <- ec$phylum[m][hit]
    tab$class[un][hit]  <- ec$class[m][hit]
    tab$order[un][hit]  <- ec$order[m][hit]
    tab$family[un][hit] <- ec$family[m][hit]
    tab$basis[un][hit]  <- 'enrichment phylum/class of the genus (name not resolved to a species)'
  }
  fb <- is.na(tab$basis)
  tab$basis[fb] <- paste0('source metabolic type (', tab$metab[fb], '); name not in the enrichment cache')
  mg <- MassGroupFromRanks(tab$phylum, tab$class, tab$family, tab$order)
  mg$mass_group[fb] <- ifelse(grepl('ectotherm vertebrate', tab$metab[fb]), 'fish',
                        ifelse(grepl('endotherm vertebrate', tab$metab[fb]), 'vertebrate', 'invertebrate'))
  mg$shell_group[fb] <- mg$mass_group[fb]
  tab <- bind_cols(tab, mg)
  tab$convert <- TRUE
  ex <- exclude(tab)
  tab$convert[ex$flag] <- FALSE
  tab$basis[ex$flag]   <- paste(tab$basis[ex$flag], ex$note[ex$flag], sep = '; ')
  as.data.frame(tab[, c(key_col, 'taxon', 'taxon_key', 'n_rows', 'species', 'phylum', 'class', 'order', 'family',
                        'mass_group', 'whole', 'shell_group', 'convert', 'basis')])
}
`%||%` <- function(a, b) if (is.null(a)) b else a
