# Tests for the owner decision workflow of the citation tooling (issue #1):
# R/library/citations/decisions_sheet.r. The tab rows are built from
# synthetic queue rows; the push and the pull run against a fake `io` list
# that records every call (no googlesheets4 token, no network): dry run by
# default, creation of the missing tab, idempotence on the three-column key,
# the snapshots, the dropdown call, and the per-row resolution of what the
# owner typed (accept, a candidate, a doi:, defer, errors) with the status
# column written in the read's order; then the decision items of
# Bib/decision_items.csv through the same fake. The doi: check runs offline
# (cfg$offline) and is reported as unchecked.
#
#   Rscript R/library/tests/test_citations_decisions_sheet.R      (from any directory)
#
# Prints one line per expectation and exits with status 1 if any failed.

this_file <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE))
if (length(this_file) == 0)
  this_file <- file.path('R', 'library', 'tests', 'test_citations_decisions_sheet.R')
repo <- normalizePath(file.path(dirname(this_file), '..', '..', '..'))
lib  <- file.path(repo, 'R', 'library')
source(file.path(lib, 'helpers.r'))
source(file.path(lib, 'dedupe_sources.r'))        # MarkdownTable()
source(file.path(lib, 'sheet_snapshots.r'))       # SheetAuth(), ReadSheetTab(), SnapshotSheetTab() (#118)
for (f in c('citations_config.r', 'normalise_citation.r', 'parse_reflists.r', 'verify_services.r', 'decide.r', 'recommend.r',
            'build_bib.r', 'sheet_append.r', 'decisions_sheet.r', 'provenance.r'))
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

# ---- synthetic queue rows -----------------------------------------------------------------------
QRow <- function(key = 'k', reason = 'weak_match', author1 = 'Doe', year = '2001', title = 'A study of things', container = 'J Things',
                 volume = '5', pages = '1-10', c1 = '10.1000/thing', c1_title = 'A study of things', c1_sim = '0.95', c1_year = '2001', c1_services = 'crossref',
                 c2 = NA, c2_sim = NA, c2_year = NA, c2_services = NA, scite_note = NA, decision = NA, src = 'Src', queued = '2026-10-06',
                 recommendation = NA, recommended_by = NA) {
  row <- as.data.frame(as.list(setNames(rep(NA_character_, length(pending_queue_columns)), pending_queue_columns)), stringsAsFactors = FALSE)
  row$queued_at <- queued; row$source_label <- src; row$native_key <- key; row$n_records <- '3'; row$reason <- reason
  row$raw_citation <- 'Doe, J. 2001. A study of things. J Things 5: 1-10.'
  row$parsed_author1 <- author1; row$parsed_year <- year; row$parsed_title <- title; row$parsed_container <- container
  row$parsed_volume <- volume; row$parsed_pages <- pages
  row$c1_doi <- c1; row$c1_title <- if (is.na(c1)) NA else c1_title; row$c1_title_sim <- c1_sim; row$c1_year <- c1_year; row$c1_container <- if (is.na(c1)) NA else 'Journal of Things'; row$c1_services <- c1_services
  row$c2_doi <- c2; row$c2_title <- if (is.na(c2)) NA else 'A study of things'; row$c2_title_sim <- c2_sim; row$c2_year <- c2_year; row$c2_services <- c2_services
  row$scite_note <- scite_note; row$decision <- decision
  if (!is.na(decision)) { row$decided_by <- 'owner'; row$decided_at <- '2026-10-05' }
  row$recommendation <- recommendation; row$recommended_by <- recommended_by
  row
}

cat('FormatParsedCell(), CandidateCell(), BuildDecisionRows()\n')
Expect(FormatParsedCell(QRow()) == 'Doe (2001) A study of things. J Things 5: 1-10' &&
         FormatParsedCell(QRow(author1 = NA, title = NA)) == '(2001) J Things 5: 1-10' &&
         FormatParsedCell(QRow(year = NA, volume = NA, pages = NA)) == 'Doe (n.d.) A study of things. J Things' &&
         FormatParsedCell(QRow(container = NA, volume = NA)) == 'Doe (2001) A study of things. 1-10',
       'the parsed cell: Author (Year) Title. Container vol: pages, the parts that exist')
cc <- CandidateCell('10.1000/thing', 'A "quoted" <i>title</i>\nwith a break', '2001', 'J Things', '0.95')
Expect(cc == '=HYPERLINK("https://doi.org/10.1000/thing", "A ""quoted"" title with a break (2001) J Things [0.95]")',
       'a candidate cell is a HYPERLINK to doi.org: tags stripped, quotes doubled, the line break a space')
long <- CandidateCell('10.1000/x', paste(rep('word', 40), collapse = ' '), NA, NA, NA)
Expect(nchar(sub('^=HYPERLINK\\("[^"]*", "', '', sub('"\\)$', '', long))) == 90 && endsWith(long, '...")') &&
         is.na(CandidateCell(NA, 'T', '2001', 'J', '1')) && CandidateCell('10.1000/a', NA, NA, NA, NA) == '=HYPERLINK("https://doi.org/10.1000/a", "")',
       'the title is cut to 90 characters; no DOI gives no cell; a DOI without metadata still links')
Expect(grepl('doi.org/10.1890/0012-9658(1997)078[2588:SDIFMW]2.0.CO;2"', CandidateCell('10.1890/0012-9658(1997)078[2588:SDIFMW]2.0.CO;2', 'T', NA, NA, NA), fixed = TRUE) &&
         grepl('doi.org/10.1000/a%3Cb%3E"', CandidateCell('10.1000/a<b>', 'T', NA, NA, NA), fixed = TRUE),
       'the DOI keeps its reserved characters in the URL and has the others encoded')
