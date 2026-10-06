# Tests for the decision layer of the citation tooling (issue #1):
# R/library/citations/decide.r. Every rule of the table in issue #1 section
# 2.3 (and the README of R/library/citations/) is exercised on synthetic
# candidates; VerifyReference() runs offline on four Kiorboe_2013 references
# whose Crossref and OpenAlex responses are recorded in
# R/library/citations/tests/fixtures/cache/; the review queue
# (WritePendingQueue(), ApplyQueueDecisions()) and the screening overlay
# (ApplySciteChecks()) run on temporary files; the screening list of the
# selective policy (ScreeningCandidates()) on a synthetic frame. No network access.
#
#   Rscript R/library/tests/test_citations_decide.R      (from any directory)
#
# Prints one line per expectation and exits with status 1 if any failed.

this_file <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE))
if (length(this_file) == 0)
  this_file <- file.path('R', 'library', 'tests', 'test_citations_decide.R')
repo <- normalizePath(file.path(dirname(this_file), '..', '..', '..'))
lib  <- file.path(repo, 'R', 'library')
source(file.path(lib, 'helpers.r'))
for (f in c('citations_config.r', 'normalise_citation.r', 'parse_reflists.r', 'verify_services.r', 'decide.r'))
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

cfg <- CitationsConfig(repo, offline = TRUE)
cfg$cache_dir <- file.path(lib, 'citations', 'tests', 'fixtures', 'cache')

# ---- synthetic references and candidates ---------------------------------------------------
Ref <- function(raw_citation = 'Doe, J. 2001. A study of things. J Things 5: 1-10.', raw_doi = NA, role = 'measurement',
                author1 = 'Doe', year = 2001L, title = 'A study of things', container = 'J Things', volume = '5', pages = '1-10')
  list(source_label = 'Src', native_key = 'k', raw_citation = raw_citation, raw_doi = raw_doi, role = role, n_records = 3L,
       parsed_author1 = author1, parsed_year = year, parsed_title = title, parsed_container = container,
       parsed_volume = volume, parsed_pages = pages, editorial_notice = NA_character_, match_reason = NA_character_)
Cand <- function(service = 'crossref', doi = '10.1/thing', title = 'A study of things', author1 = 'Doe', year = 2001L,
                 container = 'Journal of Things', volume = '5', pages = '1-10', type = 'journal-article', ...)
  CandidateRow(service, doi, title, author1, year, container, volume, pages, type, ...)

cat('ScoreCandidate(), ScoreAll(), CollapseByDOI(), IsGreyLiterature()\n')
sc <- ScoreCandidate(Ref(), Cand())
Expect(sc$title_sim == 1 && sc$author_match && sc$year_match && sc$container_match && sc$volume_match && sc$pages_match && sc$n_agree == 5L,
       'a perfect candidate: title_sim 1 and five agreements')
sc <- ScoreCandidate(Ref(), Cand(author1 = 'Roe', year = 2003L, container = 'Other', volume = '6', pages = '2-4'))
Expect(sc$n_agree == 0L && !sc$year_match, 'year 2003 is outside the +-1 window; nothing else agrees')
Expect(ScoreCandidate(Ref(), Cand(year = 2002L))$year_match, 'year 2002 is inside the window')
Expect(nrow(ScoreCandidate(Ref(), EmptyCandidates())) == 0 && 'n_agree' %in% names(ScoreCandidate(Ref(), EmptyCandidates())),
       'no candidates: an empty scored frame with the score columns')
all <- ScoreAll(Ref(), rbind(Cand(doi = '10.1/data', type = 'dataset'), Cand(doi = '10.1/comp', type = 'component'),
                             Cand(doi = '10.1/peer', type = 'peer-review'), Cand(doi = '10.1/na')),
                Cand(service = 'openalex', doi = '10.1/weak', title = 'A study of other things', score = 1e6))
Expect(!any(all$type %in% citations_excluded_types) && all$doi[1] == '10.1/na' && all$doi[2] == '10.1/weak',
       'dataset / component / peer-review candidates are dropped; the rest is ordered by title similarity, not by service score')
all <- ScoreAll(Ref(), rbind(Cand(), Cand(service = 'openalex', openalex_id = 'W1')), NULL, EmptyCandidates())
cb <- CollapseByDOI(all)
Expect(nrow(all) == 2 && nrow(cb) == 1 && cb$services_for_doi == 'crossref;openalex' && cb$openalex_id == 'W1',
       'the same DOI from both services collapses to one row that lists both services and keeps the OpenAlex id')
Expect(IsGreyLiterature('Kremer, P. 1976. The ecology ... Ph.D. thesis, Univ. of Rhode Island.') && IsGreyLiterature('Smith (unpublished data)') &&
         IsGreyLiterature('Technical Report 12, Fisheries Bulletin') && !IsGreyLiterature('Doe, J. 2001. A study. J Things 5: 1-10.') && !IsGreyLiterature(NA),
       'grey-literature patterns: thesis, unpublished, report, bulletin')

# ---- the rules ------------------------------------------------------------------------------
cat('DecideMatch(): the rules of section 2.3\n')
d <- DecideMatch(Ref(role = 'self'), open_cands = Cand())
Expect(d$match_status == 'self' && d$match_reason == 'self' && d$services == '' && is.na(d$doi), 'a self reference: status self, no service')
d <- DecideMatch(Ref(raw_doi = 'https://doi.org/10.1/THING'), doi_cands = rbind(Cand(title = 'Completely different title'), Cand(service = 'openalex', title = 'Completely different title')))
Expect(d$match_status == 'certain' && d$match_reason == 'doi_resolves' && d$doi == '10.1/thing' && d$services == 'crossref;openalex' && !d$is_retracted,
       'raw_doi resolves and author + year agree: certain / doi_resolves even with a different title')
