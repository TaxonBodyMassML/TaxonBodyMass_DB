# Tests for the raw-name rules of R/library/fix_formatting.r (#38): the
# vocabulary loader, one fixture per class of audit/raw_name_patterns.csv
# (subgenus removed, sex stripped, form/strain/size stripped, synonym and
# authority stripped, trinomial folded, placeholder and qualifier markers,
# life stage and small size class dropped and logged, species group folded,
# hybrid and alternative names credited to the first name, the status words of
# #48 in the epithet position, an uncovered bracket stopping the run), the
# report writer, the format of the rename tables
# (fix_misspellings.r, fix_nontaxa.r; the keys of fix_taxonomy_ranks.r match
# the `species` column and are checked separately), a regression list of 60
# ordinary raw names whose output must not change, and the wiring in RunMe.r.
# Non-ASCII characters are written as \u escapes so the file parses in any
# locale. No network access, no cached frames and no packages beyond base R
# are needed.
#
#   Rscript R/library/tests/test_raw_name_rules.R      (from any directory)
#
# Prints one line per expectation and exits with status 1 if any failed.

this_file <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE))
if (length(this_file) == 0)         # sourced interactively from the repo root
  this_file <- file.path('R', 'library', 'tests', 'test_raw_name_rules.R')
repo <- normalizePath(file.path(dirname(this_file), '..', '..', '..'))
lib  <- file.path(repo, 'R', 'library')
source(file.path(lib, 'helpers.r'))               # DropImputed(), imputed_log
source(file.path(lib, 'fix_formatting.r'))
source(file.path(lib, 'fix_misspellings.r'))
source(file.path(lib, 'fix_nontaxa.r'))
source(file.path(lib, 'check_taxon_names.r'))
vocab_path <- file.path(repo, 'audit', 'raw_name_patterns.csv')
raw_name_patterns <- LoadRawNamePatterns(vocab_path)

failures <- character(0)
n_checks <- 0L
Expect <- function(ok, what) {
  n_checks <<- n_checks + 1L
  if (!isTRUE(ok)) failures <<- c(failures, what)
  cat(sprintf('  %s %s\n', if (isTRUE(ok)) 'ok  ' else 'FAIL', what))
}
ErrorOf <- function(expr) tryCatch({ expr; NULL }, error = function(e) conditionMessage(e))
Has <- function(x, pattern) !is.null(x) && grepl(pattern, x, fixed = TRUE)
Frame <- function(taxon, source = 'SrcA')
  data.frame(taxon = taxon, mass_g = seq_along(taxon), n = 1, source_mass = source, stringsAsFactors = FALSE)
# Run FixFormatting on fresh logs; return the frame, the raw-name log and the imputed log.
Run <- function(taxon, source = 'SrcA') {
  raw_name_log <<- list(); imputed_log <<- list()
  out <- suppressMessages(FixFormatting(Frame(taxon, source)))
  list(out = out, log = RawNameLogTable(), imputed = if (length(imputed_log)) do.call(rbind, imputed_log) else NULL)
}
Cleaned <- function(taxon) suppressMessages(FixFormatting(Frame(taxon)))$taxon
LogOf <- function(taxon) { r <- Run(taxon); r$log[match(taxon, r$log$raw), ] }

# ---- the vocabulary ---------------------------------------------------------------
cat('LoadRawNamePatterns()\n')
Expect(is.data.frame(raw_name_patterns) && nrow(raw_name_patterns) >= 25,
       sprintf('%d rows read from audit/raw_name_patterns.csv', nrow(raw_name_patterns)))
Expect(all(raw_name_pattern_columns %in% names(raw_name_patterns)), 'the six columns are present')
Expect(all(raw_name_patterns$class %in% raw_name_classes) && all(raw_name_patterns$action %in% raw_name_actions) &&
         all(raw_name_patterns$scope %in% raw_name_scopes), 'every class, action and scope is a known one')
Expect(all(c('subgenus', 'sex', 'form_strain_region', 'life_stage', 'size_class', 'species_group', 'synonym', 'authority',
             'trinomial', 'qualifier', 'placeholder', 'hybrid', 'ambiguous') %in% raw_name_patterns$class),
       'every class but other_drop has at least one row')
Expect(all(nzchar(raw_name_patterns$note)) && all(grepl('^[0-9]{4}-[0-9]{2}-[0-9]{2}$', raw_name_patterns$added)),
       'every row has a note and an ISO date')
WriteVocab <- function(rows) {
  f <- tempfile('vocab_', fileext = '.csv')
  write.csv(rbind(raw_name_patterns, rows), f, row.names = FALSE)
  f
}
bad_class <- data.frame(pattern = '^x$', scope = 'annotation', class = 'colour', action = 'strip', note = 'n', added = '2026-10-04')
Expect(Has(ErrorOf(LoadRawNamePatterns(WriteVocab(bad_class))), 'class not one of'), 'an unknown class stops the load')
bad_combo <- data.frame(pattern = '^x$', scope = 'annotation', class = 'life_stage', action = 'strip', note = 'n', added = '2026-10-04')
Expect(Has(ErrorOf(LoadRawNamePatterns(WriteVocab(bad_combo))), 'action strip with a class that is not stripped'), 'a drop class with action strip stops the load')
bad_fold <- data.frame(pattern = '^x$', scope = 'name', class = 'life_stage', action = 'fold', note = 'n', added = '2026-10-04')
Expect(Has(ErrorOf(LoadRawNamePatterns(WriteVocab(bad_fold))), 'action fold with a class that cannot fold'), 'a drop-only class with action fold stops the load')
bad_regex <- data.frame(pattern = '^(x$', scope = 'annotation', class = 'sex', action = 'strip', note = 'n', added = '2026-10-04')
Expect(Has(ErrorOf(LoadRawNamePatterns(WriteVocab(bad_regex))), 'not a valid Perl regex'), 'an invalid regex stops the load')
Expect(Has(ErrorOf(LoadRawNamePatterns(tempfile())), 'not found'), 'a missing file stops the load')
Expect(Has(ErrorOf(FixFormatting(Frame('Gadus morhua'), patterns = NULL)), 'LoadRawNamePatterns'),
       'FixFormatting() without the vocabulary stops with a pointer to the loader')

