# De-duplication of per-source species values that reach the database through
# several compilations (issue #5).
#
# The same body-mass datum often enters TaxonBodyMass.csv through two or more
# sources: AVONET and EltonTraits both reproduce Dunning's CRC Handbook, COMBINE
# reproduces Amniote, PHYLACINE and MOM, Hoehler et al. (2023) reproduces
# Makarieva et al. (2008), which reproduces Chown et al. (2007), and so on.
# Pass 2 of RunMe.r would average such copies as independent estimates, which
# inflates n and pulls the cross-source mean towards the copied value. The
# functions here decide, species by species, which per-source values are
# independent and which are copies of another value that is kept, so that Pass 2
# averages the independent values only while source_mass and n stay complete.
#
# Two layers are combined:
#  1. the hand-maintained dependency registry Bib/source_dependencies.csv: one
#     row per edge child_label -> parent_label ("the child copies or derives its
#     values from the parent"), applied with a per-edge tolerance: a child value
#     is a copy only when it also agrees with the parent's value within
#     tol_log10 (1e-6 for verbatim copies, 0.0105 where the child re-rounded or
#     re-derived the value). Edges are transitive, labels that share a parent
#     outside the database (Dunning_2008, White_2006, ...) are compared with each
#     other, and a `provenance_only` edge documents a relation whose values
#     generally differ: it grants no tolerance-based collapse (layer 2 still
#     applies to it, see below);
#  2. a blind rule for values that are the same number to at least
#     `blind_min_sf` significant digits in any two sources of a species (two
#     independent estimates agreeing to three significant digits essentially
#     only happens when both copied the same number); values with one or two
#     significant digits (round numbers such as 20 or 1500 g) are excluded as
#     ambiguous. The blind rule applies to every pair of sources, including
#     pairs registered provenance_only: values identical to that many digits
#     are the same datum whatever the registry says about the pair (owner
#     decision, issue #31); such collapses are labelled in `dedupe_rule`.
# Matching pairs are joined into components within each species; one member of
# each component is kept (a registry ancestor of the others where there is one,
# otherwise the member with the lowest `priority`, then the fewest registry
# ancestors, then the alphabetically first label) and the other members are
# collapsed into it. Collapsing only ever removes values that agree with the
# kept one, so a species' mass can move by at most the tolerance of a near copy.
#
# Entry points used by RunMe.r:
#   LoadSourceDependencies(path, known_labels)  validated registry (stops on an
#                                               unknown label, a mislabelled
#                                               external parent or a cycle)
#   DedupeSources(within_source, deps)          list(values, pairs, closure, ...)
#   WriteDedupeReport(dd, deps, path)           reports/dedupe_summary.md
# Everything is base R; the unit tests are in tests/test_dedupe_sources.R.

# The source label is the first token of source_mass. LabelWithConversion()
# (mass_conversion.r) appends the CiteIDs of conversion references after a ';'
# ('Kendall_etal_2019; Studier_1992'), so Pass 1 must group by the label and not
# by the whole string, otherwise one source splits into several values.
SourceLabel <- function(source_mass) trimws(sub(';.*$', '', as.character(source_mass)))

# The VertNet dumps (vertnet-<class>-sept2016 and vertnet-traits-sept2016) are
# one source for de-duplication: the 'traits' dump re-exports specimens of the
# class dumps (3,884 bird species occur in both), so Pass 1 pools their records
# into one value per species and counts them once in n_sources; every dump label
# stays in source_mass for citation.
SourceGroup <- function(label) ifelse(grepl('^vertnet-', label), 'vertnet', label)

dependency_columns  <- c('child_label', 'parent_label', 'parent_in_db', 'relation',
                         'tol_log10', 'priority', 'status', 'n_rows_child', 'evidence',
                         'added')
dependency_relations <- c('copies', 'via', 'shared_primary', 'derived_same_input',
                          'provenance_only')
dependency_statuses  <- c('confirmed', 'suspected')
default_priority     <- 99L

