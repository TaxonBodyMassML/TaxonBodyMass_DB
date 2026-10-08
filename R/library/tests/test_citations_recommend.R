# Tests for the recommender of the citation tooling (issue #1):
# R/library/citations/recommend.r. Every rule of the table in the README
# (section "Recommendations") is exercised on synthetic queue rows;
# RecommendDecisions() on a small queue with agent, owner and decided rows,
# and on the tracked queue for the invariants (every recommendation in the
# grammar, every recommended_by a rule, determinism). No network access.
#
#   Rscript R/library/tests/test_citations_recommend.R      (from any directory)
#
# Prints one line per expectation and exits with status 1 if any failed.

this_file <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE))
if (length(this_file) == 0)
  this_file <- file.path('R', 'library', 'tests', 'test_citations_recommend.R')
repo <- normalizePath(file.path(dirname(this_file), '..', '..', '..'))
lib  <- file.path(repo, 'R', 'library')
source(file.path(lib, 'helpers.r'))
source(file.path(lib, 'dedupe_sources.r'))        # MarkdownTable()
for (f in c('citations_config.r', 'normalise_citation.r', 'parse_reflists.r', 'verify_services.r', 'decide.r', 'recommend.r', 'provenance.r'))
  source(file.path(lib, 'citations', f))

failures <- character(0)
n_checks <- 0L
Expect <- function(ok, what) {
  n_checks <<- n_checks + 1L
  if (!isTRUE(ok)) failures <<- c(failures, what)
  cat(sprintf('  %s %s\n', if (isTRUE(ok)) 'ok  ' else 'FAIL', what))
}

# ---- synthetic queue rows -------------------------------------------------------------------
# a complete, titled weak_match row with one Crossref candidate at 0.95 and the right year
QRow <- function(key = 'k', reason = 'weak_match', author1 = 'Doe', year = '2001', title = 'A study of things', container = 'J Things',
                 volume = '5', pages = '1-10', c1 = '10.1000/thing', c1_sim = '0.95', c1_year = '2001', c1_services = 'crossref',
                 c2 = NA, c2_sim = NA, c2_year = NA, c2_services = NA, scite_note = NA, decision = NA, src = 'Src', queued = '2026-10-06') {
  row <- as.data.frame(as.list(setNames(rep(NA_character_, length(pending_queue_columns)), pending_queue_columns)), stringsAsFactors = FALSE)
  row$queued_at <- queued; row$source_label <- src; row$native_key <- key; row$n_records <- '1'; row$reason <- reason
  row$raw_citation <- 'Doe, J. 2001. A study of things. J Things 5: 1-10.'
  row$parsed_author1 <- author1; row$parsed_year <- year; row$parsed_title <- title; row$parsed_container <- container
  row$parsed_volume <- volume; row$parsed_pages <- pages
  row$c1_doi <- c1; row$c1_title_sim <- c1_sim; row$c1_year <- c1_year; row$c1_services <- c1_services; row$c1_title <- if (is.na(c1)) NA else 'A study of things'
  row$c2_doi <- c2; row$c2_title_sim <- c2_sim; row$c2_year <- c2_year; row$c2_services <- c2_services; row$c2_title <- if (is.na(c2)) NA else 'A study of things'
  row$scite_note <- scite_note; row$decision <- decision
  if (!is.na(decision)) { row$decided_by <- 'owner'; row$decided_at <- '2026-10-06' }
  row
}
PRow <- function(role = 'measurement', owner_review = NA) list(role = role, owner_review = owner_review)
R <- function(row, prim = PRow()) RecommendRow(row, prim)

cat('FieldsComplete(), MissingFields(), IsJSTOR(), CandidateStrong()\n')
Expect(FieldsComplete(QRow()) && !FieldsComplete(QRow(container = NA)) && !FieldsComplete(QRow(author1 = '')) && identical(MissingFields(QRow(author1 = NA, year = ' ')), c('author1', 'year')) &&
         length(MissingFields(QRow())) == 0,
       'the four fields that make a nodoi entry: author1, year, title, container; blanks count as missing')