# ---- subgenus ---------------------------------------------------------------------
cat('subgenus: removed, genus and epithet kept\n')
Expect(identical(Cleaned(c('Jaera (Jaera) albifrons', 'Acanthamoeba (Hartmanella) castellani', 'Trypanosoma (Schizotrypanum) cruzi',
                           'Leucocarbo (Phal.) carunculatus', 'Tomopteris (Johnstonella) pacifica')),
                 c('Jaera_albifrons', 'Acanthamoeba_castellani', 'Trypanosoma_cruzi', 'Leucocarbo_carunculatus', 'Tomopteris_pacifica')),
       'a bracketed capitalised word between genus and epithet, abbreviated or not, is removed')
Expect(identical(Cleaned(c('Crithidia (Strigomonas) oncopelti', 'Crithida (Strigomonas) fasciculata')),
                 c('Crithidia_oncopelti', 'Crithida_fasciculata')), 'the two Makarieva names that motivated the issue')
Expect(identical(Cleaned(c('Castor Castor canadensis', 'Falcipennis Falcipennis canadensis')), c('Castor_canadensis', 'Falcipennis_canadensis')),
       'a genus written twice (VertNet) loses the repeat; before, Falcipennis_falcipennis resolved to the wrong species')
Expect(identical(LogOf('Jaera (Jaera) albifrons')$class, 'subgenus'), 'logged as class subgenus')
Expect(identical(Cleaned('Species 1 (Sutherland)*'), 'Species_sp'),
       'a capitalised word in brackets after a placeholder is not a subgenus: the record is the placeholder marker')

# ---- sex --------------------------------------------------------------------------
cat('sex: stripped, record kept\n')
Expect(identical(Cleaned(c('Calanus pacificus (F)', 'Arctocephalus gazella Female', 'Mirounga leonina Females',
                           'Phoca hispida Males', 'Callorhinus ursinus females', 'Tetrao urogallus \u2640')),
                 c('Calanus_pacificus', 'Arctocephalus_gazella', 'Mirounga_leonina', 'Phoca_hispida', 'Callorhinus_ursinus', 'Tetrao_urogallus')),
       'bracketed, trailing and sign sex marks are removed and the records kept')
r <- Run(c('Calanus pacificus (F)', 'Tetrao urogallus \u2640'))
Expect(nrow(r$out) == 2 && is.null(r$imputed) && all(r$log$class == 'sex') && !any(r$log$dropped),
       'nothing is dropped or logged as imputed; both names are logged as class sex')
pm <- RemoveNonTaxa(FixMisspellings(suppressMessages(FixFormatting(Frame('Pergamasinae (male)')))))
Expect(identical(Cleaned('Pergamasinae (male)'), 'Pergamasinae') && nrow(pm) == 0,
       "'Pergamasinae (male)' becomes the bare subfamily, which RemoveNonTaxa() lists and removes")

# ---- form, strain, region, size class --------------------------------------------
cat('form_strain_region: stripped, record kept; size_class: large classes stripped, small classes dropped\n')
Expect(identical(Cleaned(c('Conochilus (colonial)', 'Conochilus (solitary)', 'Paraphysomonas imperforata (arctic)*',
                           'Ilybius chalconatus Bulgaria', 'Mycoplasma pulmonis UAB CTIP', 'Spirulina platensis 1968-3786',
                           'Anacystis nidulans PCC (Synechococcus', 'Salpa maxima. Agg')),
                 c('Conochilus', 'Conochilus', 'Paraphysomonas_imperforata', 'Ilybius_chalconatus', 'Mycoplasma_pulmonis',
                   'Spirulina_platensis', 'Anacystis_nidulans', 'Salpa_maxima')),
       'colony forms, isolate origins, populations, strain codes and the salp aggregate generation are removed')
Expect(identical(LogOf('Conochilus (colonial)')$class, 'form_strain_region'), 'logged as class form_strain_region')
Expect(identical(Cleaned(c('Conochilus_colonial', 'Conochilus_solitary', 'Conochilus solitary')), c('Conochilus', 'Conochilus', 'Conochilus')) &&
         identical(LogOf('Conochilus_colonial')$class, 'form_strain_region') && identical(LogOf('Conochilus_colonial')$action, 'fold'),
       'the Brose_2005 spellings without brackets fold to the genus-level record Conochilus too (class form_strain_region, action fold, #48)')
Expect(identical(Cleaned(c('Lithobius aeruginosus {l}', 'Lithobius curtipes {m}', 'Allaiulus nitidus {xl}', 'Lumbricus rubellus {xxl}',
                           'Octolasion tyrtaeum{xxxl}', 'Harpactea lepida large', 'Genus epitheton medium')),
                 c('Lithobius_aeruginosus', 'Lithobius_curtipes', 'Allaiulus_nitidus', 'Lumbricus_rubellus', 'Octolasion_tyrtaeum',
                   'Harpactea_lepida', 'Genus_epitheton')),
       'the medium and large size classes, in braces (glued or not) or as words, fold into the species')
Expect(identical(LogOf('Lithobius aeruginosus {l}')$class, 'size_class') && !LogOf('Lithobius aeruginosus {l}')$dropped,
       'logged as class size_class, not dropped')
r <- Run(c('Lithobius aeruginosus {s}', 'Scutigerella immaculata {xs}', 'Trachytes pauperior{s}', 'Harpactea lepida small',
           'Salvelinus fontinalis SMALL', 'Lithobius aeruginosus {l}'), 'Brose_etal_2018')
Expect(identical(r$out$taxon, 'Lithobius_aeruginosus') && r$out$mass_g == 6,
       'the small classes {s}, {xs} and small (any case) are dropped; the {l} row survives')
