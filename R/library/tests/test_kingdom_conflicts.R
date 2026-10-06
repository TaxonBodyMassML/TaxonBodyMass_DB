# Tests for the cross-kingdom conflict rule of R/library/fix_taxonomy_ranks.r
# (Part 2b, issue #81) and the Part 7 overwrites it works with. An authority
# that matched a name to a plant, alga or fungus while the source's lower
# ranks are an animal's (an exact homonym in two kingdoms, Myrmecia
# pyriformis; a GBIF fuzzy match into the other kingdom, Parus humilis ->
# Cotoneaster humilis) used to leave the row to FilterAutotrophs(), which
# dropped it on the kingdom alone and unreported. The rule keeps the animal's
# ranks, records the authority's kingdom in `kingdom_conflict`, keeps the
# species only in the homonym case and clears it otherwise (the name is then
# unresolved and listed as such); Part 7 overwrites that set the kingdom also
# clear the GBIF match fields. No network access and no packages beyond base R
# are needed.
#
#   Rscript R/library/tests/test_kingdom_conflicts.R      (from any directory)
#
# Prints one line per expectation and exits with status 1 if any failed.

this_file <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE))
if (length(this_file) == 0)         # sourced interactively from the repo root
  this_file <- file.path('R', 'library', 'tests', 'test_kingdom_conflicts.R')
repo <- normalizePath(file.path(dirname(this_file), '..', '..', '..'))
lib  <- file.path(repo, 'R', 'library')
source(file.path(lib, 'fix_taxonomy_ranks.r'))
source(file.path(lib, 'filter_autotrophs.r'))

failures <- character(0)
n_checks <- 0L
Expect <- function(ok, what) {
  n_checks <<- n_checks + 1L
  if (!isTRUE(ok)) failures <<- c(failures, what)
  cat(sprintf('  %s %s\n', if (isTRUE(ok)) 'ok  ' else 'FAIL', what))
}

# A cache-like frame: the columns of sources/enrich_cache.Rdata, with the
# conflict rows as the cache held them on main f9f16ac (2026-10-05) and
# anchors that make the data-driven animal ranks (orders and families, and the
# majority rule for classes) work as they do on the real cache.
Row <- function(taxon, species, kingdom, phylum, class, order, family, genus,
                source = 'GBIF', conf = 99L, status = 'ACCEPTED', gfam = NA, gord = NA, changed = FALSE)
  data.frame(taxon = taxon, kingdom = kingdom, phylum = phylum, class = class, order = order,
             family = family, taxon_provided = gsub('_', ' ', taxon), species_changed = changed,
             taxonomy_source = source, genus = genus, species = species,
             gbif_confidence = as.integer(conf), gbif_status = status, gbif_family = gfam, gbif_order = gord,
             gbif_usageKey = if (is.na(conf)) NA_character_ else '1', stringsAsFactors = FALSE)
