# Citation tooling (issue #1): the Crossref and OpenAlex clients.
#
#   CachedGET(url, cfg)                 GET through httr2 with a polite User-Agent, one
#                                       request per second, retries on 429/5xx, and the raw
#                                       body cached under sources/citations_cache/ keyed by
#                                       sha1(url), so that every re-run (and every test, on
#                                       the recorded fixtures) is offline
#   CrossrefQuery(query, cfg)           /works?query.bibliographic=... -> candidates
#   CrossrefWork(doi, cfg)              /works/<doi> -> the full message (reference[],
#                                       update-to, updated-by) or NULL on 404
#   CandidatesFromCompilationReflist()  the compilation paper's deposited reference list
#                                       (closed-world candidates for author-year keys)
#   OpenAlexQuery(title, year, cfg)     /works?filter=title.search:...,publication_year:...
#   OpenAlexWork(doi, cfg)              /works/https://doi.org/<doi> -> is_retracted, type
#   ReadSciteChecks(path)               Bib/scite_checks.csv (written in Claude Code sessions
#                                       from the Scite MCP tools; read-only here)
# Candidates are normalised to one row each: service, doi, title, author1, year,
# container, volume, pages, type, openalex_id, is_retracted, update_types,
# closed_world, score (the service's relevance score, cached but never used by
# decide.r). No Google Scholar.

CitationsConfig <- function(wd_root, offline = FALSE, mailto = NULL) {
  paths <- CitationsPaths(wd_root)
  if (is.null(mailto))
    mailto <- if (offline) 'offline@invalid' else CitationsMailto('crossref', wd_root)
  c(paths, list(mailto = mailto, user_agent = CitationsUserAgent(mailto), offline = offline,
                network = citations_network, thresholds = citations_thresholds))
}

# The cache key is the sha1 of the URL without its mailto parameter, so that the
# cache and the recorded test fixtures do not depend on who ran the tool.
CacheKey <- function(url) digest::digest(sub('[?&]mailto=[^&]*', '', url), algo = 'sha1', serialize = FALSE)

# The cached response of `url` as list(url, status, body, fetched_at, cached), or
# NULL when the cache has none.
ReadCachedResponse <- function(url, cache_dir) {
  key  <- CacheKey(url)
  meta <- file.path(cache_dir, paste0(key, '.meta.json'))
  body <- file.path(cache_dir, paste0(key, '.json'))
  if (!file.exists(meta) || !file.exists(body)) return(NULL)
  m <- jsonlite::fromJSON(meta, simplifyVector = TRUE)
  list(url = url, status = as.integer(m$status), body = readChar(body, file.info(body)$size, useBytes = TRUE),
       fetched_at = m$fetched_at, cached = TRUE)
}

WriteCachedResponse <- function(url, status, body, cache_dir, fetched_at) {
  dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)
  key <- CacheKey(url)
  writeLines(body, file.path(cache_dir, paste0(key, '.json')), useBytes = TRUE)
  writeLines(jsonlite::toJSON(list(url = url, status = status, fetched_at = fetched_at,
                                   tool_version = citations_tool_version), auto_unbox = TRUE, pretty = TRUE),
             file.path(cache_dir, paste0(key, '.meta.json')))
  idx <- file.path(cache_dir, 'index.tsv')
  if (!file.exists(idx)) writeLines('sha1\tstatus\tfetched_at\turl', idx)
  cat(sprintf('%s\t%d\t%s\t%s\n', key, status, fetched_at, url), file = idx, append = TRUE)
  invisible(key)
}

