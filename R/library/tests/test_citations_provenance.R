# Tests for the offline provenance layer of the citation tooling (issue #1):
# R/library/citations/provenance.r, the part RunMe.r sources. The registry
# loader runs on the tracked Bib/source_provenance_classes.csv and on
# synthetic registries; LoadPrimaryReferences() on a temporary source tree;
# SplitSourceMass() against the conversion CiteIDs of mass_conversion.r;
# BuildProvenance() on synthetic records covering lab-Sheet rows, keyed
# records (resolved, pending, unmatched, self, a compilation reference), hop 2
# through a reference that is itself a database source,
# keyless records (registry defaults, an allometry equation, a primary
# source, a prov_type override) and conversion factors; CheckCitations() and
# WriteCitationsReport(); and the wiring in RunMe.r / enrich_genus.r. Base R
# only, no network.
#
#   Rscript R/library/tests/test_citations_provenance.R      (from any directory)
#
# Prints one line per expectation and exits with status 1 if any failed.

this_file <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE))
if (length(this_file) == 0)
  this_file <- file.path('R', 'library', 'tests', 'test_citations_provenance.R')
repo <- normalizePath(file.path(dirname(this_file), '..', '..', '..'))
lib  <- file.path(repo, 'R', 'library')
source(file.path(lib, 'helpers.r'))
source(file.path(lib, 'mass_conversion.r'))
source(file.path(lib, 'dedupe_sources.r'))
for (f in c('citations_config.r', 'normalise_citation.r', 'parse_reflists.r', 'build_bib.r', 'provenance.r'))
  source(file.path(lib, 'citations', f))

failures <- character(0)
n_checks <- 0L
Expect <- function(ok, what) {
  n_checks <<- n_checks + 1L
  if (!isTRUE(ok)) failures <<- c(failures, what)
  cat(sprintf('  %s %s\n', if (isTRUE(ok)) 'ok  ' else 'FAIL', what))
}
ErrorOf <- function(expr) tryCatch({ expr; NULL }, error = function(e) conditionMessage(e))
MessagesOf <- function(expr) { m <- character(); withCallingHandlers(expr, message = function(c) { m <<- c(m, conditionMessage(c)); invokeRestart('muffleMessage') }); m }
WarningOf <- function(expr) tryCatch({ expr; NULL }, warning = function(w) conditionMessage(w))
Has <- function(x, pattern) !is.null(x) && length(x) > 0 && any(grepl(pattern, x, fixed = TRUE))

# ---- the registry -------------------------------------------------------------------------------
cat('LoadProvenanceClasses()\n')
reg_path <- file.path(repo, 'Bib', 'source_provenance_classes.csv')
raw <- read.csv(reg_path, stringsAsFactors = FALSE, colClasses = 'character', na.strings = c('', 'NA'))
msgs <- MessagesOf(reg <- LoadProvenanceClasses(reg_path, raw$source_label))
Expect(nrow(reg) == 90 && identical(names(reg), provenance_class_columns) && !anyDuplicated(reg$source_label),
       'the tracked registry loads: 90 labels, the schema columns, unique labels')
tab <- table(reg$class)
Expect(tab[['compilation']] == 57 && tab[['primary']] == 18 && tab[['live']] == 8 && tab[['derived']] == 5 && tab[['database']] == 2 && all(names(tab) %in% provenance_classes),
       'class counts: compilation 57, primary 18, live 8, derived 5, database 2')
Expect(all(reg$default_provenance_type %in% provenance_types) &&
         all(reg$default_provenance_type[reg$class == 'primary'] == 'measured_in_source') &&
         all(reg$default_provenance_type[reg$class == 'derived'] == 'derived_allometry') &&
         all(reg$default_provenance_type[reg$class == 'live'] == 'database_record'),
       'default types follow the class: primary -> measured_in_source, derived -> derived_allometry, live -> database_record')
Expect(reg$equation_bibcite[reg$source_label == 'Feldman_etal_2016'] == 'Feldman:2016aa' && reg$equation_bibcite[reg$source_label == 'Meiri_2018'] == 'Feldman:2016aa' &&
         Has(msgs, 'derived source(s) without an equation_bibcite yet') && Has(msgs, 'Brocher_etal_2025') && Has(msgs, 'Hishi_etal_2019'),
       'the Feldman equation is registered for Feldman_etal_2016 and Meiri_2018; Brocher and Hishi are reported as lacking one')
Expect(all(c('fishbase', 'sealifebase', 'vertnet-aves-sept2016', 'Myhrvold_2015', 'Jones_2009', 'Raymond_2011', 'Ernest_2003', 'Brose_2005', 'McCoy_2008', 'GuoBailly_2024') %in% reg$source_label),
       'the live, DataRetriever and recently added labels are registered')
Expect(Has(ErrorOf(LoadProvenanceClasses(reg_path, c(raw$source_label, 'NoSuch_2099'))), 'not registered') &&
         Has(ErrorOf(LoadProvenanceClasses(reg_path, c(raw$source_label, 'NoSuch_2099'))), 'NoSuch_2099'),
       'an unregistered source label stops the run and is named')
m2 <- MessagesOf(LoadProvenanceClasses(reg_path, raw$source_label[1:10]))
Expect(Has(m2, 'registered label(s) not in the source frames of this run'), 'a registered label absent from the frames is reported, not fatal')
WriteReg <- function(d) { f <- tempfile(fileext = '.csv'); write.csv(d, f, row.names = FALSE, na = ''); f }
Reg <- function(...) data.frame(..., stringsAsFactors = FALSE)
Expect(Has(ErrorOf(LoadProvenanceClasses(WriteReg(Reg(source_label = 'A', class = 'secondary', default_provenance_type = 'unknown', equation_bibcite = NA, notes = NA)), 'A')), 'unknown class'),
       'an unknown class stops')
