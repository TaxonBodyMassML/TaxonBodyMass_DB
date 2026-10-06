# Record-level range rule (issue #34): exclude the one discordant value of a
# species instead of removing the species.
#
# Until #34 a species whose independent per-source values spanned more than an
# order of magnitude (log10_range > 1) was removed from TaxonBodyMass.csv
# whole (R/library/remove_high_range.r). In 80% of the multi-value removals a
# single value caused the spread (a VertNet juvenile, a dry mass taken as wet,
# an ephyra, a web-level food-web datum) while the other values agreed closely.
# ExcludeDiscordantValues() runs between DedupeSources() and Pass 2 of
# R/RunMe.r on the Pass-1 values (one value per species x source group) and
# decides, species by species, whether one value (or one side) can be excluded
# from the cross-source mean so that the rest agree within the threshold. The
# cascade (owner decisions of 2026-10-06 on issue #34):
#
#   A  leave-one-out: exclude one value and the rest span <= threshold. The
#      kept side must span at least two evidence groups (registry-independent
#      sources: the related pairs DedupeSources() computes from
#      Bib/source_dependencies.csv join sources into one group, so two
#      near-copies cannot outvote one independent value). Exactly one such
#      candidate: rule `loo_unique`.
#   A2 several candidates: the one of lowest trust is excluded when the trust
#      tiers single it out (`tier_tiebreak`); otherwise the one farthest from
#      the median of the others (`distance_tiebreak`).
#   D  two values, or one evidence group against one value (the kept side of a
#      leave-one-out candidate was a single group): the lower-trust side is
#      excluded when the tiers differ (`two_value_tier`); the kept side must
#      itself span <= threshold.
#   E  otherwise nothing is excluded: the species is listed as unresolved and
#      falls to the species filter (remove_high_range_taxa()) as before.
#
# Trust tiers (`value_tier` in Bib/source_provenance_classes.csv, owner-editable;
# 1 = compiled or measured adult values, 2 = maxima-based or allometric
# (Feldman_etal_2016, Meiri_2018, fishbase, sealifebase), 3 = single specimens,
# individuals, converted or web-level values (VertNet, Brose_2005, GATEWAy,
# Vanni_2017, Gonzalez_2025, Castro_2025, DeLong_etal_2010, Kiorboe_2013/2014,
# Pata_2025)). A value converted from dry, ash-free dry, carbon or energy mass
# (a conversion CiteID after the label in source_mass, LabelWithConversion())
# is tier 3 whatever its source's tier. Tiers are direction-blind (a low or a
# high outlier is judged alike). A tier-2 (maxima-based) value may be excluded
# but never decides a tie-break against another value: in A2 it never outranks
# a tier-3 candidate (the tie falls to the distance), in D a tier-2 side never
# excludes a tier-3 side (the species stays unresolved).
#
# Copies collapsed into an excluded value by DedupeSources() are excluded with
# it (a copy promoted to independent would recreate the outlier). source_mass
# and n in TaxonBodyMass.csv keep listing every source and record; n_excluded
# and sources_excluded say what was left out; n_independent counts the values
# in the mean and log10_range spans them. The provenance table keeps the
# excluded records' rows with record_status 'excluded_<rule>'.
#
# Genus-only records (#49) get the same treatment against the genus's species
# cross-source means in ExcludeDiscordantGenusRecords(): more than threshold
# from the median of two or more species, the record leaves the genus mean
# (`genus_only_discordant`); against a single species it is a two-value case
# (rule D, the record the only side that can be excluded).
#
# Entry points used by RunMe.r:
#   ValueTier(label, source_mass, origin, classes)      tier per Pass-1 value
#   ExcludeDiscordantValues(within_source, related, classes, threshold = 1)
#   ExcludeDiscordantGenusRecords(records, values, enriched, species_tiers, classes, related)
#   WriteExcludedRecords(path, species_excl, genus_excl) reports/excluded_records.csv
#   ExclusionRegisterRows(exclusions, method)            rows for audit/flagged_species.csv
# Base R only; the unit tests are in tests/test_exclude_discordant.R.

value_tiers     <- c(1L, 2L, 3L)
exclusion_rules <- c('loo_unique', 'tier_tiebreak', 'distance_tiebreak', 'two_value_tier',
                     'genus_only_discordant')
