# Tests for R/library/exclude_discordant.r (issue #34, the record-level range
# rule): the tiers, the evidence groups, every step of the cascade on
# synthetic Pass-1 values (a unique leave-one-out culprit, near-copies that
# must not outvote one value, the tier and distance tie-breaks, a tier-2
# maximum that never decides, a two-value pair of the same tier left
# unresolved, a continuum, copies excluded with their parent, the threshold
# boundary), the genus-only path, the outputs and the wiring in RunMe.r.
# Base R only, no network, no cached frames.
#
#   Rscript R/library/tests/test_exclude_discordant.R      (from any directory)
#
# Prints one line per expectation and exits with status 1 if any failed.

this_file <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE))
if (length(this_file) == 0)
  this_file <- file.path('R', 'library', 'tests', 'test_exclude_discordant.R')
repo <- normalizePath(file.path(dirname(this_file), '..', '..', '..'))
lib  <- file.path(repo, 'R', 'library')
source(file.path(lib, 'dedupe_sources.r'))
source(file.path(lib, 'exclude_discordant.r'))

failures <- character(0)
n_checks <- 0L
Expect <- function(ok, what) {
  n_checks <<- n_checks + 1L
  if (!isTRUE(ok)) failures <<- c(failures, what)
  cat(sprintf('  %s %s\n', if (isTRUE(ok)) 'ok  ' else 'FAIL', what))
}
ErrorOf <- function(expr) tryCatch({ expr; NULL }, error = function(e) conditionMessage(e))
Has <- function(x, pattern) !is.null(x) && grepl(pattern, x, fixed = TRUE)

# ---- fixtures -------------------------------------------------------------------------
# a registry of tiers: T1 handbooks (Hand1, Hand2, Hand3), the related pair
# Copy1 ~ Copy2 (T1, both derived from the same external compilation),
# T2 maxima (Max1, Max2), T3 specimens (Spec1, Spec2) and T3 web data (Web1, Web2)
classes <- data.frame(
  source_label = c('Hand1', 'Hand2', 'Hand3', 'Copy1', 'Copy2', 'Max1', 'Max2', 'Spec1', 'Spec2', 'Web1', 'Web2', 'vertnet-aves-sept2016', 'vertnet-traits-sept2016'),
  value_tier   = c(1L, 1L, 1L, 1L, 1L, 2L, 2L, 3L, 3L, 3L, 3L, 3L, 3L), stringsAsFactors = FALSE)
related <- data.frame(a = c('Copy1', 'Web1'), b = c('Copy2', 'Web2'), tol_log10 = 1e-6, kind = 'sibling', stringsAsFactors = FALSE)

V <- function(species, label, mass, n = 1L, independent = TRUE, collapsed_into = NA_character_, source_mass = label, origin = 'pipeline')
  data.frame(genus = sub(' .*$', '', species), species = species, taxon = gsub(' ', '_', species), source_label = label,
             source_group = SourceGroup(label), source_mass = source_mass, origin = origin, mass_g = mass, n = as.integer(n),
             independent = independent, collapsed_into = collapsed_into, stringsAsFactors = FALSE)