d <- DecideMatch(Ref(raw_doi = '10.1/thing'), doi_cands = Cand(author1 = 'Roe', year = 1990L))
Expect(d$match_status == 'certain' && d$match_reason == 'doi_resolves' && d$title_sim == 1, 'raw_doi resolves and the title agrees (>= 0.80): certain')
d <- DecideMatch(Ref(raw_doi = '10.1/thing'), doi_cands = Cand(author1 = 'Roe', year = 1990L, title = 'Completely different title'))
Expect(d$match_status == 'pending' && d$match_reason == 'doi_mismatch' && d$doi == '10.1/thing', 'raw_doi resolves but the metadata disagree: pending / doi_mismatch')
d <- DecideMatch(Ref(raw_doi = '10.1/thing'), doi_cands = EmptyCandidates())
Expect(d$match_status == 'pending' && d$match_reason == 'doi_mismatch' && is.na(d$doi), 'raw_doi unresolvable (no record): pending / doi_mismatch')
d <- DecideMatch(Ref(raw_doi = '10.1/thing'), doi_cands = Cand(doi = '10.1/other'))
Expect(d$match_status == 'pending' && d$match_reason == 'doi_mismatch', 'the record returned is another DOI: doi_mismatch')
d <- DecideMatch(Ref(raw_doi = '10.1/thing'), doi_cands = Cand(update_types = 'update-to:retraction'))
Expect(d$match_status == 'pending' && d$match_reason == 'retracted' && d$is_retracted && Has(d$editorial_notice, 'crossref:update-to:retraction'),
       'a Crossref retraction update on a resolving DOI: pending / retracted, never certain')
d <- DecideMatch(Ref(raw_doi = '10.1/thing'), doi_cands = Cand(update_types = 'updated-by:erratum'))
Expect(d$match_status == 'pending' && d$match_reason == 'retracted' && !d$is_retracted && Has(d$editorial_notice, 'crossref:updated-by:erratum'),
       'an erratum is a notice: pending / retracted without the retraction flag')
d <- DecideMatch(Ref(), open_cands = EmptyCandidates())
Expect(d$match_status == 'not_found' && d$match_reason == 'no_candidates' && nrow(d$candidates) == 0, 'no candidate at all: not_found / no_candidates')
d <- DecideMatch(Ref(), open_cands = Cand(title = 'Predation by butterfish on ctenophores'))
Expect(d$match_status == 'not_found' && d$match_reason == 'below_threshold' && d$title_sim < 0.7, 'best title_sim < 0.70: not_found / below_threshold')
d <- DecideMatch(Ref(raw_citation = 'Doe, J. 2001. A study of things. Ph.D. thesis, Some University.'), open_cands = Cand(title = 'Predation by butterfish on ctenophores'))
Expect(d$match_status == 'pending' && d$match_reason == 'grey_literature', 'best title_sim < 0.70 and a thesis: pending / grey_literature')
d <- DecideMatch(Ref(), open_cands = rbind(Cand(), Cand(service = 'openalex', is_retracted = TRUE)))
Expect(d$match_status == 'pending' && d$match_reason == 'retracted' && d$is_retracted && Has(d$editorial_notice, 'openalex:is_retracted'),
       'OpenAlex is_retracted on the best DOI: pending / retracted')
d <- DecideMatch(Ref(), open_cands = rbind(Cand(), Cand(service = 'openalex', doi = '10.1/twin', title = 'A study of things!')))
Expect(d$match_status == 'pending' && d$match_reason == 'ambiguous' && nrow(d$candidates) == 2, 'a runner-up with another DOI within 0.05: pending / ambiguous')
d <- DecideMatch(Ref(), open_cands = rbind(Cand(container = 'Other', volume = '9', pages = '99'), Cand(service = 'openalex', container = 'Other', volume = '9', pages = '99')))
Expect(d$match_status == 'pending' && d$match_reason == 'weak_match' && d$title_sim == 1 && !d$container_match && !d$volume_match,
       'title, author and year agree but neither container, volume nor pages: pending / weak_match')
d <- DecideMatch(Ref(), open_cands = rbind(Cand(title = 'A study of things today'), Cand(service = 'openalex', title = 'A study of things today')))
Expect(d$match_status == 'pending' && d$match_reason == 'weak_match' && d$title_sim < 0.93 && d$title_sim >= 0.7, sprintf('title_sim %.3f below 0.93 with all five flags: weak_match', d$title_sim))
d <- DecideMatch(Ref(), open_cands = rbind(Cand(), Cand(service = 'openalex', openalex_id = 'W9')))
Expect(d$match_status == 'certain' && d$match_reason == 'two_service_agreement' && d$doi == '10.1/thing' && d$openalex_id == 'W9' && d$services == 'crossref;openalex',
       'strong match returned by Crossref and OpenAlex: certain / two_service_agreement')
d <- DecideMatch(Ref(), open_cands = Cand())
Expect(d$match_status == 'pending' && d$match_reason == 'single_service', 'strong match from one open-search service: pending / single_service')
d <- DecideMatch(Ref(), closed_cands = Cand(closed_world = TRUE))
Expect(d$match_status == 'certain' && d$match_reason == 'closed_world', 'strong match (title_sim >= 0.95) from the compilation\'s deposited list: certain / closed_world')
d <- DecideMatch(Ref(), closed_cands = Cand(title = 'A study of things today', closed_world = TRUE))
Expect(d$match_status == 'pending' && d$match_reason == 'weak_match' && d$title_sim < 0.93,
       sprintf('a closed-world candidate below the strong threshold (title_sim %.3f) is a weak match like any other', d$title_sim))
