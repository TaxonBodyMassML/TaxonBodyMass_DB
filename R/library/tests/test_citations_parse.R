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
Expect(identical(ExtractDOI('Journal of Mammalogy, 81(2), 578-585. doi:10.1644/1545-1542(2000)081<0578:TBAMOT>2.0.CO;2'), '10.1644/1545-1542(2000)081<0578:tbamot>2.0.co;2'),
       'ExtractDOI keeps the angle brackets and the trailing ;2 of a SICI DOI')
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

cat('ParseCitationString() on the Nature / Scientific Data style (year in brackets at the end)\n')
r <- ParseCitationString(c(
  "O'Shea, M. The Book of Snakes: A life-size guide to six hundred species from around the world. University of Chicago Press, (2018).",
  'Iverson, J. B., Christine P. B., Kathy K. B. and Lyddan, K. K.  Latitudinal Variation in Egg and Clutch Size in Turtles (Supplement). Canadian Journal of Zoology 71 (12), 2448-61, (1993).',
  'Shine, R., Branch, W. R., Harlow, P. S., Webb, J. K., Shine, T. Biology of burrowing Asps (Atractaspididae) from Southern Africa. Copeia 2006, 103-115, (2006a).',
  'De Magalhaes, J. P., and Costa, J. A Database of Vertebrate Longevity Records and Their Relation to Other Life-History Traits. Journal of Evolutionary Biology 22 (8), 1770-74, (2009).',
  'Meiri, S. et al. Different solutions lead to similar life history traits across the great divides of the amniote tree of life. J of Biol Res-Thessaloniki 28, 3, (2021).'))
Expect(r$parsed_author1[1] == "O'Shea" && r$parsed_year[1] == 2018L &&
         r$parsed_title[1] == 'The Book of Snakes: A life-size guide to six hundred species from around the world' &&
         r$parsed_container[1] == 'University of Chicago Press' && is.na(r$parsed_volume[1]),
       'a book: the author block ends at the first title word, the year is the bracketed tail')
Expect(r$parsed_author1[2] == 'Iverson' && r$parsed_year[2] == 1993L &&
         r$parsed_title[2] == 'Latitudinal Variation in Egg and Clutch Size in Turtles (Supplement)' &&
         r$parsed_container[2] == 'Canadian Journal of Zoology' && r$parsed_volume[2] == '71' && r$parsed_pages[2] == '2448-61',
       'given names written out in the author block do not start the title; volume and pages')
Expect(r$parsed_author1[3] == 'Shine' && r$parsed_year[3] == 2006L && r$parsed_volume[3] == '2006' && r$parsed_pages[3] == '103-115' &&
         r$parsed_title[3] == 'Biology of burrowing Asps (Atractaspididae) from Southern Africa',
       'a year-numbered volume before the bracketed year with a letter suffix')
Expect(r$parsed_author1[4] == 'De Magalhaes' && r$parsed_year[4] == 2009L && r$parsed_volume[4] == '22' &&
         r$parsed_title[4] == 'A Database of Vertebrate Longevity Records and Their Relation to Other Life-History Traits',
       'a page number that looks like a year (1770) is not the year; a one-letter title start')
Expect(r$parsed_author1[5] == 'Meiri' && r$parsed_year[5] == 2021L &&
         r$parsed_title[5] == 'Different solutions lead to similar life history traits across the great divides of the amniote tree of life',
       "'et al.' ends the author block")

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

cat('ParseCitationString() on the Nature style (Chown_etal_2007 reference list)\n')
nat <- ParseCitationString(c(
  'Loveridge, J. P. & Bursell, E. Studies on the water relations of adult locusts (Orthoptera, Acrididae) I. Respiration and the production of metabolic water. Bulletin of Entomological Research 65, 13-20 (1975).',
  'Hebling, M. J. A., Penteado, C. H. S. & Mendes, E. G. Respiratory regulation in workers of the leaf cutting ant Atta sexdens rubropilosa (Forel, 1908). Comparative Biochemistry and Physiology A 101, 319-322 (1992).',
  'Gäde, G. & Auerswald, L. Flight metabolism in carpenter bees and primary structure of their hypertrehalosaemic peptide. Experimental Biology Online 3 (1998).',
  'Klok, C. J. & Chown, S. L. Temperature- and body mass-related variation in cyclic gas exchange characteristics and metabolic rates of seven weevil species: broader implications. Journal of Insect Physiology (in press).'))
