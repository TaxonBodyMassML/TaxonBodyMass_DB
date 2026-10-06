# Citation tooling (issue #1): the decision rules of section 2.3, the
# verification driver, and the review queue.
#
#   ScoreCandidate(parsed, cand)   title_sim, author/year/container/volume/pages agreement,
#                                  computed locally (service scores are never inputs)
#   DecideMatch(ref, cands, ...)   certain / pending / not_found with a reason code,
#                                  the rules of the table in issue #1 section 2.3 (and the
#                                  container_volume_page rule for title-less citations)
#   VerifyReference(ref, cfg, ...) the service calls for one reference and the decision
#   VerifyPrimaryReferences(...)   over a primary_references frame (skips decided rows)
#   WritePendingQueue(...)         appends the undecided pending/not_found rows to
#                                  Bib/pending_citations.csv (append-only, idempotent;
#                                  a key with an unapplied decision is not re-queued)
#   DedupeQueue(queue)             the duplicate rows of the queue (--dedupe-queue)
#   DedupeSciteChecks(scite)       the duplicate rows of Bib/scite_checks.csv (removed by
#                                  line through DropSciteCheckRows())
#   ApplyQueueDecisions(...)       validates the owner's `decision` and applies it
#                                  (1|2|3, doi:..., manual:<Key>, nodoi, self, drop)
#   ScreeningCandidates(...)       the DOIs of a source an agent should screen with Scite
#                                  (selective screening policy, owner decision 2026-10-05)
#   DecideMatchCrossrefOnly(...)   the Crossref-only mode of --verify --crossref-only (owner
#                                  decision 2026-10-06, the backlog while OpenAlex's daily
#                                  budget is small): OpenAlex is never asked, Crossref alone
#                                  accepts under the rules below (reason crossref_only)
#   RecheckCrossrefOnly(row, d)    the full re-check of such a row by a later --verify
#                                  without the flag: upgrade, demote or keep
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
# list(flag, notice, is_retracted, ...). A DOI without a screening row, or
# whose latest row is 'none', carries no notice: under the selective
# screening policy (owner decision 2026-10-05) the Crossref and OpenAlex
# fields alone decide, and a screen is never required for certain.
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
  list(flag = length(notices) > 0, is_retracted = retracted,
       notice = if (length(notices) > 0) paste(unique(notices), collapse = '; ') else NA_character_,
       scite_checked = sv$checked, screening_service = sv$service, gap = sv$gap)
}

ServicesWith <- function(services, nt)
  if (isTRUE(nt$scite_checked) && !is.na(nt$screening_service)) paste0(services, ';', nt$screening_service) else services

# Fields of a decision for one reference, with the top candidates for the queue.
Decision <- function(status, reason, best = NULL, scored = NULL, services, notice = NULL, verification_mode = NA_character_) {
  Fld <- function(col, default) if (is.null(best) || nrow(best) == 0 || is.null(best[[col]])) default else best[[col]][1]
  list(match_status = status, match_reason = reason,
       doi = Fld('doi', NA_character_), title_sim = Fld('title_sim', NA_real_),
       author_match = Fld('author_match', NA), year_match = Fld('year_match', NA),
       container_match = Fld('container_match', NA), volume_match = Fld('volume_match', NA),
       pages_match = Fld('pages_match', NA), openalex_id = Fld('openalex_id', NA_character_),
       is_retracted = if (is.null(notice)) Fld('is_retracted', FALSE) else notice$is_retracted,
       editorial_notice = if (is.null(notice)) NA_character_ else notice$notice,
       services = services, verification_mode = verification_mode,
       candidates = if (is.null(scored)) EmptyCandidates() else scored)
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
                        th = citations_thresholds, services = 'crossref;openalex', crossref_only = FALSE) {
  # Crossref-only mode (owner decision 2026-10-06): its own acceptance rules, below
  if (isTRUE(crossref_only)) return(DecideMatchCrossrefOnly(ref, doi_cands, open_cands, closed_cands, scite, th))
  d <- DecideMatchWith(ref, doi_cands, open_cands, closed_cands, scite, th, services)
  if (!identical(d$match_status, 'self')) d$verification_mode <- 'full'
  # A decision reached while OpenAlex was known to be unavailable (`services`
  # without it; an exhausted quota normally leaves the reference unverified
  # instead, VerifyPrimaryReferences()) is provisional when it rests on the
  # services' agreement or their joint retraction flags: it stays pending with
  # the Crossref candidates attached, is not queued for the owner, and is
  # re-verified by the next --verify. Owner matters (a disagreeing source DOI,
  # grey literature, a notice, a self reference) are decided as usual.
  provisional <- c('doi_resolves', 'two_service_agreement', 'closed_world', 'container_volume_page', 'single_service',
                   'ambiguous', 'weak_match', 'below_threshold', 'no_candidates')
  if (!'openalex' %in% strsplit(services, ';', fixed = TRUE)[[1]] && d$match_reason %in% provisional) {
    d$match_status <- 'pending'; d$match_reason <- 'service_unavailable'
  }
  d
}