q <- rbind(QRow('a', recommendation = '1', recommended_by = 'policy:strong_candidate'), QRow('b', decision = 'nodoi'),
           QRow('c', c2 = '10.2307/1', c2_sim = '0.95', c2_year = '2001', c2_services = 'crossref', title = NA, author1 = NA, scite_note = 'crossref:updated-by:correction'))
rows <- BuildDecisionRows(q, pushed_at = '2026-10-07')
Expect(identical(names(rows), sheet_decisions_columns) && nrow(rows) == 2 && identical(rows$native_key, c('a', 'c')) && all(rows$pushed_at == '2026-10-07') &&
         all(is.na(rows$decision)) && all(is.na(rows$owner_note)) && all(is.na(rows$status)) && rows$recommendation[1] == '1' && is.na(rows$recommendation[2]) &&
         identical(rows$fields_complete, c('yes', 'no')) && rows$notice[2] == 'crossref:updated-by:correction' && is.na(rows$c2[1]) && startsWith(rows$c2[2], '=HYPERLINK("https://doi.org/10.2307/1"') &&
         rows$parsed[2] == '(2001) J Things 5: 1-10' && rows$raw_citation[1] == q$raw_citation[1] && rows$n_records[1] == '3',
       'the open rows become tab rows in the schema order: decision, note and status empty, candidates as formulas, fields_complete yes / no')
fc <- FormulaColumns(rows)
Expect(inherits(fc$c1, 'googlesheets4_formula') && inherits(fc$c3, 'googlesheets4_formula') && is.character(fc$raw_citation) && identical(as.character(vctrs::vec_data(fc$c1)), rows$c1),
       'only c1..c3 are wrapped as formulas for the append, with NA kept for the empty cells')
Expect(ColumnLetter(1) == 'A' && ColumnLetter(18) == 'R' && ColumnLetter(27) == 'AA' && match('decision', sheet_decisions_columns) == 14 && match('status', sheet_decisions_columns) == 18,
       'column letters; decision is column N (14), status column R (18)')

# ---- the fake Sheet ------------------------------------------------------------------------------
FakeSheet <- function(tabs = list(), fail_validation = FALSE) {
  env <- new.env()
  env$tabs <- tabs; env$log <- character(); env$columns <- list()
  io <- list(
    read   = function(url, tab) { env$log <- c(env$log, paste('read', tab)); env$tabs[[tab]] },
    exists = function(url, tab) { env$log <- c(env$log, paste('exists', tab)); tab %in% names(env$tabs) },
    create = function(url, tab, columns) {
      env$log <- c(env$log, paste('create', tab))
      env$tabs[[tab]] <- as.data.frame(setNames(rep(list(character()), length(columns)), columns), stringsAsFactors = FALSE)
      invisible(TRUE) },
    append = function(url, tab, rows) {
      env$log <- c(env$log, paste('append', tab, nrow(rows)))
      rows[] <- lapply(rows, function(x) if (inherits(x, 'googlesheets4_formula')) as.character(vctrs::vec_data(x)) else x)
      env$tabs[[tab]] <- rbind(env$tabs[[tab]], rows); invisible(TRUE) },
    write_column = function(url, tab, col_index, values) {
      env$log <- c(env$log, paste('write_column', tab, col_index, length(values)))
      env$tabs[[tab]][[col_index]] <- as.character(values); env$columns[[tab]] <- values; invisible(length(values)) },
    set_validation = function(url, tab, col_index) {
      env$log <- c(env$log, paste('set_validation', tab, col_index))
      if (fail_validation) stop('batchUpdate rejected (test)')
      invisible(TRUE) })
  list(io = io, env = env)
}

cat('PushDecisionRows() on a fake Sheet\n')
snap <- tempfile(fileext = '.csv')
fs <- FakeSheet()
res <- suppressMessages(PushDecisionRows(q, 'url', sheet_tab_decisions, dry_run = TRUE, snapshot_path = snap, io = fs$io, pushed_at = '2026-10-07'))
Expect(res$dry_run && nrow(res$new) == 2 && res$n_before == 0 && identical(fs$env$log, 'exists BM_decisions') && !file.exists(snap) && is.na(res$validation_error),
       'dry run on a missing tab: nothing created, appended, snapshotted or validated; the diff lists the two open rows')
fs <- FakeSheet()
res <- suppressMessages(PushDecisionRows(q, 'url', sheet_tab_decisions, dry_run = FALSE, snapshot_path = snap, io = fs$io, pushed_at = '2026-10-07'))
Expect(!res$dry_run && nrow(res$new) == 2 && res$n_before == 0 && res$n_after == 2 &&
         identical(fs$env$log, c('exists BM_decisions', 'create BM_decisions', 'read BM_decisions', 'append BM_decisions 2', 'read BM_decisions', 'set_validation BM_decisions 14')) &&
         identical(names(fs$env$tabs$BM_decisions), sheet_decisions_columns) && is.na(res$validation_error) && length(res$duplicates) == 0,
       'real run on a missing tab: created with headers, read, appended, re-read, the dropdown set on column 14')
after <- read.csv(snap, stringsAsFactors = FALSE, colClasses = 'character')
Expect(nrow(after) == 2 && identical(names(after), sheet_decisions_columns) && identical(after$native_key, c('a', 'c')) && startsWith(after$c1[1], '=HYPERLINK'),
       'the snapshot is the after state of the tab')
