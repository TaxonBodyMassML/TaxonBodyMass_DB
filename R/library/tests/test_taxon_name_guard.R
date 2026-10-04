# Tests for the taxon-name guards of R/RunMe.r (#28, #48):
# CheckTaxonNames() in R/library/check_taxon_names.r on synthetic per-source
# frames (section 2b), the real cleaning chain on the name that motivated the
# guard and on the Makarieva Crithidia (Strigomonas) records (#36), a static
# check of the rename tables, CheckSheetTaxa() on synthetic lab Sheet frames
# (section 4: well-formed names, parentheses, blanks, three-part names, #48),
# and the wiring in RunMe.r. No network access and no packages beyond base R
# are needed.
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

# ---- the Sheet guard (#48) -----------------------------------------------------
cat('CheckSheetTaxa() on synthetic Sheet frames\n')
Sheet <- function(taxon, mass = seq_along(taxon), source = 'Nakagawa_2014')
  data.frame(taxon = taxon, mass_g = mass, source_mass = source, stringsAsFactors = FALSE)
Warned <- function(expr) {            # the value and the (muffled) warning message, if any
  w <- NULL
  out <- withCallingHandlers(expr, warning = function(x) { w <<- conditionMessage(x); invokeRestart('muffleWarning') })
  list(out = out, warning = w)
}
good <- Sheet(c('Gadus_morhua', 'Lepidostoma', 'Edaphus_blYhweissi', 'Osmerus_mordax'))
g <- Warned(CheckSheetTaxa(good))
Expect(identical(g$out, good) && is.null(g$warning), 'well-formed species- and genus-level names pass unchanged, without a warning')
e <- ErrorOf(CheckSheetTaxa(Sheet(c('Gadus_morhua', 'Lepidostoma_(genus_in_Opisthokonta)'), c(1, 0.0028))))
Expect(Has(e, '1 row(s) of the lab Sheet (BM_data)') &&
         Has(e, "taxon 'Lepidostoma_(genus_in_Opisthokonta)'  mass_g 0.0028  source_mass 'Nakagawa_2014'"),
       'parentheses stop the run; the row is listed with its taxon, mass and source')
Expect(Has(e, "-> 'Lepidostoma'") && !Has(e, "'Gadus_morhua'"), 'the message shows the correction to make and does not list the well-formed row')
e <- ErrorOf(CheckSheetTaxa(Sheet(c(NA, '', ' Gadus_morhua', 'Gadus_morhua ', 'gadus_morhua', 'Gadus morhua', 'Gadus_Morhua', 'Gadus_morhua2',
                                    'Gadus_morhua_(L.)'))))
Expect(Has(e, '9 row(s)'),
       'an NA cell, an empty cell, leading or trailing blanks, a lowercase genus, a space, a capitalised epithet, a digit and a bracketed third part are all rejected')
Expect(Has(e, "taxon '<empty>'  mass_g 1  source_mass") && Has(e, "taxon ''  mass_g 2  source_mass"), 'an NA cell is shown as <empty>')
w <- Warned(CheckSheetTaxa(Sheet(c('Osmerus_mordax_dentex', 'Gadus_morhua'), c(30, 1), 'Burbidge_1969')))
Expect(identical(w$out$taxon, c('Osmerus_mordax', 'Gadus_morhua')) && identical(w$out$mass_g, c(30, 1)) &&
         identical(w$out$source_mass, rep('Burbidge_1969', 2)),
       'a three-part name (a subspecies) folds to the species, as the source trinomials do; the other columns are untouched')
Expect(Has(w$warning, '1 lab Sheet (BM_data) taxon name(s) have three parts') &&
         Has(w$warning, "taxon 'Osmerus_mordax_dentex'  mass_g 30  source_mass 'Burbidge_1969'  -> 'Osmerus_mordax'") &&
         Has(w$warning, 'write the species name in the Sheet'),
       'with a warning that names the row and the folded name and asks for the species in the Sheet')
Expect(Has(ErrorOf(CheckSheetTaxa(Sheet('Osmerus_mordax_dentex'), fold_trinomials = FALSE)), '1 row(s)'),
       'fold_trinomials = FALSE makes a three-part name an error')
Expect(Has(ErrorOf(suppressWarnings(CheckSheetTaxa(Sheet(c('Osmerus_mordax_Dentex', 'Osmerus_mordax_dentex_x', 'Osmerus_Mordax_dentex'))))), '3 row(s)'),
       'a capitalised third part, four parts or a capitalised epithet are errors, not trinomials')
Expect(Has(ErrorOf(CheckSheetTaxa(data.frame(taxon = 'Gadus_morhua', mass_g = 1))), 'columns taxon, mass_g and source_mass'),
       'a frame without the three columns stops with a pointer')

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
i_filt  <- grep("^ddat <- ddat\\[which\\(!is\\.na\\(ddat\\$mass_g\\)\\), 1:4\\]", runme)
i_sheet <- grep('^ddat <- CheckSheetTaxa\\(ddat\\)', runme)
i_adat  <- grep('^sheet      <- ApplySheetOverride\\(ddat, adat_raw, genus_only\\)', runme)
Expect(length(i_filt) == 1 && length(i_sheet) == 1 && length(i_adat) == 1 && i_filt < i_sheet && i_sheet < i_adat,
       'RunMe.r checks the Sheet taxa (CheckSheetTaxa(), #48) after the mass filter and before the override binds them to the source rows (ApplySheetOverride(), #57)')

# ---- summary -------------------------------------------------------------------
cat(sprintf('\n%d expectations, %d failed\n', n_checks, length(failures)))
if (length(failures) > 0) {
  cat(paste0('  FAIL: ', failures, '\n'), sep = '')
  quit(status = 1)
}