DecideMatchWith <- function(ref, doi_cands, open_cands, closed_cands, scite, th, services) {
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
    if (nt$flag) return(Decision('pending', 'retracted', best, sc, svc, nt))
    return(Decision('certain', 'doi_resolves', best, sc, svc, nt))
  }
  # 2. open search and closed world
  sc <- ScoreAll(ref, open_cands, closed_cands)
  if (nrow(sc) == 0) return(Decision('not_found', 'no_candidates', services = services))
  by_doi <- CollapseByDOI(sc)
  best <- by_doi[1, , drop = FALSE]
  grey <- IsGreyLiterature(ref$raw_citation)
  if (is.na(ref$parsed_title) || !nzchar(ref$parsed_title)) {
    # a title-less citation ("Journal volume: pages (year)", ParseJournalOnlyStyle();
    # the PHYLACINE Mass.Source cells): there is no title to compare, so a
    # candidate is the work only when its container (abbreviation-aware),
    # volume, first page and year (within the window) all agree (owner decision
    # 2026-10-06). Both services returning it: certain / container_volume_page;
    # one: pending / single_service; two such DOIs: ambiguous; none: the
    # not_found / grey_literature outcome of a failed search.
    agree <- by_doi$container_match & by_doi$volume_match & by_doi$pages_match & by_doi$year_match
    if (!any(agree)) {
      if (grey) return(Decision('pending', 'grey_literature', best, by_doi, services))
      return(Decision('not_found', 'below_threshold', best, by_doi, services))
    }
    hits <- by_doi[agree, , drop = FALSE]
    best <- hits[1, , drop = FALSE]
    nt <- NoticeFor(best$doi, sc, scite)
    svc <- ServicesWith(services, nt)
    if (nt$flag) return(Decision('pending', 'retracted', best, by_doi, svc, nt))
    if (nrow(hits) > 1) return(Decision('pending', 'ambiguous', best, by_doi, svc, nt))
    both <- all(c('crossref', 'openalex') %in% strsplit(best$services_for_doi, ';', fixed = TRUE)[[1]])
    if (both) return(Decision('certain', 'container_volume_page', best, by_doi, svc, nt))
    return(Decision('pending', 'single_service', best, by_doi, svc, nt))
  }
  if (best$title_sim < th$not_found_sim) {
    if (grey) return(Decision('pending', 'grey_literature', best, by_doi, services))
    return(Decision('not_found', 'below_threshold', best, by_doi, services))
  }
  nt <- NoticeFor(best$doi, sc, scite)
  svc <- ServicesWith(services, nt)
  if (nt$flag) return(Decision('pending', 'retracted', best, by_doi, svc, nt))
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

# ---- Crossref-only mode (owner decision 2026-10-06) ----------------------------------------
# The backlog mode of --verify --crossref-only: OpenAlex is not consulted at
# all (its daily budget under the API key is about 1,000 lookups against some
# 6,300 waiting references), and Crossref alone accepts a reference as
# `certain` / `crossref_only` with `services` 'crossref' and the marker
# `verification_mode` 'crossref_only', under the rules of DecideMatchWith()
# applied to the Crossref candidates alone:
#  (a) a source DOI that resolves at Crossref with author + year agreeing or
#      title_sim >= doi_title_sim (the doi_resolves rule without OpenAlex);
#  (b) a strong best candidate (title_sim >= certain_title_sim, author, year
#      within the window, and one of container / volume / pages) -- what the
#      two-service rule would call single_service, there being one service;
#  (c) a title-less citation whose candidate agrees on container, volume,
#      first page and year (the container_volume_page rule on Crossref alone);
#  (d) a closed-world candidate with title_sim >= closed_world_sim, which stays
#      `certain` / `closed_world` as now.
# Everything else is as in the two-service rules: a runner-up within
# ambiguous_delta under another DOI is `pending` / `ambiguous`, a Crossref
# update-to / updated-by notice (or a screening row) is `pending` /
# `retracted`, a disagreeing or unresolvable source DOI `doi_mismatch`, grey
# literature and the thresholds unchanged; `single_service` and
# `service_unavailable` never arise. OpenAlex rows handed in by mistake are
# dropped before scoring. Rule (c) is applied here so that it holds whether or
# not DecideMatchWith() carries the title-less rule itself (a title-less
# citation it decides single_service on one agreeing DOI is accepted through
# (b); one it leaves below_threshold is re-read for the four-field agreement).
DecideMatchCrossrefOnly <- function(ref, doi_cands = NULL, open_cands = NULL, closed_cands = NULL, scite = NULL,
                                    th = citations_thresholds) {
  OnlyCrossref <- function(x) if (is.null(x) || nrow(x) == 0) x else x[x$service %in% 'crossref', , drop = FALSE]
  d <- DecideMatchWith(ref, OnlyCrossref(doi_cands), OnlyCrossref(open_cands), OnlyCrossref(closed_cands), scite, th, 'crossref')
  if (identical(d$match_status, 'self')) return(d)
  d$verification_mode <- 'crossref_only'
  # (a), (b) and the title-less rule of DecideMatchWith() when it has one: the
  # one service agreed as far as it can
  if (d$match_reason %in% c('doi_resolves', 'single_service')) {
    d$match_status <- 'certain'; d$match_reason <- 'crossref_only'
    return(d)
  }
  # (c) a title-less citation left below the title thresholds: container,
  # volume, first page and year of the Crossref candidates decide
  ref <- as.list(ref)
  titleless <- is.null(ref$parsed_title) || is.na(ref$parsed_title) || !nzchar(ref$parsed_title)
  if (titleless && d$match_reason %in% c('below_threshold', 'grey_literature') && nrow(d$candidates) > 0) {
    by_doi <- d$candidates
    agree <- by_doi$container_match & by_doi$volume_match & by_doi$pages_match & by_doi$year_match
    agree[is.na(agree)] <- FALSE
    if (any(agree)) {
      hits <- by_doi[agree, , drop = FALSE]
      best <- hits[1, , drop = FALSE]
      nt <- NoticeFor(best$doi, by_doi, scite)
      svc <- ServicesWith('crossref', nt)
      if (nt$flag) return(Decision('pending', 'retracted', best, by_doi, svc, nt, 'crossref_only'))
      if (nrow(hits) > 1) return(Decision('pending', 'ambiguous', best, by_doi, svc, nt, 'crossref_only'))
      return(Decision('certain', 'crossref_only', best, by_doi, svc, nt, 'crossref_only'))
    }
  }
  d
}

