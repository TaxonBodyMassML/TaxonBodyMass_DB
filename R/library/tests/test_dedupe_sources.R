# Tests for R/library/dedupe_sources.r (#5): the dependency registry loader,
# the transitive closure, the value-identity rules and DedupeSources() on
# synthetic per-source values. No network access and no packages beyond base R.
#
#   Rscript R/library/tests/test_dedupe_sources.R      (from any directory)
#
# Prints one line per expectation and exits with status 1 if any failed.

this_file <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE))
if (length(this_file) == 0)
  this_file <- file.path('R', 'library', 'tests', 'test_dedupe_sources.R')
repo <- normalizePath(file.path(dirname(this_file), '..', '..', '..'))
source(file.path(repo, 'R', 'library', 'dedupe_sources.r'))

failures <- character(0)
n_checks <- 0L
Expect <- function(ok, what) {
  n_checks <<- n_checks + 1L
  if (!isTRUE(ok)) failures <<- c(failures, what)
  cat(sprintf('  %s %s\n', if (isTRUE(ok)) 'ok  ' else 'FAIL', what))
}
ErrorOf <- function(expr) tryCatch({ expr; NULL }, error = function(e) conditionMessage(e))
Has <- function(x, pattern) !is.null(x) && grepl(pattern, x, fixed = TRUE)

# ---- a registry: chain A -> B -> C, a re-rounding child R of C, a provenance-
# only child P of C, siblings S1/S2 of an external parent, and D reaching C both
# directly (1e-6) and through R (0.0105)
WriteRegistry <- function(rows) {
  f <- tempfile('deps_', fileext = '.csv')
  writeLines(c(paste(dependency_columns, collapse = ','), rows), f)
  f
}
reg_rows <- c(
  'B,C,TRUE,copies,1e-6,,confirmed,,"B copies C",2026-10-03',
  'A,B,TRUE,copies,1e-6,,confirmed,,"A copies B",2026-10-03',
  'R,C,TRUE,via,0.0105,,confirmed,,"R re-rounds C",2026-10-03',
  'P,C,TRUE,provenance_only,1e-6,,confirmed,,"P cites C, values differ",2026-10-03',
  'S1,Ext,FALSE,copies,1e-6,1,confirmed,,"sibling kept",2026-10-03',
  'S2,Ext,FALSE,copies,1e-6,2,confirmed,,"sibling dropped",2026-10-03',
  'D,R,TRUE,copies,1e-6,,suspected,,"D copies R",2026-10-03',
  'D,C,TRUE,copies,1e-6,,confirmed,,"D copies C",2026-10-03')
labels <- c('A', 'B', 'C', 'R', 'P', 'S1', 'S2', 'D', 'X', 'Y',
            'vertnet-aves-sept2016', 'vertnet-traits-sept2016')

cat('LoadSourceDependencies()\n')
deps <- LoadSourceDependencies(WriteRegistry(reg_rows), labels)
Expect(nrow(deps) == 8 && identical(names(deps), dependency_columns), 'valid registry loads with its 10 columns')
Expect(is.logical(deps$parent_in_db) && is.numeric(deps$tol_log10), 'parent_in_db logical, tol_log10 numeric')
Expect(identical(unname(LabelPriority(deps)[c('S1', 'S2')]), c(1L, 2L)), 'priorities read per child label')

e <- ErrorOf(LoadSourceDependencies(WriteRegistry(c(reg_rows, 'Q,C,TRUE,copies,1e-6,,confirmed,,"unknown child",2026-10-03')), labels))
Expect(Has(e, 'child label(s) not found') && Has(e, 'Q'), 'stops on a child label absent from the frames')
e <- ErrorOf(LoadSourceDependencies(WriteRegistry(c(reg_rows, 'A,Gone,TRUE,copies,1e-6,,confirmed,,"removed parent",2026-10-03')), labels))
Expect(Has(e, 'parent_in_db = TRUE not found') && Has(e, 'Gone'), 'stops on an in-database parent absent from the frames')
e <- ErrorOf(LoadSourceDependencies(WriteRegistry(c(reg_rows, 'A,X,FALSE,copies,1e-6,,confirmed,,"mislabelled external",2026-10-03')), labels))
Expect(Has(e, 'parent_in_db = FALSE are source labels') && Has(e, 'X'), 'stops on an external parent that is a source label')
e <- ErrorOf(LoadSourceDependencies(WriteRegistry(c(reg_rows, 'C,A,TRUE,copies,1e-6,,confirmed,,"closes a cycle",2026-10-03')), labels))
Expect(Has(e, 'cycle'), 'stops on a cycle (C -> A with A -> B -> C)')
e <- ErrorOf(LoadSourceDependencies(WriteRegistry(c(reg_rows, 'X,C,TRUE,borrows,1e-6,,confirmed,,"bad relation",2026-10-03')), labels))
Expect(Has(e, 'unknown relation'), 'stops on an unknown relation')
e <- ErrorOf(LoadSourceDependencies(WriteRegistry(c(reg_rows, 'S1,C,TRUE,copies,1e-6,3,confirmed,,"other priority",2026-10-03')), labels))
Expect(Has(e, 'conflicting priorities'), 'stops when one label carries two priorities')
e <- ErrorOf(LoadSourceDependencies(WriteRegistry(c(reg_rows, 'A,B,TRUE,copies,1e-6,,confirmed,,"again",2026-10-03')), labels))
Expect(Has(e, 'duplicate edge'), 'stops on a duplicate edge')

