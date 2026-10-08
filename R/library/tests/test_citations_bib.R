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
cat('NormaliseSurname(), CrossrefFirstSurname()\n')
Expect(identical(NormaliseSurname(c('MULDER', 'A. Piechnik', 'McLaughlin', "O'Gorman", 'van der Meer', 'DE GOEDE', 'Kiørboe')),
                 c('Mulder', 'Piechnik', 'McLaughlin', "O'Gorman", 'van der Meer', 'De Goede', 'Kiørboe')),
       'leading initials dropped, all-capitals surnames title-cased, mixed case untouched')
Expect(identical(NormaliseSurname(c('Evans-WHITE', 'VillEGER', 'MacDONALD', 'DeLong', "O'GORMAN", 'LE GALL', 'Smith-Jones', 'X', NA)),
                 c('Evans-White', 'Villeger', 'Macdonald', 'DeLong', "O'Gorman", 'Le Gall', 'Smith-Jones', 'X', NA)),
       'token by token: an all-capitals token and a run of capitals after a lowercase letter are repaired; ordinary mixed case stays (#114 item 8)')
Expect(identical(FoldSurnameForKey(c('Evans-WHITE', 'VillEGER', 'Båmstedt', 'Bmstedt', 'Sma', 'Schönheit')), c('Evans-White', 'Villeger', 'Bamstedt', 'Bmstedt', 'Sma', 'Schonheit')) &&
         identical(FoldSurnameForCiteID(c('Evans-WHITE', 'VillEGER')), c('Evans-White', 'Villeger')),
       "keys fold diacritics and repair the case; a letter the record lost ('Bmstedt', 'Sma') cannot be restored by code")
Expect(identical(FoldSurnameForKey(c('MULDER', 'A. Piechnik')), c('Mulder', 'Piechnik')) &&
         identical(FoldSurnameForCiteID(c('MULDER', 'A. Piechnik')), c('Mulder', 'Piechnik')),
       'both folders apply NormaliseSurname()')
Expect(CrossrefFirstSurname(list(author = list(list(sequence = 'first'), list(family = 'Cattin Blandenier', given = 'Marie-France')))) == 'Cattin Blandenier' &&
         CrossrefFirstSurname(list(author = list(list(name = 'Some Institute')))) == 'Some Institute' &&
         is.na(CrossrefFirstSurname(list(author = list(list(sequence = 'first'))))) && is.na(CrossrefFirstSurname(list())),
       'the first author with a name is used for the key; NA when none has one')

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
cat('CrossrefYears(), KeyYear()\n')
two <- list(DOI = '10.1/two', author = list(list(family = 'VillEGER', given = 'S.')), title = list('T'),
            issued = list(`date-parts` = list(list(2012L, 11L))), `published-online` = list(`date-parts` = list(list(2012L, 11L))), `published-print` = list(`date-parts` = list(list(2013L, 3L))))
Expect(identical(CrossrefYears(two), c(2012L, 2013L)) && CrossrefYear(two) == 2012L && KeyYear(two, NA, 2013L) == 2013L && KeyYear(two, NA, 2012L) == 2012L &&
         KeyYear(two, NA, 2011L) == 2012L && KeyYear(two, NA, NA) == 2012L && KeyYear(two, 1976L, 2013L) == 1976L && identical(CrossrefYears(list()), integer()),
       "the citation's year wins over the online-first year when the record carries it; a year the record lacks is ignored; the override wins over both")

cat('EscapeLaTeX(), CrossrefAuthors(), CrossrefYear(), BuildBibEntry()\n')
Expect(EscapeLaTeX('Fish &amp; chips at 100% of <i>Salpa</i> {thompsoni}_1 #2 $3 ~ ^') == 'Fish \\& chips at 100\\% of Salpa \\{thompsoni\\}\\_1 \\#2 \\$3 \\textasciitilde{} \\textasciicircum{}',
       'HTML is stripped and the LaTeX specials are escaped')
Expect(EscapeLaTeX('The pangolin {Manis temmincki Smuts, 1835) in Zimbabwe') == 'The pangolin \\textbraceleft{}Manis temmincki Smuts, 1835) in Zimbabwe' &&
         EscapeLaTeX('a } b') == 'a \\textbraceright{} b' && EscapeLaTeX('{a} {b}') == '\\{a\\} \\{b\\}',
       'an unbalanced brace becomes \\textbraceleft{} / \\textbraceright{} (parseable); balanced pairs stay \\{ \\} (Coulson 1989 of Jones_2009)')
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