Expect(!is.null(r$imputed) && nrow(r$imputed) == 1 && r$imputed$n_dropped == 5 && r$imputed$n_taxa == 5 && r$imputed$n_kept == 1 &&
         grepl('small size class', r$imputed$reason) && grepl('owner decision 2026-10-04', r$imputed$reason),
       'one imputed-log entry for the five small-class rows, reason naming the rule and the decision')
Expect(all(r$log$class == 'size_class') && sum(r$log$dropped) == 5, 'all six names logged as class size_class, five dropped')
Expect(identical(Cleaned(c('Calanus pacificus (M)', 'Lithobius curtipes {m}')), c('Calanus_pacificus', 'Lithobius_curtipes')) &&
         identical(LogOf('Calanus pacificus (M)')$class, 'sex') && identical(LogOf('Lithobius curtipes {m}')$class, 'size_class'),
       "'(M)' is a sex mark and '{m}' a size class: the sex row precedes the size rows")

# ---- synonym and authority --------------------------------------------------------
cat('synonym and authority: stripped, record kept\n')
Expect(identical(Cleaned(c('Aspidoscelis sexlinata (Cnemidophorus sexlineatus)', 'Tigrosa helluo (Hogna helluo)',
                           'Myadestes obscurus (occidentalis)', 'Euphonia musica(elegantissima)', 'Anhinga rufa (anhinga)',
                           'Phalacrocorax brasilianus (previously olivaceus)', 'Eurostopodus argus (Eurostopodus',
                           'Phalacrocorax capillatus - filamentosus')),
                 c('Aspidoscelis_sexlinata', 'Tigrosa_helluo', 'Myadestes_obscurus', 'Euphonia_musica', 'Anhinga_rufa',
                   'Phalacrocorax_brasilianus', 'Eurostopodus_argus', 'Phalacrocorax_capillatus')),
       'alternative names, epithets and common names in brackets (balanced, glued or open) are removed')
Expect(identical(LogOf('Tigrosa helluo (Hogna helluo)')$class, 'synonym'), 'logged as class synonym')
Expect(identical(Cleaned(c('Apis mellifera L.', 'Phormidium autumnale Gom.', 'Gadus morhua (Gmelin, 1789)',
                           'Nausitho\u00eb rubra Vanh\u00f6ffen, 1902')),
                 c('Apis_mellifera', 'Phormidium_autumnale', 'Gadus_morhua', 'Nausithoe_rubra')),
       'author abbreviations and author-year citations, bracketed or trailing, are removed')
Expect(identical(LogOf('Apis mellifera L.')$class, 'authority'), 'logged as class authority')
Expect(identical(Cleaned(c('Agonum thoreyi (Dejean)', 'Lithobius piceus (L. Koch)', 'Porcellium conspersum (C.L.Koch)',
                           'Vallonia costata (O. F. M\u00fcller)', 'Chartoscirta cincta (Herrich-Sch\u00e4ffer)',
                           'Coenagrion pulchellum (Vander Linden)', 'Somatochlora flavomaculata (Van der Linden)',
                           'Callitula ferrierei Boucek', 'Pteromicra leucopeza (?) (Meigen)')),
                 c('Agonum_thoreyi', 'Lithobius_piceus', 'Porcellium_conspersum', 'Vallonia_costata', 'Chartoscirta_cincta',
                   'Coenagrion_pulchellum', 'Somatochlora_flavomaculata', 'Callitula_ferrierei', 'Pteromicra_leucopeza')),
       'the Brose_2005 authors without a year, bracketed or trailing, are removed (#69)')
Expect(identical(LogOf('Agonum thoreyi (Dejean)')$class, 'authority') && identical(LogOf('Callitula ferrierei Boucek')$class, 'authority'),
       'logged as class authority')
Expect(identical(LogOf('Agonum thoreyi (Gould)')$class, 'error') && isTRUE(LogOf('Agonum thoreyi (Gould)')$error),
       'an author not listed by name is still reported as class error, not assumed')
Expect(identical(Cleaned(c('Formica s.str. sp', 'Formica sensu stricto sp', 'Lasius s.l. sp')),
                 c('Formica_sp', 'Formica_cf', 'Lasius_cf')) &&
         identical(LogOf('Formica s.str. sp')$class, 'placeholder'),
       "'s.str.' in the epithet position is a placeholder marker Genus_sp (#69); 'sensu' and 's.l.' stay with the qualifier row (Genus_cf)")

# ---- trinomial --------------------------------------------------------------------
cat('trinomial: folded to the species\n')
Expect(identical(Cleaned(c('Acanthiza pusilla apicalis', 'Acanthopagrus_schlegelii_schlegelii', 'Canis lupus familiaris',
                           'Cocconeis placentula var. euglypta', 'Nostoc commune var.', 'Dendroica coronata sp.',
                           'Encoptolophus s. costalis')),
                 c('Acanthiza_pusilla', 'Acanthopagrus_schlegelii', 'Canis_lupus', 'Cocconeis_placentula', 'Nostoc_commune',
                   'Dendroica_coronata', 'Encoptolophus_s')),
       'a lowercase third token, with or without a rank marker, folds into the species (documented behaviour)')
Expect(identical(LogOf('Acanthiza pusilla apicalis')$class, 'trinomial'), 'logged as class trinomial')

# ---- placeholder and qualifier markers --------------------------------------------
cat('placeholder and qualifier: explicit markers that RemoveNonTaxa() removes\n')
ph <- c('Abax sp.', 'Lithobius sp', 'Lithobius sp2 {l}', 'Pheidole sp.3', 'Lasioglossum lassp8', 'Austrosyphus aussp1',
        'Centris spp2', 'Gammarus spp.', 'Lagopus spec.', 'Oligochaeta indet.', 'Mesoveliidae indet. sp. A', 'Reithrodontomys n.sp.',
        'Cyornis sp?', 'Lemniscomys SP?', 'Probolocoryphe species A', 'Gomphonema type D', 'edwardsii 1.8429',
        'Unidentified 1', 'Unidentified species 10', 'Unid. Chironomidae', 'Unknown species*', 'Species 2 (Stellenbosch)*',
        'Libellula spp. (combined)', 'Menippe spp. (M. mercenaria/M. adina hybrids)', 'Pimelodus sp. (cf. blochii')