Expect(IsJSTOR('10.2307/1234') && IsJSTOR('10.2307/x') && !IsJSTOR('10.1000/thing') && !IsJSTOR(NA), 'a JSTOR DOI starts with 10.2307/')
Expect(CandidateStrong(QRow(), 1) && CandidateStrong(QRow(c1_sim = '0.90'), 1) && !CandidateStrong(QRow(c1_sim = '0.89'), 1),
       'strong needs title_sim >= 0.90 (0.90 yes, 0.89 no)')
Expect(CandidateStrong(QRow(c1_year = '2002'), 1) && CandidateStrong(QRow(c1_year = '2000'), 1) && !CandidateStrong(QRow(c1_year = '2003'), 1) &&
         !CandidateStrong(QRow(c1_year = NA), 1) && !CandidateStrong(QRow(year = NA), 1),
       'the year within 1 of the parsed year (2 off, or either year unknown, is not strong)')
Expect(!CandidateStrong(QRow(c1_services = 'openalex'), 1) && CandidateStrong(QRow(c1_services = 'openalex'), 1, need_crossref = FALSE) &&
         CandidateStrong(QRow(c1_services = 'openalex;crossref'), 1) && !CandidateStrong(QRow(c1 = NA), 1) && !CandidateStrong(QRow(), 2),
       'Crossref must have returned the candidate (unless need_crossref = FALSE); no candidate is not strong')

cat('RecommendRow(): the rules in order of precedence\n')
r <- R(QRow(), PRow(role = 'self'))
Expect(r$recommendation == 'self' && r$rule == 'self_role', 'self_role: a self reference -> self')
r <- R(QRow(), PRow(owner_review = 'book chapter cited without the chapter'))
Expect(is.na(r$recommendation) && r$rule == 'owner_review_flagged' && grepl('book chapter', r$reason), 'owner_review_flagged: empty, the review text as the reason')
r <- R(QRow(title = NA, author1 = NA))
Expect(is.na(r$recommendation) && r$rule == 'titleless_journal_key' && grepl('#128', r$reason) && grepl('container-filtered', r$reason) && grepl('cite:', r$reason, fixed = TRUE),
       'titleless_journal_key: no title, container + volume + pages present, no agreeing candidate -> empty (the reason names both queries and the cite: route)')
Expect(R(QRow(title = NA, author1 = NA, reason = 'below_threshold', c1 = '10.1/a', c2 = '10.1/b', c1_sim = '0', c2_sim = '0'))$rule == 'titleless_journal_key',
       'titleless_journal_key: candidates that did not agree (below_threshold) give no recommendation')
r <- R(QRow(title = NA, author1 = NA, reason = 'ambiguous', c1 = '10.1644/1545-1542(2002)083<0001:sotacs>2.0.co;2', c2 = '10.1093/jmammal/83.1.1', c1_sim = '0', c2_sim = '0', c2_services = 'crossref'))
Expect(r$recommendation == '1' && r$rule == 'titleless_twin' && grepl('c1 10.1644', r$reason, fixed = TRUE) && grepl('change to 2', r$reason, fixed = TRUE),
       'titleless_twin: a title-less key whose two Crossref candidates agree on journal, volume, page and year (reason ambiguous, #128) -> 1, the top-scored one')
r <- R(QRow(title = NA, author1 = NA, reason = 'ambiguous', c1 = '10.2307/1382000', c2 = '10.1093/jmammal/83.1.1', c1_sim = '0', c2_sim = '0', c2_services = 'crossref'))
Expect(r$recommendation == '2' && r$rule == 'titleless_twin' && grepl('JSTOR', r$reason), 'titleless_twin: the publisher DOI over the JSTOR twin')
Expect(R(QRow(title = NA, author1 = NA, reason = 'ambiguous', c1 = '10.1/a', c2 = '10.1/b', c1_sim = '0', c2_sim = '0', c2_services = 'openalex'))$rule == 'titleless_journal_key' &&
         R(QRow(title = NA, author1 = NA, reason = 'ambiguous', c1 = '10.1/a', c2 = NA, c1_sim = '0'))$rule == 'titleless_journal_key',
       'titleless_twin needs both twins from Crossref')