cat('BuildBibEntryNoDOI(): the conventions of #114 item 1 (theses, chapters, corporate authors, URLs)\n')
nt <- BuildBibEntryNoDOI(Row(author1 = 'Allgaier', year = 1993L, title = NA_character_, container = 'Bat Research News', volume = '34', pages = '100'), 'Allgaier:1993aa', 'owner', '2026-10-08')
tfn <- tempfile(fileext = '.bib'); writeLines(nt, tfn)
Expect(startsWith(nt, '@article{Allgaier:1993aa,') && !grepl('title', nt, fixed = TRUE) && Field(nt, 'journal') == 'Bat Research News' && Field(nt, 'volume') == '34' && Field(nt, 'pages') == '100' &&
         length(suppressMessages(suppressWarnings(RefManageR::ReadBib(tfn, check = FALSE)))) == 1,
       'a nodoi row without a title (a journal item cited by journal, volume and page) builds a valid @article with no title field, never title = {NA}')
apa_ch <- BuildBibEntryNoDOI(Row(author1 = 'Doi', year = 1987L, title = 'Distribution of Japanese serow in its southern range, Kyushu',
                                 container = 'In: H. Soma (Ed.), The biology and management of Capricornis and related mountain antelopes. Croom Helm', pages = '93-103'), 'Doi:1987aa', 'owner', '2026-10-08')
Expect(startsWith(apa_ch, '@incollection{') && Field(apa_ch, 'editor') == 'H. Soma' && Field(apa_ch, 'booktitle') == 'The biology and management of Capricornis and related mountain antelopes' &&
         Field(apa_ch, 'publisher') == 'Croom Helm' && Field(apa_ch, 'pages') == '93--103',
       "the chapter container ParseAPAStyle() builds from an APA note reads as @incollection with editor, booktitle, publisher and pages")

ms <- BuildBibEntryNoDOI(Row(container = 'MSc thesis, University of British Columbia'), 'Nsiku:1999aa', 'MN', '2026-10-06')
Expect(startsWith(ms, '@mastersthesis{') && Field(ms, 'school') == 'University of British Columbia', "an 'MSc thesis' container: @mastersthesis with the school")
Expect(startsWith(BuildBibEntryNoDOI(Row(container = 'M.S. thesis, Middle Tennessee State University'), 'B:2015aa', 'MN', '2026-10-06'), '@mastersthesis{') &&
         startsWith(BuildBibEntryNoDOI(Row(container = 'MSc. Thesis, Ben Gurion University of the Negev'), 'B:2003aa', 'MN', '2026-10-06'), '@mastersthesis{') &&
         startsWith(BuildBibEntryNoDOI(Row(container = "Master's thesis, Some College"), 'B:2003ab', 'MN', '2026-10-06'), '@mastersthesis{') &&
         startsWith(BuildBibEntryNoDOI(Row(container = 'Ph.D. Thesis, Stanford University'), 'A:1966aa', 'MN', '2026-10-06'), '@phdthesis{') &&
         startsWith(BuildBibEntryNoDOI(Row(container = 'Unpublished PhD dissertation, University of Massachusetts'), 'A:1966ab', 'MN', '2026-10-06'), '@phdthesis{'),
       "M.S., MSc., Master's are masters theses; Ph.D. and a dissertation stay @phdthesis (Massachusetts is not an M.S.)")
Expect(ThesisSchool('University of Oslo, PhD thesis') == 'University of Oslo' && ThesisSchool('Ph.D. thesis, Univ. of Rhode Island') == 'Univ. of Rhode Island' &&
         is.na(ThesisSchool('PhD thesis')),
       'ThesisSchool() takes the text after the thesis word, or before it when nothing follows')
ch1 <- BuildBibEntryNoDOI(Row(author1 = 'Speakman, J. R. and Thomas, D. W.', year = 2003L, title = 'Physiological ecology and energetics of bats',
                              container = 'Bat Ecology (Kunz TH, Fenton MB, eds), University of Chicago Press, Chicago', pages = '430-490'), 'Speakman:2003aa', 'owner', '2026-10-04')
Expect(startsWith(ch1, '@incollection{Speakman:2003aa,') && Field(ch1, 'editor') == 'Kunz TH and Fenton MB' && Field(ch1, 'booktitle') == 'Bat Ecology' &&
         Field(ch1, 'publisher') == 'University of Chicago Press, Chicago' && Field(ch1, 'pages') == '430--490' && is.na(Field(ch1, 'journal')),
       "form B 'Book title (Editors, eds), Publisher, Place': @incollection with editor, booktitle, publisher and pages")
