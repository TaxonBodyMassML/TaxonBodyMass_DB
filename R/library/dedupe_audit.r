# Audit of the source de-duplication (#5): replicates Pass 1, the de-duplication
# and Pass 2 of R/RunMe.r from the cached frames in sources/Rdata and the
# enrichment cache, without network access or the Google Sheet override, and
# compares the result with the released TaxonBodyMass.csv (and optionally with
# the CSV of the previous release).
#
#   Rscript R/library/dedupe_audit.r [--before <old TaxonBodyMass.csv>] [--after <TaxonBodyMass.csv>]
#
# --after defaults to TaxonBodyMass.csv at the repository root. With --before
# (a CSV written before de-duplication existed, or any earlier release) the
# script also reports how well the replication reproduces that file, which
# species the de-duplication moved and by how much, and that species without
# dependencies are unchanged. Everything is printed; nothing is written.
#
# Sections: 1 replication of the pipeline; 2 de-duplication totals and shifts;
# 3 registry edge fractions and the VertNet check; 4 invariants of the --after
# CSV and its agreement with the replication; 5 --before vs --after.

suppressPackageStartupMessages({ library(plyr); library(dplyr) })
options(width = 200)

args <- commandArgs(trailingOnly = TRUE)
arg <- function(flag, default = NULL) { i <- match(flag, args); if (is.na(i) || i == length(args)) default else args[i + 1] }
this_file <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE))
if (length(this_file) == 0) this_file <- file.path('R', 'library', 'dedupe_audit.r')
wd_root  <- normalizePath(file.path(dirname(this_file), '..', '..'))
wd_db    <- file.path(wd_root, 'sources', 'databases')
wd_rdata <- file.path(wd_root, 'sources', 'Rdata')
after_csv  <- arg('--after', file.path(wd_root, 'TaxonBodyMass.csv'))
before_csv <- arg('--before')
for (f in c('helpers.r', 'fix_formatting.r', 'fix_misspellings.r', 'fix_nontaxa.r',
            'fix_taxonomy_ranks.r', 'filter_autotrophs.r', 'filter_extinct.r', 'dedupe_sources.r'))
  source(file.path(wd_root, 'R', 'library', f))
Section <- function(x) cat('\n==== ', x, '\n', sep = '')
Line <- function(...) cat(sprintf(...), '\n', sep = '')
Shifts <- function(d, label) {
  d <- d[is.finite(d)]
  Line('  %-58s n %6d | > 0.05: %5d | > 0.1: %5d | > 0.3: %4d | max %.3f', label, length(d),
       sum(abs(d) > 0.05), sum(abs(d) > 0.1), sum(abs(d) > 0.3), if (length(d)) max(abs(d)) else 0)
}
Tokens <- function(x) lapply(strsplit(ifelse(is.na(x), '', x), ';', fixed = TRUE), function(t) sort(trimws(t[nzchar(trimws(t))])))

# ---- 1. replicate RunMe.r steps 2-5 without network -------------------------------
Section('1. Replication of the pipeline from sources/Rdata (no Sheet override, no network)')
t0 <- Sys.time()
frames <- list.files(wd_rdata, pattern = '\\.Rdata$', full.names = TRUE)
if (length(frames) == 0) stop('no frames in sources/Rdata; run RunMe.r with recompile = TRUE first')
source_list <- lapply(frames, function(f) { e <- new.env(); load(f, envir = e); get(ls(e)[1], envir = e) })
source_list <- lapply(source_list, FixFormatting)
source_list <- lapply(source_list, function(df) { df$source_mass <- NormaliseSourceLabel(df$source_mass); df })
source_list <- suppressMessages(lapply(source_list, FixMisspellings))
source_list <- suppressMessages(lapply(source_list, RemoveNonTaxa))
source_list <- suppressMessages(lapply(source_list, RemoveExtinct))
source_list <- lapply(source_list, FixTaxonomyRanks)
tax_cols <- c('kingdom', 'phylum', 'class', 'order', 'family')
source_list <- lapply(source_list, function(df) { for (col in tax_cols) if (!col %in% names(df)) df[[col]] <- NA_character_; df })
adat <- bind_rows(source_list)
adat <- adat[grepl('_', adat$taxon), ]
load(file.path(wd_root, 'sources', 'enrich_cache.Rdata'))
enrich_cache <- FixTaxonomyRanks(enrich_cache)
unique_taxa <- enrich_cache[enrich_cache$taxon %in% unique(adat$taxon), ]
enrich_cols <- c('taxon', 'species', 'genus', 'kingdom', 'phylum', 'class', 'order', 'family')
adat_enriched <- merge(adat[, setdiff(names(adat), tax_cols)], unique_taxa[, enrich_cols], by = 'taxon', all.x = TRUE)
adat_enriched <- suppressMessages(FilterAutotrophs(adat_enriched))
adat_enriched <- adat_enriched[!is.na(adat_enriched$species), ]
adat_enriched$source_label <- SourceLabel(adat_enriched$source_mass)
adat_enriched$source_group <- SourceGroup(adat_enriched$source_label)
Line('  %d records, %d accepted species, %d distinct labels (%d frames) in %.0f s', nrow(adat_enriched),
     n_distinct(adat_enriched$species), n_distinct(adat_enriched$source_label), length(frames),
     as.numeric(Sys.time() - t0, units = 'secs'))

