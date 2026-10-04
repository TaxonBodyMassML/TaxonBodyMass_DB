# Tests for the six one-token rename rules of R/library/fix_misspellings.r
# added by #47: the misspelt genera that the food-web compilations
# (Brose_etal_2018) and Makarieva_2008 write as bare names (Heremodromia,
# Telonemus, Tetraluerodes, renic, Amoebobaeter, Sallinivibrio). Each is pinned
# to its GBIF genus through the real cleaning chain of RunMe.r section 2b
# (FixFormatting, FixMisspellings, RemoveNonTaxa); the result is a one-token
# name, which section 3 files as a genus-level record, so the species table
# cannot gain a row from these rules. The correct spellings pass unchanged, the
# neighbouring species-level records keep their own rules, and every one-token
# key of the table maps to a one-token value. No network access, no cached
# frames and no packages beyond base R are needed.
#
#   Rscript R/library/tests/test_misspelt_genera.R      (from any directory)
#
# Prints one line per expectation and exits with status 1 if any failed.

this_file <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE))
if (length(this_file) == 0)         # sourced interactively from the repo root
  this_file <- file.path('R', 'library', 'tests', 'test_misspelt_genera.R')
repo <- normalizePath(file.path(dirname(this_file), '..', '..', '..'))
lib  <- file.path(repo, 'R', 'library')
source(file.path(lib, 'helpers.r'))               # DropImputed(), imputed_log
source(file.path(lib, 'fix_formatting.r'))
source(file.path(lib, 'fix_misspellings.r'))
source(file.path(lib, 'fix_nontaxa.r'))
source(file.path(lib, 'check_taxon_names.r'))
raw_name_patterns <- LoadRawNamePatterns(file.path(repo, 'audit', 'raw_name_patterns.csv'))

failures <- character(0)
n_checks <- 0L
Expect <- function(ok, what) {
  n_checks <<- n_checks + 1L
  if (!isTRUE(ok)) failures <<- c(failures, what)
  cat(sprintf('  %s %s\n', if (isTRUE(ok)) 'ok  ' else 'FAIL', what))
}
ErrorOf <- function(expr) tryCatch({ expr; NULL }, error = function(e) conditionMessage(e))
Frame <- function(taxon, source = 'SrcA')
  data.frame(taxon = taxon, mass_g = seq_along(taxon), n = 1, source_mass = source, stringsAsFactors = FALSE)
Cleaned <- function(taxon) { raw_name_log <<- list(); imputed_log <<- list(); suppressMessages(FixFormatting(Frame(taxon)))$taxon }
# The chain of RunMe.r section 2b on raw names: FixFormatting, FixMisspellings, RemoveNonTaxa.
Chain <- function(taxon, source = 'SrcA') {
  raw_name_log <<- list(); imputed_log <<- list()
  RemoveNonTaxa(FixMisspellings(suppressMessages(FixFormatting(Frame(taxon, source)))))
}

# The names as the sources write them, the cleaned keys and the GBIF genera.
raw     <- c('Heremodromia', 'Telonemus', 'Tetraluerodes', 'renic', 'Amoebobaeter', 'Sallinivibrio')
keys    <- c('Heremodromia', 'Telonemus', 'Tetraluerodes', 'Renic', 'Amoebobaeter', 'Sallinivibrio')
genera  <- c('Hemerodromia', 'Telenomus', 'Tetraleurodes', 'Renicola', 'Amoebobacter', 'Salinivibrio')
sources <- c(rep('Brose_etal_2018', 4), rep('Makarieva_2008', 2))

# ---- the six names through the cleaning chain ------------------------------------
cat('the six misspelt genera of #47 through the cleaning chain\n')
Expect(identical(Cleaned(raw), keys),
       "FixFormatting() leaves the names as one-token keys ('renic' capitalised to 'Renic'), the forms the rename table matches")
out <- Chain(raw, sources)
Expect(identical(out$taxon, genera),
       'FixMisspellings() maps each to its GBIF genus: Hemerodromia, Telenomus, Tetraleurodes, Renicola, Amoebobacter, Salinivibrio')
Expect(nrow(out) == 6 && all(out$mass_g == 1:6) && identical(out$source_mass, sources),
       'RemoveNonTaxa() keeps all six records with their masses and source labels')
Expect(!any(grepl('_', out$taxon, fixed = TRUE)),
       'every result is one token, so RunMe section 3 files it as a genus-level record and no species row is created')
Expect(is.null(ErrorOf(CheckTaxonNames(list(out)))), 'the corrected names pass CheckTaxonNames()')
Expect(identical(Chain(genera)$taxon, genera), 'the correct spellings pass the chain unchanged (the rules are idempotent)')
Expect(identical(Chain(c('Sallinivibrio costicola', 'Renicola buchanani', 'Renicola cerithidicola'))$taxon,
                 c('Salinivibrio_costicola', 'Renicola_buchanani', 'Renicola_cerithidicola')),
       "the species-level neighbours keep their own fate: 'Sallinivibrio costicola' takes the older species rule, the two Carpinteria Renicola species are untouched")
Expect(nrow(Chain('Renicola sp.')) == 0, "'Renicola sp.' is still a placeholder that RemoveNonTaxa() removes (#43)")

# ---- static check of the rules in fix_misspellings.r --------------------------------
cat('static check of the rules\n')
txt <- readLines(file.path(lib, 'fix_misspellings.r'), warn = FALSE)
m <- regmatches(txt, regexec('^\\s*"([^"]+)"\\s*=\\s*"([^"]*)"\\s*,?\\s*(#.*)?$', txt))
rules <- do.call(rbind, lapply(m, function(x) if (length(x) == 4) data.frame(key = x[2], value = x[3], comment = x[4], stringsAsFactors = FALSE)))
i <- match(keys, rules$key)
Expect(!anyNA(i) && identical(rules$value[i], genera), 'the six rules are present with the genus as value')
Expect(all(grepl('GBIF [0-9]+', rules$comment[i])) && all(grepl('Brose_etal_2018|Makarieva_2008', rules$comment[i])),
       'each rule names its source and the GBIF usage key of the genus')
one_token <- rules[!grepl('_', rules$key, fixed = TRUE), ]
Expect(nrow(one_token) >= 6 && !any(grepl('_', one_token$value, fixed = TRUE)),
       sprintf('every one-token key of the table (%d) maps to a one-token value: a genus-level record is never promoted to a species', nrow(one_token)))

cat(sprintf('\n%d checks, %d failed\n', n_checks, length(failures)))
if (length(failures)) { cat(paste0('  FAIL ', failures, '\n'), sep = ''); quit(status = 1) }