d <- DecideMatch(Ref(), open_cands = rbind(Cand(doi = '10.1/data', type = 'dataset'), Cand(service = 'openalex', doi = '10.1/data', type = 'dataset')))
Expect(d$match_status == 'not_found' && d$match_reason == 'no_candidates', 'only excluded work types: no candidates')
d <- DecideMatch(Ref(), open_cands = rbind(Cand(doi = '10.1/scored', title = 'Zooplankton of the North Pacific', score = 500),
                                           Cand(service = 'openalex', doi = '10.1/scored', title = 'Zooplankton of the North Pacific', score = 500), Cand(score = 0.1)))
Expect(d$doi == '10.1/thing', 'the service relevance score never decides: the matching title wins over a high-scored stranger')
Expect(all(c('certain', 'pending', 'not_found', 'self') %in% match_statuses) &&
         all(c('weak_match', 'below_threshold', 'no_candidates', 'unscreened', 'two_service_agreement', 'closed_world', 'single_service', 'ambiguous',
               'grey_literature', 'retracted', 'doi_resolves', 'doi_mismatch') %in% match_reasons),
       'every status and reason code the rules emit is in the vocabularies')

cat('DecideMatch() with the screening file\n')
scite <- data.frame(doi = c('10.1/thing', '10.1/gap', '10.1/cons'), is_retracted = c('FALSE', NA, NA), notice_type = c('erratum', NA, 'unchecked'),
                    notice_doi = NA, checked_at = '2026-10-05', checked_by = c('scite-mcp', 'none', 'consensus-mcp'), stringsAsFactors = FALSE)
d <- DecideMatch(Ref(), open_cands = rbind(Cand(), Cand(service = 'openalex')), scite = scite)
Expect(d$match_status == 'pending' && d$match_reason == 'retracted' && d$services == 'crossref;openalex;scite-mcp' && Has(d$editorial_notice, 'scite-mcp:erratum'),
       'a Scite notice on the best DOI: pending / retracted and the screening service joins services')
d <- DecideMatch(Ref(), open_cands = rbind(Cand(doi = '10.1/gap'), Cand(service = 'openalex', doi = '10.1/gap')), scite = scite)
Expect(d$match_status == 'certain' && d$match_reason == 'two_service_agreement' && d$services == 'crossref;openalex' && is.na(d$editorial_notice),
       "a 'none' screening row (no service answered) is no notice: certain stands, no ';none' in services (selective policy, 2026-10-05)")
d <- DecideMatch(Ref(), open_cands = rbind(Cand(doi = '10.1/new'), Cand(service = 'openalex', doi = '10.1/new')), scite = scite)
Expect(d$match_status == 'certain' && d$services == 'crossref;openalex', 'a DOI without any screening row: certain on Crossref + OpenAlex alone')
d <- DecideMatch(Ref(), open_cands = rbind(Cand(doi = '10.1/cons'), Cand(service = 'openalex', doi = '10.1/cons')), scite = scite)
Expect(d$match_status == 'certain' && d$services == 'crossref;openalex;consensus-mcp' && is.na(d$editorial_notice),
       'a consensus-mcp row (unchecked) adds the service but is no notice: certain stands')
d <- DecideMatch(Ref(raw_doi = '10.1/thing'), doi_cands = Cand(), scite = scite)
Expect(d$match_status == 'pending' && d$match_reason == 'retracted' && d$services == 'crossref;openalex;scite-mcp', 'the screen applies to a resolving raw_doi as well')

# ---- the driver offline on four Kiorboe references ---------------------------------------------
cat('VerifyReference() and VerifyPrimaryReferences() offline on Kiorboe_2013 references 1, 6, 9, 12\n')
rl <- ParseRefListCSV(file.path(repo, 'sources', 'databases', 'Kiorboe_2013', 'Kiorboe2013_TableA1_references.csv'), key_col = 'Reference', citation_col = 'Citation')
prim <- InitPrimaryReferences('Kiorboe_2013', rl, c('1', '1; 6', '9', '12', '6', NA), compiler = 'Kiorboe')
d1 <- VerifyReference(prim[prim$native_key == '1', ], cfg)
Expect(d1$match_status == 'certain' && d1$match_reason == 'two_service_agreement' && d1$doi == '10.1016/j.jembe.2006.12.010' && d1$title_sim == 1 &&
         d1$author_match && d1$year_match && d1$container_match && d1$volume_match && d1$pages_match && d1$openalex_id == 'https://openalex.org/W2051884577',
       'Doyle et al. 2007: certain / two_service_agreement (abbreviated journal matched to the full name)')
d12 <- VerifyReference(prim[prim$native_key == '12', ], cfg)
Expect(d12$match_status == 'certain' && d12$match_reason == 'two_service_agreement' && d12$doi == '10.1007/bf00355587' && d12$title_sim > 0.93 && d12$author_match,
       'Omori 1969: certain / two_service_agreement (title with one extra word, diacritic surname)')
d6 <- VerifyReference(prim[prim$native_key == '6', ], cfg)
Expect(d6$match_status == 'certain' && d6$match_reason == 'two_service_agreement' && d6$doi == '10.1007/bf00392514' && d6$title_sim == 1 &&
         d6$author_match && d6$year_match && d6$container_match && d6$volume_match && d6$pages_match,
       'Ikeda & Bruce 1986: certain / two_service_agreement (the deposited title\'s "November?December" normalises to the same words as "November-December")')
d9 <- VerifyReference(prim[prim$native_key == '9', ], cfg)
Expect(d9$match_status == 'pending' && d9$match_reason == 'weak_match' && d9$doi == '10.23860/diss-2825' && d9$title_sim == 1 &&
         d9$author_match && !d9$year_match && d9$container_match && !d9$volume_match && !d9$pages_match && nrow(d9$candidates) >= 3,
       'Kremer 1976 (thesis): pending / weak_match (the Crossref dissertation record is dated 2025 and has no volume or pages)')
