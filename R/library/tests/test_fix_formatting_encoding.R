# Tests for the encoding step of FixFormatting() in R/library/fix_formatting.r
# (#37): valid UTF-8 names are no longer re-encoded from Latin-1 (which turned
# 'Nausithoe rubra' with its diaeresis into 'NausithoA_rubra' and the two
# Makarieva_2008 'Tetrao urogallus' + U+2640 records into NA), Latin-1 bytes still are
# converted, diacritics are transliterated to ASCII, the sex signs U+2640 /
# U+2642 are stripped with the record kept, and no name comes out NA. Also
# checks the Edaphus rule of fix_misspellings.r, the reuse of the shared
# Latin1ToUtf8() by TaxonKey() in foodweb_units.r, and a static property of the
# rename table. Non-ASCII characters are written as \u escapes so the file
# parses in any locale. No network access and no packages beyond base R are
# needed.
#
#   Rscript R/library/tests/test_fix_formatting_encoding.R      (from any directory)
#
# Prints one line per expectation and exits with status 1 if any failed.

this_file <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE))
if (length(this_file) == 0)         # sourced interactively from the repo root
  this_file <- file.path('R', 'library', 'tests', 'test_fix_formatting_encoding.R')
repo <- normalizePath(file.path(dirname(this_file), '..', '..', '..'))
lib  <- file.path(repo, 'R', 'library')
source(file.path(lib, 'helpers.r'))               # DropImputed(), imputed_log
source(file.path(lib, 'fix_formatting.r'))
source(file.path(lib, 'fix_misspellings.r'))
source(file.path(lib, 'check_taxon_names.r'))
source(file.path(lib, 'foodweb_units.r'))
raw_name_patterns <- LoadRawNamePatterns(file.path(repo, 'audit', 'raw_name_patterns.csv'))

failures <- character(0)
n_checks <- 0L
Expect <- function(ok, what) {
  n_checks <<- n_checks + 1L
  if (!isTRUE(ok)) failures <<- c(failures, what)
  cat(sprintf('  %s %s\n', if (isTRUE(ok)) 'ok  ' else 'FAIL', what))
}
ErrorOf <- function(expr) tryCatch({ expr; NULL }, error = function(e) conditionMessage(e))
Frame <- function(taxon, mass = seq_along(taxon))
  data.frame(taxon = taxon, mass_g = mass, n = 1, source_mass = 'SrcA', stringsAsFactors = FALSE)

# ---- the inputs -------------------------------------------------------------------
utf8_female  <- 'Tetrao urogallus \u2640'         # Makarieva_2008, two records (female sign)
utf8_male    <- 'Tetrao urogallus \u2642'         # male sign
utf8_diacr   <- 'Nausitho\u00eb rubra'            # Makarieva_2008 (e with diaeresis)
utf8_uml     <- 'Edaphus bl\u00fchweissi'         # intended GATEWAy name (u with diaeresis)
gateway_Y    <- 'Edaphus bl\u0178hweissi'         # GATEWAy as shipped: Mac Roman 0x9F read as CP1252 (Y with diaeresis)
latin1_mark  <- iconv(utf8_diacr, from = 'UTF-8', to = 'latin1')   # bytes 0xEB, marked latin1
latin1_bytes <- rawToChar(charToRaw(latin1_mark))                  # same bytes, Encoding 'unknown'
ascii        <- 'Gadus morhua'

cat('the inputs are what the test assumes\n')
Expect(identical(charToRaw(utf8_female)[18:20], as.raw(c(0xe2, 0x99, 0x80))), 'U+2640 is the three bytes e2 99 80')
Expect(validUTF8(utf8_female) && validUTF8(utf8_diacr) && validUTF8(gateway_Y), 'the UTF-8 inputs are valid UTF-8')
Expect(identical(Encoding(latin1_mark), 'latin1') && !validUTF8(latin1_mark), 'the Latin-1 input is marked latin1 and is not valid UTF-8')
Expect(identical(Encoding(latin1_bytes), 'unknown') && !validUTF8(latin1_bytes), 'the unmarked Latin-1 input is not valid UTF-8')

# ---- Latin1ToUtf8() ---------------------------------------------------------------
cat('Latin1ToUtf8()\n')
Expect(identical(charToRaw(Latin1ToUtf8(utf8_diacr)), charToRaw(utf8_diacr)), 'valid UTF-8 is returned byte for byte')
Expect(identical(charToRaw(Latin1ToUtf8(utf8_female)), charToRaw(utf8_female)), 'the U+2640 name is returned byte for byte')
Expect(identical(charToRaw(Latin1ToUtf8(latin1_mark)), charToRaw(utf8_diacr)), 'latin1-marked bytes are converted to the UTF-8 name')
Expect(identical(charToRaw(Latin1ToUtf8(latin1_bytes)), charToRaw(utf8_diacr)), 'unmarked Latin-1 bytes are converted to the UTF-8 name')
Expect(all(validUTF8(Latin1ToUtf8(c(latin1_mark, utf8_female, ascii)))), 'a mixed vector comes out all valid UTF-8')
Expect(identical(Latin1ToUtf8(c('a', NA)), c('a', NA_character_)), 'NA is preserved')
Expect(identical(Latin1ToUtf8(factor(ascii)), ascii), 'a factor is accepted')

