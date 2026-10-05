# Tests for the service layer of the citation tooling (issue #1):
# R/library/citations/verify_services.r. Everything runs on the recorded
# Crossref and OpenAlex responses in R/library/citations/tests/fixtures/cache/
# (the cache layout of CachedGET(), keyed without the mailto parameter) with
# cfg$offline = TRUE, so that no request can leave the machine: the cache key,
# the offline guard, the cache round trip, the Crossref and OpenAlex parsers
# on real responses and on synthetic records, the 404 of a non-existent DOI,
# the deposited reference list of Ikeda 2014, the closed-world candidates, and
# the screening file Bib/scite_checks.csv (ReadSciteChecks(), SciteVerdict())
# with its scite-mcp / consensus-mcp / none vocabulary. jsonlite, digest and
# stringdist are used; httr2 is never reached.
#
#   Rscript R/library/tests/test_citations_services.R      (from any directory)
#
# Prints one line per expectation and exits with status 1 if any failed.

this_file <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE))
if (length(this_file) == 0)
  this_file <- file.path('R', 'library', 'tests', 'test_citations_services.R')
repo <- normalizePath(file.path(dirname(this_file), '..', '..', '..'))
lib  <- file.path(repo, 'R', 'library')
source(file.path(lib, 'helpers.r'))
for (f in c('citations_config.r', 'normalise_citation.r', 'parse_reflists.r', 'verify_services.r'))
  source(file.path(lib, 'citations', f))

failures <- character(0)
n_checks <- 0L
Expect <- function(ok, what) {
  n_checks <<- n_checks + 1L
  if (!isTRUE(ok)) failures <<- c(failures, what)
  cat(sprintf('  %s %s\n', if (isTRUE(ok)) 'ok  ' else 'FAIL', what))
}
ErrorOf <- function(expr) tryCatch({ expr; NULL }, error = function(e) conditionMessage(e))
Has <- function(x, pattern) !is.null(x) && !is.na(x) && grepl(pattern, x, fixed = TRUE)

fixtures <- file.path(lib, 'citations', 'tests', 'fixtures', 'cache')
cfg <- CitationsConfig(repo, offline = TRUE)
cfg$cache_dir <- fixtures

# ---- configuration -------------------------------------------------------------------
cat('CitationsConfig(), CitationsUserAgent()\n')
Expect(cfg$offline && cfg$mailto == 'offline@invalid' && grepl('mailto:offline@invalid', cfg$user_agent, fixed = TRUE) &&
         grepl('^TaxonBodyMass_DB-citations/', cfg$user_agent) && cfg$network$rate_per_s == 1 && cfg$thresholds$certain_title_sim == 0.93,
       'the offline config carries a placeholder contact, the polite User-Agent and the thresholds')
Expect(cfg$cache_dir == fixtures && cfg$primary_bib == file.path(repo, 'Bib', 'TaxonBodyMass_PrimaryCitations.bib') &&
         cfg$provenance_csv == file.path(repo, 'TaxonBodyMass_Provenance.csv.gz'), 'paths are relative to the repository root')
old <- Sys.getenv('CROSSREF_MAILTO'); Sys.setenv(CROSSREF_MAILTO = 'someone@example.org')
Expect(CitationsMailto('crossref') == 'someone@example.org', 'CROSSREF_MAILTO from the environment wins')
Sys.setenv(CROSSREF_MAILTO = old)

# ---- the cache -------------------------------------------------------------------------
cat('CacheKey(), ReadCachedResponse(), WriteCachedResponse(), CachedGET() offline\n')
u1 <- 'https://api.crossref.org/works?query.bibliographic=x&rows=5&mailto=a%40b.org'
u2 <- 'https://api.crossref.org/works?query.bibliographic=x&rows=5&mailto=c%40d.org'
u3 <- 'https://api.crossref.org/works?query.bibliographic=y&rows=5&mailto=a%40b.org'
Expect(CacheKey(u1) == CacheKey(u2) && CacheKey(u1) != CacheKey(u3) && grepl('^[0-9a-f]{40}$', CacheKey(u1)) &&
         CacheKey('https://api.crossref.org/works/10.1/x?mailto=a') == CacheKey('https://api.crossref.org/works/10.1/x') &&
         CacheKey('https://api.openalex.org/works/10.1/x?mailto=a&api_key=k') == CacheKey('https://api.openalex.org/works/10.1/x'),
       'the cache key is the sha1 of the URL without its mailto parameter')