Expect(Has(ErrorOf(LoadProvenanceClasses(WriteReg(Reg(source_label = 'A', class = 'primary', default_provenance_type = 'measured', equation_bibcite = NA, notes = NA)), 'A')), 'unknown default_provenance_type'),
       'an unknown default_provenance_type stops')
Expect(Has(ErrorOf(LoadProvenanceClasses(WriteReg(Reg(source_label = c('A', 'A'), class = 'primary', default_provenance_type = 'measured_in_source', equation_bibcite = NA, notes = NA)), 'A')), 'duplicated label'),
       'a duplicated label stops')
Expect(Has(ErrorOf(LoadProvenanceClasses(WriteReg(Reg(source_label = 'A', class = 'primary')), 'A')), 'lacks column') && Has(ErrorOf(LoadProvenanceClasses(tempfile(), 'A')), 'not found'),
       'a registry without the schema or a missing file stops')

# ---- source_mass ----------------------------------------------------------------------------------
cat('SplitSourceMass(), KnownConversionCiteIDs()\n')
known <- KnownConversionCiteIDs()
Expect(all(c('Kiorboe_2013', 'Lucas_2011', 'Brey_2010', 'Studier_1992', 'MendenDeuer_2000', 'Horn_2016', 'Rizzuto_2019') %in% known), 'the conversion CiteIDs come from MassConversionFactors')
Expect(identical(ConversionCiteIDs(c('bird', 'mammal', 'vertebrate')), c('Horn_2016', 'Rizzuto_2019', '')) &&
         identical(LabelWithConversion('Gonzalez_2025', c('bird', 'mammal', 'vertebrate')),
                   c('Gonzalez_2025; Horn_2016', 'Gonzalez_2025; Rizzuto_2019', 'Gonzalez_2025')) &&
         isTRUE(all.equal(ToWetMass(c(0.3906, 0.2925, 0.25), from = 'dry', group = c('bird', 'mammal', 'vertebrate')), c(1, 1, 1))) &&
         isTRUE(all.equal(ToWetMass(0.3906 * 0.8527, from = 'afdw', group = 'bird'), 1)),
       'the bird (Horn 2016) and mammal (Rizzuto 2019) groups convert and cite; the generic vertebrate group stays uncited (#86)')
sm <- SplitSourceMass(c('Kiorboe_2013; Brey_2010', 'Smith_2003', 'Hebert_etal_2016; Kiorboe_2013; Lucas_2011', 'X; Brey_2010; Brey_2010', NA), known)
Expect(identical(sm$label, c('Kiorboe_2013', 'Smith_2003', 'Hebert_etal_2016', 'X', NA)) &&
         identical(sm$conversion, c('Brey_2010', NA, 'Kiorboe_2013; Lucas_2011', 'Brey_2010', NA)),
       'the first token is the label, the rest the distinct conversion CiteIDs joined with ;')
w <- WarningOf(SplitSourceMass(c('Kiorboe_2013; Nobody_1999'), known))
Expect(Has(w, 'not conversion CiteIDs') && Has(w, 'Nobody_1999') && is.null(WarningOf(SplitSourceMass('Kiorboe_2013; Brey_2010', known))) &&
         is.null(WarningOf(SplitSourceMass('Kiorboe_2013; Nobody_1999'))),
       'a token that is no conversion CiteID warns (and is kept); no check without the known set')

# ---- primary_references files --------------------------------------------------------------------------
cat('LoadPrimaryReferences()\n')
db <- tempfile('db'); dir.create(db)
Expect(nrow(LoadPrimaryReferences(db)) == 0 && identical(names(LoadPrimaryReferences(db)), primary_reference_columns), 'no files: the empty frame with the schema')
P <- function(label, keys, status = NA, doi = NA, bibcite = NA, cite_id = NA, role = 'measurement', reason = NA) {
  d <- EmptyPrimaryReferences()
  d[seq_along(keys), 'native_key'] <- keys
  d$source_label <- label; d$match_status <- status; d$doi <- doi; d$bibcite <- bibcite; d$cite_id <- cite_id; d$role <- role; d$match_reason <- reason
  d$raw_citation <- paste('citation', keys); d$n_records <- seq_along(keys)
  d
}
WritePrimaryReferences(P('SrcA', c('1', '2'), status = c('certain', 'pending'), doi = c('10.1/a', NA)), PrimaryReferencesPath(db, 'SrcA'))
WritePrimaryReferences(P('SrcB', c('1', 'S'), status = c('approved', 'self'), bibcite = c('Manual:2000aa', NA), role = c('measurement', 'self')), PrimaryReferencesPath(db, 'SrcB'))
all <- LoadPrimaryReferences(db)
Expect(nrow(all) == 4 && identical(sort(unique(all$source_label)), c('SrcA', 'SrcB')) && is.integer(all$n_records) && is.logical(all$author_match) &&
         all$match_status[all$source_label == 'SrcB' & all$native_key == 'S'] == 'self',
       'the per-source files are bound with their column types; the same key in two sources is fine')
WritePrimaryReferences(P('SrcA', '9'), PrimaryReferencesPath(db, 'SrcC'))
Expect(Has(ErrorOf(LoadPrimaryReferences(db)), 'every row needs a source_label') == FALSE && nrow(LoadPrimaryReferences(db)) == 5,
       'a file in another folder is accepted when its source_label is set')
WritePrimaryReferences(P('SrcA', '1'), PrimaryReferencesPath(db, 'SrcD'))
Expect(Has(ErrorOf(LoadPrimaryReferences(db)), 'duplicated (source_label, native_key)') && Has(ErrorOf(LoadPrimaryReferences(db)), 'SrcA 1'),
       'the same (source_label, native_key) twice stops')
