# Citation tooling (issue #1): the command line.
#
#   Rscript R/library/citations/run_citations.r --source <Src> \
#       [--init] [--verify] [--queue] [--apply-queue] [--bib] [--sheet [--no-dry-run]] \
#       [--screening-list] [--force] [--offline]
#
#   --init         build or update sources/databases/<Src>/primary_references.csv from the
#                  source's reference list (citations_config.r reflist_specs) and the
#                  ref_keys of its cached frame
#   --verify       Crossref + OpenAlex for every undecided reference (cached, polite);
#                  closed-world candidates from the compilation's deposited reference list
#   --queue        append the pending / not_found references to Bib/pending_citations.csv
#   --apply-queue  apply the owner's committed decisions
#   --bib          regenerate Bib/TaxonBodyMass_PrimaryCitations.bib from every source's
#                  accepted references (keys reused by DOI), assign bibcite and cite_id
#   --sheet        append the accepted references to the Sheet tab BM_primary_citations
#                  (dry run unless --no-dry-run); snapshot both citation tabs
#   --screening-list  the DOIs an agent should screen with Scite under the selective
#                  screening policy (notices, disagreements, doubtful identities, an
#                  audit sample of the newly certain DOIs); printed and written to
#                  reports/screening_<Src>.md; no network, nothing else written
#   --dedupe-queue maintenance: remove the duplicate rows of Bib/pending_citations.csv
#                  (an open row re-appended for a key already queued or decided, a
#                  decision recorded twice) and of Bib/scite_checks.csv (exact
#                  duplicates, an older row per DOI + service, a `none` gap row for a
#                  DOI another row answers); the removed rows are printed and written
#                  to reports/dedupe_queue_<date>.md; no network, no source file touched
#   --force        re-verify `certain` rows as well
#   --offline      never touch the network (cached responses only)
# Every step writes reports/citations_<Src>.md. RunMe.r never calls this file.

this_file <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE))
if (length(this_file) == 0) stop('run with Rscript R/library/citations/run_citations.r ...')
wd_root <- normalizePath(file.path(dirname(this_file), '..', '..', '..'))
lib <- file.path(wd_root, 'R', 'library')
source(file.path(lib, 'helpers.r'))
source(file.path(lib, 'mass_conversion.r'))
source(file.path(lib, 'dedupe_sources.r'))
source(file.path(lib, 'sheet_snapshots.r'))      # SheetAuth(), ReadSheetTab(), SnapshotSheetTab() (#118)
for (f in c('citations_config.r', 'normalise_citation.r', 'parse_reflists.r', 'verify_services.r',
            'decide.r', 'build_bib.r', 'cite_ids.r', 'sheet_append.r', 'provenance.r'))
  source(file.path(lib, 'citations', f))

args <- commandArgs(trailingOnly = TRUE)
Flag <- function(f) f %in% args
steps <- c('--init', '--verify', '--queue', '--apply-queue', '--bib', '--sheet', '--screening-list', '--dedupe-queue')
src_i <- which(args == '--source')
maintenance_only <- identical(args[args %in% steps], '--dedupe-queue')
if ((length(src_i) != 1 || src_i == length(args)) && !maintenance_only) stop('--source <Src> is required')
src <- if (length(src_i) == 1 && src_i < length(args)) args[src_i + 1] else NA_character_
known <- c('--source', src, steps, '--no-dry-run', '--force', '--offline')
if (any(!args %in% known)) stop('unknown argument(s): ', paste(setdiff(args, known), collapse = ' '))
if (!any(Flag(steps))) stop('give at least one step: ', paste(steps, collapse = ' '))

cfg  <- CitationsConfig(wd_root, offline = Flag('--offline'))
dir.create(cfg$reports_dir, showWarnings = FALSE)