unresolved_reasons <- c('same_tier', 'maximum_cannot_decide', 'kept_side_spread', 'one_group',
                        'no_single_culprit')
record_statuses <- c('kept', paste0('excluded_', exclusion_rules))

# ---- tiers ----------------------------------------------------------------------
# The tier of a Pass-1 value: the registry tier of its label (the lowest, i.e.
# most trusted, where the value pools several labels, 'a+b'; a label the
# registry does not know, such as a lab-Sheet citation, is tier 1), raised to
# 3 when the record was converted from another mass type (a conversion CiteID
# after the label in source_mass, pipeline records only: a Sheet row may cite
# several sources after a ';').
ValueTier <- function(source_label, source_mass, origin, classes) {
  if (!'value_tier' %in% names(classes))
    stop('ValueTier(): the registry has no value_tier column', call. = FALSE)
  tier_of <- setNames(as.integer(classes$value_tier), classes$source_label)
  tier <- vapply(strsplit(as.character(source_label), '+', fixed = TRUE), function(labs) {
    t <- tier_of[labs]
    t <- t[!is.na(t)]
    if (length(t) == 0) 1L else min(t)
  }, integer(1))
  converted <- !is.na(origin) & origin == 'pipeline' & grepl(';', as.character(source_mass), fixed = TRUE)
  tier[converted] <- 3L
  tier
}

# ---- evidence groups ----------------------------------------------------------------
# Connected components of the labels over the registry-related pairs
# (`related`: DedupeSources()$related, columns a, b). Returns one integer per
# label (same integer = same group).
EvidenceGroups <- function(labels, related) {
  n <- length(labels)
  comp <- seq_len(n)
  if (n < 2 || is.null(related) || nrow(related) == 0) return(comp)
  key <- paste(related$a, related$b)
  for (i in seq_len(n - 1L)) for (j in (i + 1L):n) {
    a <- labels[i]; b <- labels[j]
    if (paste(min(a, b), max(a, b)) %in% key) {
      m <- min(comp[i], comp[j])
      comp[comp %in% c(comp[i], comp[j])] <- m
    }
  }
  comp
}

# ---- the rules on one species ----------------------------------------------------------
# `d`: the independent values of one species (columns lg = log10(mass_g),
# tier, label, n, group). Returns list(exclude = integer indices into d,
# rule, reason, kept = indices) where rule is NA when nothing is excluded.
# Rule D between two sides (index vectors into d): the lower-trust side is
# excluded when the tiers differ, unless the trusted side is a tier-2
# (maxima-based) value and the other tier 3, and provided the kept side spans
# <= threshold.
DecideTwoSides <- function(d, side_a, side_b, threshold) {
  ta <- min(d$tier[side_a]); tb <- min(d$tier[side_b])
  if (ta == tb) return(list(exclude = integer(0), rule = NA_character_, reason = 'same_tier'))
  if (ta > tb) { out <- side_a; keep <- side_b; tk <- tb } else { out <- side_b; keep <- side_a; tk <- ta }
  if (tk == 2L) return(list(exclude = integer(0), rule = NA_character_, reason = 'maximum_cannot_decide'))
  if (length(keep) > 1 && diff(range(d$lg[keep])) > threshold)
    return(list(exclude = integer(0), rule = NA_character_, reason = 'kept_side_spread'))
  list(exclude = out, rule = 'two_value_tier', reason = NA_character_, kept = keep)
}

# A2: among the leave-one-out candidates `cand`, the lowest-trust one when the
# tiers single it out, else the farthest from the median of the other values.
# A tier-2 candidate never outranks a tier-3 one: without a tier-1 candidate
# the tiers do not narrow the set.
TieBreak <- function(d, cand) {
  tiers <- d$tier[cand]
  pool <- if (any(tiers == 1L)) cand[tiers == max(tiers)] else cand
  if (length(pool) == 1) return(list(exclude = pool, rule = 'tier_tiebreak'))
  dist <- vapply(pool, function(i) abs(d$lg[i] - stats::median(d$lg[-i])), numeric(1))
  o <- order(-dist, d$label[pool], method = 'radix')
  list(exclude = pool[o[1]], rule = 'distance_tiebreak')
}