unlink(file.path(db, c('SrcC', 'SrcD')), recursive = TRUE)
WritePrimaryReferences(P('SrcE', '1', status = 'maybe'), PrimaryReferencesPath(db, 'SrcE'))
Expect(Has(ErrorOf(LoadPrimaryReferences(db)), 'unknown match_status maybe'), 'an unknown match_status stops')
WritePrimaryReferences(P('SrcE', '1', status = 'certain', doi = '10.1/e', role = 'author'), PrimaryReferencesPath(db, 'SrcE'))
Expect(Has(ErrorOf(LoadPrimaryReferences(db)), 'unknown role author'), 'an unknown role stops')
WritePrimaryReferences(P('SrcE', '1', status = 'certain'), PrimaryReferencesPath(db, 'SrcE'))
Expect(Has(ErrorOf(LoadPrimaryReferences(db)), 'without a DOI or a manual bibcite') && Has(ErrorOf(LoadPrimaryReferences(db)), 'SrcE 1'),
       'a certain row without a DOI (and no manual bibcite) stops')
unlink(file.path(db, 'SrcE'), recursive = TRUE)
Expect(nrow(LoadPrimaryReferences(db)) == 4, 'back to the two valid files')

# ---- the provenance table --------------------------------------------------------------------------------
cat('BuildProvenance()\n')
classes <- Reg(source_label = c('Comp', 'Prim', 'Deriv', 'Term', 'Hech', 'NoEq'),
               class = c('compilation', 'primary', 'derived', 'compilation', 'primary', 'derived'),
               default_provenance_type = c('unknown', 'measured_in_source', 'derived_allometry', 'compilation_terminal', 'measured_in_source', 'derived_allometry'),
               equation_bibcite = c(NA, NA, 'Eq:2016aa', NA, NA, NA), notes = NA)
citeids <- Reg(CiteID = c('Comp', 'Prim', 'Deriv', 'Term', 'Hech', 'NoEq', 'Eq_2016', 'Brey_2010', 'Doyle_2007'),
               Bibcite = c('Comp:2013aa', 'Prim:2020aa', 'Deriv:2016aa', 'Term:2010aa', 'Hech:2011aa', 'NoEq:2019aa', 'Eq:2016aa', 'Brey:2010aa', 'Doyle:2007aa'),
               doi = c(NA, '10.1/prim', NA, NA, NA, NA, NA, '10.1/brey', '10.1/doyle'))
prim <- P('Comp', c('1', '2', 'S', '3'), status = c('certain', 'pending', 'self', 'approved'), doi = c('10.1/doyle', NA, NA, NA),
          bibcite = c('Doyle:2007aa', NA, NA, 'Term:2010aa'), cite_id = c('Doyle_2007', NA, NA, 'Term'),
          role = c('measurement', 'measurement', 'self', 'compilation'), reason = c('two_service_agreement', 'weak_match', 'self', 'manual_bib'))
R <- function(genus, species, label, origin = 'pipeline', ref_keys = NA, conversion_ids = NA, prov_type = NA)
  data.frame(genus = genus, species = species, taxon = paste(genus, species), source_label = label, origin = origin,
             ref_keys = ref_keys, conversion_ids = conversion_ids, prov_type = prov_type, stringsAsFactors = FALSE)
records <- rbind(R('Aa', 'bb', 'LabX', origin = 'BM_data'), R('Aa', 'bb', 'LabX', origin = 'BM_data'),
                 R('Aa', 'bb', 'Comp', ref_keys = '1'), R('Aa', 'bb', 'Comp', ref_keys = '1; 2'), R('Aa', 'bb', 'Comp', ref_keys = '99'),
                 R('Aa', 'bb', 'Comp', ref_keys = 'S'), R('Aa', 'bb', 'Comp', ref_keys = '3'),
                 R('Cc', 'dd', 'Comp'), R('Cc', 'dd', 'Deriv'), R('Cc', 'dd', 'NoEq'), R('Cc', 'dd', 'Prim'), R('Cc', 'dd', 'Hech', prov_type = 'compiled_from'),
                 R('Ee', 'ff', 'Comp', conversion_ids = 'Brey_2010'), R('Ee', 'ff', 'Comp', conversion_ids = 'Brey_2010; Lucas_2011'),
                 R('Gg', 'hh', 'Comp', ref_keys = '1'), R('Ii', NA, 'Comp', ref_keys = '1'))
accepted <- Reg(genus = c('Aa', 'Cc', 'Ee'), species = c('bb', 'dd', 'ff'))
prov <- BuildProvenance(records, prim, classes, citeids, accepted)
Expect(identical(names(prov), provenance_columns) && is.integer(prov$hop) && is.integer(prov$n_records) && nrow(prov) == 14,
       sprintf('the table has the schema columns and %d rows', nrow(prov)))
Expect(!any(prov$genus %in% c('Gg', 'Ii')) && all(paste(prov$genus, prov$species) %in% paste(accepted$genus, accepted$species)),
       'species outside the accepted table and records without a species are dropped')
Expect(identical(prov$genus, sort(prov$genus, method = 'radix')) && identical(prov$provenance_type[prov$genus == 'Aa'], sort(prov$provenance_type[prov$genus == 'Aa'], method = 'radix')[order(order(prov$provenance_type[prov$genus == 'Aa'], method = 'radix'))]),
       'rows are ordered by genus, species, label, origin, hop, type')
sheet <- prov[prov$origin == 'BM_data', ]
Expect(nrow(sheet) == 1 && sheet$source_mass == 'LabX' && is.na(sheet$source_bibcite) && sheet$provenance_type == 'measured_in_source' && sheet$hop == 0L &&
         sheet$n_records == 2L && is.na(sheet$primary_cite_id) && is.na(sheet$ref_role),
       'lab-Sheet rows: one row per species x label, measured_in_source at hop 0, counting the records')
