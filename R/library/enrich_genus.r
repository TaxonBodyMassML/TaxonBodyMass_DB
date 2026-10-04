# Genus-only records: resolution at genus rank, filtering, weighting and
# de-duplication of the input records that are identified to genus only
# (issue #49).
#
# A cleaned name without an underscore (a bare genus, or whatever else one
# token is) is split off in R/RunMe.r section 3 before the species path and
# feeds TaxonBodyMass_GenusLevel.csv. Until #49 every such raw row entered the
# genus mean under its raw spelling, as one value with the weight of a species'
# cross-source mean, without rank resolution, autotroph filter, one value per
# source or de-duplication. The functions here give the genus-only path the
# machinery of the species path:
#
#   ResolveGenusNames()  resolves every bare name once to an accepted GBIF
#                        genus with its kingdom-to-family classification, or
#                        records that the name is a rank above genus (family,
#                        order, tribe, ...), caching every answer in the object
#                        `genus_cache` of sources/enrich_cache.Rdata;
#   GenusOnlyValues()    Pass 1: the geometric mean per accepted genus and
#                        source group (VertNet dumps pooled), as for species;
#   DedupeGenusValues()  DedupeSources() on those values with the registry
#                        Bib/source_dependencies.csv (Brose_etal_2018 ->
#                        Brose_2005, -> Hechinger_etal_2011, ...);
#   GenusOnlyRecords()   Pass 2: one genus-only record per genus, the
#                        arithmetic mean of its independent per-source values
#                        (the "pseudo-taxon": it enters the genus mean with the
#                        weight of one species), or, as the alternative
#                        variant, one record per independent source;
#   GenusLevelTable()    the genus table: the arithmetic mean, by accepted
#                        genus, over the species' cross-source means and the
#                        genus-only record(s);
#   HigherRankRecords()  the names resolved above genus, one row per name,
#                        for the optional TaxonBodyMass_HigherRank.csv;
#   WriteGenusOnlyReport()  reports/genus_only_records.md.
#
# Resolution stages (ResolveGenusName(), one bare name at a time):
#   0. curated list genus_only_higher_rank_names: names the sources use for
#      groups above genus that the GBIF backbone and the other GBIF checklists
#      carry mostly as homonymous genera of other groups (Anisoptera,
#      Hydracarina), so no lookup can recover the rank;
#   1. the accepted genus of a resolved species in the enrichment cache: the
#      name is spelt exactly like the `genus` of a species the species path
#      resolved, and the source's classification hints (class, order, family
#      where the frame gives them; placeholder strings such as 'unknown
#      Order' are ignored) do not contradict it; the classification is the
#      modal one of those species (match_type 'cache', no lookup);
#   2. the GBIF backbone exact-name lookup (/v1/species?name=&datasetKey=
#      backbone): every usage spelt exactly like the name, at any rank.
#      ChooseGenusUsage() picks one: the usages agreeing with the source's
#      hints, then the kingdom preferred for a heterotroph database (Animalia,
#      Protozoa, Chromista, Bacteria/Archaea, Fungi, Plantae: the GBIF
#      species/match endpoint resolves Coleoptera and Oligochaeta to plant
#      genera and refuses Lagopus and Idothea as "multiple equal matches"),
#      then by standing: an ACCEPTED genus, an ACCEPTED usage above genus, a
#      SYNONYM usage above genus, a SYNONYM genus (followed to its accepted
#      genus; the order Isopoda beats the spider synonym Isopoda -> Isopeda),
#      a DOUBTFUL genus, a DOUBTFUL usage above genus; then a genus already
#      present in the species table, then the lowest usage key. A choice
#      between kingdoms or between homonyms is written to `note` and reported;
#   2b. the exact-name lookup across every GBIF checklist (/v1/species?name=)
#      decides the rank when the backbone gives no usage or only weak evidence
#      (a synonym or doubtful genus): when at least 60 % of the ranked usages
#      sit above genus, the name is a higher taxon of their modal rank
#      (Crustacea CLASS, Heteroptera ORDER, Acarina ORDER, Apocrita SUBORDER,
#      Hirudinea CLASS, Caelifera SUBORDER: the backbone holds none of these
#      above genus). For every resolved genus the same lookup also flags, in
#      `note`, a name that the checklists mostly use for a higher taxon
#      (Ensifera: the hummingbird genus and the orthopteran suborder), which
#      no lookup can settle for a source without hints;
#   3. no usage of the name anywhere: a family-group suffix (-oidea, -idae,
#      -inae, -ini; -aceae, -ales) gives the rank;
#   4. otherwise GBIF species/match with rank=GENUS and the hints, fuzzy
#      candidates only (an exact usage would have been found before), for
#      names of at least six letters, at confidence >= 80 and at most two
#      letters apart (Stercocarius -> Stercorarius; the FUZZY confidence GBIF
#      gives, 80-93, does not separate good from bad hits by itself, which is
#      why names with an exact usage at another rank, Hebridae, never reach
#      this stage); every accepted fuzzy match is reported for review;
#   5. otherwise unresolved: the rows leave the genus table and the name is
#      listed in reports/warnings_taxonomy.md with its sources and rows.
# The extinct-taxa list (audit/extinct_taxa.csv) is species-level and is not
# applied to genus-only records. FilterAutotrophs() is applied to the resolved
# classification in RunMe.r. A fuzzy stage against the accepted genera of the
# species table was considered and rejected: a third of those genera have
# another real genus within two letters.
#
# The API functions are injected (`api`), so the tests run offline on canned
# answers: see R/library/tests/test_genus_only_records.R.

genus_cache_columns <- c('taxon', 'genus', 'rank', 'gbif_status', 'match_type', 'gbif_confidence',
                         'gbif_usageKey', 'kingdom', 'phylum', 'class', 'order', 'family',
                         'taxonomy_source', 'note', 'hints', 'resolved')

EmptyGenusCache <- function() {
  data.frame(taxon = character(0), genus = character(0), rank = character(0),
             gbif_status = character(0), match_type = character(0), gbif_confidence = numeric(0),
             gbif_usageKey = character(0), kingdom = character(0), phylum = character(0),
             class = character(0), order = character(0), family = character(0),
             taxonomy_source = character(0), note = character(0), hints = character(0),
             resolved = character(0), stringsAsFactors = FALSE)
}