ws <- rbind(
  # 1. unique leave-one-out culprit (Pipistrellus pattern): a VertNet value 3.6 log10 above four agreeing handbooks
  V('Pip kuh', 'Hand1', 5.5), V('Pip kuh', 'Hand2', 5.9), V('Pip kuh', 'Hand3', 6.3), V('Pip kuh', 'Spec1', 6.9), V('Pip kuh', 'vertnet-aves-sept2016+vertnet-traits-sept2016', 26872, n = 2, source_mass = 'vertnet-aves-sept2016; vertnet-traits-sept2016'),
  # 2. Keratella pattern: two related web values (one evidence group) against one handbook value -> rule D excludes the T3 group
  V('Ker tes', 'Web1', 1.07e-8, n = 63), V('Ker tes', 'Web2', 1.23e-8, n = 20), V('Ker tes', 'Hand1', 1.98e-6),
  # 3. related T1 near-copies against one T1 value: unique LOO culprit but the kept side is one group of the same tier -> unresolved
  V('One grp', 'Copy1', 14.4), V('One grp', 'Copy2', 18.8), V('One grp', 'Hand1', 379),
  # 4. tier tie-break: Hand1 in the middle, Spec1 low and Hand2 high both resolve -> the T3 goes
  V('Tie tier', 'Spec1', 1), V('Tie tier', 'Hand1', 7), V('Tie tier', 'Hand2', 40),
  # 5. distance tie-break: same tiers, Hand1 and Hand3 both resolve, Hand1 is farther from the median of the others
  V('Tie dist', 'Hand1', 1), V('Tie dist', 'Hand2', 5), V('Tie dist', 'Hand3', 20),
  # 6. a T2 maximum never decides: candidates Spec1 (T3) and Max1 (T2) with no T1 candidate -> distance, and the maximum is farther
  V('Max tie', 'Spec1', 20), V('Max tie', 'Hand1', 42), V('Max tie', 'Max1', 400),
  # 7. a T2 maximum never decides, rule D: Spec1 (T3) against Max1 (T2) stays unresolved
  V('Max two', 'Spec1', 24), V('Max two', 'Max1', 2200),
  # 8. two values, tiers differ: T3 excluded (Helix pattern, low outlier), and the same with the T3 high
  V('Hel pom', 'Spec1', 0.1), V('Hel pom', 'Hand1', 29),
  V('Cin asi', 'Hand1', 8.1), V('Cin asi', 'vertnet-aves-sept2016', 2.3e9),
  # 9. two values, same tier: unresolved
  V('Aeq eig', 'Web1', 0.023, n = 37), V('Aeq eig', 'Spec2', 3.97, n = 2),
  # 10. a continuum: no single value resolves it
  V('Aur aur', 'Spec1', 0.14, n = 95), V('Aur aur', 'Hand1', 1.96), V('Aur aur', 'Spec2', 2.1), V('Aur aur', 'Web1', 5.1), V('Aur aur', 'Hand2', 62), V('Aur aur', 'Web2', 271),
  # 11. copies go with their parent: Max2 collapsed into Max1, Max1 the culprit (T2 against two T1 values)
  V('Cop par', 'Hand1', 10), V('Cop par', 'Hand2', 12), V('Cop par', 'Max1', 300), V('Cop par', 'Max2', 300, independent = FALSE, collapsed_into = 'Max1'),
  # 12. a converted value is tier 3 whatever its source: Hand3 with a conversion CiteID against Hand1
  V('Con ver', 'Hand1', 100), V('Con ver', 'Hand3', 2, source_mass = 'Hand3; Brey_2010'),
  # 13. within the threshold: untouched (exactly 1 log10)
  V('Fine ok', 'Hand1', 1), V('Fine ok', 'Spec1', 10),
  # 14. just over the threshold: two values, T3 excluded
  V('Edge ok', 'Hand1', 1), V('Edge ok', 'Spec1', 10.0001),
  # 15. a lab-Sheet species with two cited sources (labels unknown to the registry, tier 1): same tier, unresolved
  V('She et', 'Froese_2025', 1, origin = 'BM_data'), V('She et', 'Doe_1999', 50, origin = 'BM_data'),
  # 16. a single value: untouched
  V('Sin gle', 'Spec1', 3))

# ---- tiers and groups -------------------------------------------------------------------
cat('ValueTier(), EvidenceGroups()\n')
Expect(identical(ValueTier(c('Hand1', 'Max1', 'Spec1', 'vertnet-aves-sept2016+vertnet-traits-sept2016', 'Froese_2025'),
                           c('Hand1', 'Max1', 'Spec1', 'vertnet-aves-sept2016; vertnet-traits-sept2016', 'Froese_2025; Doe_1999'),
                           c('pipeline', 'pipeline', 'pipeline', 'pipeline', 'BM_data'), classes), c(1L, 2L, 3L, 3L, 1L)),
       'tiers by label: 1, 2, 3, pooled VertNet labels 3, an unregistered Sheet citation 1 (a Sheet row citing two sources is not a conversion)')
