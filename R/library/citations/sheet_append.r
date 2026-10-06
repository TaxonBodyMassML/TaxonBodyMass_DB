# Citation tooling (issue #1): the lab Google Sheet.
#
#   FormatCitationText(work)            the Citation cell from a Crossref work record only
#   FormatCitationTextNoDOI(row, ...)   the Citation cell of an owner-approved DOI-less entry
#   BuildSheetRows(prim, works)         the rows of BM_primary_citations for a source
#   AppendPrimaryCitations(rows, ...)   set-difference on Bibcite, print the diff, snapshot
#                                       before and after, googlesheets4::sheet_append() to
#                                       BM_primary_citations only; dry run by default
# The Sheet is only ever appended to, and only its BM_primary_citations tab; the
# tab is created (headers only) when it does not exist. Every network action
# goes through the `io` list so that the tests run on fakes. SheetAuth(),
# ReadSheetTab() and SnapshotSheetTab() live in R/library/sheet_snapshots.r
# (#118; shared with RunMe.r), which the callers of this file source first.

SheetTabExists <- function(url, tab) { SheetAuth(); tab %in% googlesheets4::sheet_names(url) }

# Create `tab` with the header row only (sheet_write() of a 0-row frame).
CreateSheetTab <- function(url, tab, columns) {
  SheetAuth()
  empty <- as.data.frame(setNames(rep(list(character()), length(columns)), columns), stringsAsFactors = FALSE)
  googlesheets4::sheet_write(empty, ss = url, sheet = tab)
  invisible(TRUE)
}

AppendSheetRows <- function(url, tab, rows) { SheetAuth(); googlesheets4::sheet_append(url, data = rows, sheet = tab); invisible(TRUE) }

# The default I/O: googlesheets4. Tests pass a list with the same four names.
SheetIO <- function() list(read = ReadSheetTab, exists = SheetTabExists, create = CreateSheetTab, append = AppendSheetRows)

# ---- citation text -----------------------------------------------------------------------
Initials <- function(given) {
  if (is.null(given) || !nzchar(given)) return('')
  parts <- strsplit(trimws(given), '[\\s]+', perl = TRUE)[[1]]
  paste(vapply(parts, function(p) {
    sub <- strsplit(p, '-', fixed = TRUE)[[1]]
    paste(paste0(substr(sub, 1, 1), '.'), collapse = '-')
  }, character(1)), collapse = ' ')
}

CrossrefAuthorList <- function(work) {
  if (length(work[['author']]) == 0) return(NA_character_)
  names <- vapply(work[['author']], function(a) {
    if (!is.null(a[['family']])) { ini <- Initials(if (is.null(a[['given']])) '' else a[['given']]); if (nzchar(ini)) paste0(a[['family']], ', ', ini) else a[['family']] }
    else if (!is.null(a[['name']])) a[['name']] else NA_character_ }, character(1))
  names <- names[!is.na(names)]
  if (length(names) == 0) return(NA_character_)
  if (length(names) == 1) return(names)
  if (length(names) == 2) return(paste(names, collapse = ' & '))
  paste0(paste(names[-length(names)], collapse = ', '), ', & ', names[length(names)])
}

StripTags <- function(x) { x <- gsub('<[^>]+>', '', x, perl = TRUE); x <- gsub('&amp;', '&', x, fixed = TRUE); trimws(gsub('\\s+', ' ', x, perl = TRUE)) }