DecideSpecies <- function(d, threshold) {
  n <- nrow(d)
  none <- function(reason) list(exclude = integer(0), rule = NA_character_, reason = reason, kept = seq_len(n))
  if (n < 2 || diff(range(d$lg)) <= threshold) return(none(NA_character_))
  if (n == 2) {
    r <- DecideTwoSides(d, 1L, 2L, threshold)
    if (length(r$exclude) == 0) return(none(r$reason))
    return(r)
  }
  rest_rng <- vapply(seq_len(n), function(i) diff(range(d$lg[-i])), numeric(1))
  cand     <- which(rest_rng <= threshold)
  if (length(cand) == 0) return(none('no_single_culprit'))
  if (length(cand) == 1) { pick <- cand; rule <- 'loo_unique' }
  else { tb <- TieBreak(d, cand); pick <- tb$exclude; rule <- tb$rule }
  kept <- setdiff(seq_len(n), pick)
  if (length(unique(d$group[kept])) >= 2)
    return(list(exclude = pick, rule = rule, reason = NA_character_, kept = kept))
  # the kept side is a single evidence group (registry-related sources, one
  # vote): the candidate against the group, rule D
  r <- DecideTwoSides(d, pick, kept, threshold)
  if (length(r$exclude) == 0) return(none(if (r$reason == 'same_tier') 'one_group' else r$reason))
  r
}