Expect(identical(ValueTier(c('Hand1', 'Max1'), c('Hand1; Brey_2010', 'Max1; Kiorboe_2013'), c('pipeline', 'pipeline'), classes), c(3L, 3L)),
       'a conversion CiteID after the label makes the value tier 3')
Expect(Has(ErrorOf(ValueTier('Hand1', 'Hand1', 'pipeline', classes[, 'source_label', drop = FALSE])), 'value_tier'),
       'a registry without value_tier stops')
g <- EvidenceGroups(c('Hand1', 'Copy1', 'Web1', 'Copy2', 'Web2', 'Hand2'), related)
Expect(length(unique(g)) == 4 && g[2] == g[4] && g[3] == g[5] && g[1] != g[6] && g[1] != g[2],
       'related labels share a group, the others are their own groups')
Expect(identical(EvidenceGroups(c('A', 'B'), NULL), 1:2) && identical(EvidenceGroups('A', related), 1L), 'no relations or one label: one group each')

# ---- the cascade ----------------------------------------------------------------------------
cat('ExcludeDiscordantValues()\n')
res <- ExcludeDiscordantValues(ws, related, classes, threshold = 1)
v <- res$values; ex <- res$exclusions; un <- res$unresolved
Excl <- function(sp) v$source_label[v$species == sp & v$excluded]
Rule <- function(sp) unique(v$exclusion_rule[v$species == sp & v$excluded])
Reason <- function(sp) un$reason[un$species == sp]
Expect(nrow(v) == nrow(ws) && all(c('value_tier', 'excluded', 'exclusion_rule', 'exclusion_distance', 'record_status') %in% names(v)) &&
         identical(v$source_label, ws$source_label),
       'the values come back in order with the new columns')
Expect(identical(Excl('Pip kuh'), 'vertnet-aves-sept2016+vertnet-traits-sept2016') && Rule('Pip kuh') == 'loo_unique' &&
         abs(v$exclusion_distance[v$species == 'Pip kuh' & v$excluded] - (log10(26872) - median(log10(c(5.5, 5.9, 6.3, 6.9))))) < 1e-12,
       'Pipistrellus: the one value whose exclusion brings the rest within 1 log10 is excluded (loo_unique), distance from the median of the kept values')
Expect(setequal(Excl('Ker tes'), c('Web1', 'Web2')) && Rule('Ker tes') == 'two_value_tier',
       'Keratella: two related web values are one evidence group and cannot outvote the handbook value; rule D excludes the T3 group')
Expect(length(Excl('One grp')) == 0 && Reason('One grp') == 'one_group',
       'two related T1 near-copies against one T1 value: the kept side is a single group of the same tier, unresolved (one_group)')
Expect(identical(Excl('Tie tier'), 'Spec1') && Rule('Tie tier') == 'tier_tiebreak',
       'two candidates of different tiers: the lowest trust goes (tier_tiebreak)')
Expect(identical(Excl('Tie dist'), 'Hand1') && Rule('Tie dist') == 'distance_tiebreak',
       'two candidates of the same tier: the farthest from the median of the others goes (distance_tiebreak)')
Expect(identical(Excl('Max tie'), 'Max1') && Rule('Max tie') == 'distance_tiebreak',
       'a T2 maximum never outranks a T3 candidate: without a T1 candidate the tie falls to the distance (here the maximum goes)')
Expect(length(Excl('Max two')) == 0 && Reason('Max two') == 'maximum_cannot_decide',
       'rule D: a T2 maximum against a T3 specimen decides nothing (maximum_cannot_decide)')
Expect(identical(Excl('Hel pom'), 'Spec1') && identical(Excl('Cin asi'), 'vertnet-aves-sept2016') &&
         Rule('Hel pom') == 'two_value_tier' && Rule('Cin asi') == 'two_value_tier' &&
         v$exclusion_distance[v$species == 'Hel pom' & v$excluded] < 0 && v$exclusion_distance[v$species == 'Cin asi' & v$excluded] > 0,
       'two values of different tiers: the T3 goes whether it is the low or the high one (direction-blind), the distance keeps the sign')