cat('DependencyClosure() and RelatedPairs()\n')
cl <- DependencyClosure(deps)
a_anc <- cl[cl$label == 'A', ]
Expect(setequal(a_anc$ancestor, c('B', 'C')) && a_anc$hops[a_anc$ancestor == 'C'] == 2,
       'A has ancestors B (1 hop) and C (2 hops)')
Expect(!any(cl$label == 'P'), 'provenance_only edges are not in the closure')
Expect(cl$tol_log10[cl$label == 'D' & cl$ancestor == 'C'] == 0.0105,
       'D -> C takes the loosest route (through R, 0.0105) over the direct 1e-6 edge')
rel <- RelatedPairs(cl)
Expect(rel$tol_log10[rel$a == 'A' & rel$b == 'R'] == 0.0105, 'A and R are siblings through C with tolerance 0.0105')
Expect(rel$tol_log10[rel$a == 'S1' & rel$b == 'S2'] == 1e-6, 'S1 and S2 are siblings through the external parent')
Expect(!any(rel$a == 'A' & rel$b == 'S1'), 'unrelated labels are not paired')

cat('SignificantDigits() and IdenticalToSF()\n')
Expect(identical(SignificantDigits(c(1234, 1230, 1200, 1000, 0.00123, 123000.5)), c(4L, 3L, 2L, 1L, 3L, 7L)),
       'significant digits counted without trailing zeros')
Expect(identical(IdenticalToSF(c(1234, 1234, 1200, 1234.5678, 999.99, 0.001234),
                               c(1230, 1236, 1200, 1230, 1000, 0.00123)),
                 c(TRUE, FALSE, FALSE, TRUE, FALSE, TRUE)),
       '1234~1230 and 1234.5678~1230 identical; 1234/1236, 1200/1200 (round) and 999.99/1000 not')

cat('DedupeSources() on synthetic values\n')
ws <- data.frame(
  genus = 'G',
  species = c('G sp1', 'G sp1',                     # exact copy B of C
              'G sp2', 'G sp2',                     # near copy R of C (within 0.0105, not identical to 3 s.f.)
              'G sp3', 'G sp3',                     # R outside tolerance
              'G sp3b', 'G sp3b',                   # B differs from C by 4e-4 log10: kept
              'G sp4', 'G sp4',                     # provenance_only P identical to C, round number
              'G sp5', 'G sp5', 'G sp5',            # chain A = B = C
              'G sp6', 'G sp6', 'G sp6',            # A = B, C differs
              'G sp7', 'G sp7',                     # A = C with B absent (transitive)
              'G sp8', 'G sp8',                     # blind: X 1234 vs Y 1230
              'G sp9', 'G sp9',                     # blind excluded: round 1200
              'G sp10', 'G sp10',                   # blind: 1234 vs 1236 not identical
              'G sp11', 'G sp11',                   # siblings S1 = S2
              'G sp12', 'G sp12',                   # siblings differ
              'G sp13',                             # single source
              'G sp14', 'G sp14',                   # provenance_only P identical to C, not a round number (#31)
              'G sp15', 'G sp15', 'G sp15',         # chain: R ~ C by registry (0.0105), X ~ C by the blind rule, R and X differ (#31)
              'G sp16', 'G sp16', 'G sp16'),        # provenance_only P joined to C only through R (#31)
  source_label = c('B', 'C', 'C', 'R', 'C', 'R', 'B', 'C', 'C', 'P', 'A', 'B', 'C', 'A', 'B', 'C', 'A', 'C',
                   'X', 'Y', 'X', 'Y', 'X', 'Y', 'S1', 'S2', 'S1', 'S2', 'X',
                   'C', 'P', 'C', 'R', 'X', 'C', 'R', 'P'),
  mass_g = c(100.5, 100.5, 1234.5, 1250, 1000, 1100, 1001, 1000, 500, 500, 42.42, 42.42, 42.42,
             42.42, 42.42, 50, 42.42, 42.42, 1234, 1230, 1200, 1200, 1234, 1236, 77.7, 77.7, 77.7, 77.9, 3.3,
             500.5, 500.5, 1234.5, 1246, 1230, 1240, 1234.4, 1234),
  stringsAsFactors = FALSE)
