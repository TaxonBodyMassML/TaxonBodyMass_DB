# Tests for the lab Sheet override of R/RunMe.r section 4
# (R/library/sheet_override.r, #57) on synthetic Sheet frames with species-
# and genus-level rows against synthetic source rows: the species override
# replaces every compiled record of a Sheet species and nothing else; the
# genus-level rows land in the genus-only rows and replace only the sources'
# genus-only rows of the same bare name, leaving the species-level values of
# the genus alone; a Sheet taxon no source carries is added; an empty Sheet
# changes nothing; and the wiring in RunMe.r (the call after CheckSheetTaxa(),
# the old bind gone, the stale bare names dropped from the species cache). No
# network access and no packages beyond base R are needed.
#
#   Rscript R/library/tests/test_sheet_override.R      (from any directory)
#
# Prints one line per expectation and exits with status 1 if any failed.

this_file <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE))
if (length(this_file) == 0)         # sourced interactively from the repo root
  this_file <- file.path('R', 'library', 'tests', 'test_sheet_override.R')
repo <- normalizePath(file.path(dirname(this_file), '..', '..', '..'))
lib  <- file.path(repo, 'R', 'library')
source(file.path(lib, 'helpers.r'))
source(file.path(lib, 'sheet_override.r'))

failures <- character(0)
n_checks <- 0L
Expect <- function(ok, what) {
  n_checks <<- n_checks + 1L
  if (!isTRUE(ok)) failures <<- c(failures, what)
  cat(sprintf('  %s %s\n', if (isTRUE(ok)) 'ok  ' else 'FAIL', what))
}
ErrorOf <- function(expr) tryCatch({ expr; NULL }, error = function(e) conditionMessage(e))
Has <- function(x, pattern) !is.null(x) && grepl(pattern, x, fixed = TRUE)
# identical() up to row names and the type of n: the Sheet rows carry n = 1 as
# a double, so the bind coerces the frames' integer n to double, as
# bind_rows() did before #57 (n is not used downstream: Pass 1 counts rows)
Same <- function(a, b) {
  a <- as.data.frame(a); b <- as.data.frame(b); rownames(a) <- NULL; rownames(b) <- NULL
  if ('n' %in% names(a)) a$n <- as.numeric(a$n)
  if ('n' %in% names(b)) b$n <- as.numeric(b$n)
  identical(a, b)
}

# ---- fixtures ------------------------------------------------------------------
# The Sheet as read_sheet() gives it (four columns, the first a group label the
# override drops) after CheckSheetTaxa() and NormaliseSourceLabel()
Sheet <- function(taxon, mass, source)
  data.frame(Taxon.group = 'x', taxon = taxon, mass_g = mass, source_mass = source, stringsAsFactors = FALSE)
# source rows as section 3 binds them: the frames' columns, kingdom..family
# added, plus a column only some frames carry
Src <- function(taxon, mass, source, class = NA_character_, dataset = NA_character_)
  data.frame(taxon = taxon, mass_g = mass, source_mass = source, n = 1L, kingdom = NA_character_, phylum = NA_character_,
             class = class, order = NA_character_, family = NA_character_, dataset = dataset, stringsAsFactors = FALSE)
adat_raw <- rbind(
  Src('Gadus_morhua', c(900, 1100), c('SrcA', 'SrcB'), class = 'Actinopterygii'),
  Src('Lepidostoma_hirtum', c(6e-4, 7e-4), 'Brose_etal_2018'),
  Src('Hypopomus_artedi', 500, 'SrcC'),
  Src('Osmerus_mordax', 30, 'Burbidge_1969', dataset = 'd1'),
  Src(NA_character_, 1, 'SrcA'))                      # a name iconv() could not transliterate (section 6 drops it)
genus_only <- rbind(
  Src('Lepidostoma', c(5e-4, 8e-4), 'Brose_etal_2018'),
  Src('Lepidostoma', 9e-4, 'SrcD'),
  Src('Hypopomus', 450, 'SrcC'),
  Src('Caroperla', 0.005, 'SrcE', class = 'Insecta'),
  Src('Staphylinidae', 0.01, 'Brose_etal_2018'))