# Pass 1 as before #5 (grouped by the full source_mass string) and as now
ws_old <- adat_enriched %>% group_by(genus, species, source_mass) %>%
  summarise(mass_g = 10^mean(log10(mass_g)), n = n(), .groups = 'drop')
ws <- adat_enriched %>% group_by(genus, species, source_group) %>%
  summarise(source_label = paste(sort(unique(source_label)), collapse = '+'),
            source_mass  = paste(unique(trimws(unlist(strsplit(sort(unique(source_mass)), ';', fixed = TRUE)))), collapse = '; '),
            mass_g = 10^mean(log10(mass_g)), n = n(), .groups = 'drop')
deps <- LoadSourceDependencies(file.path(wd_root, 'Bib', 'source_dependencies.csv'),
                               known_labels = unique(adat_enriched$source_label))
dd <- DedupeSources(ws, deps)
v  <- dd$values
Pass2 <- function(w, indep = rep(TRUE, nrow(w))) {
  w$indep <- indep
  w %>% group_by(genus, species) %>%
    summarise(log10_range = if (sum(indep) > 1) log10(max(mass_g[indep]) / min(mass_g[indep])) else 0,
              n = sum(n), n_sources = n(), n_independent = sum(indep),
              source_mass = paste(unique(trimws(unlist(strsplit(source_mass, ';', fixed = TRUE)))), collapse = '; '),
              mass_g = signif(mean(mass_g[indep]), 4),       # last: it shadows the column
              .groups = 'drop')
}
old      <- Pass2(ws_old)                      # Pass 1/2 before #5
regroup  <- Pass2(ws)                          # new Pass 1 grouping, every value in the mean
new      <- Pass2(v, v$independent)            # new Pass 1 grouping, independent values only
new$source_dependencies <- (v %>% group_by(genus, species) %>%
  summarise(sd = if (any(!independent)) paste(paste0(source_label[!independent], '<', collapsed_into[!independent]), collapse = '; ') else NA_character_, .groups = 'drop'))$sd
Line('  Pass-1 rows: %d (by source_mass string, before #5) -> %d (by label, VertNet pooled); species %d',
     nrow(ws_old), nrow(ws), nrow(new))

# ---- 2. de-duplication totals and shifts ----------------------------------------------
Section('2. De-duplication (replication)')
key <- paste(v$genus, v$species)
multi <- names(which(table(key) > 1))
Line('  values collapsed: %d of %d (registry %d, blind rule %d)', sum(!v$independent), nrow(v),
     sum(v$dedupe_rule %in% 'registry'), sum(v$dedupe_rule %in% 'blind'))
Line('  species with at least one collapsed value: %d of %d multi-source species', length(unique(key[!v$independent])), length(multi))
Line('  multi-source species left with one independent value: %d', sum(new$n_sources > 1 & new$n_independent == 1))
j <- inner_join(regroup, new, by = c('genus', 'species'), suffix = c('.all', '.ind'))
Shifts(log10(j$mass_g.ind / j$mass_g.all), 'shift from de-duplication alone, all species')
Shifts(log10(j$mass_g.ind / j$mass_g.all)[j$log10_range.ind <= 1], 'shift from de-duplication alone, species kept by the range filter')
k <- inner_join(old, regroup, by = c('genus', 'species'), suffix = c('.old', '.new'))
Shifts(log10(k$mass_g.new / k$mass_g.old), 'shift from the Pass-1 regrouping alone (label, VertNet pooled)')
Line('  log10_range > 1: %d before #5, %d after regrouping, %d after de-duplication; species crossing 1 by de-duplication: %d',
     sum(old$log10_range > 1), sum(regroup$log10_range > 1), sum(new$log10_range > 1),
     sum((j$log10_range.all > 1) != (j$log10_range.ind > 1)))
big <- j[abs(log10(j$mass_g.ind / j$mass_g.all)) > 0.3 & j$log10_range.ind <= 1, ]
if (nrow(big) > 0) {
  cat('  species kept by the range filter that move by more than 0.3 log10:\n')
  for (i in seq_len(nrow(big))) Line('    %s %s: %.4g -> %.4g g (n_sources %d, n_independent %d, log10_range %.2f)',
    big$genus[i], sub('^\\S+ ', '', big$species[i]), big$mass_g.all[i], big$mass_g.ind[i], big$n_sources.ind[i], big$n_independent.ind[i], big$log10_range.ind[i])
}

