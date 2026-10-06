BackfillRanks <- function(compiled) {
  wd_passes      <- file.path(wd_root, 'sources', 'passes')
  rank_fill_cols <- c('kingdom', 'phylum', 'class', 'order', 'family')

  needs <- which(
    !is.na(compiled$species) &
    rowSums(is.na(compiled[, rank_fill_cols])) > 0
  )
  if (length(needs) == 0) return(compiled)

  message(sprintf('BackfillRanks: %d taxa with resolved species but missing higher ranks...',
                  length(needs)))
  pb <- cli_progress_bar(
    total  = length(needs),
    format = '  Backfill {pb_bar} {pb_current}/{pb_total} | ETA: {pb_eta}'
  )

  for (i in seq_along(needs)) {
    idx <- needs[i]
    cli_progress_update(id = pb)

    tryCatch({
      key <- compiled$gbif_usageKey[idx]

      # For old cache entries without a stored key, fetch it first
      if (is.na(key)) {
        hit <- name_backbone(name = compiled$species[idx], verbose = FALSE)
        key <- hit$usageKey
      }

      if (!is.na(key)) {
        cl <- name_usage(key = key, data = 'parents')$data
        if (is.data.frame(cl) && nrow(cl) > 0) {
          for (rk in rank_fill_cols) {
            if (is.na(compiled[[rk]][idx])) {
              val <- cl$canonicalName[tolower(cl$rank) == rk]
              if (length(val) == 1 && !is.na(val))
                compiled[[rk]][idx] <- iconv(val, to = 'ASCII//TRANSLIT')
            }
          }
        }
      }
      Sys.sleep(0.1)
    }, error = function(e) NULL)

    if (i %% 100 == 0)
      write.csv(compiled, file.path(wd_root, 'tmp', 'enrich_checkpoint.csv'),
                row.names = FALSE)
  }
  cli_progress_done(id = pb)

  n_still <- sum(!is.na(compiled$species) &
                   rowSums(is.na(compiled[, rank_fill_cols])) > 0)
  message(sprintf('  %d taxa still have at least one missing higher rank after backfill.',
                  n_still))
  write.csv(compiled, file.path(wd_passes, 'TaxonBodyMass_rank_backfill_pass.csv'),
            row.names = FALSE)
  compiled
}

##########################################################################
# Catalogue of Life (ChecklistBank) name match: stage 4 of EnrichTaxonomy()
##########################################################################
# Until #103 the stage called api.checklistbank.org/nidx/match, which answers
# only {nidx, matched} (no type, no usage), so it never resolved a name (the
# cache held 0 COL rows against 47,667 GBIF rows). The name-usage matcher of
# the COL checklist (dataset 3LR) returns the matched usage with its status
# and classification. The HTTP call (ColMatchFetch) is separate from the
# parsing (ParseColMatch) and the row update (ColStage) so that
# R/library/tests/test_col_stage.R runs the stage on recorded responses.
#
# Response (verified live 2026-10-06): {type, usage, original, issues, match}.
# `type` is lower case, one of exact, variant, canonical, ambiguous, none,
# unsupported, higherrank. A bare binomial (no authorship) matches as
# `variant`; a misspelt epithet is not fuzzy-matched at species rank but falls
# to `higherrank` with the genus as `usage`; an unknown name is `none` without
# `usage`. `usage` has id (the COL usage key), name, authorship, rank, status
# (accepted, provisionally accepted, synonym, ambiguous synonym, misapplied,
# bare name), namesIndexId and `classification`, a list of {rank, name, id,
# status} from the parent upward; for a synonym it starts with the accepted
# species (Felis concolor -> species Puma concolor, genus Puma, ...). There is
# no numeric confidence.

COL_MATCH_URL <- 'https://api.checklistbank.org/dataset/3LR/match/nameusage'
COL_RANKS     <- c('kingdom', 'phylum', 'class', 'order', 'family', 'genus')
COL_COLUMNS   <- c('col_match_type', 'col_status', 'col_usageKey', 'col_matched_name')

ColMatchFetch <- function(name) {
  resp <- request(COL_MATCH_URL) |>
    req_url_query(q = name) |>
    req_headers('User-Agent' = 'TaxonBodyMassDB/1.0') |>
    req_timeout(10) |>
    req_retry(max_tries = 3, backoff = ~ 10) |>
    req_perform()
  resp_body_json(resp)
}