Expect(BibTeXNameList('Gans, C., Dawson, W. R.') == 'Gans, C. and Dawson, W. R.' &&
         BibTeXNameList('Huei, R. B., Pianka, E. R. and Schoener, T. W.') == 'Huei, R. B. and Pianka, E. R. and Schoener, T. W.' &&
         BibTeXNameList('Horn, H.-G., Bohme, W. & U. Krebs') == 'Horn, H.-G. and Bohme, W. and U. Krebs' &&
         BibTeXNameList('Fielder, P. L. and, Kareiva, P. M.') == 'Fielder, P. L. and Kareiva, P. M.' &&
         BibTeXNameList('Rockstein, M.') == 'Rockstein, M.' && BibTeXNameList('Kunz TH and Fenton MB') == 'Kunz TH and Fenton MB',
       "BibTeXNameList(): comma / '&' editor lists become ' and '-joined BibTeX name lists; initials stay with their surname")
chE <- BuildBibEntryNoDOI(Row(author1 = 'Bennett', year = 1976L, title = 'Metabolism', container = 'Biology of Reptilia, Vol. 5, p. 127-223. Gans, C., Dawson, W. R., Editors, London, Academic Press', pages = '127-223'), 'Bennett:1976aa', 'owner', '2026-10-05')
tfE <- tempfile(fileext = '.bib'); writeLines(chE, tfE)
Expect(Field(chE, 'editor') == 'Gans, C. and Dawson, W. R.' && length(suppressMessages(suppressWarnings(RefManageR::ReadBib(tfE, check = FALSE)))) == 1,
       'a chapter whose editors are comma-joined gets a BibTeX editor list RefManageR parses (the Meiri_2018 Bennett 1976 entry)')
ch2 <- BuildBibEntryNoDOI(Row(author1 = 'Keister and Buck', year = 1964L, container = 'Physiology of Insecta, Volume 3 (ed. Rockstein, M.), Academic Press, New York', volume = '3', pages = '617-658'),
                          'Keister:1964aa', 'owner', '2026-10-04')
Expect(startsWith(ch2, '@incollection{') && Field(ch2, 'editor') == 'Rockstein, M.' && Field(ch2, 'booktitle') == 'Physiology of Insecta, Volume 3' &&
         Field(ch2, 'publisher') == 'Academic Press, New York' && Field(ch2, 'volume') == '3' && Field(ch2, 'pages') == '617--658',
       "'(ed. Name)' marks the editor; the volume of the series is kept")
ch3 <- BuildBibEntryNoDOI(Row(container = 'In: Burghardt, G. M. and Rand, A. S. (eds.), Iguanas of the world: their behavior, ecology and conservation. Noyes Publications, Park Ridge, New Jersey', pages = '84-116'),
                          'Auffenberg:1982aa', 'owner', '2026-10-05')
Expect(startsWith(ch3, '@incollection{') && Field(ch3, 'editor') == 'Burghardt, G. M. and Rand, A. S.' && Field(ch3, 'booktitle') == 'Iguanas of the world: their behavior, ecology and conservation' &&
         Field(ch3, 'publisher') == 'Noyes Publications, Park Ridge, New Jersey' && Field(ch3, 'pages') == '84--116',
       "form A 'In: Editors (eds.), Book title. Publisher, Place': the booktitle ends at the first sentence end after the marker")
ch4 <- BuildBibEntryNoDOI(Row(container = 'Pages 9-28 In: Bennett, D. (Ed.), Wildlife of Polillo Island Philippines. University of Oxford'), 'Bennett:2000aa', 'owner', '2026-10-05')
Expect(startsWith(ch4, '@incollection{') && Field(ch4, 'editor') == 'Bennett, D.' && Field(ch4, 'booktitle') == 'Wildlife of Polillo Island Philippines' &&
         Field(ch4, 'publisher') == 'University of Oxford' && Field(ch4, 'pages') == '9--28',
       'a leading pages clause before In: fills the pages when parsed_pages is empty')
ch5 <- BuildBibEntryNoDOI(Row(container = 'Biology of Reptilia, Vol. 5, p. 127-223. Gans, C., Dawson, W. R., Editors, London, Academic Press'), 'Bennett:1976aa', 'owner', '2026-10-05')
Expect(startsWith(ch5, '@incollection{') && Field(ch5, 'editor') == 'Gans, C. and Dawson, W. R.' && Field(ch5, 'booktitle') == 'Biology of Reptilia, Vol. 5' &&
         Field(ch5, 'publisher') == 'London, Academic Press' && Field(ch5, 'pages') == '127--223',
       "'Editors' outside brackets: the sentence before it names the editors, 'p. 127-223' gives the pages")
ch6 <- ParseChapterContainer('A. Alon (editor) Encyclopedia of plants and animals of the land of Israel. Ministry of Defense Press, Tel-Aviv. (in Hebrew)')
Expect(ch6$editor == 'A. Alon' && ch6$booktitle == 'Encyclopedia of plants and animals of the land of Israel' && ch6$publisher == 'Ministry of Defense Press, Tel-Aviv. (in Hebrew)',
       "'<Editors> (editor) <Book title>. <Publisher>': initials before a marker-only bracket name the editors")