query1 <- 'Doyle 2007 The energy density of jellyfish: Estimates from bomb-calorimetry and proximate-composition J. Exp. Mar. Biol. Ecol 343 239-252'
hit <- ReadCachedResponse(CrossrefQueryURL(query1, cfg), fixtures)
Expect(!is.null(hit) && hit$status == 200L && hit$cached && nchar(hit$body) > 1000 && hit$fetched_at == '2026-10-04T22:19:31Z',
       'a recorded response reads back with its status and fetch time')
Expect(is.null(ReadCachedResponse('https://api.crossref.org/works?query.bibliographic=nothing', fixtures)), 'an unknown URL has no cached response')
e <- ErrorOf(CachedGET('https://api.crossref.org/works?query.bibliographic=nothing&mailto=offline%40invalid', cfg))
Expect(Has(e, 'offline: no cached response'), 'offline: an uncached URL stops instead of reaching the network')
got <- CachedGET(CrossrefQueryURL(query1, cfg), cfg)
Expect(got$cached && got$status == 200L, 'offline: a cached URL is served from the cache')
t0 <- Sys.time(); PaceRequest('example.org', 4); PaceRequest('example.org', 4); PaceRequest('other.org', 4); dt <- as.numeric(Sys.time() - t0, units = 'secs')
Expect(dt >= 0.25 && dt < 0.6 && inherits(.citations_last_request[['example.org']], 'POSIXct'),
       sprintf('PaceRequest() spaces requests to one host by 1/rate seconds (%.2f s for two to one host and one to another)', dt))
tmpc <- tempfile('cache'); dir.create(tmpc)
key <- WriteCachedResponse('https://example.org/w?a=1&mailto=x', 200L, '{"ok":true}', tmpc, '2026-01-01T00:00:00Z')
back <- ReadCachedResponse('https://example.org/w?a=1&mailto=y', tmpc)
idx <- readLines(file.path(tmpc, 'index.tsv'))
Expect(identical(trimws(back$body), '{"ok":true}') && back$status == 200L && back$fetched_at == '2026-01-01T00:00:00Z' &&
         file.exists(file.path(tmpc, paste0(key, '.json'))) && length(idx) == 2 && idx[1] == 'sha1\tstatus\tfetched_at\turl' &&
         startsWith(idx[2], paste0(key, '\t200\t')),
       'write / read round trip: body, meta and index.tsv, readable under another mailto')
meta <- jsonlite::fromJSON(file.path(tmpc, paste0(key, '.meta.json')))
Expect(meta$tool_version == citations_tool_version && meta$url == 'https://example.org/w?a=1&mailto=x', 'the meta file records the tool version and the URL')

# ---- Crossref -----------------------------------------------------------------------------
cat('QuotaCondition(), the per-host quota flag of CachedGET(), OpenAlexAuth()\n')
qc <- QuotaCondition('api.openalex.org', 82961)
Expect(inherits(qc, 'citations_quota') && inherits(qc, 'error') && grepl('quota exhausted', conditionMessage(qc), fixed = TRUE) &&
         grepl('23.0 h', conditionMessage(qc), fixed = TRUE) && grepl('OPENALEX_API_KEY', conditionMessage(qc), fixed = TRUE) && qc$host == 'api.openalex.org',
       'an exhausted quota is a classed error naming the host, the reset time and the API-key remedy')
assign('api.crossref.org', QuotaCondition('api.crossref.org'), envir = .citations_quota_hit)
cfg_net <- cfg; cfg_net$offline <- FALSE
caught <- tryCatch(CachedGET('https://api.crossref.org/works/10.1/none?mailto=offline%40invalid', cfg_net), citations_quota = function(e) e)
Expect(inherits(caught, 'citations_quota') && caught$host == 'api.crossref.org',
       'once a host has answered 429 every further uncached request to it raises the condition without a network call')
