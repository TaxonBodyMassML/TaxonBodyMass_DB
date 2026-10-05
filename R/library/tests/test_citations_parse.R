# Tests for the parsing layer of the citation tooling (issue #1):
# R/library/citations/normalise_citation.r and parse_reflists.r. The 18
# references of Kiorboe_2013 (sources/databases/Kiorboe_2013/
# Kiorboe2013_TableA1_references.csv) are the main fixture; other citation
# styles are inline. No network access; stringdist and digest are used.
#
#   Rscript R/library/tests/test_citations_parse.R      (from any directory)
#
# Prints one line per expectation and exits with status 1 if any failed.

this_file <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE))
if (length(this_file) == 0)
  this_file <- file.path('R', 'library', 'tests', 'test_citations_parse.R')
repo <- normalizePath(file.path(dirname(this_file), '..', '..', '..'))
lib  <- file.path(repo, 'R', 'library')
source(file.path(lib, 'helpers.r'))
for (f in c('citations_config.r', 'normalise_citation.r', 'parse_reflists.r'))
  source(file.path(lib, 'citations', f))

failures <- character(0)
n_checks <- 0L
Expect <- function(ok, what) {
  n_checks <<- n_checks + 1L
  if (!isTRUE(ok)) failures <<- c(failures, what)
  cat(sprintf('  %s %s\n', if (isTRUE(ok)) 'ok  ' else 'FAIL', what))
}
ErrorOf <- function(expr) tryCatch({ expr; NULL }, error = function(e) conditionMessage(e))
Has <- function(x, pattern) !is.null(x) && grepl(pattern, x, fixed = TRUE)

# ---- normalisation --------------------------------------------------------------------
cat('NormaliseCitationString(), CleanDOI(), ExtractDOI(), CitationHashKey()\n')
Expect(identical(NormaliseCitationString(c('Kiørboe, T. (2013). Zooplankton body-composition!', NA, '  <i>Salpa</i> {thompsoni} ')),
                 c('kiorboe t 2013 zooplankton body composition', NA, 'salpa thompsoni')),
       'folds to lowercase ASCII words; NA kept; tags and braces dropped')
Expect(identical(CleanDOI(c('https://doi.org/10.4319/LO.2013.58.5.1843', 'doi:10.1159/000113543.', '', NA, 'http://dx.doi.org/10.1007/BF00355587')),
                 c('10.4319/lo.2013.58.5.1843', '10.1159/000113543', NA, NA, '10.1007/bf00355587')),
       'CleanDOI strips the resolver prefix and trailing punctuation, lowercases, empties to NA')
Expect(identical(ExtractDOI(c('Brain 45(2), 96-109. doi:10.1159/000113543', 'no doi here', 'see https://doi.org/10.1016/j.jembe.2006.12.010)')),
                 c('10.1159/000113543', NA, '10.1016/j.jembe.2006.12.010')),
       'ExtractDOI finds an embedded DOI and ignores a closing bracket')
Expect(identical(ExtractDOI(c('Physiology, 56(1), 1-5. doi:10.1016/0300-9629(77)90123-4.', '(see 10.1016/0306-4565(92)90025-B))', NA, 'none')),
                 c('10.1016/0300-9629(77)90123-4', '10.1016/0306-4565(92)90025-b', NA, NA)) && identical(ExtractDOI(c(NA, 'none')), c(NA_character_, NA_character_)),
       'ExtractDOI keeps the parentheses of older DOIs, drops only unbalanced closing brackets, and survives a vector without any DOI')
h <- CitationHashKey(c('Taylor, G. M., Nol, E., & Boire, D. (1995). Brain regions', 'taylor g m nol e boire d 1995 brain regions', NA))
Expect(grepl('^h:[0-9a-f]{8}$', h[1]) && h[1] == h[2] && is.na(h[3]), 'the hash key depends on the normalised string only')