ddat <- Sheet(c('Gadus_morhua', 'Lepidostoma', 'Hypopomus', 'Evermannella'), c(1000, 0.0028, 588, 28.9),
              c('SheetA', 'Nakagawa_2014', 'Froese_2025; Froese_2014', 'Froese_2025; Froese_2014'))

# ---- SplitSheetRows() and SheetRows() --------------------------------------------
cat('SplitSheetRows() and SheetRows()\n')
h <- SplitSheetRows(ddat)
Expect(identical(h$species$taxon, 'Gadus_morhua') && identical(h$genus$taxon, c('Lepidostoma', 'Hypopomus', 'Evermannella')),
       'the rule of section 3: a name with an underscore is species-level, a bare name genus-level; order kept')
r <- SheetRows(h$genus)
Expect(identical(names(r), sheet_row_columns) && !'Taxon.group' %in% names(r),
       'SheetRows() gives the nine columns the paths take (taxon, mass_g, source_mass, n, kingdom..family) and drops the Sheet\'s other columns')
Expect(all(r$n == 1) && all(is.na(r[, sheet_hint_columns])) && identical(r$mass_g, c(0.0028, 588, 28.9)) &&
         identical(r$source_mass, c('Nakagawa_2014', 'Froese_2025; Froese_2014', 'Froese_2025; Froese_2014')),
       'n = 1, no classification hints, mass and the full source_mass string (conversion CiteIDs after ";") kept')
Expect(nrow(SheetRows(ddat[0, ])) == 0 && identical(names(SheetRows(ddat[0, ])), sheet_row_columns), 'no rows: an empty frame with the same columns')

# ---- the override --------------------------------------------------------------
cat('ApplySheetOverride()\n')
res <- ApplySheetOverride(ddat, adat_raw, genus_only)
Expect(setequal(names(res), c('adat', 'genus_only', 'species', 'genus', 'n_species_replaced', 'n_genus_replaced')),
       'returns the species records, the genus-only rows, the two halves of the Sheet and the replacement counts')
a <- res$adat
gm <- a[!is.na(a$taxon) & a$taxon == 'Gadus_morhua', ]
Expect(nrow(gm) == 1 && gm$mass_g == 1000 && gm$source_mass == 'SheetA' && gm$n == 1,
       'a Sheet species row replaces every compiled record of the species (both sources\' records gone)')
Expect(Same(a[is.na(a$taxon) | a$taxon != 'Gadus_morhua', names(adat_raw)], adat_raw[is.na(adat_raw$taxon) | adat_raw$taxon != 'Gadus_morhua', ]),
       'the source records of every other species, the NA name included, are untouched and in their order')
Expect(all(grepl('_', a$taxon[!is.na(a$taxon)], fixed = TRUE)), 'no genus-level Sheet row enters the species path')
Expect(a$taxon[1] == 'Gadus_morhua' && is.na(gm$dataset) && all(is.na(gm[, sheet_hint_columns])),
       'the Sheet row comes first; the columns the Sheet lacks (the frames\' own, the hints) are NA in it')
Expect(all(c('Lepidostoma_hirtum', 'Hypopomus_artedi') %in% a$taxon) &&
         identical(a$mass_g[!is.na(a$taxon) & a$taxon == 'Lepidostoma_hirtum'], c(6e-4, 7e-4)) &&
         a$mass_g[!is.na(a$taxon) & a$taxon == 'Hypopomus_artedi'] == 500,
       'a Sheet genus row leaves the species-level values of the genus alone (Lepidostoma_hirtum, Hypopomus_artedi)')
g <- res$genus_only
lp <- g[g$taxon == 'Lepidostoma', ]
Expect(nrow(lp) == 1 && lp$mass_g == 0.0028 && lp$source_mass == 'Nakagawa_2014',
       'a Sheet genus row replaces the sources\' genus-only rows of that bare name (Brose_etal_2018 and SrcD gone)')