# ---- --dedupe-queue (maintenance over the two shared files; no source needed) ----
if (Flag('--dedupe-queue')) {
  dq <- DedupeQueue(ReadPendingQueue(cfg$pending_csv))
  ds <- DedupeSciteChecks(ReadSciteChecks(cfg$scite_csv))
  if (nrow(dq$removed) > 0) WritePendingQueueFile(dq$queue, cfg$pending_csv)
  if (nrow(ds$removed) > 0) DropSciteCheckRows(cfg$scite_csv, ds$removed$row)
  cat(sprintf('--dedupe-queue: %d duplicate row(s) removed from %s (%d kept), %d from %s (%d kept)\n',
              nrow(dq$removed), basename(cfg$pending_csv), nrow(dq$queue), nrow(ds$removed), basename(cfg$scite_csv), nrow(ds$scite)))
  qt <- dq$removed[, c('row', 'why', 'queued_at', 'source_label', 'native_key', 'reason', 'c1_doi', 'decision', 'decided_at')]
  st <- ds$removed[, c('row', 'why', 'doi', 'notice_type', 'checked_at', 'checked_by')]
  for (i in seq_len(nrow(qt))) cat(sprintf('  queue row %s (%s): %s %s, %s, decision %s\n', qt$row[i], qt$why[i], qt$source_label[i], qt$native_key[i], qt$reason[i], if (is.na(qt$decision[i])) '(open)' else qt$decision[i]))
  for (i in seq_len(nrow(st))) cat(sprintf('  scite row %s (%s): %s %s %s\n', st$row[i], st$why[i], st$doi[i], st$checked_by[i], st$notice_type[i]))
  md <- file.path(cfg$reports_dir, sprintf('dedupe_queue_%s.md', format(Sys.Date())))
  writeLines(c(sprintf('# Duplicate queue and screening rows removed -- %s (%s)', format(Sys.Date()), citations_tool_version), '',
               sprintf('%s: %d row(s) removed, %d kept. %s: %d row(s) removed, %d kept.', basename(cfg$pending_csv), nrow(dq$removed), nrow(dq$queue),
                       basename(cfg$scite_csv), nrow(ds$removed), nrow(ds$scite)), '',
               '## pending_citations.csv', '', if (nrow(qt) > 0) MarkdownTable(qt) else 'none', '',
               '## scite_checks.csv', '', if (nrow(st) > 0) MarkdownTable(st) else 'none'), md)
  cat('  report:', md, '\n')
  if (identical(args[args %in% steps], '--dedupe-queue')) quit(save = 'no', status = 0)
}
spec <- tryCatch(ReflistSpec(src), error = function(e) NULL)
folder <- if (!is.null(spec$folder)) spec$folder else src     # the source folder under sources/databases
frame  <- if (!is.null(spec$frame)) spec$frame else folder     # the cached frame BodyMass_<frame>.Rdata
prim_path <- PrimaryReferencesPathForLabel(cfg$wd_db, src)
dir.create(file.path(wd_root, 'tmp'), showWarnings = FALSE)
cat(sprintf('run_citations: %s (%s)\n', src, citations_tool_version))

report <- list()
Note <- function(...) { msg <- sprintf(...); cat(' ', msg, '\n'); report[[length(report) + 1]] <<- msg }

# ---- the source's frame ----
LoadFrame <- function(folder) {
  f <- file.path(cfg$wd_rdata, sprintf('BodyMass_%s.Rdata', folder))
  if (!file.exists(f)) stop('cached frame not found: ', f, ' (run RunMe.r with recompile = TRUE first)')
  e <- new.env(); load(f, envir = e); get(ls(e)[1], envir = e)
}

# The compilation's own DOI, for the closed-world candidates of --verify and the
# deposited reference list of a crossref_reflist --init.
CompilationDOI <- function() {
  if (!is.null(spec$compilation_doi)) return(spec$compilation_doi)
  ids <- read.csv(cfg$citeids_csv, stringsAsFactors = FALSE, colClasses = 'character')
  bk <- ids$Bibcite[!is.na(ids$CiteID) & ids$CiteID == src]
  if (length(bk) == 0) return(NA_character_)
  bib <- ReadBibEntries(cfg$curated_bib)
  d <- bib$doi[bib$key == bk[1]]
  if (length(d) == 0) NA_character_ else d[1]
}