# ---- the reference list ---------------------------------------------------------------
cat('ParseRefListCSV()\n')
kio <- file.path(repo, 'sources', 'databases', 'Kiorboe_2013', 'Kiorboe2013_TableA1_references.csv')
rl <- ParseRefListCSV(kio, key_col = 'Reference', citation_col = 'Citation')
Expect(nrow(rl) == 18 && identical(rl$native_key, as.character(1:18)) && all(is.na(rl$raw_doi)),
       'Kiorboe_2013: 18 numbered references, no DOI column')
Expect(startsWith(rl$raw_citation[6], '———, and B. Bruce. 1986.'), 'raw_citation is verbatim (the same-author dashes are kept)')
e <- ErrorOf(ParseRefListCSV(kio, key_col = 'Nope', citation_col = 'Citation'))
Expect(Has(e, 'lacks column'), 'stops on a missing column')
mcc <- ParseRefListCSV(file.path(repo, 'sources', 'databases', 'McCoy_2008', 'appendixS1_references.csv'),
                       key_col = 'ref', citation_col = 'citation', doi_col = 'doi')
Expect(nrow(mcc) >= 29 && 'raw_doi' %in% names(mcc), 'McCoy_2008: reference list with a DOI column reads')
heb <- ParseRefListCSV(file.path(repo, 'sources', 'databases', 'Hebert_etal_2016', 'references.csv'), key_col = 'Ref.code',
                       citation_cols = c('Authors', 'Year', 'Title', 'Journal.Book'), type_col = 'Pub.type', csv_sep = ';', file_encoding = 'latin1')
Expect(nrow(heb) >= 190 && heb$raw_citation[heb$native_key == '2'] == 'Lynch, M. 1980. The evolution of cladoceran life histories. Quarterly Review of Biology.' &&
         heb$note[heb$native_key == '2'] == 'Article',
       'Hebert_etal_2016: a semicolon-separated list with split fields is pasted into one citation; the type goes to note')
dup <- tempfile(fileext = '.csv'); writeLines(c('k,c', '1,"A. 2000. T. J 1: 1-2."', '1,"B. 2001. U. K 2: 3-4."'), dup)
Expect(Has(ErrorOf(ParseRefListCSV(dup, 'k', 'c')), 'duplicated native key'), 'stops on a duplicated key')

cat('ExpandSameAuthorMarkers()\n')
ex <- ExpandSameAuthorMarkers(rl$raw_citation)
Expect(startsWith(ex[6], 'Ikeda, T., and B. Bruce. 1986.') && startsWith(ex[7], 'Ikeda, T., and K. Hirakawa. 1998.') &&
         startsWith(ex[8], 'Ikeda, T., and H. R. Skjoldal. 1989.') && startsWith(ex[13], 'Omori, M., and T. Ikeda. 1984.'),
       'the dashes take the previous entry\'s first author (Ikeda for 6-8, Omori for 13)')
Expect(identical(ex[-c(6, 7, 8, 13)], rl$raw_citation[-c(6, 7, 8, 13)]), 'entries without a marker are unchanged')
Expect(ExpandSameAuthorMarkers(c('———. 1990. Title. J 1: 1-2.'))[1] == '———. 1990. Title. J 1: 1-2.',
       'a marker in the first entry is left alone')

# ---- the regex parse -------------------------------------------------------------------
cat('ParseCitationString() on the 18 Kiorboe references\n')
p <- ParseCitationString(ex)
Expect(identical(p$parsed_author1, c('Doyle', 'Falk-Petersen', 'Huntley', 'Iguchi', 'Ikeda', 'Ikeda', 'Ikeda', 'Ikeda', 'Kremer',
                                     'Menden-Deuer', 'Meyer', 'Omori', 'Omori', 'Putt', 'Reeve', 'Tande', 'Uye', 'Williams')),
       'first surnames of all 18 entries')