# Read and validate Bib/source_dependencies.csv. `known_labels` are the source
# labels present in the data (SourceLabel() of every record): every child and
# every parent flagged parent_in_db = TRUE must be one of them, and an external
# parent (parent_in_db = FALSE) must not be, so a renamed or removed source is
# noticed at the next run instead of silently disabling its edges. Stops on any
# problem; returns the registry as a data frame.
LoadSourceDependencies <- function(path, known_labels) {
  if (!file.exists(path)) stop('source dependency registry not found: ', path, call. = FALSE)
  deps <- read.csv(path, stringsAsFactors = FALSE, na.strings = c('', 'NA'),
                   colClasses = c(child_label = 'character', parent_label = 'character',
                                  relation = 'character', status = 'character',
                                  evidence = 'character', added = 'character'),
                   check.names = FALSE, strip.white = TRUE)
  missing_cols <- setdiff(dependency_columns, names(deps))
  if (length(missing_cols) > 0)
    stop('source_dependencies.csv lacks column(s): ', paste(missing_cols, collapse = ', '),
         call. = FALSE)
  if (nrow(deps) == 0) stop('source_dependencies.csv has no edges', call. = FALSE)
  deps <- deps[, dependency_columns]
  problems <- character(0)
  for (col in c('child_label', 'parent_label', 'parent_in_db', 'relation', 'tol_log10', 'status'))
    if (anyNA(deps[[col]]))
      problems <- c(problems, sprintf('column %s is empty in row(s) %s', col,
                                      paste(which(is.na(deps[[col]])), collapse = ', ')))
  if (!is.logical(deps$parent_in_db))
    problems <- c(problems, 'parent_in_db must be TRUE or FALSE')
  if (!is.numeric(deps$tol_log10) || any(deps$tol_log10 < 0, na.rm = TRUE))
    problems <- c(problems, 'tol_log10 must be a non-negative number')
  if (!is.numeric(deps$priority) ||
      any(!is.na(deps$priority) & (deps$priority < 1 | deps$priority != round(deps$priority))))
    problems <- c(problems, 'priority must be empty or a positive integer')
  bad_rel <- setdiff(unique(deps$relation), dependency_relations)
  if (length(bad_rel) > 0)
    problems <- c(problems, sprintf('unknown relation(s) %s (allowed: %s)',
                                    paste(bad_rel, collapse = ', '),
                                    paste(dependency_relations, collapse = ', ')))
  bad_status <- setdiff(unique(deps$status), dependency_statuses)
  if (length(bad_status) > 0)
    problems <- c(problems, sprintf('unknown status value(s) %s (allowed: %s)',
                                    paste(bad_status, collapse = ', '),
                                    paste(dependency_statuses, collapse = ', ')))
  if (length(problems) > 0)
    stop('source_dependencies.csv: ', paste(problems, collapse = '; '), call. = FALSE)

  self <- deps$child_label == deps$parent_label
  if (any(self))
    problems <- c(problems, sprintf('self edge(s): %s', paste(deps$child_label[self], collapse = ', ')))
  dup <- duplicated(deps[, c('child_label', 'parent_label')])
  if (any(dup))
    problems <- c(problems, sprintf('duplicate edge(s): %s',
                                    paste(deps$child_label[dup], deps$parent_label[dup],
                                          sep = ' -> ', collapse = ', ')))
  known_labels <- unique(as.character(known_labels))
  unknown_child <- setdiff(deps$child_label, known_labels)
  if (length(unknown_child) > 0)
    problems <- c(problems, sprintf('child label(s) not found in any source frame: %s',
                                    paste(unknown_child, collapse = ', ')))
  in_db <- deps$parent_in_db
  unknown_parent <- setdiff(deps$parent_label[in_db], known_labels)
  if (length(unknown_parent) > 0)
    problems <- c(problems, sprintf(paste('parent label(s) flagged parent_in_db = TRUE not found in any',
                                          'source frame (renamed or removed source? external parents',
                                          'take parent_in_db = FALSE): %s'),
                                    paste(unknown_parent, collapse = ', ')))
  mislabelled <- intersect(deps$parent_label[!in_db], known_labels)
  if (length(mislabelled) > 0)
    problems <- c(problems, sprintf('parent label(s) flagged parent_in_db = FALSE are source labels: %s',
                                    paste(mislabelled, collapse = ', ')))
  # one priority per child label
  pr <- deps[!is.na(deps$priority), c('child_label', 'priority')]
  pr <- unique(pr)
  if (anyDuplicated(pr$child_label))
    problems <- c(problems, sprintf('conflicting priorities for: %s',
                                    paste(unique(pr$child_label[duplicated(pr$child_label)]), collapse = ', ')))
  cyc <- DependencyCycle(deps)
  if (length(cyc) > 0)
    problems <- c(problems, sprintf('the registry has a cycle through: %s', paste(cyc, collapse = ', ')))
  if (length(problems) > 0)
    stop('source_dependencies.csv: ', paste(problems, collapse = '; '), call. = FALSE)
  rownames(deps) <- NULL
  deps
}

