# Citation tooling (issue #1): the decision rules of section 2.3, the
# verification driver, and the review queue.
#
#   ScoreCandidate(parsed, cand)   title_sim, author/year/container/volume/pages agreement,
#                                  computed locally (service scores are never inputs)
#   DecideMatch(ref, cands, ...)   certain / pending / not_found with a reason code,
#                                  the rules of the table in issue #1 section 2.3
#   VerifyReference(ref, cfg, ...) the service calls for one reference and the decision
#   VerifyPrimaryReferences(...)   over a primary_references frame (skips decided rows)
#   WritePendingQueue(...)         appends the undecided pending/not_found rows to
#                                  Bib/pending_citations.csv (append-only, idempotent)
#   ApplyQueueDecisions(...)       validates the owner's `decision` and applies it
#                                  (1|2|3, doi:..., manual:<Key>, nodoi, self, drop)
# Only VerifyReference() / ApplyQueueDecisions() with a doi: decision touch the
# services, through verify_services.r (cached). Everything else is offline.

# ---- scoring --------------------------------------------------------------------------
# The locally computed agreement between the parsed reference and one
# candidate row; adds title_sim, author_match, year_match, container_match,
# volume_match, pages_match and n_agree to the row.
ScoreCandidate <- function(parsed, cand, window = citations_thresholds$year_window) {
  if (nrow(cand) == 0) return(cbind(cand, title_sim = numeric(), author_match = logical(), year_match = logical(),
                                     container_match = logical(), volume_match = logical(), pages_match = logical(),
                                     n_agree = integer()))
  cand$title_sim       <- TitleSimilarity(parsed$parsed_title, cand$title)
  cand$author_match    <- vapply(cand$author1, function(a) AuthorMatch(parsed$parsed_author1, a), logical(1), USE.NAMES = FALSE)
  cand$year_match      <- !is.na(parsed$parsed_year) & !is.na(cand$year) & abs(cand$year - parsed$parsed_year) <= window
  cand$container_match <- vapply(cand$container, function(x) ContainerMatch(parsed$parsed_container, x), logical(1), USE.NAMES = FALSE)
  cand$volume_match    <- vapply(cand$volume, function(x) VolumeMatch(parsed$parsed_volume, x), logical(1), USE.NAMES = FALSE)
  cand$pages_match     <- vapply(cand$pages, function(x) PagesMatch(parsed$parsed_pages, x), logical(1), USE.NAMES = FALSE)
  cand$n_agree <- as.integer(cand$author_match) + as.integer(cand$year_match) + as.integer(cand$container_match) +
                  as.integer(cand$volume_match) + as.integer(cand$pages_match)
  rownames(cand) <- NULL
  cand
}

# Pool the candidate frames, drop the excluded work types, score, and order by
# title similarity then agreement count. A DOI returned by several services
# keeps one row per service (DecideMatch() counts the services per DOI).
ScoreAll <- function(parsed, ...) {
  cands <- do.call(rbind, Filter(function(x) !is.null(x) && nrow(x) > 0, list(...)))
  if (is.null(cands) || nrow(cands) == 0) return(ScoreCandidate(parsed, EmptyCandidates()))
  cands <- cands[is.na(cands$type) | !cands$type %in% citations_excluded_types, , drop = FALSE]
  cands <- cands[!is.na(cands$doi), , drop = FALSE]
  sc <- ScoreCandidate(parsed, cands)
  sc[order(-sc$title_sim, -sc$n_agree, sc$service, method = 'radix'), , drop = FALSE]
}

IsGreyLiterature <- function(raw_citation)
  !is.na(raw_citation) && grepl(citations_grey_pattern, tolower(FoldASCII(raw_citation)), perl = TRUE)

# A retraction or editorial notice on a DOI from any of the three sources:
# OpenAlex is_retracted, Crossref update-to / updated-by, Scite. Returns
# list(flag, notice, is_retracted).
NoticeFor <- function(doi, scored, scite) {
  rows <- scored[!is.na(scored$doi) & scored$doi == doi, , drop = FALSE]
  retracted <- any(rows$is_retracted, na.rm = TRUE)
  upd <- unique(na.omit(rows$update_types))
  notices <- character(0)
  if (retracted) notices <- c(notices, 'openalex:is_retracted')
  if (length(upd) > 0) {
    notices <- c(notices, paste0('crossref:', upd))
    if (any(grepl('retract|withdraw|remov', upd, ignore.case = TRUE))) retracted <- TRUE
  }
  sv <- SciteVerdict(doi, scite)
  if (sv$is_retracted) { retracted <- TRUE; notices <- c(notices, paste0(sv$service, ':retraction')) }
  if (!is.na(sv$notice)) notices <- c(notices, sv$notice)
  if (sv$gap) notices <- c(notices, 'screening:none (no service answered; stays pending)')
  list(flag = length(notices) > 0, is_retracted = retracted,
       notice = if (length(notices) > 0) paste(unique(notices), collapse = '; ') else NA_character_,
       scite_checked = sv$checked, screening_service = sv$service, gap = sv$gap)
}

