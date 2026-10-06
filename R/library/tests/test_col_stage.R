# Tests for stage 4 of R/library/enrich_taxonomy.r, the Catalogue of Life
# (ChecklistBank) name match (issue #103). Until #103 the stage called
# nidx/match, which answers only {nidx, matched}, so it never resolved a name.
# ParseColMatch() and ColStage() run here on recorded responses of
# GET api.checklistbank.org/dataset/3LR/match/nameusage?q=<name>
# (R/library/tests/fixtures/col/, fetched 2026-10-06): an accepted species
# matched as a variant (Prionchulus muscorum), a synonym whose classification
# starts with the accepted species (Felis concolor -> Puma concolor), a
# misspelt epithet COL answers with the genus only (higherrank) and an unknown
# name (none). No network access; jsonlite reads the fixtures.
#
#   Rscript R/library/tests/test_col_stage.R      (from any directory)
#
# Prints one line per expectation and exits with status 1 if any failed.

this_file <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE))
if (length(this_file) == 0)         # sourced interactively from the repo root
  this_file <- file.path('R', 'library', 'tests', 'test_col_stage.R')
repo <- normalizePath(file.path(dirname(this_file), '..', '..', '..'))
lib  <- file.path(repo, 'R', 'library')
source(file.path(lib, 'enrich_taxonomy.r'))
source(file.path(lib, 'fix_taxonomy_ranks.r'))
fixtures <- file.path(lib, 'tests', 'fixtures', 'col')

failures <- character(0)
n_checks <- 0L
Expect <- function(ok, what) {
  n_checks <<- n_checks + 1L
  if (!isTRUE(ok)) failures <<- c(failures, what)
  cat(sprintf('  %s %s\n', if (isTRUE(ok)) 'ok  ' else 'FAIL', what))
}

# The recorded responses, keyed by the query name, read as httr2::resp_body_json() returns them (nested lists)
recorded <- list(
  'Prionchulus muscorum' = 'prionchulus_muscorum_variant_accepted.json',
  'Felis concolor'       = 'felis_concolor_variant_synonym.json',
  'Prionchulus muscorom' = 'prionchulus_muscorom_higherrank.json',
  'Xyzzy abcde'          = 'xyzzy_abcde_none.json')
ReadFixture <- function(name) {
  if (!name %in% names(recorded)) stop('no recorded response for ', name)
  jsonlite::fromJSON(file.path(fixtures, recorded[[name]]), simplifyVector = FALSE)
}
calls <- character(0)
FetchRecorded <- function(name) { calls <<- c(calls, name); ReadFixture(name) }

cat('ParseColMatch(): the response mapping\n')
p <- ParseColMatch(ReadFixture('Prionchulus muscorum'))
Expect(identical(p$match_type, 'variant') && identical(p$status, 'accepted') && identical(p$usageKey, 'BC766') &&
       identical(p$matched_name, 'Prionchulus muscorum'),
       'an accepted species: type variant (a bare binomial has no authorship), status accepted, usage id BC766')
Expect(identical(p$species, 'Prionchulus muscorum'), 'the accepted species is the usage name')
Expect(identical(unname(p$ranks), c('Animalia', 'Nematoda', 'Enoplea', 'Mononchida', 'Mononchidae', 'Prionchulus')),
       'kingdom..genus are read from the classification (the sub- and super-ranks are skipped)')

p <- ParseColMatch(ReadFixture('Felis concolor'))
Expect(identical(p$match_type, 'variant') && identical(p$status, 'synonym') && identical(p$matched_name, 'Felis concolor') &&
       identical(p$usageKey, '3DXV5'),
       'a synonym: status synonym, the matched name is the synonym')
Expect(identical(p$species, 'Puma concolor') && identical(p$ranks[['genus']], 'Puma') && identical(p$ranks[['family']], 'Felidae'),
       'the species and genus are the accepted ones from the classification (Felis concolor -> Puma concolor)')

p <- ParseColMatch(ReadFixture('Prionchulus muscorom'))
Expect(identical(p$match_type, 'higherrank') && identical(p$status, 'accepted') && identical(p$matched_name, 'Prionchulus') &&
       identical(p$usageKey, '87JZG'),
       'a misspelt epithet: COL answers higherrank with the genus as usage; the answer is recorded')
Expect(is.na(p$species) && all(is.na(p$ranks)), 'but nothing is resolved from it')

