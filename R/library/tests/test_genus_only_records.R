# Tests for the genus-only path of R/library/enrich_genus.r (#49): the
# resolution of bare names at genus rank on canned GBIF answers (cache hit,
# exact accepted genus, homonyms settled by the source's classification and by
# kingdom preference, synonyms followed to the accepted genus, names above
# genus, the curated list, the suffix rule, fuzzy matches accepted and
# rejected, unresolved names, caching), the autotroph filter on the resolved
# classification, the exclusion of higher-rank names, Pass 1 and
# de-duplication of the genus x source values, the pseudo-taxon and
# per-source weightings, the genus table, and the wiring in RunMe.r (the
# species path must stay untouched: TaxonBodyMass.csv is byte-identical to
# the run before #49). No network access and no packages beyond base R.
#
#   Rscript R/library/tests/test_genus_only_records.R      (from any directory)
#
# Prints one line per expectation and exits with status 1 if any failed.

this_file <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE))
if (length(this_file) == 0)         # sourced interactively from the repo root
  this_file <- file.path('R', 'library', 'tests', 'test_genus_only_records.R')
repo <- normalizePath(file.path(dirname(this_file), '..', '..', '..'))
lib  <- file.path(repo, 'R', 'library')
source(file.path(lib, 'helpers.r'))
source(file.path(lib, 'dedupe_sources.r'))
source(file.path(lib, 'filter_autotrophs.r'))
source(file.path(lib, 'enrich_genus.r'))

failures <- character(0)
n_checks <- 0L
Expect <- function(ok, what) {
  n_checks <<- n_checks + 1L
  if (!isTRUE(ok)) failures <<- c(failures, what)
  cat(sprintf('  %s %s\n', if (isTRUE(ok)) 'ok  ' else 'FAIL', what))
}
Has <- function(x, pattern) !is.null(x) && !is.na(x) && grepl(pattern, x, fixed = TRUE)

# ---- canned GBIF answers --------------------------------------------------------
# One usage row in the format of UsageRow(): the backbone exact-name lookup
# answers, the accepted usages synonyms point to, and the species/match
# answers for the names without an exact usage.
U <- function(key, name, rank, status, K, P, C, O = NA, F = NA, genus = NA, acceptedKey = NA, accepted = NA,
              matchType = 'EXACT', confidence = NA) {
  data.frame(key = key, canonicalName = name, rank = rank, status = status, matchType = matchType,
             confidence = confidence, kingdom = K, phylum = P, class = C, order = O, family = F,
             genus = genus, acceptedKey = acceptedKey, accepted = accepted, stringsAsFactors = FALSE)
}
lookup_answers <- list(
  Lagopus = rbind(
    U('2473369', 'Lagopus', 'GENUS', 'ACCEPTED', 'Animalia', 'Chordata', 'Aves', 'Galliformes', 'Phasianidae', 'Lagopus'),
    U('3233247', 'Lagopus', 'GENUS', 'HETEROTYPIC_SYNONYM', 'Plantae', 'Tracheophyta', 'Magnoliopsida', 'Fabales', 'Fabaceae', 'Trifolium', '2973363', 'Trifolium Tourn. ex L.'),
    U('6007644', 'Lagopus', 'GENUS', 'SYNONYM', 'Animalia', 'Arthropoda', 'Insecta', 'Lepidoptera', 'Noctuidae', 'Callopistria', '8875134', 'Callopistria Hubner')),
  Limonia = rbind(
    U('3190428', 'Limonia', 'GENUS', 'ACCEPTED', 'Plantae', 'Tracheophyta', 'Magnoliopsida', 'Sapindales', 'Rutaceae', 'Limonia'),
    U('1516824', 'Limonia', 'GENUS', 'ACCEPTED', 'Animalia', 'Arthropoda', 'Insecta', 'Diptera', 'Limoniidae', 'Limonia')),
  Myodes = rbind(
    U('2438546', 'Myodes', 'GENUS', 'ACCEPTED', 'Animalia', 'Chordata', 'Mammalia', 'Rodentia', 'Cricetidae', 'Myodes'),
    U('1046345', 'Myodes', 'GENUS', 'SYNONYM', 'Animalia', 'Arthropoda', 'Insecta', 'Coleoptera', 'Ripiphoridae', 'Ripiphorus', '1046300', 'Ripiphorus Bosc')),
  Dendroica = U('2487300', 'Dendroica', 'GENUS', 'SYNONYM', 'Animalia', 'Chordata', 'Aves', 'Passeriformes', 'Parulidae', 'Setophaga', '2487384', 'Setophaga Swainson, 1827'),
  Idothea = rbind(
    U('2769562', 'Idothea', 'GENUS', 'SYNONYM', 'Plantae', 'Tracheophyta', 'Liliopsida', 'Asparagales', 'Asparagaceae', 'Drimia', '2776527', 'Drimia Jacq. ex Willd.'),
    U('7859505', 'Idothea', 'GENUS', 'SYNONYM', 'Animalia', 'Mollusca', 'Bivalvia', 'Lucinida', 'Lucinidae', 'Fimbria', '2287583', 'Fimbria Megerle von Muhlfeld, 1811'),
    U('6785462', 'Idothea', 'GENUS', 'SYNONYM', 'Animalia', 'Arthropoda', 'Malacostraca', 'Isopoda', 'Idoteidae', 'Idotea', '2201390', 'Idotea Fabricius, 1798')),
  Staphylinidae = U('7854', 'Staphylinidae', 'FAMILY', 'ACCEPTED', 'Animalia', 'Arthropoda', 'Insecta', 'Coleoptera', 'Staphylinidae'),
  Coleoptera = rbind(
    U('10313671', 'Coleoptera', 'GENUS', 'DOUBTFUL', 'Plantae', 'Tracheophyta', 'Magnoliopsida', 'Malvales', 'Malvaceae', 'Coleoptera'),
    U('1470', 'Coleoptera', 'ORDER', 'ACCEPTED', 'Animalia', 'Arthropoda', 'Insecta', 'Coleoptera')),
  Oligochaeta = rbind(
    U('5401803', 'Oligochaeta', 'GENUS', 'ACCEPTED', 'Plantae', 'Tracheophyta', 'Magnoliopsida', 'Asterales', 'Asteraceae', 'Oligochaeta'),
    U('8166676', 'Oligochaeta', 'CLASS', 'SYNONYM', 'Animalia', 'Annelida', 'Clitellata', acceptedKey = '255', accepted = 'Clitellata')),
  Hebridae = U('4312', 'Hebridae', 'FAMILY', 'ACCEPTED', 'Animalia', 'Arthropoda', 'Insecta', 'Hemiptera', 'Hebridae'),
  Gomphonema = U('7499700', 'Gomphonema', 'GENUS', 'ACCEPTED', 'Chromista', 'Ochrophyta', 'Bacillariophyceae', 'Cymbellales', 'Gomphonemataceae', 'Gomphonema'),
  Hydrobiosis = rbind(
    U('8558036', 'Hydrobiosis', 'GENUS', 'DOUBTFUL', 'Animalia', 'Arthropoda', 'Insecta', 'Trichoptera', 'Hydrobiosidae', 'Hydrobiosis'),
    U('1434509', 'Hydrobiosis', 'GENUS', 'ACCEPTED', 'Animalia', 'Arthropoda', 'Insecta', 'Trichoptera', 'Hydrobiosidae', 'Hydrobiosis')),
  Zygoptera = U('9999999', 'Zygoptera', 'GENUS', 'DOUBTFUL', 'Protozoa', NA, NA, genus = 'Zygoptera'),
  Isopoda = rbind(
    U('643', 'Isopoda', 'ORDER', 'ACCEPTED', 'Animalia', 'Arthropoda', 'Malacostraca', 'Isopoda'),
    U('3253116', 'Isopoda', 'GENUS', 'SYNONYM', 'Animalia', 'Arthropoda', 'Arachnida', 'Araneae', 'Sparassidae', 'Isopeda', '2164000', 'Isopeda L.Koch, 1875')),
  Heteroptera = rbind(
    U('3248454', 'Heteroptera', 'GENUS', 'DOUBTFUL', 'Animalia', 'Arthropoda', 'Insecta', 'Hemiptera', 'Miridae', 'Heteroptera'),
    U('3264953', 'Heteroptera', 'GENUS', 'SYNONYM', 'Animalia', 'Arthropoda', 'Insecta', 'Diptera', 'Sphaeroceridae', 'Coproica', '1600000', 'Coproica Rondani, 1861')),
  Crustacea = U('10996236', 'Crustacea', 'GENUS', 'DOUBTFUL', 'Animalia', 'Arthropoda', 'Insecta', 'Hymenoptera', 'Apidae', 'Crustacea'),
  Phasianus = rbind(
    U('2473738', 'Phasianus', 'GENUS', 'ACCEPTED', 'Animalia', 'Chordata', 'Aves', 'Galliformes', 'Phasianidae', 'Phasianus'),
    U('3247049', 'Phasianus', 'GENUS', 'DOUBTFUL', 'Animalia', 'Mollusca', NA, genus = 'Phasianus')),
  Ensifera = U('2476000', 'Ensifera', 'GENUS', 'ACCEPTED', 'Animalia', 'Chordata', 'Aves', 'Apodiformes', 'Trochilidae', 'Ensifera'))