ServicesWith <- function(services, nt)
  if (isTRUE(nt$scite_checked) && !is.na(nt$screening_service)) paste0(services, ';', nt$screening_service) else services

# Fields of a decision for one reference, with the top candidates for the queue.
Decision <- function(status, reason, best = NULL, scored = NULL, services, notice = NULL) {
  Fld <- function(col, default) if (is.null(best) || nrow(best) == 0 || is.null(best[[col]])) default else best[[col]][1]
  list(match_status = status, match_reason = reason,
       doi = Fld('doi', NA_character_), title_sim = Fld('title_sim', NA_real_),
       author_match = Fld('author_match', NA), year_match = Fld('year_match', NA),
       container_match = Fld('container_match', NA), volume_match = Fld('volume_match', NA),
       pages_match = Fld('pages_match', NA), openalex_id = Fld('openalex_id', NA_character_),
       is_retracted = if (is.null(notice)) Fld('is_retracted', FALSE) else notice$is_retracted,
       editorial_notice = if (is.null(notice)) NA_character_ else notice$notice,
       services = services, candidates = if (is.null(scored)) EmptyCandidates() else scored)
}

# The best row per distinct DOI (first in the scored order), with the services
# that returned the DOI joined in `services_for_doi`.
CollapseByDOI <- function(scored) {
  if (nrow(scored) == 0) { scored$services_for_doi <- character(); return(scored) }
  first <- scored[!duplicated(scored$doi), , drop = FALSE]
  first$services_for_doi <- vapply(first$doi, function(d)
    paste(sort(unique(scored$service[scored$doi == d])), collapse = ';'), character(1), USE.NAMES = FALSE)
  first$openalex_id <- vapply(first$doi, function(d) {
    ids <- na.omit(scored$openalex_id[scored$doi == d]); if (length(ids) > 0) ids[1] else NA_character_ }, character(1), USE.NAMES = FALSE)
  first$is_retracted <- vapply(first$doi, function(d) any(scored$is_retracted[scored$doi == d], na.rm = TRUE), logical(1), USE.NAMES = FALSE)
  first$closed_world <- vapply(first$doi, function(d) any(scored$closed_world[scored$doi == d]), logical(1), USE.NAMES = FALSE)
  first
}