dd <- DedupeSources(ws, deps)
v  <- dd$values
Row <- function(sp, lab) v[v$species == sp & v$source_label == lab, ]
Expect(identical(names(v)[seq_along(names(ws))], names(ws)) &&
         all(c('independent', 'collapsed_into', 'dedupe_rule') %in% names(v)) && nrow(v) == nrow(ws),
       'values keep the input columns and gain independent, collapsed_into, dedupe_rule')
Expect(!Row('G sp1', 'B')$independent && Row('G sp1', 'B')$collapsed_into == 'C' &&
         Row('G sp1', 'B')$dedupe_rule == 'registry' && Row('G sp1', 'C')$independent,
       'exact copy: B collapsed into C by the registry, C kept')
Expect(!Row('G sp2', 'R')$independent && Row('G sp2', 'R')$collapsed_into == 'C' &&
         Row('G sp2', 'R')$dedupe_rule == 'registry',
       'near copy within 0.0105 collapsed into its parent (registry, not blind)')
Expect(Row('G sp3', 'R')$independent && Row('G sp3', 'C')$independent, 'near copy outside the tolerance kept')
Expect(Row('G sp3b', 'B')$independent && Row('G sp3b', 'C')$independent,
       'copies edge (1e-6) does not collapse values 4e-4 log10 apart')
Expect(Row('G sp4', 'P')$independent && Row('G sp4', 'C')$independent,
       'provenance_only edge: identical round values (500, two significant digits) are not collapsed')
Expect(Row('G sp5', 'A')$collapsed_into == 'C' && Row('G sp5', 'B')$collapsed_into == 'C' &&
         Row('G sp5', 'C')$independent,
       'chain A = B = C collapses into the root C')
Expect(Row('G sp6', 'A')$collapsed_into == 'B' && Row('G sp6', 'B')$independent && Row('G sp6', 'C')$independent,
       'A = B with a different C: A into B, C kept')
Expect(Row('G sp7', 'A')$collapsed_into == 'C', 'transitive: A collapses into C when B is absent')
Expect(!Row('G sp8', 'Y')$independent && Row('G sp8', 'Y')$collapsed_into == 'X' &&
         Row('G sp8', 'Y')$dedupe_rule == 'blind' && Row('G sp8', 'X')$independent,
       'blind rule: 1234 vs 1230 collapsed (3 s.f.), first label kept')
Expect(Row('G sp9', 'X')$independent && Row('G sp9', 'Y')$independent, 'blind rule skips the round number 1200')
Expect(Row('G sp10', 'X')$independent && Row('G sp10', 'Y')$independent, 'blind rule leaves 1234 vs 1236 alone')
Expect(!Row('G sp11', 'S2')$independent && Row('G sp11', 'S2')$collapsed_into == 'S1',
       'siblings of an external parent collapse into the lower priority label')
Expect(Row('G sp12', 'S1')$independent && Row('G sp12', 'S2')$independent, 'siblings that differ are both kept')
Expect(Row('G sp13', 'X')$independent && is.na(Row('G sp13', 'X')$collapsed_into), 'single-source species untouched')
# ---- #31 (resolution B): the blind rule applies to provenance_only pairs too,
# such collapses are labelled, and component coalescing may chain values that
# do not match each other.
Expect(!Row('G sp14', 'P')$independent && Row('G sp14', 'P')$collapsed_into == 'C' &&
         Row('G sp14', 'P')$dedupe_rule == 'blind (provenance_only edge)',
       '#31: identical non-round values 500.5 on a provenance_only edge are collapsed and labelled blind (provenance_only edge)')
Expect(!Row('G sp15', 'R')$independent && Row('G sp15', 'R')$collapsed_into == 'C' && Row('G sp15', 'R')$dedupe_rule == 'registry' &&
         !Row('G sp15', 'X')$independent && Row('G sp15', 'X')$collapsed_into == 'C' && Row('G sp15', 'X')$dedupe_rule == 'blind' &&
         Row('G sp15', 'C')$independent,
       '#31: R (registry, 0.0105) and X (blind) both collapse into C although R = 1246 and X = 1230 do not match each other')