Expect(nat$parsed_author1[1] == 'Loveridge' && nat$parsed_year[1] == 1975L && nat$parsed_container[1] == 'Bulletin of Entomological Research' &&
         nat$parsed_volume[1] == '65' && nat$parsed_pages[1] == '13-20' &&
         nat$parsed_title[1] == 'Studies on the water relations of adult locusts (Orthoptera, Acrididae) I. Respiration and the production of metabolic water',
       'Nature style: year at the end, "&" author block, "I." kept inside the title')
Expect(nat$parsed_author1[2] == 'Hebling' && nat$parsed_year[2] == 1992L && nat$parsed_volume[2] == '101' &&
         nat$parsed_title[2] == 'Respiratory regulation in workers of the leaf cutting ant Atta sexdens rubropilosa (Forel, 1908)',
       'Nature style: a year inside the title does not end the author block')
Expect(nat$parsed_author1[3] == 'Gade' && nat$parsed_year[3] == 1998L && nat$parsed_container[3] == 'Experimental Biology Online' &&
         nat$parsed_volume[3] == '3' && is.na(nat$parsed_pages[3]), 'Nature style without pages')
Expect(nat$parsed_author1[4] == 'Klok' && is.na(nat$parsed_year[4]) && nat$parsed_container[4] == 'Journal of Insect Physiology (in press)' &&
         nat$parsed_title[4] == 'Temperature- and body mass-related variation in cyclic gas exchange characteristics and metabolic rates of seven weevil species: broader implications',
       'undated Nature-style entry: author block stripped from the title')

cat('ParseCitationString() on the comma style (Hudson_2013 Appendix S6)\n')
cs <- ParseCitationString(c(
  'Acquarone, M., Born, E.W. & Speakman, J.R. (2006) Field Metabolic Rates of Walrus (Odobenus rosmarus) Measured by the Doubly Labeled Water Method, Aquatic Mammals, 32, 363\u2013369.',
  'Bell, G.P., Bartholomew, G.A. & Nagy, K.A. (1986) The roles of energetics, water economy, foraging behavior, and geothermal refugia in the distribution of the bat, Macrotus californicus, Journal of Comparative Physiology B: Biochemical, Systemic, and Environmental Physiology, 156, 441\u2013450.',
  'Riek, A., van der Sluijs, L. & Gerken, M. (2007) Measuring the energy expenditure and water flux in free-ranging alpacas (Lama pacos) in the Peruvian Andes using the doubly labelled water technique, Journal of Experimental Zoology, 307A, 667\u2013675.',
  'Simmen, B., Bayart, F., Rasamimanana, H., Zahariev, A., Blanc, S. & Pasquet, P. (2010) Total energy expenditure and body composition in two free-living sympatric lemurs, PLoS One, 5, e9860.',
  'Fleming, T.H. (1988) Energetics, in T.H. Fleming, ed., The short-tailed fruit bat: a study in plant-animal interactions, chapter 8, The University of Chicago Press, Chicago, pp. 217\u2013238.',
  'Nagy, K.A., Gavrilov, V.M., Kerimov, A.B. & Ivankina, E. (1999) Relationships between field metabolic rate and territoriality in passerines, in Acta XXII Congressus Internationalis Ornithologici, Durban, South Africa, pp. 390\u2013400.',
  'von Helversen, O. & Reyer, H.U. (1984) Nectar intake and energy expenditure in a flower visiting bat, Oecologia, 63, 178\u2013184.',
  'Nagy, K. A. (1987). Field metabolic rate and food requirement scaling in mammals and birds. Ecological Monographs, 57, 111-128.'))