# The rules of issue #1 section 2.3 for one reference. `ref` is one row of a
# primary_references frame (a list or one-row data frame); `doi_cands` the
# candidate rows for a raw_doi (Crossref work + OpenAlex work), `open_cands`
# the open-search rows of both services, `closed_cands` the rows from the
# compilation's reference list; `scite` the rows of ReadSciteChecks().
DecideMatch <- function(ref, doi_cands = NULL, open_cands = NULL, closed_cands = NULL, scite = NULL,
                        th = citations_thresholds, services = 'crossref;openalex') {
  ref <- as.list(ref)
  if (identical(ref$role, 'self'))
    return(Decision('self', 'self', services = ''))
  # 1. a DOI given by the source
  if (!is.na(ref$raw_doi) && nzchar(ref$raw_doi)) {
    sc <- ScoreAll(ref, doi_cands)
    sc <- sc[!is.na(sc$doi) & sc$doi == CleanDOI(ref$raw_doi), , drop = FALSE]
    if (nrow(sc) == 0) return(Decision('pending', 'doi_mismatch', services = services))
    best <- CollapseByDOI(sc)[1, , drop = FALSE]
    agree <- (isTRUE(best$author_match) && isTRUE(best$year_match)) || best$title_sim >= th$doi_title_sim
    if (!agree) return(Decision('pending', 'doi_mismatch', best, sc, services))
    nt <- NoticeFor(best$doi, sc, scite)
    svc <- ServicesWith(services, nt)
    if (nt$flag) return(Decision('pending', if (nt$gap && !nt$is_retracted) 'unscreened' else 'retracted', best, sc, svc, nt))
    return(Decision('certain', 'doi_resolves', best, sc, svc, nt))
  }
  # 2. open search and closed world
  sc <- ScoreAll(ref, open_cands, closed_cands)
  if (nrow(sc) == 0) return(Decision('not_found', 'no_candidates', services = services))
  by_doi <- CollapseByDOI(sc)
  best <- by_doi[1, , drop = FALSE]
  grey <- IsGreyLiterature(ref$raw_citation)
  if (best$title_sim < th$not_found_sim) {
    if (grey) return(Decision('pending', 'grey_literature', best, by_doi, services))
    return(Decision('not_found', 'below_threshold', best, by_doi, services))
  }
  nt <- NoticeFor(best$doi, sc, scite)
  svc <- ServicesWith(services, nt)
  if (nt$flag) return(Decision('pending', if (nt$gap && !nt$is_retracted) 'unscreened' else 'retracted', best, by_doi, svc, nt))
  if (nrow(by_doi) > 1 && by_doi$title_sim[2] >= best$title_sim - th$ambiguous_delta)
    return(Decision('pending', 'ambiguous', best, by_doi, svc, nt))
  strong <- best$title_sim >= th$certain_title_sim && isTRUE(best$author_match) && isTRUE(best$year_match) &&
            (isTRUE(best$container_match) || isTRUE(best$volume_match) || isTRUE(best$pages_match))
  if (!strong) return(Decision('pending', 'weak_match', best, by_doi, svc, nt))
  both <- all(c('crossref', 'openalex') %in% strsplit(best$services_for_doi, ';', fixed = TRUE)[[1]])
  if (both) return(Decision('certain', 'two_service_agreement', best, by_doi, svc, nt))
  if (isTRUE(best$closed_world) && best$title_sim >= th$closed_world_sim)
    return(Decision('certain', 'closed_world', best, by_doi, svc, nt))
  Decision('pending', 'single_service', best, by_doi, svc, nt)
}

# ---- the driver --------------------------------------------------------------------------
# The service calls for one reference (cached; offline when cfg$offline and
# everything is cached) and the decision. `reflist` is the compilation's
# deposited reference list (CandidatesFromCompilationReflist()), `scite` the
# rows of ReadSciteChecks(). Returns the decision list (DecideMatch()).
VerifyReference <- function(ref, cfg, reflist = NULL, scite = NULL) {
  ref <- as.list(ref)
  if (identical(ref$role, 'self')) return(DecideMatch(ref))
  if (!is.na(ref$raw_doi) && nzchar(ref$raw_doi)) {
    w  <- CrossrefWork(ref$raw_doi, cfg)
    cr <- if (is.null(w)) EmptyCandidates() else NormaliseCrossrefItem(w)
    oa <- OpenAlexWork(ref$raw_doi, cfg)
    return(DecideMatch(ref, doi_cands = rbind(cr, if (is.null(oa)) EmptyCandidates() else oa), scite = scite))
  }
  query <- if (!is.na(ref$parsed_title)) paste(na.omit(c(ref$parsed_author1, ref$parsed_year, ref$parsed_title,
                                                           ref$parsed_container, ref$parsed_volume, ref$parsed_pages)), collapse = ' ')
           else ref$raw_citation
  cr <- CrossrefQuery(query, cfg)
  oa <- if (!is.na(ref$parsed_title)) OpenAlexQuery(ref$parsed_title, ref$parsed_year, cfg)
        else OpenAlexQuery(NA, NA, cfg, search = ref$raw_citation)
  closed <- ClosedWorldCandidates(ref, reflist, cfg)
  # the DOI of a strong candidate is looked up in the other service when that
  # service's own search missed it, so that two_service_agreement can be reached
  # for titles OpenAlex's title.search or Crossref's bibliographic query rank low
  open <- rbind(cr, oa)
  if (nrow(open) > 0 || nrow(closed) > 0) {
    sc <- ScoreAll(ref, open, closed)
    if (nrow(sc) > 0) {
      top <- sc$doi[1]
      have <- unique(sc$service[sc$doi == top])
      if (!'openalex' %in% have) { x <- OpenAlexWork(top, cfg); if (!is.null(x)) oa <- rbind(oa, x) }
      if (!'crossref' %in% have) { w <- CrossrefWork(top, cfg); if (!is.null(w)) cr <- rbind(cr, NormaliseCrossrefItem(w)) }
    }
  }
  DecideMatch(ref, open_cands = rbind(cr, oa), closed_cands = closed, scite = scite)
}

