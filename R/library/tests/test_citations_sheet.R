# Tests for the Google Sheet layer of the citation tooling (issue #1):
# R/library/citations/sheet_append.r. The Citation cell is formatted from the
# recorded Crossref record of Ikeda & Bruce 1986 (R/library/citations/tests/
# fixtures/cache/) and from synthetic records; AppendPrimaryCitations() runs
# against a fake `io` list that records every call (no googlesheets4, no
# token, no network): dry run by default, creation of the missing tab with
# headers only, idempotence on Bibcite, snapshots before and after, the CiteID
# conflict, and the refusal to write anywhere but BM_primary_citations.
#
#   Rscript R/library/tests/test_citations_sheet.R      (from any directory)
#
# Prints one line per expectation and exits with status 1 if any failed.

this_file <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE))
if (length(this_file) == 0)
  this_file <- file.path('R', 'library', 'tests', 'test_citations_sheet.R')
repo <- normalizePath(file.path(dirname(this_file), '..', '..', '..'))
lib  <- file.path(repo, 'R', 'library')
source(file.path(lib, 'helpers.r'))
for (f in c('citations_config.r', 'normalise_citation.r', 'parse_reflists.r', 'verify_services.r', 'build_bib.r', 'sheet_append.r'))
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

# ---- the Citation cell -------------------------------------------------------------------------
cat('Initials(), CrossrefAuthorList(), FormatCitationText(), FormatCitationTextNoDOI()\n')
Expect(Initials('Thomas K.') == 'T. K.' && Initials('Jean-Pierre') == 'J.-P.' && Initials('T.') == 'T.' && Initials('') == '' && Initials(NULL) == '',
       'initials from given names, hyphenated names kept together')
A <- function(...) list(author = lapply(list(...), function(n) if (length(n) == 1) list(name = n) else list(family = n[1], given = n[2])))
Expect(CrossrefAuthorList(A(c('Doyle', 'Thomas K.'))) == 'Doyle, T. K.' && CrossrefAuthorList(A(c('Ikeda', 'T.'), c('Bruce', 'B.'))) == 'Ikeda, T. & Bruce, B.' &&
         CrossrefAuthorList(A(c('A', 'X'), c('B', 'Y'), c('C', 'Z'))) == 'A, X., B, Y., & C, Z.' && CrossrefAuthorList(A('FAO', c('Doe', 'J'))) == 'FAO & Doe, J.' &&
         is.na(CrossrefAuthorList(list())),
       'one, two and three authors; an organisation name as given; none -> NA')
w <- CrossrefWork('10.1007/bf00392514', cfg)
cit <- FormatCitationText(w)
Expect(cit == paste('Ikeda, T. & Bruce, B. (1986). Metabolic activity and elemental composition of krill and other zooplankton from Prydz Bay, Antarctica,',
                    'during early summer (November?December). Marine Biology, 92(4), 545-555. https://doi.org/10.1007/bf00392514'),
       'the Citation cell of Ikeda & Bruce 1986 from the Crossref record only')
syn <- list(DOI = '10.1/X', type = 'book', title = list('A <i>Book</i>.'), author = list(list(name = 'Some Society')), publisher = 'Pub &amp; Co')
Expect(FormatCitationText(syn) == 'Some Society (n.d.). A Book. Pub & Co. https://doi.org/10.1/x',
       'no year -> n.d.; a trailing period is not doubled; tags stripped and &amp; decoded; the publisher stands in for the container')
Expect(FormatCitationText(list(DOI = '10.1/Y', title = list('T'), author = list(), `container-title` = list('J'), volume = '3', issued = list(`date-parts` = list(list(2000L))))) ==
         '(2000). T. J, 3. https://doi.org/10.1/y',
       'no authors and no pages: the parts that exist, in order')