hp <- g[g$taxon == 'Hypopomus', ]
Expect(nrow(hp) == 1 && hp$mass_g == 588 && hp$source_mass == 'Froese_2025; Froese_2014', 'Hypopomus: the source row replaced by the Sheet row')
Expect(sum(g$taxon == 'Evermannella') == 1 && g$mass_g[g$taxon == 'Evermannella'] == 28.9, 'a bare name no source carries is added')
Expect(Same(g[g$taxon %in% c('Caroperla', 'Staphylinidae'), names(genus_only)], genus_only[genus_only$taxon %in% c('Caroperla', 'Staphylinidae'), ]) &&
         g$class[g$taxon == 'Caroperla'] == 'Insecta',
       'the other bare names keep their rows, order and classification hints')
Expect(identical(g$taxon[1:3], c('Lepidostoma', 'Hypopomus', 'Evermannella')) && all(sheet_row_columns %in% names(g)),
       'the Sheet rows come first and the genus-only rows carry the columns section 5b expects')
Expect(all(g$n[1:3] == 1) && all(is.na(g[1:3, sheet_hint_columns])), 'the Sheet genus rows carry n = 1 and no hints (resolution at genus rank without a classification)')
Expect(!any(g$taxon %in% c('Gadus_morhua', 'Lepidostoma_hirtum')), 'no species-level row enters the genus-only path')
Expect(res$n_species_replaced == 1 && res$n_genus_replaced == 2,
       'one Sheet species and two Sheet genera had source rows to replace (Evermannella is an addition)')
Expect(identical(res$species$taxon, 'Gadus_morhua') && identical(res$genus$taxon, c('Lepidostoma', 'Hypopomus', 'Evermannella')),
       'the two halves of the Sheet are returned')
Expect(nrow(a) == nrow(adat_raw) - 2 + 1 && nrow(g) == nrow(genus_only) - 4 + 3, 'row counts: records replaced and rows added')
Expect(is.double(a$n) && is.double(g$n) && all(a$n == 1) && all(g$n == 1), 'n is 1 in every row (double, as bind_rows() made it before #57)')

# ---- edge cases ------------------------------------------------------------------
cat('edge cases\n')
e <- ApplySheetOverride(ddat[0, ], adat_raw, genus_only)
Expect(Same(e$adat, adat_raw) && Same(e$genus_only, genus_only) && nrow(e$species) == 0 && nrow(e$genus) == 0 &&
         e$n_species_replaced == 0 && e$n_genus_replaced == 0,
       'no Sheet rows: both inputs come back unchanged')
s <- ApplySheetOverride(ddat[ddat$taxon == 'Gadus_morhua', ], adat_raw, genus_only)
Expect(Same(s$genus_only, genus_only) && sum(!is.na(s$adat$taxon) & s$adat$taxon == 'Gadus_morhua') == 1,
       'species rows only: the genus-only rows are untouched')
o <- ApplySheetOverride(Sheet('Osmerus', 25, 'SheetB'), adat_raw, genus_only)
Expect(Same(o$adat, adat_raw) && o$n_genus_replaced == 0 && nrow(o$genus_only) == nrow(genus_only) + 1 && o$genus_only$taxon[1] == 'Osmerus',
       'a Sheet genus row for a genus the sources hold only as species values: the species records are untouched, the row is added to the genus-only path')
d2 <- Sheet(c('Lepidostoma', 'Lepidostoma'), c(0.002, 0.003), c('SrcX', 'SrcY'))
t2 <- ApplySheetOverride(d2, adat_raw, genus_only)
Expect(sum(t2$genus_only$taxon == 'Lepidostoma') == 2 && t2$n_genus_replaced == 1,
       'two Sheet rows of one bare name both enter (Pass 1 of section 5b combines them per source); the name counts once')
Expect(Has(ErrorOf(ApplySheetOverride(data.frame(taxon = 'Gadus_morhua', mass_g = 1), adat_raw, genus_only)), 'columns taxon, mass_g and source_mass'),
       'a Sheet frame without the three columns stops with a pointer')