Expect(is.null(ParseChapterContainer('Handbook of birds, 2nd ed. Oxford University Press')) && is.null(ParseChapterContainer('John Wiley & Sons')) &&
         is.null(ParseChapterContainer(NA)) && is.null(ParseChapterContainer('Mammals in the Seas')) &&
         startsWith(BuildBibEntryNoDOI(Row(container = 'Handbook of birds, 2nd ed. Oxford University Press'), 'H:2000aa', 'MN', '2026-10-06'), '@book{'),
       "a singular 'ed.' is an edition, not an editor marker: @book as before; Lockyer's 'Mammals in the Seas 3, 379-487' stays @article")
Expect(startsWith(BuildBibEntryNoDOI(Row(container = 'Mammals in the Seas', volume = '3', pages = '379-487'), 'Lockyer:1981aa', 'MN', '2026-10-06'), '@article{'), 'a container with volume and pages and no marker: @article')
corp <- BuildBibEntryNoDOI(Row(author1 = '{Birdcare Avicultural}', year = 2021L, title = 'Birdcare Avicultural data',
                               container = 'Birdcare Avicultural, www.birdcare.com.au (accessed 24/08/2021)'), 'Birdcare-Avicultural:2021aa', 'owner', '2026-10-05')
Expect(startsWith(corp, '@misc{') && grepl('\n\tauthor = {{Birdcare Avicultural}},\n', corp, fixed = TRUE) &&
         Field(corp, 'howpublished') == 'Birdcare Avicultural, www.birdcare.com.au (accessed 24/08/2021)' && Field(corp, 'url') == 'www.birdcare.com.au' && is.na(Field(corp, 'publisher')),
       'a corporate author in braces is written {{...}} (not escaped); a URL in the container makes a database-style @misc with howpublished and url')
Expect(NoDOIAuthorField('{FAO & WHO} and Doe, J.') == '{FAO \\& WHO} and Doe, J.' && NoDOIAuthorField('Ikeda and Hirakawa') == 'Ikeda and Hirakawa' && is.na(NoDOIAuthorField(NA)) &&
         FirstOfAuthorList('{Birdcare Avicultural}') == 'Birdcare Avicultural' && FirstOfAuthorList('{World Parrot Trust} and Doe') == 'World Parrot Trust',
       'NoDOIAuthorField() escapes inside the braces; FirstOfAuthorList() drops them for keys and CiteIDs')
web <- BuildBibEntryNoDOI(c(Row(author1 = '{World Parrot Trust}', year = 2021L, container = 'World Parrot Trust'), notes = 'web page (ADW precedent): https://www.parrots.org/encyclopedia/x. Owner 2026-10-05'),
                          'World-Parrot-Trust:2021aa', 'owner', '2026-10-05')
Expect(startsWith(web, '@misc{') && Field(web, 'url') == 'https://www.parrots.org/encyclopedia/x' && Field(web, 'howpublished') == 'World Parrot Trust',
       "a URL in notes is used when the notes or container say web / database; a trailing period is not part of it")
bk2 <- BuildBibEntryNoDOI(c(Row(container = 'Some Publisher'), notes = 'no Crossref DOI, only a review at https://example.org/review'), 'X:2000aa', 'MN', '2026-10-06')
Expect(startsWith(bk2, '@book{') && is.na(Field(bk2, 'url')), 'a URL in the notes of an ordinary book is not taken (no database / web word)')
pu <- BuildBibEntryNoDOI(c(Row(container = 'Online database'), parsed_url = 'https://animaldiversity.org/accounts/Mus_musculus/'), 'ADW:2020aa', 'MN', '2026-10-06')
Expect(startsWith(pu, '@misc{') && Field(pu, 'url') == 'https://animaldiversity.org/accounts/Mus_musculus/' && Field(pu, 'howpublished') == 'Online database',
       'the optional parsed_url column is the url field (underscores not escaped in a URL)')
pu2 <- BuildBibEntryNoDOI(c(Row(container = 'Mar. Biol.', volume = '3', pages = '4-10'), parsed_url = 'https://example.org/paper'), 'K:1976ad', 'MN', '2026-10-06')
Expect(startsWith(pu2, '@article{') && Field(pu2, 'url') == 'https://example.org/paper', 'parsed_url adds a url field to any type without changing the type')
Expect('parsed_url' %in% primary_reference_columns && 'parsed_url' %in% primary_reference_optional_columns && 'parsed_url' %in% primary_reference_owner_columns &&
         identical(tail(primary_reference_columns, 3), c('owner_review', 'parsed_url', 'verification_mode')) &&
         'verification_mode' %in% primary_reference_optional_columns && !'verification_mode' %in% primary_reference_owner_columns,
       'parsed_url is an optional, owner-editable column at the end of the schema (older files read with it NA); verification_mode an optional tool-written one after it')

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