K <- function(key_status) prov[prov$genus == 'Aa' & prov$origin == 'pipeline' & prov$match_status %in% key_status, ]
k1 <- K('certain')
Expect(nrow(k1) == 1 && k1$source_mass == 'Comp' && k1$source_bibcite == 'Comp:2013aa' && k1$provenance_type == 'compiled_from' && k1$hop == 1L && k1$ref_role == 'measurement' &&
         k1$primary_cite_id == 'Doyle_2007' && k1$primary_bibcite == 'Doyle:2007aa' && k1$primary_doi == '10.1/doyle' && k1$n_records == 2L,
       'a resolved measurement reference: compiled_from, hop 1, the primary CiteID / bibcite / DOI, two records')
k2 <- K('pending')
Expect(nrow(k2) == 1 && k2$provenance_type == 'compiled_from' && k2$ref_role == 'measurement' && is.na(k2$primary_cite_id) && is.na(k2$primary_bibcite) && k2$n_records == 1L,
       'a pending reference keeps its type and role but no primary citation yet')
k99 <- K('unmatched_key')
Expect(nrow(k99) == 1 && k99$provenance_type == 'unknown' && is.na(k99$ref_role) && is.na(k99$primary_cite_id) && k99$hop == 1L,
       'a key the reference list lacks: unknown / unmatched_key')
ks <- K('self')
Expect(nrow(ks) == 1 && ks$provenance_type == 'measured_in_source' && ks$hop == 0L && ks$ref_role == 'self' && ks$primary_cite_id == 'Comp' && ks$primary_bibcite == 'Comp:2013aa' && is.na(ks$primary_doi),
       'a self reference points at the source itself at hop 0')
k3 <- K('approved')
Expect(nrow(k3) == 1 && k3$provenance_type == 'compilation_terminal' && k3$hop == 1L && k3$ref_role == 'compilation' && k3$primary_cite_id == 'Term' && k3$primary_bibcite == 'Term:2010aa',
       'an approved reference with role compilation: compilation_terminal citing the intermediate')
D <- function(label) prov[prov$genus == 'Cc' & prov$source_mass == label, ]
Expect(nrow(D('Comp')) == 1 && D('Comp')$provenance_type == 'unknown' && D('Comp')$hop == 1L && is.na(D('Comp')$primary_cite_id) && is.na(D('Comp')$match_status),
       "a keyless record of a compilation: the registry default 'unknown'")
Expect(nrow(D('Deriv')) == 1 && D('Deriv')$provenance_type == 'derived_allometry' && D('Deriv')$ref_role == 'equation' && D('Deriv')$primary_bibcite == 'Eq:2016aa' &&
         D('Deriv')$primary_cite_id == 'Eq_2016' && D('Deriv')$hop == 1L,
       'a derived source: derived_allometry with the registered equation as the reference')
Expect(nrow(D('NoEq')) == 1 && D('NoEq')$provenance_type == 'derived_allometry' && is.na(D('NoEq')$ref_role) && is.na(D('NoEq')$primary_bibcite),
       'a derived source without an equation_bibcite yet: no equation reference')
Expect(nrow(D('Prim')) == 1 && D('Prim')$provenance_type == 'measured_in_source' && D('Prim')$hop == 0L && D('Prim')$ref_role == 'self' && D('Prim')$primary_cite_id == 'Prim' &&
         D('Prim')$primary_bibcite == 'Prim:2020aa' && D('Prim')$primary_doi == '10.1/prim' && D('Prim')$match_status == 'self',
       'a primary source: measured_in_source citing itself (with its DOI)')
Expect(nrow(D('Hech')) == 1 && D('Hech')$provenance_type == 'compiled_from' && D('Hech')$hop == 1L && is.na(D('Hech')$ref_role),
       'a record-level prov_type overrides the registry default')
cv <- prov[prov$genus == 'Ee', ]
Expect(nrow(cv) == 3 && sum(cv$provenance_type == 'conversion_factor') == 2 && sum(cv$provenance_type == 'unknown') == 1 &&
         cv$n_records[cv$provenance_type == 'unknown'] == 2L,
       'conversion CiteIDs give one conversion_factor row each beside the default row')
brey <- cv[cv$primary_cite_id %in% 'Brey_2010', ]
Expect(nrow(brey) == 1 && brey$hop == 0L && brey$ref_role == 'conversion' && brey$primary_bibcite == 'Brey:2010aa' && brey$primary_doi == '10.1/brey' && brey$n_records == 2L &&
         cv$n_records[cv$primary_cite_id %in% 'Lucas_2011'] == 1L && is.na(cv$primary_bibcite[cv$primary_cite_id %in% 'Lucas_2011']),
       'a conversion row: hop 0, role conversion, the CiteID resolved to its bibcite and DOI, records counted per CiteID')
# a derived source with keyed records (Meiri_2018, Stage 2): the length
# sources are measurement rows typed derived_allometry, the equation row is
# written beside them per species, an unmatched key stays unknown, a pending
# key has no primary citation, and a prov_type override gets no equation row
prim_d <- rbind(prim, P('Deriv', c('L1', 'L2', 'L3', 'OWN'), status = c('certain', 'pending', 'certain', 'self'), doi = c('10.1/l1', NA, '10.1/doyle', NA),
                        bibcite = c('L1:2001aa', NA, 'Doyle:2007aa', NA), cite_id = c('L1_2001', NA, 'Doyle_2007', NA),
                        role = c('measurement', 'measurement', 'measurement', 'self'), reason = c('two_service_agreement', 'weak_match', 'two_service_agreement', 'owner_self')))
rec_d <- rbind(R('Mm', 'nn', 'Deriv', ref_keys = 'L1; L2'), R('Mm', 'nn', 'Deriv', ref_keys = 'L1; 99'), R('Uu', 'vv', 'Deriv', ref_keys = 'OWN'),
               R('Oo', 'pp', 'Deriv', ref_keys = 'L3'), R('Qq', 'rr', 'Deriv', ref_keys = 'L1', prov_type = 'compiled_from'),
               R('Ss', 'tt', 'NoEq', ref_keys = 'L1'))