# 'Authors (Year). Title. Container, volume(issue), pages. https://doi.org/DOI'
# from a Crossref work record and nothing else (`year_override`: the owner's
# recorded ':year=' decision, see BuildBibEntry()).
FormatCitationText <- function(work, year_override = NA_integer_) {
  if (is.null(work) || is.null(work[['DOI']])) stop('FormatCitationText(): a Crossref work record with a DOI is required', call. = FALSE)
  au <- CrossrefAuthorList(work); yr <- CrossrefYear(work)
  if (!is.na(year_override)) yr <- as.integer(year_override)
  title <- StripTags(CrossrefTitle(work))
  cont <- if (length(work[['container-title']]) > 0) StripTags(work[['container-title']][[1]]) else
          if (!is.null(work[['publisher']])) StripTags(work[['publisher']]) else NA_character_
  vol <- work[['volume']]; iss <- work[['issue']]; pg <- work[['page']]   # [[ ]]: `$issue` would match `issued`
  src <- cont
  if (!is.null(vol)) src <- paste0(src, ', ', vol, if (!is.null(iss)) paste0('(', iss, ')') else '')
  if (!is.null(pg)) src <- paste0(src, ', ', gsub('-+', '-', pg))
  parts <- c(if (!is.na(au)) au, paste0('(', if (is.na(yr)) 'n.d.' else yr, ').'),
             if (!is.na(title)) paste0(sub('[.]$', '', title), '.'), if (!is.na(src)) paste0(src, '.'),
             paste0('https://doi.org/', CleanDOI(work[['DOI']])))
  paste(parts, collapse = ' ')
}

# The Citation cell of a DOI-less, owner-approved entry, from the parsed
# fields: the author field as approved (a surname, or a BibTeX 'A and B and C'
# list written 'A, B, & C'; a corporate name's braces, '{Birdcare
# Avicultural}', are dropped), never an invented 'et al.'.
FormatCitationTextNoDOI <- function(row) {
  row <- as.list(row)
  src <- row$parsed_container
  if (!is.na(row$parsed_volume)) src <- paste0(src, ', ', row$parsed_volume)
  if (!is.na(row$parsed_pages)) src <- paste0(src, ', ', row$parsed_pages)
  au <- NA_character_
  if (!is.na(row$parsed_author1)) {
    names <- trimws(gsub('[{}]', '', strsplit(row$parsed_author1, '\\s+and\\s+', perl = TRUE)[[1]]))
    au <- if (length(names) == 1) names else if (length(names) == 2) paste(names, collapse = ' & ') else
          paste0(paste(names[-length(names)], collapse = ', '), ', & ', names[length(names)])
  }
  parts <- c(if (!is.na(au)) au,
             paste0('(', if (is.na(row$parsed_year)) 'n.d.' else row$parsed_year, ').'),
             if (!is.na(row$parsed_title)) paste0(sub('[.]$', '', row$parsed_title), '.'),
             if (!is.na(src)) paste0(src, '.'), 'No DOI.')
  paste(parts, collapse = ' ')
}

# The BM_primary_citations rows for the accepted references of a
# primary_references frame: `works` is a list of Crossref work records keyed by
# DOI (from the cache). Rows need bibcite and cite_id (set by --bib). A
# `manual_bib` row cites a curated bib key (an owner's `manual:<Key>` decision,
# such as Vanni_2017's 'Ikeda database' -> Ikeda:2014aa): its Sheet row is the
# owner's (BM_citations) and the curated entry may carry no DOI, so no row is
# built for it (issue #99).
BuildSheetRows <- function(prim, works, added = format(Sys.Date()), added_by = citations_tool_version) {
  ok <- prim$match_status %in% c('certain', 'approved', 'nodoi_approved') & !is.na(prim$bibcite) & !is.na(prim$cite_id) &
    !(prim$match_reason %in% 'manual_bib')
  rows <- lapply(which(ok), function(i) {
    r <- prim[i, ]
    cit <- if (!is.na(r$doi) && !is.null(works[[r$doi]])) FormatCitationText(works[[r$doi]], r$year_override)
           else if (r$match_status == 'nodoi_approved') FormatCitationTextNoDOI(r)
           else NA_character_
    data.frame(CiteID = r$cite_id, Bibcite = paste0('\\citep{', r$bibcite, '}'), Citation = cit,
               DOI = if (is.na(r$doi)) '' else r$doi, Role = r$role, Added = added, AddedBy = added_by,
               stringsAsFactors = FALSE)
  })
  out <- if (length(rows) == 0) as.data.frame(setNames(rep(list(character()), length(sheet_primary_columns)), sheet_primary_columns), stringsAsFactors = FALSE)
         else do.call(rbind, rows)
  out <- out[!duplicated(out$Bibcite), , drop = FALSE]
  if (any(is.na(out$Citation)))
    stop('BuildSheetRows(): no Crossref record for ', paste(out$Bibcite[is.na(out$Citation)], collapse = ', '), call. = FALSE)
  rownames(out) <- NULL
  out[, sheet_primary_columns]
}