Expect(identical(Cleaned(ph),
                 c('Abax_sp', 'Lithobius_sp', 'Lithobius_sp', 'Pheidole_sp', 'Lasioglossum_sp', 'Austrosyphus_sp',
                   'Centris_spp', 'Gammarus_spp', 'Lagopus_spec', 'Oligochaeta_indet', 'Mesoveliidae_indet', 'Reithrodontomys_sp',
                   'Cyornis_sp', 'Lemniscomys_sp', 'Probolocoryphe_sp', 'Gomphonema_type', 'Edwardsii_sp',
                   'Unidentified_sp', 'Unidentified_sp', 'Unid_sp', 'Unknown_sp', 'Species_sp',
                   'Libellula_spp', 'Menippe_spp', 'Pimelodus_sp')),
       'every placeholder form leaves as Genus_<word> (sp, spp, spec, indet, type as written, also with a trailing number; sp for other codes and digits)')
r <- Run(ph)
Expect(all(r$log$class == 'placeholder') && !any(r$log$dropped) && is.null(r$imputed),
       'placeholders are logged as class placeholder and not dropped in FixFormatting()')
rn <- RemoveNonTaxa(FixMisspellings(r$out))
Expect(nrow(rn) == 0,
       "after FixMisspellings() and RemoveNonTaxa() no placeholder survives: 'Lagopus spec.' and 'Gomphonema type D' are removed like every other marker (their rename rules to genus-level records went with #43)")
Expect(nrow(RemoveNonTaxa(Frame(c('Gomphonema_type', 'Lagopus_spec', 'Hydrobiosis_type')))) == 0,
       'RemoveNonTaxa() removes the _type and _spec markers directly (#43)')
ph48 <- c('Canis undefinable', 'Microtus ssp', 'Peromyscus ssp', 'Genus undetermined', 'Genus undet.', 'Genus subsp.', 'Genus SSP', 'Genus unidentifiable')
Expect(identical(Cleaned(ph48), c('Canis_sp', 'Microtus_sp', 'Peromyscus_sp', 'Genus_sp', 'Genus_sp', 'Genus_sp', 'Genus_sp', 'Genus_sp')),
       'ssp, subsp, undefinable, undetermined, undet. and unidentifiable in the epithet position are placeholders: the marker Genus_sp (#48)')
r <- Run(ph48, 'vertnet-traits-sept2016')
Expect(all(r$log$class == 'placeholder') && !any(r$log$dropped) && is.null(r$imputed) && nrow(RemoveNonTaxa(FixMisspellings(r$out))) == 0,
       'logged as class placeholder and removed by RemoveNonTaxa(): not turned into genus-only records (#43, option B)')
Expect(identical(Cleaned(c('Acanthiza pusilla ssp. apicalis', 'Nostoc commune ssp.')), c('Acanthiza_pusilla', 'Nostoc_commune')),
       'ssp. after a binomial is still the trinomial marker, not a placeholder')
ql <- c('Zercon cf gurensis', 'Lithobius cf. mutabilis', 'Pseudobodo c.f. tremulans', 'Arietellus cf.', 'Procapritermes nr. sandakanensis',
        'Macrocheles cf. opacus aciculatus', 'Scolopendrella cf. subnuda {s}')
Expect(identical(Cleaned(ql), c('Zercon_cf', 'Lithobius_cf', 'Pseudobodo_cf', 'Arietellus_cf', 'Procapritermes_nr',
                                'Macrocheles_cf', 'Scolopendrella_cf')),
       'cf./c.f./nr. before the epithet leave as Genus_cf / Genus_nr (a size class after a qualifier is not checked)')
r <- Run(ql)
Expect(all(r$log$class == 'qualifier') && nrow(RemoveNonTaxa(r$out)) == 0, 'qualifiers are logged as class qualifier and RemoveNonTaxa() removes every marker')
Expect(identical(Cleaned(c('Buteo (rufofuscus)', 'Empidonax [traillii]')), c('Buteo_rufofuscus', 'Empidonax_traillii')) &&
         identical(LogOf('Buteo (rufofuscus)')$class, 'qualifier'),
       'the two VertNet names with the epithet alone in brackets fold to the binomial (class qualifier, action fold)')

# ---- species groups: folded to the nominal species ----------------------------------
cat('species_group: the marker stripped, the nominal species kept\n')
r <- Run(c('Polypedilum halterale group', 'Heterotrissocladius marcidus group', 'Hylaeus modestus grp', 'Lasioglossum tegulare grp',
           'Genus epitheton complex', 'Genus epitheton s.l.'), 'Hrycik_2024')
Expect(identical(r$out$taxon, c('Polypedilum_halterale', 'Heterotrissocladius_marcidus', 'Hylaeus_modestus', 'Lasioglossum_tegulare',
                                'Genus_epitheton', 'Genus_epitheton')),
       'group, grp, complex and s.l. after a binomial are removed and the nominal species kept (owner decision 2026-10-04)')
Expect(all(r$log$class == 'species_group') && !any(r$log$dropped) && is.null(r$imputed) && nrow(RemoveNonTaxa(r$out)) == 6,
       'logged as class species_group; nothing dropped or logged as imputed; RemoveNonTaxa() keeps them')

# ---- life stage: dropped through DropImputed() -----------------------------------
cat('life_stage: dropped through DropImputed() and logged\n')
stages <- c('Calanus pacificus (N1)', 'Calanus pacificus (II)', 'Calanus pacificus (IV)', 'Calanus pacificus (V)', 'Calanus pacificus (F)')
r <- Run(stages, 'DeLong_etal_2010')
Expect(identical(r$out$taxon, 'Calanus_pacificus') && r$out$mass_g == 5,
       'of the five Calanus pacificus rows only the adult female (F) survives, with its own mass')