res2 <- suppressMessages(PushDecisionRows(q, 'url', sheet_tab_decisions, dry_run = FALSE, snapshot_path = snap, io = fs$io, pushed_at = '2026-10-08'))
Expect(nrow(res2$new) == 0 && res2$n_before == 2 && res2$n_after == 2 && !any(grepl('^append', fs$env$log[-(1:6)])) && grepl('^set_validation', tail(fs$env$log, 1)),
       'a second push appends nothing (idempotent on source_label + native_key + queued_at) and still (re)sets the dropdown')
q_re <- rbind(q, QRow('a', queued = '2026-10-09'))          # the key re-queued after a pull: a new row
res3 <- suppressMessages(PushDecisionRows(q_re, 'url', sheet_tab_decisions, dry_run = FALSE, snapshot_path = snap, io = fs$io, pushed_at = '2026-10-09'))
Expect(nrow(res3$new) == 1 && res3$new$queued_at == '2026-10-09' && res3$n_after == 3 && nrow(read.csv(snap, stringsAsFactors = FALSE)) == 3,
       'a key re-queued under a new queued_at is appended as a new row')
fv <- FakeSheet(fail_validation = TRUE)
resv <- suppressMessages(PushDecisionRows(q, 'url', sheet_tab_decisions, dry_run = FALSE, io = fv$io))
Expect(nrow(resv$new) == 2 && nrow(fv$env$tabs$BM_decisions) == 2 && Has(resv$validation_error, 'batchUpdate rejected'),
       'a rejected validation request does not undo the push; the error is returned')
dupt <- FakeSheet(list(BM_decisions = rbind(rows, rows[1, ])))
resd <- suppressMessages(PushDecisionRows(q, 'url', sheet_tab_decisions, dry_run = TRUE, io = dupt$io))
Expect(identical(resd$duplicates, 'Src a 2026-10-06') && nrow(resd$new) == 0, 'a key twice on the tab is reported')
Expect(Has(ErrorOf(suppressMessages(PushDecisionRows(q, 'url', sheet_tab_decisions, io = FakeSheet(list(BM_decisions = data.frame(x = 1)))$io))), 'has no source_label, native_key, queued_at column'),
       'a tab without the key columns stops')
Expect(identical(names(DecisionsSheetIO()), c('read', 'exists', 'create', 'append', 'write_column', 'set_validation')), 'the default io has the six operations the fake implements')

cat('ResolveTabDecision()\n')
qa <- QRow('a', recommendation = '1')
TR <- function(decision = NA, recommendation = '1', note = NA) list(decision = decision, recommendation = recommendation, owner_note = note)
r <- ResolveTabDecision(TR('accept'), qa, cfg, pulled_at = '2026-10-10')
Expect(r$decision == '1' && r$status == 'pulled 2026-10-10' && is.na(r$message), 'accept takes the recommendation shown on the tab')
Expect(ResolveTabDecision(TR('accept', recommendation = NA), qa, cfg)$decision == '1', 'an empty recommendation cell falls back to the queue row\'s')
r <- ResolveTabDecision(TR('accept', recommendation = NA), QRow('a'), cfg)
Expect(is.na(r$decision) && r$status == 'error: accept with no recommendation: type the decision', 'accept with no recommendation anywhere is an error')
Expect(ResolveTabDecision(TR(NA), qa, cfg)$status == 'deferred' && ResolveTabDecision(TR('  '), qa, cfg)$status == 'deferred' && ResolveTabDecision(TR('Defer'), qa, cfg)$status == 'deferred' &&
         is.na(ResolveTabDecision(TR('defer'), qa, cfg)$decision),
       'an empty cell or defer leaves the row open')
Expect(ResolveTabDecision(TR(' nodoi '), qa, cfg)$decision == 'nodoi' && ResolveTabDecision(TR('1:year=1999'), qa, cfg)$decision == '1:year=1999',
       'a typed decision is trimmed and kept with its year override')
Expect(Has(ResolveTabDecision(TR('2'), qa, cfg)$status, 'error: candidate 2 has no DOI in the queue') && Has(ResolveTabDecision(TR('maybe'), qa, cfg)$status, 'error: \'maybe\' is not a decision') &&
         Has(ResolveTabDecision(TR('nodoi:year=1999'), qa, cfg)$status, 'error: a year override needs a candidate or doi: decision') &&
         Has(ResolveTabDecision(TR('1'), QRow('a', c1_services = 'openalex'), cfg)$status, 'error: candidate 1 (10.1000/thing) was returned by openalex only'),
       'a candidate the row lacks, a word outside the grammar, a year override on nodoi and an OpenAlex-only candidate are per-row errors')
r <- ResolveTabDecision(TR('doi:10.1007/bf00392514'), qa, cfg)
Expect(r$decision == 'doi:10.1007/bf00392514' && startsWith(r$status, 'pulled') && Has(r$message, 'not checked at Crossref (offline)'),
       'offline, a doi: decision is pulled unchecked and the message says so')
cfg_on <- cfg; cfg_on$offline <- FALSE      # the fixture cache answers both DOIs without the network
Expect(startsWith(ResolveTabDecision(TR('doi:10.1007/bf00392514'), qa, cfg_on)$status, 'pulled') &&
         ResolveTabDecision(TR('doi:10.9999/this-doi-does-not-exist'), qa, cfg_on)$status == 'error: doi:10.9999/this-doi-does-not-exist does not resolve at Crossref',
       'online, a doi: decision is resolved at Crossref (from the recorded fixtures) and an unresolved one is an error')