# ---- the --bib step -------------------------------------------------------------------------------------
cat('AssignPrimaryKeys()\n')
PRow <- function(source_label, native_key, status, doi = NA_character_, bibcite = NA_character_, cite_id = NA_character_, reason = NA_character_,
                 author1 = 'Kremer', year = 1976L, title = 'The ecology of the ctenophore Mnemiopsis leidyi in Narragansett Bay',
                 container = 'Ph.D. thesis, Univ. of Rhode Island', year_override = NA_integer_) {
  r <- EmptyPrimaryReferences()[rep(1L, 0), ]
  r[1, 'native_key'] <- native_key
  r$source_label <- source_label; r$match_status <- status; r$match_reason <- reason; r$doi <- doi; r$bibcite <- bibcite; r$cite_id <- cite_id
  r$parsed_author1 <- author1; r$parsed_year <- year; r$parsed_title <- title; r$parsed_container <- container
  r$decided_by <- 'owner'; r$decided_at <- '2026-10-04'; r$year_override <- year_override; r$n_records <- 1L; r$role <- 'measurement'
  r
}
ap <- rbind(PRow('Kiorboe_2013', '6', 'certain', doi = '10.1007/bf00392514'),
            PRow('Hebert_etal_2016', '12', 'approved', doi = '10.1007/BF00392514', reason = 'owner_candidate'),
            PRow('Kiorboe_2013', '9', 'nodoi_approved', reason = 'owner_nodoi'),
            PRow('Kiorboe_2013', '12', 'approved', bibcite = 'Omori:1969aa', reason = 'manual_bib'),
            PRow('Lislevand_etal_2007', '24', 'approved', doi = '10.9999/this-doi-does-not-exist', reason = 'owner_candidate'),
            PRow('Kiorboe_2013', '1', 'pending', doi = '10.1/pending'))
ids0 <- data.frame(Bibcite = c('Omori:1969aa', 'Kiorboe:2013aa'), CiteID = c('Omori_1969', 'Kiorboe_2013'), doi = c(NA, '10.4319/lo.2013.58.5.1843'), stringsAsFactors = FALSE)
cur_syn <- data.frame(key = c('Omori:1969aa', 'Kiorboe:2013aa'), type = 'article', doi = c(NA, '10.4319/lo.2013.58.5.1843'), stringsAsFactors = FALSE)
res <- AssignPrimaryKeys(ap, cfg, cur_syn, ids0)
K <- function(src, key, col) res$prim[[col]][res$prim$source_label == src & res$prim$native_key == key]
Expect(identical(sort(names(res$entries)), c('Ikeda:1986aa', 'Kremer:1976aa')) && startsWith(res$entries[['Ikeda:1986aa']], '@article{Ikeda:1986aa,') &&
         startsWith(res$entries[['Kremer:1976aa']], '@phdthesis{Kremer:1976aa,'),
       'one entry per key: the Crossref record of the DOI rows, the owner-approved fields of the nodoi row; no entry for the curated manual key')
Expect(K('Kiorboe_2013', '6', 'bibcite') == 'Ikeda:1986aa' && K('Hebert_etal_2016', '12', 'bibcite') == 'Ikeda:1986aa' &&
         K('Kiorboe_2013', '6', 'cite_id') == 'Ikeda_1986' && K('Hebert_etal_2016', '12', 'cite_id') == 'Ikeda_1986',
       'two sources citing one DOI (case apart) share the key and the CiteID')
Expect(K('Kiorboe_2013', '9', 'bibcite') == 'Kremer:1976aa' && K('Kiorboe_2013', '9', 'cite_id') == 'Kremer_1976' &&
         K('Kiorboe_2013', '12', 'cite_id') == 'Omori_1969' && K('Kiorboe_2013', '12', 'bibcite') == 'Omori:1969aa',
       'the nodoi row gets a key and a CiteID; the manual_bib row keeps the curated key and takes its CiteID from the table')
Expect(identical(res$no_record, 'Lislevand_etal_2007 24 (10.9999/this-doi-does-not-exist)') && is.na(K('Lislevand_etal_2007', '24', 'bibcite')) &&
         is.na(K('Lislevand_etal_2007', '24', 'cite_id')) && length(res$authorless) == 0,
       'an accepted DOI without a Crossref record is reported in no_record, not fatal; the row stays without a key (#114 item 3)')
