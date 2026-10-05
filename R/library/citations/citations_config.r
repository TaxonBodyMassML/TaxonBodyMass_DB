# Citation tooling (issue #1): configuration shared by every file of
# R/library/citations/ and, through provenance.r, by RunMe.r.
#
# Everything here is offline: paths relative to the repository root, the column
# schemas of the tracked CSV files, the controlled vocabularies, the decision
# thresholds of decide.r, the identity sent to Crossref and OpenAlex, and the
# per-source description of where a source's reference list is and how it is
# keyed (ReflistSpec()). Nothing in this file talks to the network.
#
# The hard rules of issue #1 (section F) that this layer encodes:
#  - no citation text enters a bib or the Sheet unless built by code from
#    Crossref/OpenAlex metadata (build_bib.r, sheet_append.r) or approved by the
#    owner in the review queue (Bib/pending_citations.csv);
#  - `raw_citation` is immutable; the owner edits only `parsed_*`, `role`,
#    `notes` and the queue's `decision`;
#  - service relevance scores are cached with the raw responses but are never
#    decision inputs; every accepted row carries the services consulted, the
#    locally computed agreement, `verified_at` and `tool_version`.

citations_tool_version <- 'tbmcite 0.1.0'

# ---- paths ----------------------------------------------------------------------
CitationsPaths <- function(wd_root) {
  wd_root <- normalizePath(wd_root, mustWork = TRUE)
  list(
    wd_root            = wd_root,
    wd_db              = file.path(wd_root, 'sources', 'databases'),
    wd_rdata           = file.path(wd_root, 'sources', 'Rdata'),
    wd_bib             = file.path(wd_root, 'Bib'),
    cache_dir          = file.path(wd_root, 'sources', 'citations_cache'),
    reports_dir        = file.path(wd_root, 'reports'),
    curated_bib        = file.path(wd_root, 'Bib', 'TaxonBodyMass_Citations.bib'),
    primary_bib        = file.path(wd_root, 'Bib', 'TaxonBodyMass_PrimaryCitations.bib'),
    citeids_csv        = file.path(wd_root, 'Bib', 'TaxonBodyMass_CitationCiteIDs.csv'),
    pending_csv        = file.path(wd_root, 'Bib', 'pending_citations.csv'),
    scite_csv          = file.path(wd_root, 'Bib', 'scite_checks.csv'),
    classes_csv        = file.path(wd_root, 'Bib', 'source_provenance_classes.csv'),
    snapshot_primary   = file.path(wd_root, 'Bib', 'BM_primary_citations_snapshot.csv'),
    snapshot_citations = file.path(wd_root, 'Bib', 'BM_citations_snapshot.csv'),
    provenance_csv     = file.path(wd_root, 'TaxonBodyMass_Provenance.csv.gz'),
    warnings_md        = file.path(wd_root, 'reports', 'warnings_citations.md')
  )
}

# The lab Google Sheet (the same document RunMe.r reads for BM_data and
# BM_citations) and the names of its citation tabs. Only `sheet_tab_primary` is
# ever written by this tooling (sheet_append.r).
citations_sheet_url  <- paste0('https://docs.google.com/spreadsheets/d/',
                               '1_TzVFXjcUrDBGHbpRuLh3NwYIF1I8AucsJh8heIFulY/edit?usp=sharing')
sheet_tab_citations  <- 'BM_citations'
sheet_tab_primary    <- 'BM_primary_citations'

# ---- network identity ---------------------------------------------------------
# Crossref's polite pool and OpenAlex's polite pool both ask for a contact
# address: CROSSREF_MAILTO / OPENALEX_MAILTO from the environment, falling back
# to the git user.email of the repository (the main checkout and its worktrees
# share one config). Stops when neither is set, so that no anonymous request
# is ever sent. OPENALEX_API_KEY, when set, is sent with every OpenAlex request
# (CitationsConfig(); the free pool is 1,000 requests a day without one).
CitationsMailto <- function(service = c('crossref', 'openalex'), wd_root = NULL) {
  service <- match.arg(service)
  var  <- if (service == 'crossref') 'CROSSREF_MAILTO' else 'OPENALEX_MAILTO'
  mail <- trimws(Sys.getenv(var, unset = ''))
  if (!nzchar(mail) && !is.null(wd_root)) {
    mail <- tryCatch(trimws(system2('git', c('-C', shQuote(wd_root), 'config', 'user.email'),
                                    stdout = TRUE, stderr = FALSE)),
                     error = function(e) '', warning = function(w) '')
    if (length(mail) == 0) mail <- ''
  }
  if (!nzchar(mail))
    stop('No contact address for ', service, ': set ', var,
         ' (or git config user.email) before using the citation tooling', call. = FALSE)
  mail
}

