# Citation tooling (issue #1): the command line.
#
#   Rscript R/library/citations/run_citations.r --source <Src> \
#       [--init] [--verify] [--queue] [--apply-queue] [--bib] [--sheet [--no-dry-run]] \
#       [--force] [--offline]
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
for (f in c('citations_config.r', 'normalise_citation.r', 'parse_reflists.r', 'verify_services.r',
            'decide.r', 'build_bib.r', 'cite_ids.r', 'sheet_append.r', 'provenance.r'))
  source(file.path(lib, 'citations', f))

args <- commandArgs(trailingOnly = TRUE)
Flag <- function(f) f %in% args
src_i <- which(args == '--source')
if (length(src_i) != 1 || src_i == length(args)) stop('--source <Src> is required')
src <- args[src_i + 1]
steps <- c('--init', '--verify', '--queue', '--apply-queue', '--bib', '--sheet')
known <- c('--source', src, steps, '--no-dry-run', '--force', '--offline')
if (any(!args %in% known)) stop('unknown argument(s): ', paste(setdiff(args, known), collapse = ' '))
if (!any(Flag(steps))) stop('give at least one step: ', paste(steps, collapse = ' '))

cfg  <- CitationsConfig(wd_root, offline = Flag('--offline'))
spec <- tryCatch(ReflistSpec(src), error = function(e) NULL)
folder <- if (!is.null(spec$folder)) spec$folder else src     # the source folder under sources/databases
frame  <- if (!is.null(spec$frame)) spec$frame else folder     # the cached frame BodyMass_<frame>.Rdata
prim_path <- PrimaryReferencesPathForLabel(cfg$wd_db, src)
dir.create(cfg$reports_dir, showWarnings = FALSE)
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

