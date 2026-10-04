# Tests for the taxon-name guard of R/RunMe.r section 2b (#28):
# CheckTaxonNames() in R/library/check_taxon_names.r on synthetic per-source
# frames, the real cleaning chain on the name that motivated the guard and on
# the Makarieva Crithidia (Strigomonas) records (#36), a static check of the
# rename tables, and the wiring in RunMe.r. No network
# access and no packages beyond base R are needed.
#
#   Rscript R/library/tests/test_taxon_name_guard.R      (from any directory)
#
# Prints one line per expectation and exits with status 1 if any failed.

this_file <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE))
if (length(this_file) == 0)         # sourced interactively from the repo root
  this_file <- file.path('R', 'library', 'tests', 'test_taxon_name_guard.R')
repo <- normalizePath(file.path(dirname(this_file), '..', '..', '..'))
lib  <- file.path(repo, 'R', 'library')
source(file.path(lib, 'helpers.r'))               # DropImputed(), imputed_log
source(file.path(lib, 'check_taxon_names.r'))
source(file.path(lib, 'fix_formatting.r'))
source(file.path(lib, 'fix_misspellings.r'))
source(file.path(lib, 'fix_nontaxa.r'))
raw_name_patterns <- LoadRawNamePatterns(file.path(repo, 'audit', 'raw_name_patterns.csv'))

failures <- character(0)
n_checks <- 0L
Expect <- function(ok, what) {
  n_checks <<- n_checks + 1L
  if (!isTRUE(ok)) failures <<- c(failures, what)
  cat(sprintf('  %s %s\n', if (isTRUE(ok)) 'ok  ' else 'FAIL', what))
}
ErrorOf <- function(expr) tryCatch({ expr; NULL }, error = function(e) conditionMessage(e))
Has <- function(x, pattern) !is.null(x) && grepl(pattern, x, fixed = TRUE)
Frame <- function(taxon, source)
  data.frame(taxon = taxon, mass_g = 1, source_mass = source, stringsAsFactors = FALSE)

# ---- synthetic frames ----------------------------------------------------------
cat('CheckTaxonNames() on synthetic frames\n')
clean <- list(Frame(c('Genus_species', 'Genus', 'Brachypera_isabellina', 'Edaphus_blYhweissi', 'UnID_chrysomonad'), 'SrcA'),
              Frame(c('Alpha_beta', NA), 'SrcB; Conv_2010'))
Expect(is.null(ErrorOf(CheckTaxonNames(clean))),
       'species-level, genus-level, mixed-case and NA names pass')
Expect(identical(suppressWarnings(CheckTaxonNames(clean)), 7L),
       'returns the number of names checked')

dirty <- list(Frame(c('Genus_species', 'Rhytonomus isabellina'), 'Chown_etal_2007'),
              Frame('Rhytonomus isabellina', 'Makarieva_2008'),
              Frame(c('Alpha_beta', 'Gamma delta epsilon', '', 'Tab\tname'), 'SrcC; Brey_2010'))
e <- ErrorOf(CheckTaxonNames(dirty))
Expect(!is.null(e), 'a name with a space stops the run')
Expect(Has(e, '4 cleaned taxon name(s)'), 'the four distinct offending names are counted')
e38 <- ErrorOf(CheckTaxonNames(list(Frame(c('Genus_species_(weird)', 'Genus_sp2', 'Genus_species_subsp', 'genus_species', 'Genus_Species'), 'SrcD'))))
Expect(Has(e38, '5 cleaned taxon name(s)'),
       'brackets, digits, a third token, a lowercase genus and a capitalised epithet stop the run too (#38)')
Expect(Has(e, "'Rhytonomus isabellina'  (Chown_etal_2007, Makarieva_2008)"),
       'the taxon is named with every source that carries it')
Expect(Has(e, "'Gamma delta epsilon'  (SrcC)"),
       'only the source label is reported, not the conversion CiteID after ";"')
Expect(Has(e, "''  (SrcC)"), 'an empty name is reported')
Expect(Has(e, "'Tab\tname'  (SrcC)"), 'a tab counts as whitespace')
Expect(!Has(e, "'Genus_species'") && !Has(e, "'Alpha_beta'"), 'well-formed names are not listed')
Expect(Has(e, 'fix_misspellings.r'), 'the message points at the rename tables')

one <- list(Frame('Rhytonomus isabellina', 'Ehnes_etal_2011'))
Expect(Has(ErrorOf(CheckTaxonNames(one)), '1 cleaned taxon name(s)'), 'a single offender in a single frame')