# Names the sources write for groups above genus that the GBIF backbone and
# most other GBIF checklists hold as homonymous genera of other groups, so
# that neither the backbone nor the checklist majority (stage 2b) recovers the
# rank. Stage 0; the rank is the one the sources mean.
genus_only_higher_rank_names <- c(
  Anisoptera  = 'SUBORDER',   # dragonflies (Odonata); backbone: doubtful tettigoniid / libellulid genera and a dipterocarp genus; checklists: 44 genus usages against 14 suborder
  Hydracarina = 'UNRANKED'    # water mites (Trombidiformes), an informal group; backbone: a doubtful arrenurid genus; checklists: family, genus, class and suborder usages
)

# Family-group and ordinal suffixes that give the rank of a name GBIF does not
# carry at all (stage 3). Zoological (ICZN) endings first, then botanical.
genus_only_rank_suffixes <- c(oidea = 'SUPERFAMILY', idae = 'FAMILY', inae = 'SUBFAMILY', ini = 'TRIBE',
                              oideae = 'SUBFAMILY', aceae = 'FAMILY', ales = 'ORDER', formes = 'ORDER')

# Kingdom preference for homonyms the hints do not settle: the database
# describes heterotrophs, so an animal, protozoan or chromist usage is the
# likelier meaning of a bare name in a food-web or metabolic compilation than
# a plant or fungal genus of the same spelling.
genus_only_kingdom_preference <- c(Animalia = 1, Protozoa = 2, Chromista = 3, Bacteria = 4, Archaea = 4,
                                   Fungi = 5, Plantae = 6, Viruses = 7)

genus_only_higher_ranks <- c('KINGDOM', 'SUBKINGDOM', 'INFRAKINGDOM', 'SUPERPHYLUM', 'PHYLUM', 'SUBPHYLUM',
                             'INFRAPHYLUM', 'SUPERCLASS', 'CLASS', 'SUBCLASS', 'INFRACLASS', 'PARVCLASS',
                             'SUPERORDER', 'ORDER', 'SUBORDER', 'INFRAORDER', 'PARVORDER', 'SUPERFAMILY',
                             'FAMILY', 'SUBFAMILY', 'TRIBE', 'SUBTRIBE')
genus_only_synonym_statuses <- c('SYNONYM', 'HETEROTYPIC_SYNONYM', 'HOMOTYPIC_SYNONYM', 'PROPARTE_SYNONYM')
genus_only_species_ranks    <- c('SPECIES', 'SUBSPECIES', 'VARIETY', 'SUBVARIETY', 'FORM', 'SUBFORM', 'SPECIES_AGGREGATE',
                                 'INFRASPECIFIC_NAME', 'INFRASUBSPECIFIC_NAME', 'CULTIVAR', 'STRAIN')
genus_only_fuzzy_min_confidence <- 80
genus_only_fuzzy_max_distance   <- 2
genus_only_fuzzy_min_length     <- 6
genus_only_checklist_min_share  <- 0.6     # share of ranked checklist usages above genus that makes a name a higher taxon
genus_hint_ranks <- c('kingdom', 'phylum', 'class', 'order', 'family')
# Kingdom spellings of the non-backbone checklists, mapped to the backbone's.
genus_only_kingdom_synonyms <- c(Metazoa = 'Animalia', Animal = 'Animalia', Viridiplantae = 'Plantae', Protista = 'Protozoa')

# Class names as the frames give them (after FixTaxonomyRanks(), which maps
# Squamata and Lepidosauria to Reptilia and Actinopteri to Actinopterygii)
# against the GBIF backbone, which files lizards and snakes under class
# Squamata and gives most fishes no class at all: the same map as Part 1 of
# fix_taxonomy_ranks.r, applied on both sides before a hint is compared.
NormaliseClassName <- function(x) {
  syn <- c(Actinopteri = 'Actinopterygii', Teleostei = 'Actinopterygii',
           Lepidosauria = 'Reptilia', Squamata = 'Reptilia')
  hit <- !is.na(x) & x %in% names(syn)
  x[hit] <- syn[x[hit]]
  x
}

# ---- GBIF API -----------------------------------------------------------------
# One list of three functions, each returning a data frame of usages with the
# columns of UsageRow() (or NULL when nothing was found); errors stop the
# caller so the name is retried at the next run instead of being cached as
# unresolved.
gbif_backbone_key <- 'd7dddbf4-2cf0-4f39-9b2a-bb099caae36c'

UsageRow <- function(x, match_type = 'EXACT') {
  g <- function(k) { v <- x[[k]]; if (is.null(v) || length(v) == 0) NA_character_ else as.character(v[[1]]) }
  status <- g('status'); if (is.na(status)) status <- g('taxonomicStatus')
  conf <- suppressWarnings(as.numeric(g('confidence')))
  data.frame(key = g('usageKey') %||% g('key'), canonicalName = g('canonicalName'), rank = g('rank'),
             status = status, matchType = match_type, confidence = conf,
             kingdom = g('kingdom'), phylum = g('phylum'), class = g('class'), order = g('order'),
             family = g('family'), genus = g('genus'),
             acceptedKey = g('acceptedUsageKey') %||% g('acceptedKey'), accepted = g('accepted'),
             stringsAsFactors = FALSE)
}
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0 || is.na(a[1])) b else a