# ---- FixFormatting() on the names of #37 ------------------------------------------
cat('FixFormatting() on the names of #37\n')
inp <- Frame(c(utf8_female, utf8_male, utf8_diacr, latin1_mark, latin1_bytes, utf8_uml, ascii, 'Tetrao urogallus'),
             mass = c(3900, 4010, 2.6, 2.6, 2.6, 6.72e-05, 1000, 4010))
out <- FixFormatting(inp)
Expect(nrow(out) == nrow(inp), 'no row is lost')
Expect(!anyNA(out$taxon), 'no name is NA')
Expect(identical(out$taxon, c('Tetrao_urogallus', 'Tetrao_urogallus', 'Nausithoe_rubra', 'Nausithoe_rubra',
                              'Nausithoe_rubra', 'Edaphus_bluhweissi', 'Gadus_morhua', 'Tetrao_urogallus')),
       'every name comes out as the expected Genus_species')
Expect(identical(out$mass_g, inp$mass_g), 'the masses stay with their rows')
Expect(all(validUTF8(out$taxon)) && !any(grepl('[^\x01-\x7F]', out$taxon)), 'the output is plain ASCII')
Expect(is.null(ErrorOf(CheckTaxonNames(list(out)))), 'the taxon-name guard passes on the output')
Expect(identical(FixFormatting(Frame(utf8_female))$taxon, 'Tetrao_urogallus'),
       "'Tetrao urogallus \\u2640' alone is a Tetrao_urogallus record (sex sign stripped, record kept)")
Expect(identical(FixFormatting(Frame('\u2640 Tetrao urogallus'))$taxon, 'Tetrao_urogallus'), 'a leading sex sign is stripped too')
Expect(identical(FixFormatting(Frame('Nausitho\u00eb rubra Vanh\u00f6ffen, 1902'))$taxon, 'Nausithoe_rubra'),
       'a diacritic in a trailing authority does not change the binomial (the authority is an annotation of audit/raw_name_patterns.csv, #38)')

# ---- what the pipeline does with the real GATEWAy and Makarieva bytes --------------
cat('the cleaning chain on the GATEWAy Edaphus record\n')
ff <- FixFormatting(Frame(gateway_Y))
Expect(identical(ff$taxon, 'Edaphus_blYhweissi'), "FixFormatting transliterates the shipped U+0178 to 'Edaphus_blYhweissi'")
Expect(identical(FixMisspellings(ff)$taxon, 'Edaphus_bluhweissi'),
       "fix_misspellings.r maps it to 'Edaphus_bluhweissi' (Edaphus bl\\u00fchweissi Scheerpeltz, 1936; GBIF synonym of Edaphus lederi)")
Expect(identical(FixMisspellings(FixFormatting(Frame(utf8_uml)))$taxon, 'Edaphus_bluhweissi'),
       'the correctly spelt name reaches the same key without a rule')

# ---- rows that are NA or empty after cleaning are dropped, not kept as NA rows ------
cat('empty and NA names\n')
e <- FixFormatting(Frame(c(ascii, NA, '', '  ', '\u2640')))
Expect(nrow(e) == 1 && identical(e$taxon, 'Gadus_morhua') && !anyNA(e$mass_g),
       'NA, empty, blank and sign-only names are dropped as rows; no all-NA row remains')

# ---- the shared helper is used by TaxonKey() of foodweb_units.r --------------------
cat('TaxonKey() of foodweb_units.r\n')
Expect(identical(TaxonKey(latin1_mark), 'nausithoe rubra') && identical(TaxonKey(utf8_diacr), 'nausithoe rubra'),
       'TaxonKey() gives the same key for the Latin-1 and the UTF-8 spelling')
defs <- vapply(list.files(lib, pattern = '\\.[rR]$', full.names = TRUE),
               function(f) any(grepl('^Latin1ToUtf8 <- function', readLines(f, warn = FALSE))), logical(1))
Expect(identical(basename(names(defs)[defs]), 'fix_formatting.r'), 'Latin1ToUtf8() is defined once, in fix_formatting.r')

# ---- static check of the rename table ----------------------------------------------
cat('static check of fix_misspellings.r\n')
txt  <- readLines(file.path(lib, 'fix_misspellings.r'), warn = FALSE)
keys <- regmatches(txt, regexec('^\\s*"([^"]+)"\\s*=\\s*"', txt))
keys <- unlist(lapply(keys, function(x) if (length(x) == 2) x[2] else character(0)))
Expect(length(keys) > 300, sprintf('%d rule keys read', length(keys)))
Expect(!any(grepl('[^\x01-\x7F]', keys)),
       'no rule key contains a non-ASCII character (FixFormatting strips them, so such a key can never match)')
Expect('Edaphus_blYhweissi' %in% keys, 'the Edaphus rule is present')

# ---- summary -------------------------------------------------------------------
cat(sprintf('\n%d expectations, %d failed\n', n_checks, length(failures)))
if (length(failures) > 0) {
  cat(paste0('  FAIL: ', failures, '\n'), sep = '')
  quit(status = 1)
}