p <- ParseColMatch(ReadFixture('Xyzzy abcde'))
Expect(identical(p$match_type, 'none') && is.na(p$status) && is.na(p$usageKey) && is.na(p$matched_name) && is.na(p$species),
       'an unknown name: type none, no usage, nothing resolved')
Expect(is.na(ParseColMatch(NULL)$species) && is.na(ParseColMatch(list())$match_type), 'an empty or missing body resolves nothing')

# statuses and types that must not resolve, built from the accepted fixture
body <- ReadFixture('Prionchulus muscorum')
Expect(all(vapply(c('ambiguous', 'unsupported', 'none'), function(t) { b <- body; b$type <- t; is.na(ParseColMatch(b)$species) }, logical(1))),
       'types ambiguous, unsupported and none resolve nothing')
Expect(all(vapply(c('misapplied', 'ambiguous synonym', 'bare name'), function(st) { b <- body; b$usage$status <- st; is.na(ParseColMatch(b)$species) }, logical(1))),
       'statuses misapplied, ambiguous synonym and bare name resolve nothing')
b <- body; b$type <- 'EXACT'; b$usage$status <- 'Provisionally accepted'
Expect(identical(ParseColMatch(b)$species, 'Prionchulus muscorum') && identical(ParseColMatch(b)$match_type, 'exact'),
       'exact and provisionally accepted resolve; the type and status are stored in lower case')
b <- body; b$usage$name <- 'Prionchulus (Subgenus) muscorum'
Expect(identical(ParseColMatch(b)$species, 'Prionchulus muscorum') && identical(ParseColMatch(b)$matched_name, 'Prionchulus (Subgenus) muscorum'),
       'a subgenus in brackets in the accepted name is dropped from the species (Dichotomius (Selenocopris) opacus of #85); the matched name keeps it')
b <- body; b$usage$rank <- 'subspecies'; b$usage$name <- 'Prionchulus muscorum alpinus'
Expect(is.na(ParseColMatch(b)$species), 'an accepted usage below species rank with no species in the classification resolves nothing')

cat('ColStage(): the row update\n')
Frame <- function(...) {
  d <- data.frame(..., stringsAsFactors = FALSE)
  d$taxon_provided <- gsub('_', ' ', d$taxon)
  d
}
compiled <- Frame(
  taxon           = c('Prionchulus_muscorum', 'Felis_concolor', 'Prionchulus_muscorom', 'Xyzzy_abcde', 'Homo_sapiens'),
  kingdom         = c('Animalia', NA, 'Animalia', NA, 'Animalia'),
  phylum          = c('Nematoda', NA, 'Nematoda', NA, 'Chordata'),
  class           = c(NA, NA, NA, NA, 'Mammalia'),
  order           = c('Mononchida', NA, 'Mononchida', NA, 'Primates'),
  family          = c('Mononchidae', 'Felidae', 'Mononchidae', NA, 'Hominidae'),
  genus           = c('Prionchulus', 'Felis', 'Prionchulus', NA, 'Homo'),
  species         = c(NA, NA, NA, NA, 'Homo sapiens'),
  species_changed = FALSE,
  taxonomy_source = c(NA, NA, NA, NA, 'GBIF'),
  gbif_confidence = c(94L, 94L, 94L, NA, 99L),
  gbif_status     = c('ACCEPTED', 'SYNONYM', 'ACCEPTED', NA, 'ACCEPTED'),
  gbif_family     = c('Mononchidae', 'Felidae', 'Mononchidae', NA, 'Hominidae'),
  gbif_order      = c('Mononchida', 'Carnivora', 'Mononchida', NA, 'Primates'),
  gbif_usageKey   = c('100', '200', '100', NA, '2436436'))
out <- ColStage(compiled, fetch = FetchRecorded, sleep = 0, progress = FALSE)
R <- function(tx) out[out$taxon == tx, ]

Expect(identical(calls, c('Prionchulus muscorum', 'Felis concolor', 'Prionchulus muscorom', 'Xyzzy abcde')),
       'only the rows without a species are queried, by their taxon_provided; a GBIF resolution is never offered to COL')
Expect(all(COL_COLUMNS %in% names(out)) && nrow(out) == nrow(compiled) &&
       identical(names(out)[seq_along(names(compiled))], names(compiled)),
       'the four col_* columns are added after the existing ones')
h <- R('Homo_sapiens')
Expect(identical(h$species, 'Homo sapiens') && identical(h$taxonomy_source, 'GBIF') && all(is.na(unlist(h[COL_COLUMNS]))) &&
       identical(h$gbif_family, 'Hominidae'),
       'the GBIF row is untouched (no override, #103 policy)')