GbifGenusApi <- function(user_agent = 'TaxonBodyMass_DB/1.0 (genus-only records, issue #49)', timeout = 30) {
  perform <- function(req) {
    req |> httr2::req_user_agent(user_agent) |> httr2::req_timeout(timeout) |>
      httr2::req_retry(max_tries = 3, backoff = ~ 5) |> httr2::req_perform() |> httr2::resp_body_json()
  }
  list(
    # every backbone usage spelt like `name` (the lookup is case-insensitive
    # and exact on the canonical name), any rank
    lookup = function(name) {
      r <- perform(httr2::request('https://api.gbif.org/v1/species') |>
                     httr2::req_url_query(name = name, datasetKey = gbif_backbone_key, limit = 100))
      if (length(r$results) == 0) return(NULL)
      do.call(rbind, lapply(r$results, UsageRow, match_type = 'EXACT'))
    },
    # the same across every checklist GBIF indexes (up to 200 usages): the
    # ranks the taxonomic community gives the name
    lookup_all = function(name) {
      r <- perform(httr2::request('https://api.gbif.org/v1/species') |>
                     httr2::req_url_query(name = name, limit = 200))
      if (length(r$results) == 0) return(NULL)
      do.call(rbind, lapply(r$results, UsageRow, match_type = 'EXACT'))
    },
    # species/match at genus rank with the source's hints; the main match and
    # the alternatives, with GBIF's match type and confidence
    match = function(name, hints = NULL) {
      q <- list(name = name, rank = 'GENUS', strict = 'false', verbose = 'true')
      for (h in genus_hint_ranks) if (!is.null(hints) && !is.na(hints[h])) q[[h]] <- unname(hints[h])
      r <- perform(httr2::request('https://api.gbif.org/v1/species/match') |> httr2::req_url_query(!!!q))
      rows <- list()
      if (!is.null(r$matchType) && r$matchType != 'NONE') rows[[1]] <- UsageRow(r, match_type = r$matchType)
      for (a in r$alternatives %||% list()) rows[[length(rows) + 1]] <- UsageRow(a, match_type = a$matchType %||% NA_character_)
      if (length(rows) == 0) return(NULL)
      do.call(rbind, rows)
    },
    # one usage by key (to follow a synonym to its accepted genus)
    usage = function(key) UsageRow(perform(httr2::request(paste0('https://api.gbif.org/v1/species/', key))))
  )
}

# ---- resolution ---------------------------------------------------------------
# The accepted genera of the species path: one row per `genus` of a resolved
# species in the enrichment cache with the modal kingdom/phylum/class/order/
# family of its species.
CacheGenera <- function(enrich_cache) {
  ec <- enrich_cache[!is.na(enrich_cache$species) & !is.na(enrich_cache$genus) & nzchar(enrich_cache$genus), ]
  if (nrow(ec) == 0)
    return(data.frame(genus = character(0), kingdom = character(0), phylum = character(0), class = character(0),
                      order = character(0), family = character(0), n_species = integer(0), stringsAsFactors = FALSE))
  Mode <- function(x) { x <- x[!is.na(x) & nzchar(x)]; if (length(x) == 0) NA_character_ else names(which.max(table(x))) }
  sp <- split(ec, ec$genus)
  out <- data.frame(genus = names(sp), stringsAsFactors = FALSE)
  for (rk in genus_hint_ranks) out[[rk]] <- vapply(sp, function(d) Mode(d[[rk]]), character(1))
  out$n_species <- vapply(sp, nrow, integer(1))
  rownames(out) <- NULL
  out
}

# Hints of a name as a named character vector over genus_hint_ranks (NA where
# the frames give nothing), from the modal non-NA value over its rows.
# Placeholder strings the frames carry ('unknown Order', 'Unidentified',
# VertNet) are no hints, and a two-word value ('Phasianidae Tetraoninae',
# family and subfamily) is reduced to its first word.
CleanHint <- function(x) {
  x <- trimws(as.character(x))
  x[is.na(x) | !nzchar(x)] <- NA_character_
  junk <- grepl('^(unknown|unidentif|undetermin|indet|unid|unk|none|n/?a|\\?)', x, ignore.case = TRUE)
  x[junk] <- NA_character_
  two <- !is.na(x) & grepl('^[A-Z][a-z]+ [A-Z][a-z]+$', x)
  x[two] <- sub(' .*$', '', x[two])
  x[!is.na(x) & !grepl('^[A-Z][a-z]+$', x)] <- NA_character_
  x
}
NameHints <- function(rows) {
  Mode <- function(x) { x <- x[!is.na(x) & nzchar(x)]; if (length(x) == 0) NA_character_ else names(which.max(table(x))) }
  h <- vapply(genus_hint_ranks, function(rk) if (rk %in% names(rows)) Mode(CleanHint(rows[[rk]])) else NA_character_, character(1))
  names(h) <- genus_hint_ranks
  h
}
HintString <- function(hints) {
  if (is.null(hints) || all(is.na(hints))) return(NA_character_)
  paste(sprintf('%s=%s', names(hints)[!is.na(hints)], hints[!is.na(hints)]), collapse = '|')
}

# Agreement of candidate usages with the hints: +1 per hint rank the usage
# carries with the same name, -2 per rank where both are given and differ
# (class names normalised on both sides).
HintScore <- function(cands, hints) {
  if (is.null(hints)) return(rep(0, nrow(cands)))
  hints[] <- CleanHint(hints)
  if (all(is.na(hints))) return(rep(0, nrow(cands)))
  score <- rep(0, nrow(cands))
  for (rk in genus_hint_ranks) {
    if (is.na(hints[rk])) next
    cv <- as.character(cands[[rk]]); hv <- hints[[rk]]
    if (rk == 'class') { cv <- NormaliseClassName(cv); hv <- NormaliseClassName(hv) }
    agree <- !is.na(cv) & tolower(cv) == tolower(hv)
    differ <- !is.na(cv) & tolower(cv) != tolower(hv)
    score <- score + agree - 2 * differ
  }
  score
}