Expect(identical(p$parsed_year, c(2007L, 1981L, 1989L, 2004L, 1974L, 1986L, 1998L, 1989L, 1976L, 2000L, 2002L, 1969L, 1984L,
                                  1989L, 1980L, 1982L, 1982L, 1982L)),
       'years of all 18 entries (the title year 1983-1984 of entry 3 is not taken)')
Expect(identical(p$parsed_volume, c('343', '49', '10', '26', '22', '92', '45', '100', NA, '45', '47', '3', NA, '34', '2', '62', '38', '71')) &&
         identical(p$parsed_pages[c(1, 5, 12, 14)], c('239-252', '1-97', '4-10', '1097-1103')),
       'volumes and pages; none for the thesis (9) and the book (13)')
Expect(p$parsed_title[1] == 'The energy density of jellyfish: Estimates from bomb-calorimetry and proximate-composition' &&
         p$parsed_container[1] == 'J. Exp. Mar. Biol. Ecol',
       'entry 1: title and journal abbreviation')
Expect(p$parsed_title[2] == paste('Ecological investigations on the zooplakton community of Balsfjorden, Northern Norway: Seasonal changes in body weight',
                                  'and the main biochemical composition of Thysanoessa inermis (Kroyer), T. raschii (M. Sars), and Meganyctiphanes norvegica (M. Sars) in relation to environmental factors'),
       'entry 2: initials inside the title (T. raschii, M. Sars) do not split it; diacritics folded')
Expect(p$parsed_title[6] == 'Metabolic activity and elemental composition of krill and other zooplankton from Prydz Bay, Antarctica, during early summer (November-December)' &&
         p$parsed_container[6] == 'Mar. Biol',
       'entry 6: a title ending in a closing bracket splits before the journal')
Expect(p$parsed_title[11] == 'Feeding and energy budgets of Antarctic krill Euphausia superba at the onset of winter-I. Furcilia III larvae',
       'entry 11: the roman numeral I. stays in the title')
Expect(p$parsed_title[9] == 'The ecology of the ctenophore Mnemiopsis leidyi in Narragansett Bay' && p$parsed_container[9] == 'Ph.D. thesis, Univ. of Rhode Island',
       'entry 9: thesis title and institution')
Expect(p$parsed_title[13] == 'Methods in marine zooplankton ecology' && p$parsed_container[13] == 'John Wiley & Sons', 'entry 13: book title and publisher')
Expect(p$parsed_title[16] == paste('Ecological Investigations on the zooplankton community of Balsfjorden, Northern Norway: Generation cycles, and variations in body',
                                   'weight and body content of carbon and nitrogen related to overwintering and reproduction in the copepod Calanus finmarchicus (Gunnerus)') &&
         p$parsed_container[16] == 'J. Exp. Mar. Biol. Ecol', 'entry 16: bracketed authority ends the title')
Expect(all(is.na(p$parsed_doi)), 'no DOI in the Kiorboe list')

cat('ParseCitationString() on other styles\n')
q <- ParseCitationString(c(
  'Taylor, G. M., Nol, E., & Boire, D. (1995). Brain regions and encephalization in anurans: adaptation or stability? Brain, behavior and evolution, 45(2), 96-109. doi:10.1159/000113543',
  'Carey JR, Judge DS (2000) Longevity Records: Life Spans of Mammals, Birds, Amphibians, Reptiles, and Fish. Odense: Odense University Press. 241 p.',
  'van der Meer J, Piersma T (1994) Physiologically inspired regression models for estimating and predicting nutrient stores and their composition in birds. Physiol Zool 67:305-329',
  'ARUDPRAGASAM, K. D., AND E. YLOR (1964). GILL VENTILATION VOLUMES. J. Exp. Biol., 41, 309-321',
  'This study', NA, ''))
Expect(q$parsed_author1[1] == 'Taylor' && q$parsed_year[1] == 1995L && q$parsed_title[1] == 'Brain regions and encephalization in anurans: adaptation or stability?' &&
         q$parsed_container[1] == 'Brain, behavior and evolution' && q$parsed_volume[1] == '45' && q$parsed_pages[1] == '96-109' && q$parsed_doi[1] == '10.1159/000113543',
       'APA style with issue, question mark and a DOI tail')
