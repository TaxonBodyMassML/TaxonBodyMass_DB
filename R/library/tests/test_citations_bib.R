# Tests for the bibliography layer of the citation tooling (issue #1):
# R/library/citations/build_bib.r and cite_ids.r. ReadBibEntries() runs on
# the curated BibDesk file and on a synthetic file; BuildBibEntry() on the
# recorded Crossref record of Ikeda & Bruce 1986 (R/library/citations/tests/
# fixtures/cache/) and on synthetic records of every mapped type;
# BuildBibEntryNoDOI(), WritePrimaryBib(), CheckBibKeysUnique(),
# CheckBibSyntax() (RefManageR, when installed) and the key / CiteID minting
# run on temporary files. No network access.
#
#   Rscript R/library/tests/test_citations_bib.R      (from any directory)
#
# Prints one line per expectation and exits with status 1 if any failed.

this_file <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE))
if (length(this_file) == 0)
  this_file <- file.path('R', 'library', 'tests', 'test_citations_bib.R')
repo <- normalizePath(file.path(dirname(this_file), '..', '..', '..'))
lib  <- file.path(repo, 'R', 'library')
source(file.path(lib, 'helpers.r'))
for (f in c('citations_config.r', 'normalise_citation.r', 'parse_reflists.r', 'verify_services.r', 'build_bib.r', 'cite_ids.r'))
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
Field <- function(entry, name) {         # the value of one field (values here contain no unescaped braces)
  m <- regmatches(entry, regexpr(paste0('\n\t', name, ' = \\{([^{}\n]|\\\\[{}])*\\}'), entry, perl = TRUE))
  if (length(m) == 0) NA_character_ else sub(paste0('^\n\t', name, ' = \\{(.*)\\}$'), '\\1', m, perl = TRUE)
}

cfg <- CitationsConfig(repo, offline = TRUE)
cfg$cache_dir <- file.path(lib, 'citations', 'tests', 'fixtures', 'cache')

# ---- reading ------------------------------------------------------------------------------------
cat('ReadBibEntries()\n')
cur <- ReadBibEntries(cfg$curated_bib)
Expect(nrow(cur) >= 420 && !anyDuplicated(cur$key) && 'Kiorboe:2013aa' %in% cur$key && cur$type[cur$key == 'Kiorboe:2013aa'] == 'article' &&
         cur$type[cur$key == 'Guo:2024aa'] == 'incollection',
       sprintf('the curated bib reads: %d entries with unique keys and lowercase types', nrow(cur)))
Expect(sum(!is.na(cur$doi)) >= 17 && all(cur$doi[!is.na(cur$doi)] == tolower(cur$doi[!is.na(cur$doi)])) && '10.1139/f10-035' %in% cur$doi &&
         all(grepl('^10\\.', cur$doi[!is.na(cur$doi)])),
       sprintf('%d curated entries carry a DOI, read lowercase and bare', sum(!is.na(cur$doi))))
syn <- tempfile(fileext = '.bib')
writeLines(c('%% comment', '@comment{BibDesk notes}', '@string{jt = "Journal"}', '', '@Article{Alpha:2001aa,', '\tauthor = {A},', '\tdoi = "https://doi.org/10.1/ALPHA",', '\tyear = {2001}}',
             '@book{Beta:1999aa,', '\ttitle = {B}}', '@misc{ Gamma:2000aa ,', '\tDOI = {10.1/gamma.},', '}'), syn)
sb <- ReadBibEntries(syn)
Expect(identical(sb$key, c('Alpha:2001aa', 'Beta:1999aa', 'Gamma:2000aa')) && identical(sb$type, c('article', 'book', 'misc')) &&
         identical(sb$doi, c('10.1/alpha', NA, '10.1/gamma')),
       '@comment and @string are skipped; quoted, prefixed and upper-case DOI fields are cleaned; a key with blanks is trimmed')
Expect(nrow(ReadBibEntries(tempfile())) == 0 && identical(names(ReadBibEntries(tempfile())), c('key', 'type', 'doi')), 'a missing bib reads as no entries')