# The full re-check (Crossref + OpenAlex) of a row accepted in Crossref-only
# mode, by a later --verify without the flag: `row` is the row as it stands
# (certain, verification_mode crossref_only, DOI X), `d` the decision of the
# two-service rules on the same reference. Returns the decision to apply, or
# NULL to keep the row as it is (verified_at stamped):
#  * d certain (two_service_agreement, doi_resolves, closed_world): the
#    upgrade -- OpenAlex agrees (or, on a source DOI, is clean);
#  * d pending / retracted: a notice, applied as always;
#  * OpenAlex returned X too but the rules end pending (an ambiguous twin):
#    the two-service decision stands;
#  * OpenAlex disagrees -- it returned no row for X but a plausible candidate
#    (title_sim >= not_found_sim) under another DOI: `pending` / `doi_mismatch`
#    with both services' candidates attached, for the owner;
#  * OpenAlex is silent on X and offers nothing plausible: the Crossref-only
#    acceptance stands (NULL), and the row is re-checked again next time (the
#    cached responses make that free).
RecheckCrossrefOnly <- function(row, d, th = citations_thresholds) {
  row <- as.list(row)
  if (d$match_status %in% 'certain' || d$match_reason %in% 'retracted') return(d)
  cands <- d$candidates
  if (is.null(cands) || nrow(cands) == 0) return(NULL)
  svc <- if ('services_for_doi' %in% names(cands)) cands$services_for_doi else cands$service
  from_oa <- grepl('openalex', svc, fixed = TRUE)
  same <- !is.na(cands$doi) & !is.na(row$doi) & cands$doi == row$doi
  if (any(from_oa & same)) return(d)
  if (any(from_oa & !same & !is.na(cands$title_sim) & cands$title_sim >= th$not_found_sim)) {
    d$match_status <- 'pending'; d$match_reason <- 'doi_mismatch'
    return(d)
  }
  NULL
}

# ---- the driver --------------------------------------------------------------------------
# The service calls for one reference (cached; offline when cfg$offline and
# everything is cached) and the decision. `reflist` is the compilation's
# deposited reference list (CandidatesFromCompilationReflist()), `scite` the
# rows of ReadSciteChecks(). Returns the decision list (DecideMatch()). With
# `crossref_only` (the mode of --crossref-only, DecideMatchCrossrefOnly()) no
# OpenAlex request is made: the Crossref work or query and the closed-world
# candidates are the whole evidence.
VerifyReference <- function(ref, cfg, reflist = NULL, scite = NULL, crossref_only = FALSE) {
  ref <- as.list(ref)
  if (identical(ref$role, 'self')) return(DecideMatch(ref))
  if (!is.na(ref$raw_doi) && nzchar(ref$raw_doi)) {
    w  <- CrossrefWork(ref$raw_doi, cfg)
    cr <- if (is.null(w)) EmptyCandidates() else NormaliseCrossrefItem(w)
    if (isTRUE(crossref_only)) return(DecideMatch(ref, doi_cands = cr, scite = scite, crossref_only = TRUE))
    oa <- OpenAlexWork(ref$raw_doi, cfg)
    return(DecideMatch(ref, doi_cands = rbind(cr, if (is.null(oa)) EmptyCandidates() else oa), scite = scite))
  }
  query <- if (!is.na(ref$parsed_title)) paste(na.omit(c(ref$parsed_author1, ref$parsed_year, ref$parsed_title,
                                                           ref$parsed_container, ref$parsed_volume, ref$parsed_pages)), collapse = ' ')
           else ref$raw_citation
  cr <- CrossrefQuery(query, cfg)
  closed <- ClosedWorldCandidates(ref, reflist, cfg)
  if (isTRUE(crossref_only)) return(DecideMatch(ref, open_cands = cr, closed_cands = closed, scite = scite, crossref_only = TRUE))
  oa <- if (!is.na(ref$parsed_title)) OpenAlexQuery(ref$parsed_title, ref$parsed_year, cfg)
        else OpenAlexQuery(NA, NA, cfg, search = ref$raw_citation)
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
                'container_match', 'volume_match', 'pages_match', 'openalex_id', 'is_retracted', 'editorial_notice',
                'verification_mode'))
    prim[[col]][i] <- if (is.null(d[[col]])) NA else d[[col]]
  prim$verified_at[i]  <- verified_at
  prim$tool_version[i] <- citations_tool_version
  prim
}