# the checklists' exact usages (stage 2b): one row per usage, rank and kingdom spellings as the checklists give them
CL <- function(name, ranks, kingdoms = 'Animalia')
  data.frame(key = seq_along(ranks), canonicalName = name, rank = ranks, status = 'ACCEPTED', matchType = 'EXACT', confidence = NA,
             kingdom = rep_len(kingdoms, length(ranks)), phylum = 'Arthropoda', class = NA, order = NA, family = NA, genus = NA,
             acceptedKey = NA, accepted = NA, stringsAsFactors = FALSE)
checklist_answers <- list(
  Zygoptera   = CL('Zygoptera', c(rep('SUBORDER', 15), rep('GENUS', 3), rep('ORDER', 2)), c(rep('Animalia', 14), 'Metazoa', 'Chromista', 'Protozoa', 'Animalia', 'Animalia', 'Animalia')),
  Heteroptera = CL('Heteroptera', c(rep('ORDER', 33), rep('SUBORDER', 21), rep('GENUS', 15), 'SERIES', 'SUBGENUS')),
  Crustacea   = CL('Crustacea', c(rep('CLASS', 26), rep('SUBPHYLUM', 25), rep('PHYLUM', 11), rep('GENUS', 5), 'ORDER'), c(rep('Metazoa', 2), rep('Animalia', 66))),
  Ensifera    = CL('Ensifera', c(rep('SUBORDER', 30), rep('GENUS', 6))),
  Dendroica   = CL('Dendroica', rep('GENUS', 40)),
  Lagopus     = CL('Lagopus', c(rep('GENUS', 65), 'SUBGENUS', 'SUBGENUS')),
  Lithobius   = CL('Lithobius', c(rep('GENUS', 185), rep('SUBGENUS', 14))),
  Idothea     = CL('Idothea', rep('GENUS', 8)),
  Myodes      = CL('Myodes', rep('GENUS', 30)),
  Limonia     = CL('Limonia', rep('GENUS', 50)),
  Hydrobiosis = CL('Hydrobiosis', rep('GENUS', 9)),
  Gomphonema  = CL('Gomphonema', rep('GENUS', 20), 'Chromista'),
  Phasianus   = CL('Phasianus', rep('GENUS', 40)),
  Stercocarius = NULL, Isolauctis = NULL, Brachyderinae = NULL, Lithobiusxxx = NULL, Xyzzyq = NULL, Renic = NULL,   # Brachyderinae: no checklist usage here, to exercise the suffix stage
  Euchrysia   = CL('Euchrysia', rep('GENUS', 3)))
usage_answers <- list(
  '2487384' = U('2487384', 'Setophaga', 'GENUS', 'ACCEPTED', 'Animalia', 'Chordata', 'Aves', 'Passeriformes', 'Parulidae', 'Setophaga'),
  '2201390' = U('2201390', 'Idotea', 'GENUS', 'ACCEPTED', 'Animalia', 'Arthropoda', 'Malacostraca', 'Isopoda', 'Idoteidae', 'Idotea'),
  '1046300' = U('1046300', 'Ripiphorus', 'GENUS', 'ACCEPTED', 'Animalia', 'Arthropoda', 'Insecta', 'Coleoptera', 'Ripiphoridae', 'Ripiphorus'),
  '2776527' = U('2776527', 'Drimia', 'GENUS', 'ACCEPTED', 'Plantae', 'Tracheophyta', 'Liliopsida', 'Asparagales', 'Asparagaceae', 'Drimia'))