# Append `rows` (BuildSheetRows()) to `tab`: the rows whose Bibcite is already in
# the tab are skipped (idempotent), the difference is printed, and with
# dry_run = FALSE the tab is snapshotted to `snapshot_path` before and after the
# append (the committed file is the after state). A dry run, or a run with
# nothing to append, snapshots the existing tab as it is (read-only; #114).
# A missing tab is created with headers only. Returns list(new, n_before,
# n_after, dry_run).
AppendPrimaryCitations <- function(rows, url = citations_sheet_url, tab = sheet_tab_primary, dry_run = TRUE,
                                   snapshot_path = NULL, io = SheetIO()) {
  if (tab != sheet_tab_primary) stop('AppendPrimaryCitations(): writes go to ', sheet_tab_primary, ' only', call. = FALSE)
  rows <- as.data.frame(rows, stringsAsFactors = FALSE)
  miss <- setdiff(sheet_primary_columns, names(rows))
  if (length(miss) > 0) stop('AppendPrimaryCitations(): rows lack column(s) ', paste(miss, collapse = ', '), call. = FALSE)
  rows <- rows[, sheet_primary_columns]
  exists <- io$exists(url, tab)
  if (!exists) {
    message(sprintf('  tab %s does not exist: %s', tab, if (dry_run) 'would be created (dry run)' else 'creating it with headers only'))
    if (!dry_run) { io$create(url, tab, sheet_primary_columns); exists <- TRUE }
  }
  existing <- if (exists) io$read(url, tab) else as.data.frame(setNames(rep(list(character()), length(sheet_primary_columns)), sheet_primary_columns), stringsAsFactors = FALSE)
  if (!'Bibcite' %in% names(existing)) stop(tab, ' has no Bibcite column', call. = FALSE)
  new <- rows[!rows$Bibcite %in% existing$Bibcite, , drop = FALSE]
  dup <- new$CiteID %in% existing$CiteID
  if (any(dup)) stop('CiteID(s) already in ', tab, ' under another Bibcite: ', paste(new$CiteID[dup], collapse = ', '), call. = FALSE)
  message(sprintf('  %s: %d rows in the tab, %d to append (%d already present)%s', tab, nrow(existing), nrow(new),
                  nrow(rows) - nrow(new), if (dry_run) ' -- DRY RUN, nothing written' else ''))
  if (nrow(new) > 0) print(new[, c('CiteID', 'Bibcite', 'DOI', 'Role')], row.names = FALSE)
  n_after <- nrow(existing)
  if (!dry_run && nrow(new) > 0) {
    if (!is.null(snapshot_path)) SnapshotSheetTab(existing, snapshot_path)
    io$append(url, tab, new)
    after <- io$read(url, tab)
    n_after <- nrow(after)
    if (!is.null(snapshot_path)) SnapshotSheetTab(after, snapshot_path)
    missing_after <- new$Bibcite[!new$Bibcite %in% after$Bibcite]
    if (length(missing_after) > 0) stop('after the append the tab lacks ', paste(missing_after, collapse = ', '), call. = FALSE)
  } else if (!is.null(snapshot_path) && exists) {
    SnapshotSheetTab(existing, snapshot_path)
  }
  invisible(list(new = new, n_before = nrow(existing), n_after = n_after, dry_run = dry_run))
}