prov_d <- BuildProvenance(rec_d, prim_d, classes, citeids, Reg(genus = c('Mm', 'Oo', 'Qq', 'Ss', 'Uu'), species = c('nn', 'pp', 'rr', 'tt', 'vv')))
du <- prov_d[prov_d$genus == 'Uu', ]
Expect(nrow(du) == 2 && all(du$provenance_type == 'derived_allometry') && du$primary_cite_id[du$ref_role == 'self'] == 'Deriv' && du$match_status[du$ref_role == 'self'] == 'self' && du$hop[du$ref_role == 'self'] == 1L && sum(du$ref_role == 'equation') == 1,
       "a self reference of a derived source: derived_allometry citing the source itself, beside the equation row")
dm <- prov_d[prov_d$genus == 'Mm', ]
Expect(nrow(dm) == 4 && sum(dm$ref_role %in% 'equation') == 1 && sum(dm$ref_role %in% 'measurement') == 2 && sum(dm$match_status %in% 'unmatched_key') == 1,
       'a derived source with keys: two measurement rows, one unmatched key, one equation row per species')
de <- dm[dm$ref_role %in% 'equation', ]
Expect(de$provenance_type == 'derived_allometry' && de$primary_bibcite == 'Eq:2016aa' && de$primary_cite_id == 'Eq_2016' && de$n_records == 2L && de$hop == 1L && is.na(de$match_status),
       'the equation row counts the two records and cites the registered equation')
d1 <- dm[dm$primary_cite_id %in% 'L1_2001', ]
Expect(nrow(d1) == 1 && d1$provenance_type == 'derived_allometry' && d1$ref_role == 'measurement' && d1$match_status == 'certain' && d1$primary_doi == '10.1/l1' && d1$n_records == 2L,
       'a resolved length source: derived_allometry, role measurement, the primary citation, two records')
d2 <- dm[dm$match_status %in% 'pending', ]
Expect(nrow(d2) == 1 && d2$provenance_type == 'derived_allometry' && d2$ref_role == 'measurement' && is.na(d2$primary_cite_id) && d2$n_records == 1L,
       'a pending length source keeps the derived type and role without a primary citation')
Expect(dm$provenance_type[dm$match_status %in% 'unmatched_key'] == 'unknown' && is.na(dm$ref_role[dm$match_status %in% 'unmatched_key']),
       'an unmatched key of a derived source stays unknown')
do <- prov_d[prov_d$genus == 'Oo', ]
Expect(nrow(do) == 2 && all(do$provenance_type == 'derived_allometry') && !any(do$provenance_type %in% c('compiled_via_compilation', 'compilation_terminal')) && do$primary_cite_id[do$ref_role == 'measurement'] == 'Doyle_2007',
       'a length source that resolves to a database label is not followed to a second hop under a derived source')
dq <- prov_d[prov_d$genus == 'Qq', ]
Expect(nrow(dq) == 1 && dq$provenance_type == 'compiled_from' && dq$ref_role == 'measurement' && dq$primary_cite_id == 'L1_2001',
       'a record-level prov_type override on a derived source: the override, no equation row')
ds <- prov_d[prov_d$genus == 'Ss', ]
Expect(nrow(ds) == 1 && ds$provenance_type == 'unknown' && ds$match_status == 'uningested',
       'a derived source without an equation_bibcite and without a reference list: no equation row, the key uningested')
Expect(nrow(BuildProvenance(records, prim, classes, citeids, accepted[0, ])) == 0 && identical(names(BuildProvenance(records, prim, classes, citeids, accepted[0, ])), provenance_columns),
       'no accepted species: the empty table')
Expect(Has(ErrorOf(BuildProvenance(records[, -5], prim, classes, citeids, accepted)), 'records lack column'), 'records without origin stop')
min_rec <- records[, c('genus', 'species', 'taxon', 'source_label', 'origin')]
Expect(nrow(BuildProvenance(min_rec, prim, classes, citeids, accepted)) == 8 && all(BuildProvenance(min_rec, prim, classes, citeids, accepted)$provenance_type[BuildProvenance(min_rec, prim, classes, citeids, accepted)$source_mass == 'Comp'] == 'unknown'),
       'records without ref_keys / conversion_ids / prov_type columns work (registry defaults only)')
un <- BuildProvenance(records, EmptyPrimaryReferences(), classes, citeids, accepted)
Expect(nrow(un) == 14 && all(un$match_status[un$genus == 'Aa' & un$origin == 'pipeline'] == 'uningested') &&
         sum(un$match_status %in% 'uningested') == 5 && !any(un$match_status %in% 'unmatched_key'),
       "without a primary_references.csv for the source every key is 'uningested', not 'unmatched_key'")
Expect(all(c('unmatched_key', 'uningested') %in% provenance_only_statuses) && !any(provenance_only_statuses %in% match_statuses), 'the provenance-only statuses are not reference statuses')

# ---- hop 2: a reference that is itself a database source ----------------------------------------------------
cat('BuildProvenance() hop 2\n')
# Comp2 cites C (resolved by DOI to the label Inter, whose curated entry carries that DOI), B (resolved by bib key to
# the label Term2, a label without a primary_references.csv) and M (an ordinary measurement). Inter's own records: for
# Aa bb the keys i1 (certain, Doyle) and i2 (pending); for Cc dd the key iS (self); none for Ee ff.
classes2 <- rbind(classes, Reg(source_label = c('Comp2', 'Inter', 'Term2'), class = 'compilation', default_provenance_type = 'unknown', equation_bibcite = NA, notes = NA))
citeids2 <- rbind(citeids, Reg(CiteID = c('Comp2', 'Inter', 'Term2', 'Other_1999'), Bibcite = c('Comp2:2022aa', 'Inter:2007aa', 'Term2:2010aa', 'Other:1999aa'),
                               doi = c('10.1/comp2', '10.1/INTER', NA, '10.1/other')))