Expect(!is.null(r$imputed) && nrow(r$imputed) == 1 && r$imputed$source == 'DeLong_etal_2010' && r$imputed$n_dropped == 4 &&
         r$imputed$n_taxa == 4 && r$imputed$n_kept == 1 && grepl('life-stage', r$imputed$reason) && grepl('#38', r$imputed$reason),
       'one imputed-log entry: source DeLong_etal_2010, 4 rows of 4 names dropped, 1 kept, a reason naming the rule')
Expect(identical(sort(r$log$class), c('life_stage', 'life_stage', 'life_stage', 'life_stage', 'sex')) &&
         sum(r$log$dropped) == 4 && all(is.na(r$log$cleaned[r$log$dropped])),
       'the raw-name log has four dropped life_stage lines and one sex line')
r <- Run(c('Mirounga angustirostris Juveniles', 'Callorhinus ursinus Juveniles Males', 'Mirounga angustirostris Females',
           'Brachyuran larvae (megalops)', 'immature tubificid with hairs', 'Chironomidae larvae'), 'Verberk_2020')
Expect(identical(r$out$taxon, c('Mirounga_angustirostris', 'Chironomidae_larvae')),
       'trailing Juveniles (alone or with a sex word), a bracketed megalops and the Hrycik immature label are dropped; a two-token label is left to RemoveNonTaxa()')
Expect(identical(r$log$class[r$log$raw == 'Callorhinus ursinus Juveniles Males'], 'life_stage') &&
         identical(r$log$classes[r$log$raw == 'Callorhinus ursinus Juveniles Males'], 'life_stage'),
       'a name with a stage and a sex word is filed under life_stage, the class that decided its fate')
Expect(identical(Cleaned(c('Gnathophausia zoea', 'Clubiona juvenis', 'Ducula zoeae', 'Columba larvata')),
                 c('Gnathophausia_zoea', 'Clubiona_juvenis', 'Ducula_zoeae', 'Columba_larvata')),
       'stage-like epithets of real species are not annotations and are kept')

# ---- hybrids and ambiguous names: credited to the first name ----------------------
cat('hybrid and ambiguous: the name cut at the separator, the first name kept\n')
r <- Run(c('Anas platyrhynchos x rubripes', 'Tympanuchus phasianellus X cupido', 'Lonchura X Poephila cantans x guttata',
           'Centrocercus X Tympanuchus urophasianus X phasianellus', 'Melanerpes aurifrons x hoffmannii ?',
           'Cebus nigritusXlibidinosus', 'Carduelis sinica x Serinus canaria', 'Zygiella x-notata', 'Gadus morhua'), 'vertnet-aves-sept2016')
Expect(identical(r$out$taxon, c('Anas_platyrhynchos', 'Tympanuchus_phasianellus', 'Lonchura', 'Centrocercus', 'Melanerpes_aurifrons',
                                'Cebus_nigritus', 'Carduelis_sinica', 'Zygiella_xnotata', 'Gadus_morhua')),
       'names joined by x or X (spaced or glued) are cut at the x and credited to the first name, a bare genus giving a genus-level record; x- inside an epithet is not a hybrid')
Expect(is.null(r$imputed) && !any(r$log$dropped) && all(r$log$class[r$log$raw != 'Zygiella x-notata'] == 'hybrid') &&
         all(r$log$action[r$log$class == 'hybrid'] == 'fold'),
       'nothing dropped or logged as imputed; the hybrids are logged as class hybrid, action fold (owner decision 2026-10-04)')
r <- Run(c('Anas hybrid', 'Dendroica hybrid', 'Melospiza hybrid', 'Vermivora hybrid', 'Anas_hybrid', 'Anas hybrid?', 'Anas platyrhynchos hybrid',
           'Chloephaga hybrida'), 'vertnet-aves-sept2016')
Expect(identical(r$out$taxon, c('Anas', 'Dendroica', 'Melospiza', 'Vermivora', 'Anas', 'Anas', 'Anas_platyrhynchos', 'Chloephaga_hybrida')),
       'the word hybrid in place of the epithet credits the record to the bare genus, a genus-level record (#48); after a binomial it credits the species; the epithet hybrida is a name')
Expect(sum(r$log$class == 'hybrid') == 7 && all(r$log$action[r$log$class == 'hybrid'] == 'fold') && !any(r$log$dropped) && is.null(r$imputed) &&
         !('Chloephaga hybrida' %in% r$log$raw),
       'the seven hybrid labels are logged as class hybrid, action fold; nothing is dropped; Chloephaga hybrida is not logged')
r <- Run(c('Pipilo maculatus,  ocai', 'Empidonax traillii/alnorum', 'Lithobius cyrt/mutabi', 'Coccinella septempunctata and Harpalus pennsylvanicus',
           'Sitobion avenae, Metopolophium dirhodum', 'Musculium/Sphaerium', 'Pacific herring, Clupea palasi', 'Skate, Raja orinacea',
           'Diptera larvae/pupae', 'Petrochelidon; Hirundo fulva; rustica', 'Nausithoe rubra Vanhoffen, 1902', 'Myotis velifer /'), 'SrcA')
Expect(identical(r$out$taxon, c('Pipilo_maculatus', 'Empidonax_traillii', 'Lithobius_cyrt', 'Coccinella_septempunctata', 'Sitobion_avenae',
                                'Musculium', 'Pacific_herring', 'Skate', 'Diptera_larvae', 'Petrochelidon', 'Nausithoe_rubra', 'Myotis_velifer')),
       'comma, slash, semicolon and "and" cut the name; the first fragment is kept even when incomplete (Lithobius_cyrt); an author year after a comma and a stray slash are not separators')
Expect(is.null(r$imputed) && !any(r$log$dropped) && sum(r$log$class == 'ambiguous') == 10,
       'nothing dropped; the ten names with alternatives are logged as class ambiguous')