# Decision fields into a primary_references row.
ApplyDecisionToRow <- function(prim, i, d, verified_at) {
  for (col in c('match_status', 'match_reason', 'doi', 'services', 'title_sim', 'author_match', 'year_match',
                'container_match', 'volume_match', 'pages_match', 'openalex_id', 'is_retracted', 'editorial_notice'))
    prim[[col]][i] <- d[[col]]
  prim$verified_at[i]  <- verified_at
  prim$tool_version[i] <- citations_tool_version
  prim
}

# Verify every row of `prim` whose status is not final (NA, pending, not_found;
# certain is re-verified only with force = TRUE; approved, nodoi_approved,
# rejected and self are never touched). Rows without a raw_citation (a key the
# reference list lacks) are skipped. Returns list(prim, candidates), the latter
# a list of scored candidate frames keyed by native_key for WritePendingQueue().
VerifyPrimaryReferences <- function(prim, cfg, reflist = NULL, scite = NULL, force = FALSE,
                                    verified_at = format(Sys.time(), '%Y-%m-%dT%H:%M:%SZ', tz = 'UTC'),
                                    progress = interactive()) {
  todo <- is.na(prim$match_status) | prim$match_status %in% c('pending', 'not_found') |
          (force & prim$match_status == 'certain')
  todo <- todo & !is.na(prim$raw_citation) & !(prim$role %in% 'self')
  cands <- list()
  for (i in which(todo)) {
    d <- VerifyReference(prim[i, ], cfg, reflist, scite)
    prim <- ApplyDecisionToRow(prim, i, d, verified_at)
    cands[[prim$native_key[i]]] <- d$candidates
    if (progress) cat(sprintf('  %s: %s (%s)\n', prim$native_key[i], d$match_status, d$match_reason))
  }
  self <- prim$role %in% 'self' & is.na(prim$match_status)
  prim$match_status[self] <- 'self'; prim$match_reason[self] <- 'self'
  prim <- ApplySciteChecks(prim, scite, verified_at)
  list(prim = prim, candidates = cands)
}

# The screening file is applied to every row with a DOI whatever its status:
# the screening service joins `services`; a notice, a retraction or a 'none'
# row turns a certain / approved row back to pending (reason retracted /
# unscreened) so that it is queued and never auto-accepted (issue #1, F5).
ApplySciteChecks <- function(prim, scite, verified_at = format(Sys.time(), '%Y-%m-%dT%H:%M:%SZ', tz = 'UTC')) {
  if (is.null(scite) || nrow(scite) == 0) return(prim)
  for (i in which(!is.na(prim$doi))) {
    sv <- SciteVerdict(prim$doi[i], scite)
    if (!sv$checked && !sv$gap) next
    svc <- strsplit(if (is.na(prim$services[i])) '' else prim$services[i], ';', fixed = TRUE)[[1]]
    svc <- svc[nzchar(svc) & !svc %in% screening_services]
    prim$services[i] <- paste(c(svc, sv$service), collapse = ';')
    notice <- c(if (sv$is_retracted) paste0(sv$service, ':retraction'), if (!is.na(sv$notice)) sv$notice,
                if (sv$gap) 'screening:none (no service answered; stays pending)')
    if (length(notice) > 0) {
      prim$editorial_notice[i] <- paste(unique(notice), collapse = '; ')
      if (sv$is_retracted) prim$is_retracted[i] <- TRUE
      if (prim$match_status[i] %in% c('certain', 'approved')) {
        prim$match_status[i] <- 'pending'
        prim$match_reason[i] <- if (sv$gap && !sv$is_retracted) 'unscreened' else 'retracted'
        prim$verified_at[i]  <- verified_at
      }
    }
  }
  prim
}

# ---- the review queue ------------------------------------------------------------------
EmptyPendingQueue <- function()
  as.data.frame(setNames(rep(list(character()), length(pending_queue_columns)), pending_queue_columns),
                stringsAsFactors = FALSE)

ReadPendingQueue <- function(path) {
  if (!file.exists(path)) return(EmptyPendingQueue())
  d <- read.csv(path, stringsAsFactors = FALSE, colClasses = 'character', na.strings = c('', 'NA'),
                check.names = FALSE, encoding = 'UTF-8', fileEncoding = 'UTF-8')
  miss <- setdiff(pending_queue_columns, names(d))
  if (length(miss) > 0) stop(basename(path), ' lacks column(s) ', paste(miss, collapse = ', '), call. = FALSE)
  d[, pending_queue_columns]
}