# ---- the species path -------------------------------------------------------------------
# `within_source`: DedupeSources()$values (genus, species, source_label,
# source_mass, origin, mass_g, n, independent, collapsed_into; taxon for the
# tables). `related`: DedupeSources()$related. `classes`:
# LoadProvenanceClasses() with value_tier. Returns a list:
#   values      within_source with value_tier, excluded (logical),
#               exclusion_rule, exclusion_distance (log10 of the value over the
#               median of the kept values; copies carry their parent's rule
#               and distance) and record_status
#   exclusions  one row per excluded Pass-1 value (copies included, copy_of
#               naming the parent): genus, species, taxon, source_label,
#               source_mass, mass_g, n, value_tier, rule, distance_log10,
#               copy_of, n_kept, single_value_rescue (TRUE when the species
#               rests on one kept value after the exclusion; owner decision
#               2026-10-06: such species are flagged SUSPICIOUS for review),
#               kept_mass_g (the arithmetic mean of the kept values),
#               kept_values ('label value g (n N, T#)' joined by '; ')
#   unresolved  the species left to the species filter: genus, species, taxon,
#               n_independent, n_groups, log10_range, reason, values
#   counts      species rescued, values excluded (independent / copies), by rule
ExcludeDiscordantValues <- function(within_source, related, classes, threshold = 1) {
  need <- c('genus', 'species', 'source_label', 'source_mass', 'mass_g', 'n', 'independent', 'collapsed_into')
  miss <- setdiff(need, names(within_source))
  if (length(miss) > 0)
    stop('ExcludeDiscordantValues(): within_source lacks column(s) ', paste(miss, collapse = ', '), call. = FALSE)
  ws <- as.data.frame(within_source, stringsAsFactors = FALSE)
  if (!'origin' %in% names(ws)) ws$origin <- 'pipeline'
  if (!'taxon'  %in% names(ws)) ws$taxon  <- paste(ws$genus, ws$species, sep = '_')
  ws$value_tier         <- ValueTier(ws$source_label, ws$source_mass, ws$origin, classes)
  ws$excluded           <- FALSE
  ws$exclusion_rule     <- NA_character_
  ws$exclusion_distance <- NA_real_
  key <- paste(ws$genus, ws$species, sep = '\r')
  ind <- which(ws$independent)
  # species whose independent values span more than the threshold
  rng <- tapply(log10(ws$mass_g[ind]), key[ind], function(x) if (length(x) > 1) diff(range(x)) else 0)
  keys <- names(rng)[rng > threshold]
  excl <- list(); unres <- list()
  FmtValues <- function(d) paste(sprintf('%s %.4g g (n %d, T%d)', d$label, 10^d$lg, d$n, d$tier), collapse = '; ')
  for (k in keys) {
    rows <- ind[key[ind] == k]
    d <- data.frame(row = rows, label = ws$source_label[rows], lg = log10(ws$mass_g[rows]),
                    tier = ws$value_tier[rows], n = ws$n[rows], stringsAsFactors = FALSE)
    d <- d[order(d$lg, d$label, method = 'radix'), ]
    d$group <- EvidenceGroups(d$label, related)
    r <- DecideSpecies(d, threshold)
    g <- ws$genus[rows[1]]; s <- ws$species[rows[1]]; tx <- ws$taxon[rows[1]]
    if (length(r$exclude) == 0) {
      unres[[k]] <- data.frame(genus = g, species = s, taxon = tx, n_independent = nrow(d),
                               n_groups = length(unique(d$group)), log10_range = diff(range(d$lg)),
                               reason = r$reason, values = FmtValues(d), stringsAsFactors = FALSE)
      next
    }
    kept <- d[r$kept, ]
    med  <- stats::median(kept$lg)
    out  <- d[r$exclude, ]
    out_rows <- out$row
    ws$excluded[out_rows]           <- TRUE
    ws$exclusion_rule[out_rows]     <- r$rule
    ws$exclusion_distance[out_rows] <- out$lg - med
    # copies collapsed into an excluded value go with it
    cp <- which(key == k & !ws$independent & ws$collapsed_into %in% out$label)
    if (length(cp) > 0) {
      ws$excluded[cp]           <- TRUE
      ws$exclusion_rule[cp]     <- r$rule
      ws$exclusion_distance[cp] <- ws$exclusion_distance[out_rows][match(ws$collapsed_into[cp], out$label)]
    }
    er <- c(out_rows, cp)
    excl[[k]] <- data.frame(
      genus = g, species = s, taxon = tx, source_label = ws$source_label[er], source_mass = ws$source_mass[er],
      mass_g = ws$mass_g[er], n = ws$n[er], value_tier = ws$value_tier[er], rule = r$rule,
      distance_log10 = ws$exclusion_distance[er],
      copy_of = c(rep(NA_character_, length(out_rows)), ws$collapsed_into[cp]),
      n_kept = nrow(kept), single_value_rescue = nrow(kept) == 1L, kept_mass_g = mean(10^kept$lg), kept_values = FmtValues(kept),
      stringsAsFactors = FALSE)
  }
  Bind <- function(l, template) {
    if (length(l) == 0) return(template)
    out <- do.call(rbind, l); rownames(out) <- NULL; out
  }
  exclusions <- Bind(excl, data.frame(genus = character(), species = character(), taxon = character(),
                                      source_label = character(), source_mass = character(), mass_g = numeric(),
                                      n = integer(), value_tier = integer(), rule = character(),
                                      distance_log10 = numeric(), copy_of = character(), n_kept = integer(),
                                      single_value_rescue = logical(), kept_mass_g = numeric(), kept_values = character(),
                                      stringsAsFactors = FALSE))
  unresolved <- Bind(unres, data.frame(genus = character(), species = character(), taxon = character(),
                                       n_independent = integer(), n_groups = integer(), log10_range = numeric(),
                                       reason = character(), values = character(), stringsAsFactors = FALSE))
  if (nrow(exclusions) > 0)
    exclusions <- exclusions[order(exclusions$genus, exclusions$species, !is.na(exclusions$copy_of),
                                   exclusions$source_label, method = 'radix'), ]
  if (nrow(unresolved) > 0)
    unresolved <- unresolved[order(unresolved$genus, unresolved$species, method = 'radix'), ]
  rownames(exclusions) <- NULL; rownames(unresolved) <- NULL
  ws$record_status <- ifelse(ws$excluded, paste0('excluded_', ws$exclusion_rule), 'kept')
  indep_excl <- exclusions[is.na(exclusions$copy_of), , drop = FALSE]
  counts <- list(species_flagged = length(keys),
                 species_rescued = length(unique(paste(indep_excl$genus, indep_excl$species))),
                 species_unresolved = nrow(unresolved),
                 values_excluded = nrow(exclusions),
                 values_excluded_independent = nrow(indep_excl),
                 values_excluded_copies = sum(!is.na(exclusions$copy_of)),
                 species_single_value = length(unique(paste(indep_excl$genus, indep_excl$species)[indep_excl$single_value_rescue])),
                 by_rule = table(factor(indep_excl$rule, levels = exclusion_rules)),
                 species_by_rule = table(factor(indep_excl$rule[!duplicated(paste(indep_excl$genus, indep_excl$species))], levels = exclusion_rules)),
                 unresolved_by_reason = table(factor(unresolved$reason, levels = unresolved_reasons)))
  list(values = ws, exclusions = exclusions, unresolved = unresolved, counts = counts, threshold = threshold)
}