# ---- 3. edge fractions and VertNet ----------------------------------------------------
Section('3. Registry edge fractions (identical = |dlog10| <= 1e-6) and VertNet')
p <- dd$pairs
Frac <- function(l1, l2, expect) {
  s <- p[(p$source_label.i == l1 & p$source_label.j == l2) | (p$source_label.i == l2 & p$source_label.j == l1), ]
  f <- sum(s$exact) / nrow(s)
  Line('  %-40s shared %5d identical %5d f_exact %.3f (expected >= %.2f: %s)', paste(l1, l2, sep = ' - '), nrow(s), sum(s$exact), f, expect, if (f >= expect) 'ok' else 'BELOW')
}
Frac('Tobias_2022', 'Wilman_etal_2014', 0.94)
Frac('Myhrvold_2015', 'Soria_etal_2021', 0.98)
Frac('Hoehler_etal_2023', 'Makarieva_2008', 0.80)
Line('  AnAge - Makarieva_2008 / Uyeda_etal_2017 / Hoehler_etal_2023 identical pairs: %d / %d / %d (after #15)',
     sum(p$exact & ((p$source_label.i == 'AnAge' & p$source_label.j == 'Makarieva_2008') | (p$source_label.j == 'AnAge' & p$source_label.i == 'Makarieva_2008'))),
     sum(p$exact & ((p$source_label.i == 'AnAge' & p$source_label.j == 'Uyeda_etal_2017') | (p$source_label.j == 'AnAge' & p$source_label.i == 'Uyeda_etal_2017'))),
     sum(p$exact & ((p$source_label.i == 'AnAge' & p$source_label.j == 'Hoehler_etal_2023') | (p$source_label.j == 'AnAge' & p$source_label.i == 'Hoehler_etal_2023'))))
vv <- sum(grepl('^vertnet', p$source_label.i) & grepl('^vertnet', p$source_label.j))
Line('  vertnet x vertnet value pairs: %d (%s)', vv, if (vv == 0) 'ok' else 'NOT ZERO')
Line('  pooled VertNet groups (two or more dumps for one species): %d', sum(grepl('+', v$source_label, fixed = TRUE)))

# ---- 4. the --after CSV ------------------------------------------------------------------
Section(paste('4. Checks on', after_csv))
aft <- read.csv(after_csv, stringsAsFactors = FALSE)
need <- c('n_sources', 'n_independent', 'source_dependencies')
if (!all(need %in% names(aft))) {
  Line('  columns %s missing: this file predates #5', paste(setdiff(need, names(aft)), collapse = ', '))
} else {
  ok1 <- aft$n_independent <= aft$n_sources & aft$n_sources <= aft$n & aft$n_independent >= 1
  Line('  rows %d; 1 <= n_independent <= n_sources <= n: %s (%d violations)', nrow(aft), if (all(ok1)) 'ok' else 'FAIL', sum(!ok1))
  n_dep <- ifelse(is.na(aft$source_dependencies) | aft$source_dependencies == '', 0L,
                  lengths(strsplit(aft$source_dependencies, ';', fixed = TRUE)))
  ok2 <- n_dep == aft$n_sources - aft$n_independent
  Line('  source_dependencies pairs == n_sources - n_independent: %s (%d violations)', if (all(ok2)) 'ok' else 'FAIL', sum(!ok2))
  toks <- Tokens(aft$source_mass)
  ok3 <- mapply(function(sd, tk) {
    if (is.na(sd) || sd == '') return(TRUE)
    labs <- unlist(strsplit(unlist(strsplit(sd, ';', fixed = TRUE)), '[<+]'))
    all(trimws(labs) %in% tk)
  }, aft$source_dependencies, toks)
  Line('  every label in source_dependencies occurs in source_mass: %s (%d violations)', if (all(ok3)) 'ok' else 'FAIL', sum(!ok3))
  Line('  species with dependencies %d; multi-source species with one independent value %d; values collapsed %d',
       sum(n_dep > 0), sum(aft$n_sources > 1 & aft$n_independent == 1), sum(n_dep))
  m <- inner_join(aft, new, by = c('genus', 'species'), suffix = c('.csv', '.rep'))
  same <- with(m, abs(log10(mass_g.csv / mass_g.rep)) < 1e-9 & n.csv == n.rep & n_sources.csv == n_sources.rep &
                 n_independent.csv == n_independent.rep & abs(log10_range.csv - log10_range.rep) < 1e-9 &
                 (is.na(source_dependencies.csv) == is.na(source_dependencies.rep)) &
                 (is.na(source_dependencies.csv) | source_dependencies.csv == source_dependencies.rep))
  Line('  replication vs CSV: %d of %d CSV species replicated; mass, n, n_sources, n_independent, log10_range and dependencies agree for %d (%.2f%%; the rest is the Sheet override)',
       nrow(m), nrow(aft), sum(same), 100 * mean(same))
  Line('  CSV species absent from the replication (Sheet-only taxa or synonyms): %d; replicated species absent from the CSV (range filter): %d',
       nrow(aft) - nrow(m), nrow(new) - nrow(m))
}