Expect(Has(ErrorOf(FormatCitationText(list(title = list('T')))), 'Crossref work record with a DOI is required') && Has(ErrorOf(FormatCitationText(NULL)), 'required'),
       'no DOI: stop (nothing typed ever becomes a Citation cell)')
Row <- function(author1 = 'Kremer', year = 1976L, title = 'The ecology of the ctenophore Mnemiopsis leidyi in Narragansett Bay',
                container = 'Ph.D. thesis, Univ. of Rhode Island', volume = NA, pages = NA)
  list(parsed_author1 = author1, parsed_year = year, parsed_title = title, parsed_container = container, parsed_volume = volume, parsed_pages = pages)
Expect(FormatCitationTextNoDOI(Row()) == 'Kremer (1976). The ecology of the ctenophore Mnemiopsis leidyi in Narragansett Bay. Ph.D. thesis, Univ. of Rhode Island. No DOI.' &&
         FormatCitationTextNoDOI(Row(container = 'Mar. Biol.', volume = '3', pages = '4-10')) ==
           'Kremer (1976). The ecology of the ctenophore Mnemiopsis leidyi in Narragansett Bay. Mar. Biol., 3, 4-10. No DOI.' &&
         FormatCitationTextNoDOI(Row(author1 = NA, year = NA, container = NA)) == '(n.d.). The ecology of the ctenophore Mnemiopsis leidyi in Narragansett Bay. No DOI.' &&
         startsWith(FormatCitationTextNoDOI(Row(author1 = 'Ikeda and Hirakawa and Imamura')), 'Ikeda, Hirakawa, & Imamura (1976).') &&
         startsWith(FormatCitationTextNoDOI(Row(author1 = 'Omori and Ikeda')), 'Omori & Ikeda (1976).'),
       'the DOI-less cell from the approved parsed fields: the author field as approved (no invented et al.), ending with No DOI')
Expect(grepl('^Ikeda, T. & Bruce, B. \\(1985\\)\\.', FormatCitationText(w, year_override = 1985L)), 'a recorded year override changes the Citation cell year')

# ---- the rows -------------------------------------------------------------------------------------
cat('BuildSheetRows()\n')
prim <- EmptyPrimaryReferences()
prim[1:5, 'native_key'] <- as.character(1:5)
prim$source_label <- 'Kiorboe_2013'
prim$match_status <- c('certain', 'nodoi_approved', 'pending', 'certain', 'approved')
prim$doi <- c('10.1007/bf00392514', NA, '10.1/pending', NA, '10.1007/bf00392514')
prim$bibcite <- c('Ikeda:1986aa', 'Kremer:1976aa', 'X:2000aa', NA, 'Ikeda:1986aa')
prim$cite_id <- c('Ikeda_1986', 'Kremer_1976', 'X_2000', NA, 'Ikeda_1986')
prim$role <- c('measurement', 'measurement', 'measurement', 'measurement', 'compilation')
for (col in names(Row())) prim[[col]][2] <- Row()[[col]]
works <- list('10.1007/bf00392514' = w)
rows <- BuildSheetRows(prim, works, added = '2026-10-06', added_by = 'tbmcite test')
Expect(identical(names(rows), sheet_primary_columns) && nrow(rows) == 2 && identical(rows$CiteID, c('Ikeda_1986', 'Kremer_1976')) &&
         identical(rows$Bibcite, c('\\citep{Ikeda:1986aa}', '\\citep{Kremer:1976aa}')) && rows$Citation[1] == cit && endsWith(rows$Citation[2], 'No DOI.') &&
         identical(rows$DOI, c('10.1007/bf00392514', '')) && identical(rows$Role, c('measurement', 'measurement')) && all(rows$Added == '2026-10-06') && all(rows$AddedBy == 'tbmcite test'),
       'accepted rows with a bibcite and a CiteID become Sheet rows (Bibcite wrapped in \\citep{}); pending, keyless and duplicate-Bibcite rows are left out')