# Pick one usage among the exact (or fuzzy) candidates of a name; see the
# header for the order of the criteria. Returns NULL when no candidate is a
# genus or a rank above genus, else list(choice = one-row data frame, note).
ChooseGenusUsage <- function(cands, hints = NULL, known_genera = character(0)) {
  if (is.null(cands) || nrow(cands) == 0) return(NULL)
  cands <- cands[!is.na(cands$rank) & cands$rank %in% c('GENUS', genus_only_higher_ranks), , drop = FALSE]
  if (nrow(cands) == 0) return(NULL)
  cands$status[is.na(cands$status)] <- 'DOUBTFUL'
  notes <- character(0)
  n_kingdoms <- length(unique(na.omit(cands$kingdom)))
  # 1. the source's classification
  sc <- HintScore(cands, hints)
  if (any(sc != 0)) {
    if (length(unique(sc)) > 1 && n_kingdoms > 1)
      notes <- c(notes, sprintf('homonym in %d kingdoms settled by the source classification (%s)', n_kingdoms, HintString(hints)))
    cands <- cands[sc == max(sc), , drop = FALSE]
  }
  # 2. kingdom preference
  if (length(unique(na.omit(cands$kingdom))) > 1) {
    kp <- unname(genus_only_kingdom_preference[cands$kingdom]); kp[is.na(kp)] <- 8
    chosen <- cands$kingdom[which.min(kp)]
    notes <- c(notes, sprintf('homonym across kingdoms (%s): %s preferred', paste(sort(unique(cands$kingdom)), collapse = ', '), chosen))
    cands <- cands[kp == min(kp), , drop = FALSE]
  }
  # 3. standing: accepted genus, accepted higher taxon, synonym higher taxon,
  #    synonym genus, doubtful genus, doubtful higher taxon
  is_genus <- cands$rank == 'GENUS'
  cls <- ifelse(is_genus & cands$status == 'ACCEPTED', 1L,
         ifelse(!is_genus & cands$status == 'ACCEPTED', 2L,
         ifelse(!is_genus & cands$status %in% genus_only_synonym_statuses, 3L,
         ifelse(is_genus & cands$status %in% genus_only_synonym_statuses, 4L,
         ifelse(is_genus, 5L, 6L)))))
  weak <- min(cls) >= 4L
  cands <- cands[cls == min(cls), , drop = FALSE]
  if (min(cls) == 5L) notes <- c(notes, 'only a DOUBTFUL genus usage')
  # 4. several usages of the same standing: a genus the species table already holds, then the lowest key
  if (nrow(cands) > 1) {
    acc <- ifelse(cands$status %in% genus_only_synonym_statuses & !is.na(cands$accepted),
                  sub(' .*$', '', cands$accepted), cands$canonicalName)
    known <- acc %in% known_genera
    if (any(known) && !all(known)) cands <- cands[known, , drop = FALSE]
    if (nrow(cands) > 1) {
      cands <- cands[order(suppressWarnings(as.numeric(cands$key))), , drop = FALSE]
      notes <- c(notes, sprintf('%d usages of equal standing in %s (%s): the first by usage key taken',
                                nrow(cands), cands$kingdom[1], paste(na.omit(unique(cands$family)), collapse = ', ')))
    }
  }
  list(choice = cands[1, , drop = FALSE], note = paste(notes, collapse = '; '), weak = weak)
}

# The rank the GBIF checklists give a name (stage 2b): the exact usages across
# every checklist, their ranked ones (a rank above species, not UNRANKED),
# and the share of those above genus. Returns NULL when there is no ranked
# usage; else list(above = TRUE/FALSE, rank = the modal rank above genus,
# n_above, n_ranked, classification = modal kingdom..family of the usages at
# that rank, with the checklists' kingdom spellings mapped to the backbone's).
ChecklistRank <- function(name, api) {
  u <- api$lookup_all(name)
  if (is.null(u) || nrow(u) == 0) return(NULL)
  u <- u[!is.na(u$canonicalName) & u$canonicalName == name & !is.na(u$rank) &
           !u$rank %in% c(genus_only_species_ranks, 'UNRANKED'), , drop = FALSE]
  if (nrow(u) == 0) return(NULL)
  above <- u$rank %in% genus_only_higher_ranks
  share <- sum(above) / nrow(u)
  out <- list(above = share >= genus_only_checklist_min_share, n_above = sum(above), n_ranked = nrow(u),
              share = share, rank = NA_character_, classification = NULL)
  if (sum(above) > 0) {
    ranks <- table(u$rank[above])
    out$rank <- names(ranks)[which.max(ranks)]
    at <- u[above & u$rank == out$rank, , drop = FALSE]
    Mode <- function(x) { x <- x[!is.na(x) & nzchar(x)]; if (length(x) == 0) NA_character_ else names(which.max(table(x))) }
    cl <- lapply(genus_hint_ranks, function(rk) Mode(at[[rk]]))
    names(cl) <- genus_hint_ranks
    k <- cl$kingdom
    if (!is.na(k) && k %in% names(genus_only_kingdom_synonyms)) cl$kingdom <- unname(genus_only_kingdom_synonyms[k])
    out$classification <- cl
  }
  out
}

RankBySuffix <- function(name) {
  for (s in names(genus_only_rank_suffixes))
    if (grepl(paste0(s, '$'), name)) return(unname(genus_only_rank_suffixes[s]))
  NA_character_
}

GenusCacheRow <- function(taxon, genus = NA_character_, rank = NA_character_, status = NA_character_,
                          match_type, confidence = NA_real_, key = NA_character_, classification = NULL,
                          source = NA_character_, note = NA_character_, hints = NULL) {
  cl <- setNames(rep(NA_character_, length(genus_hint_ranks)), genus_hint_ranks)
  if (!is.null(classification))
    for (rk in genus_hint_ranks) if (!is.null(classification[[rk]]) && !is.na(classification[[rk]][1]) && nzchar(classification[[rk]][1]))
      cl[rk] <- as.character(classification[[rk]][1])
  data.frame(taxon = taxon, genus = genus, rank = rank, gbif_status = status, match_type = match_type,
             gbif_confidence = confidence, gbif_usageKey = as.character(key),
             kingdom = cl[['kingdom']], phylum = cl[['phylum']], class = cl[['class']], order = cl[['order']],
             family = cl[['family']], taxonomy_source = source,
             note = if (is.na(note) || !nzchar(note)) NA_character_ else note,
             hints = HintString(hints), resolved = format(Sys.Date()), stringsAsFactors = FALSE)
}