cat('ResolveTabDecision(): the cite: form of owner_note (2026-10-08)\n')
full <- 'cite: Smith, J. & Jones, A. (1987) Body size of shrews. Journal of Mammalogy 68: 123-130.'
want <- list(parsed_author1 = 'Smith', parsed_year = '1987', parsed_title = 'Body size of shrews', parsed_container = 'Journal of Mammalogy', parsed_volume = '68', parsed_pages = '123-130')
Expect(CiteNote(full) == 'Smith, J. & Jones, A. (1987) Body size of shrews. Journal of Mammalogy 68: 123-130.' && CiteNote('CITE:Smith (1987) T. J 1: 2') == 'Smith (1987) T. J 1: 2' &&
         CiteNote('  Cite:   x  ') == 'x' && is.na(CiteNote('checked the PDF')) && is.na(CiteNote('cite:')) && is.na(CiteNote('cite: ')) && is.na(CiteNote(NA)) && is.na(CiteNote(NULL)) &&
         is.na(CiteNote('citation: Smith (1987)')) && is.na(CiteNote('see cite: Smith')),
       'CiteNote(): the prefix in any case, with or without a space, the text trimmed; any other note, an empty citation and NA give NA')
pc <- ParseCiteNote(full)
Expect(identical(pc$parsed, want) && length(pc$missing) == 0 && is.null(ParseCiteNote('checked the PDF')) && is.null(ParseCiteNote(NA)) &&
         identical(ParseCiteNote('cite: Smith, J. & Jones, A. (1987) Body size of shrews.')$missing, 'container') &&
         identical(ParseCiteNote('cite: Body size of shrews')$missing, c('year', 'container')),
       'ParseCiteNote(): the six parsed_* fields as character and the required fields that are missing; NULL for any other note')
qa_nodoi <- QRow('a', recommendation = 'nodoi')
r <- ResolveTabDecision(TR(NA, note = full), qa_nodoi, cfg, pulled_at = '2026-10-10')
Expect(r$decision == 'nodoi' && r$status == 'pulled 2026-10-10 (cite: Smith (1987) Body size of shrews. Journal of Mammalogy 68: 123-130)' && identical(r$parsed, want) && is.na(r$message),
       'cite: with an empty decision cell: the decision is nodoi, the parsed fields returned, the status shows the parse')
Expect(ResolveTabDecision(TR('accept', recommendation = 'nodoi', note = full), qa_nodoi, cfg)$decision == 'nodoi' && identical(ResolveTabDecision(TR('accept', recommendation = 'nodoi', note = full), qa_nodoi, cfg)$parsed, want) &&
         ResolveTabDecision(TR('nodoi', note = full), qa, cfg)$decision == 'nodoi' && ResolveTabDecision(TR(' nodoi ', note = full), qa, cfg)$decision == 'nodoi',
       'cite: with accept (recommendation nodoi) or a typed nodoi keeps that decision and carries the fields')
r <- ResolveTabDecision(TR('doi:10.1007/bf00392514', note = full), qa, cfg, pulled_at = '2026-10-10')
Expect(r$decision == 'doi:10.1007/bf00392514' && identical(r$parsed, want) && startsWith(r$status, 'pulled 2026-10-10 (cite: Smith (1987)') && Has(r$message, 'offline') &&
         ResolveTabDecision(TR('1', note = full), qa, cfg)$decision == '1' && identical(ResolveTabDecision(TR('1', note = full), qa, cfg)$parsed, want) &&
         ResolveTabDecision(TR('drop', note = full), qa, cfg)$decision == 'drop',
       'cite: with a doi:, a candidate or any other valid decision: the decision stands and the parsed fields still update')
r <- ResolveTabDecision(TR(NA, note = 'cite: Smith, J. & Jones, A. (1987) Body size of shrews.'), qa, cfg)
Expect(is.na(r$decision) && r$status == 'error: cite: could not be parsed (missing: container); edit the note or add the fields in parentheses' && is.null(r$parsed) &&
         Has(ResolveTabDecision(TR('nodoi', note = 'cite: Body size of shrews'), qa, cfg)$status, 'error: cite: could not be parsed (missing: year, container)'),
       'cite: missing a required field is a per-row error whatever the cell says: no decision, no fields, the missing fields named')
Expect(ResolveTabDecision(TR(NA, note = 'CITE:Smith, J. (1987) Body size of shrews. Journal of Mammalogy 68: 123-130.'), qa, cfg)$decision == 'nodoi' &&
         ResolveTabDecision(TR(NA, note = 'Cite:   Smith, J. (1987) Body size of shrews. Journal of Mammalogy 68: 123-130.'), qa, cfg)$decision == 'nodoi',
       'the cite prefix is case-insensitive and works with or without a space after the colon')
Expect(ResolveTabDecision(TR('defer', note = full), qa, cfg)$status == 'deferred' && is.null(ResolveTabDecision(TR('defer', note = full), qa, cfg)$parsed),
       'cite: with defer still defers (nothing written)')
r <- ResolveTabDecision(TR('nodoi', note = 'checked the PDF'), qa, cfg, pulled_at = '2026-10-10')
Expect(r$decision == 'nodoi' && r$status == 'pulled 2026-10-10' && is.null(r$parsed) && ResolveTabDecision(TR(NA, note = 'checked the PDF'), qa, cfg)$status == 'deferred' &&
         ResolveTabDecision(TR('maybe', note = 'checked the PDF'), qa, cfg)$status == 'error: \'maybe\' is not a decision (1|2|3, doi:10..., manual:<Key>, nodoi, self, drop; optional :year=YYYY)',
       'a non-cite note changes nothing: plain status, no fields, an empty cell still defers, a bad cell is still the same error')