Expect(q$parsed_author1[2] == 'Carey' && q$parsed_year[2] == 2000L && q$parsed_title[2] == 'Longevity Records: Life Spans of Mammals, Birds, Amphibians, Reptiles, and Fish' &&
         q$parsed_container[2] == 'Odense: Odense University Press' && is.na(q$parsed_volume[2]),
       'author-initials style book with a page count')
Expect(q$parsed_author1[3] == 'van der Meer' && q$parsed_volume[3] == '67' && q$parsed_pages[3] == '305-329' && q$parsed_container[3] == 'Physiol Zool',
       'particles stay with the surname; colon volume:pages')
Expect(q$parsed_author1[4] == 'Arudpragasam' && q$parsed_year[4] == 1964L && q$parsed_volume[4] == '41' && q$parsed_pages[4] == '309-321',
       'ALL CAPS entry: surname title-cased, volume and pages found')
Expect(is.na(q$parsed_year[5]) && q$parsed_title[5] == 'This study' && all(is.na(q$parsed_author1[6:7])), 'no year: title only; NA and empty strings parse to NA')

cat('TitleSimilarity() and the agreement helpers\n')
Expect(TitleSimilarity('The energy density of jellyfish: Estimates from bomb-calorimetry', 'The energy density of jellyfish: estimates from bomb-calorimetry') == 1,
       'case and punctuation do not matter')
s1 <- TitleSimilarity('Weight and chemical composition of some important oceanic zooplankton in the North Pacific',
                      'Weight and chemical composition of some important oceanic zooplankton in the North Pacific Ocean')
s2 <- TitleSimilarity('The ecology of the ctenophore Mnemiopsis leidyi in Narragansett Bay', 'Predation by the Ctenophore Mnemiopsis leidyi in Narragansett Bay, Rhode Island')
s3 <- TitleSimilarity('Weight and chemical composition of some important oceanic zooplankton', 'Gill ventilation volumes, oxygen consumption and respiratory rhythms in Carcinus')
Expect(s1 > 0.93 && s2 > 0.6 && s2 < 0.7 && s3 < 0.4, sprintf('one extra word %.3f (certain range), a related title %.3f (below 0.70), unrelated %.3f', s1, s2, s3))
Expect(identical(TitleSimilarity('A title', c('A title', NA, '')), c(1, 0, 0)) && TitleSimilarity(NA, 'x') == 0, 'vectorised over candidates; missing titles score 0')
Expect(AuthorMatch('Falk-Petersen', 'Falk‐Petersen') && AuthorMatch('Kiorboe', 'Kiørboe') && AuthorMatch('Meer', 'van der Meer') &&
         !AuthorMatch('Ikeda', 'Omori') && !AuthorMatch('Li', 'Lin') && !AuthorMatch(NA, 'Omori'),
       'AuthorMatch folds dashes and diacritics, allows a contained surname of four letters or more')
Expect(ContainerMatch('J. Exp. Mar. Biol. Ecol.', 'Journal of Experimental Marine Biology and Ecology') && ContainerMatch('Limnol. Oceanogr.', 'Limnology and Oceanography') &&
         ContainerMatch('J. Oceanogr. Soc. Japan', 'Journal of the Oceanographical Society of Japan') && !ContainerMatch('Polar Biol.', 'Marine Biology') &&
         !ContainerMatch(NA, 'Marine Biology') && !ContainerMatch('Mar. Biol.', ''),
       'ContainerMatch is abbreviation-aware and false for missing names')
Expect(VolumeMatch('343', '343') && !VolumeMatch('343', '34') && !VolumeMatch(NA, '1') && PagesMatch('239-252', '239') && PagesMatch('239-252', '239-252') &&
         !PagesMatch('239-252', '240-252') && !PagesMatch(NA, '1'),
       'VolumeMatch and PagesMatch (first page)')