# Verify every row of `prim` whose status is not final (NA, pending, not_found;
# certain is re-verified only with force = TRUE; approved, nodoi_approved,
# rejected and self are never touched). Rows without a raw_citation (a key the
# reference list lacks) are skipped. Returns list(prim, candidates, skipped,
# quota, rechecked): the candidates are scored candidate frames keyed by
# native_key for WritePendingQueue(); `skipped` names the references a spent
# service quota (CachedGET()'s 'citations_quota' condition) left unverified
# and `quota` the condition's message.
#
# Crossref-only mode (`crossref_only = TRUE`, --crossref-only; owner decision
# 2026-10-06): OpenAlex is never asked, DecideMatchCrossrefOnly() decides, and
# only the rows no two-service decision has reached are taken -- unverified
# (NA), pending / service_unavailable and pending / single_service; every
# other pending or not_found row was decided with OpenAlex and is left as it
# is. With `force` every row the normal run would take, and the certain rows,
# are re-decided in Crossref-only form (a two_service_agreement row becomes
# crossref_only). Without the flag a certain row whose verification_mode is
# 'crossref_only' is re-checked in full (RecheckCrossrefOnly(): upgraded,
# demoted to pending / doi_mismatch, or kept); `rechecked` names those rows
# with their outcome. A row whose DOI changes under a new decision loses its
# bibcite / cite_id, as under a queue decision, so that --bib mints or reuses
# a key for the new DOI.
# `min_records`: verify only the keys cited by at least that many records
# (`n_records`); the others keep their status (NA for a new reference, reported
# as unverified, named in `below_min_records`) for a later run -- the owner's
# rule for a large list on one OpenAlex day (Jones_2009, 2026-10-06). The
# default 1 means every key.
VerifyPrimaryReferences <- function(prim, cfg, reflist = NULL, scite = NULL, force = FALSE,
                                    verified_at = format(Sys.time(), '%Y-%m-%dT%H:%M:%SZ', tz = 'UTC'),
                                    progress = interactive(), crossref_only = FALSE, min_records = 1L) {
  if (is.null(prim$verification_mode)) prim$verification_mode <- rep(NA_character_, nrow(prim))
  certain <- prim$match_status %in% 'certain'
  if (isTRUE(crossref_only)) {
    todo <- is.na(prim$match_status) |
            (prim$match_status %in% 'pending' & prim$match_reason %in% c('service_unavailable', 'single_service')) |
            (force & (prim$match_status %in% c('pending', 'not_found') | certain))
    recheck <- rep(FALSE, nrow(prim))
  } else {
    recheck <- certain & prim$verification_mode %in% 'crossref_only'
    todo <- is.na(prim$match_status) | prim$match_status %in% c('pending', 'not_found') | (force & certain) | recheck
  }
  todo <- todo & !is.na(prim$raw_citation) & !(prim$role %in% 'self')
  below <- todo & (is.na(prim$n_records) | prim$n_records < min_records)
  todo  <- todo & !below
  cands <- list()
  skipped <- character(0); quota <- NULL; rechecked <- character(0)
  for (i in which(todo)) {
    d <- tryCatch(VerifyReference(prim[i, ], cfg, reflist, scite, crossref_only = isTRUE(crossref_only)), citations_quota = function(e) e)
    if (inherits(d, 'citations_quota')) {
      # a service's quota is spent: the row keeps its previous status (NA for a
      # new reference) and is reported; the cached responses of the other
      # service are kept for the re-run
      skipped <- c(skipped, prim$native_key[i]); quota <- conditionMessage(d)
      if (progress) cat(sprintf('  %s: left unverified (quota of %s)\n', prim$native_key[i], d$host))
      next
    }
    if (recheck[i] && !force) {
      d <- RecheckCrossrefOnly(prim[i, ], d, cfg$thresholds)
      if (is.null(d)) {
        # OpenAlex silent: the Crossref-only acceptance stands, the attempt is stamped
        prim$verified_at[i] <- verified_at; prim$tool_version[i] <- citations_tool_version
        rechecked[prim$native_key[i]] <- 'kept'
        if (progress) cat(sprintf('  %s: certain (crossref_only) kept, OpenAlex silent\n', prim$native_key[i]))
        next
      }
      rechecked[prim$native_key[i]] <- if (d$match_status == 'certain') sprintf('upgraded to %s', d$match_reason) else sprintf('%s/%s', d$match_status, d$match_reason)
    }
    # a reference the list (or the owner) marked for review is never
    # auto-accepted: it is queued with its candidates (citations_config.r)
    if (!is.na(prim$owner_review[i]) && (d$match_status == 'certain' || d$match_reason %in% 'service_unavailable')) {
      d$match_status <- 'pending'; d$match_reason <- 'owner_review'
    }
    old_doi <- prim$doi[i]
    prim <- ApplyDecisionToRow(prim, i, d, verified_at)
    if (!is.na(old_doi) && !identical(prim$doi[i], old_doi)) { prim$bibcite[i] <- NA_character_; prim$cite_id[i] <- NA_character_ }
    cands[[prim$native_key[i]]] <- d$candidates
    if (progress) cat(sprintf('  %s: %s (%s)\n', prim$native_key[i], d$match_status, d$match_reason))
  }
  self <- prim$role %in% 'self' & is.na(prim$match_status)
  prim$match_status[self] <- 'self'; prim$match_reason[self] <- 'self'
  prim <- ApplySciteChecks(prim, scite, verified_at)
  list(prim = prim, candidates = cands, skipped = skipped, quota = quota, rechecked = rechecked,
       below_min_records = prim$native_key[below])
}

# The screening file is applied to every row with a DOI whatever its status
# (selective screening policy, owner decision 2026-10-05): a row screened by a
# service gains that service in `services`; a notice or a retraction turns a
# certain / approved row back to pending (reason retracted) so that it is
# queued and never auto-accepted (issue #1, F5). A DOI with no screening row,
# or whose latest row is 'none', keeps its status: the Crossref update-to and
# OpenAlex is_retracted fields consulted at --verify are the screen of record,
# and the gap of a 'none' row is only recorded (its stale ';none' suffix and
# 'screening:none' note of the earlier rule are removed). An 'owner-waiver'
# row is kept valid for history (SciteVerdict()) though no longer needed.
ApplySciteChecks <- function(prim, scite, verified_at = format(Sys.time(), '%Y-%m-%dT%H:%M:%SZ', tz = 'UTC')) {
  if (is.null(scite) || nrow(scite) == 0) return(prim)
  for (i in which(!is.na(prim$doi))) {
    sv <- SciteVerdict(prim$doi[i], scite)
    if (!sv$checked && !sv$gap) next
    svc <- strsplit(if (is.na(prim$services[i])) '' else prim$services[i], ';', fixed = TRUE)[[1]]
    svc <- svc[nzchar(svc) & !svc %in% screening_services]
    prim$editorial_notice[i] <- DropGapNote(prim$editorial_notice[i])
    if (sv$gap) { prim$services[i] <- paste(svc, collapse = ';'); next }
    prim$services[i] <- paste(c(svc, sv$service), collapse = ';')
    notice <- c(if (sv$is_retracted) paste0(sv$service, ':retraction'), if (!is.na(sv$notice)) sv$notice)
    if (length(notice) > 0) {
      prim$editorial_notice[i] <- paste(unique(notice), collapse = '; ')
      if (sv$is_retracted) prim$is_retracted[i] <- TRUE
      if (prim$match_status[i] %in% c('certain', 'approved')) {
        prim$match_status[i] <- 'pending'
        prim$match_reason[i] <- 'retracted'
        prim$verified_at[i]  <- verified_at
      }
    }
  }
  prim
}