cat('ResolveTabDecision(): cite: notes in APA style, a journal item without a title, a thesis (2026-10-08)\n')
nt <- 'cite: Allgaier, A. (1993). Bat Research News, 34(4), 100. https://www.eaglehill.us/programs/journals/nabr/BRN-archives/BRN-archives.shtml'
pnt <- ParseCiteNote(nt)
Expect(length(pnt$missing) == 0 && isTRUE(pnt$no_title) && is.na(pnt$parsed$parsed_title) && pnt$parsed$parsed_container == 'Bat Research News' && pnt$parsed$parsed_volume == '34' && pnt$parsed$parsed_pages == '100' &&
         identical(ParseCiteNote('cite: Allgaier, A. (1993). Bat Research News.')$missing, 'container') && !isTRUE(ParseCiteNote(full)$no_title),
       'ParseCiteNote(): a journal item cited without a title needs no title when container, volume and pages are there (no_title); without them the text reads as a title and the container is missing')
r <- ResolveTabDecision(TR(NA, note = nt), qa_nodoi, cfg, pulled_at = '2026-10-10')
Expect(r$decision == 'nodoi' && r$status == 'pulled 2026-10-10 (cite: Allgaier (1993) Bat Research News 34: 100; no title)' && is.na(r$parsed$parsed_title) && r$parsed$parsed_container == 'Bat Research News',
       'a title-less journal item pulls as nodoi with the status saying so')
r <- ResolveTabDecision(TR(NA, note = 'cite: Bennett, P. M. (1986). Environmental correlates of evolutionary change in mammals (Doctoral dissertation, University of Sussex). https://bl.uk'), qa_nodoi, cfg, pulled_at = '2026-10-10')
Expect(r$decision == 'nodoi' && r$parsed$parsed_container == 'PhD thesis, University of Sussex' && r$parsed$parsed_title == 'Environmental correlates of evolutionary change in mammals' &&
         NoDOIEntryType(r$parsed)$type == 'phdthesis' && ThesisSchool(r$parsed$parsed_container) == 'University of Sussex' &&
         r$status == 'pulled 2026-10-10 (cite: Bennett (1986) Environmental correlates of evolutionary change in mammals. PhD thesis, University of Sussex)',
       'a thesis note gives the thesis container, which the bib layer reads as @phdthesis with the school')
r <- ResolveTabDecision(TR(NA, note = 'cite: Álvarez del Toro, M. & Smith, H. M. (1956). Notulae herpetologicae Chiapasiae I. Herpetologica, 12(1): 3–17.'), qa_nodoi, cfg, pulled_at = '2026-10-10')
Expect(r$decision == 'nodoi' && r$parsed$parsed_author1 == 'Alvarez del Toro' && r$parsed$parsed_container == 'Herpetologica' && r$parsed$parsed_volume == '12' && r$parsed$parsed_pages == '3-17' &&
         r$status == 'pulled 2026-10-10 (cite: Alvarez del Toro (1956) Notulae herpetologicae Chiapasiae I. Herpetologica 12: 3-17)',
       'an APA note that failed the 2026-10-08 pull (missing: container) now pulls')

cat('ReciteQueue()\n')
old_apa <- QRow('x', container = 'Biotemas, 12(1): 95-117. Universidade Federal de Santa Catarina, Florianopolis', volume = NA, pages = NA, decision = 'nodoi')
old_apa$owner_note <- 'cite: Cherem, J. J., Olimpio, J. & Ximénez, A. (1999). Descrição de uma nova espécie do gênero Cavia Pallas, 1766 (Mammalia - Caviidae) das Ilhas dos Moleques do Sul, Santa Catarina, Sul do Brasil. Biotemas, 12(1): 95–117. Universidade Federal de Santa Catarina, Florianópolis.'
old_apa$parsed_author1 <- 'Cherem'; old_apa$parsed_year <- '1999'; old_apa$parsed_title <- 'Descricao de uma nova especie do genero Cavia Pallas, 1766 (Mammalia - Caviidae) das Ilhas dos Moleques do Sul, Santa Catarina, Sul do Brasil'
same <- QRow('y', author1 = 'Smith', year = '1987', title = 'Body size of shrews', container = 'Journal of Mammalogy', volume = '68', pages = '123-130'); same$owner_note <- full
bad <- QRow('z', container = NA); bad$owner_note <- 'cite: Smith, J. (1987) Body size of shrews.'
plain <- QRow('w'); plain$owner_note <- 'checked the PDF'
open_apa <- QRow('v', container = NA, volume = NA, pages = NA); open_apa$owner_note <- 'cite: Allgaier, A. (1993). Bat Research News, 34(4), 100. https://eaglehill.us'
rq <- ReciteQueue(rbind(old_apa, same, bad, plain, open_apa))
RQ <- function(k, col) rq$queue[[col]][rq$queue$native_key == k]
Expect(rq$rows == 4 && nrow(rq$unparsed) == 1 && rq$unparsed$native_key == 'z' && rq$unparsed$missing == 'container' && identical(names(rq$per_column), cite_note_fields),
       'four cite: rows seen (decided or open); the one still missing its container is left alone and listed; a plain note is not a cite: row')
Expect(RQ('x', 'parsed_container') == 'Biotemas' && RQ('x', 'parsed_volume') == '12' && RQ('x', 'parsed_pages') == '95-117' && RQ('x', 'parsed_title') == old_apa$parsed_title && RQ('x', 'decision') == 'nodoi' &&
         identical(sort(rq$changes$column[rq$changes$native_key == 'x']), c('parsed_container', 'parsed_pages', 'parsed_volume')) &&
         rq$changes$old[rq$changes$native_key == 'x' & rq$changes$column == 'parsed_container'] == old_apa$parsed_container && is.na(rq$changes$old[rq$changes$native_key == 'x' & rq$changes$column == 'parsed_volume']),
       'a decided row whose container swallowed the volume, pages and publisher is re-parsed: three cells changed, the decision untouched, the change table keeps old and new')