# ---- keys -----------------------------------------------------------------------------------------
cat('FoldSurnameForKey(), BibKeyFor()\n')
Expect(identical(FoldSurnameForKey(c('Kiørboe', 'van der Meer', "O'Brien", 'Menden-Deuer', ' Falk‐Petersen ', 'Hárdstedt-Roméo')),
                 c('Kiorboe', 'van-der-Meer', 'OBrien', 'Menden-Deuer', 'Falk-Petersen', 'Hardstedt-Romeo')),
       'surnames fold diacritics and the Unicode hyphen, blanks become -, apostrophes vanish')
Expect(BibKeyFor('Doyle', 2007L) == 'Doyle:2007aa' && BibKeyFor('Doyle', 2007L, known_keys = 'Doyle:2007aa') == 'Doyle:2007ab' &&
         BibKeyFor('Doyle', 2007L, known_keys = c('Doyle:2007aa', 'Doyle:2007ab')) == 'Doyle:2007ac' &&
         BibKeyFor('Doyle', 2007L, known_keys = paste0('Doyle:2007', TwoLetterSuffixes()[1:26])) == 'Doyle:2007ba',
       "'Surname:YYYYaa' with the first free two-letter suffix (aa, ab, ..., az, ba)")
Expect(BibKeyFor('Other', 1999L, doi = 'https://doi.org/10.1016/J.JEMBE.2006.12.010', known_keys = c('Doyle:2007aa'),
                 known_dois = c('Doyle:2007aa' = '10.1016/j.jembe.2006.12.010', 'X:2000aa' = NA)) == 'Doyle:2007aa',
       'a DOI already attached to a key reuses that key whatever the surname or year')
Expect(BibKeyFor('Kiørboe', 2013L, known_keys = cur$key) == 'Kiorboe:2013ab' && BibKeyFor(NA, NA) == 'Anon:ndaa' && BibKeyFor('Smith', NA) == 'Smith:ndaa' &&
         BibKeyFor('', 2001L) == 'Anon:2001aa',
       'the curated key Kiorboe:2013aa is taken; missing surname -> Anon, missing year -> nd')
Expect(length(TwoLetterSuffixes()) == 676 && TwoLetterSuffixes()[1] == 'aa' && TwoLetterSuffixes()[27] == 'ba' && !anyDuplicated(TwoLetterSuffixes()),
       '676 distinct suffixes in BibDesk order')

# ---- entries from Crossref ------------------------------------------------------------------------
cat('EscapeLaTeX(), CrossrefAuthors(), CrossrefYear(), BuildBibEntry()\n')
Expect(EscapeLaTeX('Fish &amp; chips at 100% of <i>Salpa</i> {thompsoni}_1 #2 $3 ~ ^') == 'Fish \\& chips at 100\\% of Salpa \\{thompsoni\\}\\_1 \\#2 \\$3 \\textasciitilde{} \\textasciicircum{}',
       'HTML is stripped and the LaTeX specials are escaped')
Expect(EscapeLaTeX('a\\b') == 'a\\textbackslash{}b' && EscapeLaTeX('  two   spaces  ') == 'two spaces' && EscapeLaTeX('x&lt;y&gt;z&nbsp;w&eacute;') == 'x<y>z w',
       'a backslash becomes \\textbackslash{}, blanks collapse, entities decode or vanish')
w <- CrossrefWork('10.1007/bf00392514', cfg)
Expect(CrossrefAuthors(w) == 'Ikeda, T. and Bruce, B.' && CrossrefYear(w) == 1986L && CrossrefTitle(w) == w$title[[1]],
       'authors joined with and, the issued year, the title without a subtitle')
Expect(CrossrefAuthors(list(author = list(list(name = 'FAO & WHO'), list(family = 'Doe', given = 'J. P.')))) == '{FAO \\& WHO} and Doe, J. P.' &&
         is.na(CrossrefAuthors(list())) && CrossrefYear(list(created = list(`date-parts` = list(list(2020L))))) == 2020L && is.na(CrossrefYear(list())),
       'an organisation author is braced; no authors -> NA; the year falls back to created')
