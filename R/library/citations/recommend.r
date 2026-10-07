# Citation tooling (issue #1): a recommended decision for every open row of
# the review queue (the owner decision workflow of the Sheet tab
# BM_decisions, owner decision 2026-10-06).
#
#   FieldsComplete(row), MissingFields(row)   author, year, title and container of a queue row
#   IsJSTOR(doi)                               a 10.2307/ DOI, JSTOR's copy of a published paper
#   CandidateStrong(row, k)                    candidate k reaches accept_sim, its year is within
#                                              year_window of the parsed year, Crossref returned it
#   RecommendRow(row, prim_row)                the first matching rule of the table in the README
#   RecommendDecisions(queue, prim, overwrite) every open row of the queue with its recommendation,
#                                              the rule x source counts as the attribute `counts`
#
# Offline and deterministic: nothing here asks a service, and the same queue
# and primary_references frames always give the same recommendations. A
# recommendation is not a decision. The owner reads it on the tab, fills
# `accept` down the column or types another decision, and only the pulled
# `decision` is ever applied (--apply-queue). A row a session has read by hand
# (`recommended_by` 'agent') or the owner has annotated ('owner') keeps its
# recommendation until --recommend --force; the policy rows are recomputed
# at every run, so a changed threshold or a corrected parsed field shows at
# once. Two of the rules record owner policies of 2026-10-06: twin publisher
# DOIs take the top-scored candidate, and a reference whose fields are
# incomplete and which has no good candidate is recommended `drop` (the owner
# completes `parsed_*` and decides `nodoi` to keep it).

Nz <- function(x) !is.null(x) && length(x) == 1 && !is.na(x) && nzchar(trimws(as.character(x)))

FieldsComplete <- function(row) { row <- as.list(row); all(vapply(c('parsed_author1', 'parsed_year', 'parsed_title', 'parsed_container'), function(col) Nz(row[[col]]), logical(1))) }

MissingFields <- function(row) {
  row <- as.list(row)
  cols <- c('parsed_author1', 'parsed_year', 'parsed_title', 'parsed_container')
  sub('^parsed_', '', cols[!vapply(cols, function(col) Nz(row[[col]]), logical(1))])
}

# A title-less citation whose journal key (container, volume, pages) is whole
# -- the 'Journal volume: pages (year)' shape of the Faurby_etal_2018 list,
# left to the container-filtered query of #128.
HasJournalKey <- function(row) { row <- as.list(row); Nz(row$parsed_container) && Nz(row$parsed_volume) && Nz(row$parsed_pages) }

IsJSTOR <- function(doi) !is.na(doi) && startsWith(tolower(doi), citations_recommend$jstor_prefix)

# Candidate k of a queue row is strong when its title similarity reaches
# `sim`, its year and the parsed year are both known and within
# `year_window`, and (`need_crossref`) Crossref is among the services that
# returned it -- the entry is built from the Crossref record, so an
# OpenAlex-only candidate cannot be accepted as a candidate index (#114
# item 3).
CandidateStrong <- function(row, k, sim = citations_recommend$accept_sim, need_crossref = TRUE) {
  row <- as.list(row)
  doi <- row[[paste0('c', k, '_doi')]]
  if (!Nz(doi)) return(FALSE)
  ts <- suppressWarnings(as.numeric(row[[paste0('c', k, '_title_sim')]]))
  cy <- suppressWarnings(as.integer(row[[paste0('c', k, '_year')]]))
  py <- suppressWarnings(as.integer(row$parsed_year))
  if (is.na(ts) || ts < sim) return(FALSE)
  if (is.na(cy) || is.na(py) || abs(cy - py) > citations_recommend$year_window) return(FALSE)
  if (need_crossref) {
    svc <- row[[paste0('c', k, '_services')]]
    svc <- if (!Nz(svc)) character(0) else strsplit(svc, ';', fixed = TRUE)[[1]]
    if (!'crossref' %in% svc) return(FALSE)
  }
  TRUE
}