# Labels left after repeatedly removing nodes without outgoing edges (Kahn's
# algorithm on child -> parent); empty when the registry is acyclic.
DependencyCycle <- function(deps) {
  e <- unique(deps[, c('child_label', 'parent_label')])
  repeat {
    sinks <- setdiff(e$parent_label, e$child_label)     # parents that are nobody's child
    if (length(sinks) == 0) break
    e <- e[!e$parent_label %in% sinks, , drop = FALSE]
    if (nrow(e) == 0) break
  }
  unique(c(e$child_label, e$parent_label))
}

# Priority per child label (the smallest value given on its edges); labels
# without one are not in the vector and take default_priority.
LabelPriority <- function(deps) {
  pr <- deps[!is.na(deps$priority), c('child_label', 'priority')]
  if (nrow(pr) == 0) return(integer(0))
  out <- tapply(pr$priority, pr$child_label, min)
  setNames(as.integer(out), names(out))
}

# Transitive closure of the collapsing edges (all relations but
# provenance_only): one row per (label, ancestor) with the tolerance of the
# route (the largest edge tolerance along it) and its number of hops. Where
# several routes lead to the same ancestor the largest route tolerance is kept:
# a value may have travelled by any of them, so a match within the loosest
# route counts (Myhrvold_2015 reaches Dunning_2008 directly with 0.0105 and
# through AnAge with 1e-6; its bird values are compared with AVONET at 0.0105).
DependencyClosure <- function(deps) {
  e <- deps[deps$relation != 'provenance_only', c('child_label', 'parent_label', 'tol_log10')]
  empty <- data.frame(label = character(0), ancestor = character(0),
                      tol_log10 = numeric(0), hops = integer(0), stringsAsFactors = FALSE)
  if (nrow(e) == 0) return(empty)
  anc_of <- function(label, depth = 0L) {
    if (depth > nrow(e)) stop('dependency registry is not acyclic', call. = FALSE)
    ps <- e[e$child_label == label, , drop = FALSE]
    if (nrow(ps) == 0) return(empty[, c('ancestor', 'tol_log10', 'hops')])
    out <- data.frame(ancestor = ps$parent_label, tol_log10 = ps$tol_log10, hops = 1L,
                      stringsAsFactors = FALSE)
    for (i in seq_len(nrow(ps))) {
      up <- anc_of(ps$parent_label[i], depth + 1L)
      if (nrow(up) > 0)
        out <- rbind(out, data.frame(ancestor = up$ancestor,
                                     tol_log10 = pmax(ps$tol_log10[i], up$tol_log10),
                                     hops = up$hops + 1L, stringsAsFactors = FALSE))
    }
    out <- out[order(out$ancestor, -out$tol_log10, out$hops), , drop = FALSE]
    out[!duplicated(out$ancestor), , drop = FALSE]
  }
  labels  <- unique(e$child_label)
  closure <- do.call(rbind, lapply(labels, function(l) {
    a <- anc_of(l)
    if (nrow(a) == 0) return(NULL)
    data.frame(label = l, a, stringsAsFactors = FALSE)
  }))
  if (is.null(closure)) return(empty)
  rownames(closure) <- NULL
  closure
}