Expect(identical(sort(RemoveNonTaxa(FixMisspellings(r$out))$taxon),
                 sort(c('Pipilo_maculatus', 'Empidonax_traillii', 'Lithobius_cyrt', 'Coccinella_septempunctata', 'Sitobion_avenae',
                        'Musculium', 'Petrochelidon', 'Nausithoe_rubra', 'Myotis_velifer'))),
       'RemoveNonTaxa() then lists Pacific_herring, Skate and Diptera_larvae, the labels the cut leaves')
r <- Run(c('Lithobius aeruginosus {s}', 'Harpactea lepida small'), c('Brose_etal_2018', 'SrcB'))
Expect(!is.null(r$imputed) && nrow(r$imputed) == 2 && setequal(r$imputed$source, c('Brose_etal_2018', 'SrcB')),
       'a frame with several source labels gets one imputed-log entry per label')

# ---- symbols and encoding ---------------------------------------------------------
cat('symbols and encoding: characters removed, record kept\n')
Expect(identical(Cleaned(c('Alphestes afer*', 'Azomonas agilis?', 'Neanthes "arenaceodentata"', "Phrynosoma m'calli", 'Seicercus ?',
                           'Anabaena flos-aquae', 'Daubentonia_madagascariensi\ns')),
                 c('Alphestes_afer', 'Azomonas_agilis', 'Neanthes_arenaceodentata', 'Phrynosoma_mcalli', 'Seicercus',
                   'Anabaena_flosaquae', 'Daubentonia_madagascariensis')),
       'asterisks, question marks, quotes, apostrophes, hyphens and control characters are removed')
Expect(identical(LogOf('Alphestes afer*')$class, 'symbols') && identical(LogOf('Nausitho\u00eb rubra')$class, 'encoding'),
       'logged as class symbols / encoding')
r <- Run(c('Gadus morhua', 'gadus  morhua', ' Gadus_morhua ', 'Bathygobius Andrei'))
Expect(nrow(r$log) == 0, 'blank, underscore and case normalisation alone is not logged')

# ---- an uncovered bracket or token: class error, the run stops --------------------
cat('error: uncovered annotations stop the run\n')
r <- Run(c('Gadus morhua (weird)', 'Gadus morhua Weird', 'Gadus morhua {q9}', 'Gadus morhua'), 'SrcZ')
Expect(identical(r$out$taxon, c('Gadus_morhua_(weird)', 'Gadus_morhua_Weird', 'Gadus_morhua_{q9}', 'Gadus_morhua')),
       'the uncovered names (a lowercase or a capitalised word no row lists, a code in braces) keep their brackets and tokens, so they cannot pass for binomials')
Expect(sum(r$log$class == 'error') == 3 && all(r$log$error[r$log$class == 'error']), 'three names logged as class error')
e <- ErrorOf(CheckRawNames())
Expect(Has(e, '3 raw taxon name(s)') && Has(e, "'Gadus morhua (weird)'  (SrcZ: 1 row)") && Has(e, 'raw_name_patterns.csv'),
       'CheckRawNames() stops, lists each name with its source and row count, and points at the vocabulary')
Expect(Has(ErrorOf(CheckTaxonNames(list(r$out))), '3 cleaned taxon name(s)'),
       'CheckTaxonNames() would stop on them too (brackets, a capitalised third token)')
invisible(Run(c('Jaera (Jaera) albifrons', 'Gadus morhua')))
Expect(is.null(ErrorOf(CheckRawNames())) && identical(suppressWarnings(CheckRawNames()), 1L),
       'CheckRawNames() passes when no name is uncovered and returns the number of logged names')
raw_name_log <- list()
Expect(identical(suppressWarnings(CheckRawNames()), 0L), 'an empty log passes')

# ---- the report -------------------------------------------------------------------
cat('WriteRawNameReport()\n')
r <- Run(c('Jaera (Jaera) albifrons', 'Calanus pacificus (IV)', 'Lithobius sp2 {l}', 'Anas platyrhynchos x rubripes',
           'Gadus morhua (weird)', 'Gadus morhua'), 'SrcR')
f <- tempfile('raw_names_', fileext = '.md')
WriteRawNameReport(f)
rep <- readLines(f)
Expect(any(grepl('^# TaxonBodyMass_DB Raw Name Report -- ', rep)) && any(rep == '## Summary'), 'header and summary present')
Expect(any(grepl('^\\| error \\| 1 \\| 1 \\| 0 \\| SrcR \\(1\\) \\|$', rep)) && any(grepl('^\\| life_stage \\| 1 \\| 1 \\| 1 \\|', rep)) &&
         any(grepl('^\\| hybrid \\| 1 \\| 1 \\| 0 \\|', rep)),
       'the summary table counts names, rows and dropped records per class (the hybrid is kept, the life stage dropped)')
Expect(any(grepl('class `error`\\): 1 -- THE RUN STOPS', rep)), 'the summary flags the uncovered name')
Expect(all(c('## error (1 names, 1 rows)', '## life_stage (1 names, 1 rows)', '## hybrid (1 names, 1 rows)',
             '## placeholder (1 names, 1 rows)', '## subgenus (1 names, 1 rows)') %in% rep),
       'one section per class, drop classes first')
Expect(any(grepl('`Jaera (Jaera) albifrons` | `Jaera_albifrons` | subgenus | 1 | SrcR', rep, fixed = TRUE)) &&
         any(grepl('`Calanus pacificus (IV)` | (dropped) | life_stage | 1 | SrcR', rep, fixed = TRUE)) &&
         any(grepl('`Anas platyrhynchos x rubripes` | `Anas_platyrhynchos` | hybrid | 1 | SrcR', rep, fixed = TRUE)),
       'each name is listed with its result, classes, rows and source')
raw_name_log <- list(); WriteRawNameReport(f)
Expect(any(readLines(f) == 'No raw name was changed or classified.'), 'an empty log writes an empty report')