CitationsUserAgent <- function(mailto) {
  sprintf('TaxonBodyMass_DB-citations/%s (https://github.com/TaxonBodyMassML/TaxonBodyMass_DB; mailto:%s) R/%s httr2',
          sub('^tbmcite ', '', citations_tool_version), mailto, getRversion())
}

# Requests per second to each service (polite pools allow more; one per second
# keeps a whole source's verification well under any limit) and the retry policy
# for 429 and 5xx responses: at most `max_tries` attempts within
# `max_retry_seconds` (a Retry-After beyond that, OpenAlex's day-long one when
# its 1,000-requests-a-day quota is spent, is not waited for: the response is
# treated as an exhausted quota, verify_services.r QuotaCondition()); a request
# times out after `timeout_s` seconds and a dropped connection is retried like a 5xx.
citations_network <- list(rate_per_s = 1, max_tries = 4L, max_retry_seconds = 30, timeout_s = 60,
                          transient_status = c(429L, 500L, 502L, 503L, 504L),
                          crossref_rows = 5L, openalex_per_page = 5L,
                          crossref_api = 'https://api.crossref.org/works',
                          openalex_api = 'https://api.openalex.org/works')

# ---- decision thresholds (issue #1, section 2.3) ------------------------------
citations_thresholds <- list(
  doi_title_sim      = 0.80,  # raw_doi resolves and title agrees (or author & year agree)
  certain_title_sim  = 0.93,  # two-service agreement
  closed_world_sim   = 0.95,  # single service, candidate from the compilation's own reference list
  not_found_sim      = 0.70,  # below this the best candidate is no match
  ambiguous_delta    = 0.05,  # runner-up within this of the best, different DOI
  year_window        = 1L     # |parsed_year - candidate year| tolerated
)

# Crossref / OpenAlex work types that are never a primary reference and are
# filtered before scoring (a figshare collection or a dataset component often
# carries the article's title and authors under a second DOI).
citations_excluded_types <- c('dataset', 'component', 'peer-review', 'grant', 'journal',
                              'journal-issue', 'journal-volume', 'book-series', 'book-set',
                              'report-component', 'report-series', 'proceedings-series',
                              'paratext', 'libguides', 'supplementary-materials')

# Grey-literature patterns (issue #1, 2.3): a reference matching one of these with
# no good candidate is queued as `grey_literature` with the proposal `nodoi`.
citations_grey_pattern <- paste0('\\b(thesis|dissertation|report|unpublished|unpubl\\.|',
                                 'pers(onal)?\\.? comm|in prep|bulletin|memoir|memoirs|',
                                 'technical report|tech\\. rep|working paper|mimeo)\\b')

# ---- controlled vocabularies ---------------------------------------------------
match_statuses   <- c('certain', 'pending', 'approved', 'nodoi_approved', 'rejected',
                      'not_found', 'self')
match_reasons    <- c('doi_resolves', 'doi_mismatch', 'two_service_agreement', 'closed_world',
                      'single_service', 'ambiguous', 'grey_literature', 'retracted',
                      'weak_match', 'below_threshold', 'no_candidates', 'unscreened', 'service_unavailable',
                      'owner_review', 'self',
                      'owner_candidate', 'owner_doi', 'manual_bib', 'owner_nodoi',
                      'owner_self', 'owner_drop', 'key_not_in_reflist')
reference_roles  <- c('measurement', 'compilation', 'equation', 'conversion', 'database', 'self')
provenance_classes <- c('primary', 'compilation', 'derived', 'database', 'live', 'unknown')
provenance_types   <- c('measured_in_source', 'compiled_from', 'compiled_via_compilation',
                        'compilation_terminal', 'derived_allometry', 'derived_imputed',
                        'database_record', 'conversion_factor', 'unknown')
# match_status values of the provenance table that are not reference statuses:
# 'unmatched_key' (a key the source's reference list lacks), 'uningested' (the
# source has no primary_references.csv yet; owner decision 2026-10-04)
provenance_only_statuses <- c('unmatched_key', 'uningested')
# hop of a provenance row by its type (issue #1, 1.3)
provenance_type_hop <- c(measured_in_source = 0L, compiled_from = 1L, compiled_via_compilation = 2L,
                         compilation_terminal = 1L, derived_allometry = 1L, derived_imputed = 1L,
                         database_record = 1L, conversion_factor = 0L, unknown = 1L)
# the provenance_type of a resolved primary reference by its role
role_provenance_type <- c(measurement = 'compiled_from', compilation = 'compilation_terminal',
                          equation = 'derived_allometry', conversion = 'conversion_factor',
                          database = 'database_record', self = 'measured_in_source')