Expect(is.na(K('Kiorboe_2013', '1', 'bibcite')) && nrow(res$prim) == nrow(ap) && identical(names(res$prim), names(ap)), 'a pending row is untouched; the frame keeps its shape')
res2 <- AssignPrimaryKeys(res$prim, cfg, cur_syn, ids0)
Expect(identical(res2$prim, res$prim) && identical(res2$entries, res$entries), 'a second pass over the keyed frame reproduces it (idempotent)')
Expect(Has(ErrorOf(AssignPrimaryKeys(PRow('X', 'm', 'approved', bibcite = 'Nope:2000aa', reason = 'manual_bib'), cfg, cur_syn, ids0)), 'is not in'),
       'a manual bibcite the curated bib lacks stops')
stale <- rbind(ids0, data.frame(Bibcite = 'Ikeda:1986aa', CiteID = 'IkedaJr_1985', doi = '10.1007/bf00392514', stringsAsFactors = FALSE))   # a stale Sheet row for the same Bibcite and DOI
keep <- AssignPrimaryKeys(PRow('Wilman_etal_2014', 'Dunning08', 'approved', doi = '10.1007/bf00392514', bibcite = 'Ikeda:1986aa', cite_id = 'Ikeda_1986', reason = 'owner_candidate'), cfg, cur_syn, stale)
fresh <- AssignPrimaryKeys(PRow('Wilman_etal_2014', 'Dunning08', 'approved', doi = '10.1007/bf00392514', reason = 'owner_candidate'), cfg, cur_syn, stale)
Expect(keep$prim$cite_id == 'Ikeda_1986' && keep$prim$bibcite == 'Ikeda:1986aa' && fresh$prim$cite_id == 'IkedaJr_1985' && fresh$prim$bibcite == 'Ikeda:1986ab',
       'a row that keeps its key keeps its CiteID over a Sheet row for the same Bibcite and DOI; a keyless row takes the table\'s id by DOI (#114 item 7)')
nk <- AssignPrimaryKeys(PRow('Kiorboe_2013', '9', 'nodoi_approved', bibcite = 'Kremer:1976aa', cite_id = 'Kremer_1976x', reason = 'owner_nodoi'), cfg, cur_syn, ids0)
Expect(nk$prim$cite_id == 'Kremer_1976x', 'the same for a nodoi row')
cat('AssignPrimaryKeys(): key minting with the normalised surname and the citation year; existing keys untouched (#114 item 8)\n')
Two <- function(doi) two
mint <- AssignPrimaryKeys(rbind(PRow('SrcA', 'n', 'certain', doi = '10.1/two', author1 = 'Villeger', year = 2013L),
                                PRow('SrcB', 'o', 'certain', doi = '10.1/two', author1 = 'Villeger', year = 2013L, bibcite = 'VillEGER:2012aa', cite_id = 'VillEGER_2012'),
                                PRow('SrcC', 'p', 'certain', doi = '10.1/three', author1 = 'Villeger', year = 2011L)),
                          cfg, cur_syn, ids0, work_for = function(doi) { w <- two; w$DOI <- doi; w })
Kp <- function(src, col) mint$prim[[col]][mint$prim$source_label == src]
Expect(Kp('SrcA', 'bibcite') == 'VillEGER:2012aa' && Kp('SrcA', 'cite_id') == 'VillEGER_2012' && Kp('SrcB', 'bibcite') == 'VillEGER:2012aa' && Kp('SrcB', 'cite_id') == 'VillEGER_2012',
       'a DOI already keyed by another row (its record-spelt key) keeps that key for every row: existing keys are reproduced, not renamed')
Expect(Kp('SrcC', 'bibcite') == 'Villeger:2012aa' && Kp('SrcC', 'cite_id') == 'Villeger_2012' && startsWith(mint$entries[['Villeger:2012aa']], '@misc{Villeger:2012aa,') &&
         grepl('\n\tyear = {2012}', mint$entries[['Villeger:2012aa']], fixed = TRUE),
       "a new key takes the normalised surname; the citation's 2011 is not among the record's years, so the record's 2012 stands")
mint2 <- AssignPrimaryKeys(PRow('SrcD', 'q', 'certain', doi = '10.1/four', author1 = 'Villeger', year = 2013L), cfg, cur_syn, ids0, work_for = function(doi) { w <- two; w$DOI <- doi; w })
Expect(mint2$prim$bibcite == 'Villeger:2013aa' && mint2$prim$cite_id == 'Villeger_2013' && grepl('\n\tyear = {2012}', mint2$entries[[1]], fixed = TRUE),
       "a new key takes the citation's 2013 (the record's print year) over the online-first 2012; the entry's year field stays the record's")