cache <- rbind(
  # anchors
  Row('Myrmecia_gulosa',    'Myrmecia gulosa',    'Animalia', 'Arthropoda',   'Insecta',        'Hymenoptera',   'Formicidae',    'Myrmecia'),
  Row('Anurida_maritima',   'Anurida maritima',   'Animalia', 'Arthropoda',   'Collembola',     'Poduromorpha',  'Neanuridae',    'Anurida'),
  Row('Rusa_unicolor',      'Rusa unicolor',      'Animalia', 'Chordata',     'Mammalia',       'Artiodactyla',  'Cervidae',      'Rusa'),
  Row('Rusa_timorensis',    'Rusa timorensis',    'Animalia', 'Chordata',     'Mammalia',       'Artiodactyla',  'Cervidae',      'Rusa'),
  Row('Cervus_elaphus',     'Cervus elaphus',     'Animalia', 'Chordata',     'Mammalia',       'Artiodactyla',  'Cervidae',      'Cervus'),
  Row('Notesthes_robusta',  'Notesthes robusta',  'Animalia', 'Chordata',     'Actinopterygii', 'Scorpaeniformes', 'Tetrarogidae', 'Notesthes'),
  Row('Calamaria_lumbricoidea', 'Calamaria lumbricoidea', 'Animalia', 'Chordata', 'Reptilia',  'Squamata',      'Colubridae',    'Calamaria'),
  # genuine plants, a fungus and an alga (dropped by FilterAutotrophs(), untouched here)
  Row('Camelia_japonica',   'Camellia japonica',  'Plantae',  'Tracheophyta', 'Magnoliopsida',  'Ericales',      'Theaceae',      'Camellia', conf = 80L),
  Row('Lycopodium_annotium', 'Spinulum annotinum', 'Plantae', 'Tracheophyta', 'Lycopodiopsida', 'Lycopodiales',  'Lycopodiaceae', 'Spinulum', conf = 94L, status = 'SYNONYM'),
  Row('Asterina_gibbosa',   'Asterina gibbosa',   'Fungi',    'Ascomycota',   'Dothideomycetes', 'Asterinales',  'Asterinaceae',  'Asterina', source = 'NCBI'),
  Row('Ulva_lactuca',       'Ulva lactuca',       'Plantae',  'Chlorophyta',  'Ulvophyceae',    'Ulvales',       'Ulvaceae',      'Ulva'),
  Row('Lobelia_cardinalis', 'Lobelia cardinalis', 'Plantae',  'Tracheophyta', 'Magnoliopsida',  'Asterales',     'Campanulaceae', 'Lobelia'),
  Row('Rosa_canina',        'Rosa canina',        'Plantae',  'Tracheophyta', 'Magnoliopsida',  'Rosales',       'Rosaceae',      'Rosa'),
  # a snake with a plant class written by a source (Part 2 noise)
  Row('Calamaria_muelleri', 'Calamaria muelleri', 'Animalia', 'Chordata',     'Lycopodiopsida', 'Squamata',      'Colubridae',    'Calamaria', source = 'NCBI', conf = 100L, status = NA),
  # the conflict rows
  Row('Myrmecia_pyriformis', 'Myrmecia pyriformis (in: green algae)', 'Viridiplantae', 'Arthropoda', 'Insecta', 'Hymenoptera', 'Formicidae', 'Myrmecia',
      source = 'NCBI', conf = 100L, status = NA, changed = TRUE),
  Row('Parus_humilis',      'Cotoneaster humilis', 'Plantae', 'Tracheophyta', 'Aves',          'Passeriformes', 'Paridae',       'Cotoneaster',
      conf = 81L, status = 'SYNONYM', gfam = 'Rosaceae', gord = 'Rosales', changed = TRUE),
  Row('Rusa_nana',          'Rosa nana',          'Plantae',  'Tracheophyta', 'Magnoliopsida',  'Artiodactyla',  'Cervidae',      'Rosa',
      conf = 81L, status = 'SYNONYM', gfam = 'Rosaceae', gord = 'Rosales', changed = TRUE),
  # a future homonym with no Part 7 entry: the same binomial in both kingdoms,
  # the source's class and family, NCBI's phylum and order
  Row('Testus_homonymus',   'Testus homonymus (in: eudicots)', 'Viridiplantae', 'Streptophyta', 'Insecta', 'Asterales', 'Formicidae', 'Testus',
      source = 'NCBI', conf = 100L, status = NA, changed = TRUE),
  # a future fuzzy match with no Part 7 entry
  Row('Testus_fuzzyus',     'Testum fuzzyum',     'Plantae',  'Tracheophyta', 'Mammalia',       'Rosales',       'Cervidae',      'Testum',
      conf = 82L, status = 'ACCEPTED', gfam = 'Rosaceae', gord = 'Rosales', changed = TRUE),
  # a cross-kingdom Part 7 entry of before #81 whose GBIF fields describe the wrong organism
  Row('Trypanosoma_lewisi', 'Trypanosoma lewisi', 'Protozoa', 'Euglenozoa',   'Kinetoplastea',  'Trypanosomatida', 'Trypanosomatidae', 'Trypanosoma',
      source = 'manual', conf = 84L, status = 'SYNONYM', gfam = 'Pleuroceridae'),
  stringsAsFactors = FALSE)