# ---- the genus-only path (#49) ----------------------------------------------------------
# `records`: GenusOnlyRecords() (one record per genus); `values`: the genus x
# source values behind them (DedupeGenusValues()$values: genus, source_label,
# source_mass, independent); `enriched`: the species table after the range
# filter (genus, species, mass_g); `species_tiers`: a data frame (genus,
# species, tier) with the lowest tier among each species' values in the mean.
# A record is judged against the genus's species cross-source means: more than
# `threshold` from their median with two or more species it is excluded
# (`genus_only_discordant`); against a single species rule D applies, the
# record being the only side that can be excluded (a species value is never
# removed from the genus mean here). Returns list(records with record_status,
# value_tier, distance_log10; exclusions; unresolved; counts).
ExcludeDiscordantGenusRecords <- function(records, values, enriched, species_tiers, classes, threshold = 1) {
  rec <- as.data.frame(records, stringsAsFactors = FALSE)
  rec$record_status  <- rep('kept', nrow(rec))
  rec$value_tier     <- rep(NA_integer_, nrow(rec))
  rec$distance_log10 <- rep(NA_real_, nrow(rec))
  empty_ex <- data.frame(genus = character(), source_label = character(), source_mass = character(), mass_g = numeric(),
                         n = integer(), value_tier = integer(), rule = character(), distance_log10 = numeric(),
                         n_species = integer(), species_median_g = numeric(), species_values = character(),
                         stringsAsFactors = FALSE)
  empty_un <- data.frame(genus = character(), source_label = character(), mass_g = numeric(), value_tier = integer(),
                         n_species = integer(), species_median_g = numeric(), distance_log10 = numeric(),
                         reason = character(), species_values = character(), stringsAsFactors = FALSE)
  if (nrow(rec) == 0 || nrow(enriched) == 0)
    return(list(records = rec, exclusions = empty_ex, unresolved = empty_un,
                counts = list(records_excluded = 0L, records_unresolved = 0L)))
  if (nrow(values) > 0) {
    if (!'independent' %in% names(values)) values$independent <- TRUE
    values$tier <- ValueTier(values$source_label, values$source_mass, rep('pipeline', nrow(values)), classes)
    rec_tier <- tapply(values$tier[values$independent], values$genus[values$independent], min)
    rec$value_tier <- as.integer(rec_tier[rec$genus])
  }
  rec$value_tier[is.na(rec$value_tier)] <- 1L
  sp_lg   <- split(log10(enriched$mass_g), enriched$genus)
  sp_name <- split(enriched$species, enriched$genus)
  sp_tier <- if (!is.null(species_tiers) && nrow(species_tiers) > 0)
    tapply(species_tiers$tier, species_tiers$genus, min) else integer(0)
  excl <- list(); unres <- list()
  for (i in seq_len(nrow(rec))) {
    g <- rec$genus[i]
    if (!g %in% names(sp_lg)) next
    lg <- sp_lg[[g]]; med <- stats::median(lg)
    dist <- log10(rec$mass_g[i]) - med
    rec$distance_log10[i] <- dist
    if (abs(dist) <= threshold) next
    o <- order(lg)
    sp_vals <- paste(sprintf('%s %.4g g', sp_name[[g]][o], 10^lg[o]), collapse = '; ')
    row <- function(reason = NA_character_, rule = NA_character_)
      data.frame(genus = g, source_label = rec$source_label[i], source_mass = rec$source_mass[i], mass_g = rec$mass_g[i],
                 n = rec$n[i], value_tier = rec$value_tier[i], rule = rule, distance_log10 = dist,
                 n_species = length(lg), species_median_g = 10^med, reason = reason, species_values = sp_vals,
                 stringsAsFactors = FALSE)
    if (length(lg) >= 2) {
      rec$record_status[i] <- 'excluded_genus_only_discordant'
      excl[[g]] <- row(rule = 'genus_only_discordant')
      next
    }
    st <- if (g %in% names(sp_tier)) as.integer(sp_tier[[g]]) else 1L
    d <- data.frame(lg = c(log10(rec$mass_g[i]), lg), tier = c(rec$value_tier[i], st))
    r <- DecideTwoSides(d, 1L, 2L, threshold)
    if (length(r$exclude) == 1 && r$exclude == 1L) {
      rec$record_status[i] <- 'excluded_two_value_tier'
      excl[[g]] <- row(rule = 'two_value_tier')
    } else {
      unres[[g]] <- row(reason = if (length(r$exclude) == 0) r$reason else 'same_tier')
    }
  }
  Bind <- function(l, template, cols) {
    if (length(l) == 0) return(template)
    out <- do.call(rbind, l)[, cols]; rownames(out) <- NULL; out
  }
  exclusions <- Bind(excl, empty_ex, names(empty_ex))
  unresolved <- Bind(unres, empty_un, names(empty_un))
  if (nrow(unresolved) > 0) unresolved$reason[unresolved$reason == 'same_tier' & unresolved$value_tier < 2] <- 'same_tier'
  list(records = rec, exclusions = exclusions, unresolved = unresolved,
       counts = list(records_excluded = nrow(exclusions), records_unresolved = nrow(unresolved),
                     by_rule = table(factor(exclusions$rule, levels = exclusion_rules))))
}