mint3 <- AssignPrimaryKeys(PRow('SrcD', 'q', 'certain', doi = '10.1/four', author1 = 'Villeger', year = 2013L, year_override = 2011L), cfg, cur_syn, ids0, work_for = function(doi) { w <- two; w$DOI <- doi; w })
Expect(mint3$prim$bibcite == 'Villeger:2011aa' && grepl('\n\tyear = {2011}', mint3$entries[[1]], fixed = TRUE) && grepl('Year 2011 by owner decision', mint3$entries[[1]], fixed = TRUE),
       'a year override is applied at mint time and in the entry')
# the override belongs to the work: the row without it (SrcA) sorts first
# and builds the entry, yet the entry and the key take SrcB's `:year=2011`
# (Dunning:2008aa had reverted to the record's 2007 when a Myhrvold_2015 row
# of the same DOI was approved without the override, 2026-10-08)
mint4 <- AssignPrimaryKeys(rbind(PRow('SrcA', 'a', 'certain', doi = '10.1/four', author1 = 'Villeger', year = 2013L),
                                 PRow('SrcB', 'b', 'approved', doi = '10.1/four', author1 = 'Villeger', year = 2013L, year_override = 2011L, reason = 'owner_candidate')),
                           cfg, cur_syn, ids0, work_for = function(doi) { w <- two; w$DOI <- doi; w })
Expect(length(mint4$entries) == 1 && names(mint4$entries) == 'Villeger:2011aa' && all(mint4$prim$bibcite == 'Villeger:2011aa') &&
         grepl('\n\tyear = {2011}', mint4$entries[[1]], fixed = TRUE) && grepl('Year 2011 by owner decision', mint4$entries[[1]], fixed = TRUE),
       'a year override recorded on any accepted row of a DOI applies to the entry and the key, whichever row builds them')
source(file.path(lib, 'citations', 'provenance.r'))
tracked <- LoadPrimaryReferences(cfg$wd_db)
acc_t <- tracked[tracked$match_status %in% c('certain', 'approved', 'nodoi_approved'), ]
pkeys <- ReadBibEntries(cfg$primary_bib)$key
Expect(nrow(acc_t) > 2000 && all(!is.na(acc_t$bibcite)) && all(!is.na(acc_t$cite_id)) && setequal(pkeys, setdiff(unique(acc_t$bibcite), cur$key)),
       sprintf('every one of the %d accepted tracked rows carries a bibcite and a cite_id, and the %d primary bib keys are exactly those bibcites: the keep-existing-key rule covers every existing key', nrow(acc_t), length(pkeys)))
odd <- unique(acc_t$bibcite[grepl('^[A-Za-z-]*[a-z][A-Z]{2,}|^[A-Z]{2,}[:-]|-[A-Z]{2,}:', acc_t$bibcite)])
Expect(all(c('Evans-WHITE:2005aa', 'VillEGER:2012aa') %in% odd), sprintf('the record-spelt keys the owner may rename are still in the tracked files (%s)', paste(odd, collapse = ', ')))

# ---- the file -------------------------------------------------------------------------------------------
cat('WritePrimaryBib(), CheckBibSyntax(), CheckBibKeysUnique()\n')
pb <- tempfile(fileext = '.bib')
WritePrimaryBib(c('Ikeda:1986aa' = e, 'Doe:2010aa' = ch, 'Kremer:1976aa' = nd, 'anon:2000aa' = mi, 'Nsiku:1999aa' = ms, 'Speakman:2003aa' = ch1, 'Birdcare-Avicultural:2021aa' = corp), pb)
lines <- readLines(pb, encoding = 'UTF-8')
Expect(startsWith(lines[1], '%% GENERATED by R/library/citations/build_bib.r') && any(grepl(citations_tool_version, lines, fixed = TRUE)) && lines[7] == '',
       'the header says GENERATED and names the tool version')
rb <- ReadBibEntries(pb)
Expect(identical(rb$key, c('Birdcare-Avicultural:2021aa', 'Doe:2010aa', 'Ikeda:1986aa', 'Kremer:1976aa', 'Nsiku:1999aa', 'Speakman:2003aa', 'anon:2000aa')) &&
         identical(rb$type, c('misc', 'incollection', 'article', 'phdthesis', 'mastersthesis', 'incollection', 'misc')) &&
         identical(rb$doi, c(NA, '10.1/t', '10.1007/bf00392514', NA, NA, NA, NA)),
       'entries are written in byte order of the keys (upper case before lower) and read back')