e <- BuildBibEntry(w, 'Ikeda:1986aa')
Expect(startsWith(e, '@article{Ikeda:1986aa,\n') && Field(e, 'author') == 'Ikeda, T. and Bruce, B.' && Field(e, 'journal') == 'Marine Biology' &&
         Field(e, 'volume') == '92' && Field(e, 'number') == '4' && Field(e, 'pages') == '545--555' && Field(e, 'year') == '1986' && Field(e, 'doi') == '10.1007/bf00392514' &&
         startsWith(Field(e, 'title'), 'Metabolic activity and elemental composition of krill') && endsWith(e, '}'),
       'Ikeda & Bruce 1986 from the Crossref record: @article with journal, volume, number, pages (--), year and doi')
Expect(!grepl('\n\t(note|publisher|booktitle|school|howpublished) = ', e, perl = TRUE) && length(strsplit(e, '\n')[[1]]) == 9,
       'no empty or foreign fields; one field per line')
Mk <- function(type, ...) c(list(DOI = '10.1/T', type = type, title = list('A <i>Title</i> &amp; more'), author = list(list(family = 'Doe', given = 'J.')),
                                 issued = list(`date-parts` = list(list(2010L)))), list(...))
ch <- BuildBibEntry(Mk('book-chapter', `container-title` = list('Big Book'), publisher = 'Pub House', page = '1-9'), 'Doe:2010aa')
Expect(startsWith(ch, '@incollection{Doe:2010aa,') && Field(ch, 'booktitle') == 'Big Book' && Field(ch, 'publisher') == 'Pub House' && Field(ch, 'pages') == '1--9' &&
         Field(ch, 'title') == 'A Title \\& more' && Field(ch, 'doi') == '10.1/t',
       'book-chapter -> @incollection with booktitle and publisher; HTML stripped and escaped in the title; DOI lowercased')
bk <- BuildBibEntry(Mk('book', publisher = 'Pub House', `container-title` = list('A Series')), 'Doe:2010ab')
Expect(startsWith(bk, '@book{') && Field(bk, 'publisher') == 'Pub House' && Field(bk, 'series') == 'A Series' && is.na(Field(bk, 'journal')),
       'book -> @book with publisher and a series when the container differs from the title')
th <- BuildBibEntry(Mk('dissertation', institution = list(list(name = 'Some University')), publisher = 'ProQuest'), 'Doe:2010ac')
Expect(startsWith(th, '@phdthesis{') && Field(th, 'school') == 'Some University', 'dissertation -> @phdthesis with the institution as school')
rp <- BuildBibEntry(Mk('report', publisher = 'An Agency'), 'Doe:2010ad')
Expect(startsWith(rp, '@techreport{') && Field(rp, 'institution') == 'An Agency', 'report -> @techreport with the publisher as institution')
pa <- BuildBibEntry(Mk('proceedings-article', `container-title` = list('Proc Conf'), publisher = 'Soc'), 'Doe:2010ae')
Expect(startsWith(pa, '@inproceedings{') && Field(pa, 'booktitle') == 'Proc Conf', 'proceedings-article -> @inproceedings')
ms <- BuildBibEntry(Mk('posted-content', publisher = 'bioRxiv'), 'Doe:2010af')
Expect(startsWith(ms, '@misc{') && Field(ms, 'howpublished') == 'bioRxiv', 'an unmapped type -> @misc with howpublished')
st <- BuildBibEntry(Mk('journal-article', subtitle = list('With a subtitle'), `container-title` = list('J')), 'Doe:2010ag')
Expect(Field(st, 'title') == 'A Title \\& more: With a subtitle', 'a subtitle is appended to the title')
Expect(Has(ErrorOf(BuildBibEntry(list(type = 'book'), 'X')), 'Crossref work record with a DOI is required') && Has(ErrorOf(BuildBibEntry(NULL, 'X')), 'required'),
       'no record or no DOI: stop (nothing typed ever becomes an entry)')
yo <- BuildBibEntry(w, 'Ikeda:1986ab', year_override = 1985L)
Expect(Field(yo, 'year') == '1985' && Field(yo, 'note') == 'Year 1985 by owner decision (the Crossref record says 1986)' && Field(yo, 'doi') == '10.1007/bf00392514' &&
         Field(e, 'year') == '1986' && is.na(Field(e, 'note')),
       'a recorded year override replaces the year and is noted in the entry; without one the record\'s year stands')