# ---- outputs ---------------------------------------------------------------------------
# reports/excluded_records.csv: the species-level exclusions (one row per
# excluded Pass-1 value, copies included) and the genus-only ones, with a
# `level` column (single_value_rescue marks the rows whose species, or genus,
# rests on one kept value); no timestamp, so two runs write the same file.
WriteExcludedRecords <- function(path, species_excl, genus_excl = NULL) {
  Num <- function(x) ifelse(is.na(x), NA_character_, trimws(formatC(x, digits = 6, format = 'g')))
  sp <- species_excl$exclusions
  out <- data.frame(level = rep('species', nrow(sp)), genus = sp$genus, species = sp$species, taxon = sp$taxon,
                    source_label = sp$source_label, source_mass = sp$source_mass, mass_g = Num(sp$mass_g), n = sp$n,
                    value_tier = sp$value_tier, rule = sp$rule, distance_log10 = round(sp$distance_log10, 4),
                    copy_of = sp$copy_of, n_kept = sp$n_kept, single_value_rescue = sp$single_value_rescue,
                    kept_mass_g = Num(sp$kept_mass_g), kept_values = sp$kept_values, stringsAsFactors = FALSE)
  if (!is.null(genus_excl) && nrow(genus_excl$exclusions) > 0) {
    ge <- genus_excl$exclusions
    out <- rbind(out, data.frame(level = rep('genus', nrow(ge)), genus = ge$genus, species = NA_character_, taxon = ge$genus,
                                 source_label = ge$source_label, source_mass = ge$source_mass, mass_g = Num(ge$mass_g), n = ge$n,
                                 value_tier = ge$value_tier, rule = ge$rule, distance_log10 = round(ge$distance_log10, 4),
                                 copy_of = NA_character_, n_kept = ge$n_species, single_value_rescue = ge$n_species == 1L,
                                 kept_mass_g = Num(ge$species_median_g), kept_values = ge$species_values, stringsAsFactors = FALSE))
  }
  write.csv(out, path, row.names = FALSE, na = '')
  invisible(out)
}