# The parts of a parsed response the stage uses. match_type, status, usageKey
# and matched_name are recorded for every answer (so the cache shows what COL
# said, higherrank and none included); species and ranks are set only for an
# accepted match: type exact, variant or canonical, usage status accepted,
# provisionally accepted or synonym, and a species-rank name available (the
# usage itself when it is an accepted species, else the species entry of the
# classification, which for a synonym is its accepted species). higherrank
# (COL's own fallback to the genus), ambiguous, none, unsupported and the
# misapplied / ambiguous-synonym / bare-name statuses fill nothing.
ParseColMatch <- function(body) {
  chr1 <- function(x) if (is.null(x) || length(x) == 0 || is.na(x[[1]])) NA_character_ else as.character(x[[1]])
  out  <- list(match_type = NA_character_, status = NA_character_, usageKey = NA_character_,
               matched_name = NA_character_, species = NA_character_,
               ranks = setNames(rep(NA_character_, length(COL_RANKS)), COL_RANKS))
  if (!is.list(body)) return(out)
  out$match_type <- tolower(chr1(body$type))
  usage <- body$usage
  if (!is.list(usage)) return(out)
  out$status       <- tolower(chr1(usage$status))
  out$usageKey     <- chr1(usage$id)
  out$matched_name <- chr1(usage$name)
  if (!isTRUE(out$match_type %in% c('exact', 'variant', 'canonical'))) return(out)
  if (!isTRUE(out$status %in% c('accepted', 'provisionally accepted', 'synonym'))) return(out)

  cl <- usage$classification
  if (!is.list(cl)) cl <- list()
  cl_rank <- vapply(cl, function(x) tolower(chr1(x$rank)), character(1))
  cl_name <- vapply(cl, function(x) chr1(x$name), character(1))
  usage_rank <- tolower(chr1(usage$rank))

  species <- NA_character_
  if (identical(usage_rank, 'species') && out$status != 'synonym') {
    species <- out$matched_name
  } else if (any(cl_rank == 'species', na.rm = TRUE)) {
    species <- cl_name[which(cl_rank == 'species')[1]]
  }
  if (is.na(species)) return(out)
  # a binomial only: drop a subgenus written in brackets (COL's accepted name
  # Dichotomius (Selenocopris) opacus), an infraspecific epithet or an
  # authorship that a usage or classification entry might carry
  species <- sub('^([A-Z][a-z]+)\\s+\\([A-Z][a-z]+\\)\\s+', '\\1 ', species)
  species <- sub('^([A-Z][a-z]+\\s+[a-z][a-z-]+).*', '\\1', species)
  if (!grepl('^[A-Z][a-z]+ [a-z][a-z-]+$', species)) return(out)
  out$species <- species
  for (rk in COL_RANKS) {
    hit <- which(cl_rank == rk)
    if (length(hit) > 0 && !is.na(cl_name[hit[1]])) out$ranks[[rk]] <- cl_name[hit[1]]
  }
  if (is.na(out$ranks[['genus']])) out$ranks[['genus']] <- sub(' .*', '', species)
  out
}