match_answers <- list(
  Stercocarius = rbind(
    U('2481130', 'Stercorarius', 'GENUS', 'ACCEPTED', 'Animalia', 'Chordata', 'Aves', 'Charadriiformes', 'Stercorariidae', 'Stercorarius', matchType = 'FUZZY', confidence = 85),
    U('5219000', 'Stercorarius', 'SPECIES', 'ACCEPTED', 'Animalia', 'Chordata', 'Aves', 'Charadriiformes', 'Stercorariidae', 'Stercorarius', matchType = 'FUZZY', confidence = -31)),
  Oligochaeta = U('9268423', 'Oligachaeta', 'GENUS', 'SYNONYM', 'Animalia', 'Arthropoda', 'Insecta', 'Orthoptera', 'Gryllidae', matchType = 'FUZZY', confidence = 85),
  Hebridae = U('8000001', 'Hebridea', 'GENUS', 'ACCEPTED', 'Animalia', 'Arthropoda', 'Insecta', 'Orthoptera', 'Acrididae', 'Hebridea', matchType = 'FUZZY', confidence = 85),
  Lithobiusxxx = U('1017', 'Lithobius', 'GENUS', 'ACCEPTED', 'Animalia', 'Arthropoda', 'Chilopoda', 'Lithobiomorpha', 'Lithobiidae', 'Lithobius', matchType = 'FUZZY', confidence = 90),
  Xyzzyq = U('1018', 'Xyzzy', 'GENUS', 'ACCEPTED', 'Animalia', 'Arthropoda', 'Insecta', matchType = 'FUZZY', confidence = 70))
calls <- character(0)
mock_api <- list(
  lookup = function(name) { calls <<- c(calls, paste('lookup', name)); lookup_answers[[name]] },
  lookup_all = function(name) { calls <<- c(calls, paste('lookup_all', name)); checklist_answers[[name]] },
  match  = function(name, hints = NULL) { calls <<- c(calls, paste('match', name)); match_answers[[name]] },
  usage  = function(key) { calls <<- c(calls, paste('usage', key)); usage_answers[[as.character(key)]] })
# the species path's cache: resolved species whose accepted genera are Lithobius, Idotea, Myodes, Gomphonema
enrich_cache <- data.frame(
  taxon   = c('Lithobius_forficatus', 'Lithobius_mutabilis', 'Idotea_balthica', 'Myodes_glareolus', 'Gomphonema_parvulum', 'Nomen_dubium'),
  species = c('Lithobius forficatus', 'Lithobius mutabilis', 'Idotea balthica', 'Myodes glareolus', 'Gomphonema parvulum', NA),
  genus   = c('Lithobius', 'Lithobius', 'Idotea', 'Myodes', 'Gomphonema', NA),
  kingdom = c('Animalia', 'Animalia', 'Animalia', 'Animalia', 'Chromista', NA),
  phylum  = c('Arthropoda', 'Arthropoda', 'Arthropoda', 'Chordata', 'Ochrophyta', NA),
  class   = c('Chilopoda', 'Chilopoda', 'Malacostraca', 'Mammalia', 'Bacillariophyceae', NA),
  order   = c('Lithobiomorpha', 'Lithobiomorpha', 'Isopoda', 'Rodentia', 'Cymbellales', NA),
  family  = c('Lithobiidae', 'Lithobiidae', 'Idoteidae', 'Cricetidae', 'Gomphonemataceae', NA),
  stringsAsFactors = FALSE)

# genus-only rows as section 3 of RunMe.r splits them off (taxon, mass_g, n,
# source_mass, the frames' kingdom..family hints)
Rows <- function(taxon, mass, source, class = NA, order = NA, family = NA, kingdom = NA, phylum = NA)
  data.frame(taxon = taxon, mass_g = mass, n = 1, source_mass = source, kingdom = kingdom, phylum = phylum,
             class = class, order = order, family = family, stringsAsFactors = FALSE)
genus_only <- rbind(
  Rows('Lagopus', c(14.0, 70.8), 'vertnet-traits-sept2016', class = 'Aves', order = 'Galliformes', family = 'Phasianidae'),
  Rows('Lagopus', 500, 'vertnet-aves-sept2016', class = 'Aves', order = 'Galliformes', family = 'Phasianidae'),
  Rows('Lagopus', c(511.5, 598), 'Brose_etal_2018'),
  Rows('Lagopus', c(511.5, 598), 'Brose_2005'),
  Rows('Stercocarius', c(298, 391), 'Brose_etal_2018'),
  Rows('Lithobius', c(4.5e-4, 4.5e-4, 4.5e-4), 'Brose_etal_2018'),
  Rows('Limonia', 0.01, 'Brose_etal_2018'),
  Rows('Myodes', 18.1, 'vertnet-mammalia-sept2016', class = 'Insecta'),      # a deliberately contradicting hint
  Rows('Dendroica', 8, 'Brose_etal_2018'),
  Rows('Idothea', 0.05, 'Brose_etal_2018'),
  Rows('Staphylinidae', c(0.01, 0.012), 'Brose_etal_2018'),
  Rows('Staphylinidae', 0.011, 'Brose_2005'),
  Rows('Coleoptera', 0.02, 'Brose_etal_2018'),
  Rows('Oligochaeta', c(0.004, 0.003), 'Brose_etal_2018'),
  Rows('Hebridae', 0.001, 'Brose_etal_2018'),
  Rows('Gomphonema', 3.8e-9, 'Brose_etal_2018'),
  Rows('Hydrobiosis', 0.003, 'Brose_etal_2018'),
  Rows('Phasianus', 453.6, 'vertnet-traits-sept2016', class = 'Aves', order = 'unknown Order', family = 'Unidentified'),
  Rows('Isopoda', 0.03, 'Brose_etal_2018'),
  Rows('Heteroptera', c(0.003, 0.002), 'Brose_etal_2018'),
  Rows('Crustacea', 0.5, 'Brose_etal_2018'),
  Rows('Ensifera', c(0.05, 0.04), 'Brose_etal_2018'),
  Rows('Anisoptera', 0.24, 'Brose_etal_2018'),
  Rows('Zygoptera', 0.05, 'Brose_etal_2018'),
  Rows('Brachyderinae', 0.002, 'Brose_etal_2018'),
  Rows('Lithobiusxxx', 0.001, 'SrcA'),
  Rows('Xyzzyq', 0.001, 'SrcA'),
  Rows('Isolauctis', 0.001, 'Eklof_etal_2017'),
  Rows('Renic', 0.001, 'Brose_etal_2018'))