# ---- the real cleaning chain on the name that motivated the guard ---------------
cat('the cleaning chain on the Rhytonomus record\n')
out <- FixMisspellings(FixFormatting(Frame('Rhytonomus isobellina', 'Chown_etal_2007')))
Expect(identical(out$taxon, 'Brachypera_isabellina'),
       "fix_misspellings.r maps 'Rhytonomus isobellina' to 'Brachypera_isabellina' (Phytonomus isabellinus Boheman 1834)")
Expect(grepl('_', out$taxon, fixed = TRUE), 'the corrected name passes the species test of section 3')
Expect(is.null(ErrorOf(CheckTaxonNames(list(out)))), 'and the guard passes on it')

odd <- Frame(c('Genus  species', '  Genus species subsp. x', 'Genus species',
               'Genus species (Auth., 1900)', 'Genus_species'), 'SrcA')
Expect(is.null(ErrorOf(CheckTaxonNames(list(FixFormatting(odd))))),
       'FixFormatting leaves no whitespace whatever the input spacing (a tab inside a name is a removed symbol)')

# ---- #36: Makarieva_2008's Crithidia (Strigomonas) records -----------------------
cat('the cleaning chain on the Makarieva Crithidia (Strigomonas) records (#36, #38)\n')
ff <- FixFormatting(Frame(c('Crithidia (Strigomonas) oncopelti', 'Crithida (Strigomonas) fasciculata'), 'Makarieva_2008'))
Expect(identical(ff$taxon, c('Crithidia_oncopelti', 'Crithida_fasciculata')),
       'FixFormatting removes the bracketed subgenus and keeps genus and epithet (#38; before, Crithidia_strigomonas)')
mk <- FixMisspellings(ff)
Expect(identical(mk$taxon, c('Strigomonas_oncopelti', 'Crithidia_fasciculata')),
       'each rule maps its own row: Strigomonas_oncopelti and Crithidia_fasciculata')
Expect(nrow(RemoveNonTaxa(mk)) == 2, 'RemoveNonTaxa keeps both')
Expect(is.null(ErrorOf(CheckTaxonNames(list(mk)))), 'neither name trips the guard')

# ---- static check of the rename tables -----------------------------------------
cat('static check of the rename tables in R/library\n')
Values <- function(file) {            # right-hand sides of "key" = "value" lines
  txt <- readLines(file.path(lib, file))
  m <- regmatches(txt, regexec('^\\s*"[^"]+"\\s*=\\s*"([^"]*)"', txt))
  unlist(lapply(m, function(x) if (length(x) == 2) x[2] else character(0)))
}
Entries <- function(file) {           # quoted entries of the character vectors
  txt <- readLines(file.path(lib, file))
  m <- regmatches(txt, regexec('^\\s*"([^"]+)"\\s*,?\\s*(#.*)?$', txt))
  unlist(lapply(m, function(x) if (length(x) >= 2) x[2] else character(0)))
}
vals <- Values('fix_misspellings.r')
Expect(length(vals) > 300, sprintf('%d replacement values read from fix_misspellings.r', length(vals)))
Expect(!any(grepl('[[:space:]]', vals)), 'no replacement value of fix_misspellings.r contains whitespace')
Expect(all(grepl('^[A-Z][a-z]+(_[a-z]+)?$', vals)),
       'every replacement value is Genus or Genus_species (letters only, lowercase epithet)')
ents <- Entries('fix_nontaxa.r')
Expect(length(ents) > 100, sprintf('%d entries read from fix_nontaxa.r', length(ents)))
Expect(!any(grepl('[[:space:]]', ents)),
       'no fix_nontaxa.r entry contains whitespace (such an entry can never match a cleaned name)')

# ---- wiring in RunMe.r ------------------------------------------------------------
cat('R/RunMe.r wiring\n')
runme  <- readLines(file.path(repo, 'R', 'RunMe.r'))
i_src  <- grep("source\\(.*check_taxon_names\\.r", runme)
i_ext  <- grep('^source_list <- lapply\\(source_list, RemoveExtinct\\)', runme)
i_call <- grep('^CheckTaxonNames\\(source_list\\)', runme)
i_bind <- grep('^adat_raw <- bind_rows\\(source_list\\)', runme)
Expect(length(i_src) == 1 && length(i_call) == 1,
       'RunMe.r sources check_taxon_names.r and calls CheckTaxonNames() once')
Expect(length(i_ext) == 1 && length(i_bind) == 1 && i_ext < i_call && i_call < i_bind,
       'the call sits after RemoveExtinct() and before the section-3 bind')

# ---- summary -------------------------------------------------------------------
cat(sprintf('\n%d expectations, %d failed\n', n_checks, length(failures)))
if (length(failures) > 0) {
  cat(paste0('  FAIL: ', failures, '\n'), sep = '')
  quit(status = 1)
}