Expect(cs$parsed_author1[1] == 'Acquarone' && cs$parsed_year[1] == 2006L && cs$parsed_container[1] == 'Aquatic Mammals' &&
         cs$parsed_volume[1] == '32' && cs$parsed_pages[1] == '363-369' &&
         cs$parsed_title[1] == 'Field Metabolic Rates of Walrus (Odobenus rosmarus) Measured by the Doubly Labeled Water Method',
       'comma style: title ends at the comma before the journal')
Expect(cs$parsed_container[2] == 'Journal of Comparative Physiology B: Biochemical, Systemic, and Environmental Physiology' &&
         cs$parsed_title[2] == 'The roles of energetics, water economy, foraging behavior, and geothermal refugia in the distribution of the bat, Macrotus californicus' &&
         cs$parsed_volume[2] == '156', 'comma style: a journal name of comma_containers keeps its commas')
Expect(cs$parsed_volume[3] == '307A' && cs$parsed_pages[3] == '667-675' && cs$parsed_container[3] == 'Journal of Experimental Zoology' &&
         cs$parsed_volume[4] == '5' && cs$parsed_pages[4] == 'e9860' && cs$parsed_container[4] == 'PLoS One',
       'comma style: a lettered volume and an article number')
Expect(cs$parsed_title[5] == 'Energetics' && cs$parsed_container[5] == 'The short-tailed fruit bat: a study in plant-animal interactions' &&
         is.na(cs$parsed_volume[5]) && cs$parsed_pages[5] == '217-238' && cs$parsed_year[5] == 1988L,
       'comma style: a chapter gives the book as container, no volume')
Expect(cs$parsed_title[6] == 'Relationships between field metabolic rate and territoriality in passerines' &&
         cs$parsed_container[6] == 'Acta XXII Congressus Internationalis Ornithologici' && cs$parsed_pages[6] == '390-400',
       'comma style: proceedings give the volume name as container')
Expect(cs$parsed_author1[7] == 'von Helversen' && cs$parsed_container[7] == 'Oecologia', 'comma style: a particle surname')
Expect(cs$parsed_title[8] == 'Field metabolic rate and food requirement scaling in mammals and birds' && cs$parsed_container[8] == 'Ecological Monographs',
       'an entry with a period after the title is left to the generic path')
Expect(is.null(ParseCommaStyle('Nagy, K. A. (1987). Field metabolic rate and food requirement scaling in mammals and birds. Ecological Monographs, 57, 111-128.')),
       'ParseCommaStyle() returns NULL on a sentence boundary in the body')

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
cat('ParseAuthorYearKey(), ReflistFromCrossrefReferences()\n')
ak <- ParseAuthorYearKey(c('Ikeda et al. (2007)', 'Ikeda and Mitchell (1982)', 'Kaeriyama & Ikeda (2004)', 'Ikeda (2013a)',
                           'Ikeda (unpublished data)', 'Köster et al. (2010)', 'garbage', NA))
Expect(identical(ak$author1, c('Ikeda', 'Ikeda', 'Kaeriyama', 'Ikeda', 'Ikeda', 'Köster', NA, NA)) &&
         identical(ak$author2, c(NA, 'Mitchell', 'Ikeda', NA, NA, NA, NA, NA)) &&
         identical(ak$et_al, c(TRUE, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE)) &&
         identical(ak$n_authors, c(3L, 2L, 2L, 1L, 1L, 3L, NA, NA)) &&
         identical(ak$year, c(2007L, 1982L, 2004L, 2013L, NA, 2010L, NA, NA)) &&
         identical(ak$suffix, c(NA, NA, NA, 'a', NA, NA, NA, NA)) &&
         identical(ak$unpublished, c(FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE)),
       'the ESM key forms: et al., two surnames (and / &), a letter suffix, unpublished data, diacritics; junk and NA give NA')