Expect(d9$candidates$doi[1] == '10.23860/diss-2825' && d9$candidates$services_for_doi[1] == 'crossref;openalex' &&
         d9$candidates$doi[2] == '10.1016/0302-3524(76)90071-2' && d9$candidates$title_sim[2] < 0.7,
       'the queue candidates are DOI-collapsed in score order: the dissertation (both services) then Kremer\'s 1976 paper')
res <- VerifyPrimaryReferences(prim, cfg, verified_at = '2026-10-05T00:00:00Z', progress = FALSE)
p <- res$prim
Expect(identical(p$match_status[match(c('1', '6', '9', '12'), p$native_key)], c('certain', 'certain', 'pending', 'certain')) &&
         all(p$verified_at == '2026-10-05T00:00:00Z') && all(p$tool_version == citations_tool_version) && all(p$services == 'crossref;openalex') &&
         identical(sort(names(res$candidates)), c('1', '12', '6', '9')),
       'VerifyPrimaryReferences() decides every undecided row, stamps verified_at and tool_version, keeps the candidates by key')
res2 <- VerifyPrimaryReferences(p, cfg, verified_at = '2026-10-06T00:00:00Z', progress = FALSE)
Expect(identical(res2$prim$verified_at[res2$prim$native_key %in% c('1', '6', '12')], rep('2026-10-05T00:00:00Z', 3)) &&
         identical(res2$prim$verified_at[res2$prim$native_key %in% c('9')], '2026-10-06T00:00:00Z'),
       'a re-run leaves certain rows alone and re-verifies pending rows')
res3 <- VerifyPrimaryReferences(p, cfg, force = TRUE, verified_at = '2026-10-07T00:00:00Z', progress = FALSE)
Expect(all(res3$prim$verified_at == '2026-10-07T00:00:00Z'), 'force = TRUE re-verifies certain rows too')
skip <- prim; skip$raw_citation[skip$native_key == '9'] <- NA; skip$role[skip$native_key == '12'] <- 'self'
res4 <- VerifyPrimaryReferences(skip, cfg, progress = FALSE)
Expect(is.na(res4$prim$match_status[res4$prim$native_key == '9']) && res4$prim$match_status[res4$prim$native_key == '12'] == 'self' &&
         res4$prim$match_reason[res4$prim$native_key == '12'] == 'self' && !'12' %in% names(res4$candidates),
       'rows without a raw_citation are skipped; self rows get status self without a service call')

cat('ApplySciteChecks()\n')
sc2 <- data.frame(doi = c('10.1016/j.jembe.2006.12.010', '10.1007/bf00355587', '10.23860/diss-2825'), is_retracted = c('FALSE', NA, NA),
                  notice_type = c('correction', NA, 'unchecked'), notice_doi = NA, checked_at = '2026-10-05',
                  checked_by = c('scite-mcp', 'none', 'consensus-mcp'), stringsAsFactors = FALSE)
q <- ApplySciteChecks(p, sc2, verified_at = '2026-10-08T00:00:00Z')
r1 <- q[q$native_key == '1', ]; r12 <- q[q$native_key == '12', ]; r9 <- q[q$native_key == '9', ]; r6 <- q[q$native_key == '6', ]
Expect(r1$match_status == 'pending' && r1$match_reason == 'retracted' && r1$services == 'crossref;openalex;scite-mcp' && Has(r1$editorial_notice, 'scite-mcp:correction') &&
         r1$verified_at == '2026-10-08T00:00:00Z',
       'a correction notice turns a certain row back to pending / retracted')
Expect(r12$match_status == 'certain' && r12$match_reason == 'two_service_agreement' && r12$services == 'crossref;openalex' && is.na(r12$editorial_notice) &&
         r12$verified_at == '2026-10-05T00:00:00Z',
       "a 'none' row leaves a certain row certain, untouched (selective policy)")
stale <- p; j <- which(stale$native_key == '12'); stale$services[j] <- 'crossref;openalex;none'
stale$editorial_notice[j] <- 'screening:none (no service answered; stays pending)'
stale$editorial_notice[stale$native_key == '6'] <- 'crossref:updated-by:erratum; screening:none (no service answered; stays pending)'
qs <- ApplySciteChecks(stale, rbind(sc2, data.frame(doi = '10.1007/bf00392514', is_retracted = NA, notice_type = NA, notice_doi = NA, checked_at = '2026-10-05', checked_by = 'none')))
Expect(qs$services[qs$native_key == '12'] == 'crossref;openalex' && is.na(qs$editorial_notice[qs$native_key == '12']) &&
         qs$editorial_notice[qs$native_key == '6'] == 'crossref:updated-by:erratum' && qs$match_status[qs$native_key == '6'] == 'certain',
       "the stale ';none' suffix and 'screening:none' note of the earlier rule are removed; other notices are kept")
Expect(is.na(DropGapNote(NA)) && is.na(DropGapNote('screening:none (no service answered; stays pending)')) &&
         DropGapNote('scite-mcp:erratum; screening:none (no service answered; stays pending)') == 'scite-mcp:erratum' &&
         DropGapNote('scite-mcp:erratum') == 'scite-mcp:erratum',
       'DropGapNote() removes only the gap note')
Expect(r9$match_status == 'pending' && r9$match_reason == 'weak_match' && r9$services == 'crossref;openalex;consensus-mcp' && is.na(r9$editorial_notice),
       'a consensus-mcp row only records the service on a pending row')
Expect(r6$services == 'crossref;openalex' && identical(ApplySciteChecks(p, NULL), p) && identical(ApplySciteChecks(p, sc2[0, ]), p),
       'DOIs without a screening row and an empty screening file leave rows unchanged')