# ---- ChooseGenusUsage() -------------------------------------------------------
cat('ChooseGenusUsage()\n')
ch <- ChooseGenusUsage(lookup_answers$Lagopus, hints = c(kingdom = NA, phylum = NA, class = 'Aves', order = 'Galliformes', family = 'Phasianidae'))
Expect(ch$choice$key == '2473369' && Has(ch$note, 'settled by the source classification'),
       'Lagopus with class Aves: the bird genus, note says the source classification settled the homonym')
ch <- ChooseGenusUsage(lookup_answers$Lagopus)
Expect(ch$choice$key == '2473369' && Has(ch$note, 'homonym across kingdoms') && Has(ch$note, 'Animalia preferred'),
       'Lagopus without hints: Animalia preferred over the plant synonyms, ACCEPTED over the noctuid synonym; flagged')
ch <- ChooseGenusUsage(lookup_answers$Limonia)
Expect(ch$choice$family == 'Limoniidae' && Has(ch$note, 'Animalia preferred'),
       'Limonia: two accepted genera, the animal one by kingdom preference')
ch <- ChooseGenusUsage(lookup_answers$Coleoptera)
Expect(ch$choice$rank == 'ORDER', 'Coleoptera: the beetle order (Animalia) beats the doubtful plant genus')
ch <- ChooseGenusUsage(lookup_answers$Oligochaeta)
Expect(ch$choice$rank == 'CLASS', 'Oligochaeta: the annelid class (a synonym of Clitellata) beats the accepted plant genus')
ch <- ChooseGenusUsage(lookup_answers$Hydrobiosis)
Expect(ch$choice$status == 'ACCEPTED' && !Has(ch$note, 'DOUBTFUL') && !ch$weak, 'Hydrobiosis: the accepted usage over the doubtful one, no flag')
ch <- ChooseGenusUsage(lookup_answers$Isopoda)
Expect(ch$choice$rank == 'ORDER' && !ch$weak, 'Isopoda: the accepted order beats the synonym spider genus Isopeda')
ch <- ChooseGenusUsage(lookup_answers$Heteroptera)
Expect(ch$choice$status == 'SYNONYM' && ch$weak, 'Heteroptera: only a synonym and doubtful genera in the backbone: the synonym, flagged weak')
ch <- ChooseGenusUsage(lookup_answers$Crustacea)
Expect(ch$choice$status == 'DOUBTFUL' && ch$weak && Has(ch$note, 'DOUBTFUL'), 'Crustacea: a doubtful genus only, flagged weak')
ch <- ChooseGenusUsage(lookup_answers$Phasianus, hints = c(kingdom = NA, phylum = NA, class = 'Aves', order = NA, family = NA))
Expect(ch$choice$key == '2473738', 'Phasianus with class Aves: the accepted bird genus (the doubtful mollusc has no class to contradict)')
Expect(identical(CleanHint(c('Aves', 'unknown Order', 'Unidentified', 'Phasianidae Tetraoninae', '', NA, 'n/a', 'not a name')),
                 c('Aves', NA, NA, 'Phasianidae', NA, NA, NA, NA)),
       'CleanHint(): placeholder strings and non-names become NA, a two-word value keeps its first word')
Expect(identical(unname(NameHints(Rows('X', 1, 'S', class = 'Aves', order = 'unknown Order', family = 'Unidentified'))), c(NA, NA, 'Aves', NA, NA)),
       'NameHints(): the VertNet placeholders are no hints')
ch <- ChooseGenusUsage(lookup_answers$Idothea, known_genera = c('Idotea', 'Lithobius'))
Expect(ch$choice$accepted == 'Idotea Fabricius, 1798' && Has(ch$note, 'Animalia preferred'),
       'Idothea: among the animal synonyms the one whose accepted genus the species table holds (Idotea)')
ch <- ChooseGenusUsage(lookup_answers$Idothea[2:3, ])
Expect(ch$choice$key == '6785462' && Has(ch$note, '2 usages of equal standing'),
       'two animal synonyms of equal standing and no known genus: the lower usage key, flagged')
Expect(is.null(ChooseGenusUsage(lookup_answers$Stercocarius)) && is.null(ChooseGenusUsage(data.frame())),
       'no candidates: NULL')
Expect(identical(HintScore(lookup_answers$Myodes, c(kingdom = NA, phylum = NA, class = 'Insecta', order = NA, family = NA)), c(-2, 1)),
       'HintScore(): -2 for a contradicting class, +1 for an agreeing one')
Expect(HintScore(U('1', 'Sceloporus', 'GENUS', 'ACCEPTED', 'Animalia', 'Chordata', 'Squamata'),
                 c(kingdom = NA, phylum = NA, class = 'Reptilia', order = NA, family = NA)) == 1,
       'HintScore(): GBIF class Squamata agrees with the frames\' Reptilia')
Expect(identical(RankBySuffix(c('Brachyderinae')), 'SUBFAMILY') && identical(RankBySuffix('Tanytarsini'), 'TRIBE') &&
         identical(RankBySuffix('Tydeidae'), 'FAMILY') && identical(RankBySuffix('Dorylaimoidea'), 'SUPERFAMILY') &&
         is.na(RankBySuffix('Lithobius')),
       'RankBySuffix(): -inae, -ini, -idae, -oidea; nothing for a genus name')

# ---- ResolveGenusNames() on the mock API ----------------------------------------
cat('ResolveGenusNames() on canned GBIF answers\n')
calls <- character(0)
gc <- ResolveGenusNames(genus_only, EmptyGenusCache(), enrich_cache, api = mock_api, sleep = 0, verbose = FALSE)
Row <- function(nm) gc[gc$taxon == nm, ]
Expect(identical(names(gc), genus_cache_columns) && nrow(gc) == length(unique(genus_only$taxon)) && !anyDuplicated(gc$taxon),
       'one cache row per bare name with the genus_cache columns')
r <- Row('Lithobius')
Expect(r$match_type == 'cache' && r$genus == 'Lithobius' && r$rank == 'GENUS' && r$class == 'Chilopoda' &&
         !any(calls %in% c('lookup Lithobius', 'match Lithobius')),
       'Lithobius: the accepted genus of two resolved species in the enrichment cache; no backbone lookup or fuzzy call (only the checklist flag)')