Expect(length(Excl('Aeq eig')) == 0 && Reason('Aeq eig') == 'same_tier', 'two values of the same tier stay unresolved (same_tier)')
Expect(length(Excl('Aur aur')) == 0 && Reason('Aur aur') == 'no_single_culprit' && un$n_independent[un$species == 'Aur aur'] == 6,
       'a continuum: no single value resolves it (no_single_culprit)')
Expect(setequal(Excl('Cop par'), c('Max1', 'Max2')) && Rule('Cop par') == 'loo_unique' &&
         ex$copy_of[ex$species == 'Cop par' & ex$source_label == 'Max2'] == 'Max1' && is.na(ex$copy_of[ex$species == 'Cop par' & ex$source_label == 'Max1']) &&
         v$exclusion_distance[v$species == 'Cop par' & v$source_label == 'Max2'] == v$exclusion_distance[v$species == 'Cop par' & v$source_label == 'Max1'],
       'a copy collapsed into the excluded value is excluded with it, named as its copy, with its rule and distance')
Expect(identical(Excl('Con ver'), 'Hand3') && v$value_tier[v$species == 'Con ver' & v$source_label == 'Hand3'] == 3L,
       'a converted value of a tier-1 source is tier 3 and goes in rule D')
Expect(length(Excl('Fine ok')) == 0 && !'Fine ok' %in% un$species && length(Excl('Sin gle')) == 0 && !'Sin gle' %in% un$species,
       'a species exactly at the threshold and a single-value species are untouched and not listed')
Expect(identical(Excl('Edge ok'), 'Spec1'), 'a species just over the threshold is judged')
Expect(length(Excl('She et')) == 0 && Reason('She et') == 'same_tier', 'lab-Sheet citations are tier 1: same tier, unresolved')
Expect(all(v$record_status[v$excluded] == paste0('excluded_', v$exclusion_rule[v$excluded])) && all(v$record_status[!v$excluded] == 'kept') &&
         all(v$record_status %in% record_statuses),
       'record_status is kept or excluded_<rule>')
Expect(identical(names(ex), c('genus', 'species', 'taxon', 'source_label', 'source_mass', 'mass_g', 'n', 'value_tier', 'rule', 'distance_log10',
                              'copy_of', 'n_kept', 'single_value_rescue', 'kept_mass_g', 'kept_values')) &&
         nrow(ex) == 12 && sum(is.na(ex$copy_of)) == 11 &&
         ex$n_kept[ex$species == 'Pip kuh'] == 4 && abs(ex$kept_mass_g[ex$species == 'Pip kuh'] - mean(c(5.5, 5.9, 6.3, 6.9))) < 1e-12 &&
         ex$kept_values[ex$species == 'Pip kuh'] == 'Hand1 5.5 g (n 1, T1); Hand2 5.9 g (n 1, T1); Hand3 6.3 g (n 1, T1); Spec1 6.9 g (n 1, T3)',
       'the exclusion table: 12 rows (11 independent values, 1 copy), the kept values beside each with the new mean')
Expect(identical(ex$species, sort(ex$species, method = 'radix')) && all(diff(order(ex$genus, ex$species, method = 'radix')) >= 0),
       'the exclusion table is ordered by genus and species in byte order')
Expect(is.logical(ex$single_value_rescue) && setequal(unique(ex$species[ex$single_value_rescue]), c('Ker tes', 'Hel pom', 'Cin asi', 'Con ver', 'Edge ok')) &&
         !any(ex$single_value_rescue[ex$species %in% c('Pip kuh', 'Cop par', 'Tie tier')]) && res$counts$species_single_value == 5,
       'single_value_rescue marks the species left with one kept value (the two-value rescues and the Keratella group case), counted in the counts')