sc4 <- rbind(sc2[2, ], data.frame(doi = '10.1007/bf00355587', is_retracted = NA, notice_type = 'waived', notice_doi = NA, checked_at = '2026-10-05',
                                  checked_by = 'owner-waiver', stringsAsFactors = FALSE))
q4 <- ApplySciteChecks(p, sc4, verified_at = '2026-10-08T00:00:00Z')
r12w <- q4[q4$native_key == '12', ]
Expect(r12w$match_status == 'certain' && r12w$services == 'crossref;openalex;owner-waiver' && is.na(r12w$editorial_notice) && !isTRUE(r12w$is_retracted),
       "an owner-waiver row after a 'none' row leaves a certain row certain and records the waiver in services")
sc3 <- data.frame(doi = '10.1016/j.jembe.2006.12.010', is_retracted = 'TRUE', notice_type = 'retraction', notice_doi = NA, checked_at = '2026-10-05', checked_by = 'scite-mcp', stringsAsFactors = FALSE)
q3 <- ApplySciteChecks(q, sc3)
Expect(q3$is_retracted[q3$native_key == '1'] && q3$services[q3$native_key == '1'] == 'crossref;openalex;scite-mcp' && Has(q3$editorial_notice[q3$native_key == '1'], 'scite-mcp:retraction'),
       'a retraction sets is_retracted; the screening service is not duplicated in services')

# ---- the screening list -------------------------------------------------------------------------
cat('ScreeningCandidates(), ScreeningSeed(), LatestScreen()\n')
SRow <- function(key, doi, status = 'certain', reason = 'two_service_agreement', services = 'crossref;openalex', year = 2001L,
                 citation = 'Doe, J. 2001. A study of things. J Things 5: 1-10.', notice = NA_character_, retracted = FALSE, role = 'measurement', n = 2L)
  data.frame(source_label = 'Src', native_key = key, n_records = n, role = role, raw_citation = citation, parsed_year = year, doi = doi,
             match_status = status, match_reason = reason, services = services, is_retracted = retracted, editorial_notice = notice, stringsAsFactors = FALSE)
sp <- rbind(SRow('n1', '10.1/notice', 'pending', 'retracted', notice = 'crossref:updated-by:erratum'),
            SRow('n2', '10.1/oaret', 'pending', 'retracted', retracted = TRUE),
            SRow('s1', '10.1/single', 'pending', 'single_service', services = 'crossref'),
            SRow('s2', '10.1/onesvc', 'approved', 'owner_doi', services = 'crossref'),
            SRow('a1', '10.1/amb', 'pending', 'ambiguous'),
            SRow('g1', '10.1/grey', 'pending', 'grey_literature', citation = 'Doe, J. 2001. A study. Ph.D. thesis, Some University.'),
            SRow('g2', '10.1/thesis', 'approved', 'owner_candidate', citation = 'Roe, R. 1999. Things. Technical report 12.'),
            SRow('d1', '10.1/dup'), SRow('d2', '10.1/dup'),
            SRow('m1', '10.1/mism', 'pending', 'doi_mismatch'),
            SRow('o1', '10.1/old', year = 1931L),
            SRow('x1', '10.1/self', 'self', 'self', role = 'self'), SRow('x2', '10.1/drop', 'rejected', 'owner_drop'),
            SRow('x3', NA_character_, 'nodoi_approved', 'owner_nodoi'),
            SRow('z1', '10.1/scited', 'certain', 'two_service_agreement'),
            SRow('z2', '10.1/scitednotice', 'pending', 'retracted', notice = 'scite-mcp:erratum'),
            do.call(rbind, lapply(1:40, function(k) SRow(sprintf('c%02d', k), sprintf('10.1/c%02d', k)))))
ssc <- data.frame(doi = c('10.1/scited', '10.1/scitednotice', '10.1/c01', '10.1/c02', '10.1/c03'), is_retracted = c('FALSE', 'FALSE', NA, NA, NA),
                  notice_type = c('none', 'erratum', 'unchecked', 'unchecked', NA), notice_doi = NA, checked_at = '2026-10-05',
                  checked_by = c('scite-mcp', 'scite-mcp', 'consensus-mcp', 'consensus-mcp', 'none'), stringsAsFactors = FALSE)
cl <- ScreeningCandidates(sp, ssc, date = as.Date('2026-10-05'))
Get <- function(k) cl[cl$native_key == k, ]
Expect(Get('n1')$category == 'notice' && Get('n1')$reason == 'retracted' && Get('n2')$category == 'notice',
       'a DOI with a Crossref notice or the OpenAlex retraction flag is listed under notice')
Expect(Get('s1')$category == 'disagreement' && Get('s1')$reason == 'single_service' && Get('s2')$reason == 'single_service' &&
         Get('a1')$reason == 'ambiguous' && Get('a1')$category == 'disagreement',
       'single_service and ambiguous rows, and an accepted row one service answered, are listed under disagreement')
Expect(Get('g1')$reason == 'grey_literature' && Get('g2')$reason == 'grey_literature' && Get('d1')$reason == 'duplicate_doi' && Get('d2')$reason == 'duplicate_doi' &&
         Get('m1')$reason == 'doi_mismatch' && Get('o1')$reason == 'old_journal' && all(cl$category[cl$native_key %in% c('g1', 'g2', 'd1', 'd2', 'm1', 'o1')] == 'doubtful'),
       'grey literature (by reason or by the citation text), a DOI shared by two keys, a mismatching source DOI and an old journal are doubtful')
Expect(!any(c('x1', 'x2', 'x3', 'z1') %in% cl$native_key) && Get('z2')$category == 'notice' && Get('z2')$screened_by == 'scite-mcp',
       'self, rejected and DOI-less rows are never listed; a DOI screened by scite-mcp only when it carries a notice')