# Resolve one bare name (stages 0-5 of the header). `cache_genera` is
# CacheGenera(enrich_cache); `api` the GBIF functions (GbifGenusApi() or a
# mock). Returns one row of the genus cache.
ResolveGenusName <- function(name, hints = NULL, cache_genera, api) {
  known <- cache_genera$genus
  # 0. curated higher-rank names
  if (name %in% names(genus_only_higher_rank_names))
    return(GenusCacheRow(name, rank = unname(genus_only_higher_rank_names[name]), match_type = 'curated',
                         source = 'manual', note = 'a group above genus that GBIF carries mostly as a homonymous genus (genus_only_higher_rank_names)',
                         hints = hints))
  # the ranks the checklists give the name: decisive when the backbone is
  # weak (2b), a flag otherwise
  checklist <- NULL
  AboveGenusRow <- function(cl, extra = NULL)
    GenusCacheRow(name, rank = cl$rank, match_type = 'checklists', classification = cl$classification, source = 'GBIF checklists',
                  note = paste(c(sprintf('%d of %d ranked exact usages in the GBIF checklists are above genus (modal rank %s); the backbone has no accepted usage of the name',
                                         cl$n_above, cl$n_ranked, cl$rank), extra), collapse = '; '),
                  hints = hints)
  Flag <- function(row) {
    if (is.null(checklist)) checklist <<- ChecklistRank(name, api)
    if (!is.null(checklist) && checklist$above)
      row$note <- paste(c(row$note[!is.na(row$note)],
                          sprintf('also a higher taxon in the checklists: %d of %d ranked exact usages above genus (%s)',
                                  checklist$n_above, checklist$n_ranked, checklist$rank)), collapse = '; ')
    row
  }
  # 1. the accepted genus of a resolved species
  cg <- cache_genera[cache_genera$genus == name, , drop = FALSE]
  if (nrow(cg) == 1 && HintScore(cg, hints) >= 0)
    return(Flag(GenusCacheRow(name, genus = name, rank = 'GENUS', status = 'ACCEPTED', match_type = 'cache',
                              classification = cg, source = 'enrich_cache',
                              note = sprintf('accepted genus of %d resolved species', cg$n_species), hints = hints)))
  # 2. exact usages of the name in the backbone
  cands <- api$lookup(name)
  if (!is.null(cands)) cands <- cands[!is.na(cands$canonicalName) & cands$canonicalName == name, , drop = FALSE]
  ch <- ChooseGenusUsage(cands, hints, known)
  if (!is.null(ch) && !ch$weak) {
    row <- UsageToCacheRow(name, ch, 'EXACT', api, hints)
    return(if (row$rank == 'GENUS') Flag(row) else row)
  }
  # 2b. the backbone gives nothing or only a synonym / doubtful genus: the checklists decide the rank
  checklist <- ChecklistRank(name, api)
  if (!is.null(checklist) && checklist$above)
    return(AboveGenusRow(checklist, if (!is.null(ch)) sprintf('backbone: only %s %s usage(s)', tolower(ch$choice$status), tolower(ch$choice$rank))))
  if (!is.null(ch)) return(UsageToCacheRow(name, ch, 'EXACT', api, hints))
  # 3. no usage at all: the rank by suffix
  rk <- RankBySuffix(name)
  if (!is.na(rk))
    return(GenusCacheRow(name, rank = rk, match_type = 'suffix', source = 'suffix',
                         note = 'no GBIF usage of this name at any rank; rank from the family-group suffix', hints = hints))
  # 4. fuzzy genus match
  m <- if (nchar(name) >= genus_only_fuzzy_min_length) api$match(name, hints) else NULL
  if (!is.null(m)) {
    m <- m[!is.na(m$matchType) & m$matchType == 'FUZZY' & !is.na(m$rank) & m$rank == 'GENUS' &
             !is.na(m$confidence) & m$confidence >= genus_only_fuzzy_min_confidence &
             !is.na(m$canonicalName) &
             as.integer(utils::adist(name, m$canonicalName)) <= genus_only_fuzzy_max_distance, , drop = FALSE]
    ch <- ChooseGenusUsage(m, hints, known)
    if (!is.null(ch)) return(UsageToCacheRow(name, ch, 'FUZZY', api, hints))
  }
  # 5. unresolved
  GenusCacheRow(name, match_type = 'NONE', note = 'no GBIF usage of this name at any rank and no acceptable fuzzy genus match', hints = hints)
}

# A chosen usage as a cache row: a synonym genus is followed to its accepted
# genus (one more API call), a usage above genus is recorded with its rank.
UsageToCacheRow <- function(name, ch, match_type, api, hints) {
  u <- ch$choice
  note <- ch$note
  if (match_type == 'FUZZY')
    note <- paste(c(sprintf('fuzzy match of %s (confidence %s, %d letter(s) apart)', name, u$confidence,
                            as.integer(utils::adist(name, u$canonicalName))), note[nzchar(note)]), collapse = '; ')
  if (u$rank != 'GENUS')
    return(GenusCacheRow(name, rank = u$rank, status = u$status, match_type = match_type, confidence = u$confidence,
                         key = u$key, classification = u, source = 'GBIF', note = note, hints = hints))
  if (u$status %in% genus_only_synonym_statuses && !is.na(u$acceptedKey)) {
    acc <- api$usage(u$acceptedKey)
    accepted <- sub(' .*$', '', acc$canonicalName)
    note <- paste(c(sprintf('%s is a synonym of %s', u$canonicalName, accepted), note[nzchar(note)]), collapse = '; ')
    return(GenusCacheRow(name, genus = accepted, rank = 'GENUS', status = 'SYNONYM', match_type = match_type,
                         confidence = u$confidence, key = acc$key, classification = acc, source = 'GBIF', note = note, hints = hints))
  }
  GenusCacheRow(name, genus = u$canonicalName, rank = 'GENUS', status = u$status, match_type = match_type,
                confidence = u$confidence, key = u$key, classification = u, source = 'GBIF', note = note, hints = hints)
}