# GET `url`: from the cache when present, else over the network (unless
# cfg$offline, which stops instead) with the politeness settings of
# citations_config.r. 2xx and 404 responses are cached (a 404 from
# /works/<doi> means "no such DOI" and must not be fetched again); anything else
# after the retries is an error.
CachedGET <- function(url, cfg) {
  hit <- ReadCachedResponse(url, cfg$cache_dir)
  if (!is.null(hit)) return(hit)
  if (isTRUE(cfg$offline))
    stop('offline: no cached response for ', url, call. = FALSE)
  host <- sub('^https?://([^/]+)/.*$', '\\1', url)
  req <- httr2::request(url)
  req <- httr2::req_user_agent(req, cfg$user_agent)
  req <- httr2::req_headers(req, Accept = 'application/json')
  req <- httr2::req_throttle(req, rate = cfg$network$rate_per_s, realm = host)
  req <- httr2::req_retry(req, max_tries = cfg$network$max_tries,
                          is_transient = function(resp) httr2::resp_status(resp) %in% cfg$network$transient_status,
                          backoff = function(i) 2^i)
  req <- httr2::req_error(req, is_error = function(resp) FALSE)
  resp <- httr2::req_perform(req)
  status <- httr2::resp_status(resp)
  body <- httr2::resp_body_string(resp)
  fetched_at <- format(Sys.time(), '%Y-%m-%dT%H:%M:%SZ', tz = 'UTC')
  if (status >= 200 && status < 300 || status == 404L)
    WriteCachedResponse(url, status, body, cfg$cache_dir, fetched_at)
  else
    stop('HTTP ', status, ' from ', host, ' for ', url, call. = FALSE)
  list(url = url, status = status, body = body, fetched_at = fetched_at, cached = FALSE)
}

ParseJSON <- function(body) jsonlite::fromJSON(body, simplifyVector = FALSE)

Enc <- function(x) utils::URLencode(enc2utf8(as.character(x)), reserved = TRUE)

# ---- normalised candidate rows -------------------------------------------------------
EmptyCandidates <- function() {
  data.frame(service = character(), doi = character(), title = character(), author1 = character(),
             year = integer(), container = character(), volume = character(), pages = character(),
             type = character(), openalex_id = character(), is_retracted = logical(),
             update_types = character(), closed_world = logical(), score = numeric(),
             stringsAsFactors = FALSE)
}

CandidateRow <- function(service, doi, title, author1, year, container, volume, pages, type,
                         openalex_id = NA_character_, is_retracted = NA, update_types = NA_character_,
                         closed_world = FALSE, score = NA_real_) {
  Chr <- function(x) if (is.null(x) || length(x) == 0 || identical(x, '')) NA_character_ else as.character(x[[1]])
  data.frame(service = service, doi = CleanDOI(Chr(doi)), title = Chr(title), author1 = Chr(author1),
             year = if (is.null(year) || length(year) == 0) NA_integer_ else suppressWarnings(as.integer(year[[1]])),
             container = Chr(container), volume = Chr(volume), pages = Chr(pages), type = Chr(type),
             openalex_id = Chr(openalex_id), is_retracted = if (is.null(is_retracted)) NA else as.logical(is_retracted),
             update_types = Chr(update_types), closed_world = closed_world,
             score = if (is.null(score) || length(score) == 0) NA_real_ else as.numeric(score[[1]]),
             stringsAsFactors = FALSE)
}

# One Crossref work item (the `message` of /works/<doi> or an element of
# /works?query items) as a candidate row.
NormaliseCrossrefItem <- function(item, closed_world = FALSE) {
  title <- if (length(item$title) > 0) item$title[[1]] else NA_character_
  if (length(item$subtitle) > 0 && !is.na(title) && nzchar(item$subtitle[[1]]) &&
      !grepl(tolower(item$subtitle[[1]]), tolower(title), fixed = TRUE))
    title <- paste0(title, ': ', item$subtitle[[1]])
  a1 <- NA_character_
  if (length(item$author) > 0) {
    first <- item$author[[1]]
    seq_first <- which(vapply(item$author, function(a) identical(a$sequence, 'first'), logical(1)))
    if (length(seq_first) > 0) first <- item$author[[seq_first[1]]]
    a1 <- if (!is.null(first$family)) first$family else first$name
  }
  year <- NA_integer_
  for (f in c('issued', 'published-print', 'published-online', 'created')) {
    dp <- item[[f]][['date-parts']]
    if (length(dp) > 0 && length(dp[[1]]) > 0 && !is.null(dp[[1]][[1]])) { year <- as.integer(dp[[1]][[1]]); break }
  }
  upd <- c(vapply(item[['update-to']], function(u) paste0('update-to:', u$type), character(1)),
           vapply(item[['updated-by']], function(u) paste0('updated-by:', u$type), character(1)))
  CandidateRow('crossref', doi = item$DOI, title = title, author1 = a1, year = year,
               container = if (length(item[['container-title']]) > 0) item[['container-title']][[1]] else item$publisher,
               volume = item$volume, pages = item$page, type = item$type,
               update_types = if (length(upd) > 0) paste(upd, collapse = ';') else NA_character_,
               closed_world = closed_world, score = item$score)
}