# ---- the format of the rename tables (3b) ----------------------------------------
cat('format of the rename tables\n')
key_re <- '^[A-Z][A-Za-z]*(_[a-z][A-Za-z]*)?$'      # what FixFormatting() can produce
val_re <- '^[A-Z][a-z]+(_[a-z]+)?$'                 # a proper Genus or Genus_species
txt <- readLines(file.path(lib, 'fix_misspellings.r'), warn = FALSE)
m <- regmatches(txt, regexec('^\\s*"([^"]+)"\\s*=\\s*"([^"]*)"', txt))
keys <- unlist(lapply(m, function(x) if (length(x) == 3) x[2] else character(0)))
vals <- unlist(lapply(m, function(x) if (length(x) == 3) x[3] else character(0)))
pre <- regmatches(txt, regexec('^\\s*c\\("([^"]+)",\\s*"([^"]+)"\\)', txt))
pk <- unlist(lapply(pre, function(x) if (length(x) == 3) x[2] else character(0)))
pv <- unlist(lapply(pre, function(x) if (length(x) == 3) x[3] else character(0)))
Expect(length(keys) > 300 && length(pk) >= 6, sprintf('%d corrections and %d genus prefixes read from fix_misspellings.r', length(keys), length(pk)))
Expect(all(grepl(key_re, keys)), paste('every correction key is Genus or Genus_species as FixFormatting() writes it:',
                                      paste(keys[!grepl(key_re, keys)], collapse = ', ')))
Expect(all(grepl(val_re, vals)), paste('every correction value is a proper Genus or Genus_species:', paste(vals[!grepl(val_re, vals)], collapse = ', ')))
Expect(!anyDuplicated(keys), paste('no correction key is duplicated:', paste(keys[duplicated(keys)], collapse = ', ')))
Expect(all(keys[grepl('_(sp|spp|spec|indet|unk|type|cf|nr|aff)$', keys)] %in% 'Hydrobiosis_type'),
       paste("no correction key is a placeholder or qualifier marker, which RemoveNonTaxa() removes (#43; 'Hydrobiosis_type', with no rows in the sources, was left in place):",
             paste(setdiff(keys[grepl('_(sp|spp|spec|indet|unk|type|cf|nr|aff)$', keys)], 'Hydrobiosis_type'), collapse = ', ')))
Expect(all(grepl('^[A-Z][A-Za-z]*_$', pk)) && all(grepl('^[A-Z][a-z]+_$', pv)), 'every genus prefix pair is Genus_ -> Genus_')
Expect(!any(grepl('[^\x01-\x7F]', c(keys, vals))), 'no key or value contains a non-ASCII character')
nt <- readLines(file.path(lib, 'fix_nontaxa.r'), warn = FALSE)
en <- regmatches(nt, regexec('^\\s*"([^"]+)"\\s*,?\\s*(#.*)?$', nt))
ents <- unlist(lapply(en, function(x) if (length(x) >= 2) x[2] else character(0)))
Expect(length(ents) > 100, sprintf('%d entries read from fix_nontaxa.r', length(ents)))
Expect(all(grepl(key_re, ents)), paste('every fix_nontaxa.r entry is Genus or Genus_species as FixFormatting() writes it:',
                                      paste(ents[!grepl(key_re, ents)], collapse = ', ')))
Expect(!anyDuplicated(ents), paste('no fix_nontaxa.r entry is duplicated:', paste(ents[duplicated(ents)], collapse = ', ')))
# fix_taxonomy_ranks.r keys match the `species` column ('Genus epithet', with a space) except
# taxon_overwrites, keyed by the cleaned taxon; a key of the wrong form can never match.
tr <- readLines(file.path(lib, 'fix_taxonomy_ranks.r'), warn = FALSE)
tk <- regmatches(tr, regexec("^\\s*'([^']+)'\\s*=\\s*c\\(", tr))
tk <- unlist(lapply(tk, function(x) if (length(x) == 2) x[2] else character(0)))
i_over <- grep('^\\s*taxon_overwrites <- list\\(', tr)
tk_over <- regmatches(tr[i_over:length(tr)], regexec("^\\s*'([^']+)'\\s*=\\s*c\\(", tr[i_over:length(tr)]))
tk_over <- unlist(lapply(tk_over, function(x) if (length(x) == 2) x[2] else character(0)))
tk_species <- setdiff(tk, tk_over)
Expect(length(tk_species) > 50 && all(grepl('^[A-Z][a-z]+ [a-z]+$', tk_species)),
       sprintf("the %d species-keyed fills of fix_taxonomy_ranks.r are 'Genus epithet' with a space", length(tk_species)))
Expect(length(tk_over) >= 5 && all(grepl(key_re, tk_over)),
       sprintf('the %d taxon_overwrites keys of fix_taxonomy_ranks.r are Genus_species', length(tk_over)))