Expect(res$counts$species_flagged == 15 && res$counts$species_rescued == 10 && res$counts$species_unresolved == 5 &&
         res$counts$values_excluded_independent == 11 && res$counts$values_excluded_copies == 1 &&
         identical(as.integer(res$counts$by_rule[c('loo_unique', 'tier_tiebreak', 'distance_tiebreak', 'two_value_tier')]), c(2L, 1L, 2L, 6L)) &&
         identical(as.integer(res$counts$species_by_rule[c('loo_unique', 'tier_tiebreak', 'distance_tiebreak', 'two_value_tier')]), c(2L, 1L, 2L, 5L)) &&
         identical(as.integer(res$counts$unresolved_by_reason[c('same_tier', 'maximum_cannot_decide', 'one_group', 'no_single_culprit')]), c(2L, 1L, 1L, 1L)),
       'the counts: 15 species over the threshold, 10 rescued by 11 values (loo 2, tier 1, distance 2, two-value 6 in 5 species), 5 unresolved')
Expect(Has(ErrorOf(ExcludeDiscordantValues(ws[, setdiff(names(ws), 'collapsed_into')], related, classes)), 'lacks column'),
       'a frame without the de-duplication columns stops')
res2 <- ExcludeDiscordantValues(ws, related, classes, threshold = 2)
Expect(res2$counts$species_flagged == 6 && !any(res2$values$excluded[res2$values$species == 'Tie tier']),
       'the threshold is a parameter: at 2 log10 fewer species are over it')
res3 <- ExcludeDiscordantValues(ws, NULL, classes)
Expect(identical(res3$values$source_label[res3$values$species == 'Ker tes' & res3$values$excluded], 'Hand1') &&
         res3$values$exclusion_rule[res3$values$species == 'Ker tes' & res3$values$excluded] == 'loo_unique',
       'without the registry relations the Keratella handbook value is outvoted (the refinement is what prevents it)')
# Pass 2 on the result as RunMe.r computes it
in_mean <- v$independent & !v$excluded
Expect(all(tapply(log10(v$mass_g[in_mean]), v$species[in_mean], function(x) if (length(x) > 1) diff(range(x)) else 0)[unique(ex$species)] <= 1) &&
         all(tapply(log10(v$mass_g[in_mean]), v$species[in_mean], function(x) if (length(x) > 1) diff(range(x)) else 0)[un$species] > 1),
       'after the exclusions every rescued species spans <= 1 log10 and every unresolved one still more')

# ---- the genus-only path -------------------------------------------------------------------
cat('ExcludeDiscordantGenusRecords()\n')
records <- data.frame(genus = c('Lagopus', 'Lithobius', 'Ara', 'Aus', 'Bus', 'Cus'),
                      mass_g = c(31, 4.5e-4, 5, 20, 3, 100), n = c(2L, 1L, 1L, 1L, 1L, 1L), n_sources = 1L, n_independent = 1L,
                      source_mass = c('vertnet-aves-sept2016', 'Web1', 'Spec1', 'Max1', 'Hand1', 'Hand1'), source_label = c('vertnet-aves-sept2016', 'Web1', 'Spec1', 'Max1', 'Hand1', 'Hand1'),
                      log10_range = 0, source_dependencies = NA, taxon_provided = NA, kingdom = NA, phylum = NA, class = NA, order = NA, family = NA,
                      stringsAsFactors = FALSE)
values <- data.frame(genus = records$genus, source_label = records$source_label, source_mass = records$source_mass, independent = TRUE, stringsAsFactors = FALSE)
enriched <- data.frame(genus = c('Lagopus', 'Lagopus', 'Lagopus', 'Lithobius', 'Ara', 'Aus', 'Bus', 'Dus'),
                       species = c('Lagopus a', 'Lagopus b', 'Lagopus c', 'Lithobius a', 'Ara a', 'Aus a', 'Bus a', 'Dus a'),
                       mass_g = c(480, 520, 640, 1.25e-2, 1000, 2000, 150, 1), stringsAsFactors = FALSE)