# the decision grammar of the review queue (issue #1, 1.5), validated by
# ApplyQueueDecisions(). A candidate or doi: decision may carry ':year=YYYY'
# (owner decision 2026-10-04): the accepted DOI's bib entry and Citation cell
# take that year instead of the service record's (a digitised thesis deposited
# with its 2025 scan date); the override is kept in the queue row's decision
# and in primary_references.csv `year_override`, and BuildBibEntry() applies it
# only from there.
queue_decision_pattern <- '^(1|2|3|doi:10\\.[0-9]{4,9}/\\S+?|manual:[A-Za-z][A-Za-z0-9:_-]*|nodoi|self|drop)(:year=(1[6-9][0-9]{2}|20[0-9]{2}))?$'

# ---- column schemas of the tracked files --------------------------------------
# sources/databases/<Src>/primary_references.csv (issue #1, 1.1)
primary_reference_columns <- c(
  'source_label', 'native_key', 'raw_citation', 'raw_doi', 'n_records', 'role',
  'parsed_author1', 'parsed_year', 'parsed_title', 'parsed_container', 'parsed_volume', 'parsed_pages',
  'doi', 'bibcite', 'cite_id',
  'match_status', 'match_reason', 'services',
  'title_sim', 'author_match', 'year_match', 'container_match', 'volume_match', 'pages_match',
  'openalex_id', 'is_retracted', 'editorial_notice', 'verified_at', 'tool_version',
  'decided_by', 'decided_at', 'year_override', 'notes', 'owner_review')
# the columns the owner may edit by hand (everything else is written by the tool)
primary_reference_owner_columns <- c('role', 'parsed_author1', 'parsed_year', 'parsed_title',
                                     'parsed_container', 'parsed_volume', 'parsed_pages', 'notes', 'owner_review')
# `owner_review` (added 2026-10-04, #64; optional in files written before it): a
# reason, from the reference list's `review_col` or the owner, why the reference
# must be decided in the review queue whatever the services say (a known alias
# such as a web cited under another paper, a thesis, a book chapter, a work that
# reports no body sizes). A verified row with a reason is forced to pending /
# owner_review and queued with its candidates; the standing rule that theses,
# books and near-misses always queue (owner, 2026-10-04) is applied through it.
primary_reference_optional_columns <- c('owner_review')
# For a `nodoi` entry parsed_author1 may hold the full author list in BibTeX
# form ('Ikeda and Hirakawa and Imamura') when the owner approved it; the
# field is a query input only until then.

# Bib/pending_citations.csv (issue #1, 1.5)
pending_candidate_fields <- c('doi', 'title', 'author1', 'year', 'container', 'title_sim', 'services')
pending_queue_columns <- c(
  'queued_at', 'source_label', 'native_key', 'n_records', 'raw_citation', 'raw_doi',
  'parsed_author1', 'parsed_year', 'parsed_title', 'parsed_container', 'parsed_volume', 'parsed_pages',
  'reason',
  paste0('c1_', pending_candidate_fields), paste0('c2_', pending_candidate_fields),
  paste0('c3_', pending_candidate_fields),
  'scite_note', 'decision', 'decided_by', 'decided_at')

# Bib/scite_checks.csv (issue #1, 1.7; owner amendment 2026-10-04): one row per
# DOI screened for retractions and corrections in a Claude Code session. The
# screening service is recorded in `checked_by`: 'scite-mcp' (editorialNotices
# read), 'consensus-mcp' (the fallback when Scite is unavailable, returns nothing
# or fails on quota; Consensus has no retraction field, so such a row carries
# notice_type 'unchecked' and the DOI relies on the Crossref update-to and
# OpenAlex is_retracted flags that verify_services.r consults for every DOI), or
# 'none' (neither service answered: the row records the gap and the reference
# stays pending). `services` of a verified reference lists the services behind
# the decision: 'crossref;openalex' plus ';scite-mcp' or ';consensus-mcp' when a
# screening row exists for its DOI.
scite_check_columns <- c('doi', 'is_retracted', 'notice_type', 'notice_doi', 'checked_at', 'checked_by')
screening_services  <- c('scite-mcp', 'consensus-mcp', 'none')
screening_notice_none <- c('none', 'unchecked')     # notice_type values that are not a notice

# Bib/source_provenance_classes.csv (issue #1, 1.6)
provenance_class_columns <- c('source_label', 'class', 'default_provenance_type', 'equation_bibcite', 'notes')

# TaxonBodyMass_Provenance.csv.gz (issue #1, 1.3)
provenance_columns <- c('genus', 'species', 'taxon', 'source_mass', 'source_bibcite', 'origin',
                        'hop', 'via_cite_id', 'ref_role', 'provenance_type',
                        'primary_cite_id', 'primary_bibcite', 'primary_doi', 'match_status', 'n_records')

# Bib/TaxonBodyMass_CitationCiteIDs.csv: the first two columns are unchanged
# (TaxonBodyMassML reads them and nothing else); the rest were added by #1.
citeids_columns <- c('Bibcite', 'CiteID', 'doi', 'role', 'bib_file')