# ---- keys and in-row citations ---------------------------------------------------------
cat('SplitRefKeys(), ExplodeRefKeys(), ParseInRowCitations(), DetectSelf()\n')
Expect(identical(SplitRefKeys(c('1, 2', '9;10; 11', NA, '', ' 7 ', 'NA', '3; 3'), sep = '[;,]'), c('1; 2', '9; 10; 11', NA, NA, '7', NA, '3')),
       'keys split at the per-source separator, trimmed, de-duplicated, empty to NA')
ex2 <- ExplodeRefKeys(c('1; 2', '3', NA, '4'))
Expect(identical(ex2$record, c(1L, 1L, 2L, 4L)) && identical(ex2$native_key, c('1', '2', '3', '4')),
       'ExplodeRefKeys gives one row per record x key; an NA record contributes no row')
Expect(JoinRefKeys(c('1; 2', '3', NA, '2;1')) == '1; 2; 3' && is.na(JoinRefKeys(c(NA, NA))) && is.na(JoinRefKeys(character())) && JoinRefKeys('7') == '7',
       'JoinRefKeys joins the distinct keys of several records (Pass 1); NA when none')
inrow <- ParseInRowCitations(c('Taylor, G. M. (1995). Brain. J 1: 1-2. doi:10.1159/000113543', 'taylor g m 1995 brain j 1 1 2 doi 10 1159 000113543', 'Other, A. (2000). X. Y 2: 3-4.', NA))
Expect(nrow(inrow$references) == 2 && inrow$references$n_records[inrow$references$raw_citation == 'Other, A. (2000). X. Y 2: 3-4.'] == 1 &&
         sum(inrow$references$n_records) == 3 && inrow$references$raw_doi[grepl('Taylor', inrow$references$raw_citation)] == '10.1159/000113543' &&
         length(inrow$keys) == 4 && is.na(inrow$keys[4]) && inrow$keys[1] == inrow$keys[2],
       'in-row citations: distinct normalised strings become hashed keys with record counts and embedded DOIs')
inrow2 <- ParseInRowCitations(c('Taylor, G. M. (1995). Brain. J 1: 1-2.', 'Taylor, G. M. (1995). Brain. J 1: 1-2.', 'Other, A. (2000). X. Y 2: 3-4.', NA),
                              labels = c('Taylor, 1995', 'Taylor 1995', NA, NA))
Expect('note' %in% names(inrow2$references) && inrow2$references$note[grepl('Taylor', inrow2$references$raw_citation)] == 'in-text: Taylor, 1995' &&
         is.na(inrow2$references$note[grepl('Other', inrow2$references$raw_citation)]) && !'note' %in% names(inrow$references),
       'the optional in-text labels become the note of the first record\'s form; no note column without labels')
Expect(identical(DetectSelf(c('This study', 'Ikeda (unpublished data)', 'Vinagre unpublished', 'Doyle et al. 2007', 'present study, own data'), 'Ikeda'),
                 c(TRUE, TRUE, FALSE, FALSE, TRUE)),
       'self: this study / own data / the compiler\'s unpublished data, not another author\'s unpublished data')

# ---- the skeleton ------------------------------------------------------------------------
cat('InitPrimaryReferences(), MergePrimaryReferences(), Read/WritePrimaryReferences()\n')
keys <- c('1', '1; 6', '6', NA, '12', '99', '12; 1')
prim <- InitPrimaryReferences('Kiorboe_2013', rl, keys, compiler = 'Kiorboe')
Expect(identical(names(prim), primary_reference_columns), 'the skeleton has the 32 columns of the schema')
Expect(identical(prim$native_key, c('1', '6', '12', '99')) && identical(prim$n_records, c(3L, 2L, 2L, 1L)),
       'one row per key cited, in reference-list order then the unmatched keys; n_records counts records')