out <- FixTaxonomyRanks(cache)
R <- function(tx) out[out$taxon == tx, ]
Same <- function(tx, cols = c('species', 'genus', 'kingdom', 'phylum', 'class', 'order', 'family', 'taxonomy_source'))
  identical(out[out$taxon == tx, cols], cache[cache$taxon == tx, cols])

cat('the rule: which rows it touches\n')
Expect('kingdom_conflict' %in% names(out), 'FixTaxonomyRanks() adds the kingdom_conflict column to a frame with a species column')
Expect(identical(sort(out$taxon[!is.na(out$kingdom_conflict)]),
                 sort(c('Myrmecia_pyriformis', 'Parus_humilis', 'Rusa_nana', 'Testus_homonymus', 'Testus_fuzzyus'))),
       'exactly the five rows with a plant kingdom over animal ranks are flagged')
Expect(all(vapply(c('Camelia_japonica', 'Lycopodium_annotium', 'Asterina_gibbosa', 'Ulva_lactuca', 'Lobelia_cardinalis', 'Rosa_canina'), Same, logical(1))),
       'genuine plants, a fungus and an alga are untouched (the majority rule: Lycopodiopsida is no animal class though a snake carries it)')
Expect(nrow(FilterAutotrophs(out[out$taxon %in% c('Camelia_japonica', 'Lycopodium_annotium', 'Asterina_gibbosa', 'Ulva_lactuca', 'Lobelia_cardinalis', 'Rosa_canina'), ])) == 0,
       'and they still leave through FilterAutotrophs()')
Expect(all(vapply(c('Myrmecia_gulosa', 'Anurida_maritima', 'Rusa_unicolor', 'Rusa_timorensis', 'Cervus_elaphus', 'Notesthes_robusta', 'Calamaria_lumbricoidea'), Same, logical(1))),
       'Animalia rows are untouched')
Expect(identical(R('Myrmecia_pyriformis')$kingdom_conflict, 'Viridiplantae') && identical(R('Parus_humilis')$kingdom_conflict, 'Plantae'),
       'kingdom_conflict records the kingdom the authority returned')

cat('the homonym case (same binomial in both kingdoms)\n')
h <- R('Testus_homonymus')
Expect(identical(h$kingdom, 'Animalia') && identical(h$species, 'Testus homonymus') && identical(h$genus, 'Testus'),
       "kingdom becomes Animalia and NCBI's '(in: eudicots)' annotation is stripped from the species")
Expect(is.na(h$phylum) && is.na(h$order) && identical(h$class, 'Insecta') && identical(h$family, 'Formicidae'),
       "the plant phylum and order (Streptophyta; Asterales, seen under Plantae in the frame) are cleared for rank inference; the source's class and family stay")
Expect(identical(h$taxonomy_source, 'NCBI') && isFALSE(h$species_changed), 'the source stays NCBI and the name is not a name change')
Expect(nrow(FilterAutotrophs(h)) == 1, 'the row survives FilterAutotrophs()')

cat('the fuzzy case (another genus from the other kingdom)\n')
f <- R('Testus_fuzzyus')
Expect(is.na(f$species) && is.na(f$genus) && is.na(f$taxonomy_source),
       'species, genus and taxonomy_source are cleared: the name is unresolved and will be listed as such')
Expect(identical(f$kingdom, 'Animalia') && is.na(f$phylum) && identical(f$class, 'Mammalia') && is.na(f$order) && identical(f$family, 'Cervidae'),
       "kingdom Animalia, the source's class and family kept, the plant phylum and order cleared")
Expect(identical(f$gbif_confidence, 82L) && identical(f$gbif_family, 'Rosaceae'),
       'the GBIF match fields are left as evidence of what happened')
r <- R('Rusa_nana')
Expect(is.na(r$species) && identical(r$kingdom, 'Animalia') && identical(r$order, 'Artiodactyla') && identical(r$family, 'Cervidae') &&
       is.na(r$class) && is.na(r$phylum),
       'Rusa_nana (Smith_2003; GBIF fuzzy to Rosa nana) is unresolved with the MOM order and family kept')