p <- R('Prionchulus_muscorum')
Expect(identical(p$species, 'Prionchulus muscorum') && identical(p$taxonomy_source, 'COL') && isFALSE(p$species_changed) &&
       identical(p$genus, 'Prionchulus'),
       'Prionchulus muscorum is resolved, taxonomy_source COL, no name change')
Expect(identical(p$class, 'Enoplea') && identical(p$kingdom, 'Animalia') && identical(p$order, 'Mononchida'),
       'the missing class is filled from COL; the ranks already set are kept (NA-fill as in stages 2-6)')
Expect(identical(p$col_match_type, 'variant') && identical(p$col_status, 'accepted') && identical(p$col_usageKey, 'BC766') &&
       identical(p$col_matched_name, 'Prionchulus muscorum'),
       'the match type, status, usage key and matched name are recorded')
Expect(is.na(p$gbif_family) && is.na(p$gbif_order) && identical(p$gbif_confidence, 94L) && identical(p$gbif_status, 'ACCEPTED') &&
       identical(p$gbif_usageKey, '100'),
       "gbif_family and gbif_order (GBIF's higher-rank match, preferred by Pass 1) are cleared; confidence, status and key stay")

f <- R('Felis_concolor')
Expect(identical(f$species, 'Puma concolor') && identical(f$genus, 'Puma') && isTRUE(f$species_changed) && identical(f$taxonomy_source, 'COL'),
       'the synonym Felis concolor resolves to Puma concolor with genus Puma and species_changed TRUE')
Expect(identical(f$family, 'Felidae') && identical(f$order, 'Carnivora') && identical(f$class, 'Mammalia') && identical(f$kingdom, 'Animalia'),
       'its empty ranks are filled from the classification of the accepted species')
Expect(identical(f$col_status, 'synonym') && identical(f$col_matched_name, 'Felis concolor'),
       'the synonym status and the matched (synonym) name are recorded')

m <- R('Prionchulus_muscorom')
Expect(is.na(m$species) && is.na(m$taxonomy_source) && is.na(m$class) && identical(m$gbif_family, 'Mononchidae'),
       'the higherrank answer resolves nothing, fills nothing and leaves the GBIF fields alone')
Expect(identical(m$col_match_type, 'higherrank') && identical(m$col_matched_name, 'Prionchulus') && identical(m$col_usageKey, '87JZG'),
       'but the answer is recorded, so the cache shows the stage ran')
x <- R('Xyzzy_abcde')
Expect(identical(x$col_match_type, 'none') && is.na(x$col_status) && is.na(x$species) && is.na(x$kingdom),
       'an unknown name records type none and nothing else')

# a fetch that fails leaves the row as it was
out_err <- ColStage(compiled[1, ], fetch = function(name) stop('timeout'), sleep = 0, progress = FALSE)
Expect(is.na(out_err$species) && is.na(out_err$col_match_type) && identical(out_err$gbif_family, 'Mononchidae'),
       'a failed request leaves the row unchanged (it falls through to the next stage)')
# idempotent: a second pass queries only the rows still unresolved
calls <- character(0)
out2 <- ColStage(out, fetch = FetchRecorded, sleep = 0, progress = FALSE)
Expect(identical(calls, c('Prionchulus muscorom', 'Xyzzy abcde')) && identical(out2, out),
       'a second pass re-queries only the unresolved rows and changes nothing')
# explicit idx: rows with a species in idx are skipped
calls <- character(0)
invisible(ColStage(compiled, idx = c(5L, 2L), fetch = FetchRecorded, sleep = 0, progress = FALSE))
Expect(identical(calls, 'Felis concolor'), 'an explicit idx still skips rows with a species')

cat('the COL row through FixTaxonomyRanks()\n')
fx <- FixTaxonomyRanks(out)
Expect(identical(fx$species[fx$taxon == 'Felis_concolor'], 'Puma concolor') && identical(fx$taxonomy_source[fx$taxon == 'Felis_concolor'], 'COL') &&
       all(is.na(fx$kingdom_conflict)),
       'FixTaxonomyRanks() keeps the COL rows (Animalia, no conflict) and their source')

cat(sprintf('\n%d checks, %d failed\n', n_checks, length(failures)))
if (length(failures) > 0) { cat(paste('  -', failures), sep = '\n'); quit(status = 1) }