WritePendingQueueFile <- function(queue, path) {
  write.csv(queue[, pending_queue_columns], path, row.names = FALSE, na = '', fileEncoding = 'UTF-8')
  invisible(queue)
}

# One queue row for a pending / not_found reference with its top three
# candidates (`cands`: the scored, DOI-collapsed candidates of the decision).
QueueRow <- function(ref, cands, queued_at) {
  ref <- as.list(ref)
  row <- as.list(setNames(rep(NA_character_, length(pending_queue_columns)), pending_queue_columns))
  row$queued_at <- queued_at
  for (col in c('source_label', 'native_key', 'raw_citation', 'raw_doi', 'parsed_author1', 'parsed_title',
                'parsed_container', 'parsed_volume', 'parsed_pages'))
    row[[col]] <- if (is.null(ref[[col]])) NA_character_ else as.character(ref[[col]])
  row$n_records <- as.character(ref$n_records); row$parsed_year <- as.character(ref$parsed_year)
  row$reason <- ref$match_reason
  if (!is.null(cands) && nrow(cands) > 0) {
    # the open-search decision already hands over the DOI-collapsed frame (with
    # services_for_doi); collapsing it again would recount the services from
    # the one surviving row per DOI and lose the second service
    if (!'services_for_doi' %in% names(cands)) cands <- CollapseByDOI(cands)
    for (k in seq_len(min(3L, nrow(cands)))) {
      row[[paste0('c', k, '_doi')]]       <- cands$doi[k]
      row[[paste0('c', k, '_title')]]     <- cands$title[k]
      row[[paste0('c', k, '_author1')]]   <- cands$author1[k]
      row[[paste0('c', k, '_year')]]      <- as.character(cands$year[k])
      row[[paste0('c', k, '_container')]] <- cands$container[k]
      row[[paste0('c', k, '_title_sim')]] <- as.character(cands$title_sim[k])
      row[[paste0('c', k, '_services')]]  <- cands$services_for_doi[k]
    }
  }
  if (!is.na(ref$editorial_notice)) row$scite_note <- ref$editorial_notice
  as.data.frame(row, stringsAsFactors = FALSE)
}

# Append the pending / not_found rows of `prim` that are not already queued
# without a decision (keyed on source_label + native_key) to the queue file;
# existing rows are never rewritten. Returns the queue.
WritePendingQueue <- function(prim, candidates, path, queued_at = format(Sys.Date())) {
  queue <- ReadPendingQueue(path)
  open <- paste(queue$source_label, queue$native_key)[is.na(queue$decision) | !nzchar(queue$decision)]
  todo <- prim$match_status %in% c('pending', 'not_found') & !paste(prim$source_label, prim$native_key) %in% open
  new <- lapply(which(todo), function(i) QueueRow(prim[i, ], candidates[[prim$native_key[i]]], queued_at))
  if (length(new) > 0) queue <- rbind(queue, do.call(rbind, new))
  rownames(queue) <- NULL
  WritePendingQueueFile(queue, path)
  queue
}

ValidateDecision <- function(decision) grepl(queue_decision_pattern, trimws(decision), perl = TRUE)

# The two parts of a decision: the action ('1', 'doi:10...', 'nodoi', ...) and
# the year override (integer or NA) of a ':year=YYYY' suffix.
SplitDecision <- function(decision) {
  d <- trimws(decision)
  m <- regmatches(d, regexec('^(.*?)(?::year=([0-9]{4}))?$', d, perl = TRUE))[[1]]
  list(action = m[2], year = if (nzchar(m[3])) as.integer(m[3]) else NA_integer_)
}