dep <- data.frame(key = paste0('CR', 1:9),
                  doi = c('10.1/a', '10.1/b', '10.1/c', '10.1/d', NA, '10.1/f', '10.1/g', '10.1/h', '10.1/i'),
                  author = c('T Ikeda', 'T Ikeda', 'T Ikeda', 'T Ikeda', 'T Ikeda', 'U Båmstedt', 'T Ikeda', 'T Ikeda', 'X Doe'),
                  year = c('2013', '2013', '2012', '2012', '1974', '1979', '2012', '2007', '2000'),
                  unstructured = c('Ikeda T (2013a) Euphausiids. Mar Biol 160:251–262',
                                   'Ikeda T (2013b) Amphipods. J Oceanogr 69:339–355',
                                   'Ikeda T, Takahashi T (2012) Chaetognaths. J Exp Mar Biol Ecol 424–425:78–88',
                                   'Ikeda T, McKinnon AD (2012) Hyperbenthos. Plankton Benthos Res 7:8–19',
                                   'Ikeda T (1974) Nutritional ecology of marine zooplankton. Mem Fac Fish Hokkaido Univ 22:1–97',
                                   'Båmstedt U (1979) Seasonal variation. In: Naylor E, Hartnoll RG (eds) Cyclic phenomena. Pergamon Press, Oxford, pp 267–274',
                                   'Ikeda T (2012) Deep zooplankton. J Oceanogr 68:641–649',
                                   'Ikeda T, Sano F, Yamaguchi A (2007) Copepods. Mar Ecol Prog Ser 339:215–219',
                                   NA),
                  journal_title = c(rep(NA, 8), 'Some J'), article_title = c(rep(NA, 8), 'A title'),
                  volume = c(rep(NA, 8), '5'), first_page = c(rep(NA, 8), '10'), stringsAsFactors = FALSE)
rc <- ReflistFromCrossrefReferences(dep, c('Ikeda (2013a)', 'Ikeda (2013b)', 'Ikeda and Takahashi (2012)', 'Ikeda and McKinnon (2012)',
                                           'Ikeda (2012)', 'Ikeda et al. (2007)', 'Ikeda (1974)', 'Bamstedt (1979)', 'Doe (2000)',
                                           'Ikeda (unpublished data)', 'Ikeda (2013)', 'Nobody (1999)', 'Ikeda and Sano (2007)'))
un <- attr(rc, 'unresolved')
Expect(nrow(rc) == 10 && identical(rc$raw_doi[match(c('Ikeda (2013a)', 'Ikeda (2013b)', 'Ikeda and Takahashi (2012)', 'Ikeda and McKinnon (2012)', 'Ikeda (2012)', 'Ikeda et al. (2007)'), rc$native_key)],
                                   c('10.1/a', '10.1/b', '10.1/c', '10.1/d', '10.1/g', '10.1/h')),
       'suffix, the second surname and the author form (one / two / et al.) pick one deposited reference each among same-author same-year entries')
Expect(rc$raw_citation[rc$native_key == 'Ikeda (2013a)'] == dep$unstructured[1] && rc$note[rc$native_key == 'Ikeda (2013a)'] == 'deposited reference CR1',
       'the deposited unstructured text is the citation and the Crossref reference key the note')
Expect(is.na(rc$raw_doi[rc$native_key == 'Ikeda (1974)']) && rc$raw_citation[rc$native_key == 'Ikeda (1974)'] == dep$unstructured[5],
       'a deposited reference without DOI joins with raw_doi NA')
Expect(rc$raw_doi[rc$native_key == 'Bamstedt (1979)'] == '10.1/f' && Has(rc$owner_review[rc$native_key == 'Bamstedt (1979)'], 'book chapter'),
       'diacritics are folded (Bamstedt / Båmstedt) and a deposited book chapter is flagged for the owner\'s review')
Expect(rc$raw_citation[rc$native_key == 'Doe (2000)'] == 'X Doe (2000) A title. Some J 5:10' && Has(rc$note[rc$native_key == 'Doe (2000)'], 'assembled'),
       'without unstructured text the citation is assembled from the structured fields')