prim2 <- rbind(P('Comp2', c('C', 'B', 'M'), status = c('certain', 'approved', 'certain'), doi = c('10.1/inter', NA, '10.1/other'),
                 bibcite = c(NA, 'Term2:2010aa', NA), cite_id = c(NA, NA, 'Other_1999'), reason = c('doi_resolves', 'manual_bib', 'two_service_agreement')),
               P('Inter', c('i1', 'i2', 'iS'), status = c('certain', 'pending', 'self'), doi = c('10.1/doyle', NA, NA),
                 bibcite = c('Doyle:2007aa', NA, NA), cite_id = c('Doyle_2007', NA, NA), role = c('measurement', 'measurement', 'self')))
records2 <- rbind(R('Aa', 'bb', 'Comp2', ref_keys = 'C'), R('Aa', 'bb', 'Comp2', ref_keys = 'C'), R('Aa', 'bb', 'Comp2', ref_keys = 'M'),
                  R('Aa', 'bb', 'Inter', ref_keys = 'i1; i2'),
                  R('Cc', 'dd', 'Comp2', ref_keys = 'C'), R('Cc', 'dd', 'Inter', ref_keys = 'iS'),
                  R('Ee', 'ff', 'Comp2', ref_keys = 'C'), R('Ee', 'ff', 'Comp2', ref_keys = 'B'),
                  R('Ee', 'ff', 'Comp2', ref_keys = 'C', prov_type = 'compiled_from'))
prov2 <- BuildProvenance(records2, prim2, classes2, citeids2, accepted)
c2 <- prov2[prov2$source_mass == 'Comp2', ]
Expect(identical(names(prov2), provenance_columns) && nrow(c2) == 6, sprintf('the hop-2 fixture gives %d Comp2 rows', nrow(c2)))
h2 <- c2[c2$genus == 'Aa' & c2$provenance_type == 'compiled_via_compilation', ]
Expect(nrow(h2) == 1 && h2$hop == 2L && h2$via_cite_id == 'Inter' && h2$primary_cite_id == 'Doyle_2007' && h2$primary_bibcite == 'Doyle:2007aa' &&
         h2$primary_doi == '10.1/doyle' && h2$ref_role == 'measurement' && h2$match_status == 'certain' && h2$n_records == 2L,
       'a reference matched by DOI to a label whose record of the species resolves: hop 2, compiled_via_compilation, via the label, the label\'s primary reference, two records')
Expect(!any(c2$genus == 'Aa' & c2$provenance_type == 'compiled_via_compilation' & is.na(c2$primary_cite_id)),
       'the intermediate\'s pending key gives no hop-2 row')
m <- c2[c2$genus == 'Aa' & c2$primary_cite_id %in% 'Other_1999', ]
Expect(nrow(m) == 1 && m$provenance_type == 'compiled_from' && m$hop == 1L && is.na(m$via_cite_id), 'an ordinary measurement reference beside it is unchanged')
sf <- c2[c2$genus == 'Cc', ]
Expect(nrow(sf) == 1 && sf$provenance_type == 'compiled_from' && sf$hop == 1L && sf$ref_role == 'measurement' && sf$primary_cite_id == 'Inter' &&
         sf$primary_bibcite == 'Inter:2007aa' && sf$primary_doi == '10.1/INTER' && is.na(sf$via_cite_id) && sf$match_status == 'certain',
       'the intermediate measured the species itself (self): compiled_from citing the intermediate at hop 1')
tm <- c2[c2$genus == 'Ee' & c2$ref_role %in% 'compilation' & c2$primary_cite_id %in% 'Inter', ]
Expect(nrow(tm) == 1 && tm$provenance_type == 'compilation_terminal' && tm$hop == 1L && tm$ref_role == 'compilation' && tm$primary_bibcite == 'Inter:2007aa' &&
         is.na(tm$via_cite_id) && tm$match_status == 'certain',
       'no resolved intermediate reference for the species: compilation_terminal citing the intermediate')
tb <- c2[c2$genus == 'Ee' & c2$primary_cite_id %in% 'Term2', ]
Expect(nrow(tb) == 1 && tb$provenance_type == 'compilation_terminal' && tb$ref_role == 'compilation' && tb$primary_bibcite == 'Term2:2010aa' && tb$match_status == 'approved',
       'a reference matched by bib key to a label without a primary_references.csv: compilation_terminal citing the label')
ovr <- c2[c2$genus == 'Ee' & c2$provenance_type == 'compiled_from', ]
Expect(nrow(ovr) == 1 && ovr$hop == 1L && is.na(ovr$primary_cite_id) && ovr$primary_doi == '10.1/inter' && is.na(ovr$via_cite_id) && ovr$ref_role == 'measurement',
       'a record-level prov_type override is left alone (the reference as resolved, no intermediate)')
it <- prov2[prov2$source_mass == 'Inter', ]
Expect(nrow(it) == 3 && sum(it$provenance_type == 'compiled_from') == 2 && sum(it$provenance_type == 'measured_in_source') == 1,
       'the intermediate\'s own rows are untouched')
il <- IntermediateReferences(records2, prim2, 'Inter')
Expect(nrow(il) == 2 && all(il$label == 'Inter') && identical(sort(il$i_status), c('certain', 'self')), 'IntermediateReferences(): accepted and self references only, one row per species x reference')
Expect(identical(MatchIntermediateLabel(c('Inter', NA, NA, NA), c(NA, 'Term2:2010aa', NA, NA), c(NA, NA, '10.1/inter', '10.1/none'),
                                        classes2$source_label, citeids2$Bibcite[match(classes2$source_label, citeids2$CiteID)],
                                        citeids2$doi[match(classes2$source_label, citeids2$CiteID)]),
                 c('Inter', 'Term2', 'Inter', NA)),
       'MatchIntermediateLabel(): by CiteID, bib key, DOI (case-insensitive), else NA')