# The 'screening:none (...)' note the earlier rule wrote on a gap is removed
# from an editorial_notice (NA when nothing else remains).
DropGapNote <- function(notice) {
  if (is.na(notice)) return(NA_character_)
  parts <- trimws(strsplit(notice, ';', fixed = TRUE)[[1]])
  keep <- parts[nzchar(parts) & !grepl('^screening:none', parts)]
  # the gap note itself holds a ';' ("no service answered; stays pending"): drop its tail too
  keep <- keep[!grepl('^stays pending\\)?$', keep)]
  if (length(keep) == 0) NA_character_ else paste(keep, collapse = '; ')
}

# ---- the screening list ------------------------------------------------------------------
# The DOIs of one source an agent should screen with Scite (Consensus as the
# fallback) under the selective screening policy (owner decision 2026-10-05):
# a reference is certain on Crossref + OpenAlex alone, and the screen is
# called for (a) a DOI whose services carry a retraction or correction notice
# (to read the notice type), (b) rows where the two services disagree or only
# one answered (single_service, ambiguous), (c) doubtful identities (grey
# literature, a DOI shared by several keys, a mismatching source DOI, an old
# journal: parsed_year before `old_year`), and (d) a random audit sample of the
# newly certain DOIs (certain rows not yet screened by scite-mcp or
# consensus-mcp): `sample_frac` of them, at least `min_sample`, drawn with a
# seed derived from the source label and `date` (sha1, so that the draw of a
# round can be repeated and the README can say how it was taken). A DOI
# already screened by scite-mcp is listed only when it carries a notice (a
# consensus-mcp row cannot read a notice type, so it does not close a notice
# case). A certain row accepted in Crossref-only mode (verification_mode
# crossref_only; owner decision 2026-10-06) lacks OpenAlex by design and is
# not a disagreement: it waits for the full re-check of the next --verify
# and enters the audit-sample pool like any other certain row. Rows without
# a DOI, self and rejected rows are never listed. Returns
# one row per native key: source_label, native_key, n_records, match_status,
# match_reason, doi, category (notice / disagreement / doubtful /
# audit_sample), reason (the codes of the list, ';'-joined), screened_by (the
# latest screening row of the DOI, '' when none), parsed_year, raw_citation;
# attributes `seed`, `date`, `n_new_certain`, `n_sample`. No network.
ScreeningCandidates <- function(prim, scite = NULL, sample_frac = citations_screening$sample_frac,
                                min_sample = citations_screening$min_sample, old_year = citations_screening$old_year,
                                date = Sys.Date(), seed = NULL) {
  prim <- prim[!is.na(prim$doi) & !prim$match_status %in% c('self', 'rejected') & !prim$role %in% 'self', , drop = FALSE]
  src <- if (nrow(prim) > 0) prim$source_label[1] else NA_character_
  if (is.null(seed)) seed <- ScreeningSeed(src, date)
  Out <- function(d, category, reason) {
    data.frame(source_label = d$source_label, native_key = d$native_key, n_records = d$n_records,
               match_status = d$match_status, match_reason = d$match_reason, doi = d$doi,
               category = rep(category, nrow(d)), reason = rep(reason, nrow(d)),
               screened_by = vapply(d$doi, function(x) LatestScreen(x, scite), character(1), USE.NAMES = FALSE),
               parsed_year = d$parsed_year, raw_citation = d$raw_citation, stringsAsFactors = FALSE)
  }
  empty <- Out(prim[0, , drop = FALSE], character(0), character(0))
  if (nrow(prim) == 0) return(structure(empty, seed = seed, date = format(date), n_new_certain = 0L, n_sample = 0L))
  screened <- vapply(prim$doi, function(x) LatestScreen(x, scite), character(1), USE.NAMES = FALSE)
  by_scite <- screened == 'scite-mcp'
  # (a) a notice from Crossref / OpenAlex (or an earlier screen)
  notice <- prim$match_reason %in% 'retracted' | prim$is_retracted %in% TRUE |
            (!is.na(prim$editorial_notice) & !grepl('^screening:none', prim$editorial_notice))
  # (b) the services disagree or only one answered
  one_service <- vapply(prim$services, function(x) {
    sv <- if (is.na(x)) character(0) else strsplit(x, ';', fixed = TRUE)[[1]]
    !all(c('crossref', 'openalex') %in% sv) }, logical(1), USE.NAMES = FALSE)
  xo <- if (is.null(prim$verification_mode)) rep(FALSE, nrow(prim)) else prim$verification_mode %in% 'crossref_only'
  disagree <- prim$match_reason %in% c('single_service', 'ambiguous') |
              (one_service & prim$match_status %in% c('certain', 'approved', 'pending') & !(xo & prim$match_status %in% 'certain'))
  # (c) doubtful identities
  grey <- prim$match_reason %in% 'grey_literature' |
          vapply(prim$raw_citation, IsGreyLiterature, logical(1), USE.NAMES = FALSE)
  dup  <- prim$doi %in% prim$doi[duplicated(prim$doi)]
  mism <- prim$match_reason %in% 'doi_mismatch'
  old  <- !is.na(prim$parsed_year) & prim$parsed_year < old_year
  rows <- list()
  Add <- function(sel, category, reason) {
    sel <- sel & !(by_scite & category != 'notice')
    if (any(sel)) rows[[length(rows) + 1]] <<- Out(prim[sel, , drop = FALSE], category, reason)
  }
  Add(notice, 'notice', 'retracted')
  Add(disagree & prim$match_reason %in% 'ambiguous', 'disagreement', 'ambiguous')
  Add(disagree & !prim$match_reason %in% 'ambiguous', 'disagreement', 'single_service')
  Add(grey, 'doubtful', 'grey_literature')
  Add(dup, 'doubtful', 'duplicate_doi')
  Add(mism, 'doubtful', 'doi_mismatch')
  Add(old, 'doubtful', 'old_journal')
  listed <- if (length(rows) > 0) do.call(rbind, rows) else empty
  # (d) the audit sample of the newly certain DOIs not listed for another reason
  new_certain <- prim$match_status %in% 'certain' & !screened %in% c('scite-mcp', 'consensus-mcp') &
                 !prim$native_key %in% listed$native_key
  pool <- sort(unique(prim$doi[new_certain]))
  n_sample <- if (length(pool) == 0) 0L else as.integer(min(length(pool), max(min_sample, ceiling(sample_frac * length(pool)))))
  if (n_sample > 0) {
    drawn <- WithSeed(seed, function() pool[sample.int(length(pool), n_sample)])
    sel <- new_certain & prim$doi %in% drawn
    rows[[length(rows) + 1]] <- Out(prim[sel, , drop = FALSE], 'audit_sample', 'audit_sample')
  }
  out <- if (length(rows) > 0) do.call(rbind, rows) else empty
  # one row per key, the categories in priority order, the reasons joined
  if (nrow(out) > 0) {
    out <- out[order(match(out$category, screening_categories), out$native_key, method = 'radix'), , drop = FALSE]
    reasons <- tapply(out$reason, out$native_key, function(r) paste(unique(r), collapse = ';'))
    out <- out[!duplicated(out$native_key), , drop = FALSE]
    out$reason <- unname(reasons[out$native_key])
    out <- out[order(match(out$category, screening_categories), -out$n_records, out$native_key, method = 'radix'), , drop = FALSE]
    rownames(out) <- NULL
  }
  structure(out, seed = seed, date = format(date), n_new_certain = length(pool), n_sample = n_sample)
}