cat('the Part 7 entries of #81\n')
m <- R('Myrmecia_pyriformis')
Expect(identical(unlist(m[c('species', 'genus', 'kingdom', 'phylum', 'class', 'order', 'family', 'taxonomy_source')], use.names = FALSE),
                 c('Myrmecia pyriformis', 'Myrmecia', 'Animalia', 'Arthropoda', 'Insecta', 'Hymenoptera', 'Formicidae', 'manual')),
       'Myrmecia_pyriformis is the bull ant, taxonomy_source manual')
Expect(isFALSE(m$species_changed) && is.na(m$gbif_confidence) && is.na(m$gbif_status) && is.na(m$gbif_usageKey),
       'its name is unchanged and the GBIF match fields are cleared')
p <- R('Parus_humilis')
Expect(identical(unlist(p[c('species', 'genus', 'kingdom', 'phylum', 'class', 'order', 'family', 'taxonomy_source')], use.names = FALSE),
                 c('Pseudopodoces humilis', 'Pseudopodoces', 'Animalia', 'Chordata', 'Aves', 'Passeriformes', 'Paridae', 'manual')),
       'Parus_humilis is the ground tit under its accepted name')
Expect(isTRUE(p$species_changed) && is.na(p$gbif_family) && is.na(p$gbif_order) && is.na(p$gbif_confidence) && is.na(p$gbif_status),
       'the name change is recorded and the Rosaceae/Rosales GBIF fields are cleared (Pass 1 prefers gbif_family/gbif_order)')
Expect(nrow(FilterAutotrophs(out[out$taxon %in% c('Myrmecia_pyriformis', 'Parus_humilis'), ])) == 2,
       'both rows survive FilterAutotrophs()')
t <- R('Trypanosoma_lewisi')
Expect(is.na(t$gbif_family) && is.na(t$gbif_confidence) && is.na(t$gbif_status) && identical(t$family, 'Trypanosomatidae'),
       'the older cross-kingdom entry Trypanosoma_lewisi loses its gastropod GBIF fields (Pleuroceridae) too')
Expect(identical(class(out$gbif_confidence), 'integer') && identical(class(out$species_changed), 'logical'),
       'clearing keeps the column types')

cat('Part 2 noise and frames without a species column\n')
Expect(is.na(R('Calamaria_muelleri')$class) && identical(R('Calamaria_muelleri')$kingdom, 'Animalia') && is.na(R('Calamaria_muelleri')$kingdom_conflict),
       'a plant class on an Animalia record (Calamaria muelleri, Lycopodiopsida) is cleared by Part 2 and is no conflict')
src <- data.frame(taxon = c('Myrmecia_pyriformis', 'Parus_humilis', 'Camelia_japonica'), mass_g = 1:3, n = 1, source_mass = 'SrcA',
                  kingdom = c('Viridiplantae', 'Plantae', 'Plantae'), phylum = c('Arthropoda', 'Tracheophyta', 'Tracheophyta'),
                  class = c('Insecta', 'Aves', 'Magnoliopsida'), order = c('Hymenoptera', 'Passeriformes', 'Ericales'),
                  family = c('Formicidae', 'Paridae', 'Theaceae'), stringsAsFactors = FALSE)
src_out <- FixTaxonomyRanks(src)
Expect(!'kingdom_conflict' %in% names(src_out) && identical(src_out$kingdom[3], 'Plantae') && identical(src_out$class[3], 'Magnoliopsida'),
       'a per-source frame (no species column) gets no column and Part 2b leaves it alone (Camelia keeps its plant ranks)')
Expect(identical(src_out$kingdom[1:2], c('Animalia', 'Animalia')) && identical(src_out$family[2], 'Paridae') && !'species' %in% names(src_out),
       'Part 7 writes only the columns present (kingdom to family) on a per-source frame, as before')
# second run: idempotent on the corrected frame
out2 <- FixTaxonomyRanks(out)
Expect(identical(out2, out), 'a second application changes nothing (the correction is persisted in the cache)')

cat(sprintf('\n%d checks, %d failed\n', n_checks, length(failures)))
if (length(failures) > 0) { cat(paste('  -', failures), sep = '\n'); quit(status = 1) }