prov_no <- BuildProvenance(records2, prim2[prim2$source_label != 'Inter', ], classes2, citeids2, accepted)
Expect(all(prov_no$provenance_type[prov_no$source_mass == 'Comp2' & prov_no$primary_cite_id %in% 'Inter'] == 'compilation_terminal') &&
         sum(prov_no$source_mass == 'Comp2' & prov_no$primary_cite_id %in% 'Inter') == 3 && !any(prov_no$provenance_type == 'compiled_via_compilation'),
       'without the intermediate\'s primary_references.csv every such record is terminal at the intermediate (no hop-2 row)')

# ---- the checks ---------------------------------------------------------------------------------------------
cat('CheckCitations(), WriteCitationsReport()\n')
bib <- Reg(key = c('Comp:2013aa', 'Prim:2020aa', 'Deriv:2016aa', 'Term:2010aa', 'Hech:2011aa', 'NoEq:2019aa', 'Eq:2016aa', 'Brey:2010aa', 'Doyle:2007aa'), type = 'article', doi = NA, file = 'Citations')
ck <- CheckCitations(prov, bib, citeids, prim, sheet_bibcites = c('Doyle:2007aa', 'Term:2010aa'))
Expect(length(ck$problems) == 2 && Has(ck$problems, '1 source label(s) without a Bibcite: LabX') && Has(ck$problems, 'without a CiteID row (Sheet tabs / snapshots): Lucas_2011'),
       'a consistent set reports only the lab-Sheet label without a Bibcite and the conversion CiteID that has no CiteID row')
Expect(ck$counts[['rows']] == 14 && ck$counts[['species']] == 3 && ck$counts[['primary_refs']] == 7 && ck$counts[['unresolved_refs']] == 1 && ck$counts[['unverified_refs']] == 0,
       'counts: rows, species, distinct primary CiteIDs, unresolved and unverified references')
cov <- ck$coverage
Expect(identical(cov$source_label, c('Comp', 'Deriv', 'Hech', 'NoEq', 'Prim')) && cov$n_species[cov$source_label == 'Comp'] == 3 &&
         cov$n_record_links[cov$source_label == 'Comp'] == 9 && cov$pct_resolved[cov$source_label == 'Comp'] == round(100 * 3 / 9, 1) &&
         cov$refs_total[cov$source_label == 'Comp'] == 4 && cov$refs_resolved[cov$source_label == 'Comp'] == 2 && cov$refs_pending[cov$source_label == 'Comp'] == 1 &&
         cov$refs_self[cov$source_label == 'Comp'] == 1 && cov$unmatched_key_links[cov$source_label == 'Comp'] == 1 && cov$uningested_links[cov$source_label == 'Comp'] == 0 &&
         cov$pct_resolved[cov$source_label == 'Deriv'] == 100 && cov$pct_resolved[cov$source_label == 'Prim'] == 0 && cov$refs_total[cov$source_label == 'Prim'] == 0,
       'per-source coverage: Comp 3 of 9 record links resolved (conversion rows excluded), the equation counts for Deriv, a primary source has no hop-1 links')
ck2 <- CheckCitations(prov, bib[bib$key != 'Doyle:2007aa', ], citeids[citeids$CiteID != 'Eq_2016', ], prim, sheet_bibcites = character())
Expect(Has(ck2$problems, 'primary_bibcite key(s) in no bib file: Doyle:2007aa') && Has(ck2$problems, 'primary_cite_id(s) without a CiteID row') && Has(ck2$problems, 'Eq_2016') &&
         Has(ck2$problems, '1 accepted reference(s) without a bib entry (run --bib): Comp 1'),
       'a missing bib key, a missing CiteID row and an accepted reference without a bib entry are reported')
prim_bad <- prim; prim_bad$match_reason[prim_bad$native_key == '3'] <- 'owner_candidate'; prim_bad$bibcite[prim_bad$native_key == '1'] <- 'New:2007aa'
ck3 <- CheckCitations(prov, bib, citeids, prim_bad, sheet_bibcites = character())
Expect(Has(ck3$problems, '1 certain/approved reference(s) without a DOI: Comp 3') && Has(ck3$problems, 'accepted bibcite(s) with no CiteID row yet (run --sheet): New:2007aa'),
       'an approved row without DOI or manual bibcite and an accepted bibcite without a CiteID row are reported')
rp <- tempfile(fileext = '.md')
WriteCitationsReport(rp, ck, classes = classes, unmapped_sheet = c('Foo_2001 -> Foo:2001aa'), uncited_labels = 'LabX')
lines <- readLines(rp)
Expect(startsWith(lines[1], '# Citation and provenance warnings') && Has(lines, '## Totals') && Has(lines, '- provenance rows: 14 (3 species); distinct primary CiteIDs: 7; unresolved references (pending / not_found): 1; unverified references: 0') &&
         Has(lines, '## Problems') && Has(lines, '- 1 source label(s) without a Bibcite: LabX') && Has(lines, '- Foo_2001 -> Foo:2001aa') && Has(lines, '## Per-source coverage') &&
         Has(lines, '| Comp | compilation | 3 | 9 | 33.3 | 4 | 2 | 1 | 0 | 1 | 0 | 0 | 1 | 0 |'),
       'the report has the totals, the problems, the unmapped Sheet rows and the coverage table with the class column')
WriteCitationsReport(rp, CheckCitations(prov[0, ], bib, citeids, prim[0, ]))
Expect(Has(readLines(rp), '(none)'), 'an empty check writes (none) sections')

# ---- the wiring --------------------------------------------------------------------------------------------------
cat('RunMe.r and enrich_genus.r wiring\n')
runme <- readLines(file.path(repo, 'R', 'RunMe.r'))
Expect(any(grepl("^wd_bib\\s*<-\\s*file\\.path\\(wd_root, 'Bib'\\)", runme)) && !any(grepl("file\\.path\\(wd_root, 'bib'\\)", runme)) &&
         any(grepl("^curated_bib_path <- file\\.path\\(wd_bib, 'TaxonBodyMass_Citations\\.bib'\\)", runme)) &&
         any(grepl("^primary_bib_path <- file\\.path\\(wd_bib, 'TaxonBodyMass_PrimaryCitations\\.bib'\\)", runme)),
       "wd_bib is 'Bib' and the bib is read through it")