Expect(CrossrefReturned(QRow(), 1) && !CrossrefReturned(QRow(c1_services = 'openalex'), 1) && !CrossrefReturned(QRow(c2 = NA), 2) && !CrossrefReturned(QRow(c1_services = NA), 1),
       'CrossrefReturned(): a DOI with crossref among its services')
r <- R(QRow(title = NA, author1 = NA, volume = NA))
Expect(r$recommendation == 'drop' && r$rule == 'titleless_incomplete', 'titleless_incomplete: no title and no whole journal key -> drop')
r <- R(QRow(reason = 'retracted', scite_note = 'crossref:updated-by:correction', c1_sim = '1'))
Expect(r$recommendation == '1' && r$rule == 'correction_notice', 'correction_notice: a correction / erratum note, candidate 1 at >= 0.95 and the right year -> 1')
Expect(R(QRow(reason = 'retracted', scite_note = 'crossref:updated-by:erratum', c1_sim = '0.96'))$rule == 'correction_notice' &&
         R(QRow(reason = 'retracted', scite_note = 'crossref:updated-by:corrigendum', c1_sim = '1'))$rule == 'correction_notice',
       'erratum and corrigendum count as corrections')
r <- R(QRow(reason = 'retracted', scite_note = 'openalex:is_retracted', c1_sim = '1'))
Expect(is.na(r$recommendation) && r$rule == 'retraction_notice', 'retraction_notice: a retraction note -> empty')
Expect(R(QRow(reason = 'retracted', scite_note = 'crossref:updated-by:correction', c1_sim = '0.94'))$rule == 'retraction_notice' &&
         R(QRow(reason = 'retracted', scite_note = 'correction; retraction', c1_sim = '1'))$rule == 'retraction_notice' &&
         R(QRow(reason = 'retracted', scite_note = NA, c1_sim = '1'))$rule == 'retraction_notice',
       'a correction under 0.95, a note that also says retraction, and no note at all are left to the owner')
twin <- QRow(reason = 'ambiguous', c1 = '10.2307/1234', c1_sim = '1', c2 = '10.1000/thing', c2_sim = '1', c2_year = '2001', c2_services = 'crossref')
r <- R(twin)
Expect(r$recommendation == '2' && r$rule == 'jstor_twin', 'jstor_twin: JSTOR in c1, the publisher DOI in c2 -> 2')
r <- R(QRow(reason = 'ambiguous', c1 = '10.1000/thing', c1_sim = '1', c2 = '10.2307/1234', c2_sim = '1', c2_year = '2001', c2_services = 'crossref'))
Expect(r$recommendation == '1' && r$rule == 'jstor_twin', 'jstor_twin: JSTOR in c2 -> 1')
r <- R(QRow(reason = 'weak_match', c1 = '10.2307/1234', c1_sim = '0.95', c2 = '10.1000/thing', c2_sim = '0.95', c2_year = '2001', c2_services = 'crossref'))
Expect(r$recommendation == '2' && r$rule == 'jstor_twin', 'jstor_twin does not depend on the reason code')
Expect(R(QRow(reason = 'ambiguous', c1 = '10.2307/1234', c1_sim = '1', c2 = '10.1000/thing', c2_sim = '0.89', c2_year = '2001', c2_services = 'crossref'))$rule != 'jstor_twin',
       'both twins must be strong')
r <- R(QRow(reason = 'ambiguous', c1 = '10.1000/a', c1_sim = '1', c2 = '10.1111/b', c2_sim = '0.98', c2_year = '2001', c2_services = 'crossref'))
Expect(r$recommendation == '1' && r$rule == 'publisher_twin' && grepl('c1 10.1000/a, c2 10.1111/b', r$reason, fixed = TRUE) && grepl('change to 2', r$reason),
       'publisher_twin: two strong publisher DOIs on an ambiguous row -> 1, both DOIs in the reason (owner policy 2026-10-06)')