query1 <- 'Doyle 2007 The energy density of jellyfish: Estimates from bomb-calorimetry and proximate-composition J. Exp. Mar. Biol. Ecol 343 239-252'
served <- tryCatch(CachedGET(CrossrefQueryURL(query1, cfg_net), cfg_net), citations_quota = function(e) e)
Expect(!inherits(served, 'citations_quota') && isTRUE(served$cached), 'cached responses are still served for a flagged host')
ResetQuotaFlags()
Expect(length(ls(.citations_quota_hit)) == 0, 'ResetQuotaFlags() clears the flags')
cfg_key <- cfg; cfg_key$openalex_api_key <- 'k1'
cfg_nokey <- cfg; cfg_nokey$openalex_api_key <- ''          # independent of an OPENALEX_API_KEY in the environment
Expect(OpenAlexAuth(cfg_nokey) == '' && OpenAlexAuth(cfg_key) == '&api_key=k1' && grepl('&api_key=k1$', OpenAlexWorkURL('10.1/x', cfg_key)) &&
         grepl('&api_key=k1$', OpenAlexQueryURL('a title', 2000L, cfg_key)) && !grepl('api_key', OpenAlexWorkURL('10.1/x', cfg_nokey)),
       'OPENALEX_API_KEY is appended to the OpenAlex URLs only when set')

cat('CrossrefQuery(), NormaliseCrossrefItem(), CrossrefWork()\n')
cr <- CrossrefQuery(query1, cfg)
Expect(identical(names(cr), names(EmptyCandidates())) && nrow(cr) == 5 && all(cr$service == 'crossref'),
       'the Doyle query gives five normalised crossref candidates')
Expect(cr$doi[1] == '10.1016/j.jembe.2006.12.010' && cr$title[1] == 'The energy density of jellyfish: Estimates from bomb-calorimetry and proximate-composition' &&
         cr$author1[1] == 'Doyle' && cr$year[1] == 2007L && cr$container[1] == 'Journal of Experimental Marine Biology and Ecology' &&
         cr$volume[1] == '343' && cr$pages[1] == '239-252' && cr$type[1] == 'journal-article' && !cr$closed_world[1] && is.na(cr$update_types[1]),
       'the first candidate carries the Doyle 2007 metadata')
Expect(is.numeric(cr$score) && all(!is.na(cr$score)) && cr$type[5] == 'posted-content' && cr$container[5] == 'Elsevier BV' && is.na(cr$pages[5]) && is.na(cr$volume[5]),
       'relevance scores are kept (cached, never decision inputs); a preprint falls back to its publisher as container, missing fields are NA')
Expect(nrow(CrossrefQuery(NA, cfg)) == 0 && nrow(CrossrefQuery('  ', cfg)) == 0, 'an empty query gives no candidates without a request')
Expect(grepl('rows=5&mailto=offline%40invalid$', CrossrefQueryURL(query1, cfg)) && grepl('query.bibliographic=Doyle%202007', CrossrefQueryURL(query1, cfg), fixed = TRUE),
       'the query URL is percent-encoded with rows and mailto')

# a citation that is itself a URL with '%20' escapes (Smith_2003 reference 174):
# URLencode() skips a string holding '%xx' unless repeated = TRUE, and curl
# refuses the raw spaces
u_pct <- CrossrefQueryURL('www.iiasa.ac.at/~sendzim/ Trop%20Wet%20Forest.xls', cfg)
Expect(grepl('query.bibliographic=www.iiasa.ac.at%2F~sendzim%2F%20Trop%2520Wet%2520Forest.xls&', u_pct, fixed = TRUE) &&
         !inherits(try(curl::curl_parse_url(u_pct), silent = TRUE), 'try-error'),
       'Enc() percent-encodes a query that already holds %xx sequences')
w <- CrossrefWork('10.1007/BF00392514', cfg)
Expect(!is.null(w) && w$DOI == '10.1007/bf00392514' && w$author[[1]]$family == 'Ikeda' && w$volume == '92' && length(w$reference) == 28,
       'CrossrefWork() returns the full message of a DOI (case-insensitive, with reference[])')
item <- NormaliseCrossrefItem(w)
Expect(item$doi == '10.1007/bf00392514' && item$author1 == 'Ikeda' && item$year == 1986L && item$container == 'Marine Biology' &&
         item$volume == '92' && item$pages == '545-555' && item$type == 'journal-article' && is.na(item$update_types) && is.na(item$openalex_id) && is.na(item$is_retracted),
       'a work record normalises like a query item (no OpenAlex fields)')
Expect(is.null(CrossrefWork('10.9999/this-doi-does-not-exist', cfg)), 'a cached 404 means no such DOI (NULL)')
Expect(is.null(CrossrefWork(NA, cfg)) && is.null(CrossrefWork('', cfg)), 'NA / empty DOI: NULL without a request')
Expect(Has(ErrorOf(CrossrefWork('10.1234/not-cached', cfg)), 'offline'), 'an uncached DOI stops offline')
syn <- list(DOI = '10.1/ABC', type = 'journal-article', title = list('Main title'), subtitle = list('A subtitle'),
            author = list(list(family = 'Second', given = 'B.', sequence = 'additional'), list(family = 'First', given = 'A.', sequence = 'first')),
            `published-online` = list(`date-parts` = list(list(2001L, 5L))),
            `container-title` = list('J Syn'), volume = '1', page = '2-3', score = 99,
            `update-to` = list(list(type = 'retraction', DOI = '10.1/abc')), `updated-by` = list(list(type = 'erratum', DOI = '10.1/abc-err')))