samp <- cl[cl$category == 'audit_sample', ]
Expect(attr(cl, 'n_new_certain') == 38 && attr(cl, 'n_sample') == 3 && nrow(samp) == 3 && all(grepl('^c', samp$native_key)) &&
         !any(samp$native_key %in% c('c01', 'c02')) && all(samp$match_status == 'certain') && all(samp$reason == 'audit_sample'),
       'the audit sample: 5% of the 38 newly certain DOIs (the two Consensus-screened and the Scite-screened ones excluded, the none-screened one and the listed ones not in the pool) is below the floor of 3, so 3 are drawn')
big <- rbind(sp, do.call(rbind, lapply(41:120, function(k) SRow(sprintf('c%03d', k), sprintf('10.1/c%03d', k)))))
clb <- ScreeningCandidates(big, ssc, date = as.Date('2026-10-05'))
Expect(attr(clb, 'n_new_certain') == 118 && attr(clb, 'n_sample') == 6 && sum(clb$category == 'audit_sample') == 6 &&
         attr(ScreeningCandidates(big, ssc, sample_frac = 0.10, date = as.Date('2026-10-05')), 'n_sample') == 12 &&
         attr(ScreeningCandidates(big, ssc, min_sample = 10L, date = as.Date('2026-10-05')), 'n_sample') == 10,
       'with 118 newly certain DOIs the 5% sample is 6 (ceiling); sample_frac and min_sample are honoured')
cl2 <- ScreeningCandidates(sp, ssc, date = as.Date('2026-10-05'))
cl3 <- ScreeningCandidates(sp, ssc, date = as.Date('2026-10-06'))
Expect(identical(cl, cl2) && attr(cl, 'seed') == ScreeningSeed('Src', as.Date('2026-10-05')) && attr(cl, 'date') == '2026-10-05' &&
         attr(cl3, 'seed') != attr(cl, 'seed') && identical(ScreeningCandidates(sp, ssc, seed = attr(cl, 'seed'))$native_key, cl$native_key),
       'the draw is deterministic: the same source and date give the same list, another date another seed, and the seed can be passed back')
set.seed(1); before <- runif(1); set.seed(1); invisible(ScreeningCandidates(sp, ssc, date = as.Date('2026-10-05'))); after <- runif(1)
Expect(identical(before, after), 'the draw restores the random state of the session')
Expect(!anyDuplicated(cl$native_key) && identical(cl$category, cl$category[order(match(cl$category, screening_categories))]) &&
         all(cl$reason %in% unlist(lapply(strsplit(cl$reason, ';'), identity))) && all(unlist(strsplit(cl$reason, ';')) %in% screening_list_reasons) &&
         nrow(ScreeningCandidates(sp[sp$match_status == 'self', ], ssc)) == 0 && nrow(ScreeningCandidates(sp, NULL, date = as.Date('2026-10-05'))) >= nrow(cl) - 0,
       'one row per key in category order, every reason code in the vocabulary, an empty frame gives an empty list, no screening file is allowed')
Expect(LatestScreen('10.1/scited', ssc) == 'scite-mcp' && LatestScreen('10.1/c01', ssc) == 'consensus-mcp' && LatestScreen('10.1/c03', ssc) == 'none' &&
         LatestScreen('10.1/c04', ssc) == '' && LatestScreen('10.1/c04', NULL) == '',
       'LatestScreen(): the service of record, none for a gap, empty without a row')

# ---- the queue --------------------------------------------------------------------------------
cat('WritePendingQueue(), ReadPendingQueue()\n')
qf <- tempfile(fileext = '.csv')
Expect(nrow(ReadPendingQueue(qf)) == 0 && identical(names(ReadPendingQueue(qf)), pending_queue_columns), 'a missing queue file reads as empty with the schema')
queue <- WritePendingQueue(p, res$candidates, qf, queued_at = '2026-10-05')
Expect(nrow(queue) == 1 && identical(queue$native_key, '9') && all(queue$source_label == 'Kiorboe_2013') && all(queue$queued_at == '2026-10-05') &&
         identical(names(queue), pending_queue_columns),
       'only the pending row is queued, with the schema columns')
r9q <- queue[queue$native_key == '9', ]
Expect(r9q$reason == 'weak_match' && r9q$c1_doi == '10.23860/diss-2825' && r9q$c1_services == 'crossref;openalex' && r9q$c1_title_sim == '1' && r9q$c1_year == '2025' &&   # the Crossref deposit year of the digitised thesis
         r9q$c2_doi == '10.1016/0302-3524(76)90071-2' && r9q$c2_author1 == 'Kremer' && r9q$c3_doi == '10.2307/1351633' && r9q$n_records == '1' && r9q$parsed_year == '1976' &&
         startsWith(r9q$raw_citation, 'Kremer, P. 1976.') && is.na(r9q$decision),
       'a queue row carries the reason, the parsed fields and the top three DOI-collapsed candidates')
r6q <- QueueRow(p[p$native_key == '6', ], res$candidates[['6']], '2026-10-05')
Expect(r6q$c1_doi == '10.1007/bf00392514' && startsWith(r6q$raw_citation, '———, and B. Bruce. 1986.') && r6q$parsed_author1 == 'Ikeda' && r6q$c1_services == 'crossref;openalex',
       'a queue row keeps raw_citation verbatim (dashes kept); parsed_author1 is the expanded surname')