Expect(is.na(prim$raw_citation[4]) && prim$notes[4] == 'key not in reference list' && prim$match_reason[4] == 'key_not_in_reflist',
       'a key the list lacks keeps an empty raw_citation and a note')
Expect(prim$parsed_author1[2] == 'Ikeda' && prim$parsed_year[2] == 1986L, 'the same-author expansion is applied in list order (entry 6 -> Ikeda)')
Expect(all(prim$role == 'measurement') && all(is.na(prim$match_status)) && all(prim$tool_version == citations_tool_version),
       'roles default to measurement, nothing verified yet, tool_version stamped')
self_list <- rbind(rl[1, ], data.frame(native_key = 'S', raw_citation = 'This study', raw_doi = NA, note = NA, stringsAsFactors = FALSE))
ps <- InitPrimaryReferences('X', self_list, c('1', 'S', 'S'))
Expect(ps$role[ps$native_key == 'S'] == 'self' && ps$match_status[ps$native_key == 'S'] == 'self' && ps$n_records[ps$native_key == 'S'] == 2L,
       'a self reference gets role and status self')
Expect(nrow(InitPrimaryReferences('X', rl, c(NA, NA))) == 0, 'no keys: an empty skeleton')
# the owner's edits survive a re-init; counts and new keys update
owner <- prim
owner$role[1] <- 'compilation'; owner$parsed_title[1] <- 'corrected'; owner$notes[1] <- 'owner note'
owner$match_status[2] <- 'certain'; owner$doi[2] <- '10.1007/bf00392514'
skel2 <- InitPrimaryReferences('Kiorboe_2013', rl, c('1', '6', '6', '6', '2'), compiler = 'Kiorboe')
m <- MergePrimaryReferences(owner, skel2)
Expect(m$role[m$native_key == '1'] == 'compilation' && m$parsed_title[m$native_key == '1'] == 'corrected' && m$notes[m$native_key == '1'] == 'owner note' &&
         m$match_status[m$native_key == '6'] == 'certain' && m$doi[m$native_key == '6'] == '10.1007/bf00392514',
       'owner edits and verification columns survive')
Expect(identical(m$n_records[match(c('1', '6', '12', '99', '2'), m$native_key)], c(1L, 3L, 0L, 0L, 1L)) && nrow(m) == 5,
       'n_records updated, keys no record cites fall to 0, the new key 2 appended')
changed <- skel2; changed$raw_citation[1] <- 'a different text'
w <- tryCatch({ MergePrimaryReferences(owner, changed); NULL }, warning = function(w) conditionMessage(w))
Expect(Has(w, 'raw_citation differs') && Has(w, 'immutable'), 'a changed reference-list text is reported, not applied')
f <- tempfile(fileext = '.csv')
WritePrimaryReferences(m, f); back <- ReadPrimaryReferences(f)
Expect(identical(back$native_key, m$native_key) && identical(back$n_records, m$n_records) && identical(back$parsed_year, m$parsed_year) &&
         is.logical(back$author_match) && identical(back$raw_citation, m$raw_citation),
       'the CSV round-trips with its column types')
Expect(is.null(ReadPrimaryReferences(tempfile())), 'a missing file reads as NULL')

# ---- stubs -------------------------------------------------------------------------------
cat('format stubs\n')
Expect(Has(ErrorOf(ParseRefListPDF('x.pdf')), 'not implemented yet') && Has(ErrorOf(ParseRefListXLSX('x.xlsx')), 'not implemented yet'),
       'the later-tier parsers stop with a clear message')
Expect(Has(ErrorOf(ReflistSpec('NoSuchSource')), 'No reference-list specification') && ReflistSpec('Kiorboe_2013')$format == 'csv',
       'ReflistSpec() names the missing specification')

cat(sprintf('\n%d checks, %d failed\n', n_checks, length(failures)))
if (length(failures) > 0) { cat(paste0('  FAIL: ', failures, '\n'), sep = ''); quit(status = 1) }