Expect(any(grepl("'citations_config\\.r', 'normalise_citation\\.r', 'parse_reflists\\.r', 'build_bib\\.r', 'provenance\\.r'", runme)) &&
         !any(grepl("source\\(.*(verify_services|sheet_append|decide|cite_ids|run_citations)\\.r", runme)),
       'RunMe sources the five offline citation files and none of the network ones')
Expect(any(grepl('^prov_classes <- LoadProvenanceClasses\\(file\\.path\\(wd_bib, .source_provenance_classes\\.csv.\\)', runme)) &&
         any(grepl('^prim_refs <- LoadPrimaryReferences\\(wd_db\\)', runme)) &&
         which(grepl('^prov_classes <- LoadProvenanceClasses', runme)) > which(grepl('NormaliseSourceLabel\\(df\\$source_mass\\)', runme))[1] &&
         which(grepl('^prov_classes <- LoadProvenanceClasses', runme)) < which(grepl('FixMisspellings', runme))[1],
       'the registry and the primary references are loaded after the labels are normalised and before the misspelling fixes')
Expect(any(grepl("whose Bibcite key is in neither bib file", runme)) && any(grepl('^sheet_unmapped <- c\\(', runme)),
       'section 8 lists the Sheet rows whose Bibcite is in neither bib instead of dropping them silently')
Expect(any(grepl('^bibs <- CheckBibKeysUnique\\(curated_bib_path, primary_bib_path\\)', runme)) &&
         any(grepl('sheet_tab_primary %in% sheet_names\\(bm_sheet_url\\)', runme)) && any(grepl("'BM_primary_citations_snapshot\\.csv'", runme)) &&
         any(grepl('^provenance <- BuildProvenance\\(prov_records, prim_refs, prov_classes, dcite\\[, c\\(.CiteID., .Bibcite., .doi.\\)\\], enriched\\)', runme)) &&
         any(grepl("'TaxonBodyMass_Provenance\\.csv\\.gz'", runme)) && any(grepl("'warnings_citations\\.md'", runme)) &&
         any(grepl('dcite\\[order\\(dcite\\$CiteID, dcite\\$Bibcite\\), citeids_columns\\]', runme)),
       'section 8 reads both bibs (unique keys), the primary tab or its snapshot, builds the provenance table, the report and the CiteIDs CSV with the new columns')
Expect(any(grepl('^source_split <- SplitSourceMass\\(adat_enriched\\$source_mass\\)', runme)) && any(grepl('KnownConversionCiteIDs\\(\\)\\)$', runme)) &&
         any(grepl("^adat\\$origin <- ifelse\\(adat\\$taxon %in% sheet\\$species\\$taxon, 'BM_data', 'pipeline'\\)", runme)) &&
         any(grepl('^    ref_keys        = JoinRefKeys\\(ref_keys\\),', runme)) &&
         which(grepl('^prov_records <- adat_enriched', runme)) < which(grepl('^within_source <- adat_enriched', runme)),
       'source_mass is split before Pass 1, origin is set after the Sheet override, ref_keys go through Pass 1, the provenance records are taken before Pass 1')
kio <- readLines(file.path(repo, 'sources', 'databases', 'Kiorboe_2013', 'BodyMass_Kiorboe_2013.r'))
Expect(any(grepl("^adat\\$ref_keys <- SplitRefKeys\\(adat\\$Reference, ';'\\)", kio)) && any(grepl("'source_mass', 'ref_keys'\\)\\]", kio)),
       'the Kiorboe_2013 parser keeps the Reference column as ref_keys')
genus <- readLines(file.path(lib, 'enrich_genus.r'))
Expect(any(grepl("source_mass   = vapply\\(sp, function\\(d\\) paste\\(unique\\(trimws\\(unlist\\(strsplit\\(d\\$source_mass, ';', fixed = TRUE\\)\\)\\)\\), collapse = '; '\\)", genus)) &&
         !any(grepl("paste\\(d\\$source_mass, collapse = '-'\\)", genus)),
       "GenusLevelTable() joins the distinct labels with '; '")
gl <- read.csv(file.path(repo, 'TaxonBodyMass_GenusLevel.csv'), stringsAsFactors = FALSE, nrows = 2000)
Expect(!any(grepl('_[0-9]{4}-[A-Za-z]', gl$source_mass)) && any(grepl('; ', gl$source_mass, fixed = TRUE)) &&
         !any(vapply(strsplit(gl$source_mass, '; ', fixed = TRUE), anyDuplicated, integer(1)) > 0),
       "TaxonBodyMass_GenusLevel.csv: no '-'-joined labels, '; '-joined distinct labels")
readme <- readLines(file.path(repo, 'README.md'))
Expect(any(grepl('source_provenance_classes\\.csv', readme)) && any(grepl('pending_citations\\.csv', readme)) && any(grepl('scite_checks\\.csv', readme)),
       'the main README lists the three new Bib files')
gi <- readLines(file.path(repo, '.gitignore'))
Expect(any(grepl('^sources/citations_cache/', gi)), 'the response cache is git-ignored')
Expect(file.exists(file.path(repo, 'Bib', 'pending_citations.csv')) && identical(names(read.csv(file.path(repo, 'Bib', 'pending_citations.csv'), check.names = FALSE)), pending_queue_columns) &&
         identical(names(read.csv(file.path(repo, 'Bib', 'scite_checks.csv'), check.names = FALSE)), scite_check_columns),
       'the tracked queue and screening files carry their schemas')

cat(sprintf('\n%d checks, %d failed\n', n_checks, length(failures)))
if (length(failures) > 0) { cat(paste0('  FAIL: ', failures, '\n'), sep = ''); quit(status = 1) }