r <- Row('Lagopus')
Expect(r$match_type == 'EXACT' && r$genus == 'Lagopus' && r$gbif_status == 'ACCEPTED' && r$family == 'Phasianidae' &&
         Has(r$hints, 'class=Aves') && Has(r$note, 'settled by the source classification'),
       'Lagopus (VertNet hints class Aves): the bird genus by exact lookup, hints recorded')
r <- Row('Limonia')
Expect(r$genus == 'Limonia' && r$family == 'Limoniidae' && Has(r$note, 'Animalia preferred'),
       'Limonia (no hints): the crane-fly genus by kingdom preference, flagged in note')
r <- Row('Myodes')
Expect(r$match_type == 'EXACT' && r$genus == 'Ripiphorus' && r$gbif_status == 'SYNONYM' && any(calls == 'usage 1046300'),
       'Myodes with a contradicting class hint (Insecta): the cache genus is skipped and the hint picks the beetle synonym')
r <- Row('Dendroica')
Expect(r$genus == 'Setophaga' && r$gbif_status == 'SYNONYM' && r$gbif_usageKey == '2487384' &&
         Has(r$note, 'Dendroica is a synonym of Setophaga') && r$family == 'Parulidae',
       'Dendroica: synonym followed to the accepted genus Setophaga (one usage call)')
r <- Row('Idothea')
Expect(r$genus == 'Idotea' && r$class == 'Malacostraca' && Has(r$note, 'Idothea is a synonym of Idotea'),
       'Idothea: the isopod synonym (its accepted genus is in the species table), not the plant Drimia')
r <- Row('Staphylinidae')
Expect(r$match_type == 'EXACT' && r$rank == 'FAMILY' && is.na(r$genus) && r$order == 'Coleoptera',
       'Staphylinidae: a family, no genus, classification kept')
Expect(Row('Coleoptera')$rank == 'ORDER' && Row('Oligochaeta')$rank == 'CLASS' && Row('Hebridae')$rank == 'FAMILY',
       'Coleoptera, Oligochaeta, Hebridae resolve above genus (not to the plant genera, not fuzzily to Hebridea)')
Expect(!any(calls %in% c('match Oligochaeta', 'match Hebridae', 'match Coleoptera')),
       'names with an exact usage at any rank never reach the fuzzy stage')
r <- Row('Anisoptera')
Expect(r$match_type == 'curated' && r$rank == 'SUBORDER' && !any(grepl('Anisoptera$', calls)),
       'Anisoptera: the curated higher-rank list, no API call')
r <- Row('Zygoptera')
Expect(r$match_type == 'checklists' && r$rank == 'SUBORDER' && r$kingdom == 'Animalia' && Has(r$note, '17 of 20 ranked exact usages') && Has(r$note, 'doubtful genus'),
       'Zygoptera: the backbone has only a doubtful protozoan genus; the checklists make it a suborder (kingdom spelling Metazoa mapped)')
Expect(Row('Isopoda')$rank == 'ORDER' && Row('Isopoda')$match_type == 'EXACT' && !any(calls == 'lookup_all Isopoda'),
       'Isopoda: the accepted order of the backbone, no checklist call needed')
r <- Row('Heteroptera')
Expect(r$rank == 'ORDER' && r$match_type == 'checklists' && is.na(r$genus) && Has(r$note, 'backbone: only synonym genus'),
       'Heteroptera: the synonym genus Coproica is weak evidence; the checklists (ORDER 33, SUBORDER 21 of 71) make it a higher taxon')
Expect(Row('Crustacea')$rank == 'CLASS' && Row('Crustacea')$match_type == 'checklists',
       'Crustacea: the doubtful bee genus is weak evidence; the checklists make it a class')
r <- Row('Phasianus')
Expect(r$match_type == 'EXACT' && r$genus == 'Phasianus' && r$gbif_status == 'ACCEPTED' && r$family == 'Phasianidae' && r$hints == 'class=Aves',
       'Phasianus with the VertNet placeholders \'unknown Order\' / \'Unidentified\': the placeholders are dropped and the accepted bird genus wins')
r <- Row('Ensifera')
Expect(r$genus == 'Ensifera' && r$rank == 'GENUS' && r$match_type == 'EXACT' && Has(r$note, 'also a higher taxon in the checklists: 30 of 36'),
       'Ensifera: an accepted genus kept as such, flagged because the checklists mostly use the name for a suborder')
Expect(!Has(Row('Dendroica')$note, 'also a higher taxon') && !Has(Row('Lithobius')$note, 'also a higher taxon'),
       'genera the checklists use only as genera carry no flag')
Expect(any(calls == 'lookup_all Lithobius') && any(calls == 'lookup_all Dendroica'),
       'the checklists are consulted for every resolved genus (the flag) and for the weak backbone cases')
r <- Row('Brachyderinae')
Expect(r$match_type == 'suffix' && r$rank == 'SUBFAMILY' && !any(calls == 'match Brachyderinae'),
       'Brachyderinae: no GBIF usage, rank from the suffix, no fuzzy call')
r <- Row('Stercocarius')
Expect(r$match_type == 'FUZZY' && r$genus == 'Stercorarius' && r$gbif_confidence == 85 && r$family == 'Stercorariidae' &&
         Has(r$note, 'fuzzy match of Stercocarius (confidence 85, 1 letter(s) apart)'),
       'Stercocarius: fuzzy match to Stercorarius accepted (confidence 85, one letter) and flagged')
Expect(Row('Lithobiusxxx')$match_type == 'NONE' && Row('Xyzzyq')$match_type == 'NONE',
       'fuzzy candidates three letters apart or below confidence 80 are rejected')
Expect(Row('Renic')$match_type == 'NONE' && !any(calls == 'match Renic'),
       'a name of fewer than six letters (Renic) is never matched fuzzily')
r <- Row('Isolauctis')
Expect(r$match_type == 'NONE' && is.na(r$genus) && is.na(r$rank) && Has(r$note, 'no GBIF usage'),
       'Isolauctis: unresolved, note says why')
Expect(Row('Gomphonema')$match_type == 'cache' && Row('Gomphonema')$phylum == 'Ochrophyta',
       'Gomphonema: resolved (a cache genus); the autotroph filter removes it later')