Expect(!Row('G sp16', 'P')$independent && Row('G sp16', 'P')$collapsed_into == 'C' &&
         Row('G sp16', 'P')$dedupe_rule == 'blind (via third source)',
       '#31: provenance_only P = 1234 reaches C = 1240 through R = 1234.4 (blind with P, registry with C), collapsed and labelled blind (via third source)')
Expect(Row('G sp1', 'B')$dedupe_rule == 'registry' && Row('G sp8', 'Y')$dedupe_rule == 'blind',
       '#31: values without a provenance_only partner keep the plain registry / blind labels')
Expect(sum(dd$pairs$prov_only) == 3 && all(dd$pairs$species_key[dd$pairs$prov_only] %in% c('G G sp4', 'G G sp14', 'G G sp16')),
       'pairs table flags the three provenance_only pairs (sp4, sp14, sp16)')
keep_per_species <- tapply(v$independent, v$species, sum)
Expect(all(keep_per_species >= 1), 'every species keeps at least one independent value')
ok_ref <- all(vapply(which(!v$independent), function(i)
  any(v$independent & v$species == v$species[i] & v$source_label == v$collapsed_into[i]), logical(1)))
Expect(ok_ref, 'collapsed_into always names an independent value of the same species')
Expect(all(c('species_key', 'd', 'exact', 'reg_tol', 'registry', 'blind') %in% names(dd$pairs)) &&
         nrow(dd$pairs) == 24, 'pairs table has one row per within-species pair (24)')

e <- ErrorOf(DedupeSources(rbind(ws, ws[1, ]), deps))
Expect(Has(e, 'more than one value per species and source label'), 'stops on duplicated species x label rows')

cat('SourceLabel() and SourceGroup()\n')
Expect(identical(SourceLabel(c('Kendall_etal_2019; Studier_1992', ' AnAge ', NA)), c('Kendall_etal_2019', 'AnAge', NA)),
       'SourceLabel() takes the first token of source_mass')
Expect(identical(SourceGroup(c('vertnet-aves-sept2016', 'vertnet-traits-sept2016', 'Tobias_2022')),
                 c('vertnet', 'vertnet', 'Tobias_2022')),
       'SourceGroup() pools the VertNet dumps and leaves other labels alone')

cat('WriteDedupeReport()\n')
rep_file <- tempfile('dedupe_', fileext = '.md')
rep <- WriteDedupeReport(dd, deps, rep_file, min_residual = 1)
txt <- readLines(rep_file)
Expect(any(grepl('^## Totals', txt)) && any(grepl('^## Registry edges', txt)) &&
         any(grepl('^## Siblings sharing an external parent', txt)) &&
         any(grepl('^## Provenance-only edges', txt)) && any(grepl('^## Residual identical pairs', txt)),
       'report has its five sections')
Expect(rep$edges$collapsed_into_parent[rep$edges$child == 'B' & rep$edges$parent == 'C'] == 2 &&
         rep$edges$shared[rep$edges$child == 'B' & rep$edges$parent == 'C'] == 4,
       'edge table counts shared species and collapses for B -> C')
Expect(rep$siblings$collapsed[rep$siblings$pair == 'S1 - S2'] == 1, 'sibling table counts the S1 - S2 collapse')
pc <- rep$provenance_only[rep$provenance_only$child == 'P' & rep$provenance_only$parent == 'C', ]
Expect(nrow(pc) == 1 && pc$shared == 3 && pc$blind_identical == 1 && pc$collapsed_blind_direct == 1 && pc$collapsed_via_third_source == 1,
       '#31: provenance-only table counts the P - C pairs (3 shared, 1 blind-identical, 1 direct and 1 via-third-source collapse)')
Expect(rep$totals$value[grepl('blind \\(provenance_only edge\\)', rep$totals$quantity)] == 1 &&
         rep$totals$value[grepl('via third source', rep$totals$quantity)] == 1 &&
         rep$totals$value[rep$totals$quantity == 'values collapsed by the blind rule only'] == 4,
       '#31: totals count the labelled collapses (1 + 1) within the 4 blind-only collapses (sp8, sp14, sp15, sp16)')
Expect(any(rep$residual$pair == 'X - Y') && rep$residual$identical_but_round[rep$residual$pair == 'X - Y'] == 1,
       'residual table lists X - Y with its round-number identical pair')
Expect(rep$totals$value[rep$totals$quantity == 'values collapsed (total)'] == sum(!v$independent),
       'totals agree with the values')

cat(sprintf('\n%d expectations, %d failed\n', n_checks, length(failures)))
if (length(failures) > 0) {
  cat(paste0('  FAIL: ', failures, '\n'), sep = '')
  quit(status = 1)
}