Expect(Has(ErrorOf(WritePrimaryBib(c('A:1aa' = e, 'A:1aa' = ch), tempfile())), 'duplicated key'), 'duplicated keys stop the write')
empty <- tempfile(fileext = '.bib'); WritePrimaryBib(character(), empty)
Expect(nrow(ReadBibEntries(empty)) == 0 && startsWith(readLines(empty)[1], '%% GENERATED'), 'an empty entry set writes the header only')
n <- CheckBibSyntax(pb)
Expect(is.na(n) || n == 7L, sprintf('RefManageR parses every generated entry, the @mastersthesis and the {{corporate}} author included (%s)', if (is.na(n)) 'RefManageR not installed, skipped' else n))
if (!is.na(n)) {
  bad <- tempfile(fileext = '.bib'); writeLines(c(readLines(pb), '@article{Broken:2000aa,', '\tauthor = {Unclosed'), bad)
  Expect(!is.null(ErrorOf(CheckBibSyntax(bad))) || isTRUE(suppressWarnings(CheckBibSyntax(bad)) < 8), 'a broken entry is not counted as parsed')
}
cb <- tempfile(fileext = '.bib'); writeLines(c('@article{Doe:2010aa,', '\ttitle = {X}}', '@book{Only:2000aa,', '\ttitle = {Y}}'), cb)
Expect(Has(ErrorOf(CheckBibKeysUnique(cb, pb)), 'present in both') && Has(ErrorOf(CheckBibKeysUnique(cb, pb)), 'Doe:2010aa'),
       'a key in both files stops the pipeline')
cb2 <- tempfile(fileext = '.bib'); writeLines(c('@book{Only:2000aa,', '\ttitle = {Y}}', '@book{Only:2000aa,', '\ttitle = {Z}}'), cb2)
Expect(Has(ErrorOf(CheckBibKeysUnique(cb2, pb)), 'duplicated bib key'), 'a key twice in one file stops too')
cb3 <- tempfile(fileext = '.bib'); writeLines(c('@book{Only:2000aa,', '\ttitle = {Y}}'), cb3)
ok <- CheckBibKeysUnique(cb3, pb)
Expect(is.list(ok) && nrow(ok$curated) == 1 && nrow(ok$primary) == 7, 'disjoint files pass and return both entry tables')
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
many <- data.frame(CiteID = c('Flores_2008', paste0('Flores_2008', letters[-1])), Bibcite = NA, doi = NA)
Expect(CiteIDFor('Flores', 2008L, known = many) == 'Flores_2008aa' &&
         CiteIDFor('Flores', 2008L, known = rbind(many, data.frame(CiteID = 'Flores_2008aa', Bibcite = NA, doi = NA))) == 'Flores_2008ab',
       'after z the suffixes continue aa, ab, ... (66 Flores-Villela and Rubio-Perez 2008 entries in Meiri_2018)')
Expect(CiteIDFor('Other', 1999L, bibcite = 'Ikeda:1986aa', known = known) == 'Ikeda_1986' &&
         CiteIDFor('Other', 1999L, doi = 'https://doi.org/10.1016/J.JEMBE.2006.12.010', known = known) == 'Doyle_2007' &&
         CiteIDFor('Other', 1999L, doi = '10.1/new', bibcite = 'New:1999aa', known = known) == 'Other_1999',
       'an existing Bibcite or DOI reuses its CiteID; otherwise a new id is minted')
Expect(CiteIDFor(NA, NA) == 'Anon_nd' && CiteIDFor('van der Meer', 1994L) == 'vanderMeer_1994' && CiteIDFor('Martinez-Palacios', 1992L) == 'Martinez-Palacios_1992' &&
         CiteIDFor('Smith', 2003L, known = known[, c('CiteID', 'Bibcite')]) == 'Smith_2003',
       'missing parts -> Anon / nd; hyphens kept; a known table without a doi column works')
ids <- read.csv(cfg$citeids_csv, stringsAsFactors = FALSE, colClasses = 'character')
Expect(identical(names(ids)[1:2], c('Bibcite', 'CiteID')) && !anyDuplicated(ids$CiteID[!is.na(ids$CiteID) & nzchar(ids$CiteID)]) && CiteIDFor('Kiorboe', 2013L, bibcite = 'Kiorboe:2013aa', known = ids) == 'Kiorboe_2013' &&
         CiteIDFor('Kiorboe', 2013L, known = ids) == 'Kiorboe_2013b',
       'the tracked CiteIDs CSV: Bibcite and CiteID first, unique ids (curated entries awaiting their Sheet row have none), Kiorboe:2013aa reuses Kiorboe_2013, a new Kiorboe 2013 work gets Kiorboe_2013b')

cat(sprintf('\n%d checks, %d failed\n', n_checks, length(failures)))
if (length(failures) > 0) { cat(paste0('  FAIL: ', failures, '\n'), sep = ''); quit(status = 1) }