Expect(!any(rq$changes$native_key == 'y') && identical(unlist(rq$queue[rq$queue$native_key == 'y', cite_note_fields], use.names = FALSE), unlist(same[, cite_note_fields], use.names = FALSE)),
       'a row the parser reads as before is unchanged')
Expect(identical(unlist(rq$queue[rq$queue$native_key == 'z', cite_note_fields], use.names = FALSE), unlist(bad[, cite_note_fields], use.names = FALSE)) &&
         identical(unlist(rq$queue[rq$queue$native_key == 'w', cite_note_fields], use.names = FALSE), unlist(plain[, cite_note_fields], use.names = FALSE)),
       'the unparsable and the plain-note rows keep their fields')
Expect(RQ('v', 'parsed_container') == 'Bat Research News' && RQ('v', 'parsed_volume') == '34' && RQ('v', 'parsed_pages') == '100' && is.na(RQ('v', 'parsed_title')) && is.na(RQ('v', 'decision')) &&
         rq$per_column[['parsed_container']] == 2 && rq$per_column[['parsed_title']] == 1 && sum(rq$per_column) == nrow(rq$changes) && identical(names(rq$queue), pending_queue_columns),
       'an open title-less row takes container, volume and pages and loses the stale title; the per-column counts add up; the queue keeps its schema')

cat('PullDecisions()\n')
queue <- rbind(QRow('a', recommendation = '1'), QRow('b', recommendation = 'nodoi'), QRow('c', c1_services = 'openalex', recommendation = 'nodoi'),
               QRow('d'), QRow('e', recommendation = 'drop'), QRow('f', recommendation = '1', src = 'Other'), QRow('g'))
tab <- BuildDecisionRows(queue, '2026-10-07')
queue$decision[queue$native_key == 'd'] <- 'drop'; queue$decided_by[queue$native_key == 'd'] <- 'owner'; queue$decided_at[queue$native_key == 'd'] <- '2026-10-05'   # decided in the CSV after the push
tab <- tab[nrow(tab):1, ]                                  # the owner sorted the tab
tab$decision <- c('defer', 'accept', 'drop', '1', '2', 'doi:10.1007/bf00392514', 'nodoi')[match(tab$native_key, c('g', 'f', 'e', 'c', 'b', 'a', 'd'))]
tab$owner_note[tab$native_key == 'a'] <- 'checked the PDF'
tab <- rbind(tab, data.frame(source_label = 'Src', native_key = 'zz', queued_at = '2026-10-06', n_records = '1', reason = 'weak_match', parsed = '', c1 = NA, c2 = NA, c3 = NA, notice = NA,
                             fields_complete = 'yes', recommendation = NA, recommendation_reason = NA, decision = 'nodoi', owner_note = NA, raw_citation = 'x', pushed_at = '2026-10-07', status = NA,
                             stringsAsFactors = FALSE))
tab <- rbind(tab, tab[tab$native_key == 'e', ])          # a key twice on the tab
res <- PullDecisions(queue, tab, pulled_at = '2026-10-10', cfg = cfg)
r <- res$results; qq <- res$queue
S <- function(k) r$status[r$native_key == k]
Expect(nrow(r) == nrow(tab) && identical(r$native_key, tab$native_key) && identical(names(r), c('source_label', 'native_key', 'queued_at', 'cell', 'decision', 'status', 'message')),
       'one result per tab row in the tab\'s (sorted) order')
Expect(S('g') == 'deferred' && is.na(qq$decision[qq$native_key == 'g']), 'defer: the row stays open')
Expect(S('f') == 'pulled 2026-10-10' && qq$decision[qq$native_key == 'f'] == '1' && qq$decided_by[qq$native_key == 'f'] == 'owner' && qq$decided_at[qq$native_key == 'f'] == '2026-10-10',
       'accept on a sorted row is matched by key: the recommendation becomes the decision, decided_by owner, decided_at the pull date')
Expect(all(S('e') == 'error: duplicate tab rows for this key') && is.na(qq$decision[qq$native_key == 'e']), 'a key twice on the tab: both rows an error, the queue row untouched')
Expect(Has(S('c'), 'error: candidate 1 (10.1000/thing) was returned by openalex only') && is.na(qq$decision[qq$native_key == 'c']), 'an OpenAlex-only candidate is a per-row error')
Expect(Has(S('b'), 'error: candidate 2 has no DOI'), 'a candidate the row lacks is a per-row error')
Expect(S('a') == 'pulled 2026-10-10' && qq$decision[qq$native_key == 'a'] == 'doi:10.1007/bf00392514' && qq$owner_note[qq$native_key == 'a'] == 'checked the PDF' &&
         Has(r$message[r$native_key == 'a'], 'offline'),
       'a doi: decision is pulled with the owner_note')
Expect(S('d') == 'ignored: already pulled 2026-10-05 as drop (change it in the CSV)' && qq$decision[qq$native_key == 'd'] == 'drop' && qq$decided_at[qq$native_key == 'd'] == '2026-10-05',
       'a row already decided in the queue is left alone and the tab is told')