si <- NormaliseCrossrefItem(syn, closed_world = TRUE)
Expect(si$doi == '10.1/abc' && si$title == 'Main title: A subtitle' && si$author1 == 'First' && si$year == 2001L &&
         si$update_types == 'update-to:retraction;updated-by:erratum' && si$closed_world && si$score == 99,
       'synthetic item: subtitle appended, sequence=first author chosen, year from published-online, update types joined')
org <- NormaliseCrossrefItem(list(DOI = '10.1/org', type = 'report', title = list(), author = list(list(name = 'Some Agency')), publisher = 'Agency Press'))
Expect(is.na(org$title) && org$author1 == 'Some Agency' && org$container == 'Agency Press' && is.na(org$year),
       'an organisation author and a publisher-only container are kept; missing title and year are NA')

cat('CandidatesFromCompilationReflist()\n')
rl <- CandidatesFromCompilationReflist('10.1007/s00227-014-2540-5', cfg)
Expect(nrow(rl) == 101 && sum(!is.na(rl$doi)) == 89 && identical(names(rl), c('key', 'doi', 'author', 'year', 'unstructured', 'journal_title', 'article_title', 'volume', 'first_page')),
       'Ikeda 2014: 101 deposited references, 89 with a DOI')
Expect(rl$key[1] == '2540_CR1' && rl$doi[1] == '10.1242/jeb.054502' && rl$author[1] == 'PS Agutter' && rl$year[1] == '2011' &&
         rl$journal_title[1] == 'J Exp Biol' && rl$volume[1] == '214' && rl$first_page[1] == '1055' && grepl('^Agutter PS, Tuszynski JA \\(2011\\)', rl$unstructured[1]),
       'the first deposited reference is parsed field by field (DOI lowercased)')
Expect(nrow(CandidatesFromCompilationReflist('10.1007/bf00392514', cfg)) == 28, 'the Ikeda 1986 paper has 28 deposited references')
Expect(nrow(CandidatesFromCompilationReflist(NA, cfg)) == 0 && nrow(CandidatesFromCompilationReflist('10.9999/this-doi-does-not-exist', cfg)) == 0,
       'no DOI or an unknown DOI: an empty list')

cat('ClosedWorldCandidates()\n')
parsed <- list(parsed_author1 = 'Ikeda', parsed_year = 1986L, parsed_title = 'Metabolic activity and elemental composition of krill')
reflist <- data.frame(key = c('r1', 'r2', 'r3', 'r4'),
                      doi = c('10.1007/bf00392514', '10.9999/this-doi-does-not-exist', NA, '10.1007/bf00392514'),
                      author = c('T Ikeda', NA, 'T Ikeda', 'M Omori'), year = c('1986', NA, '1986', '1969'),
                      unstructured = c(NA, 'Ikeda T, Bruce B (1986) Metabolic activity. Mar Biol 92:545', NA, 'Omori M (1969) Weight. Mar Biol 3:4'),
                      journal_title = NA, article_title = NA, volume = NA, first_page = NA, stringsAsFactors = FALSE)
cw <- ClosedWorldCandidates(parsed, reflist, cfg)
Expect(nrow(cw) == 1 && cw$doi == '10.1007/bf00392514' && cw$closed_world && cw$service == 'crossref' && cw$author1 == 'Ikeda',
       'author+year hits (and an unstructured hit) resolve through the cached works; the 404 DOI is dropped; one row per DOI')
Expect(nrow(ClosedWorldCandidates(list(parsed_author1 = 'Nobody', parsed_year = 1986L), reflist, cfg)) == 0 &&
         nrow(ClosedWorldCandidates(list(parsed_author1 = NA, parsed_year = 1986L), reflist, cfg)) == 0 &&
         nrow(ClosedWorldCandidates(parsed, NULL, cfg)) == 0 && nrow(ClosedWorldCandidates(parsed, reflist[0, ], cfg)) == 0,
       'no hit, no author, no list: empty candidates')