queue2 <- WritePendingQueue(p, res$candidates, qf, queued_at = '2026-10-06')
Expect(nrow(queue2) == 1 && identical(queue2$queued_at, '2026-10-05'), 'a second --queue appends nothing for rows already open (idempotent)')
back <- ReadPendingQueue(qf)
Expect(identical(back$native_key, queue$native_key) && identical(back$c1_doi, queue$c1_doi) && is.na(back$decision[1]), 'the queue file round-trips')
decided <- back; decided$decision <- '1'; decided$decided_by <- 'MN'; decided$decided_at <- '2026-10-06'
WritePendingQueueFile(decided, qf)
queue3 <- WritePendingQueue(p, res$candidates, qf, queued_at = '2026-10-07')
Expect(nrow(queue3) == 2 && identical(queue3$native_key, c('9', '9')) && queue3$decision[1] == '1' && is.na(queue3$decision[2]) && queue3$queued_at[2] == '2026-10-07',
       'a decided row is never rewritten; a still-pending reference is queued again as a new row')
Expect(Has(ErrorOf(ReadPendingQueue({ f <- tempfile(fileext = '.csv'); writeLines('a,b', f); f })), 'lacks column'), 'a queue file without the schema stops')

cat('ValidateDecision(), ApplyQueueDecisions()\n')
Expect(all(ValidateDecision(c('1', '2', '3', 'doi:10.1007/bf00392514', 'manual:Ikeda:1986aa', 'manual:Van-der-Meer:1994aa', 'nodoi', 'self', 'drop', ' drop ',
                                '1:year=1976', 'doi:10.1007/bf00392514:year=1986', 'nodoi:year=1976'))) &&
         !any(ValidateDecision(c('4', '0', 'doi:abc', 'doi:10.1/', 'manual:', 'manual:1abc', 'yes', '', 'nodoi ok', '1:year=76', '1:year=1976x', '1:yr=1976'))),
       'the decision grammar: 1|2|3, doi:10..., manual:<Key>, nodoi, self, drop, with an optional :year=YYYY suffix')
Expect(identical(SplitDecision('1:year=1976'), list(action = '1', year = 1976L)) && identical(SplitDecision('doi:10.1007/bf00392514:year=1986'), list(action = 'doi:10.1007/bf00392514', year = 1986L)) &&
         identical(SplitDecision(' nodoi '), list(action = 'nodoi', year = NA_integer_)),
       'SplitDecision() separates the action from the year override')
Q <- function(key, decision, by = 'MN', at = '2026-10-06', c1 = '10.1007/bf00392514', c2 = NA, c1_sim = '0.906', c1_services = 'crossref;openalex') {
  row <- as.data.frame(as.list(setNames(rep(NA_character_, length(pending_queue_columns)), pending_queue_columns)), stringsAsFactors = FALSE)
  row$source_label <- 'Kiorboe_2013'; row$native_key <- key; row$decision <- decision; row$decided_by <- by; row$decided_at <- at
  row$c1_doi <- c1; row$c2_doi <- c2; row$c1_title_sim <- c1_sim; row$c1_services <- c1_services
  row
}
base <- prim
base$match_status[base$native_key %in% c('1', '6', '9', '12')] <- 'pending'
qd <- rbind(Q('6', '1'), Q('9', 'nodoi'), Q('12', 'manual:Omori:1969aa'), Q('1', 'drop'), Q('99', 'self'))
a <- ApplyQueueDecisions(qd, base)
Expect(a$match_status[a$native_key == '6'] == 'approved' && a$match_reason[a$native_key == '6'] == 'owner_candidate' && a$doi[a$native_key == '6'] == '10.1007/bf00392514' &&
         a$title_sim[a$native_key == '6'] == 0.906 && a$services[a$native_key == '6'] == 'crossref;openalex' && a$decided_by[a$native_key == '6'] == 'MN' && a$decided_at[a$native_key == '6'] == '2026-10-06',
       "decision '1': approved / owner_candidate with the candidate's DOI, similarity and services")
Expect(a$match_status[a$native_key == '9'] == 'nodoi_approved' && a$match_reason[a$native_key == '9'] == 'owner_nodoi' && is.na(a$doi[a$native_key == '9']),
       "decision 'nodoi': nodoi_approved without a DOI")
Expect(a$match_status[a$native_key == '12'] == 'approved' && a$match_reason[a$native_key == '12'] == 'manual_bib' && a$bibcite[a$native_key == '12'] == 'Omori:1969aa',
       "decision 'manual:<Key>': approved / manual_bib with the curated key")
Expect(a$match_status[a$native_key == '1'] == 'rejected' && a$match_reason[a$native_key == '1'] == 'owner_drop', "decision 'drop': rejected / owner_drop")
Expect(!'99' %in% a$native_key && nrow(a) == nrow(base), 'a decision for a key the file lacks is ignored')
s <- ApplyQueueDecisions(Q('6', 'self'), base)
Expect(s$match_status[s$native_key == '6'] == 'self' && s$match_reason[s$native_key == '6'] == 'owner_self' && s$role[s$native_key == '6'] == 'self', "decision 'self': status and role self")
a2 <- ApplyQueueDecisions(Q('6', 'doi:10.1007/BF00392514'), base, cfg)
Expect(a2$match_status[a2$native_key == '6'] == 'approved' && a2$match_reason[a2$native_key == '6'] == 'owner_doi' && a2$doi[a2$native_key == '6'] == '10.1007/bf00392514' &&
         a2$services[a2$native_key == '6'] == 'crossref' && a2$author_match[a2$native_key == '6'] && a2$volume_match[a2$native_key == '6'] && a2$title_sim[a2$native_key == '6'] > 0.9 &&
         !is.na(a2$verified_at[a2$native_key == '6']),
       "decision 'doi:': re-verified at Crossref (cached), approved / owner_doi with fresh agreement flags")