cat('BuildBibEntryNoDOI()\n')
Row <- function(author1 = 'Kremer', year = 1976L, title = 'The ecology of the ctenophore Mnemiopsis leidyi in Narragansett Bay',
                container = 'Ph.D. thesis, Univ. of Rhode Island', volume = NA, pages = NA)
  list(source_label = 'Kiorboe_2013', parsed_author1 = author1, parsed_year = year, parsed_title = title, parsed_container = container,
       parsed_volume = volume, parsed_pages = pages)
nd <- BuildBibEntryNoDOI(Row(), 'Kremer:1976aa', 'MN', '2026-10-06')
Expect(startsWith(nd, '@phdthesis{Kremer:1976aa,') && Field(nd, 'school') == 'Univ. of Rhode Island' && Field(nd, 'author') == 'Kremer' && Field(nd, 'year') == '1976' &&
         Field(nd, 'note') == 'No DOI; from Kiorboe_2013 reference list; approved 2026-10-06 MN' && is.na(Field(nd, 'doi')),
       'a thesis: @phdthesis with the school after the thesis marker and the approval note')
ar <- BuildBibEntryNoDOI(Row(container = 'Mar. Biol.', volume = '3', pages = '4-10'), 'Kremer:1976ab', 'MN', '2026-10-06')
Expect(startsWith(ar, '@article{') && Field(ar, 'journal') == 'Mar. Biol.' && Field(ar, 'volume') == '3' && Field(ar, 'pages') == '4--10', 'volume or pages: @article')
bo <- BuildBibEntryNoDOI(Row(container = 'John Wiley & Sons'), 'Kremer:1976ac', 'MN', '2026-10-06')
Expect(startsWith(bo, '@book{') && Field(bo, 'publisher') == 'John Wiley \\& Sons', 'a container without volume or pages: @book with an escaped publisher')
mi <- BuildBibEntryNoDOI(Row(container = NA, author1 = NA, year = NA), 'anon:2000aa', 'MN', '2026-10-06')
Expect(startsWith(mi, '@misc{') && is.na(Field(mi, 'author')) && is.na(Field(mi, 'year')) && Field(mi, 'title') == Row()$parsed_title, 'nothing but a title: @misc')
al <- BuildBibEntryNoDOI(Row(author1 = 'Ikeda and Hirakawa and Imamura', container = 'Plankton Biology and Ecology', volume = '45', pages = '31-44', year = 1998L), 'Ikeda:1998aa', 'owner', '2026-10-04')
Expect(Field(al, 'author') == 'Ikeda and Hirakawa and Imamura' && startsWith(al, '@article{'), 'an owner-approved author list in BibTeX form is kept as the author field')
Expect(FirstOfAuthorList('Ikeda and Hirakawa and Imamura') == 'Ikeda' && FirstOfAuthorList('Kremer') == 'Kremer' && FirstOfAuthorList('Doe, J. and Roe, R.') == 'Doe' && is.na(FirstOfAuthorList(NA)),
       'FirstOfAuthorList() gives the first surname of an author field for keys and CiteIDs')

cat('MatchingNoDOIEntry()\n')
NoDOIRow <- function(source_label, native_key, author1, year, title, bibcite = NA_character_, status = 'nodoi_approved')
  data.frame(source_label = source_label, native_key = native_key, parsed_author1 = author1, parsed_year = year,
             parsed_title = title, bibcite = bibcite, match_status = status, decided_by = 'owner', decided_at = '2026-10-04',
             parsed_container = 'Plankton Biology and Ecology', parsed_volume = '45', parsed_pages = '31-44', stringsAsFactors = FALSE)
pri <- rbind(NoDOIRow('Kiorboe_2013', '7', 'Ikeda and Hirakawa and Imamura', 1998L,
                      'Metabolism and body composition of zooplankton in the cold mesopelagic zone of the southern Japan Sea', 'Ikeda:1998aa'),
             NoDOIRow('Kiorboe_2013', '9', 'Kremer', 1976L, 'The ecology of the ctenophore Mnemiopsis leidyi in Narragansett Bay', 'Kremer:1976aa'),
             NoDOIRow('Hebert_etal_2016', '74', 'Ikeda', 1998L,
                      'Metabolism and body composition of zooplankton in the cold mesopelagic zone of the southern Japan Sea.'))