Expect(Row('Hydrobiosis')$gbif_status == 'ACCEPTED', 'Hydrobiosis: the accepted usage, not the doubtful one')
n_calls <- length(calls)
gc2 <- ResolveGenusNames(genus_only, gc, enrich_cache, api = mock_api, sleep = 0, verbose = FALSE)
Expect(identical(gc2, gc) && length(calls) == n_calls, 'a second call finds every name cached and makes no API call')
gc3 <- ResolveGenusNames(Rows('Hydrobiosis', 1, 'SrcA'), EmptyGenusCache(), enrich_cache, api = mock_api, sleep = 0, verbose = FALSE)
Expect(nrow(gc3) == 1 && gc3$taxon == 'Hydrobiosis', 'resolution of a single new name appends one row')

# ---- outcomes, the autotroph filter and the higher-rank exclusion --------------
cat('outcomes, FilterAutotrophs() and the higher-rank exclusion\n')
gc$outcome <- ifelse(is.na(gc$rank), 'unresolved', ifelse(gc$rank == 'GENUS', 'genus', 'above genus'))
tax_cols <- c('kingdom', 'phylum', 'class', 'order', 'family')
go <- merge(genus_only[, setdiff(names(genus_only), tax_cols)],
            gc[, c('taxon', 'genus', 'rank', 'gbif_status', 'match_type', 'outcome', tax_cols)], by = 'taxon', all.x = TRUE)
go$source_label <- SourceLabel(go$source_mass)
go$source_group <- SourceGroup(go$source_label)
Expect(setequal(unique(go$taxon[go$outcome == 'above genus']), c('Staphylinidae', 'Coleoptera', 'Oligochaeta', 'Hebridae', 'Anisoptera', 'Zygoptera', 'Brachyderinae', 'Isopoda', 'Heteroptera', 'Crustacea')),
       'ten names are above genus')
Expect(setequal(unique(go$taxon[go$outcome == 'unresolved']), c('Isolauctis', 'Lithobiusxxx', 'Xyzzyq', 'Renic')), 'four names are unresolved')
genus_rows <- go[go$outcome == 'genus', ]
kept <- FilterAutotrophs(genus_rows)
Expect(!'Gomphonema' %in% kept$genus && all(c('Lagopus', 'Lithobius', 'Idotea', 'Stercorarius') %in% kept$genus),
       'FilterAutotrophs() on the resolved classification removes the diatom genus and keeps the animals')
Expect(nrow(FilterAutotrophs(data.frame(genus = c('Oligochaeta', 'Zea', 'Gymnodinium', 'Noctiluca'),
                                        kingdom = c('Plantae', 'Plantae', 'Chromista', 'Chromista'),
                                        phylum = c('Tracheophyta', 'Tracheophyta', 'Myzozoa', 'Myzozoa'), stringsAsFactors = FALSE))) == 1,
       'a plant genus homonym and a listed dinoflagellate genus are removed, the heterotrophic Noctiluca stays')
hr <- HigherRankRecords(go[go$outcome == 'above genus', ])
Expect(identical(names(hr), c('taxon', 'rank', 'kingdom', 'phylum', 'class', 'order', 'family', 'mass_g', 'source_mass', 'n', 'n_independent')) &&
         nrow(hr) == 10 && hr$taxon[1] == 'Staphylinidae',
       'HigherRankRecords(): one row per name, the columns of TaxonBodyMass_HigherRank.csv, most rows first')
st <- hr[hr$taxon == 'Staphylinidae', ]
Expect(st$rank == 'FAMILY' && st$n == 3 && st$n_independent == 2 &&
         abs(st$mass_g - signif(mean(c(10^mean(log10(c(0.01, 0.012))), 0.011)), 4)) < 1e-12 &&
         st$source_mass == 'Brose_2005; Brose_etal_2018',
       'Staphylinidae: three rows from two sources, the mean of the two sources\' geometric means')
Expect(setequal(hr$taxon[hr$rank == 'SUBORDER'], c('Anisoptera', 'Zygoptera')) && hr$rank[hr$taxon == 'Brachyderinae'] == 'SUBFAMILY' &&
         hr$rank[hr$taxon == 'Crustacea'] == 'CLASS' && hr$rank[hr$taxon == 'Heteroptera'] == 'ORDER',
       'ranks of the curated, checklist- and suffix-derived names are carried')

# ---- Pass 1, de-duplication and Pass 2 --------------------------------------------
cat('GenusOnlyValues(), DedupeGenusValues(), GenusOnlyRecords()\n')
vals <- GenusOnlyValues(kept)
Expect(!anyDuplicated(paste(vals$genus, vals$source_group)) && all(c('genus', 'source_group', 'source_label', 'source_mass', 'taxon_provided', 'mass_g', 'n') %in% names(vals)),
       'one value per genus and source group')
lv <- vals[vals$genus == 'Lagopus', ]
Expect(nrow(lv) == 3 && setequal(lv$source_group, c('vertnet', 'Brose_etal_2018', 'Brose_2005')),
       'Lagopus: the VertNet dumps pooled into one value, Brose_etal_2018 and Brose_2005 one each')
vn <- lv[lv$source_group == 'vertnet', ]
Expect(abs(vn$mass_g - 10^mean(log10(c(14.0, 70.8, 500)))) < 1e-9 && vn$n == 3 &&
         vn$source_label == 'vertnet-aves-sept2016+vertnet-traits-sept2016' && vn$source_mass == 'vertnet-aves-sept2016; vertnet-traits-sept2016',
       'the pooled VertNet value is the geometric mean of the three records, both dump labels kept')
sv <- vals[vals$genus == 'Stercorarius', ]
Expect(nrow(sv) == 1 && sv$taxon_provided == 'Stercocarius' && abs(sv$mass_g - sqrt(298 * 391)) < 1e-9,
       'Stercocarius rows become a Stercorarius value; taxon_provided keeps the spelling written')
Expect(nrow(GenusOnlyValues(kept[0, ])) == 0, 'no rows: an empty values table')

reg <- tempfile('deps_', fileext = '.csv')
writeLines(c(paste(dependency_columns, collapse = ','),
             'Brose_etal_2018,Brose_2005,TRUE,copies,1e-6,,confirmed,,"GATEWAy incorporates Brose 2005",2026-10-03',
             'Tobias_2022,Dunning_2008,FALSE,copies,1e-6,1,confirmed,,"AVONET copies Dunning (gives the priority column a value)",2026-10-03'), reg)
deps <- LoadSourceDependencies(reg, known_labels = c(unique(go$source_label), 'Tobias_2022'))
dd <- DedupeGenusValues(vals, deps)
v <- dd$values
Expect(all(c('independent', 'collapsed_into', 'dedupe_rule') %in% names(v)) && !'species' %in% names(v) && nrow(v) == nrow(vals),
       'DedupeGenusValues() returns the values with the de-duplication columns and no species column')