# ---- OpenAlex -------------------------------------------------------------------------------
cat('OpenAlexSearchText(), OpenAlexQueryURL(), OpenAlexQuery(), OpenAlexWork()\n')
Expect(OpenAlexSearchText('Krill (November-December): a "test", ok? [x]') == 'Krill November-December a test ok x',
       'filter-syntax characters are removed from the search text')
u <- OpenAlexQueryURL('The energy density of jellyfish: Estimates', 2007L, cfg)
Expect(grepl('filter=title.search%3AThe%20energy%20density%20of%20jellyfish%20Estimates%2Cpublication_year%3A2006-2008&per-page=5&mailto=', u, fixed = TRUE),
       'the title search URL carries the year window')
Expect(grepl('filter=title.search%3AX&per-page=5', OpenAlexQueryURL('X', NA, cfg), fixed = TRUE) &&
         grepl('[?]search=Some%20citation%20text&per-page=5', OpenAlexQueryURL(NA, NA, cfg, search = 'Some citation: text')),
       'no year: no window; search = the full-text variant')
oa <- OpenAlexQuery('The energy density of jellyfish: Estimates from bomb-calorimetry and proximate-composition', 2007L, cfg)
Expect(nrow(oa) == 1 && oa$service == 'openalex' && oa$doi == '10.1016/j.jembe.2006.12.010' && oa$author1 == 'Doyle' && oa$year == 2007L &&
         oa$container == 'Journal of Experimental Marine Biology and Ecology' && oa$volume == '343' && oa$pages == '239-252' &&
         oa$type == 'article' && oa$openalex_id == 'https://openalex.org/W2051884577' && identical(oa$is_retracted, FALSE) && is.numeric(oa$score),
       'the Doyle title search gives one openalex candidate with a bare DOI, the surname, pages joined and the OpenAlex id')
oa2 <- OpenAlexQuery('Weight and chemical composition of some important oceanic zooplankton in the North Pacific', 1969L, cfg)
Expect(nrow(oa2) == 1 && oa2$doi == '10.1007/bf00355587' && AuthorMatch('Omori', oa2$author1) && oa2$pages == '4-10',
       'the Omori 1969 title search: the diacritic surname matches through AuthorMatch()')
Expect(nrow(OpenAlexQuery(NA, NA, cfg)) == 0 && nrow(OpenAlexQuery('', 2000L, cfg)) == 0, 'no title and no search text: no candidates')
ow <- OpenAlexWork('10.1007/bf00392514', cfg)
Expect(!is.null(ow) && nrow(ow) == 1 && ow$doi == '10.1007/bf00392514' && identical(ow$is_retracted, FALSE) && ow$openalex_id == 'https://openalex.org/W2037357551' &&
         ow$author1 == 'Ikeda' && ow$year == 1986L,
       'OpenAlexWork() gives the retraction flag and the id of a DOI')
Expect(is.null(OpenAlexWork(NA, cfg)) && Has(ErrorOf(OpenAlexWork('10.1234/not-cached', cfg)), 'offline'), 'NA DOI: NULL; uncached DOI stops offline')
sw <- NormaliseOpenAlexItem(list(id = 'https://openalex.org/W1', doi = 'https://doi.org/10.1/XYZ', display_name = 'Only display name',
                                 publication_year = 1999, type = 'book', is_retracted = TRUE,
                                 authorships = list(list(author = list(display_name = 'Jean-Pierre van der Meer'))),
                                 biblio = list(volume = '7', first_page = '12', last_page = '12'), relevance_score = 3.5))
Expect(sw$doi == '10.1/xyz' && sw$title == 'Only display name' && sw$author1 == 'Meer' && sw$year == 1999L && sw$pages == '12' &&
         isTRUE(sw$is_retracted) && is.na(sw$container) && sw$score == 3.5,
       'synthetic OpenAlex work: display_name fallback, last name token, single page, retraction flag')

# ---- the screening file ---------------------------------------------------------------------
cat('ReadSciteChecks(), SciteVerdict()\n')
empty <- ReadSciteChecks(tempfile())
Expect(nrow(empty) == 0 && identical(names(empty), scite_check_columns), 'a missing screening file reads as no rows')
real <- ReadSciteChecks(file.path(repo, 'Bib', 'scite_checks.csv'))
Expect(identical(names(real), scite_check_columns), 'the tracked Bib/scite_checks.csv has the schema')
WriteChecks <- function(rows) { f <- tempfile(fileext = '.csv'); write.csv(rows, f, row.names = FALSE, na = ''); f }
Row <- function(doi, is_retracted, notice_type, checked_by, notice_doi = NA)
  data.frame(doi = doi, is_retracted = is_retracted, notice_type = notice_type, notice_doi = notice_doi,
             checked_at = '2026-10-05', checked_by = checked_by, stringsAsFactors = FALSE)