# Runs the COL stage on the rows `idx` of `compiled` (default: every row
# without a species) and returns the updated frame. `fetch(name)` returns the
# parsed response (ColMatchFetch, or a reader of recorded responses in the
# tests). For an accepted match the ranks are NA-filled as in stages 2 to 6
# (so a source's animal ranks survive under a plant kingdom for Part 2b of
# fix_taxonomy_ranks.r), the genus is the accepted species' genus, and
# gbif_family / gbif_order are cleared: on such a row they come from GBIF's
# higher-rank or fuzzy match of a name GBIF could not resolve, and Pass 1 of
# RunMe.r prefers them over family / order. gbif_confidence, gbif_status and
# gbif_usageKey stay as the record of what GBIF returned. A COL answer never
# replaces a species an earlier stage set (#103: no override of GBIF).
ColStage <- function(compiled, idx = which(is.na(compiled$species)), fetch = ColMatchFetch,
                     sleep = 0.5, checkpoint = NULL, progress = TRUE) {
  for (col in COL_COLUMNS) if (!col %in% names(compiled)) compiled[[col]] <- NA_character_
  idx <- idx[is.na(compiled$species[idx])]
  show_bar <- isTRUE(progress) && length(idx) > 0 && requireNamespace('cli', quietly = TRUE)
  if (show_bar)
    pb <- cli::cli_progress_bar(total = length(idx),
                                format = '  COL {cli::pb_bar} {cli::pb_current}/{cli::pb_total} | ETA: {cli::pb_eta}')
  for (i in seq_along(idx)) {
    row  <- idx[i]
    name <- compiled$taxon_provided[row]
    if (show_bar) cli::cli_progress_update(id = pb)
    m <- tryCatch(ParseColMatch(fetch(name)), error = function(e) NULL)
    if (!is.null(m)) {
      compiled$col_match_type[row]   <- m$match_type
      compiled$col_status[row]       <- m$status
      compiled$col_usageKey[row]     <- m$usageKey
      compiled$col_matched_name[row] <- if (is.na(m$matched_name)) NA_character_ else
                                          iconv(m$matched_name, to = 'ASCII//TRANSLIT')
      if (!is.na(m$species)) {
        for (rk in setdiff(COL_RANKS, 'genus')) {
          if (is.na(compiled[[rk]][row]) && !is.na(m$ranks[[rk]]))
            compiled[[rk]][row] <- iconv(m$ranks[[rk]], to = 'ASCII//TRANSLIT')
        }
        compiled$species[row]         <- iconv(m$species, to = 'ASCII//TRANSLIT')
        compiled$genus[row]           <- sub(' .*', '', compiled$species[row])
        compiled$taxonomy_source[row] <- 'COL'
        compiled$species_changed[row] <- !identical(compiled$taxon_provided[row], compiled$species[row])
        for (col in intersect(c('gbif_family', 'gbif_order'), names(compiled)))
          compiled[[col]][row] <- NA_character_
      }
    }
    if (sleep > 0) Sys.sleep(sleep)
    if (!is.null(checkpoint) && i %% 100 == 0)
      write.csv(compiled, checkpoint, row.names = FALSE)
  }
  if (show_bar) cli::cli_progress_done(id = pb)
  compiled
}