# The checked_by of the DOI's latest screening row ('' when none; the service
# of record of SciteVerdict(), 'none' for an unanswered gap).
LatestScreen <- function(doi, scite) {
  sv <- SciteVerdict(doi, scite)
  if (sv$checked) sv$service else if (sv$gap) 'none' else ''
}

# A seed from the source label and the date of the draw (first seven hex digits
# of their sha1), so that the audit sample of a round can be reproduced.
ScreeningSeed <- function(source_label, date)
  strtoi(substr(digest::digest(paste(source_label, format(date)), algo = 'sha1', serialize = FALSE), 1, 7), 16L)

# Evaluate f() under `seed` and restore the caller's random state.
WithSeed <- function(seed, f) {
  had <- exists('.Random.seed', envir = globalenv(), inherits = FALSE)
  old <- if (had) get('.Random.seed', envir = globalenv()) else NULL
  on.exit(if (had) assign('.Random.seed', old, envir = globalenv()) else
            if (exists('.Random.seed', envir = globalenv(), inherits = FALSE)) rm('.Random.seed', envir = globalenv()))
  set.seed(seed)
  f()
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
# (keyed on source_label + native_key) to the queue file; existing rows are
# never rewritten. A key is already queued when it has an open row (no
# decision) or a recorded decision not yet applied to its row -- the decided_at
# of the queue row differs from the row's (#114 item 4; the Chown and Lislevand
# rounds re-appended such keys): the owner's decision stands until
# --apply-queue. A key whose applied decision left it pending again (a later
# retraction) is a new case and is queued. Rows pending only because a service
# was unavailable (service_unavailable) are not owner decisions and are not
# queued. Returns the queue, with the attribute `skipped_decided` naming the
# keys held back for an unapplied decision.
WritePendingQueue <- function(prim, candidates, path, queued_at = format(Sys.Date())) {
  queue <- ReadPendingQueue(path)
  key_q <- paste(queue$source_label, queue$native_key)
  has_decision <- !is.na(queue$decision) & nzchar(trimws(queue$decision))
  open <- key_q[!has_decision]
  key_p <- paste(prim$source_label, prim$native_key)
  unapplied <- vapply(seq_len(nrow(prim)), function(i) {
    at <- queue$decided_at[has_decision & key_q == key_p[i]]
    length(at) > 0 && !(!is.na(prim$decided_at[i]) && prim$decided_at[i] %in% at)
  }, logical(1))
  todo <- prim$match_status %in% c('pending', 'not_found') & !prim$match_reason %in% 'service_unavailable' & !key_p %in% open
  skipped <- prim$native_key[todo & unapplied]
  todo <- todo & !unapplied
  new <- lapply(which(todo), function(i) QueueRow(prim[i, ], candidates[[prim$native_key[i]]], queued_at))
  if (length(new) > 0) queue <- rbind(queue, do.call(rbind, new))
  rownames(queue) <- NULL
  WritePendingQueueFile(queue, path)
  structure(queue, skipped_decided = skipped)
}

# ---- maintenance: duplicate rows (--dedupe-queue, #114 item 4) ------------------------
# The queue rows that duplicate an earlier row of the same key, each with the
# reason it is removed (the first row of a key is always kept):
#  * `open_duplicate`: an open row (no decision) equal to an earlier row in
#    every case column (everything but queued_at and the decision columns),
#    whether that earlier row is open (an exact re-append) or decided (the
#    re-append of a decided key that --queue made before the rule above);
#  * `same_decision`: a decided row whose key has an earlier decided row with
#    the same decision, decided_by and decided_at (one decision recorded
#    twice; the rows may differ in reason or scite_note).
# Rows of one key that differ in their case columns and both carry a decision,
# or an open row with new candidates, are different cases and are kept.
# Returns list(queue, removed): `removed` has the queue columns plus `row`
# (the position in the file read) and `why`.
queue_case_columns <- setdiff(pending_queue_columns, c('queued_at', 'decision', 'decided_by', 'decided_at'))
DedupeQueue <- function(queue) {
  n <- nrow(queue)
  drop <- rep(FALSE, n); why <- rep(NA_character_, n)
  if (n > 1) {
    key <- paste(queue$source_label, queue$native_key)
    has_decision <- !is.na(queue$decision) & nzchar(trimws(queue$decision))
    Same <- function(a, b, cols) all(vapply(cols, function(col) {
      x <- queue[[col]][a]; y <- queue[[col]][b]
      (is.na(x) && is.na(y)) || (!is.na(x) && !is.na(y) && x == y) }, logical(1)))
    for (j in 2:n) {
      earlier <- which(key[seq_len(j - 1)] == key[j] & !drop[seq_len(j - 1)])
      if (length(earlier) == 0) next
      if (!has_decision[j]) {
        if (any(vapply(earlier, function(i) Same(i, j, queue_case_columns), logical(1)))) { drop[j] <- TRUE; why[j] <- 'open_duplicate' }
      } else {
        dec <- earlier[has_decision[earlier]]
        if (any(vapply(dec, function(i) Same(i, j, c('decision', 'decided_by', 'decided_at')), logical(1)))) { drop[j] <- TRUE; why[j] <- 'same_decision' }
      }
    }
  }
  removed <- queue[drop, , drop = FALSE]
  removed$row <- which(drop); removed$why <- why[drop]
  kept <- queue[!drop, , drop = FALSE]
  rownames(kept) <- NULL; rownames(removed) <- NULL
  list(queue = kept, removed = removed)
}

# The screening rows that duplicate another row of the same DOI: an exact
# duplicate, an earlier row of the same DOI and service (the latest row per
# DOI + service is kept, by checked_at then position), and a `none` row (a
# recorded gap) for a DOI that another row answers (the gap is closed; the
# Smith_2003 round recorded 30 such pairs, a `none` row then an owner-waiver
# row). Returns list(scite, removed) with `row` and `why` on `removed`.
DedupeSciteChecks <- function(scite) {
  n <- nrow(scite)
  drop <- rep(FALSE, n); why <- rep(NA_character_, n)
  if (n > 1) {
    all_cols <- do.call(paste, c(lapply(scite_check_columns, function(col) ifelse(is.na(scite[[col]]), '', scite[[col]])), sep = '\r'))
    dup <- duplicated(all_cols); drop[dup] <- TRUE; why[dup] <- 'exact_duplicate'
    ds <- paste(scite$doi, scite$checked_by)
    for (k in unique(ds[duplicated(ds) & !drop])) {
      i <- which(ds == k & !drop)
      keep <- i[order(ifelse(is.na(scite$checked_at[i]), '', scite$checked_at[i]), i, decreasing = TRUE)][1]
      drop[setdiff(i, keep)] <- TRUE; why[setdiff(i, keep)] <- 'older_same_service'
    }
    answered <- unique(scite$doi[!drop & scite$checked_by != 'none'])
    gap <- !drop & scite$checked_by == 'none' & scite$doi %in% answered
    drop[gap] <- TRUE; why[gap] <- 'gap_answered'
  }
  removed <- scite[drop, , drop = FALSE]
  removed$row <- which(drop); removed$why <- why[drop]
  kept <- scite[!drop, , drop = FALSE]
  rownames(kept) <- NULL; rownames(removed) <- NULL
  list(scite = kept, removed = removed)
}

# Remove the rows `rows` (positions in the frame ReadSciteChecks() read, header
# excluded) from the screening file by line, so that every other line keeps
# its bytes (the file is appended by hand, unquoted, with the DOIs' own case,
# and holds no embedded newlines). Stops if the line count does not match.
DropSciteCheckRows <- function(path, rows) {
  lines <- readLines(path, encoding = 'UTF-8', warn = FALSE)
  n_rows <- nrow(ReadSciteChecks(path))
  if (length(lines) != n_rows + 1L)
    stop(basename(path), ': ', length(lines), ' lines for ', n_rows, ' rows; the file cannot be edited by line', call. = FALSE)
  if (length(rows) > 0) writeLines(lines[-(rows + 1L)], path, useBytes = TRUE)
  invisible(length(rows))
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
# owner_candidate; the candidate must carry `crossref` in its services, since
# the entry is built from the Crossref record -- an OpenAlex-only candidate is
# rejected with the proposal doi: / nodoi, #114 item 3); `doi:` is re-verified through Crossref (approved /
# owner_doi; stops when the DOI does not resolve); `manual:<Key>` records the
# curated-bib key (approved / manual_bib); `nodoi` marks a DOI-less entry to be
# built from the parsed fields (nodoi_approved); `self` and `drop` set those
# statuses and clear the candidate's DOI and agreement (#114 item 5). A row
# whose DOI changes loses its bibcite / cite_id for --bib to re-mint. A
# `certain` row is overridden by a queue row the owner adds by hand with a
# `doi:` decision (re-verified at Crossref). Returns the updated
# primary_references frame. The queue itself is not modified (approval is
# the committed decision).
ApplyQueueDecisions <- function(queue, prim, cfg = NULL) {
  decided <- queue[!is.na(queue$decision) & nzchar(trimws(queue$decision)), , drop = FALSE]
  problems <- character(0)
  # a decision already applied to its row (same decided_at, a final status) is
  # history: the Crossref-record rule below is not re-imposed on it
  Applied <- function(q) {
    i <- which(prim$source_label == q$source_label & prim$native_key == q$native_key)
    length(i) == 1 && !is.na(prim$match_status[i]) && prim$match_status[i] %in% c('approved', 'nodoi_approved', 'rejected', 'self') &&
      !is.na(prim$decided_at[i]) && prim$decided_at[i] == q$decided_at
  }
  for (j in seq_len(nrow(decided))) {
    q <- decided[j, ]
    key <- paste(q$source_label, q$native_key)
    if (!ValidateDecision(q$decision)) { problems <- c(problems, sprintf('%s: decision %s does not match the grammar', key, shQuote(q$decision))); next }
    if (is.na(q$decided_by) || !nzchar(q$decided_by)) problems <- c(problems, sprintf('%s: decided_by is empty', key))
    if (is.na(q$decided_at) || is.na(as.Date(q$decided_at, format = '%Y-%m-%d'))) problems <- c(problems, sprintf('%s: decided_at is not an ISO date', key))
    act <- SplitDecision(q$decision)$action
    if (grepl('^[123]$', act) && (is.na(q[[paste0('c', act, '_doi')]]) || !nzchar(q[[paste0('c', act, '_doi')]])))
      problems <- c(problems, sprintf('%s: candidate %s has no DOI in the queue', key, act))
    else if (grepl('^[123]$', act) && q$source_label %in% prim$source_label && !Applied(q)) {
      # a candidate only OpenAlex returned may have no Crossref record to build
      # the entry from (#114 item 3): the owner checks the DOI and decides
      # doi: (re-verified at Crossref) or nodoi. Only the rows of the source
      # being applied are checked: another source's row cannot be seen as
      # applied from this frame (the Lislevand 24 decision, already applied
      # with bibcite Fry:1988aa, stopped every other source's --apply-queue;
      # Hudson round, 2026-10-06)
      svc <- q[[paste0('c', act, '_services')]]
      svc <- if (is.na(svc)) character(0) else strsplit(svc, ';', fixed = TRUE)[[1]]
      if (!'crossref' %in% svc)
        problems <- c(problems, sprintf('%s: candidate %s (%s) was returned by %s only, so no Crossref record exists to build its entry from; decide doi:%s if the DOI resolves at Crossref, else nodoi',
                                        key, act, q[[paste0('c', act, '_doi')]], if (length(svc) == 0) 'no service' else paste(svc, collapse = ';'), q[[paste0('c', act, '_doi')]]))
    }
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
    old_doi <- prim$doi[i]
    prim$decided_by[i] <- q$decided_by; prim$decided_at[i] <- q$decided_at
    prim$tool_version[i] <- citations_tool_version
    prim$year_override[i] <- parts$year
    if (grepl('^[123]$', dec)) {
      prim$doi[i] <- CleanDOI(q[[paste0('c', dec, '_doi')]]); prim$match_status[i] <- 'approved'
      prim$match_reason[i] <- 'owner_candidate'
      prim$title_sim[i] <- suppressWarnings(as.numeric(q[[paste0('c', dec, '_title_sim')]]))
      prim$services[i] <- q[[paste0('c', dec, '_services')]]
    } else if (startsWith(dec, 'doi:')) {
      # the override path of a certain row as well (#114 item 5): the DOI the
      # owner gives is re-verified at Crossref like any other
      doi <- CleanDOI(sub('^doi:', '', dec))
      if (is.null(cfg)) stop('ApplyQueueDecisions(): a doi: decision needs cfg to re-verify ', doi, call. = FALSE)
      w <- CrossrefWork(doi, cfg)
      if (is.null(w)) stop('decision doi:', doi, ' for ', q$source_label, ' ', q$native_key, ' does not resolve at Crossref', call. = FALSE)
      cand <- ScoreCandidate(prim[i, ], NormaliseCrossrefItem(w))
      prim$doi[i] <- doi; prim$match_status[i] <- 'approved'; prim$match_reason[i] <- 'owner_doi'
      prim$title_sim[i] <- cand$title_sim; prim$author_match[i] <- cand$author_match; prim$year_match[i] <- cand$year_match
      prim$container_match[i] <- cand$container_match; prim$volume_match[i] <- cand$volume_match; prim$pages_match[i] <- cand$pages_match
      prim$openalex_id[i] <- NA_character_; prim$is_retracted[i] <- NA; prim$editorial_notice[i] <- NA_character_
      prim$services[i] <- 'crossref'
      prim$verified_at[i] <- format(Sys.time(), '%Y-%m-%dT%H:%M:%SZ', tz = 'UTC')
    } else if (startsWith(dec, 'manual:')) {
      prim$bibcite[i] <- sub('^manual:', '', dec); prim$cite_id[i] <- NA_character_
      prim$match_status[i] <- 'approved'; prim$match_reason[i] <- 'manual_bib'
    } else if (dec == 'nodoi') {
      prim$match_status[i] <- 'nodoi_approved'; prim$match_reason[i] <- 'owner_nodoi'; prim$doi[i] <- NA_character_
    } else if (dec == 'self') {
      prim$match_status[i] <- 'self'; prim$match_reason[i] <- 'owner_self'; prim$role[i] <- 'self'
      prim <- ClearCandidateFields(prim, i)
    } else if (dec == 'drop') {
      # the best (wrong) candidate's DOI and its agreement are cleared (#114 item 5)
      prim$match_status[i] <- 'rejected'; prim$match_reason[i] <- 'owner_drop'
      prim <- ClearCandidateFields(prim, i)
    }
    # a key minted for another DOI (or for a DOI the row no longer has) is
    # not carried over: --bib mints or reuses one for the new state
    if (!identical(prim$doi[i], old_doi) && !startsWith(dec, 'manual:')) { prim$bibcite[i] <- NA_character_; prim$cite_id[i] <- NA_character_ }
  }
  prim
}

# The candidate-derived fields of a row: the DOI the services proposed, its
# agreement flags, the OpenAlex id and the notices (not raw_doi, the source's
# own text, and not services / verified_at, the record of the attempt).
ClearCandidateFields <- function(prim, i) {
  for (col in c('doi', 'openalex_id', 'editorial_notice')) prim[[col]][i] <- NA_character_
  prim$title_sim[i] <- NA_real_
  for (col in c('author_match', 'year_match', 'container_match', 'volume_match', 'pages_match', 'is_retracted')) prim[[col]][i] <- NA
  prim
}