# Unordered pairs of labels that the registry relates, with the tolerance that
# applies to the pair: ancestor/descendant pairs take the route tolerance; two
# labels with a common ancestor (in the database or external) take the larger of
# their two route tolerances. Where several relations connect a pair the largest
# tolerance applies, for the same reason as in DependencyClosure().
RelatedPairs <- function(closure) {
  empty <- data.frame(a = character(0), b = character(0), tol_log10 = numeric(0),
                      kind = character(0), stringsAsFactors = FALSE)
  if (nrow(closure) == 0) return(empty)
  direct <- data.frame(a = closure$label, b = closure$ancestor, tol_log10 = closure$tol_log10,
                       kind = 'ancestor', stringsAsFactors = FALSE)
  sib <- merge(closure[, c('label', 'ancestor', 'tol_log10')],
               closure[, c('label', 'ancestor', 'tol_log10')], by = 'ancestor')
  sib <- sib[sib$label.x < sib$label.y, , drop = FALSE]
  sib <- data.frame(a = sib$label.x, b = sib$label.y,
                    tol_log10 = pmax(sib$tol_log10.x, sib$tol_log10.y),
                    kind = 'sibling', stringsAsFactors = FALSE)
  rel <- rbind(direct, sib)
  k1 <- pmin(rel$a, rel$b); k2 <- pmax(rel$a, rel$b)
  rel$a <- k1; rel$b <- k2
  rel <- rel[order(rel$a, rel$b, -rel$tol_log10, rel$kind != 'ancestor'), , drop = FALSE]
  rel <- rel[!duplicated(rel[, c('a', 'b')]), , drop = FALSE]
  rownames(rel) <- NULL
  rel
}

# Number of significant digits of the decimal representation of x (at most 15;
# trailing zeros are not counted, so 1200 has two and 1230 three).
SignificantDigits <- function(x) {
  s <- sprintf('%.15g', x)
  s <- sub('[eE].*$', '', s)
  s <- gsub('[^0-9]', '', s)
  s <- sub('^0+', '', s)
  s <- sub('0+$', '', s)
  nchar(s)
}

# TRUE where x and y are the same number to at least `min_sf` significant
# digits: they agree once both are rounded to the precision of the less precise
# one, and that precision is at least min_sf digits. 1234 vs 1230 is identical
# (three digits), 1234 vs 1236 is not (four digits each, and they differ), and
# 1200 vs 1200 is excluded (two digits: a round number that two compilations may
# well quote independently).
IdenticalToSF <- function(x, y, min_sf = 3) {
  p  <- pmin(SignificantDigits(x), SignificantDigits(y))
  ok <- !is.na(x) & !is.na(y) & p >= min_sf
  if (any(ok))
    ok[ok] <- abs(signif(x[ok], p[ok]) - signif(y[ok], p[ok])) <=
      1e-9 * pmax(abs(x[ok]), abs(y[ok]))
  ok
}