Expect(Has(ErrorOf(BuildSheetRows(prim, list())), 'no Crossref record for') && Has(ErrorOf(BuildSheetRows(prim, list())), 'Ikeda:1986aa'),
       'a certain row whose record is not in the cache stops (no cell is typed)')
Expect(nrow(BuildSheetRows(prim[3, ], works)) == 0 && identical(names(BuildSheetRows(prim[3, ], works)), sheet_primary_columns), 'nothing accepted: an empty frame with the schema')

# ---- the append through a fake io --------------------------------------------------------------------
cat('AppendPrimaryCitations() on a fake Sheet\n')
FakeSheet <- function(tabs = list()) {
  env <- new.env()
  env$tabs <- tabs; env$log <- character()
  io <- list(
    read   = function(url, tab) { env$log <- c(env$log, paste('read', tab)); env$tabs[[tab]] },
    exists = function(url, tab) { env$log <- c(env$log, paste('exists', tab)); tab %in% names(env$tabs) },
    create = function(url, tab, columns) {
      env$log <- c(env$log, paste('create', tab))
      env$tabs[[tab]] <- as.data.frame(setNames(rep(list(character()), length(columns)), columns), stringsAsFactors = FALSE)
      invisible(TRUE) },
    append = function(url, tab, rows) { env$log <- c(env$log, paste('append', tab, nrow(rows))); env$tabs[[tab]] <- rbind(env$tabs[[tab]], rows); invisible(TRUE) })
  list(io = io, env = env)
}
snap <- tempfile(fileext = '.csv')
fs <- FakeSheet()
res <- suppressMessages(AppendPrimaryCitations(rows, 'url', sheet_tab_primary, dry_run = TRUE, snapshot_path = snap, io = fs$io))
Expect(res$dry_run && nrow(res$new) == 2 && res$n_before == 0 && res$n_after == 0 && identical(fs$env$log, 'exists BM_primary_citations') && !file.exists(snap),
       'dry run on a missing tab: nothing created, nothing appended, no snapshot; the diff lists both rows')
fs <- FakeSheet()
res <- suppressMessages(AppendPrimaryCitations(rows, 'url', sheet_tab_primary, dry_run = FALSE, snapshot_path = snap, io = fs$io))
Expect(!res$dry_run && nrow(res$new) == 2 && res$n_before == 0 && res$n_after == 2 &&
         identical(fs$env$log, c('exists BM_primary_citations', 'create BM_primary_citations', 'read BM_primary_citations', 'append BM_primary_citations 2', 'read BM_primary_citations')) &&
         identical(names(fs$env$tabs[[sheet_tab_primary]]), sheet_primary_columns) && nrow(fs$env$tabs[[sheet_tab_primary]]) == 2,
       'real run on a missing tab: created with headers only, read, appended, read again')
after <- read.csv(snap, stringsAsFactors = FALSE, colClasses = 'character')
Expect(nrow(after) == 2 && identical(names(after), sheet_primary_columns) && identical(after$Bibcite, rows$Bibcite) && after$Citation[1] == cit,
       'the committed snapshot is the after state of the tab')
res2 <- suppressMessages(AppendPrimaryCitations(rows, 'url', sheet_tab_primary, dry_run = FALSE, snapshot_path = snap, io = fs$io))
Expect(nrow(res2$new) == 0 && res2$n_before == 2 && res2$n_after == 2 && !any(grepl('^append', fs$env$log[-(1:5)])) && nrow(fs$env$tabs[[sheet_tab_primary]]) == 2,
       'a second append of the same rows writes nothing (idempotent on Bibcite); the tab is snapshotted')
more <- rbind(rows, data.frame(CiteID = 'Doyle_2007', Bibcite = '\\citep{Doyle:2007aa}', Citation = 'Doyle ... https://doi.org/10.1016/j.jembe.2006.12.010',
                               DOI = '10.1016/j.jembe.2006.12.010', Role = 'measurement', Added = '2026-10-07', AddedBy = 'tbmcite test', stringsAsFactors = FALSE))