# Apply the owner's decisions: every queue row with a non-empty `decision`
# must have decided_by and an ISO decided_at, match the grammar and refer to an
# existing reference; `1|2|3` take that candidate's DOI (approved /
# owner_candidate); `doi:` is re-verified through Crossref (approved /
# owner_doi; stops when the DOI does not resolve); `manual:<Key>` records the
# curated-bib key (approved / manual_bib); `nodoi` marks a DOI-less entry to be
# built from the parsed fields (nodoi_approved); `self` and `drop` set those
# statuses. Returns the updated primary_references frame. The queue itself is
# not modified (approval is the committed decision).
ApplyQueueDecisions <- function(queue, prim, cfg = NULL) {
  decided <- queue[!is.na(queue$decision) & nzchar(trimws(queue$decision)), , drop = FALSE]
  problems <- character(0)
  for (j in seq_len(nrow(decided))) {
    q <- decided[j, ]
    key <- paste(q$source_label, q$native_key)
    if (!ValidateDecision(q$decision)) { problems <- c(problems, sprintf('%s: decision %s does not match the grammar', key, shQuote(q$decision))); next }
    if (is.na(q$decided_by) || !nzchar(q$decided_by)) problems <- c(problems, sprintf('%s: decided_by is empty', key))
    if (is.na(q$decided_at) || is.na(as.Date(q$decided_at, format = '%Y-%m-%d'))) problems <- c(problems, sprintf('%s: decided_at is not an ISO date', key))
    act <- SplitDecision(q$decision)$action
    if (grepl('^[123]$', act) && (is.na(q[[paste0('c', act, '_doi')]]) || !nzchar(q[[paste0('c', act, '_doi')]])))
      problems <- c(problems, sprintf('%s: candidate %s has no DOI in the queue', key, act))
    if (!is.na(SplitDecision(q$decision)$year) && !grepl('^([123]|doi:)', act))
      problems <- c(problems, sprintf('%s: a year override needs a candidate or doi: decision', key))
  }
  if (length(problems) > 0)
    stop('pending_citations.csv: ', paste(problems, collapse = '; '), call. = FALSE)
  for (j in seq_len(nrow(decided))) {
    q <- decided[j, ]
    i <- which(prim$source_label == q$source_label & prim$native_key == q$native_key)
    if (length(i) != 1) next           # a decision for another source's reference
    if (!is.na(prim$match_status[i]) && prim$match_status[i] %in% c('approved', 'nodoi_approved', 'rejected') &&
        !is.na(prim$decided_at[i]) && prim$decided_at[i] == q$decided_at) next   # already applied
    parts <- SplitDecision(q$decision)
    dec <- parts$action
    prim$decided_by[i] <- q$decided_by; prim$decided_at[i] <- q$decided_at
    prim$tool_version[i] <- citations_tool_version
    prim$year_override[i] <- parts$year
    if (grepl('^[123]$', dec)) {
      prim$doi[i] <- CleanDOI(q[[paste0('c', dec, '_doi')]]); prim$match_status[i] <- 'approved'
      prim$match_reason[i] <- 'owner_candidate'
      prim$title_sim[i] <- suppressWarnings(as.numeric(q[[paste0('c', dec, '_title_sim')]]))
      prim$services[i] <- q[[paste0('c', dec, '_services')]]
    } else if (startsWith(dec, 'doi:')) {
      doi <- CleanDOI(sub('^doi:', '', dec))
      if (is.null(cfg)) stop('ApplyQueueDecisions(): a doi: decision needs cfg to re-verify ', doi, call. = FALSE)
      w <- CrossrefWork(doi, cfg)
      if (is.null(w)) stop('decision doi:', doi, ' for ', q$source_label, ' ', q$native_key, ' does not resolve at Crossref', call. = FALSE)
      cand <- ScoreCandidate(prim[i, ], NormaliseCrossrefItem(w))
      prim$doi[i] <- doi; prim$match_status[i] <- 'approved'; prim$match_reason[i] <- 'owner_doi'
      prim$title_sim[i] <- cand$title_sim; prim$author_match[i] <- cand$author_match; prim$year_match[i] <- cand$year_match
      prim$container_match[i] <- cand$container_match; prim$volume_match[i] <- cand$volume_match; prim$pages_match[i] <- cand$pages_match
      prim$services[i] <- 'crossref'
      prim$verified_at[i] <- format(Sys.time(), '%Y-%m-%dT%H:%M:%SZ', tz = 'UTC')
    } else if (startsWith(dec, 'manual:')) {
      prim$bibcite[i] <- sub('^manual:', '', dec); prim$match_status[i] <- 'approved'; prim$match_reason[i] <- 'manual_bib'
    } else if (dec == 'nodoi') {
      prim$match_status[i] <- 'nodoi_approved'; prim$match_reason[i] <- 'owner_nodoi'; prim$doi[i] <- NA_character_
    } else if (dec == 'self') {
      prim$match_status[i] <- 'self'; prim$match_reason[i] <- 'owner_self'; prim$role[i] <- 'self'
    } else if (dec == 'drop') {
      prim$match_status[i] <- 'rejected'; prim$match_reason[i] <- 'owner_drop'
    }
  }
  prim
}