# Mark the independent values among the Pass-1 rows (one row per accepted
# species x source label; columns genus, species, source_label, mass_g).
# Returns a list:
#   values   within_source with `independent` (logical), `collapsed_into` (label
#            of the kept value, NA where independent) and `dedupe_rule` (NA
#            where independent; 'registry' when the value has a registry match
#            in its component; otherwise 'blind', or 'blind (provenance_only
#            edge)' when it is blind-identical to a provenance_only partner, or
#            'blind (via third source)' when it shares a component with a
#            provenance_only partner it does not match itself)
#   pairs    every within-species pair of values with the log10 difference,
#            the registry tolerance that applied (NA if unrelated) and the
#            registry / blind matches (the material of WriteDedupeReport)
#   closure, related   the registry closure and the related label pairs
DedupeSources <- function(within_source, deps, blind_min_sf = 3, exact_tol = 1e-6) {
  need <- c('genus', 'species', 'source_label', 'mass_g')
  if (!all(need %in% names(within_source)))
    stop('DedupeSources(): within_source needs columns ', paste(need, collapse = ', '), call. = FALSE)
  ws <- as.data.frame(within_source, stringsAsFactors = FALSE)
  ws$.row <- seq_len(nrow(ws))
  ws$.key <- paste(ws$genus, ws$species)
  if (anyDuplicated(paste(ws$.key, ws$source_label)))
    stop('DedupeSources(): more than one value per species and source label', call. = FALSE)
  closure <- DependencyClosure(deps)
  rel     <- RelatedPairs(closure)
  prio    <- LabelPriority(deps)
  n_anc   <- table(closure$label)

  dup_keys <- unique(ws$.key[duplicated(ws$.key)])
  multi <- ws[ws$.key %in% dup_keys, c('.row', '.key', 'source_label', 'mass_g')]
  pairs <- merge(multi, multi, by = '.key', suffixes = c('.i', '.j'))
  pairs <- pairs[pairs$.row.i < pairs$.row.j, , drop = FALSE]
  pairs$d     <- abs(log10(pairs$mass_g.i) - log10(pairs$mass_g.j))
  pairs$exact <- pairs$d <= exact_tol
  a <- pmin(pairs$source_label.i, pairs$source_label.j)
  b <- pmax(pairs$source_label.i, pairs$source_label.j)
  m <- match(paste(a, b), paste(rel$a, rel$b))
  pairs$reg_tol  <- rel$tol_log10[m]
  pairs$registry <- !is.na(pairs$reg_tol) & pairs$d <= pairs$reg_tol
  # The blind rule is registry-independent by design: it also fires on pairs
  # registered provenance_only (identical values are the same datum whatever
  # the relation; #31). Such pairs are flagged so the collapses can be labelled.
  pairs$blind    <- IdenticalToSF(pairs$mass_g.i, pairs$mass_g.j, blind_min_sf)
  prov <- deps[deps$relation == 'provenance_only' & deps$parent_in_db, , drop = FALSE]
  pairs$prov_only <- paste(a, b) %in% paste(pmin(prov$child_label, prov$parent_label),
                                            pmax(prov$child_label, prov$parent_label))
  pairs$match    <- pairs$registry | pairs$blind      # provenance_only pairs included (#31)

  # connected components of matching pairs within species: propagate the
  # smallest row id along the edges until nothing changes
  comp <- ws$.row
  e <- pairs[pairs$match, c('.row.i', '.row.j'), drop = FALSE]
  if (nrow(e) > 0) {
    repeat {
      mn  <- pmin(comp[e$.row.i], comp[e$.row.j])
      upd <- tapply(c(mn, mn), c(e$.row.i, e$.row.j), min)
      idx <- as.integer(names(upd))
      new <- pmin(comp[idx], as.integer(upd))
      if (all(new == comp[idx])) break
      comp[idx] <- new
    }
  }
  ws$.comp <- comp
  pairs$same_component <- ws$.comp[pairs$.row.i] == ws$.comp[pairs$.row.j]

  # one kept value per component: the member that is a registry ancestor of the
  # most other members, then the lowest priority, the fewest ancestors, the
  # first label
  grp <- ws[ws$.comp %in% ws$.comp[duplicated(ws$.comp)], c('.row', '.comp', 'source_label')]
  ws$independent    <- TRUE
  ws$collapsed_into <- NA_character_
  ws$dedupe_rule    <- NA_character_
  if (nrow(grp) > 0) {
    mm <- merge(grp, grp, by = '.comp')
    mm <- mm[mm$.row.x != mm$.row.y, , drop = FALSE]
    is_anc <- paste(mm$source_label.y, mm$source_label.x) %in% paste(closure$label, closure$ancestor)
    n_desc <- tapply(is_anc, mm$.row.x, sum)
    grp$n_desc <- as.integer(n_desc[as.character(grp$.row)])
    grp$n_desc[is.na(grp$n_desc)] <- 0L
    grp$prio  <- unname(prio[grp$source_label]); grp$prio[is.na(grp$prio)] <- default_priority
    grp$n_anc <- as.integer(n_anc[grp$source_label]); grp$n_anc[is.na(grp$n_anc)] <- 0L
    grp <- grp[order(grp$.comp, -grp$n_desc, grp$prio, grp$n_anc, grp$source_label), ]
    rep <- grp[!duplicated(grp$.comp), c('.comp', '.row', 'source_label')]
    rep_row <- rep$.row[match(ws$.comp, rep$.comp)]
    ws$independent <- is.na(rep_row) | rep_row == ws$.row
    ws$collapsed_into[!ws$independent] <- ws$source_label[rep_row[!ws$independent]]
    reg_rows <- unique(c(pairs$.row.i[pairs$registry], pairs$.row.j[pairs$registry]))
    # blind-identical to a provenance_only partner, or sharing a component with
    # one it does not match itself (joined through a third source)
    pb <- pairs[pairs$blind & pairs$prov_only, , drop = FALSE]
    pv <- pairs[pairs$prov_only & pairs$same_component & !pairs$match, , drop = FALSE]
    direct_rows   <- unique(c(pb$.row.i, pb$.row.j))
    indirect_rows <- unique(c(pv$.row.i, pv$.row.j))
    rule <- ifelse(ws$.row %in% reg_rows, 'registry',
            ifelse(ws$.row %in% direct_rows, 'blind (provenance_only edge)',
            ifelse(ws$.row %in% indirect_rows, 'blind (via third source)', 'blind')))
    ws$dedupe_rule[!ws$independent] <- rule[!ws$independent]
  }
  values <- ws[, setdiff(names(ws), c('.row', '.key', '.comp'))]
  pairs  <- pairs[, c('.key', 'source_label.i', 'source_label.j', 'mass_g.i', 'mass_g.j', 'd',
                      'exact', 'reg_tol', 'registry', 'blind', 'prov_only', 'match', 'same_component')]
  names(pairs)[1] <- 'species_key'
  rownames(pairs) <- NULL
  list(values = values, pairs = pairs, closure = closure, related = rel,
       exact_tol = exact_tol, blind_min_sf = blind_min_sf)
}

