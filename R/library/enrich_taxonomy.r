EnrichTaxonomy <- function(compiled) {
  library(rgbif)
  library(taxize)
  library(worrms)
  library(ritis)
  library(httr2)
  library(cli)
  library(dplyr)

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

  ##########################################################################
  # Stage 1 — GBIF name backbone (chunked batch)
  ##########################################################################
  GBIF_BATCH <- 1000
  n_total    <- nrow(compiled)
  message(sprintf('Stage 1/6: GBIF name backbone (%d taxa in chunks of %d)...',
                  n_total, GBIF_BATCH))

  pb <- cli_progress_bar(
    total  = n_total,
    format = '  GBIF {pb_bar} {pb_current}/{pb_total} | ETA: {pb_eta}'
  )

  gbif_chunk_call <- function(chunk, start, end, max_tries = 3) {
    delays <- c(5, 15, 45)
    for (attempt in seq_len(max_tries)) {
      res <- tryCatch(
        name_backbone_checklist(nameUsage = chunk, verbose = FALSE),
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
  compiled$gbif_confidence <- gbif_res$confidence
  compiled$gbif_status     <- gbif_res$status

  resolved <- !is.na(compiled$species)
  compiled$species_changed[resolved] <-
    compiled$taxon_provided[resolved] != compiled$species[resolved]
  compiled$taxonomy_source[resolved] <- 'GBIF'
  message(sprintf('  Resolved: %d / %d', sum(resolved), n_total))

  ##########################################################################
  # Stage 2 — NCBI Taxonomy (per-species; fallback)
  ##########################################################################
  needs_ncbi <- which(is.na(compiled$species))
  message(sprintf('Stage 2/6: NCBI Taxonomy (%d taxa)...', length(needs_ncbi)))

  pb <- cli_progress_bar(total = length(needs_ncbi),
                         format = '  NCBI {pb_bar} {pb_current}/{pb_total} | ETA: {pb_eta}')

  ncbi_ranks <- c('kingdom', 'phylum', 'class', 'order', 'family', 'genus', 'species')

  for (i in seq_along(needs_ncbi)) {
    idx  <- needs_ncbi[i]
    name <- compiled$taxon_provided[idx]
    cli_progress_update(id = pb)

    tryCatch({
      cl <- classification(name, db = 'ncbi', rows = 1)[[1]]
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

  ##########################################################################
  # Stage 3 — WoRMS (batch; marine taxa)
  ##########################################################################
  needs_worms <- which(is.na(compiled$species))
  message(sprintf('Stage 3/6: WoRMS (%d taxa)...', length(needs_worms)))

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
        idx      <- batch_idx[j]
        rec_list <- recs[[j]]
        if (is.null(rec_list) || length(rec_list) == 0) next
        best <- Filter(function(r) !is.null(r$status) && r$status == 'accepted', rec_list)
        best <- if (length(best) > 0) best[[1]] else rec_list[[1]]
        if (!best$match_type %in% c('exact', 'phonetic', 'near_1')) next

        worms_ranks <- c('kingdom', 'phylum', 'class', 'order', 'family', 'genus')
        for (rk in worms_ranks) {
          if (is.na(compiled[[rk]][idx]) && !is.null(best[[rk]]))
            compiled[[rk]][idx] <- iconv(best[[rk]], to = 'ASCII//TRANSLIT')
        }
        if (!is.null(best$rank) && tolower(best$rank) == 'species' &&
            !is.null(best$scientificname)) {
          compiled$species[idx]  <- iconv(best$scientificname, to = 'ASCII//TRANSLIT')
          compiled$taxonomy_source[idx] <- 'WoRMS'
          compiled$species_changed[idx] <-
            compiled$taxon_provided[idx] != compiled$species[idx]
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

  ##########################################################################
  # Stage 4 — COL / ChecklistBank (per-species; esp. Squamata)
  ##########################################################################
  needs_col <- which(is.na(compiled$species))
  message(sprintf('Stage 4/6: COL (%d taxa)...', length(needs_col)))
  pb <- cli_progress_bar(total = length(needs_col),
                         format = '  COL {pb_bar} {pb_current}/{pb_total} | ETA: {pb_eta}')

  for (i in seq_along(needs_col)) {
    idx  <- needs_col[i]
    name <- compiled$taxon_provided[idx]
    cli_progress_update(id = pb)

    tryCatch({
      cl <- classification(name, db = 'col', rows = 1)[[1]]
      if (is.data.frame(cl) && nrow(cl) > 0) {
        col_ranks <- c('kingdom', 'phylum', 'class', 'order', 'family', 'genus')
        for (rk in col_ranks) {
          if (is.na(compiled[[rk]][idx])) {
            val <- cl$name[tolower(cl$rank) == rk]
            if (length(val) == 1 && !is.na(val))
              compiled[[rk]][idx] <- iconv(val, to = 'ASCII//TRANSLIT')
          }
        }
        if (is.na(compiled$species[idx])) {
          compiled$species[idx]  <- iconv(name, to = 'ASCII//TRANSLIT')
          compiled$taxonomy_source[idx] <- 'COL'
        }
      }
      Sys.sleep(0.5)
    }, error = function(e) NULL)

    if (i %% 100 == 0)
      write.csv(compiled, file.path(wd_root, 'tmp', 'enrich_checkpoint.csv'),
                row.names = FALSE)
  }
  cli_progress_done(id = pb)

  ##########################################################################
  # Stage 5 — ITIS (per-species; vertebrates)
  ##########################################################################
  needs_itis <- which(is.na(compiled$species))
  message(sprintf('Stage 5/6: ITIS (%d taxa)...', length(needs_itis)))
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
      if (nrow(hits) == 0) { Sys.sleep(0.5); next }
      tsn  <- hits$tsn[1]
      hier <- hierarchy_full(tsn)
      if (is.null(hier) || nrow(hier) == 0) { Sys.sleep(0.5); next }

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
      }
      Sys.sleep(0.5)
    }, error = function(e) NULL)

    if (i %% 100 == 0)
      write.csv(compiled, file.path(wd_root, 'tmp', 'enrich_checkpoint.csv'),
                row.names = FALSE)
  }
  cli_progress_done(id = pb)

  ##########################################################################
  # Stage 6 — Wikidata SPARQL (batch; last automated fallback)
  ##########################################################################
  needs_wiki <- which(is.na(compiled$species))
  message(sprintf('Stage 6/6: Wikidata SPARQL (%d taxa)...', length(needs_wiki)))
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

  n_unresolved <- sum(is.na(compiled$species))
  message(sprintf('Enrichment complete. %d taxa unresolved after all 6 stages.',
                  n_unresolved))

  compiled
}