Expect(Has(ErrorOf(ApplySheetOverride(ddat, adat_raw, list())), 'genus-only source rows'), 'the source rows must be data frames with a taxon column')
Expect(nrow(BindRowsFill(adat_raw[0, ], genus_only)) == nrow(genus_only) && nrow(BindRowsFill(genus_only, adat_raw[0, ])) == nrow(genus_only),
       'BindRowsFill(): an empty side returns the other')
bf <- BindRowsFill(data.frame(a = 'x', stringsAsFactors = FALSE), data.frame(a = 'y', b = 2, stringsAsFactors = FALSE))
Expect(identical(bf$a, c('x', 'y')) && identical(bf$b, c(NA_real_, 2)), 'BindRowsFill(): a column one side lacks is NA in its rows')

# ---- wiring in RunMe.r --------------------------------------------------------------
cat('R/RunMe.r wiring\n')
runme   <- readLines(file.path(repo, 'R', 'RunMe.r'))
i_src   <- grep("^source\\(file\\.path\\(wd_root, 'R', 'library', 'sheet_override\\.r'\\)\\)", runme)
i_split <- grep("^genus_only <- adat_raw\\[!grepl\\('_', adat_raw\\$taxon\\), \\]", runme)
i_check <- grep('^ddat <- CheckSheetTaxa\\(ddat\\)', runme)
i_norm  <- grep('^ddat\\$source_mass <- NormaliseSourceLabel\\(ddat\\$source_mass\\)', runme)
i_call  <- grep('^sheet      <- ApplySheetOverride\\(ddat, adat_raw, genus_only\\)', runme)
i_adat  <- grep('^adat       <- sheet\\$adat$', runme)
i_go    <- grep('^genus_only <- sheet\\$genus_only$', runme)
i_5     <- grep('^# 5\\. Enrich unique taxa', runme)
i_label <- grep('^genus_only\\$source_label <- SourceLabel\\(genus_only\\$source_mass\\)', runme)
i_res   <- grep('^genus_cache <- ResolveGenusNames\\(genus_only, genus_cache, enrich_cache\\)', runme)
Expect(length(i_src) == 1 && length(i_call) == 1 && length(i_adat) == 1 && length(i_go) == 1,
       'RunMe.r sources sheet_override.r and applies the override once, taking both the species records and the genus-only rows from it')
Expect(all(lengths(list(i_split, i_check, i_norm, i_5)) == 1) && i_split < i_check && i_check < i_norm && i_norm < i_call &&
         i_call < i_adat && i_adat < i_go && i_go < i_5,
       'the call follows the section-3 split, CheckSheetTaxa() and the label normalisation, and precedes section 5')
Expect(length(i_label) == 1 && length(i_res) == 1 && i_go < i_label && i_label < i_res,
       'the genus-only path (labels, groups, resolution at genus rank) starts after the Sheet rows have joined it')
Expect(!any(grepl('^adat <- bind_rows\\(ddat\\[|^sel  <- adat_raw\\$taxon %!in% ddat\\$taxon', runme)),
       'the old bind of every Sheet row into the species path is gone')
# the species enrichment cache: bare names cannot reach it any more, and the
# rows earlier runs left there (Hypopomus -> Hypopomus artedi) are dropped
i_load  <- grep('^  load\\(cache_path\\)', runme)
i_stale <- grep("^  stale_bare <- !grepl\\('_', enrich_cache\\$taxon, fixed = TRUE\\)", runme)
i_drop  <- grep('^    enrich_cache <- enrich_cache\\[!stale_bare, \\]', runme)
i_save  <- grep('^save\\(enrich_cache, genus_cache, file = cache_path\\)', runme)
Expect(length(i_load) == 1 && length(i_stale) == 1 && length(i_drop) == 1 && length(i_save) >= 1 &&
         i_load < i_stale && i_stale < i_drop && i_drop < min(i_save) && min(i_save) < i_res,
       'stale bare names are dropped from the species cache after it is loaded and before it is saved and CacheGenera() reads it')

# ---- summary -------------------------------------------------------------------
cat(sprintf('\n%d expectations, %d failed\n', n_checks, length(failures)))
if (length(failures) > 0) {
  cat(paste0('  FAIL: ', failures, '\n'), sep = '')
  quit(status = 1)
}