# One OpenAlex work as a candidate row.
NormaliseOpenAlexItem <- function(w) {
  a1 <- NA_character_
  if (length(w$authorships) > 0) {
    dn <- w$authorships[[1]]$author$display_name
    if (!is.null(dn)) { toks <- strsplit(trimws(dn), '\\s+')[[1]]; a1 <- toks[length(toks)] }
  }
  src <- w$primary_location$source$display_name
  fp <- w$biblio$first_page; lp <- w$biblio$last_page
  pages <- if (is.null(fp)) NA_character_ else if (is.null(lp) || identical(lp, fp)) fp else paste0(fp, '-', lp)
  CandidateRow('openalex', doi = w$doi, title = if (!is.null(w$title)) w$title else w$display_name,
               author1 = a1, year = w$publication_year, container = src, volume = w$biblio$volume,
               pages = pages, type = w$type, openalex_id = w$id, is_retracted = w$is_retracted,
               score = w$relevance_score)
}

# ---- Crossref ------------------------------------------------------------------------
CrossrefQueryURL <- function(query, cfg, rows = cfg$network$crossref_rows)
  sprintf('%s?query.bibliographic=%s&rows=%d&mailto=%s', cfg$network$crossref_api,
          Enc(gsub('\\s+', ' ', trimws(query))), as.integer(rows), Enc(cfg$mailto))

CrossrefQuery <- function(query, cfg, rows = cfg$network$crossref_rows) {
  if (is.na(query) || !nzchar(trimws(query))) return(EmptyCandidates())
  r <- CachedGET(CrossrefQueryURL(query, cfg, rows), cfg)
  if (r$status != 200L) return(EmptyCandidates())
  items <- ParseJSON(r$body)$message$items
  if (length(items) == 0) return(EmptyCandidates())
  do.call(rbind, lapply(items, NormaliseCrossrefItem))
}

CrossrefWorkURL <- function(doi, cfg)
  sprintf('%s/%s?mailto=%s', cfg$network$crossref_api, Enc(CleanDOI(doi)), Enc(cfg$mailto))

# The full Crossref record of a DOI (message), or NULL when Crossref has none.
CrossrefWork <- function(doi, cfg) {
  if (is.na(doi) || !nzchar(doi)) return(NULL)
  r <- CachedGET(CrossrefWorkURL(doi, cfg), cfg)
  if (r$status == 404L) return(NULL)
  if (r$status != 200L) return(NULL)
  ParseJSON(r$body)$message
}

# The deposited reference list of a compilation paper as a data frame (key,
# doi, author, year, unstructured, journal_title, article_title, volume,
# first_page), empty when Crossref holds none.
CandidatesFromCompilationReflist <- function(compilation_doi, cfg) {
  empty <- data.frame(key = character(), doi = character(), author = character(), year = character(),
                      unstructured = character(), journal_title = character(), article_title = character(),
                      volume = character(), first_page = character(), stringsAsFactors = FALSE)
  if (is.null(compilation_doi) || is.na(compilation_doi)) return(empty)
  w <- CrossrefWork(compilation_doi, cfg)
  if (is.null(w) || length(w$reference) == 0) return(empty)
  Chr <- function(x) if (is.null(x)) NA_character_ else as.character(x)
  out <- do.call(rbind, lapply(w$reference, function(r)
    data.frame(key = Chr(r$key), doi = CleanDOI(Chr(r$DOI)), author = Chr(r$author), year = Chr(r$year),
               unstructured = Chr(r$unstructured), journal_title = Chr(r[['journal-title']]),
               article_title = Chr(r[['article-title']]), volume = Chr(r$volume),
               first_page = Chr(r[['first-page']]), stringsAsFactors = FALSE)))
  rownames(out) <- NULL
  out
}