species_tiers <- data.frame(genus = enriched$genus, species = enriched$species, tier = c(1L, 1L, 1L, 1L, 2L, 1L, 3L, 1L), stringsAsFactors = FALSE)
gr <- ExcludeDiscordantGenusRecords(records, values, enriched, species_tiers, classes)
St <- function(g) gr$records$record_status[gr$records$genus == g]
Expect(St('Lagopus') == 'excluded_genus_only_discordant' && gr$exclusions$n_species[gr$exclusions$genus == 'Lagopus'] == 3 &&
         abs(gr$exclusions$distance_log10[gr$exclusions$genus == 'Lagopus'] - (log10(31) - log10(520))) < 1e-12,
       'a record more than 1 log10 from the median of three species is excluded (genus_only_discordant), distance from the median')
Expect(St('Lithobius') == 'excluded_two_value_tier',
       'against a single species: a T3 record 1.4 log10 off is excluded by the two-value tier rule')
Expect(St('Ara') == 'kept' && gr$unresolved$reason[gr$unresolved$genus == 'Ara'] == 'maximum_cannot_decide',
       'a T3 record against a single species whose only value is a T2 maximum: the maximum cannot decide, the record is kept and listed')
Expect(St('Aus') == 'excluded_two_value_tier', 'a T2 record against a single T1 species value: the record is excluded')
Expect(St('Bus') == 'kept' && gr$unresolved$reason[gr$unresolved$genus == 'Bus'] == 'same_tier' &&
         gr$unresolved$species_values[gr$unresolved$genus == 'Bus'] == 'Bus a 150 g',
       'a T1 record against a single T3 species value: the species is never the excluded side, the record is kept and listed')
Expect(St('Cus') == 'kept' && !'Cus' %in% gr$unresolved$genus && is.na(gr$records$distance_log10[gr$records$genus == 'Cus']),
       'a genus without species values is untouched')
Expect(gr$counts$records_excluded == 3 && gr$counts$records_unresolved == 2 && identical(as.integer(gr$counts$by_rule[c('genus_only_discordant', 'two_value_tier')]), c(1L, 2L)),
       'the genus counts')
gr0 <- ExcludeDiscordantGenusRecords(records[0, ], values[0, ], enriched, species_tiers, classes)
Expect(nrow(gr0$records) == 0 && nrow(gr0$exclusions) == 0 && 'record_status' %in% names(gr0$records), 'no records: empty results with the columns')

# ---- GenusLevelTable() with excluded records --------------------------------------------------
cat('GenusLevelTable() and record_status\n')
source(file.path(lib, 'enrich_genus.r'))
gt <- GenusLevelTable(enriched[, c('genus', 'species', 'mass_g')] |> transform(n = 1L, n_independent = 1L, source_mass = 'Hand9'), gr$records)
Expect(abs(gt$mass_g[gt$taxon == 'Lagopus'] - mean(c(480, 520, 640))) < 1e-9 && gt$n[gt$taxon == 'Lagopus'] == 3 && gt$n_independent[gt$taxon == 'Lagopus'] == 3 &&
         grepl('vertnet-aves-sept2016', gt$source_mass[gt$taxon == 'Lagopus'], fixed = TRUE),
       'an excluded genus-only record leaves the genus mean, n and n_independent but stays in source_mass')
Expect(abs(gt$mass_g[gt$taxon == 'Bus'] - mean(c(150, 3))) < 1e-9 && gt$n[gt$taxon == 'Bus'] == 2, 'a kept (unresolved) record enters the mean as before')
Expect(!'Cus' %in% gt$taxon == FALSE && 'Cus' %in% gt$taxon, 'a genus with only a kept genus-only record has its row')
rec_only <- gr$records[gr$records$genus == 'Lagopus', ]
Expect(!'Lagopus' %in% GenusLevelTable(enriched[0, ] |> transform(n = integer(), n_independent = integer(), source_mass = character()), rec_only)$taxon,
       'a genus whose only contributor is an excluded record has no row')