# the new Sheet tab BM_primary_citations (issue #1, 1.8)
sheet_primary_columns <- c('CiteID', 'Bibcite', 'Citation', 'DOI', 'Role', 'Added', 'AddedBy')

# ---- per-source reference lists ------------------------------------------------
# Where a source's reference list is and how its native keys join the records'
# `ref_keys` (parse_reflists.r). `format` selects the parser: csv (a two-column
# key/citation file), inrow (the citation text sits in every record:
# `citation_col`, an optional `doi_col`, and `intext_col`, the short in-text
# form kept as the reference's note), or one of the formats of later tiers
# (xlsx, bib, docx, pdf, html, endnote_doc). `sep` is
# the regular expression the parse script passed to SplitRefKeys(). The
# compilation's own DOI (for CandidatesFromCompilationReflist()) is read from the
# curated bib through the label's Bibcite unless `compilation_doi` is given.
# `review_col` names a column of the list whose text marks a reference for the
# owner's review whatever the services say (primary_references `owner_review`).
# `folder` names the source folder when it differs from the label, `frame` the
# cached frame (BodyMass_<frame>.Rdata) when several labels share one, and
# `prim_file` the label's primary_references file in a shared folder
# ('primary_references_<Label>.csv'; LoadPrimaryReferences() reads both names).
reflist_specs <- list(
  Kiorboe_2013 = list(format = 'csv', file = 'Kiorboe2013_TableA1_references.csv',
                      key_col = 'Reference', citation_col = 'Citation', sep = ';',
                      compiler = 'Kiorboe'),
  McCoy_2008   = list(format = 'csv', file = 'appendixS1_references.csv',
                      key_col = 'ref', citation_col = 'citation', doi_col = 'doi', sep = ';',
                      compiler = 'McCoy'),
  Hebert_etal_2016 = list(format = 'csv', file = 'references.csv', csv_sep = ';', file_encoding = 'latin1',
                          key_col = 'Ref.code', citation_col = NULL,
                          citation_cols = c('Authors', 'Year', 'Title', 'Journal.Book'),
                          type_col = 'Pub.type', sep = ',', compiler = 'Hebert'),
  Herberstein_etal_2022 = list(format = 'inrow', file = 'observations.csv',
                               citation_col = 'fullReference', intext_col = 'inTextReference',
                               compiler = 'Herberstein'),
  Ikeda_2014   = list(format = 'crossref_reflist', sep = ';', compiler = 'Ikeda'),
  Hudson_2013  = list(format = 'csv', file = 'references.csv',
                      key_col = 'key', citation_col = 'citation', sep = ';',
                      compiler = 'Hudson'),
  Wilman_etal_2014 = list(format = 'csv', file = 'references.csv',
                          key_col = 'key', citation_col = 'citation', sep = ',',
                          compiler = 'Wilman'),
  # web-level attribution (issue #64): one key per work cited for a food web
  Brose_etal_2018 = list(format = 'csv', file = 'references.csv',
                         key_col = 'key', citation_col = 'citation', doi_col = 'doi', type_col = 'note',
                         review_col = 'owner_review', sep = ';', compiler = 'Brose',
                         compilation_doi = '10.1038/s41559-019-0899-x'),
  Brose_2005   = list(format = 'csv', file = 'brose2005_references.csv', folder = 'DataRetriever',
                      frame = 'DataRetrieverAll', prim_file = 'primary_references_Brose_2005.csv',
                      key_col = 'key', citation_col = 'citation', doi_col = 'doi', type_col = 'note',
                      review_col = 'owner_review', sep = ';', compiler = 'Brose',
                      compilation_doi = '10.1890/05-0379'),
  # Appendix S2 superscript numbers 1-115, the asterisk of the unpublished rows and
  # the key S1 of the Appendix S1 ants, resolved in references.csv written by
  # parse_chown_supmat.py from the supplement PDF
  Chown_etal_2007 = list(format = 'csv', file = 'references.csv',
                         key_col = 'key', citation_col = 'raw_citation', sep = ';',
                         compiler = 'Chown'),
  AyalaBerdon_2025 = list(format = 'csv', file = 'references.csv',
                          key_col = 'key', citation_col = 'citation', sep = ';',
                          compiler = 'Ayala-Berdon',
                          compilation_doi = '10.1007/s00360-025-01630-3')  # no CiteID row yet (#71)
)

ReflistSpec <- function(source_label) {
  spec <- reflist_specs[[source_label]]
  if (is.null(spec))
    stop('No reference-list specification for ', source_label,
         ' in reflist_specs (R/library/citations/citations_config.r); add one before --init',
         call. = FALSE)
  spec$source_label <- source_label
  spec
}