# ---- regression: ordinary names keep their output -------------------------------
cat('regression: 60 ordinary raw names\n')
pinned <- rbind(
  c("Gadus morhua", "Gadus_morhua"),
  c("Gadus_morhua", "Gadus_morhua"),
  c("gadus morhua", "Gadus_morhua"),
  c("Gadus Morhua", "Gadus_morhua"),
  c("  Gadus morhua  ", "Gadus_morhua"),
  c("Gadus  morhua", "Gadus_morhua"),
  c("Chiton__cummingii", "Chiton_cummingii"),
  c("Phacochoerus__aethiopicus", "Phacochoerus_aethiopicus"),
  c("Argoctenus ", "Argoctenus"),
  c("Clubiona_", "Clubiona"),
  c("Lithobius", "Lithobius"),
  c("Tanytarsini", "Tanytarsini"),
  c("Bathygobius Andrei", "Bathygobius_andrei"),
  c("Sebastes_Saxicola", "Sebastes_saxicola"),
  c("Family Aphididae", "Family_aphididae"),
  c("Order Oligochaeta", "Order_oligochaeta"),
  c("Oligochaeta", "Oligochaeta"),
  c("Anabaena flos-aquae", "Anabaena_flosaquae"),
  c("Quietula y-cauda", "Quietula_ycauda"),
  c("Xestia c-nigrum", "Xestia_cnigrum"),
  c("Zygiella x-notata", "Zygiella_xnotata"),
  c("Pseudo-Nitzschia heimii", "PseudoNitzschia_heimii"),
  c("Pipilo erythrophthalmus-oca", "Pipilo_erythrophthalmusoca"),
  c("Cheilopogon xenopterus-group", "Cheilopogon_xenopterusgroup"),
  c("Bacillus megate-", "Bacillus_megate"),
  c("Methylobacte- extorquens", "Methylobacte_extorquens"),
  c("Lithobius sp.", "Lithobius_sp"),
  c("Lithobius sp", "Lithobius_sp"),
  c("Gammarus spp.", "Gammarus_spp"),
  c("Lagopus spec.", "Lagopus_spec"),
  c("Oligochaeta indet.", "Oligochaeta_indet"),
  c("Zercon cf gurensis", "Zercon_cf"),
  c("Lithobius cf. mutabilis", "Lithobius_cf"),
  c("Formica s.str. sp", "Formica_sp"),           # Formica_sstr until #69 (owner decision 2026-10-05: placeholder marker)
  c("Encoptolophus s. costalis", "Encoptolophus_s"),
  c("Eumops_bo riensis", "Eumops_bo"),
  c("Acanthiza pusilla apicalis", "Acanthiza_pusilla"),
  c("Acanthopagrus_schlegelii_schlegelii", "Acanthopagrus_schlegelii"),
  c("Canis lupus familiaris", "Canis_lupus"),
  c("Cocconeis placentula var. euglypta", "Cocconeis_placentula"),
  c("Harpactea lepida large", "Harpactea_lepida"),
  c("Callorhinus ursinus females", "Callorhinus_ursinus"),
  c("Apis mellifera L.", "Apis_mellifera"),
  c("Salpa maxima. Agg", "Salpa_maxima"),
  c("Tetrao urogallus \u2640", "Tetrao_urogallus"),
  c("Nausitho\u00eb rubra", "Nausithoe_rubra"),
  c("Edaphus bl\u0178hweissi", "Edaphus_blYhweissi"),
  c("Neanthes \"arenaceodentata\"", "Neanthes_arenaceodentata"),
  c("Phrynosoma m'calli", "Phrynosoma_mcalli"),
  c("Alphestes afer*", "Alphestes_afer"),
  c("Azomonas agilis?", "Azomonas_agilis"),
  c("Seicercus ?", "Seicercus"),
  c("Myotis velifer /", "Myotis_velifer"),
  c("Daubentonia_madagascariensi\ns", "Daubentonia_madagascariensis"),
  c("root feeding nematodes", "Root_feeding"),
  c("Aphanocapsa PCC", "Aphanocapsa_pCC"),
  c("edwardsii MIN", "Edwardsii_mIN"),
  c("CrayVertebrate Cambarus tenebrosus", "CrayVertebrate_cambarus"),
  c("Dendroica coronata sp.", "Dendroica_coronata"),
  c("Spirulina platensis 1968-3786", "Spirulina_platensis"))
got <- Cleaned(pinned[, 1])
Expect(length(got) == nrow(pinned), 'no pinned name is dropped')
Expect(identical(got, pinned[, 2]),
       paste('every pinned name gives its pre-#38 output; differences:',
             paste(sprintf('%s -> %s (expected %s)', pinned[got != pinned[, 2], 1], got[got != pinned[, 2]], pinned[got != pinned[, 2], 2]), collapse = '; ')))
Expect(identical(Cleaned(c(NA, '', '  ', '\u2640', '()')), character(0)), 'NA, empty, blank, sign-only and bracket-only names are dropped as rows')

# ---- wiring in RunMe.r ------------------------------------------------------------
cat('R/RunMe.r wiring\n')
runme   <- readLines(file.path(repo, 'R', 'RunMe.r'))
i_load  <- grep("^raw_name_patterns <- LoadRawNamePatterns\\(file\\.path\\(wd_root, 'audit', 'raw_name_patterns\\.csv'\\)\\)", runme)
i_fix   <- grep('^source_list <- lapply\\(source_list, FixFormatting\\)', runme)
i_imp   <- grep("^imputed_tab <- MergeImputedLog\\(imputed_log", runme)   # the merged log, #40
i_rep   <- grep("^WriteRawNameReport\\(file\\.path\\(wd_root, 'reports', 'warnings_raw_names\\.md'\\)\\)", runme)
i_chk   <- grep('^CheckRawNames\\(\\)', runme)
i_mis   <- grep('^source_list <- lapply\\(source_list, FixMisspellings\\)', runme)
i_unres <- grep('^unresolved_names <- adat_enriched', runme)
i_ce    <- grep('unresolved = unresolved_names, exclusions = excl\\)', runme)
Expect(length(i_load) == 1 && length(i_fix) == 1 && i_load < i_fix, 'the vocabulary is loaded from audit/ before FixFormatting() runs')
Expect(length(i_imp) == 1 && length(i_rep) == 1 && length(i_chk) == 1 && length(i_mis) == 1 &&
         i_fix < i_imp && i_imp < i_rep && i_rep < i_chk && i_chk < i_mis,
       'after FixFormatting(): the imputed log is written, the report written, CheckRawNames() run, then FixMisspellings()')
Expect(length(i_unres) == 1 && length(i_ce) == 1 && i_unres < i_ce,
       'the unresolved names are collected after the enrichment merge and passed to check_enriched()')

# ---- summary -------------------------------------------------------------------
cat(sprintf('\n%d expectations, %d failed\n', n_checks, length(failures)))
if (length(failures) > 0) {
  cat(paste0('  FAIL: ', failures, '\n'), sep = '')
  quit(status = 1)
}