# The closed-world candidates for one parsed reference: the compilation's
# deposited references whose first author and year agree (or whose
# unstructured text contains the surname and the year), each resolved through
# Crossref to a full candidate row flagged closed_world = TRUE.
ClosedWorldCandidates <- function(parsed, reflist, cfg) {
  if (is.null(reflist) || nrow(reflist) == 0) return(EmptyCandidates())
  a <- NormaliseCitationString(parsed$parsed_author1); y <- parsed$parsed_year
  if (is.na(a) || !nzchar(a)) return(EmptyCandidates())
  ref_author <- NormaliseCitationString(reflist$author)
  ref_year   <- suppressWarnings(as.integer(substr(reflist$year, 1, 4)))
  unstr <- NormaliseCitationString(reflist$unstructured)
  hit <- (!is.na(ref_author) & grepl(a, ref_author, fixed = TRUE) & !is.na(ref_year) & !is.na(y) & ref_year == y) |
         (!is.na(unstr) & grepl(paste0('\\b', a, '\\b'), unstr, perl = TRUE) & !is.na(y) & grepl(as.character(y), unstr, fixed = TRUE))
  hits <- reflist[hit & !is.na(reflist$doi), , drop = FALSE]
  if (nrow(hits) == 0) return(EmptyCandidates())
  rows <- lapply(unique(hits$doi), function(d) {
    w <- CrossrefWork(d, cfg)
    if (is.null(w)) NULL else NormaliseCrossrefItem(w, closed_world = TRUE)
  })
  rows <- rows[!vapply(rows, is.null, logical(1))]
  if (length(rows) == 0) EmptyCandidates() else do.call(rbind, rows)
}

# ---- OpenAlex ------------------------------------------------------------------------
# Characters with a meaning in OpenAlex filter syntax are removed from the title.
OpenAlexSearchText <- function(x) {
  x <- FoldASCII(x)
  x <- gsub('[,:|&"\'()\\[\\]{}<>!?]', ' ', x, perl = TRUE)
  trimws(gsub('\\s+', ' ', x, perl = TRUE))
}

OpenAlexQueryURL <- function(title, year, cfg, per_page = cfg$network$openalex_per_page, search = NULL) {
  if (!is.null(search))
    return(sprintf('%s?search=%s&per-page=%d&mailto=%s', cfg$network$openalex_api,
                   Enc(OpenAlexSearchText(search)), as.integer(per_page), Enc(cfg$mailto)))
  filt <- paste0('title.search:', OpenAlexSearchText(title))
  if (!is.na(year))
    filt <- paste0(filt, sprintf(',publication_year:%d-%d', year - cfg$thresholds$year_window,
                                 year + cfg$thresholds$year_window))
  sprintf('%s?filter=%s&per-page=%d&mailto=%s', cfg$network$openalex_api, Enc(filt),
          as.integer(per_page), Enc(cfg$mailto))
}

# Title search within a year window (or a full-text `search` of the whole
# citation when no title was parsed).
OpenAlexQuery <- function(title, year, cfg, search = NULL) {
  if (is.null(search) && (is.na(title) || !nzchar(OpenAlexSearchText(title)))) return(EmptyCandidates())
  r <- CachedGET(OpenAlexQueryURL(title, year, cfg, search = search), cfg)
  if (r$status != 200L) return(EmptyCandidates())
  res <- ParseJSON(r$body)$results
  if (length(res) == 0) return(EmptyCandidates())
  do.call(rbind, lapply(res, NormaliseOpenAlexItem))
}

OpenAlexWorkURL <- function(doi, cfg)
  sprintf('%s/https://doi.org/%s?mailto=%s', cfg$network$openalex_api, CleanDOI(doi), Enc(cfg$mailto))