good <- rbind(Row('https://doi.org/10.1/A', 'FALSE', 'none', 'scite-mcp'),
              Row('10.1/b', 'FALSE', 'erratum', 'scite-mcp', '10.1/b-err'),
              Row('10.1/c', 'TRUE', 'retraction', 'scite-mcp'),
              Row('10.1/d', NA, 'unchecked', 'consensus-mcp'),
              Row('10.1/e', NA, NA, 'none'),
              Row('10.1/f', 'FALSE', 'none', 'scite-mcp'),
              Row('10.1/f', NA, 'unchecked', 'consensus-mcp'),
              Row('10.1/g', NA, NA, 'none'),
              Row('10.1/g', 'FALSE', 'correction', 'scite-mcp'))
sc <- ReadSciteChecks(WriteChecks(good))
Expect(nrow(sc) == 9 && sc$doi[1] == '10.1/a' && all(sc$checked_by %in% screening_services), 'a valid file reads with cleaned DOIs')
Expect(Has(ErrorOf(ReadSciteChecks(WriteChecks(Row('10.1/x', 'FALSE', 'none', 'scholar')))), 'checked_by must be one of'),
       'an unknown screening service is rejected')
Expect(Has(ErrorOf(ReadSciteChecks(WriteChecks(Row('10.1/x', 'FALSE', 'none', 'consensus-mcp')))), "must have notice_type 'unchecked'"),
       'a consensus-mcp row must say unchecked (Consensus has no retraction field)')
Expect(Has(ErrorOf(ReadSciteChecks(WriteChecks(Row('10.1/x', 'TRUE', 'unchecked', 'consensus-mcp')))), 'cannot assert is_retracted'),
       'a consensus-mcp row cannot assert a retraction')
Expect(Has(ErrorOf(ReadSciteChecks(WriteChecks(Row('10.1/x', 'maybe', 'none', 'scite-mcp')))), 'is_retracted must be TRUE or FALSE'),
       'is_retracted must be TRUE or FALSE')
Expect(Has(ErrorOf(ReadSciteChecks(WriteChecks(good[, -6]))), 'lacks column'), 'a missing column stops')
v <- SciteVerdict('10.1/a', sc)
Expect(v$checked && v$service == 'scite-mcp' && !v$is_retracted && is.na(v$notice) && !v$gap, 'a clean scite-mcp row: checked, no notice')
v <- SciteVerdict('https://doi.org/10.1/B', sc)
Expect(v$checked && v$notice == 'scite-mcp:erratum' && !v$is_retracted, 'an erratum row gives the notice with its service')
v <- SciteVerdict('10.1/c', sc)
Expect(v$checked && v$is_retracted && v$notice == 'scite-mcp:retraction', 'a retraction row sets is_retracted')
v <- SciteVerdict('10.1/d', sc)
Expect(v$checked && v$service == 'consensus-mcp' && is.na(v$notice) && !v$is_retracted && !v$gap, 'a consensus-only row: checked by consensus-mcp, unchecked is not a notice')
v <- SciteVerdict('10.1/e', sc)
Expect(!v$checked && v$service == 'none' && v$gap, "a 'none' row records the gap (neither service answered)")
v <- SciteVerdict('10.1/f', sc)
Expect(v$checked && v$service == 'scite-mcp' && is.na(v$notice), 'with both services on a DOI scite-mcp is the service of record')
v <- SciteVerdict('10.1/g', sc)
Expect(v$checked && v$service == 'scite-mcp' && v$notice == 'scite-mcp:correction' && !v$gap, "a later scite-mcp row supersedes a 'none' row")
v <- SciteVerdict('10.1/zz', sc)
Expect(!v$checked && is.na(v$service) && !v$gap && !SciteVerdict(NA, sc)$checked && !SciteVerdict('10.1/a', NULL)$checked && !SciteVerdict('10.1/a', empty)$checked,
       'an unscreened DOI, an NA DOI or no screening rows: not checked, no gap')

cat(sprintf('\n%d checks, %d failed\n', n_checks, length(failures)))
if (length(failures) > 0) { cat(paste0('  FAIL: ', failures, '\n'), sep = ''); quit(status = 1) }