tw <- MatchingNoDOIEntry(pri[3, ], pri)
Expect(!is.null(tw) && tw$bibcite == 'Ikeda:1998aa' && tw$source_label == 'Kiorboe_2013',
       'the same first surname, year and normalised title (author list vs surname, trailing period) reuses the other source\'s key')
Expect(is.null(MatchingNoDOIEntry(NoDOIRow('Hebert_etal_2016', '69', 'Ikeda', 1974L, 'Nutritional ecology of marine zooplankton'), pri)),
       'a different title gets no match (a new key is minted)')
Expect(is.null(MatchingNoDOIEntry(NoDOIRow('Hebert_etal_2016', '74', 'Ikeda', 1999L, pri$parsed_title[1]), pri)),
       'a different year gets no match')
Expect(is.null(MatchingNoDOIEntry(pri[1, ], pri)), 'a row never matches itself')
pri2 <- pri; pri2$match_status[1] <- 'pending'; pri2$bibcite[1] <- NA
Expect(is.null(MatchingNoDOIEntry(pri2[3, ], pri2)), 'only nodoi_approved rows with a bibcite are reused')

# ---- the file -------------------------------------------------------------------------------------------
cat('WritePrimaryBib(), CheckBibSyntax(), CheckBibKeysUnique()\n')
pb <- tempfile(fileext = '.bib')
WritePrimaryBib(c('Ikeda:1986aa' = e, 'Doe:2010aa' = ch, 'Kremer:1976aa' = nd, 'anon:2000aa' = mi), pb)
lines <- readLines(pb, encoding = 'UTF-8')
Expect(startsWith(lines[1], '%% GENERATED by R/library/citations/build_bib.r') && any(grepl(citations_tool_version, lines, fixed = TRUE)) && lines[7] == '',
       'the header says GENERATED and names the tool version')
rb <- ReadBibEntries(pb)
Expect(identical(rb$key, c('Doe:2010aa', 'Ikeda:1986aa', 'Kremer:1976aa', 'anon:2000aa')) && identical(rb$type, c('incollection', 'article', 'phdthesis', 'misc')) &&
         identical(rb$doi, c('10.1/t', '10.1007/bf00392514', NA, NA)),
       'entries are written in byte order of the keys (upper case before lower) and read back')
Expect(Has(ErrorOf(WritePrimaryBib(c('A:1aa' = e, 'A:1aa' = ch), tempfile())), 'duplicated key'), 'duplicated keys stop the write')
empty <- tempfile(fileext = '.bib'); WritePrimaryBib(character(), empty)
Expect(nrow(ReadBibEntries(empty)) == 0 && startsWith(readLines(empty)[1], '%% GENERATED'), 'an empty entry set writes the header only')
n <- CheckBibSyntax(pb)
Expect(is.na(n) || n == 4L, sprintf('RefManageR parses every generated entry (%s)', if (is.na(n)) 'RefManageR not installed, skipped' else n))
if (!is.na(n)) {
  bad <- tempfile(fileext = '.bib'); writeLines(c(readLines(pb), '@article{Broken:2000aa,', '\tauthor = {Unclosed'), bad)
  Expect(!is.null(ErrorOf(CheckBibSyntax(bad))) || isTRUE(suppressWarnings(CheckBibSyntax(bad)) < 5), 'a broken entry is not counted as parsed')
}
cb <- tempfile(fileext = '.bib'); writeLines(c('@article{Doe:2010aa,', '\ttitle = {X}}', '@book{Only:2000aa,', '\ttitle = {Y}}'), cb)
Expect(Has(ErrorOf(CheckBibKeysUnique(cb, pb)), 'present in both') && Has(ErrorOf(CheckBibKeysUnique(cb, pb)), 'Doe:2010aa'),
       'a key in both files stops the pipeline')