# ---- --init ----
if (Flag('--init')) {
  if (is.null(spec)) ReflistSpec(src)          # stops with the message
  frame <- LoadFrame(frame)
  frame <- frame[SourceLabel(frame$source_mass) == src, , drop = FALSE]
  if (!'ref_keys' %in% names(frame))
    stop('the parse script of ', src, ' does not keep ref_keys yet (SplitRefKeys() in BodyMass_', folder, '.r)')
  if (all(is.na(frame$ref_keys)))
    stop('no record of ', src, ' in the cached frame carries ref_keys (a live-download frame is rebuilt only ',
         'with its download flag on; see the source README)')
  reflist <- switch(spec$format,
    csv = ParseRefListCSV(file.path(cfg$wd_db, folder, spec$file), key_col = spec$key_col,
                          citation_col = spec$citation_col, doi_col = spec$doi_col,
                          citation_cols = spec$citation_cols, type_col = spec$type_col,
                          csv_sep = if (is.null(spec$csv_sep)) ',' else spec$csv_sep,
                          file_encoding = if (is.null(spec$file_encoding)) 'UTF-8' else spec$file_encoding,
                          review_col = spec$review_col),
    inrow = {
      raw <- read.csv(file.path(cfg$wd_db, folder, spec$file), stringsAsFactors = FALSE, check.names = FALSE,
                      colClasses = 'character', encoding = 'UTF-8')
      ParseInRowCitations(raw[[spec$citation_col]], if (is.null(spec$doi_col)) NULL else raw[[spec$doi_col]],
                          labels = if (is.null(spec$intext_col)) NULL else raw[[spec$intext_col]])$references
    },
    crossref_reflist = {
      # the paper's reference list as deposited at Crossref, joined to the
      # author-year keys of its tables (parse_reflists.r)
      comp_doi <- CompilationDOI()
      if (is.na(comp_doi))
        stop('--init for format crossref_reflist needs the compilation DOI: give compilation_doi in reflist_specs ',
             'or a doi field in the label\'s curated bib entry')
      deposited <- CandidatesFromCompilationReflist(comp_doi, cfg)
      if (nrow(deposited) == 0) stop('the Crossref record of ', comp_doi, ' deposits no references')
      native <- unique(ExplodeRefKeys(frame$ref_keys)$native_key)
      rl <- ReflistFromCrossrefReferences(deposited, native)
      un <- attr(rl, 'unresolved')
      Note('--init: compilation DOI %s deposits %d references (%d with DOI); %d of %d native keys joined to one deposited reference (%d with DOI), %d kept as the compiler\'s unpublished data, %d unresolved',
           comp_doi, nrow(deposited), sum(!is.na(deposited$doi)), sum(!grepl('^unpublished', rl$note)), length(native),
           sum(!is.na(rl$raw_doi)), sum(grepl('^unpublished', rl$note)), nrow(un))
      if (nrow(un) > 0) Note('--init: unresolved key(s): %s', paste(sprintf('%s (%s)', un$key, un$reason), collapse = '; '))
      rl
    },
    stop('--init for format ', spec$format, ' is not implemented yet'))
  skeleton <- InitPrimaryReferences(src, reflist, frame$ref_keys, compiler = spec$compiler)
  existing <- ReadPrimaryReferences(prim_path)
  prim <- MergePrimaryReferences(existing, skeleton)
  WritePrimaryReferences(prim, prim_path)
  Note('--init: %d records, %d with ref_keys (%.1f%% NA); %d native keys -> %s', nrow(frame),
       sum(!is.na(frame$ref_keys)), 100 * mean(is.na(frame$ref_keys)), nrow(prim), basename(prim_path))
  unmatched <- prim$native_key[is.na(prim$raw_citation)]
  if (length(unmatched) > 0) Note('--init: %d key(s) not in the reference list: %s', length(unmatched), paste(unmatched, collapse = ', '))
  unused <- setdiff(reflist$native_key, prim$native_key)
  if (length(unused) > 0) Note('--init: %d reference(s) of the list cited by no record: %s', length(unused), paste(unused, collapse = ', '))
  if (any(prim$role == 'self')) Note('--init: %d self reference(s): %s', sum(prim$role == 'self'), paste(prim$native_key[prim$role == 'self'], collapse = ', '))
  if (any(!is.na(prim$owner_review))) Note('--init: %d reference(s) marked for the owner\'s review: %s', sum(!is.na(prim$owner_review)), paste(prim$native_key[!is.na(prim$owner_review)], collapse = ', '))
}

prim <- ReadPrimaryReferences(prim_path)
if (is.null(prim)) stop('no ', basename(prim_path), ' for ', src, ': run --init first')

candidates <- list()
# ---- --verify / --queue ----
if (Flag('--verify') || Flag('--queue')) {
  comp_doi <- CompilationDOI()
  reflist <- if (is.na(comp_doi)) NULL else CandidatesFromCompilationReflist(comp_doi, cfg)
  Note('%s: compilation DOI %s; %d deposited references (%d with DOI)',
       if (Flag('--verify')) '--verify' else '--queue (re-scoring pending rows from the cache)',
       if (is.na(comp_doi)) 'none' else comp_doi,
       if (is.null(reflist)) 0L else nrow(reflist), if (is.null(reflist)) 0L else sum(!is.na(reflist$doi)))
  scite <- ReadSciteChecks(cfg$scite_csv)
  res <- VerifyPrimaryReferences(prim, cfg, reflist, scite, force = Flag('--force'), progress = TRUE)
  prim <- res$prim; candidates <- res$candidates
  WritePrimaryReferences(prim, prim_path)
  if (length(res$skipped) > 0)
    Note('--verify: %d reference(s) left unverified -- %s: %s', length(res$skipped), res$quota, paste(res$skipped, collapse = ', '))
  tab <- table(factor(prim$match_status, levels = c(match_statuses, NA)), useNA = 'ifany')
  Note('status counts: %s', paste(sprintf('%s %d', ifelse(is.na(names(tab)), 'unverified', names(tab)), tab)[tab > 0], collapse = ', '))
}
if (Flag('--queue')) {
  queue <- WritePendingQueue(prim, candidates, cfg$pending_csv)
  open <- queue[queue$source_label == src & (is.na(queue$decision) | !nzchar(queue$decision)), ]
  Note('--queue: %d open queue row(s) for %s in %s (%d rows in the file)', nrow(open), src, basename(cfg$pending_csv), nrow(queue))
  held <- attr(queue, 'skipped_decided')
  if (length(held) > 0) Note('--queue: %d key(s) not re-queued, their recorded decision awaits --apply-queue: %s', length(held), paste(held, collapse = ', '))
}