Expect(Has(ErrorOf(ApplyQueueDecisions(Q('6', 'doi:10.9999/this-doi-does-not-exist'), base, cfg)), 'does not resolve at Crossref'), 'a doi: decision that does not resolve stops')
Expect(Has(ErrorOf(ApplyQueueDecisions(Q('6', 'doi:10.1007/bf00392514'), base)), 'needs cfg'), 'a doi: decision without cfg stops')
Expect(Has(ErrorOf(ApplyQueueDecisions(Q('6', 'maybe'), base)), 'does not match the grammar'), 'an invalid decision stops')
Expect(Has(ErrorOf(ApplyQueueDecisions(Q('6', '1', by = NA), base)), 'decided_by is empty'), 'a decision without decided_by stops')
Expect(Has(ErrorOf(ApplyQueueDecisions(Q('6', '1', at = 'yesterday'), base)), 'decided_at is not an ISO date'), 'a decision without an ISO decided_at stops')
Expect(Has(ErrorOf(ApplyQueueDecisions(Q('6', '2'), base)), 'candidate 2 has no DOI'), 'picking a candidate the row does not have stops')
Expect(Has(ErrorOf(ApplyQueueDecisions(rbind(Q('6', 'x'), Q('9', '1', by = '')), base)), 'does not match the grammar') &&
         Has(ErrorOf(ApplyQueueDecisions(rbind(Q('6', 'x'), Q('9', '1', by = '')), base)), 'decided_by is empty'),
       'every problem is reported in one stop')
again <- ApplyQueueDecisions(Q('6', '1'), a)
Expect(identical(again, a), 'an already applied decision (same decided_at) is a no-op')
yo <- ApplyQueueDecisions(Q('9', '1:year=1976', c1 = '10.23860/diss-2825'), base)
Expect(yo$match_status[yo$native_key == '9'] == 'approved' && yo$doi[yo$native_key == '9'] == '10.23860/diss-2825' && yo$year_override[yo$native_key == '9'] == 1976L &&
         is.na(yo$year_override[yo$native_key == '6']),
       "'1:year=1976' approves the candidate and records the year override on that row only")
yo2 <- ApplyQueueDecisions(Q('6', 'doi:10.1007/bf00392514:year=1985'), base, cfg)
Expect(yo2$match_status[yo2$native_key == '6'] == 'approved' && yo2$match_reason[yo2$native_key == '6'] == 'owner_doi' && yo2$year_override[yo2$native_key == '6'] == 1985L,
       'a doi: decision takes the year override too')
Expect(Has(ErrorOf(ApplyQueueDecisions(Q('9', 'nodoi:year=1976'), base)), 'a year override needs a candidate or doi: decision'),
       'a year override on nodoi / self / drop stops')
Expect(identical(ApplyQueueDecisions(Q('6', NA), base), base) && identical(ApplyQueueDecisions(Q('6', '  '), base), base), 'rows without a decision change nothing')

cat('DecideMatch() without OpenAlex (service_unavailable), WritePendingQueue() skip\n')
d <- DecideMatch(Ref(raw_doi = '10.1/thing'), doi_cands = Cand(), services = 'crossref')
Expect(d$match_status == 'pending' && d$match_reason == 'service_unavailable' && d$doi == '10.1/thing' && d$services == 'crossref',
       'a resolving source DOI without OpenAlex: pending / service_unavailable, the Crossref candidate kept')
d <- DecideMatch(Ref(), open_cands = Cand(), services = 'crossref')
Expect(d$match_status == 'pending' && d$match_reason == 'service_unavailable', 'a strong single-service match without OpenAlex: service_unavailable, not single_service')
d <- DecideMatch(Ref(), open_cands = Cand(title = 'Completely different title'), services = 'crossref')
Expect(d$match_status == 'pending' && d$match_reason == 'service_unavailable', 'below threshold without OpenAlex: service_unavailable, not not_found')
d <- DecideMatch(Ref(), services = 'crossref')
Expect(d$match_status == 'pending' && d$match_reason == 'service_unavailable', 'no candidates without OpenAlex: service_unavailable')
d <- DecideMatch(Ref(raw_doi = '10.1/thing'), doi_cands = Cand(title = 'Completely different title', author1 = 'Roe'), services = 'crossref')
Expect(d$match_status == 'pending' && d$match_reason == 'doi_mismatch', 'a disagreeing source DOI is still doi_mismatch without OpenAlex (owner matter)')
d <- DecideMatch(Ref(raw_citation = 'Doe, J. 2001. Unpublished thesis.'), open_cands = Cand(title = 'Completely different title'), services = 'crossref')
Expect(d$match_status == 'pending' && d$match_reason == 'grey_literature', 'grey literature is still grey_literature without OpenAlex (owner matter)')
Expect(DecideMatch(Ref(role = 'self'), services = 'crossref')$match_status == 'self', 'a self reference is self without OpenAlex')
p2 <- EmptyPrimaryReferences()
p2[1:2, 'native_key'] <- c('u', 'g'); p2$source_label <- 'SrcU'; p2$raw_citation <- c('Doe 2001', 'Roe 1999 thesis'); p2$n_records <- 1L
p2$match_status <- 'pending'; p2$match_reason <- c('service_unavailable', 'grey_literature'); p2$editorial_notice <- NA_character_
qf2 <- tempfile(fileext = '.csv')
q2 <- WritePendingQueue(p2, list(), qf2, queued_at = '2026-10-05')
Expect(nrow(q2) == 1 && q2$native_key == 'g' && q2$reason == 'grey_literature', 'WritePendingQueue() queues the grey-literature row but not the service_unavailable row')

cat(sprintf('\n%d checks, %d failed\n', n_checks, length(failures)))
if (length(failures) > 0) { cat(paste0('  FAIL: ', failures, '\n'), sep = ''); quit(status = 1) }