cb2 <- tempfile(fileext = '.bib'); writeLines(c('@book{Only:2000aa,', '\ttitle = {Y}}', '@book{Only:2000aa,', '\ttitle = {Z}}'), cb2)
Expect(Has(ErrorOf(CheckBibKeysUnique(cb2, pb)), 'duplicated bib key'), 'a key twice in one file stops too')
cb3 <- tempfile(fileext = '.bib'); writeLines(c('@book{Only:2000aa,', '\ttitle = {Y}}'), cb3)
ok <- CheckBibKeysUnique(cb3, pb)
Expect(is.list(ok) && nrow(ok$curated) == 1 && nrow(ok$primary) == 4, 'disjoint files pass and return both entry tables')
Expect(is.null(ErrorOf(CheckBibKeysUnique(cfg$curated_bib, tempfile()))), 'the curated bib alone has unique keys')

# ---- CiteIDs ----------------------------------------------------------------------------------------------
cat('FoldSurnameForCiteID(), CiteIDFor()\n')
Expect(identical(FoldSurnameForCiteID(c('Martinez-Palacios', 'van der Meer', "O'Brien", 'Kiørboe', 'Menden-Deuer')),
                 c('Martinez-Palacios', 'vanderMeer', 'OBrien', 'Kiorboe', 'Menden-Deuer')),
       'CiteID surnames keep hyphens, drop blanks and apostrophes, fold diacritics')
known <- data.frame(CiteID = c('Doyle_2007', 'Ikeda_1986', 'Kiorboe_2013'), Bibcite = c('Doyle:2007aa', 'Ikeda:1986aa', 'Kiorboe:2013aa'),
                    doi = c('10.1016/j.jembe.2006.12.010', NA, NA), stringsAsFactors = FALSE)
Expect(CiteIDFor('Doyle', 2007L) == 'Doyle_2007' && CiteIDFor('Doyle', 2007L, known = known) == 'Doyle_2007b' &&
         CiteIDFor('Doyle', 2007L, known = rbind(known, data.frame(CiteID = 'Doyle_2007b', Bibcite = 'Doyle:2007ab', doi = NA))) == 'Doyle_2007c',
       "'Surname_YYYY' with b, c, ... suffixes over the known CiteIDs (never _etal_)")
Expect(CiteIDFor('Other', 1999L, bibcite = 'Ikeda:1986aa', known = known) == 'Ikeda_1986' &&
         CiteIDFor('Other', 1999L, doi = 'https://doi.org/10.1016/J.JEMBE.2006.12.010', known = known) == 'Doyle_2007' &&
         CiteIDFor('Other', 1999L, doi = '10.1/new', bibcite = 'New:1999aa', known = known) == 'Other_1999',
       'an existing Bibcite or DOI reuses its CiteID; otherwise a new id is minted')
Expect(CiteIDFor(NA, NA) == 'Anon_nd' && CiteIDFor('van der Meer', 1994L) == 'vanderMeer_1994' && CiteIDFor('Martinez-Palacios', 1992L) == 'Martinez-Palacios_1992' &&
         CiteIDFor('Smith', 2003L, known = known[, c('CiteID', 'Bibcite')]) == 'Smith_2003',
       'missing parts -> Anon / nd; hyphens kept; a known table without a doi column works')
ids <- read.csv(cfg$citeids_csv, stringsAsFactors = FALSE, colClasses = 'character')
Expect(identical(names(ids)[1:2], c('Bibcite', 'CiteID')) && !anyDuplicated(ids$CiteID) && CiteIDFor('Kiorboe', 2013L, bibcite = 'Kiorboe:2013aa', known = ids) == 'Kiorboe_2013' &&
         CiteIDFor('Kiorboe', 2013L, known = ids) == 'Kiorboe_2013b',
       'the tracked CiteIDs CSV: Bibcite and CiteID first, unique ids, Kiorboe:2013aa reuses Kiorboe_2013, a new Kiorboe 2013 work gets Kiorboe_2013b')

cat(sprintf('\n%d checks, %d failed\n', n_checks, length(failures)))
if (length(failures) > 0) { cat(paste0('  FAIL: ', failures, '\n'), sep = ''); quit(status = 1) }