Expect(R(QRow(reason = 'weak_match', c1 = '10.1000/a', c1_sim = '1', c2 = '10.1111/b', c2_sim = '0.98', c2_year = '2001', c2_services = 'crossref'))$rule == 'strong_candidate',
       'publisher_twin needs the ambiguous reason; otherwise the strong first candidate stands')
r <- R(QRow(c1_sim = '0.90'))
Expect(r$recommendation == '1' && r$rule == 'strong_candidate' && grepl('title_sim 0.90', r$reason), 'strong_candidate: sim 0.90 -> 1')
r <- R(QRow(c1_sim = '0.89'))
Expect(r$recommendation == 'nodoi' && r$rule == 'fields_complete_no_match' && grepl('0.89 is another work', r$reason), 'sim 0.89: not strong, fields complete -> nodoi')
Expect(R(QRow(c1_year = '2002'))$rule == 'strong_candidate' && R(QRow(c1_year = '1999'))$rule == 'fields_complete_no_match', 'year 1 off is strong, 2 off is not')
r <- R(QRow(c1_services = 'openalex'))
Expect(r$recommendation == 'nodoi' && r$rule == 'openalex_only_candidate' && grepl('doi:10.1000/thing', r$reason, fixed = TRUE),
       'openalex_only_candidate: a strong candidate Crossref did not return -> nodoi (fields complete), the doi: proposal in the reason')
Expect(R(QRow(c1_services = 'openalex', container = NA))$recommendation == 'drop' && R(QRow(c1_services = 'openalex', container = NA))$rule == 'openalex_only_candidate',
       'openalex_only_candidate with incomplete fields -> drop')
r <- R(QRow(reason = 'grey_literature', c1 = NA, c1_sim = NA, c1_year = NA, c1_services = NA, container = 'Ph.D. thesis, Univ. of Rhode Island'))
Expect(r$recommendation == 'nodoi' && r$rule == 'grey_complete', 'grey_complete: grey literature with complete fields -> nodoi')
r <- R(QRow(reason = 'grey_literature', c1 = NA, c1_sim = NA, c1_year = NA, c1_services = NA, container = NA))
Expect(r$recommendation == 'drop' && r$rule == 'fields_incomplete' && grepl('missing: container', r$reason), 'grey literature with a missing field -> drop (fields_incomplete)')
r <- R(QRow(reason = 'no_candidates', c1 = NA, c1_sim = NA, c1_year = NA, c1_services = NA))
Expect(r$recommendation == 'nodoi' && r$rule == 'fields_complete_no_match' && r$reason == 'no candidate', 'no candidate, fields complete -> nodoi')
r <- R(QRow(reason = 'no_candidates', c1 = NA, c1_sim = NA, c1_year = NA, c1_services = NA, author1 = NA, year = NA))
Expect(r$recommendation == 'drop' && r$rule == 'fields_incomplete' && grepl('missing: author1, year; complete parsed_\\* and decide nodoi', r$reason),
       'no candidate, fields incomplete -> drop naming the missing fields (owner policy 2026-10-06)')
Expect(R(QRow(), NULL)$rule == 'strong_candidate', 'a row without a primary_references line is recommended on the queue alone')
Expect(R(QRow(title = NA, author1 = NA), PRow(owner_review = 'x'))$rule == 'owner_review_flagged' && R(QRow(title = NA), PRow(role = 'self'))$rule == 'self_role',
       'precedence: self before owner_review before the title rules')