# ---- outputs -------------------------------------------------------------------------------
cat('WriteExcludedRecords(), ExclusionRegisterRows()\n')
f <- tempfile(fileext = '.csv')
WriteExcludedRecords(f, res, gr)
csv <- read.csv(f, stringsAsFactors = FALSE)
Expect(identical(names(csv), c('level', 'genus', 'species', 'taxon', 'source_label', 'source_mass', 'mass_g', 'n', 'value_tier', 'rule', 'distance_log10',
                               'copy_of', 'n_kept', 'single_value_rescue', 'kept_mass_g', 'kept_values')) &&
         sum(csv$single_value_rescue & csv$level == 'species') == 6 && sum(csv$single_value_rescue & csv$level == 'genus') == 2 &&
         sum(csv$level == 'species') == 12 && sum(csv$level == 'genus') == 3 && all(csv$rule %in% exclusion_rules),
       'reports/excluded_records.csv: the species rows then the genus rows, one per excluded value')
f2 <- tempfile(fileext = '.csv'); WriteExcludedRecords(f2, res, gr)
Expect(identical(readLines(f), readLines(f2)), 'the CSV carries no timestamp: two writes are identical')
u <- ws[!duplicated(ws$species), ]
taxa <- data.frame(genus = u$genus, species = u$species, kingdom = 'Animalia', phylum = 'P', class = 'C', order = 'O', family = 'F',
                   gbif_confidence = 99, stringsAsFactors = FALSE)
rows <- ExclusionRegisterRows(ex, taxa, 'range_rule_2026-10-06')
Expect(nrow(rows) == 11 && identical(names(rows), c('taxon', 'mass_g', 'source_mass', 'n', 'kingdom', 'phylum', 'taxon_class', 'order', 'family', 'genus', 'species',
                                                   'confidence', 'form', 'subspecies', 'variety', 'log10_mass', 'log10_pred', 'residual', 'abs_residual',
                                                   'class_outlier', 'severity', 'method', 'note')) &&
         all(rows$method == 'range_rule_2026-10-06') && all(abs(rows$log10_mass - rows$log10_pred - rows$residual) < 1e-12) &&
         rows$severity[rows$taxon == 'Pip_kuh'] == 'CRITICAL' && rows$severity[rows$taxon == 'Tie_tier'] == 'SUSPICIOUS' &&
         grepl('Collapsed copies excluded with it: Max2', rows$note[rows$taxon == 'Cop_par'], fixed = TRUE) &&
         grepl('converted', rows$note[rows$taxon == 'Con_ver'], fixed = TRUE),
       'the register rows: one per independent excluded value, the register columns, severity by distance, copies and conversions in the note')
sv <- SingleValueRescueRows(ex, taxa, 'range_rule_2026-10-06')
Expect(nrow(sv) == 5 && identical(names(sv), names(rows)) && all(sv$severity == 'SUSPICIOUS') && all(sv$method == 'range_rule_2026-10-06') &&
         sv$source_mass[sv$taxon == 'Ker_tes'] == 'Hand1' && sv$mass_g[sv$taxon == 'Ker_tes'] == 1.98e-6 && sv$n[sv$taxon == 'Ker_tes'] == 1 &&
         abs(sv$log10_pred[sv$taxon == 'Ker_tes'] - log10(1.07e-8)) < 1e-12 &&
         all(startsWith(sv$note, 'Record-level range rule (#34): rescued species rests on one kept value; review.')) &&
         grepl('Web1 1.07e-08 g (n 63, T3); Web2 1.23e-08 g (n 20, T3)', sv$note[sv$taxon == 'Ker_tes'], fixed = TRUE) &&
         sv$source_mass[sv$taxon == 'Hel_pom'] == 'Hand1' && abs(sv$residual[sv$taxon == 'Hel_pom'] - log10(29 / 0.1)) < 1e-12,
       'the single-value rows: one per such species, the kept value and label as the record, log10_pred the excluded value, both excluded values of a group in the note')
Expect(is.null(SingleValueRescueRows(ex[!ex$single_value_rescue, ], taxa, 'x')), 'no single-value rescues: NULL')