EnrichTaxonomy <- function(compiled) {
  wd_passes <- file.path(wd_root, 'sources', 'passes')
  dir.create(wd_passes, showWarnings = FALSE)

  ##########################################################################
  # Stage 0 — Preserve input name; initialise or normalise taxonomy columns
  ##########################################################################
  compiled$taxon_provided  <- gsub('_', ' ', compiled$taxon)
  compiled$species_changed <- FALSE
  compiled$taxonomy_source <- NA_character_

  for (col in c('kingdom', 'phylum', 'class', 'order', 'family', 'genus', 'species')) {
    if (!col %in% names(compiled)) {
      compiled[[col]] <- NA_character_
    } else {
      compiled[[col]] <- iconv(compiled[[col]], from = 'UTF-8', to = 'ASCII//TRANSLIT')
    }
  }

  compiled$gbif_confidence <- NA_real_
  compiled$gbif_status     <- NA_character_
  compiled$gbif_family     <- NA_character_
  compiled$gbif_order      <- NA_character_
  for (col in COL_COLUMNS) compiled[[col]] <- NA_character_   # stage 4 (#103)

  ##########################################################################
  # Stage 1 — GBIF name backbone (chunked batch)
  ##########################################################################
  GBIF_BATCH <- 1000
  n_total    <- nrow(compiled)
  message(sprintf('Stage 1/7: GBIF name backbone (%d taxa in chunks of %d)...',
                  n_total, GBIF_BATCH))

  pb <- cli_progress_bar(
    total  = n_total,
    format = '  GBIF {pb_bar} {pb_current}/{pb_total} | ETA: {pb_eta}'
  )

  gbif_chunk_call <- function(chunk, start, end, max_tries = 3) {
    delays <- c(5, 15, 45)
    for (attempt in seq_len(max_tries)) {
      res <- tryCatch(
        name_backbone_checklist(name_data = chunk, verbose = FALSE,
                                bucket_size = 150, sleep = 2),
        error = function(e) {
          message(sprintf('  GBIF chunk %d-%d attempt %d/%d failed: %s',
                          start, end, attempt, max_tries, e$message))
          NULL
        }
      )
      if (!is.null(res)) return(res)
      if (attempt < max_tries) Sys.sleep(delays[attempt])
    }
    warning(sprintf('GBIF chunk %d-%d failed after %d attempts; those taxa fall through to fallbacks.',
                    start, end, max_tries))
    data.frame(matrix(NA, nrow = nrow(chunk), ncol = 0))
  }

  gbif_chunks <- lapply(seq(1, n_total, by = GBIF_BATCH), function(start) {
    end   <- min(start + GBIF_BATCH - 1, n_total)
    chunk <- data.frame(
      scientificName = compiled$taxon_provided[start:end],
      stringsAsFactors = FALSE
    )
    res <- gbif_chunk_call(chunk, start, end)
    cli_progress_update(id = pb, inc = nrow(chunk))
    res
  })
  cli_progress_done(id = pb)

  gbif_res <- bind_rows(gbif_chunks)

  # Capture GBIF family/order before NA-fill for cross-check in check_enriched (Check 10)
  compiled$gbif_family <- if ('family' %in% names(gbif_res))
    iconv(gbif_res$family, to = 'ASCII//TRANSLIT') else NA_character_
  compiled$gbif_order  <- if ('order' %in% names(gbif_res))
    iconv(gbif_res$order,  to = 'ASCII//TRANSLIT') else NA_character_

  # Enforce confidence threshold: discard species resolution below 75
  if ('confidence' %in% names(gbif_res)) {
    low_conf_idx <- which(!is.na(gbif_res$confidence) & gbif_res$confidence < 75)
    if ('species' %in% names(gbif_res)) gbif_res$species[low_conf_idx] <- NA_character_
  }

  rank_cols <- c('kingdom', 'phylum', 'class', 'order', 'family', 'genus', 'species')
  for (col in rank_cols) {
    if (col %in% names(gbif_res)) {
      fill <- is.na(compiled[[col]]) & !is.na(gbif_res[[col]])
      compiled[[col]][fill] <- iconv(gbif_res[[col]][fill], to = 'ASCII//TRANSLIT')
    }
  }

  # For high-confidence GBIF matches (>=90), override any source-pre-seeded rank
  # values with GBIF's taxonomy — catches cases where a source supplied a wrong
  # higher rank (e.g. a plant class for a fish).
  if ('confidence' %in% names(gbif_res)) {
    high_conf <- !is.na(gbif_res$confidence) & gbif_res$confidence >= 90
    for (col in c('kingdom', 'phylum', 'class', 'order', 'family')) {
      if (col %in% names(gbif_res)) {
        override <- high_conf & !is.na(gbif_res[[col]])
        compiled[[col]][override] <- iconv(gbif_res[[col]][override], to = 'ASCII//TRANSLIT')
      }
    }
  }

  compiled$gbif_confidence <- gbif_res$confidence
  compiled$gbif_status     <- gbif_res$status
  compiled$gbif_usageKey   <- if ('usageKey' %in% names(gbif_res))
    gbif_res$usageKey else NA_real_

  # Strip author citations from GBIF species names (e.g. "Homo sapiens (L., 1758)")
  compiled$species[!is.na(compiled$species)] <- sub(
    '^([A-Z][a-z]+\\s+[a-z][a-z-]+).*', '\\1',
    compiled$species[!is.na(compiled$species)]
  )

  resolved <- !is.na(compiled$species)
  compiled$species_changed[resolved] <-
    compiled$taxon_provided[resolved] != compiled$species[resolved]
  compiled$taxonomy_source[resolved] <- 'GBIF'

  reclassified <- resolved & compiled$species_changed &
    !is.na(compiled$genus) & !startsWith(compiled$species, compiled$genus)
  compiled$genus[reclassified] <- sub(' .*', '', compiled$species[reclassified])

  message(sprintf('  Resolved: %d / %d', sum(resolved), n_total))
  write.csv(compiled, file.path(wd_passes, 'TaxonBodyMass_GBIF_pass.csv'), row.names = FALSE)

  ##########################################################################
  # Stage 2 — NCBI Taxonomy (per-species; fallback)
  ##########################################################################
  needs_ncbi <- which(is.na(compiled$species))
  message(sprintf('Stage 2/7: NCBI Taxonomy (%d taxa)...', length(needs_ncbi)))

  pb <- cli_progress_bar(total = length(needs_ncbi),
                         format = '  NCBI {pb_bar} {pb_current}/{pb_total} | ETA: {pb_eta}')

  ncbi_ranks <- c('kingdom', 'phylum', 'class', 'order', 'family', 'genus', 'species')

  for (i in seq_along(needs_ncbi)) {
    idx  <- needs_ncbi[i]
    name <- compiled$taxon_provided[idx]
    cli_progress_update(id = pb)

    tryCatch({
      cl <- suppressMessages(classification(name, db = 'ncbi', rows = 1))[[1]]
      if (is.data.frame(cl) && nrow(cl) > 0) {
        for (rk in ncbi_ranks) {
          if (is.na(compiled[[rk]][idx])) {
            val <- cl$name[tolower(cl$rank) == rk]
            if (length(val) == 1 && !is.na(val))
              compiled[[rk]][idx] <- iconv(val, to = 'ASCII//TRANSLIT')
          }
        }
        if (!is.na(compiled$species[idx])) {
          compiled$taxonomy_source[idx] <- 'NCBI'
          compiled$species_changed[idx] <-
            compiled$taxon_provided[idx] != compiled$species[idx]
          if (compiled$species_changed[idx] && !is.na(compiled$genus[idx]) &&
              !startsWith(compiled$species[idx], compiled$genus[idx]))
            compiled$genus[idx] <- sub(' .*', '', compiled$species[idx])
        }
      }
      Sys.sleep(0.34)
    }, error = function(e) NULL)

    if (i %% 100 == 0)
      write.csv(compiled, file.path(wd_root, 'tmp', 'enrich_checkpoint.csv'),
                row.names = FALSE)
  }
  cli_progress_done(id = pb)

  # NCBI uses 'Metazoa' where others use 'Animalia'
  compiled$kingdom[!is.na(compiled$kingdom) & compiled$kingdom == 'Metazoa'] <- 'Animalia'

  n_ncbi <- sum(!is.na(compiled$species)) - sum(resolved)
  message(sprintf('  Resolved: %d additional', n_ncbi))
  write.csv(compiled, file.path(wd_passes, 'TaxonBodyMass_NCBI_pass.csv'), row.names = FALSE)

  ##########################################################################
  # Stage 3 — WoRMS (batch; marine taxa)
  ##########################################################################
  needs_worms <- which(is.na(compiled$species))
  message(sprintf('Stage 3/7: WoRMS (%d taxa)...', length(needs_worms)))

  WORMS_BATCH <- 50
  pb <- cli_progress_bar(total = length(needs_worms),
                         format = '  WoRMS {pb_bar} {pb_current}/{pb_total} | ETA: {pb_eta}')

  for (batch_start in seq(1, max(length(needs_worms), 1), by = WORMS_BATCH)) {
    batch_idx   <- needs_worms[batch_start:min(batch_start + WORMS_BATCH - 1,
                                               length(needs_worms))]
    batch_names <- compiled$taxon_provided[batch_idx]

    tryCatch({
      recs <- wm_records_names(name = batch_names, marine_only = FALSE)
      for (j in seq_along(batch_idx)) {
        idx    <- batch_idx[j]
        rec_df <- recs[[j]]
        if (is.null(rec_df) || !is.data.frame(rec_df) || nrow(rec_df) == 0) next
        accepted <- rec_df[!is.na(rec_df$status) & rec_df$status == 'accepted', , drop = FALSE]
        best     <- if (nrow(accepted) > 0) accepted[1, ] else rec_df[1, ]
        if (!isTRUE(best$match_type %in% c('exact', 'phonetic', 'near_1'))) next

        worms_ranks <- c('kingdom', 'phylum', 'class', 'order', 'family', 'genus')
        for (rk in worms_ranks) {
          if (is.na(compiled[[rk]][idx]) && !is.null(best[[rk]]) && !is.na(best[[rk]]))
            compiled[[rk]][idx] <- iconv(best[[rk]], to = 'ASCII//TRANSLIT')
        }
        if (!is.null(best$rank) && tolower(best$rank) == 'species' &&
            !is.null(best$scientificname)) {
          compiled$species[idx]  <- iconv(best$scientificname, to = 'ASCII//TRANSLIT')
          compiled$taxonomy_source[idx] <- 'WoRMS'
          compiled$species_changed[idx] <-
            compiled$taxon_provided[idx] != compiled$species[idx]
          if (compiled$species_changed[idx] && !is.na(compiled$genus[idx]) &&
              !startsWith(compiled$species[idx], compiled$genus[idx]))
            compiled$genus[idx] <- sub(' .*', '', compiled$species[idx])
        }
      }
    }, error = function(e) NULL)

    cli_progress_update(id = pb, inc = length(batch_idx))
    Sys.sleep(0.5)
    if (batch_start %% 500 == 1)
      write.csv(compiled, file.path(wd_root, 'tmp', 'enrich_checkpoint.csv'),
                row.names = FALSE)
  }
  cli_progress_done(id = pb)
  write.csv(compiled, file.path(wd_passes, 'TaxonBodyMass_WoRMS_pass.csv'), row.names = FALSE)

  ##########################################################################
  # Stage 4 — Catalogue of Life (ChecklistBank name-usage match; #103)
  ##########################################################################
  needs_col <- which(is.na(compiled$species))
  message(sprintf('Stage 4/7: COL (%d taxa)...', length(needs_col)))
  compiled <- ColStage(compiled, needs_col,
                       checkpoint = file.path(wd_root, 'tmp', 'enrich_checkpoint.csv'))
  message(sprintf('  Resolved: %d additional',
                  sum(!is.na(compiled$taxonomy_source) & compiled$taxonomy_source == 'COL')))
  write.csv(compiled, file.path(wd_passes, 'TaxonBodyMass_COL_pass.csv'), row.names = FALSE)

  ##########################################################################
  # Stage 5 — ITIS (per-species; vertebrates)
  ##########################################################################
  needs_itis <- which(is.na(compiled$species))
  message(sprintf('Stage 5/7: ITIS (%d taxa)...', length(needs_itis)))
  pb <- cli_progress_bar(total = length(needs_itis),
                         format = '  ITIS {pb_bar} {pb_current}/{pb_total} | ETA: {pb_eta}')

  itis_rank_map <- c(kingdom = 'Kingdom', phylum = 'Phylum', class = 'Class',
                     order = 'Order', family = 'Family', genus = 'Genus',
                     species = 'Species')

  for (i in seq_along(needs_itis)) {
    idx  <- needs_itis[i]
    name <- compiled$taxon_provided[idx]
    cli_progress_update(id = pb)

    tryCatch({
      hits <- search_scientific(name)
      if (nrow(hits) == 0) { Sys.sleep(1.0); next }
      tsn  <- hits$tsn[1]
      hier <- hierarchy_full(tsn)
      if (is.null(hier) || nrow(hier) == 0) { Sys.sleep(1.0); next }

      for (rk in names(itis_rank_map)) {
        if (is.na(compiled[[rk]][idx])) {
          val <- hier$taxonname[toupper(hier$rankname) == toupper(itis_rank_map[[rk]])]
          if (length(val) == 1 && !is.na(val))
            compiled[[rk]][idx] <- iconv(val, to = 'ASCII//TRANSLIT')
        }
      }
      if (!is.na(compiled$species[idx])) {
        compiled$taxonomy_source[idx] <- 'ITIS'
        compiled$species_changed[idx] <-
          compiled$taxon_provided[idx] != compiled$species[idx]
        if (compiled$species_changed[idx] && !is.na(compiled$genus[idx]) &&
            !startsWith(compiled$species[idx], compiled$genus[idx]))
          compiled$genus[idx] <- sub(' .*', '', compiled$species[idx])
      }
      Sys.sleep(1.0)
    }, error = function(e) NULL)

    if (i %% 100 == 0)
      write.csv(compiled, file.path(wd_root, 'tmp', 'enrich_checkpoint.csv'),
                row.names = FALSE)
  }
  cli_progress_done(id = pb)
  write.csv(compiled, file.path(wd_passes, 'TaxonBodyMass_ITIS_pass.csv'), row.names = FALSE)

  ##########################################################################
  # Stage 6 — Wikidata SPARQL (batch; last automated fallback)
  ##########################################################################
  needs_wiki <- which(is.na(compiled$species))
  message(sprintf('Stage 6/7: Wikidata SPARQL (%d taxa)...', length(needs_wiki)))
  WIKI_BATCH <- 10
  pb <- cli_progress_bar(total = length(needs_wiki),
                         format = '  Wikidata {pb_bar} {pb_current}/{pb_total} | ETA: {pb_eta}')

  wiki_ranks <- c('kingdom', 'phylum', 'class', 'order', 'family', 'genus', 'species')

  for (batch_start in seq(1, max(length(needs_wiki), 1), by = WIKI_BATCH)) {
    batch_idx   <- needs_wiki[batch_start:min(batch_start + WIKI_BATCH - 1,
                                              length(needs_wiki))]
    batch_names <- compiled$taxon_provided[batch_idx]
    values_str  <- paste(sprintf('"%s"', gsub('"', '\\"', batch_names)), collapse = ' ')

    query <- sprintf(
      'SELECT ?searchName ?rankLabel ?taxonName WHERE {
  VALUES ?searchName { %s }
  ?taxon wdt:P225 ?searchName .
  ?taxon wdt:P171* ?ancestor .
  ?ancestor wdt:P225 ?taxonName .
  ?ancestor wdt:P105 ?rank .
  ?rank rdfs:label ?rankLabel .
  FILTER(LANG(?rankLabel) = "en")
}', values_str)

    tryCatch({
      resp <- request('https://query.wikidata.org/sparql') |>
        req_headers(
          'User-Agent' = 'TaxonBodyMassDB/1.0',
          'Accept'     = 'application/sparql-results+json'
        ) |>
        req_url_query(query = query, format = 'json') |>
        req_retry(max_tries = 3, backoff = ~ 15) |>
        req_perform()

      bindings <- resp_body_json(resp)$results$bindings
      wiki_map <- list()
      for (b in bindings) {
        nm <- b$searchName$value; rk <- b$rankLabel$value; tn <- b$taxonName$value
        if (!nm %in% names(wiki_map)) wiki_map[[nm]] <- list()
        if (!rk %in% names(wiki_map[[nm]])) wiki_map[[nm]][[rk]] <- tn
      }

      for (j in seq_along(batch_idx)) {
        idx  <- batch_idx[j]
        name <- batch_names[j]
        if (!name %in% names(wiki_map)) next
        for (rk in wiki_ranks) {
          if (is.na(compiled[[rk]][idx]) && rk %in% names(wiki_map[[name]]))
            compiled[[rk]][idx] <- iconv(wiki_map[[name]][[rk]], to = 'ASCII//TRANSLIT')
        }
        if (!is.na(compiled$species[idx])) {
          compiled$taxonomy_source[idx] <- 'Wikidata'
          compiled$species_changed[idx] <-
            compiled$taxon_provided[idx] != compiled$species[idx]
          if (compiled$species_changed[idx] && !is.na(compiled$genus[idx]) &&
              !startsWith(compiled$species[idx], compiled$genus[idx]))
            compiled$genus[idx] <- sub(' .*', '', compiled$species[idx])
        }
      }
    }, error = function(e) NULL)

    cli_progress_update(id = pb, inc = length(batch_idx))
    Sys.sleep(1.0)
    if (batch_start %% 100 == 1)
      write.csv(compiled, file.path(wd_root, 'tmp', 'enrich_checkpoint.csv'),
                row.names = FALSE)
  }
  cli_progress_done(id = pb)

  write.csv(compiled, file.path(wd_passes, 'TaxonBodyMass_Wikidata_pass.csv'), row.names = FALSE)

  ##########################################################################
  # Stage 7 — GBIF rank backfill via usageKey classification endpoint
  ##########################################################################
  message('Stage 7/7: GBIF rank backfill (usageKey classification lookup)...')
  compiled <- BackfillRanks(compiled)

  n_unresolved <- sum(is.na(compiled$species))
  message(sprintf('Enrichment complete. %d taxa unresolved after all 7 stages.',
                  n_unresolved))

  compiled
}