# Resolve the bare names of `genus_only` (columns taxon and, where the frames
# give them, kingdom..family) that are not yet in `genus_cache`; returns the
# cache with the new rows appended. `sleep` is the pause after each name that
# needed the API.
ResolveGenusNames <- function(genus_only, genus_cache, enrich_cache, api = GbifGenusApi(), sleep = 0.25,
                              verbose = TRUE) {
  if (is.null(genus_cache)) genus_cache <- EmptyGenusCache()
  names_todo <- sort(setdiff(unique(genus_only$taxon), genus_cache$taxon))
  if (length(names_todo) == 0) return(genus_cache)
  cache_genera <- CacheGenera(enrich_cache)
  if (verbose) message(sprintf('ResolveGenusNames: %d genus-only names to resolve (%d cached)',
                               length(names_todo), length(unique(genus_only$taxon)) - length(names_todo)))
  rows <- vector('list', length(names_todo))
  for (i in seq_along(names_todo)) {
    nm <- names_todo[i]
    hints <- NameHints(genus_only[genus_only$taxon == nm, , drop = FALSE])
    rows[[i]] <- ResolveGenusName(nm, hints, cache_genera, api)
    if (rows[[i]]$match_type != 'cache' && rows[[i]]$match_type != 'curated' && sleep > 0) Sys.sleep(sleep)
    if (verbose && i %% 50 == 0) message(sprintf('  %d / %d names', i, length(names_todo)))
  }
  new <- do.call(rbind, rows)
  out <- rbind(genus_cache[, genus_cache_columns], new[, genus_cache_columns])
  rownames(out) <- NULL
  out
}

# ---- weighting ----------------------------------------------------------------
# Pass 1 for genus-only rows: the geometric mean per accepted genus and source
# group (dedupe_sources.r: SourceGroup() pools the VertNet dumps), as the
# species path does per species. `dat` needs genus, source_label, source_group,
# source_mass, mass_g and taxon (the bare name as written), plus any of
# kingdom..family.
GenusOnlyValues <- function(dat) {
  need <- c('genus', 'source_label', 'source_group', 'source_mass', 'mass_g', 'taxon')
  if (!all(need %in% names(dat)))
    stop('GenusOnlyValues(): needs columns ', paste(need, collapse = ', '), call. = FALSE)
  dat <- dat[!is.na(dat$genus) & !is.na(dat$mass_g), , drop = FALSE]
  empty <- data.frame(genus = character(0), source_group = character(0), source_label = character(0),
                      source_mass = character(0), taxon_provided = character(0), mass_g = numeric(0),
                      n = integer(0), kingdom = character(0), phylum = character(0), class = character(0),
                      order = character(0), family = character(0), stringsAsFactors = FALSE)
  if (nrow(dat) == 0) return(empty)
  First <- function(x) { x <- x[!is.na(x)]; if (length(x)) as.character(x[1]) else NA_character_ }
  sp <- split(dat, paste(dat$genus, dat$source_group, sep = '\r'))
  out <- do.call(rbind, lapply(sp, function(d) data.frame(
    genus          = d$genus[1],
    source_group   = d$source_group[1],
    source_label   = paste(sort(unique(d$source_label)), collapse = '+'),
    source_mass    = paste(unique(trimws(unlist(strsplit(sort(unique(d$source_mass)), ';', fixed = TRUE)))), collapse = '; '),
    taxon_provided = paste(sort(unique(d$taxon)), collapse = '; '),
    mass_g         = 10^mean(log10(d$mass_g), na.rm = TRUE),
    n              = nrow(d),
    kingdom = if ('kingdom' %in% names(d)) First(d$kingdom) else NA_character_,
    phylum  = if ('phylum'  %in% names(d)) First(d$phylum)  else NA_character_,
    class   = if ('class'   %in% names(d)) First(d$class)   else NA_character_,
    order   = if ('order'   %in% names(d)) First(d$order)   else NA_character_,
    family  = if ('family'  %in% names(d)) First(d$family)  else NA_character_,
    stringsAsFactors = FALSE)))
  out <- out[order(out$genus, out$source_group), ]
  rownames(out) <- NULL
  out
}

# DedupeSources() over the genus x source values with the registry: the same
# edges and tolerances as for species (the de-duplication keys on genus and
# species; a genus-only value has no species, so one pseudo key per genus).
DedupeGenusValues <- function(values, deps) {
  if (nrow(values) == 0) {
    values$independent <- logical(0); values$collapsed_into <- character(0); values$dedupe_rule <- character(0)
    return(list(values = values, pairs = NULL))
  }
  ws <- values
  ws$species <- '[genus-only]'
  dd <- DedupeSources(ws, deps)
  v <- dd$values
  v$species <- NULL
  list(values = v, pairs = dd$pairs)
}

# Pass 2 for genus-only values. variant 'pseudo-taxon' (the default): one
# record per genus, the arithmetic mean of its independent per-source values,
# n_independent the number of those values, source_mass every label; it then
# enters the genus mean with the weight of one species. variant 'per-source':
# one record per independent per-source value, each entering the genus mean
# separately (the alternative weighting, for comparison).
GenusOnlyRecords <- function(values, variant = c('pseudo-taxon', 'per-source')) {
  variant <- match.arg(variant)
  cols <- c('genus', 'mass_g', 'n', 'n_sources', 'n_independent', 'source_mass', 'source_label', 'log10_range',
            'source_dependencies', 'taxon_provided', 'kingdom', 'phylum', 'class', 'order', 'family')
  if (nrow(values) == 0) {
    out <- as.data.frame(setNames(replicate(length(cols), character(0), simplify = FALSE), cols), stringsAsFactors = FALSE)
    for (c in c('mass_g', 'log10_range')) out[[c]] <- numeric(0)
    for (c in c('n', 'n_sources', 'n_independent')) out[[c]] <- integer(0)
    return(out)
  }
  if (!'independent' %in% names(values)) values$independent <- TRUE
  if (!'collapsed_into' %in% names(values)) values$collapsed_into <- NA_character_
  First <- function(x) { x <- x[!is.na(x)]; if (length(x)) as.character(x[1]) else NA_character_ }
  Union <- function(x) paste(unique(trimws(unlist(strsplit(x, ';', fixed = TRUE)))), collapse = '; ')
  if (variant == 'per-source') {
    v <- values[values$independent, , drop = FALSE]
    out <- data.frame(genus = v$genus, mass_g = v$mass_g, n = as.integer(v$n), n_sources = 1L, n_independent = 1L,
                      source_mass = v$source_mass, source_label = v$source_label, log10_range = 0,
                      source_dependencies = NA_character_, taxon_provided = v$taxon_provided,
                      kingdom = v$kingdom, phylum = v$phylum, class = v$class, order = v$order, family = v$family,
                      stringsAsFactors = FALSE)
  } else {
    sp <- split(values, values$genus)
    out <- do.call(rbind, lapply(sp, function(d) {
      ind <- d$independent
      data.frame(
        genus         = d$genus[1],
        mass_g        = mean(d$mass_g[ind]),
        n             = as.integer(sum(d$n)),
        n_sources     = nrow(d),
        n_independent = as.integer(sum(ind)),
        source_mass   = Union(d$source_mass),
        source_label  = paste(sort(unique(d$source_label)), collapse = '; '),
        log10_range   = if (sum(ind) > 1) log10(max(d$mass_g[ind]) / min(d$mass_g[ind])) else 0,
        source_dependencies = if (any(!ind)) paste(paste0(d$source_label[!ind], '<', d$collapsed_into[!ind]), collapse = '; ') else NA_character_,
        taxon_provided = paste(unique(unlist(strsplit(d$taxon_provided, '; ', fixed = TRUE))), collapse = '; '),
        kingdom = First(d$kingdom), phylum = First(d$phylum), class = First(d$class), order = First(d$order), family = First(d$family),
        stringsAsFactors = FALSE)
    }))
  }
  out <- out[order(out$genus), cols]
  rownames(out) <- NULL
  out
}