# The compilation's own DOI, for the closed-world candidates.
CompilationDOI <- function() {
  if (!is.null(spec$compilation_doi)) return(spec$compilation_doi)
  ids <- read.csv(cfg$citeids_csv, stringsAsFactors = FALSE, colClasses = 'character')
  bk <- ids$Bibcite[!is.na(ids$CiteID) & ids$CiteID == src]
  if (length(bk) == 0) return(NA_character_)
  bib <- ReadBibEntries(cfg$curated_bib)
  d <- bib$doi[bib$key == bk[1]]
  if (length(d) == 0) NA_character_ else d[1]
}

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
  known_keys <- c(curated$key, ids$Bibcite)
  known_dois <- setNames(curated$doi, curated$key)
  known_ids  <- ids[, intersect(c('CiteID', 'Bibcite', 'doi'), names(ids))]
  entries <- character()
  authorless <- character()
  acc <- which(all_prim$match_status %in% c('certain', 'approved', 'nodoi_approved'))
  # deterministic order: by DOI then source/key, so that keys do not depend on the run
  acc <- acc[order(is.na(all_prim$doi[acc]), all_prim$doi[acc], all_prim$source_label[acc], all_prim$native_key[acc], method = 'radix')]
  for (i in acc) {
    r <- all_prim[i, ]
    if (!is.na(r$doi)) {
      w <- CrossrefWork(r$doi, cfg)
      if (is.null(w)) stop('no Crossref record for accepted DOI ', r$doi, ' (', r$source_label, ' ', r$native_key, ')')
      fam <- CrossrefFirstSurname(w)
      # a record without any author name: the key is minted from the
      # reference's parsed surname (a key, not bib text) and the author-less
      # entry is reported for the owner (#64)
      if (is.na(fam) || !nzchar(fam)) {
        fam <- FirstOfAuthorList(r$parsed_author1)
        if (is.na(fam) || !nzchar(fam)) fam <- 'Anon'
        authorless <- c(authorless, sprintf('%s %s (%s)', r$source_label, r$native_key, r$doi))
      }
      yr <- CrossrefYear(w)
      key <- if (!is.na(r$bibcite) && (r$bibcite %in% names(entries) || r$bibcite %in% curated$key)) r$bibcite
             else BibKeyFor(fam, yr, r$doi, known_keys, c(known_dois, setNames(all_prim$doi[acc], all_prim$bibcite[acc])[!is.na(all_prim$bibcite[acc])]))
      if (!key %in% curated$key && !key %in% names(entries)) entries[key] <- BuildBibEntry(w, key, r$year_override)
      known_keys <- union(known_keys, key)
      all_prim$bibcite[i] <- key
      all_prim$cite_id[i] <- CiteIDFor(fam, yr, r$doi, key, known_ids)
    } else if (r$match_status == 'nodoi_approved') {
      surname <- FirstOfAuthorList(r$parsed_author1)
      # the same DOI-less work approved for another source keeps its key; the
      # entry is built from the row that owns the key
      twin <- if (is.na(r$bibcite)) MatchingNoDOIEntry(r, all_prim) else NULL
      key <- if (!is.na(r$bibcite)) r$bibcite else if (!is.null(twin)) twin$bibcite else BibKeyFor(surname, r$parsed_year, NA, known_keys)
      if (!key %in% curated$key && !key %in% names(entries)) {
        own <- if (!is.null(twin)) twin else r
        entries[key] <- BuildBibEntryNoDOI(own, key, own$decided_by, own$decided_at)
      }
      known_keys <- union(known_keys, key)
      all_prim$bibcite[i] <- key
      all_prim$cite_id[i] <- CiteIDFor(surname, r$parsed_year, NA, key, known_ids)
    } else if (r$match_reason %in% 'manual_bib') {
      if (!r$bibcite %in% curated$key) stop('manual bibcite ', r$bibcite, ' (', r$source_label, ' ', r$native_key, ') is not in ', basename(cfg$curated_bib))
      all_prim$cite_id[i] <- CiteIDFor(sub(':.*$', '', r$bibcite), sub('^.*:(\\d{4}).*$', '\\1', r$bibcite), NA, r$bibcite, known_ids)
    }
    if (!is.na(all_prim$cite_id[i]) && !all_prim$cite_id[i] %in% known_ids$CiteID)
      known_ids <- rbind(known_ids, data.frame(CiteID = all_prim$cite_id[i], Bibcite = all_prim$bibcite[i],
                                               doi = if ('doi' %in% names(known_ids)) r$doi else NULL, stringsAsFactors = FALSE)[, names(known_ids)])
  }
  WritePrimaryBib(entries, cfg$primary_bib)
  CheckBibKeysUnique(cfg$curated_bib, cfg$primary_bib)
  n_parsed <- CheckBibSyntax(cfg$primary_bib)
  # write back every source's bibcite / cite_id
  for (l in unique(all_prim$source_label)) {
    p <- all_prim[all_prim$source_label == l, ]
    WritePrimaryReferences(p, PrimaryReferencesPathForLabel(cfg$wd_db, l))
  }
  prim <- all_prim[all_prim$source_label == src, ]
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

# ---- the report ----
md <- file.path(cfg$reports_dir, sprintf('citations_%s.md', src))
tab <- prim[, c('native_key', 'n_records', 'role', 'match_status', 'match_reason', 'doi', 'title_sim', 'bibcite', 'cite_id')]
tab$title_sim <- ifelse(is.na(tab$title_sim), '', formatC(tab$title_sim, digits = 3, format = 'f'))
writeLines(c(sprintf('# Citations of %s -- %s (%s)', src, format(Sys.time(), '%Y-%m-%d %H:%M:%S'), citations_tool_version), '',
             sprintf('Steps: %s', paste(args[args %in% c(steps, '--no-dry-run', '--force', '--offline')], collapse = ' ')), '',
             paste0('- ', unlist(report)), '', '## References', '', MarkdownTable(tab)), md)
cat('  report:', md, '\n')