Expect(rc$raw_citation[rc$native_key == 'Ikeda (unpublished data)'] == 'Ikeda (unpublished data)' && is.na(rc$raw_doi[rc$native_key == 'Ikeda (unpublished data)']) &&
         Has(rc$note[rc$native_key == 'Ikeda (unpublished data)'], 'unpublished'),
       'the compiler\'s unpublished data keeps the key as its citation (DetectSelf() marks it self)')
Expect(nrow(un) == 3 && identical(un$key, c('Ikeda (2013)', 'Nobody (1999)', 'Ikeda and Sano (2007)')) &&
         Has(un$reason[1], 'CR1, CR2') && Has(un$reason[2], 'no deposited reference') && Has(un$reason[3], 'no deposited reference'),
       'a key without suffix against two suffixed entries is ambiguous, an unknown author and a wrong author form are unmatched')
ps <- InitPrimaryReferences('Ikeda_2014', rc, c('Ikeda (2013a)', 'Ikeda (unpublished data)', 'Ikeda (unpublished data)', 'Nobody (1999)'), compiler = 'Ikeda')
Expect(nrow(ps) == 3 && ps$role[ps$native_key == 'Ikeda (unpublished data)'] == 'self' && ps$n_records[ps$native_key == 'Ikeda (unpublished data)'] == 2L &&
         ps$raw_doi[ps$native_key == 'Ikeda (2013a)'] == '10.1/a' && ps$parsed_title[ps$native_key == 'Ikeda (2013a)'] == 'Euphausiids' &&
         ps$match_reason[ps$native_key == 'Nobody (1999)'] == 'key_not_in_reflist',
       'the skeleton from the joined list: self for the unpublished key, raw_doi and parsed_* from the deposited text, an unresolved key reported')

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
self_list <- rbind(rl[1, ], data.frame(native_key = 'S', raw_citation = 'This study', raw_doi = NA, note = NA, owner_review = NA, stringsAsFactors = FALSE))
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

cat('owner_review: review_col, the skeleton, optional on read\n')
rl <- tempfile(fileext = '.csv')
writeLines(c('key,citation,doi,owner_review', 'A,"Doe, J. 2001. A study. J Things 5: 1-10.",,alias: cited under another paper', 'B,"Roe, R. 1999. Another study. J Things 3: 1-2.",,'), rl)
r <- ParseRefListCSV(rl, key_col = 'key', citation_col = 'citation', doi_col = 'doi', review_col = 'owner_review')
Expect(identical(r$owner_review, c('alias: cited under another paper', NA_character_)), 'ParseRefListCSV() reads review_col, empty cells as NA')
sk <- InitPrimaryReferences('Src', r, c('A', 'B', 'A'))
Expect('owner_review' %in% names(sk) && sk$owner_review[sk$native_key == 'A'] == 'alias: cited under another paper' && is.na(sk$owner_review[sk$native_key == 'B']),
       'the skeleton carries owner_review from the list')
old_file <- tempfile(fileext = '.csv')
write.csv(sk[, setdiff(primary_reference_columns, 'owner_review')], old_file, row.names = FALSE, na = '')
rd <- ReadPrimaryReferences(old_file)
Expect(identical(names(rd), primary_reference_columns) && all(is.na(rd$owner_review)), 'a file written before owner_review reads with the column filled NA')
sk2 <- sk; sk2$owner_review[sk2$native_key == 'B'] <- 'new flag'; rd$owner_review <- NA_character_
mg <- MergePrimaryReferences(rd, sk2)
Expect(mg$owner_review[mg$native_key == 'B'] == 'new flag' && mg$owner_review[mg$native_key == 'A'] == 'alias: cited under another paper', 'the review flag follows the reference list on re-init')

cat(sprintf('\n%d checks, %d failed\n', n_checks, length(failures)))
if (length(failures) > 0) { cat(paste0('  FAIL: ', failures, '\n'), sep = ''); quit(status = 1) }