# ---- --apply-queue ----
if (Flag('--apply-queue')) {
  queue <- ReadPendingQueue(cfg$pending_csv)
  before <- prim$match_status
  prim <- ApplyQueueDecisions(queue, prim, cfg)
  WritePrimaryReferences(prim, prim_path)
  changed <- which(is.na(before) != is.na(prim$match_status) | (!is.na(before) & before != prim$match_status))
  Note('--apply-queue: %d decision(s) applied: %s', length(changed),
       if (length(changed) == 0) '' else paste(sprintf('%s -> %s', prim$native_key[changed], prim$match_status[changed]), collapse = ', '))
}

# ---- --bib ----
# The whole primary bib is rebuilt from every source's accepted references, so
# that it is always the deterministic image of the primary_references files.
if (Flag('--bib')) {
  curated <- ReadBibEntries(cfg$curated_bib)
  all_prim <- LoadPrimaryReferences(cfg$wd_db)
  # this source's rows are taken from memory (they may have just changed)
  all_prim <- rbind(all_prim[all_prim$source_label != src, ], prim)
  ids <- read.csv(cfg$citeids_csv, stringsAsFactors = FALSE, colClasses = 'character', na.strings = c('', 'NA'))
  res <- AssignPrimaryKeys(all_prim, cfg, curated, ids)
  all_prim <- res$prim; entries <- res$entries; authorless <- res$authorless
  acc <- which(all_prim$match_status %in% c('certain', 'approved', 'nodoi_approved'))
  WritePrimaryBib(entries, cfg$primary_bib)
  CheckBibKeysUnique(cfg$curated_bib, cfg$primary_bib)
  n_parsed <- CheckBibSyntax(cfg$primary_bib)
  # write back every source's bibcite / cite_id -- only the files whose values
  # changed (#114 item 7: an added optional column or quoting alone is no change)
  written <- character()
  for (l in unique(all_prim$source_label)) {
    p <- all_prim[all_prim$source_label == l, ]
    if (WritePrimaryReferencesIfChanged(p, PrimaryReferencesPathForLabel(cfg$wd_db, l))) written <- c(written, l)
  }
  prim <- all_prim[all_prim$source_label == src, ]
  Note('--bib: primary_references written for %d source(s)%s', length(written), if (length(written) == 0) '' else paste0(': ', paste(written, collapse = ', ')))
  if (length(res$no_record) > 0)
    Note('--bib: %d accepted DOI(s) have no Crossref record, so no entry was built and the row keeps its bibcite / cite_id as they were (an OpenAlex-only candidate approved before #114 item 3: withdraw the decision and give doi:<DOI> once it resolves at Crossref, or nodoi): %s',
         length(res$no_record), paste(res$no_record, collapse = '; '))
  if (length(authorless) > 0)
    Note('--bib: %d accepted DOI record(s) carry no author names, so their entries have no author field (owner to confirm or switch to nodoi): %s',
         length(authorless), paste(authorless, collapse = '; '))
  Note('--bib: %d entries written to %s (%d reuse a curated key); RefManageR parsed %s; %s: %d rows with bibcite',
       length(entries), basename(cfg$primary_bib),
       sum(all_prim$bibcite[acc] %in% curated$key), if (is.na(n_parsed)) 'n/a' else n_parsed, src, sum(!is.na(prim$bibcite)))
}