Expect(S('zz') == 'error: no queue row for this key', 'a tab row without a queue row is an error')
Expect(identical(names(qq), pending_queue_columns) && sum(!is.na(qq$decision)) == 3, 'the queue keeps its schema; three rows are decided (the pulled two and the old one)')
Expect(is.data.frame(ApplyQueueDecisions(qq[qq$source_label == 'Src', ], EmptyPrimaryReferences(), cfg)), 'the pulled queue passes the apply-time checks')
tab2 <- tab[!duplicated(tab$native_key) & tab$native_key != 'zz', ]
tab2$decision[tab2$native_key == 'f'] <- 'nodoi'          # a change of mind after the pull
tab2$decision[tab2$native_key == 'a'] <- 'doi:10.1007/bf00392514'
tab2$decision[tab2$native_key == 'g'] <- 'accept'; tab2$recommendation[tab2$native_key == 'g'] <- 'nodoi'
res2 <- PullDecisions(qq, tab2, pulled_at = '2026-10-11', cfg = cfg)
r2 <- res2$results
Expect(r2$status[r2$native_key == 'f'] == 'ignored: already pulled 2026-10-10 as 1 (change it in the CSV)' && res2$queue$decision[res2$queue$native_key == 'f'] == '1' &&
         r2$status[r2$native_key == 'a'] == 'pulled 2026-10-10' && r2$status[r2$native_key == 'g'] == 'pulled 2026-10-11' && res2$queue$decision[res2$queue$native_key == 'g'] == 'nodoi',
       'a second pull: a changed pulled cell is ignored, an unchanged one re-reads as pulled on its date, a newly filled row is pulled')
Expect(Has(ErrorOf(PullDecisions(queue, tab[, setdiff(names(tab), 'decision')], cfg = cfg)), 'lacks column(s) decision'), 'a tab without the key or decision column stops')
sm <- PullSummary(r)
Expect(identical(names(sm), c('source_label', 'pulled', 'deferred', 'errors', 'ignored')) && sm$pulled[sm$source_label == 'Src'] == 1 && sm$errors[sm$source_label == 'Src'] == 5 &&
         sm$deferred[sm$source_label == 'Src'] == 1 && sm$ignored[sm$source_label == 'Src'] == 1 && sm$pulled[sm$source_label == 'Other'] == 1,
       'the per-source summary counts pulled, deferred, errors and ignored')
fsp <- FakeSheet(list(BM_decisions = tab))
fsp$io$write_column('url', sheet_tab_decisions, match('status', names(tab)), r$status)
Expect(identical(fsp$env$tabs$BM_decisions$status, r$status) && tail(fsp$env$log, 1) == sprintf('write_column BM_decisions 18 %d', nrow(tab)), 'the status column is written in the read order')
lg <- tempfile(fileext = '.md')
AppendRoundLog(lg, 'test', c('- one', '- two'), date = '2026-10-10')
Expect(identical(readLines(lg), c('', '## 2026-10-10 -- test', '', '- one', '- two')), 'a round-log entry: a dated heading and the lines')

cat('PullDecisions() with cite: notes\n')
qc <- rbind(QRow('p', container = NA, recommendation = 'drop'), QRow('q', recommendation = 'nodoi'), QRow('r', container = NA, recommendation = 'drop'), QRow('s', recommendation = '1'))
tc <- BuildDecisionRows(qc, '2026-10-07')
tc$decision[tc$native_key == 'q'] <- 'accept'; tc$decision[tc$native_key == 's'] <- 'nodoi'
tc$owner_note <- c(full, full, 'cite: Smith, J. (1987) Body size of shrews.', 'checked the PDF')[match(tc$native_key, c('p', 'q', 'r', 's'))]
resc <- PullDecisions(qc, tc, pulled_at = '2026-10-10', cfg = cfg)
rc <- resc$results; qcc <- resc$queue
P <- function(k) unlist(qcc[qcc$native_key == k, cite_note_fields])
Expect(rc$status[rc$native_key == 'p'] == 'pulled 2026-10-10 (cite: Smith (1987) Body size of shrews. Journal of Mammalogy 68: 123-130)' && qcc$decision[qcc$native_key == 'p'] == 'nodoi' &&
         qcc$owner_note[qcc$native_key == 'p'] == full && identical(unname(P('p')), unname(unlist(want))) && qcc$decided_by[qcc$native_key == 'p'] == 'owner',
       'a cite: row with an empty cell is pulled as nodoi: the parsed fields written into the queue row, the note kept in full, the status showing the parse')
Expect(qcc$decision[qcc$native_key == 'q'] == 'nodoi' && identical(unname(P('q')), unname(unlist(want))) && startsWith(rc$status[rc$native_key == 'q'], 'pulled 2026-10-10 (cite:'),
       'a cite: row with accept (recommendation nodoi) keeps the decision and takes the fields')
Expect(rc$status[rc$native_key == 'r'] == 'error: cite: could not be parsed (missing: container); edit the note or add the fields in parentheses' && is.na(qcc$decision[qcc$native_key == 'r']) &&
         is.na(qcc$parsed_container[qcc$native_key == 'r']) && qcc$parsed_title[qcc$native_key == 'r'] == 'A study of things' && is.na(qcc$owner_note[qcc$native_key == 'r']),
       'a cite: row missing the container is an error: the row stays open, no field and no note written')
Expect(rc$status[rc$native_key == 's'] == 'pulled 2026-10-10' && qcc$decision[qcc$native_key == 's'] == 'nodoi' && qcc$owner_note[qcc$native_key == 's'] == 'checked the PDF' &&
         identical(unname(P('s')), c('Doe', '2001', 'A study of things', 'J Things', '5', '1-10')) && identical(names(qcc), pending_queue_columns),
       'a non-cite note leaves the parsed fields as they were; the queue keeps its schema')