snap_before <- read.csv(snap, stringsAsFactors = FALSE, colClasses = 'character')
res3 <- suppressMessages(AppendPrimaryCitations(more, 'url', sheet_tab_primary, dry_run = FALSE, snapshot_path = snap, io = fs$io))
Expect(nrow(res3$new) == 1 && res3$new$CiteID == 'Doyle_2007' && res3$n_before == 2 && res3$n_after == 3 && nrow(fs$env$tabs[[sheet_tab_primary]]) == 3 &&
         nrow(read.csv(snap, stringsAsFactors = FALSE)) == 3 && nrow(snap_before) == 2,
       'only the new Bibcite is appended; the snapshot moves from 2 to 3 rows')
clash <- rows[1, ]; clash$Bibcite <- '\\citep{Other:1986aa}'
Expect(Has(ErrorOf(suppressMessages(AppendPrimaryCitations(clash, 'url', sheet_tab_primary, dry_run = FALSE, io = fs$io))), 'already in BM_primary_citations under another Bibcite') &&
         nrow(fs$env$tabs[[sheet_tab_primary]]) == 3,
       'a CiteID already used by another Bibcite stops before anything is written')
Expect(Has(ErrorOf(AppendPrimaryCitations(rows, 'url', sheet_tab_citations, dry_run = TRUE, io = fs$io)), 'writes go to BM_primary_citations only'),
       'the BM_citations tab is never a target')
Expect(Has(ErrorOf(AppendPrimaryCitations(rows[, -3], 'url', sheet_tab_primary, io = fs$io)), 'rows lack column'), 'rows without the schema stop')
odd <- FakeSheet(list(BM_primary_citations = data.frame(Key = 'x', stringsAsFactors = FALSE)))
Expect(Has(ErrorOf(suppressMessages(AppendPrimaryCitations(rows, 'url', sheet_tab_primary, io = odd$io))), 'has no Bibcite column'), 'a tab without a Bibcite column stops')
broken <- FakeSheet(); broken$io$append <- function(url, tab, rows) invisible(TRUE)     # an append that silently writes nothing
Expect(Has(ErrorOf(suppressMessages(AppendPrimaryCitations(rows, 'url', sheet_tab_primary, dry_run = FALSE, io = broken$io))), 'after the append the tab lacks'),
       'the re-read after the append must show every new Bibcite')
Expect(identical(names(SheetIO()), c('read', 'exists', 'create', 'append')), 'the default io has the four operations the fake implements')
pre <- FakeSheet(list(BM_primary_citations = rows[1, ]))
res4 <- suppressMessages(AppendPrimaryCitations(rows, 'url', sheet_tab_primary, dry_run = TRUE, io = pre$io))
Expect(nrow(res4$new) == 1 && res4$new$CiteID == 'Kremer_1976' && res4$n_before == 1 && !any(grepl('^(create|append)', pre$env$log)),
       'dry run on an existing tab: the diff is the rows not yet present and nothing is written')

cat('SnapshotSheetTab()\n')
sf <- tempfile(fileext = '.csv')
SnapshotSheetTab(data.frame(CiteID = c('A', NA), Bibcite = c('\\citep{A:2000aa}', 'b'), n = c(1L, 2L), stringsAsFactors = FALSE), sf)
back <- read.csv(sf, stringsAsFactors = FALSE, colClasses = 'character', na.strings = character())
Expect(identical(names(back), c('CiteID', 'Bibcite', 'n')) && back$CiteID[2] == '' && back$Bibcite[1] == '\\citep{A:2000aa}' && back$n[2] == '2',
       'a snapshot is a plain CSV of character columns with empty cells for NA')

cat(sprintf('\n%d checks, %d failed\n', n_checks, length(failures)))
if (length(failures) > 0) { cat(paste0('  FAIL: ', failures, '\n'), sep = ''); quit(status = 1) }