# The genus table: the arithmetic mean by accepted genus over the species'
# cross-source means (`enriched`: genus, mass_g, n, n_independent, source_mass)
# and the genus-only record(s) of the genus (`records` from
# GenusOnlyRecords()). n sums the records, n_independent the independent
# values; source_mass joins the contributors with '-' as before #49. Rows are
# ordered by genus in the C locale.
GenusLevelTable <- function(enriched, records) {
  Take <- function(d, taxon) data.frame(taxon = taxon, mass_g = d$mass_g, n = d$n, n_independent = d$n_independent,
                                        source_mass = d$source_mass, stringsAsFactors = FALSE)
  g <- rbind(Take(enriched, enriched$genus), Take(records, records$genus))
  g <- g[!is.na(g$taxon) & nchar(g$taxon) > 0, , drop = FALSE]
  if (nrow(g) == 0)
    return(data.frame(taxon = character(0), mass_g = numeric(0), source_mass = character(0), n = numeric(0),
                      n_independent = integer(0), stringsAsFactors = FALSE))
  sp <- split(g, g$taxon)
  out <- data.frame(
    taxon         = names(sp),
    mass_g        = vapply(sp, function(d) mean(d$mass_g), numeric(1)),
    source_mass   = vapply(sp, function(d) paste(d$source_mass, collapse = '-'), character(1)),
    n             = vapply(sp, function(d) sum(d$n, na.rm = TRUE), numeric(1)),
    n_independent = vapply(sp, function(d) as.integer(sum(d$n_independent, na.rm = TRUE)), integer(1)),
    stringsAsFactors = FALSE)
  out <- out[order(out$taxon, method = 'radix'), ]
  rownames(out) <- NULL
  out
}

# The names resolved above genus, one row per name: taxon (as written), rank,
# the kingdom-to-family classification GBIF gives the usage, mass_g (the
# arithmetic mean over the sources' geometric means, as for a genus-only
# record), source_mass, n (rows) and n_independent (sources). The content of
# the optional TaxonBodyMass_HigherRank.csv.
HigherRankRecords <- function(dat) {
  dat <- dat[!is.na(dat$rank) & dat$rank != 'GENUS' & !is.na(dat$mass_g), , drop = FALSE]
  cols <- c('taxon', 'rank', 'kingdom', 'phylum', 'class', 'order', 'family', 'mass_g', 'source_mass', 'n', 'n_independent')
  if (nrow(dat) == 0)
    return(data.frame(taxon = character(0), rank = character(0), kingdom = character(0), phylum = character(0),
                      class = character(0), order = character(0), family = character(0), mass_g = numeric(0),
                      source_mass = character(0), n = integer(0), n_independent = integer(0), stringsAsFactors = FALSE))
  First <- function(x) { x <- x[!is.na(x)]; if (length(x)) as.character(x[1]) else NA_character_ }
  sp <- split(dat, dat$taxon)
  out <- do.call(rbind, lapply(sp, function(d) {
    by_src <- tapply(log10(d$mass_g), d$source_group, mean)
    data.frame(taxon = d$taxon[1], rank = d$rank[1],
               kingdom = First(d$kingdom), phylum = First(d$phylum), class = First(d$class),
               order = First(d$order), family = First(d$family),
               mass_g = signif(mean(10^by_src), 4),
               source_mass = paste(unique(trimws(unlist(strsplit(sort(unique(d$source_mass)), ';', fixed = TRUE)))), collapse = '; '),
               n = nrow(d), n_independent = length(by_src), stringsAsFactors = FALSE)
  }))
  out <- out[order(-out$n, out$taxon), cols]
  rownames(out) <- NULL
  out
}