# The recommendation of one open queue row: list(recommendation, reason,
# rule), the recommendation NA when the case is the owner's alone. `prim_row`
# is the row's line of primary_references.csv (role, owner_review), or NULL.
RecommendRow <- function(row, prim_row = NULL) {
  row <- as.list(row)
  Out <- function(rec, reason, rule) list(recommendation = rec, reason = reason, rule = rule)
  role   <- if (is.null(prim_row)) NA_character_ else as.character(as.list(prim_row)$role)
  review <- if (is.null(prim_row)) NA_character_ else as.character(as.list(prim_row)$owner_review)
  if (role %in% 'self') return(Out('self', 'role self in primary_references.csv', 'self_role'))
  if (Nz(review)) return(Out(NA_character_, paste0('owner_review: ', trimws(review)), 'owner_review_flagged'))
  if (!Nz(row$parsed_title)) {
    if (HasJournalKey(row)) return(Out(NA_character_, 'title-less journal key: re-verify under #128', 'titleless_journal_key'))
    return(Out('drop', 'no title and no journal key', 'titleless_incomplete'))
  }
  if (row$reason %in% 'retracted') {
    note <- tolower(if (Nz(row$scite_note)) row$scite_note else '')
    if (grepl('correction|erratum|corrigendum', note) && !grepl('retract|withdraw|remov', note) &&
        CandidateStrong(row, 1, sim = citations_recommend$correction_sim))
      return(Out('1', 'notice is a correction, not a retraction', 'correction_notice'))
    return(Out(NA_character_, 'retraction or unread notice', 'retraction_notice'))
  }
  s1 <- CandidateStrong(row, 1); s2 <- CandidateStrong(row, 2)
  j1 <- IsJSTOR(row$c1_doi); j2 <- IsJSTOR(row$c2_doi)
  if (s1 && s2 && xor(j1, j2)) return(Out(if (j1) '2' else '1', 'publisher DOI over the JSTOR twin', 'jstor_twin'))
  if (row$reason %in% 'ambiguous' && s1 && s2 && !j1 && !j2)
    return(Out('1', sprintf('two publisher DOIs (c1 %s, c2 %s): change to 2 if preferred', row$c1_doi, row$c2_doi), 'publisher_twin'))
  if (s1) return(Out('1', sprintf('title_sim %s, year within %d', row$c1_title_sim, citations_recommend$year_window), 'strong_candidate'))
  complete <- FieldsComplete(row)
  if (CandidateStrong(row, 1, need_crossref = FALSE))
    return(Out(if (complete) 'nodoi' else 'drop', sprintf('OpenAlex-only candidate; doi:%s if it resolves at Crossref', row$c1_doi), 'openalex_only_candidate'))
  if (row$reason %in% 'grey_literature' && complete) return(Out('nodoi', 'grey literature, fields complete', 'grey_complete'))
  if (complete)
    return(Out('nodoi', if (Nz(row$c1_doi)) sprintf('best candidate sim %s is another work', row$c1_title_sim) else 'no candidate', 'fields_complete_no_match'))
  Out('drop', sprintf('missing: %s; complete parsed_* and decide nodoi to keep it', paste(MissingFields(row), collapse = ', ')), 'fields_incomplete')
}

# Fill the recommendation block of every open row of `queue` (decided rows
# are untouched): the policy rules are recomputed, agent and owner rows are
# kept unless `overwrite`. `prim` is the primary_references frame of every
# source (LoadPrimaryReferences()), joined on source_label + native_key for
# `role` and `owner_review`; NULL when not available. `sources` restricts
# the run to those labels' rows (--source <Src>); NULL takes every source.
# The attribute `counts` is the rule x source table over the open rows of
# the run (kept agent / owner rows under their own names), `n_open` and
# `n_recommended` the row counts.
RecommendDecisions <- function(queue, prim = NULL, overwrite = FALSE, sources = NULL) {
  open <- is.na(queue$decision) | !nzchar(trimws(queue$decision))
  if (!is.null(sources)) open <- open & queue$source_label %in% sources
  keep <- !overwrite & queue$recommended_by %in% c('agent', 'owner')
  todo <- which(open & !keep)
  pk <- if (is.null(prim)) character(0) else paste(prim$source_label, prim$native_key)
  rule <- rep(NA_character_, nrow(queue))
  for (i in todo) {
    m <- match(paste(queue$source_label[i], queue$native_key[i]), pk)
    r <- RecommendRow(queue[i, ], if (is.na(m)) NULL else prim[m, ])
    queue$recommendation[i] <- r$recommendation
    queue$recommendation_reason[i] <- r$reason
    queue$recommended_by[i] <- paste0('policy:', r$rule)
    rule[i] <- r$rule
  }
  rule[open & keep] <- queue$recommended_by[open & keep]
  counts <- table(rule = factor(rule[open], levels = c(recommend_rules, 'agent', 'owner')),
                  source = factor(queue$source_label[open], levels = sort(unique(queue$source_label[open]))))
  structure(queue, counts = counts, n_open = sum(open), n_recommended = length(todo))
}

# The rule x source counts as a data frame for MarkdownTable(): one row per
# rule that occurs, a column per source, a total column, with the
# recommendation the rule gives.
RecommendationCountsTable <- function(counts) {
  m <- unclass(counts)
  m <- m[rowSums(m) > 0, , drop = FALSE]
  out <- data.frame(rule = rownames(m), stringsAsFactors = FALSE)
  for (src in colnames(m)) out[[src]] <- as.integer(m[, src])
  out$total <- as.integer(rowSums(m))
  rownames(out) <- NULL
  out
}