cat('RecommendDecisions()\n')
q <- rbind(QRow('a'), QRow('b', c1_sim = '0.5'), QRow('c', decision = 'nodoi'), QRow('d', src = 'Other', c1_sim = '0.5', container = NA), QRow('e'), QRow('f'))
q$recommendation[5] <- 'drop'; q$recommendation_reason[5] <- 'read the PDF'; q$recommended_by[5] <- 'agent'
q$recommendation[6] <- 'nodoi'; q$recommended_by[6] <- 'owner'
q$recommendation[3] <- 'stale'; q$recommended_by[3] <- 'policy:strong_candidate'
prim <- EmptyPrimaryReferences()
prim[1:2, 'native_key'] <- c('a', 'd'); prim$source_label <- c('Src', 'Other'); prim$role <- c('measurement', 'self')
rec <- RecommendDecisions(q, prim)
Expect(identical(rec$recommendation, c('1', 'nodoi', 'stale', 'self', 'drop', 'nodoi')) &&
         identical(rec$recommended_by, c('policy:strong_candidate', 'policy:fields_complete_no_match', 'policy:strong_candidate', 'policy:self_role', 'agent', 'owner')) &&
         rec$recommendation_reason[5] == 'read the PDF' && identical(names(rec), pending_queue_columns),
       'open rows get the policy recommendation (role from primary_references by source + key); agent and owner rows kept; the decided row untouched')
Expect(attr(rec, 'n_open') == 5 && attr(rec, 'n_recommended') == 3, 'n_open counts every open row, n_recommended the recomputed ones')
cnt <- attr(rec, 'counts')
Expect(identical(dim(cnt), c(length(recommend_rules) + 2L, 2L)) && cnt['strong_candidate', 'Src'] == 1 && cnt['fields_complete_no_match', 'Src'] == 1 && cnt['self_role', 'Other'] == 1 &&
         cnt['agent', 'Src'] == 1 && cnt['owner', 'Src'] == 1 && sum(cnt) == 5,
       'counts: rule x source over the open rows, the kept agent / owner rows under their own names')
forced <- RecommendDecisions(q, prim, overwrite = TRUE)
Expect(forced$recommendation[5] == '1' && forced$recommended_by[5] == 'policy:strong_candidate' && forced$recommended_by[6] == 'policy:strong_candidate' && attr(forced, 'n_recommended') == 5,
       'overwrite = TRUE recomputes the agent and owner rows')
one <- RecommendDecisions(q, prim, sources = 'Other')
Expect(is.na(one$recommendation[1]) && one$recommendation[4] == 'self' && attr(one, 'n_open') == 1 && identical(colnames(attr(one, 'counts')), 'Other'),
       'sources = <Src> restricts the run to that label')
Expect(identical(RecommendDecisions(rec, prim)[, pending_queue_columns], rec[, pending_queue_columns]), 'a second run changes nothing (deterministic)')
tab <- RecommendationCountsTable(cnt)
Expect(identical(names(tab), c('rule', 'Other', 'Src', 'total')) && nrow(tab) == 5 && tab$total[tab$rule == 'strong_candidate'] == 1 && length(MarkdownTable(tab)) == 7,
       'the counts table lists the rules that occur with a total column')

cat('the tracked queue\n')
tq <- ReadPendingQueue(file.path(repo, 'Bib', 'pending_citations.csv'))
tp <- LoadPrimaryReferences(file.path(repo, 'sources', 'databases'))
tr <- RecommendDecisions(tq, tp)
open <- is.na(tr$decision) | !nzchar(trimws(tr$decision))
Expect(all(ValidateDecision(na.omit(tr$recommendation[open]))), 'every recommendation on the tracked queue passes ValidateDecision()')
Expect(all(sub('^policy:', '', tr$recommended_by[open]) %in% c(recommend_rules, 'agent', 'owner')), 'every recommended_by is a rule, agent or owner')
Expect(identical(RecommendDecisions(tr, tp)[, pending_queue_columns], tr[, pending_queue_columns]), 'the tracked queue recommends the same twice')
Expect(all(is.na(tr$recommendation[!open]) == is.na(tq$recommendation[!open])), 'decided rows of the tracked queue are not touched')

cat(sprintf('\n%d checks, %d failed\n', n_checks, length(failures)))
if (length(failures) > 0) { cat(paste0('  FAIL: ', failures, '\n'), sep = ''); quit(status = 1) }