# ---- report -------------------------------------------------------------------
# reports/genus_only_records.md: how the genus-only names resolved, the names
# above genus and the autotroph genera that left the table, the fuzzy matches
# and homonym choices to check by eye, the synonyms folded, the
# de-duplication of the genus x source values, and the genus-only records
# that disagree with the genus's species values by more than one order of
# magnitude. `res` is the resolution of every bare name of the run (the cache
# rows joined with rows and sources), `removed_autotrophs` the resolved rows
# FilterAutotrophs() removed, `dedupe` the result of DedupeGenusValues(),
# `records` the pseudo-taxon records, `species_genus_means` a data frame
# (genus, species_mean, n_species) of the species path.
WriteGenusOnlyReport <- function(path, res, removed_autotrophs, dedupe, records, species_genus_means, deps,
                                 variant = 'pseudo-taxon') {
  Tab <- function(df) if (nrow(df) == 0) '(none)' else MarkdownTable(df)
  Fmt <- function(x) ifelse(is.na(x), '', formatC(x, digits = 3, format = 'g'))
  rows_total <- sum(res$rows)
  by_type <- aggregate(cbind(names = rep(1L, nrow(res)), rows = res$rows),
                       by = list(match_type = res$match_type, outcome = res$outcome), FUN = sum)
  by_type <- by_type[order(-by_type$rows), ]
  cross <- res[res$outcome == 'genus' & !is.na(res$note) & grepl('also a higher taxon', res$note),
               c('taxon', 'genus', 'kingdom', 'class', 'family', 'rows', 'sources', 'note')]
  higher <- res[res$outcome == 'above genus', ]
  higher <- higher[order(-higher$rows), c('taxon', 'rank', 'match_type', 'kingdom', 'class', 'rows', 'sources', 'gm')]
  names(higher)[names(higher) == 'gm'] <- 'geometric_mean_g'
  higher$geometric_mean_g <- Fmt(higher$geometric_mean_g)
  unres <- res[res$outcome == 'unresolved', c('taxon', 'rows', 'sources', 'note')]
  unres <- unres[order(-unres$rows), ]
  auto <- removed_autotrophs
  fuzzy <- res[res$match_type == 'FUZZY', c('taxon', 'genus', 'gbif_confidence', 'kingdom', 'family', 'rows', 'sources')]
  homonym <- res[!is.na(res$note) & grepl('homonym|equal standing|DOUBTFUL', res$note), c('taxon', 'genus', 'rank', 'kingdom', 'class', 'family', 'rows', 'note')]
  syn <- res[res$outcome == 'genus' & !is.na(res$genus) & res$genus != res$taxon & res$match_type != 'FUZZY',
             c('taxon', 'genus', 'gbif_status', 'kingdom', 'family', 'rows', 'sources')]
  v <- dedupe$values
  dd_tab <- if (!is.null(v) && nrow(v) > 0 && any(!v$independent)) {
    coll <- v[!v$independent, ]
    agg <- aggregate(cbind(values = rep(1L, nrow(coll))),
                     by = list(dropped = coll$source_label, kept = coll$collapsed_into, rule = coll$dedupe_rule), FUN = sum)
    agg[order(-agg$values), ]
  } else data.frame()
  cmp <- merge(records[, c('genus', 'mass_g', 'n_independent', 'source_label')], species_genus_means, by = 'genus')
  cmp$log10_ratio <- log10(cmp$mass_g / cmp$species_mean)
  far <- cmp[abs(cmp$log10_ratio) > 1, ]
  far <- far[order(-abs(far$log10_ratio)), ]
  far_tab <- data.frame(genus = far$genus, genus_only_g = Fmt(far$mass_g), species_mean_g = Fmt(far$species_mean),
                        n_species = far$n_species, log10_ratio = round(far$log10_ratio, 2), sources = far$source_label,
                        stringsAsFactors = FALSE)
  lines <- c(
    sprintf('# Genus-only records -- %s', format(Sys.time(), '%Y-%m-%d %H:%M:%S')),
    '',
    paste('Input records identified to genus only (a cleaned name without an underscore) are resolved at genus rank',
          'through the enrichment cache and the GBIF backbone (R/library/enrich_genus.r, issue #49), filtered with',
          'FilterAutotrophs(), combined as one value per genus and source (geometric mean), de-duplicated with the',
          'registry Bib/source_dependencies.csv and combined as one record per genus (arithmetic mean of the',
          sprintf('independent per-source values; variant: %s) that enters the genus mean of TaxonBodyMass_GenusLevel.csv', variant),
          'with the weight of one species. Names resolving above genus and names no stage resolved leave the table;',
          'the latter are also listed in reports/warnings_taxonomy.md.'),
    '', '## Totals', '',
    MarkdownTable(data.frame(
      quantity = c('genus-only rows', 'distinct bare names', 'names resolved to an accepted genus', '... rows',
                   'distinct accepted genera', 'names resolved above genus', '... rows', 'names unresolved', '... rows',
                   'autotroph genera removed', '... rows', 'genus x source values (after the autotroph filter)',
                   'values collapsed as copies', 'genus-only records (pseudo-taxa)',
                   'records more than 1 log10 from the genus\'s species mean'),
      value = c(rows_total, nrow(res), sum(res$outcome == 'genus'), sum(res$rows[res$outcome == 'genus']),
                length(unique(na.omit(res$genus[res$outcome == 'genus']))),
                sum(res$outcome == 'above genus'), sum(res$rows[res$outcome == 'above genus']),
                sum(res$outcome == 'unresolved'), sum(res$rows[res$outcome == 'unresolved']),
                nrow(auto), sum(auto$rows), if (is.null(v)) 0L else nrow(v), if (is.null(v)) 0L else sum(!v$independent),
                nrow(records), nrow(far)),
      stringsAsFactors = FALSE)),
    '', '## Resolution by stage', '', Tab(by_type),
    '', '## Names resolved above genus (excluded from the genus table)', '', Tab(higher),
    '', '## Autotroph genera removed (FilterAutotrophs() on the resolved classification)', '', Tab(auto),
    '', '## Fuzzy matches accepted (check by eye)', '', Tab(fuzzy),
    '', '## Homonyms and doubtful usages (the choice made; check by eye)', '', Tab(homonym),
    '', '## Genera that the GBIF checklists mostly use for a higher taxon (cross-rank homonyms; check by eye)', '',
    paste('The name is an accepted genus (kept as such) but most checklists use it for a group above genus, e.g. Ensifera,',
          'the hummingbird genus and the orthopteran suborder; a source without classification hints may mean either.'),
    '', Tab(cross),
    '', '## Synonyms and misspellings folded into the accepted genus', '', Tab(syn),
    '', '## Names unresolved (dropped; also in warnings_taxonomy.md)', '', Tab(unres),
    '', '## De-duplication of the genus x source values', '',
    'Values collapsed as copies by the registry or the blind rule (dedupe_sources.r): dropped label, kept label, rule, values.',
    '', Tab(dd_tab),
    '', '## Genus-only records more than one order of magnitude from the genus\'s species values', '',
    paste('The genus-only record against the arithmetic mean of the genus\'s species cross-source means (the two',
          'enter the genus mean with equal weight). Candidates for a sanity rule; nothing is removed here.'),
    '', Tab(far_tab), '')
  writeLines(lines, path)
  invisible(list(higher = higher, unresolved = unres, autotrophs = auto, fuzzy = fuzzy, homonym = homonym, cross = cross,
                 synonyms = syn, dedupe = dd_tab, far = far_tab))
}