# ---- 5. before vs after ---------------------------------------------------------------------
if (!is.null(before_csv)) {
  Section(paste('5.', before_csv, 'vs', after_csv))
  bef <- read.csv(before_csv, stringsAsFactors = FALSE)
  mb <- inner_join(bef, old, by = c('genus', 'species'), suffix = c('.csv', '.rep'))
  same_b <- with(mb, abs(log10(mass_g.csv / mass_g.rep)) < 1e-9 & n.csv == n.rep & abs(log10_range.csv - log10_range.rep) < 1e-9)
  Line('  replication of the pre-#5 pipeline vs the before CSV: %d of %d species replicated; mass, n and log10_range agree for %d (%.2f%%)',
       nrow(mb), nrow(bef), sum(same_b), 100 * mean(same_b))
  ba <- inner_join(bef, aft, by = c('genus', 'species'), suffix = c('.b', '.a'))
  Line('  species: before %d, after %d, in both %d, lost %d, gained %d', nrow(bef), nrow(aft), nrow(ba), nrow(bef) - nrow(ba), nrow(aft) - nrow(ba))
  if (all(need %in% names(aft))) {
    nodep <- is.na(ba$source_dependencies) | ba$source_dependencies == ''
    vert  <- grepl('vertnet-traits', ba$source_mass.a, fixed = TRUE) & grepl('vertnet-[a-z]+-sept2016', sub('vertnet-traits-sept2016', '', ba$source_mass.a))
    # species where one label carried several source_mass strings (conversion
    # variants) and therefore several Pass-1 values before #5
    split_lab <- adat_enriched %>% group_by(genus, species, source_label) %>% summarise(k = n_distinct(source_mass), .groups = 'drop') %>% filter(k > 1)
    splt <- paste(ba$genus, ba$species) %in% paste(split_lab$genus, split_lab$species)
    ident <- with(ba, mass_g.b == mass_g.a & n.b == n.a & abs(log10_range.b - log10_range.a) < 1e-12 & source_mass.b == source_mass.a)
    Line('  species without dependencies: %d; identical in mass_g, n, log10_range and source_mass: %d; of the %d that differ, %d have two pooled VertNet dumps and %d a label whose conversion variants were separate values before (Pass-1 regrouping)',
         sum(nodep), sum(ident & nodep), sum(nodep & !ident), sum(nodep & !ident & vert), sum(nodep & !ident & !vert & splt))
    vert <- vert | splt
    if (any(nodep & !ident & !vert)) {
      cat('  species without dependencies that differ for another reason (first 10):\n')
      x <- ba[nodep & !ident & !vert, ][1:min(10, sum(nodep & !ident & !vert)), ]
      for (i in seq_len(nrow(x))) Line('    %s: mass %.4g -> %.4g, n %d -> %d, source_mass %s -> %s', x$species[i], x$mass_g.b[i], x$mass_g.a[i], x$n.b[i], x$n.a[i], x$source_mass.b[i], x$source_mass.a[i])
    }
    Shifts(log10(ba$mass_g.a / ba$mass_g.b)[!nodep], 'shift before -> after, species with dependencies')
    Shifts(log10(ba$mass_g.a / ba$mass_g.b), 'shift before -> after, all species in both files')
    tok_same <- mapply(identical, Tokens(ba$source_mass.b), Tokens(ba$source_mass.a))
    Line('  source_mass: identical strings %d of %d; identical as sets of labels %d', sum(ba$source_mass.b == ba$source_mass.a), nrow(ba), sum(tok_same))
    Line('  n identical for %d species (raw record count); n_independent < n_sources for %d', sum(ba$n.b == ba$n.a), sum(ba$n_independent < ba$n_sources))
    gained <- aft[!paste(aft$genus, aft$species) %in% paste(bef$genus, bef$species), ]
    if (nrow(gained) > 0) {
      g_old <- inner_join(gained, old, by = c('genus', 'species'), suffix = c('.a', '.old'))
      Line('  gained species: %d, of which %d rest on VertNet dumps alone (n_sources 1); their pre-#5 log10_range (between the separate dumps) exceeded 1 for %d',
           nrow(gained), sum(gained$n_sources == 1 & grepl('^vertnet', gained$source_mass)), sum(g_old$log10_range.old > 1))
    }
  }
}
cat('\n')