# The OpenAlex record of a DOI as a candidate row (is_retracted, type,
# openalex_id), or NULL when OpenAlex has none.
OpenAlexWork <- function(doi, cfg) {
  if (is.na(doi) || !nzchar(doi)) return(NULL)
  r <- CachedGET(OpenAlexWorkURL(doi, cfg), cfg)
  if (r$status != 200L) return(NULL)
  NormaliseOpenAlexItem(ParseJSON(r$body))
}

# ---- screening evidence file ---------------------------------------------------------
# Bib/scite_checks.csv: doi, is_retracted, notice_type, notice_doi, checked_at,
# checked_by ('scite-mcp', 'consensus-mcp' or 'none', see citations_config.r);
# one row per DOI screened (several rows when a DOI carries several notices).
# A row with is_retracted TRUE or a notice (anything but 'none' / 'unchecked')
# forces `pending` (issue #1, 1.7); a 'none' row (no service answered) keeps the
# reference pending too; a 'consensus-mcp' row must say 'unchecked' (Consensus
# has no retraction field). A missing file reads as no rows.
ReadSciteChecks <- function(path) {
  if (!file.exists(path))
    return(as.data.frame(setNames(rep(list(character()), length(scite_check_columns)), scite_check_columns),
                         stringsAsFactors = FALSE))
  d <- read.csv(path, stringsAsFactors = FALSE, colClasses = 'character', na.strings = c('', 'NA'),
                check.names = FALSE, encoding = 'UTF-8')
  miss <- setdiff(scite_check_columns, names(d))
  if (length(miss) > 0) stop(basename(path), ' lacks column(s) ', paste(miss, collapse = ', '), call. = FALSE)
  d <- d[, scite_check_columns]
  d$doi <- CleanDOI(d$doi)
  bad <- !is.na(d$is_retracted) & !toupper(d$is_retracted) %in% c('TRUE', 'FALSE')
  if (any(bad)) stop(basename(path), ': is_retracted must be TRUE or FALSE', call. = FALSE)
  if (any(is.na(d$checked_by) | !d$checked_by %in% screening_services))
    stop(basename(path), ': checked_by must be one of ', paste(screening_services, collapse = ', '), call. = FALSE)
  cons <- d$checked_by == 'consensus-mcp'
  if (any(cons & !(d$notice_type %in% 'unchecked')))
    stop(basename(path), ": a consensus-mcp row must have notice_type 'unchecked' (Consensus has no retraction field)", call. = FALSE)
  if (any(cons & toupper(d$is_retracted) %in% 'TRUE'))
    stop(basename(path), ': a consensus-mcp row cannot assert is_retracted', call. = FALSE)
  d
}

# The screening verdict for one DOI from the rows of ReadSciteChecks():
# list(checked, service, is_retracted, notice, gap). `service` is the
# screening service to append to `services` ('scite-mcp' wins over
# 'consensus-mcp'); `gap` is TRUE when the only row says checked_by 'none'.
SciteVerdict <- function(doi, scite) {
  none <- list(checked = FALSE, service = NA_character_, is_retracted = FALSE, notice = NA_character_, gap = FALSE)
  doi <- CleanDOI(doi)
  if (is.na(doi) || is.null(scite) || nrow(scite) == 0) return(none)
  rows <- scite[!is.na(scite$doi) & scite$doi == doi, , drop = FALSE]
  if (nrow(rows) == 0) return(none)
  answered <- rows[rows$checked_by != 'none', , drop = FALSE]
  if (nrow(answered) == 0) return(list(checked = FALSE, service = 'none', is_retracted = FALSE, notice = NA_character_, gap = TRUE))
  service <- if ('scite-mcp' %in% answered$checked_by) 'scite-mcp' else 'consensus-mcp'
  notices <- answered$notice_type[!is.na(answered$notice_type) & nzchar(answered$notice_type) &
                                  !answered$notice_type %in% screening_notice_none]
  list(checked = TRUE, service = service,
       is_retracted = any(toupper(answered$is_retracted) == 'TRUE', na.rm = TRUE),
       notice = if (length(notices) > 0) paste0(service, ':', paste(unique(notices), collapse = ';')) else NA_character_,
       gap = FALSE)
}
