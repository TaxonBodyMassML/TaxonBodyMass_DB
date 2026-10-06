# Tests for the reference keys of the two retriever compilations kept by
# R/library/data_retrieve.r (issue #1, Stage 2): AmnioteValueSources() in
# R/library/foodweb_units.r (the value-providing names of an Amniote per-cell
# reference string, mapped to the keys of sources/databases/Myhrvold_2015/
# references.csv) and the PanTHERIA `References` rule (';'-separated numbers,
# a glued eight-digit token split in two). Also checks the tracked reference
# lists: every Amniote name has a unique key and the PanTHERIA list is numbered
# 1..n without a gap. No network access, base R only.
#
#   Rscript R/library/tests/test_retriever_ref_keys.R      (from any directory)
#
# Prints one line per expectation and exits with status 1 if any failed.

this_file <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE))
if (length(this_file) == 0)
  this_file <- file.path('R', 'library', 'tests', 'test_retriever_ref_keys.R')
repo <- normalizePath(file.path(dirname(this_file), '..', '..', '..'))
lib  <- file.path(repo, 'R', 'library')
source(file.path(lib, 'helpers.r'))
source(file.path(lib, 'fix_formatting.r'))            # Latin1ToUtf8() for foodweb_units.r
source(file.path(lib, 'foodweb_units.r'))
source(file.path(lib, 'citations', 'citations_config.r'))
source(file.path(lib, 'citations', 'parse_reflists.r'))

failures <- character(0)
n_checks <- 0L
Expect <- function(ok, what) {
  n_checks <<- n_checks + 1L
  if (!isTRUE(ok)) failures <<- c(failures, what)
  cat(sprintf('  %s %s\n', if (isTRUE(ok)) 'ok  ' else 'FAIL', what))
}
ErrorOf <- function(expr) tryCatch({ expr; NULL }, error = function(e) conditionMessage(e))

# ---- AmnioteValueSources() ------------------------------------------------------------
cat('AmnioteValueSources()\n')
refs <- data.frame(key = c('Dunning_1992', 'Bennett_1986', 'Szekely_2007', 'Boback_2003', 'Iverson_1993', 'Tacutu_2013'),
                   reference_name = c('Dunning, 1992', 'Bennett, 1986', 'Szekely, Lislevand, and Figuerola, 2007',
                                      'Boback and Guyer, 2003', 'Iverson, J., Balgooyen, C., Byrd, K. et al., 1993',
                                      'Tacutu, R., T. Craig, A. Budovsky et al. 2013'),
                   stringsAsFactors = FALSE)
cells <- c('Dunning, 1992',
           'Dunning, 1992 from median of 4(Dunning, 1992, Dunning, 1992, Dunning, 1992, Bennett, 1986)',
           'mean of Dunning, 1992 & Bennett, 1986 from median of 4(Dunning, 1992, Dunning, 1992, Bennett, 1986, Bennett, 1986)',
           'mean of Szekely, Lislevand, and Figuerola, 2007 and Dunning, 1992',
           'Boback and Guyer, 2003',
           'BC Birds - Dunning, 1992 from median of 3(BC Birds - Dunning, 1992, Bennett, 1986, Dunning, 1992)',
           'mean of  & Iverson, J., Balgooyen, C., Byrd, K. et al., 1993 from median of 4(, BC Reptiles - Tacutu, R., T. Craig, A. Budovsky et al. 2013, Iverson, J., Balgooyen, C., Byrd, K. et al., 1993, Iverson, J., Balgooyen, C., Byrd, K. et al., 1993)',
           'mean of Dunning, 1992 and Dunning, 1992',
           '-999', '', NA)
got <- AmnioteValueSources(cells, refs)
Expect(identical(got[1], 'Dunning_1992'), 'a plain name gives its key')
Expect(identical(got[2], 'Dunning_1992'), 'the name before "from median of" is the key; the bracketed names are not')
Expect(identical(got[3], 'Dunning_1992; Bennett_1986'), 'a "mean of A & B" cell gives both keys, "; "-joined')
Expect(identical(got[4], 'Szekely_2007; Dunning_1992'), 'a name containing ", " and " and " is split as one name; "and" joins the two')
Expect(identical(got[5], 'Boback_2003'), 'a name holding " and " is one key')
Expect(identical(got[6], 'Dunning_1992'), 'the "BC Birds - " batch prefix is dropped')
Expect(identical(got[7], 'Iverson_1993'), 'an empty first name of a "mean of" cell is ignored')
Expect(identical(got[8], 'Dunning_1992'), 'the same name twice gives the key once')
Expect(all(is.na(got[9:11])), '-999, empty and NA cells give NA')
Expect(grepl('cannot split', ErrorOf(AmnioteValueSources('Unknown, 1999', refs))),
       'a name missing from the references table stops')