# ---- wiring in RunMe.r ------------------------------------------------------------------------
cat('R/RunMe.r wiring\n')
runme <- readLines(file.path(repo, 'R', 'RunMe.r'))
i_src  <- grep("^source\\(file\\.path\\(wd_root, 'R', 'library', 'exclude_discordant\\.r'\\)\\)", runme)
i_dd   <- grep('^dedupe        <- DedupeSources\\(within_source, source_deps\\)', runme)
i_ex   <- grep('^excl          <- ExcludeDiscordantValues\\(within_source, dedupe\\$related, prov_classes, threshold = 1\\)', runme)
i_asg  <- grep('^within_source <- excl\\$values', runme)
i_p2   <- grep('^enriched <- within_source %>%', runme)
i_ce   <- grep('unresolved = unresolved_names, exclusions = excl\\)', runme)
i_filt <- grep('remove_high_range_taxa\\(enriched, threshold = 1\\)', runme)
i_gex  <- grep('^genus_excl    <- ExcludeDiscordantGenusRecords\\(genus_records, genus_values, enriched, species_tiers, prov_classes, threshold = 1\\)', runme)
i_gasg <- grep('^genus_records <- genus_excl\\$records', runme)
i_csv  <- grep("^WriteExcludedRecords\\(file\\.path\\(wd_root, 'reports', 'excluded_records\\.csv'\\), excl, genus_excl\\)", runme)
i_tab  <- grep('^gdat <- GenusLevelTable\\(enriched, genus_records\\)', runme)
i_rep  <- grep('deps = source_deps, exclusions = genus_excl\\)', runme)
Expect(all(lengths(list(i_src, i_dd, i_ex, i_asg, i_p2, i_ce, i_filt, i_gex, i_gasg, i_csv, i_tab, i_rep)) == 1) &&
         i_dd < i_ex && i_ex < i_asg && i_asg < i_p2 && i_p2 < i_ce && i_ce < i_filt && i_filt < i_gex && i_gex < i_gasg && i_gasg < i_csv && i_csv < i_tab && i_tab < i_rep,
       'ExcludeDiscordantValues() runs after DedupeSources() and before Pass 2; the genus records are judged after the range filter and before GenusLevelTable(); the CSV and the genus report follow')
p2 <- runme[i_p2:(i_p2 + 30)]
Expect(any(grepl('^    log10_range     = if \\(sum\\(independent & !excluded\\) > 1\\)', p2)) &&
         any(grepl('^    mass_g          = mean\\(mass_g\\[independent & !excluded\\], na\\.rm = TRUE\\)', p2)) &&
         any(grepl('^    n_independent   = sum\\(independent & !excluded\\),', p2)) &&
         any(grepl('^    n_excluded      = sum\\(excluded\\),', p2)) &&
         any(grepl("^    sources_excluded = if \\(any\\(excluded\\)\\)", p2)) &&
         any(grepl("paste\\(paste0\\(source_label\\[excluded\\], '<', exclusion_rule\\[excluded\\]\\), collapse = '; '\\)", p2)),
       'Pass 2 averages, ranges and counts the values in the mean and writes n_excluded and sources_excluded as label<rule')
Expect(any(grepl('nValuesExcluded     = n_values_excluded', runme)) && any(grepl('nSpeciesRescued     = n_species_rescued', runme)),
       'the numbers_db.tex macros nValuesExcluded and nSpeciesRescued are written')
readme <- readLines(file.path(repo, 'README.md'))
Expect(any(grepl('`n_excluded`', readme)) && any(grepl('`sources_excluded`', readme)) && any(grepl('`record_status`', readme)) &&
         any(grepl('excluded_records\\.csv', readme)) && any(grepl('exclude_discordant\\.r', readme)),
       'README documents the new columns, the live CSV and the module')

cat(sprintf('\n%d expectations, %d failed\n', n_checks, length(failures)))
if (length(failures) > 0) {
  cat(paste0('  FAIL: ', failures, '\n'), sep = '')
  quit(status = 1)
}