lb <- v[v$genus == 'Lagopus' & v$source_label == 'Brose_etal_2018', ]
Expect(!lb$independent && lb$collapsed_into == 'Brose_2005' && lb$dedupe_rule == 'registry' &&
         v$independent[v$genus == 'Lagopus' & v$source_label == 'Brose_2005'] && v$independent[v$genus == 'Lagopus' & v$source_group == 'vertnet'],
       'the identical Brose_etal_2018 value collapses into Brose_2005 by the registry edge; the parent and VertNet stay independent')
Expect(all(v$independent[v$genus != 'Lagopus']), 'single-source genera are untouched')
Expect(nrow(DedupeGenusValues(vals[0, ], deps)$values) == 0, 'no values: an empty result')

rec <- GenusOnlyRecords(v, variant = 'pseudo-taxon')
Expect(!anyDuplicated(rec$genus) && nrow(rec) == length(unique(v$genus)) &&
         all(c('genus', 'mass_g', 'n', 'n_sources', 'n_independent', 'source_mass', 'log10_range', 'source_dependencies') %in% names(rec)),
       'pseudo-taxon variant: one record per genus')
lr <- rec[rec$genus == 'Lagopus', ]
exp_mass <- mean(c(10^mean(log10(c(14.0, 70.8, 500))), sqrt(511.5 * 598)))
Expect(abs(lr$mass_g - exp_mass) < 1e-9 && lr$n == 7 && lr$n_sources == 3 && lr$n_independent == 2 &&
         lr$source_dependencies == 'Brose_etal_2018<Brose_2005' && Has(lr$source_mass, 'vertnet-traits-sept2016') && Has(lr$source_mass, 'Brose_2005'),
       'Lagopus record: the arithmetic mean of the two independent values (VertNet, Brose_2005), n 7, n_independent 2, the collapse recorded')
Expect(abs(lr$log10_range - abs(log10(10^mean(log10(c(14.0, 70.8, 500))) / sqrt(511.5 * 598)))) < 1e-9,
       'log10_range of the record spans the independent values')
alt <- GenusOnlyRecords(v, variant = 'per-source')
Expect(sum(alt$genus == 'Lagopus') == 2 && all(alt$n_independent == 1) && nrow(alt) == sum(v$independent),
       'per-source variant: one record per independent value (two for Lagopus)')
Expect(nrow(GenusOnlyRecords(v[0, ])) == 0, 'no values: no records')

# ---- the genus table ---------------------------------------------------------------
cat('GenusLevelTable()\n')
enriched <- data.frame(genus = c('Lagopus', 'Lagopus', 'Zz', 'Aa'), species = c('Lagopus lagopus', 'Lagopus muta', 'Zz top', 'Aa bb'),
                       mass_g = c(514, 500, 1, 2), n = c(10, 5, 1, 1), n_independent = c(4L, 3L, 1L, 1L),
                       source_mass = c('Tobias_2022; AnAge', 'Tobias_2022', 'SrcA', 'SrcA'), stringsAsFactors = FALSE)
gt <- GenusLevelTable(enriched, rec)
Expect(identical(names(gt), c('taxon', 'mass_g', 'source_mass', 'n', 'n_independent')) && !anyDuplicated(gt$taxon),
       'the table has the five columns of TaxonBodyMass_GenusLevel.csv, one row per genus')
Expect(identical(gt$taxon, sort(gt$taxon, method = 'radix')) && gt$taxon[1] == 'Aa' && gt$taxon[nrow(gt)] == 'Zz',
       'rows ordered by genus in the C locale')
lg <- gt[gt$taxon == 'Lagopus', ]
Expect(abs(lg$mass_g - mean(c(514, 500, exp_mass))) < 1e-9 && lg$n == 22 && lg$n_independent == 9 &&
         lg$source_mass == paste('Tobias_2022; AnAge', 'Tobias_2022', lr$source_mass, sep = '-'),
       'Lagopus: the mean of two species values and one genus-only record (weight of one species); n and n_independent summed; sources joined by -')
Expect(gt$mass_g[gt$taxon == 'Zz'] == 1 && gt$n_independent[gt$taxon == 'Zz'] == 1, 'a genus with species values only is unchanged')
Expect(abs(gt$mass_g[gt$taxon == 'Stercorarius'] - sqrt(298 * 391)) < 1e-9 && gt$n_independent[gt$taxon == 'Stercorarius'] == 1,
       'a genus with a genus-only record only enters with that record')
Expect(!any(c('Staphylinidae', 'Coleoptera', 'Oligochaeta', 'Anisoptera', 'Gomphonema', 'Isolauctis', 'Stercocarius', 'Dendroica', 'Idothea', 'Isopoda', 'Isopeda', 'Heteroptera', 'Coproica', 'Crustacea') %in% gt$taxon) &&
         all(c('Setophaga', 'Idotea', 'Phasianus', 'Ensifera') %in% gt$taxon),
       'higher ranks, autotrophs, unresolved names and synonym spellings are absent; the accepted genera are present')
gt_alt <- GenusLevelTable(enriched, alt)
Expect(abs(gt_alt$mass_g[gt_alt$taxon == 'Lagopus'] - mean(c(514, 500, 10^mean(log10(c(14.0, 70.8, 500))), sqrt(511.5 * 598)))) < 1e-9,
       'per-source variant: each independent genus-only value enters the genus mean separately')
Expect(nrow(GenusLevelTable(enriched[0, ], rec[0, ])) == 0, 'empty inputs: an empty table')

# ---- the report --------------------------------------------------------------------
cat('WriteGenusOnlyReport()\n')
agg <- aggregate(cbind(rows = rep(1L, nrow(go))), by = list(taxon = go$taxon), FUN = sum)
agg$sources <- vapply(agg$taxon, function(t) paste(sort(unique(go$source_label[go$taxon == t])), collapse = ', '), character(1))
agg$gm <- vapply(agg$taxon, function(t) 10^mean(log10(go$mass_g[go$taxon == t])), numeric(1))
res <- merge(gc, agg, by = 'taxon')
removed <- data.frame(genus = 'Gomphonema', kingdom = 'Chromista', phylum = 'Ochrophyta', rows = 1L, names = 'Gomphonema', sources = 'Brose_etal_2018', stringsAsFactors = FALSE)
sgm <- data.frame(genus = c('Lagopus', 'Lithobius'), species_mean = c(507, 1.25e-2), n_species = c(2L, 17L), stringsAsFactors = FALSE)
rep_file <- tempfile('genus_only_', fileext = '.md')
rp <- WriteGenusOnlyReport(rep_file, res, removed, dd, rec, sgm, deps)
txt <- readLines(rep_file)
Expect(any(grepl('^## Totals', txt)) && any(grepl('^## Names resolved above genus', txt)) && any(grepl('^## Fuzzy matches accepted', txt)) &&
         any(grepl('^## Homonyms and doubtful usages', txt)) && any(grepl('^## De-duplication of the genus x source values', txt)) &&
         any(grepl('more than one order of magnitude', txt)),
       'the report has its sections')