Expect(FieldsComplete(qcc[qcc$native_key == 'p', ]) && !FieldsComplete(qc[qc$native_key == 'p', ]) && is.data.frame(ApplyQueueDecisions(qcc, EmptyPrimaryReferences(), cfg)),
       'the cite: row is complete after the pull where it was not before, and the pulled queue passes the apply-time checks')
resc2 <- PullDecisions(qcc, tc, pulled_at = '2026-10-11', cfg = cfg)
Expect(resc2$results$status[resc2$results$native_key == 'p'] == 'pulled 2026-10-10' && resc2$results$status[resc2$results$native_key == 'q'] == 'pulled 2026-10-10' &&
         identical(resc2$queue, qcc),
       'a second pull: the cite: row with the empty cell reads as pulled on its date (the empty cell agrees with nodoi), the queue unchanged')

cat('ReadDecisionItems(), WriteDecisionItems(), PushDecisionItems(), PullDecisionItems()\n')
items <- data.frame(item_id = c('Src-1', 'Src-2', 'Other-1'), asked_at = '2026-10-06', source_label = c('Src', 'Src', 'Other'),
                    question = c('Q1?', 'Q2?', 'Q3?'), options = 'a | b', recommendation = 'a', answer = c(NA, 'b', NA), answered_at = c(NA, '2026-10-05', NA), stringsAsFactors = FALSE)
itf <- tempfile(fileext = '.csv')
WriteDecisionItems(items, itf)
back <- ReadDecisionItems(itf)
Expect(identical(names(back), decision_item_columns) && nrow(back) == 3 && is.na(back$answer[1]) && back$answer[2] == 'b' && nrow(ReadDecisionItems(tempfile())) == 0,
       'the items file round-trips; a missing file reads as empty')
Expect(Has(ErrorOf(ReadDecisionItems({ f <- tempfile(fileext = '.csv'); write.csv(rbind(items, items[1, ]), f, row.names = FALSE); f })), 'duplicated item_id Src-1'), 'a duplicated item_id stops')
irows <- BuildDecisionItemRows(items)
Expect(identical(names(irows), sheet_decision_items_columns) && nrow(irows) == 3 && all(is.na(irows$status)), 'every item becomes a tab row with an empty status')
fi <- FakeSheet(); isnap <- tempfile(fileext = '.csv')
ri <- suppressMessages(PushDecisionItems(items, 'url', sheet_tab_decision_items, dry_run = FALSE, snapshot_path = isnap, io = fi$io))
ri2 <- suppressMessages(PushDecisionItems(rbind(items, data.frame(item_id = 'Src-3', asked_at = '2026-10-07', source_label = 'Src', question = 'Q4?', options = 'x', recommendation = 'x', answer = NA, answered_at = NA)),
                                          'url', sheet_tab_decision_items, dry_run = FALSE, snapshot_path = isnap, io = fi$io))
Expect(nrow(ri$new) == 3 && ri$n_after == 3 && nrow(ri2$new) == 1 && ri2$new$item_id == 'Src-3' && ri2$n_after == 4 && nrow(read.csv(isnap, stringsAsFactors = FALSE)) == 4 &&
         !any(grepl('set_validation', fi$env$log)),
       'items are appended on item_id (idempotent), snapshotted, with no dropdown')
itab <- fi$env$tabs$BM_decision_items
itab$answer <- c('a', 'b', NA, 'yes')
itab <- rbind(itab, data.frame(item_id = 'Nope-1', asked_at = NA, source_label = NA, question = NA, options = NA, recommendation = NA, answer = 'x', answered_at = NA, status = NA))
pi <- PullDecisionItems(rbind(items, data.frame(item_id = 'Src-3', asked_at = '2026-10-07', source_label = 'Src', question = 'Q4?', options = 'x', recommendation = 'x', answer = NA, answered_at = NA)), itab, pulled_at = '2026-10-10')
Expect(pi$items$answer[1] == 'a' && pi$items$answered_at[1] == '2026-10-10' && pi$items$answer[2] == 'b' && pi$items$answered_at[2] == '2026-10-05' && is.na(pi$items$answer[3]) &&
         pi$items$answer[4] == 'yes' && identical(pi$results$status, c('pulled 2026-10-10', 'pulled 2026-10-05', NA, 'pulled 2026-10-10', 'error: no item with this item_id')) &&
         identical(pi$log, c('Src-1: Q1? -> a', 'Src-3: Q4? -> yes')),
       'a new answer is written with the pull date, an old one kept, an open item left, an unknown id an error; the log lines name the newly answered items')
itab$answer[2] <- 'changed'
Expect(PullDecisionItems(items, itab, pulled_at = '2026-10-11')$results$status[2] == 'ignored: already answered 2026-10-05 (change it in the CSV)', 'a changed answer after the pull is ignored')
tracked <- ReadDecisionItems(file.path(repo, 'Bib', 'decision_items.csv'))
Expect(nrow(tracked) >= 8 && !anyDuplicated(tracked$item_id) && all(grepl('^[A-Za-z0-9_]+-[0-9]+$', tracked$item_id)) && all(nzchar(tracked$question)) && all(nzchar(tracked$options)) &&
         all(tracked$source_label %in% names(reflist_specs)),
       'the tracked items file: unique <Src>-<n> ids, a question and options each, known source labels')

cat(sprintf('\n%d checks, %d failed\n', n_checks, length(failures)))
if (length(failures) > 0) { cat(paste0('  FAIL: ', failures, '\n'), sep = ''); quit(status = 1) }