# ---- --sheet ----
if (Flag('--sheet')) {
  works <- list()
  for (d in unique(na.omit(prim$doi[prim$match_status %in% c('certain', 'approved')]))) works[[d]] <- CrossrefWork(d, cfg)
  rows <- BuildSheetRows(prim, works)
  dry <- !Flag('--no-dry-run')
  res <- AppendPrimaryCitations(rows, citations_sheet_url, sheet_tab_primary, dry_run = dry, snapshot_path = cfg$snapshot_primary)
  # the existing tab is snapshotted read-only at every --sheet
  bm <- ReadSheetTab(citations_sheet_url, sheet_tab_citations)
  SnapshotSheetTab(bm, cfg$snapshot_citations)
  Note('--sheet%s: %d row(s) for %s, %d new, tab had %d rows; %s snapshotted (%d rows)',
       if (dry) ' (dry run)' else '', nrow(rows), src, nrow(res$new), res$n_before, sheet_tab_citations, nrow(bm))
}

# ---- --screening-list ----
# The screening list of the selective policy (owner decision 2026-10-05):
# ScreeningCandidates() over the source's rows and Bib/scite_checks.csv, the
# audit sample seeded from the label and today's date. Offline by nature.
if (Flag('--screening-list')) {
  scite <- ReadSciteChecks(cfg$scite_csv)
  today <- Sys.Date()
  cand <- ScreeningCandidates(prim, scite, date = today)
  n_cat <- table(factor(cand$category, levels = screening_categories))
  Note('--screening-list: %d DOI(s) to screen for %s (%s); audit sample %d of %d newly certain DOI(s) (%.0f%%, at least %d), seed %d from "%s %s"',
       nrow(cand), src, paste(sprintf('%s %d', names(n_cat), n_cat), collapse = ', '),
       attr(cand, 'n_sample'), attr(cand, 'n_new_certain'), 100 * citations_screening$sample_frac, citations_screening$min_sample,
       attr(cand, 'seed'), src, attr(cand, 'date'))
  for (i in seq_len(nrow(cand)))
    cat(sprintf('  %-12s %-28s %s  %s / %s  [%s]%s\n', cand$category[i], cand$native_key[i], cand$doi[i], cand$match_status[i],
                cand$match_reason[i], cand$reason[i], if (nzchar(cand$screened_by[i])) paste0(' screened: ', cand$screened_by[i]) else ''))
  sl <- file.path(cfg$reports_dir, sprintf('screening_%s.md', src))
  tab <- cand[, c('native_key', 'n_records', 'category', 'reason', 'doi', 'match_status', 'match_reason', 'screened_by', 'parsed_year')]
  writeLines(c(sprintf('# Screening list of %s -- %s (%s)', src, format(today), citations_tool_version), '',
               'Selective screening policy (owner decision 2026-10-05): a reference is certain on Crossref + OpenAlex alone;',
               'Scite (Consensus as the fallback) is called for the DOIs below. Categories: notice (read the notice type),',
               'disagreement (the two services disagree or only one answered), doubtful (grey literature, a DOI shared by',
               sprintf('several keys, a mismatching source DOI, a reference before %d), audit_sample (a random %.0f%% of the newly',
                       citations_screening$old_year, 100 * citations_screening$sample_frac),
               sprintf('certain DOIs, at least %d: %d of %d drawn with seed %d = strtoi(substr(sha1("%s %s"), 1, 7), 16)).',
                       citations_screening$min_sample, attr(cand, 'n_sample'), attr(cand, 'n_new_certain'), attr(cand, 'seed'), src, attr(cand, 'date')),
               'A DOI already screened by scite-mcp is listed only when it carries a notice.', '',
               sprintf('%d DOI(s) to screen: %s.', nrow(cand), paste(sprintf('%s %d', names(n_cat), n_cat), collapse = ', ')), '',
               MarkdownTable(tab)), sl)
  cat('  screening list:', sl, '\n')
}

# ---- the report ----
# --screening-list alone writes only its own file (the citations report is the
# record of the verifying steps)
md <- file.path(cfg$reports_dir, sprintf('citations_%s.md', src))
if (identical(args[args %in% steps], '--screening-list')) quit(save = 'no', status = 0)
tab <- prim[, c('native_key', 'n_records', 'role', 'match_status', 'match_reason', 'doi', 'title_sim', 'bibcite', 'cite_id')]
tab$title_sim <- ifelse(is.na(tab$title_sim), '', formatC(tab$title_sim, digits = 3, format = 'f'))
writeLines(c(sprintf('# Citations of %s -- %s (%s)', src, format(Sys.time(), '%Y-%m-%d %H:%M:%S'), citations_tool_version), '',
             sprintf('Steps: %s', paste(args[args %in% c(steps, '--no-dry-run', '--force', '--offline')], collapse = ' ')), '',
             paste0('- ', unlist(report)), '', '## References', '', MarkdownTable(tab)), md)
cat('  report:', md, '\n')