Expect(nrow(rp$higher) == 10 && rp$higher$taxon[1] == 'Staphylinidae' && 'Stercocarius' %in% rp$fuzzy$taxon &&
         any(rp$homonym$taxon == 'Limonia') && any(rp$synonyms$taxon == 'Dendroica') && any(rp$unresolved$taxon == 'Isolauctis'),
       'the tables list the higher ranks, the fuzzy match, the homonym choice, the synonym and the unresolved name')
Expect(nrow(rp$dedupe) == 1 && rp$dedupe$dropped == 'Brose_etal_2018' && rp$dedupe$kept == 'Brose_2005' && rp$dedupe$values == 1,
       'the de-duplication table counts the collapsed Brose value')
Expect(nrow(rp$far) == 1 && rp$far$genus == 'Lithobius', 'Lithobius (4.5e-4 g against 1.25e-2 g) is the one record more than 1 log10 from its species mean')
Expect(any(grepl('^## Genera that the GBIF checklists mostly use for a higher taxon', txt)) && nrow(rp$cross) == 1 && rp$cross$taxon == 'Ensifera',
       'the cross-rank homonym section lists Ensifera')

# ---- wiring in RunMe.r -----------------------------------------------------------
cat('R/RunMe.r wiring\n')
runme <- readLines(file.path(repo, 'R', 'RunMe.r'))
i_src   <- grep("^source\\(file\\.path\\(wd_root, 'R', 'library', 'enrich_genus\\.r'\\)\\)", runme)
i_split <- grep("^genus_only <- adat_raw\\[!grepl\\('_', adat_raw\\$taxon\\), \\]", runme)
i_keep  <- grep("^adat_raw   <- adat_raw\\[ grepl\\('_', adat_raw\\$taxon\\), \\]", runme)
i_5b    <- grep('^# 5b\\. Genus-only records', runme)
i_res   <- grep('^genus_cache <- ResolveGenusNames\\(genus_only, genus_cache, enrich_cache\\)', runme)
i_unres <- grep('^unresolved_names <- rbind\\(unresolved_names, unresolved_genus_names\\)', runme)
i_ce    <- grep('^check_enriched\\(enriched, within_source\\[within_source\\$independent, \\],', runme)
i_auto  <- grep('^genus_rows_kept <- FilterAutotrophs\\(genus_rows\\)', runme)
i_vals  <- grep('^genus_values <- GenusOnlyValues\\(genus_rows_kept\\)', runme)
i_dd    <- grep('^genus_dedupe <- DedupeGenusValues\\(genus_values, source_deps\\)', runme)
i_rec   <- grep("^genus_records     <- GenusOnlyRecords\\(genus_values, variant = 'pseudo-taxon'\\)", runme)
i_tab   <- grep('^gdat <- GenusLevelTable\\(enriched, genus_records\\)', runme)
i_wsp   <- grep("^write\\.csv\\(enriched, file = file\\.path\\(wd_root, 'TaxonBodyMass\\.csv'\\),", runme)
i_wg    <- grep('^write\\.csv\\(gdat, file = file\\.path\\(wd_root, \'TaxonBodyMass_GenusLevel\\.csv\'\\),', runme)
Expect(length(i_src) == 1 && length(i_split) == 1 && length(i_keep) == 1 && i_split < i_keep,
       'RunMe.r sources enrich_genus.r and splits genus-only rows off in section 3 as before')
Expect(all(lengths(list(i_5b, i_res, i_unres, i_ce, i_auto, i_vals, i_dd, i_rec, i_tab, i_wsp, i_wg)) == 1) &&
         i_5b < i_res && i_res < i_unres && i_unres < i_ce && i_ce < i_tab && i_auto < i_vals && i_vals < i_dd && i_dd < i_rec && i_rec < i_ce,
       'section 5b resolves, extends the unresolved list before check_enriched(), filters, weights, de-duplicates; section 6 builds the table')
Expect(any(grepl('^save\\(enrich_cache, genus_cache, file = cache_path\\)', runme)) && !any(grepl('^\\s*save\\(enrich_cache, file = cache_path\\)', runme)) &&
         any(grepl("^  if \\(!exists\\('genus_cache'\\)\\) genus_cache <- EmptyGenusCache\\(\\)", runme)),
       'the genus cache is saved with the enrichment cache and created when the cache file predates #49')
# the species path is untouched: between the Sheet override and section 5b
# nothing refers to the genus-only objects except the cache lines, and
# `enriched` is only reassigned by the range filter before it is written
i_sheet <- grep('^# 4\\. Lab Google Sheet override', runme)
species_path <- runme[i_sheet:(i_5b - 1)]
leak <- grep('genus_only|GenusOnly|genus_values|genus_records|genus_res\\b|higher_rank', species_path)
Expect(length(i_sheet) == 1 && length(leak) == 0, 'the species path (sections 4-5) does not refer to the genus-only objects')
after <- runme[i_5b:i_wsp]
assign_enriched <- grep('^\\s*enriched\\s*<-|^\\s*enriched\\$', after)
Expect(length(assign_enriched) == 1 && grepl('^\\s*enriched <- res\\$dat', after[assign_enriched]),
       'after section 5b, `enriched` is reassigned only by the range filter before TaxonBodyMass.csv is written')
Expect(!any(grepl('genus_only\\$n_independent <- 1L|bind_rows\\(enriched, genus_only\\)', runme)),
       'the pre-#49 aggregation (every raw genus-only row as one value) is gone')

# ---- summary -------------------------------------------------------------------
cat(sprintf('\n%d expectations, %d failed\n', n_checks, length(failures)))
if (length(failures) > 0) {
  cat(paste0('  FAIL: ', failures, '\n'), sep = '')
  quit(status = 1)
}