# Markdown table from a data frame (character columns left-aligned, numbers
# right-aligned).
MarkdownTable <- function(df) {
  if (nrow(df) == 0) return('(none)')
  fmt <- function(x) if (is.numeric(x)) ifelse(is.na(x), '', format(x, trim = TRUE, scientific = FALSE, drop0trailing = TRUE)) else ifelse(is.na(x), '', as.character(x))
  cells <- vapply(df, fmt, character(nrow(df)))
  if (is.null(dim(cells))) cells <- matrix(cells, nrow = nrow(df))
  align <- ifelse(vapply(df, is.numeric, logical(1)), '---:', '---')
  c(paste0('| ', paste(names(df), collapse = ' | '), ' |'),
    paste0('| ', paste(align, collapse = ' | '), ' |'),
    apply(cells, 1, function(r) paste0('| ', paste(r, collapse = ' | '), ' |')))
}

# Summary of what the registry and the blind rule did, written as markdown:
# totals, every registry edge with the species it shares and collapsed, the
# sibling pairs behind each external parent, the provenance-only edges (with
# the values the blind rule collapsed on them, #31), the
# species left with a single independent value, and the pairs of sources that
# are value-identical for >= `min_residual` species without any registry
# relation (candidates for new edges, or shared primary literature).
WriteDedupeReport <- function(dd, deps, path, min_residual = 20) {
  v <- dd$values; p <- dd$pairs
  key <- paste(v$genus, v$species)
  n_per_species <- table(key)
  multi_keys <- names(n_per_species)[n_per_species > 1]
  n_indep <- tapply(v$independent, key, sum)
  species_dep <- names(n_indep)[as.integer(n_per_species[names(n_indep)]) > as.integer(n_indep)]
  single <- names(n_indep)[names(n_indep) %in% multi_keys & n_indep == 1]
  totals <- data.frame(
    quantity = c('species x source values (Pass-1 rows)', 'accepted species', 'multi-source species',
                 'within-species value pairs', sprintf('pairs identical (|dlog10| <= %g)', dd$exact_tol),
                 'pairs related by the registry and within its tolerance',
                 sprintf('pairs identical to >= %d significant digits (blind rule)', dd$blind_min_sf),
                 'values collapsed (total)', 'values collapsed by a registry edge',
                 'values collapsed by the blind rule only',
                 '... of which blind-identical to a provenance_only partner (blind (provenance_only edge))',
                 '... of which joined to a provenance_only partner through a third source (blind (via third source))',
                 'species with at least one collapsed value',
                 'multi-source species left with one independent value'),
    value = c(nrow(v), length(n_per_species), length(multi_keys), nrow(p), sum(p$exact),
              sum(p$registry), sum(p$blind), sum(!v$independent),
              sum(v$dedupe_rule %in% 'registry'), sum(grepl('^blind', v$dedupe_rule)),
              sum(v$dedupe_rule %in% 'blind (provenance_only edge)'),
              sum(v$dedupe_rule %in% 'blind (via third source)'),
              length(species_dep), length(single)),
    stringsAsFactors = FALSE)

  pair_stats <- function(l1, l2, tol = NA) {
    s <- p[(p$source_label.i == l1 & p$source_label.j == l2) | (p$source_label.i == l2 & p$source_label.j == l1), ]
    c(shared = nrow(s), exact = sum(s$exact), within_tol = if (is.na(tol)) NA_integer_ else sum(s$d <= tol),
      blind = sum(s$blind))
  }
  collapsed_into <- function(child, parent) sum(v$source_label == child & !v$independent & v$collapsed_into %in% parent)

  in_db <- deps[deps$parent_in_db & deps$relation != 'provenance_only', ]
  edge_tab <- do.call(rbind, lapply(seq_len(nrow(in_db)), function(i) {
    st <- pair_stats(in_db$child_label[i], in_db$parent_label[i], in_db$tol_log10[i])
    data.frame(child = in_db$child_label[i], parent = in_db$parent_label[i], relation = in_db$relation[i],
               status = in_db$status[i], tol_log10 = in_db$tol_log10[i], shared = st[['shared']],
               exact = st[['exact']], within_tol = st[['within_tol']],
               f_exact = if (st[['shared']] > 0) round(st[['exact']] / st[['shared']], 2) else NA_real_,
               collapsed_into_parent = collapsed_into(in_db$child_label[i], in_db$parent_label[i]),
               child_collapsed_total = sum(v$source_label == in_db$child_label[i] & !v$independent),
               stringsAsFactors = FALSE)
  }))
  if (is.null(edge_tab)) edge_tab <- data.frame()

  ext <- deps[!deps$parent_in_db & deps$relation != 'provenance_only', ]
  sib_tab <- do.call(rbind, lapply(unique(ext$parent_label), function(par) {
    kids <- sort(unique(ext$child_label[ext$parent_label == par]))
    kids <- kids[kids %in% v$source_label]
    if (length(kids) < 2) return(NULL)
    cmb <- combn(kids, 2)
    do.call(rbind, lapply(seq_len(ncol(cmb)), function(k) {
      a <- cmb[1, k]; b <- cmb[2, k]
      tol <- dd$related$tol_log10[dd$related$a == min(a, b) & dd$related$b == max(a, b)]
      tol <- if (length(tol)) tol[1] else NA
      st <- pair_stats(a, b, tol)
      data.frame(external_parent = par, pair = paste(a, b, sep = ' - '), tol_log10 = tol,
                 shared = st[['shared']], exact = st[['exact']], within_tol = st[['within_tol']],
                 f_exact = if (st[['shared']] > 0) round(st[['exact']] / st[['shared']], 2) else NA_real_,
                 collapsed = collapsed_into(a, b) + collapsed_into(b, a), stringsAsFactors = FALSE)
    }))
  }))
  if (is.null(sib_tab)) sib_tab <- data.frame()

  prov <- deps[deps$relation == 'provenance_only', ]
  # values the blind rule collapsed on a provenance_only pair: directly
  # identical to the partner, or joined to it through a third source (#31)
  v_key <- paste(v$genus, v$species)
  prov_collapsed <- function(child, parent, label) {
    s <- p[(p$source_label.i == child & p$source_label.j == parent) | (p$source_label.i == parent & p$source_label.j == child), ]
    s <- s[s$same_component, , drop = FALSE]
    if (nrow(s) == 0) return(0L)
    rows <- unique(c(match(paste(s$species_key, s$source_label.i), paste(v_key, v$source_label)),
                     match(paste(s$species_key, s$source_label.j), paste(v_key, v$source_label))))
    sum(v$dedupe_rule[rows] %in% label)
  }
  prov_tab <- do.call(rbind, lapply(seq_len(nrow(prov)), function(i) {
    st <- if (prov$parent_in_db[i]) pair_stats(prov$child_label[i], prov$parent_label[i]) else c(shared = NA, exact = NA, within_tol = NA, blind = NA)
    data.frame(child = prov$child_label[i], parent = prov$parent_label[i], parent_in_db = prov$parent_in_db[i],
               shared = st[['shared']], exact = st[['exact']], blind_identical = st[['blind']],
               collapsed_blind_direct = if (prov$parent_in_db[i]) prov_collapsed(prov$child_label[i], prov$parent_label[i], 'blind (provenance_only edge)') else 0L,
               collapsed_via_third_source = if (prov$parent_in_db[i]) prov_collapsed(prov$child_label[i], prov$parent_label[i], 'blind (via third source)') else 0L,
               stringsAsFactors = FALSE)
  }))
  if (is.null(prov_tab)) prov_tab <- data.frame()

  # residual identical pairs without a registry relation
  res <- p[is.na(p$reg_tol), ]
  if (nrow(res) > 0) {
    ka <- pmin(res$source_label.i, res$source_label.j); kb <- pmax(res$source_label.i, res$source_label.j)
    agg <- aggregate(cbind(shared = 1, exact = res$exact, blind = res$blind,
                           round_identical = res$exact & !res$blind),
                     by = list(a = ka, b = kb), FUN = sum)
    agg <- agg[agg$exact >= min_residual, ]
    agg <- agg[order(-agg$exact), ]
    res_tab <- data.frame(pair = paste(agg$a, agg$b, sep = ' - '), shared = agg$shared, exact = agg$exact,
                          f_exact = round(agg$exact / agg$shared, 2), identical_to_3sf = agg$blind,
                          identical_but_round = agg$round_identical, stringsAsFactors = FALSE)
  } else res_tab <- data.frame()

  n_src_single <- table(as.integer(n_per_species[single]))
  single_tab <- data.frame(n_sources = as.integer(names(n_src_single)), species = as.integer(n_src_single))

  lines <- c(
    sprintf('# Source de-duplication summary -- %s', format(Sys.time(), '%Y-%m-%d %H:%M:%S')),
    '',
    paste('Values that enter through several compilations are collapsed before the cross-source mean',
          '(issue #5): a registry edge collapses a child value into its parent (or a sibling sharing an',
          'external parent) when the two agree within the edge tolerance; the blind rule collapses values',
          sprintf('identical to >= %d significant digits in any two sources, whatever the registry says about the pair;', dd$blind_min_sf),
          '`provenance_only` edges grant no tolerance-based collapse (their blind collapses are counted below, #31).',
          'Registry: `Bib/source_dependencies.csv`; code: `R/library/dedupe_sources.r`.'),
    '', '## Totals', '', MarkdownTable(totals),
    '', '## Registry edges with the parent in the database', '',
    'shared = species with a value in both; exact = identical within 1e-6 log10; within_tol = within the edge tolerance;',
    'collapsed_into_parent = child values collapsed into this parent; child_collapsed_total = child values collapsed into any kept value.',
    '', MarkdownTable(edge_tab),
    '', '## Siblings sharing an external parent', '',
    'Pairs of sources that the registry traces to the same compilation outside the database; collapsed = values of either collapsed into the other.',
    '', MarkdownTable(sib_tab),
    '', '## Provenance-only edges (no tolerance-based collapse)', '',
    paste('A provenance_only edge documents a relation whose values generally differ and takes no part in the registry',
          'closure. Values identical to >= 3 significant digits on such a pair are still collapsed by the blind rule and',
          'labelled `blind (provenance_only edge)`; values joined to the partner only through a third source are labelled',
          '`blind (via third source)` (#31).'),
    '', MarkdownTable(prov_tab),
    '', '## Multi-source species left with one independent value', '',
    sprintf('%d multi-source species rest on a single independent value after de-duplication, by number of sources:', length(single)),
    '', MarkdownTable(single_tab),
    '', sprintf('## Residual identical pairs outside the registry (>= %d identical species)', min_residual), '',
    paste('Source pairs with no registry relation whose values are identical for many species: candidates for a new',
          'registry edge, or shared primary literature. identical_to_3sf = pairs the blind rule collapses;',
          'identical_but_round = identical values of one or two significant digits, left alone.'),
    '', MarkdownTable(res_tab), '')
  writeLines(lines, path)
  invisible(list(totals = totals, edges = edge_tab, siblings = sib_tab, provenance_only = prov_tab,
                 residual = res_tab, single = single_tab))
}