Expect(grepl('lacks column', ErrorOf(AmnioteValueSources('Dunning, 1992', refs[, 'key', drop = FALSE]))),
       'a references table without reference_name stops')

# ---- the PanTHERIA rule of data_retrieve.r --------------------------------------------
cat('PanTHERIA reference numbers\n')
PanKeys <- function(x) {                    # the rule of data_retrieve.r
  x <- trimws(as.character(x))
  x[x %in% c('', '-999')] <- NA_character_
  x <- gsub('(?<=^|;)([0-9]{4})([0-9]{4})(?=;|$)', '\\1;\\2', x, perl = TRUE)
  SplitRefKeys(x, ';')
}
Expect(identical(PanKeys('511;543;2655'), '511; 543; 2655'), 'the numbers are split at ";"')
Expect(identical(PanKeys('543;30483049;2655'), '543; 3048; 3049; 2655'), 'a glued eight-digit token is split in two')
Expect(identical(PanKeys('30483049'), '3048; 3049') && identical(PanKeys('2655;15941597'), '2655; 1594; 1597'),
       'a glued token at either end of the cell is split')
Expect(identical(PanKeys('12345'), '12345'), 'a token of another length is left as it is')
Expect(is.na(PanKeys('-999')) && is.na(PanKeys('')), '-999 and an empty cell give NA')

# ---- the tracked lists --------------------------------------------------------------
cat('tracked reference lists\n')
amn <- read.csv(file.path(repo, 'sources', 'databases', 'Myhrvold_2015', 'references.csv'),
                stringsAsFactors = FALSE, colClasses = 'character', encoding = 'UTF-8')
Expect(all(c('key', 'reference_name', 'citation', 'note', 'owner_review') %in% names(amn)) && nrow(amn) >= 100,
       sprintf('Myhrvold_2015/references.csv has the expected columns (%d rows)', nrow(amn)))
Expect(!anyDuplicated(amn$key) && !anyDuplicated(amn$reference_name) && all(nzchar(amn$citation)),
       'keys and reference names are unique, every citation has text')
Expect(!any(grepl(';', amn$key)) && all(grepl('^[A-Za-z]+(_[0-9]{4}[a-z]?)?(_[0-9]+)?$', amn$key)),
       'keys are Surname[_year[letter]][_n] with no separator inside')
Expect(!any(grepl('^BC (Birds|mammals|Reptiles) - ', amn$reference_name)), 'no reference name keeps the batch prefix')
cells2 <- c('Dunning, 1992 from median of 2(Dunning, 1992, Bennett, 1986)', 'mean of Meiri, 2010 & Boback and Guyer, 2003')
Expect(identical(AmnioteValueSources(cells2, amn), c('Dunning_1992', 'Meiri_2010; Boback_2003')),
       'the tracked list splits the common cell forms')
pan <- read.csv(file.path(repo, 'sources', 'databases', 'Jones_2009', 'references.csv'),
                stringsAsFactors = FALSE, colClasses = 'character', encoding = 'UTF-8')
Expect(identical(names(pan), c('key', 'citation')) && identical(pan$key, as.character(seq_len(nrow(pan)))) && nrow(pan) == 3143,
       sprintf('Jones_2009/references.csv is numbered 1..%d without a gap', nrow(pan)))
Expect(all(nzchar(pan$citation)) && !any(grepl('History of data set usage', pan$citation)),
       'every PanTHERIA entry has text and the last one carries no following section')
Expect(!is.null(reflist_specs$Myhrvold_2015) && !is.null(reflist_specs$Jones_2009) &&
         identical(reflist_specs$Myhrvold_2015$frame, 'DataRetrieverAll') && identical(reflist_specs$Jones_2009$frame, 'DataRetrieverAll'),
       'reflist_specs name the DataRetrieverAll frame for both labels')

# ---- summary ---------------------------------------------------------------------
cat(sprintf('\n%d expectations, %d failed\n', n_checks, length(failures)))
if (length(failures) > 0) {
  cat(paste0('  FAIL: ', failures, '\n'), sep = '')
  quit(status = 1)
}