# The rows of one append-only batch of audit/flagged_species.csv from the
# species-level exclusions (independent values only; copies are named in the
# note): mass_g the excluded Pass-1 value, log10_pred log10 of the median of
# the kept values, severity CRITICAL when |residual| >= 2, SUSPICIOUS
# otherwise, `method` as given. `taxa`: a frame with genus, species, kingdom,
# phylum, class, order, family, gbif_confidence for the species (the Pass-2
# table before the filter).
ExclusionRegisterRows <- function(exclusions, taxa, method, kept_mass = NULL) {
  ex <- exclusions[is.na(exclusions$copy_of), , drop = FALSE]
  if (nrow(ex) == 0) return(NULL)
  m <- match(paste(ex$genus, ex$species), paste(taxa$genus, taxa$species))
  copies <- vapply(seq_len(nrow(ex)), function(i) {
    cp <- exclusions$source_label[!is.na(exclusions$copy_of) & exclusions$copy_of == ex$source_label[i] &
                                    exclusions$genus == ex$genus[i] & exclusions$species == ex$species[i]]
    if (length(cp) == 0) '' else sprintf(' Collapsed copies excluded with it: %s.', paste(cp, collapse = ', '))
  }, character(1))
  lg   <- log10(ex$mass_g)
  pred <- lg - ex$distance_log10
  conv <- grepl(';', ex$source_mass, fixed = TRUE)
  data.frame(
    taxon = ex$taxon, mass_g = signif(ex$mass_g, 4), source_mass = ex$source_mass, n = ex$n,
    kingdom = taxa$kingdom[m], phylum = taxa$phylum[m], taxon_class = taxa$class[m], order = taxa$order[m],
    family = taxa$family[m], genus = ex$genus, species = ex$species, confidence = taxa$gbif_confidence[m],
    form = NA, subspecies = NA, variety = NA, log10_mass = lg, log10_pred = pred, residual = ex$distance_log10,
    abs_residual = abs(ex$distance_log10), class_outlier = NA,
    severity = ifelse(abs(ex$distance_log10) >= 2, 'CRITICAL', 'SUSPICIOUS'), method = method,
    note = sprintf(paste0('Record-level range rule (#34, R/library/exclude_discordant.r): value excluded from the cross-source mean by rule %s ',
                          '(tier T%d%s; %.2f log10 %s the median of the kept values). Kept values: %s; species kept at %.4g g (n_independent %d).%s'),
                   ex$rule, ex$value_tier, ifelse(conv, ', converted', ''), abs(ex$distance_log10),
                   ifelse(ex$distance_log10 > 0, 'above', 'below'), ex$kept_values, signif(ex$kept_mass_g, 4), ex$n_kept, copies),
    stringsAsFactors = FALSE)
}

# The register rows of the rescued species that rest on a single kept value
# (owner decision 2026-10-06: flagged SUSPICIOUS for review): one row per such
# species, mass_g and source_mass the kept value and its label, n its records,
# log10_pred log10 of the excluded value (the only other evidence; the first
# excluded value where a group was excluded), the note naming both sides.
SingleValueRescueRows <- function(exclusions, taxa, method) {
  ex <- exclusions[is.na(exclusions$copy_of) & exclusions$single_value_rescue, , drop = FALSE]
  if (nrow(ex) == 0) return(NULL)
  key <- paste(ex$genus, ex$species)
  first <- ex[!duplicated(key), , drop = FALSE]
  excluded_all <- vapply(paste(first$genus, first$species), function(k)
    paste(sprintf('%s %.4g g (n %d, T%d)', ex$source_label[key == k], ex$mass_g[key == k], ex$n[key == k], ex$value_tier[key == k]), collapse = '; '),
    character(1))
  m <- match(paste(first$genus, first$species), paste(taxa$genus, taxa$species))
  kept_label <- sub(' .*$', '', first$kept_values)
  kept_n     <- as.integer(sub('^.*\\(n ([0-9]+),.*$', '\\1', first$kept_values))
  lg_kept <- log10(first$kept_mass_g)
  lg_excl <- log10(first$mass_g)
  data.frame(
    taxon = first$taxon, mass_g = signif(first$kept_mass_g, 4), source_mass = kept_label, n = kept_n,
    kingdom = taxa$kingdom[m], phylum = taxa$phylum[m], taxon_class = taxa$class[m], order = taxa$order[m],
    family = taxa$family[m], genus = first$genus, species = first$species, confidence = taxa$gbif_confidence[m],
    form = NA, subspecies = NA, variety = NA, log10_mass = lg_kept, log10_pred = lg_excl, residual = lg_kept - lg_excl,
    abs_residual = abs(lg_kept - lg_excl), class_outlier = NA, severity = 'SUSPICIOUS', method = method,
    note = sprintf(paste0('Record-level range rule (#34): rescued species rests on one kept value; review. Kept: %s. ',
                          'Excluded by rule %s: %s. log10_pred is log10 of the excluded value.'),
                   first$kept_values, first$rule, excluded_all),
    stringsAsFactors = FALSE)
}
