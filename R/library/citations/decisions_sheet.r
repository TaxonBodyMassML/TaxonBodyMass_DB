# Citation tooling (issue #1): the owner's decisions on the Sheet tab
# BM_decisions (owner decision 2026-10-06).
#
#   DecisionsSheetIO()                   SheetIO() plus write_column() and set_validation();
#                                        the tests pass fakes with the same names
#   FormatParsedCell(row)                'Author (Year) Title. Container vol: pages' of a queue row
#   CandidateCell(doi, title, ...)       a HYPERLINK formula 'title (year) container [sim]' to doi.org
#   BuildDecisionRows(queue, pushed_at)  the open queue rows as tab rows
#   PushDecisionRows(queue, ...)         append the rows not yet on the tab (key source_label +
#                                        native_key + queued_at), dry run by default, snapshot
#                                        before and after, the decision dropdown set afterwards
#   SetDecisionValidation(url, tab, col) the dropdown on the `decision` column (Sheets batchUpdate)
#   CiteNote(note), ParseCiteNote(note) the `cite: <full citation>` form of owner_note (2026-10-08):
#                                        the citation text, and its parsed fields with the missing ones
#   ResolveTabDecision(tab_row, q, cfg)  what the owner typed -> a decision, or a per-row error
#   PullDecisions(queue, tab, ...)       pure: the tab read back -> the queue with the decisions
#                                        (and the parsed fields of a cite: note) written and one
#                                        status per tab row, in the read's order
#   PullSummary(results)                 pulled / deferred / errors / ignored per source
#   ReadDecisionItems(path), WriteDecisionItems(items, path)   Bib/decision_items.csv
#   PushDecisionItems(items, ...)        the items not yet on BM_decision_items (key item_id)
#   PullDecisionItems(items, tab, ...)   pure: a new answer on the tab -> answer + answered_at
#   AppendRoundLog(path, title, lines)   a dated entry in audit/provenance_rounds.md
#
# The tab is appended to and its `status` column rewritten; no other cell is
# ever written by code, and the owner's cells are read back as text (the
# candidate cells come back as their display text, never as formulas). The
# pull never stops on a bad decision: every problem is written to the row's
# `status` and the row stays open in the queue. A decision pulled into the
# queue is the committed decision like one typed into the CSV (`decided_by`
# owner, `decided_at` the pull date), and the existing per-source
# --apply-queue applies it. The reader, the snapshot writer and the append
# are those of sheet_snapshots.r and sheet_append.r.

# ---- the io ----------------------------------------------------------------------------
# The columns that carry a formula: wrapped for googlesheets4 just before the
# append, so that everything else in this file handles plain text.
decision_formula_columns <- c('c1', 'c2', 'c3')
FormulaColumns <- function(rows) {
  for (col in intersect(decision_formula_columns, names(rows))) rows[[col]] <- googlesheets4::gs4_formula(rows[[col]])
  rows
}
AppendDecisionRows <- function(url, tab, rows) AppendSheetRows(url, tab, FormulaColumns(rows))

# A1 column letters from a position (1 -> A, 27 -> AA).
ColumnLetter <- function(n) {
  out <- ''
  while (n > 0) { r <- (n - 1) %% 26; out <- paste0(LETTERS[r + 1], out); n <- (n - 1) %/% 26 }
  out
}

# Rewrite one column below the header with `values` (one range_write(),
# nothing else touched).
WriteSheetColumn <- function(url, tab, col_index, values) {
  SheetAuth()
  L <- ColumnLetter(col_index)
  googlesheets4::range_write(url, data = data.frame(x = as.character(values), stringsAsFactors = FALSE), sheet = tab,
                             range = sprintf('%s2:%s%d', L, L, length(values) + 1L), col_names = FALSE, reformat = FALSE)
  invisible(length(values))
}

# The dropdown on column `col_index` from row 2 down (no end row): a
# ONE_OF_LIST rule, not strict (free-text decisions stay allowed), shown as
# a chip list. googlesheets4 exports no validation call, so the request is
# built by hand and sent through its request_generate() / request_make(),
# with the token that already writes the Sheet. Idempotent: setting the same
# rule again changes nothing.
SetDecisionValidation <- function(url, tab, col_index, choices = decision_tab_choices) {
  SheetAuth()
  ss <- googlesheets4::gs4_get(url)
  sheet_id <- ss$sheets$id[ss$sheets$name == tab]
  if (length(sheet_id) != 1) stop('SetDecisionValidation(): no tab ', tab, call. = FALSE)
  req <- list(setDataValidation = list(
    range = list(sheetId = sheet_id, startRowIndex = 1L, startColumnIndex = col_index - 1L, endColumnIndex = col_index),
    rule  = list(condition = list(type = 'ONE_OF_LIST', values = lapply(choices, function(v) list(userEnteredValue = v))),
                 strict = FALSE, showCustomUi = TRUE)))
  r <- googlesheets4::request_generate('sheets.spreadsheets.batchUpdate',
                                       params = list(spreadsheetId = as.character(googlesheets4::as_sheets_id(url)), requests = list(req)))
  gargle::response_process(googlesheets4::request_make(r))
  invisible(TRUE)
}

DecisionsSheetIO <- function() {
  io <- SheetIO()
  io$append <- AppendDecisionRows
  c(io, list(write_column = WriteSheetColumn, set_validation = SetDecisionValidation))
}

# ---- the cells -----------------------------------------------------------------------------
Cell <- function(x) if (Nz(x)) trimws(as.character(x)) else NA_character_

# One line for the parsed fields: 'Author (Year) Title. Container vol: pages',
# the parts that exist in that order ('(2002) Journal of Mammalogy 83: 1-19'
# for a title-less key).
FormatParsedCell <- function(row) {
  row <- as.list(row)
  au <- Cell(row$parsed_author1); yr <- Cell(row$parsed_year); ti <- Cell(row$parsed_title)
  co <- Cell(row$parsed_container); vo <- Cell(row$parsed_volume); pg <- Cell(row$parsed_pages)
  src <- paste(c(co, vo)[!is.na(c(co, vo))], collapse = ' ')
  if (!is.na(pg)) src <- if (nzchar(src)) paste0(src, ': ', pg) else pg
  paste(c(if (!is.na(au)) au, paste0('(', if (is.na(yr)) 'n.d.' else yr, ')'),
          if (!is.na(ti)) paste0(sub('[.]$', '', ti), '.'), if (nzchar(src)) src), collapse = ' ')
}

# A clickable candidate: =HYPERLINK("https://doi.org/<doi>", "<title (year)
# container [sim]>"), the title cut to 90 characters, tags stripped, a quote
# doubled, line breaks and tabs made spaces; NA when there is no candidate.
# Read back with col_types = 'c' the cell gives the label.
CandidateCell <- function(doi, title, year, container, sim) {
  if (!Nz(doi)) return(NA_character_)
  Clean <- function(x) if (!Nz(x)) '' else gsub('"', '""', gsub('\\s+', ' ', StripTags(as.character(x)), perl = TRUE), fixed = TRUE)
  t <- Clean(title)
  if (nchar(t) > 90) t <- paste0(substr(t, 1, 87), '...')
  label <- paste0(t, if (Nz(year)) paste0(' (', trimws(year), ')') else '', if (Nz(container)) paste0(' ', Clean(container)) else '',
                  if (Nz(sim)) paste0(' [', trimws(sim), ']') else '')
  sprintf('=HYPERLINK("https://doi.org/%s", "%s")', utils::URLencode(trimws(doi), reserved = FALSE), trimws(label))
}

# The open rows of the queue as tab rows (sheet_decisions_columns): the
# decision, note and status cells empty, `pushed_at` the push date.
BuildDecisionRows <- function(queue, pushed_at = format(Sys.Date())) {
  open <- queue[is.na(queue$decision) | !nzchar(trimws(queue$decision)), , drop = FALSE]
  n <- nrow(open)
  Cand <- function(k) vapply(seq_len(n), function(i) CandidateCell(open[[paste0('c', k, '_doi')]][i], open[[paste0('c', k, '_title')]][i], open[[paste0('c', k, '_year')]][i],
                                                                open[[paste0('c', k, '_container')]][i], open[[paste0('c', k, '_title_sim')]][i]), character(1))
  out <- data.frame(source_label = open$source_label, native_key = open$native_key, queued_at = open$queued_at, n_records = open$n_records, reason = open$reason,
                    parsed = vapply(seq_len(n), function(i) FormatParsedCell(open[i, ]), character(1)),
                    c1 = Cand(1), c2 = Cand(2), c3 = Cand(3), notice = open$scite_note,
                    fields_complete = vapply(seq_len(n), function(i) if (FieldsComplete(open[i, ])) 'yes' else 'no', character(1)),
                    recommendation = open$recommendation, recommendation_reason = open$recommendation_reason,
                    decision = rep(NA_character_, n), owner_note = rep(NA_character_, n), raw_citation = open$raw_citation,
                    pushed_at = rep(pushed_at, n), status = rep(NA_character_, n), stringsAsFactors = FALSE)
  rownames(out) <- NULL
  out[, sheet_decisions_columns]
}

# ---- the push -----------------------------------------------------------------------------
# Append the rows of `rows` whose key (`key_cols`) is not yet on `tab`: the
# pattern of AppendPrimaryCitations() -- a missing tab is created with
# headers only, the difference is printed per source, with dry_run = FALSE
# the tab is snapshotted before and after the append and re-read to check
# that every new key is present; a dry run or a run with nothing to append
# snapshots the existing tab as it is. Rows already on the tab are never
# rewritten (a recommendation changed after the push is not shown; delete
# the row on the tab to push it again). Keys appearing twice on the tab
# (two pushes racing) are reported in `duplicates`. Returns list(new,
# n_before, n_after, dry_run, duplicates).
AppendKeyedRows <- function(rows, key_cols, url, tab, columns, dry_run = TRUE, snapshot_path = NULL, io = DecisionsSheetIO(), what = 'row') {
  rows <- as.data.frame(rows, stringsAsFactors = FALSE)
  miss <- setdiff(columns, names(rows))
  if (length(miss) > 0) stop('rows for ', tab, ' lack column(s) ', paste(miss, collapse = ', '), call. = FALSE)
  rows <- rows[, columns, drop = FALSE]
  Key <- function(d) do.call(paste, c(lapply(key_cols, function(col) ifelse(is.na(d[[col]]), '', as.character(d[[col]]))), sep = '\r'))
  exists <- io$exists(url, tab)
  if (!exists) {
    message(sprintf('  tab %s does not exist: %s', tab, if (dry_run) 'would be created (dry run)' else 'creating it with headers only'))
    if (!dry_run) { io$create(url, tab, columns); exists <- TRUE }
  }
  existing <- if (exists) io$read(url, tab) else as.data.frame(setNames(rep(list(character()), length(columns)), columns), stringsAsFactors = FALSE)
  miss <- setdiff(key_cols, names(existing))
  if (length(miss) > 0) stop(tab, ' has no ', paste(miss, collapse = ', '), ' column', call. = FALSE)
  new <- rows[!Key(rows) %in% Key(existing), , drop = FALSE]
  message(sprintf('  %s: %d %s(s) in the tab, %d to append (%d already present)%s', tab, nrow(existing), what, nrow(new),
                  nrow(rows) - nrow(new), if (dry_run) ' -- DRY RUN, nothing written' else ''))
  if (nrow(new) > 0 && 'source_label' %in% names(new)) {
    per <- table(new$source_label)
    message('    ', paste(sprintf('%s %d', names(per), per), collapse = ', '))
  }
  n_after <- nrow(existing); after <- existing
  if (!dry_run && nrow(new) > 0) {
    if (!is.null(snapshot_path)) SnapshotSheetTab(existing, snapshot_path)
    io$append(url, tab, new)
    after <- io$read(url, tab)
    n_after <- nrow(after)
    if (!is.null(snapshot_path)) SnapshotSheetTab(after, snapshot_path)
    missing_after <- Key(new)[!Key(new) %in% Key(after)]
    if (length(missing_after) > 0) stop('after the append ', tab, ' lacks ', length(missing_after), ' of the new ', what, 's', call. = FALSE)
  } else if (!is.null(snapshot_path) && exists) {
    SnapshotSheetTab(existing, snapshot_path)
  }
  k <- Key(after)
  duplicates <- unique(k[duplicated(k)])
  if (length(duplicates) > 0) message(sprintf('  %s: %d key(s) appear more than once on the tab (two pushes?); the pull marks them as errors', tab, length(duplicates)))
  invisible(list(new = new, n_before = nrow(existing), n_after = n_after, dry_run = dry_run, duplicates = gsub('\r', ' ', duplicates, fixed = TRUE)))
}

# The open queue rows to BM_decisions; after a real push the decision
# dropdown is (re)set. A rejected batchUpdate does not undo the push: the
# error is returned as `validation_error` and the README's manual recipe
# applies. Returns AppendKeyedRows()'s list plus validation_error.
PushDecisionRows <- function(queue, url = citations_sheet_url, tab = sheet_tab_decisions, dry_run = TRUE, snapshot_path = NULL,
                             io = DecisionsSheetIO(), pushed_at = format(Sys.Date())) {
  rows <- BuildDecisionRows(queue, pushed_at)
  res <- AppendKeyedRows(rows, c('source_label', 'native_key', 'queued_at'), url, tab, sheet_decisions_columns,
                         dry_run = dry_run, snapshot_path = snapshot_path, io = io, what = 'queue row')
  res$validation_error <- NA_character_
  if (!dry_run) {
    v <- tryCatch({ io$set_validation(url, tab, match('decision', sheet_decisions_columns)); NA_character_ },
                  error = function(e) conditionMessage(e))
    res$validation_error <- v
    if (!is.na(v)) message('  the decision dropdown could not be set (', v, '); set it by hand (README, section "Owner decisions in the Sheet")')
  }
  invisible(res)
}

# ---- the pull -----------------------------------------------------------------------------
# The `cite:` form of owner_note (owner request 2026-10-08): a note reading
# `cite: <full citation>` (the prefix in any case, with or without a space)
# supplies the bibliographic fields of a DOI-less entry, so that the owner
# never edits parsed_* in primary_references.csv by hand. CiteNote()
# (decide.r, which --apply-queue uses too) gives the citation text, NA for
# any other note; ParseCiteNote() parses it with ParseCitationString() into
# the six parsed_* fields (as the queue stores them, every one character)
# and names the required ones (author1, year, title, container: what
# BuildBibEntryNoDOI() needs) that are missing. NULL for any other note.
ParseCiteNote <- function(note) {
  cite <- CiteNote(note)
  if (is.na(cite)) return(NULL)
  p <- ParseCitationString(cite)
  parsed <- lapply(setNames(cite_note_fields, cite_note_fields), function(col) { v <- p[[col]][1]; if (Nz(v)) as.character(v) else NA_character_ })
  list(citation = cite, parsed = parsed, missing = MissingFields(parsed))
}

# What the owner typed in `decision` of one tab row, resolved against its
# queue row: an empty cell or `defer` leaves the row open (status deferred);
# `accept` takes the recommendation shown on the tab (the queue's when the
# tab cell is empty; an error when there is none); anything else must match
# the grammar and pass QueueDecisionProblems() with decided_by / decided_at
# as the pull will write them; a `doi:` decision is resolved at Crossref
# when `cfg` is online (offline: pulled unchecked, said in the message, and
# --apply-queue will still stop on it if it does not resolve). An owner_note
# in the `cite:` form is parsed first: a citation missing a required field
# is a per-row error whatever the cell says; a complete one makes an empty
# cell `nodoi`, leaves any typed decision (and `defer`) as it is, and is
# shown in the status as `pulled <date> (cite: Author (Year) Title.
# Container vol: pages)`. Returns list(decision, status, message, parsed):
# decision NA unless the row is decided; `parsed` the cite: fields (a named
# list of the six parsed_* columns) when a decided row carries them, else NULL.
ResolveTabDecision <- function(tab_row, queue_row, cfg = NULL, pulled_at = format(Sys.Date()), decided_by = 'owner') {
  tab_row <- as.list(tab_row); queue_row <- as.list(queue_row)
  Err <- function(msg) list(decision = NA_character_, status = paste0('error: ', msg), message = msg, parsed = NULL)
  cite <- ParseCiteNote(tab_row$owner_note)
  if (!is.null(cite) && length(cite$missing) > 0)
    return(Err(sprintf('cite: could not be parsed (missing: %s); edit the note or add the fields in parentheses', paste(cite$missing, collapse = ', '))))
  cell <- Cell(tab_row$decision)
  if (is.na(cell) && !is.null(cite)) cell <- 'nodoi'          # the note implies the decision
  if (is.na(cell) || tolower(cell) == 'defer') return(list(decision = NA_character_, status = 'deferred', message = NA_character_, parsed = NULL))
  decision <- cell
  if (tolower(cell) == 'accept') {
    rec <- Cell(tab_row$recommendation)
    if (is.na(rec)) rec <- Cell(queue_row$recommendation)
    if (is.na(rec)) return(Err('accept with no recommendation: type the decision'))
    decision <- rec
  }
  if (!ValidateDecision(decision))
    return(Err(sprintf('%s is not a decision (1|2|3, doi:10..., manual:<Key>, nodoi, self, drop; optional :year=YYYY)', shQuote(decision))))
  q <- queue_row; q$decision <- decision; q$decided_by <- decided_by; q$decided_at <- pulled_at
  problems <- QueueDecisionProblems(q)
  if (length(problems) > 0) {
    prefix <- paste0(q$source_label, ' ', q$native_key, ': ')
    problems <- ifelse(startsWith(problems, prefix), substring(problems, nchar(prefix) + 1L), problems)
    return(Err(paste(problems, collapse = '; ')))
  }
  msg <- NA_character_
  act <- SplitDecision(decision)$action
  if (startsWith(act, 'doi:')) {
    doi <- sub('^doi:', '', act)
    if (is.null(cfg) || isTRUE(cfg$offline)) msg <- sprintf('doi:%s not checked at Crossref (offline)', doi)
    else if (is.null(CrossrefWork(doi, cfg))) return(Err(sprintf('doi:%s does not resolve at Crossref', doi)))
  }
  status <- sprintf('pulled %s', pulled_at)
  if (!is.null(cite)) status <- sprintf('%s (cite: %s)', status, FormatParsedCell(cite$parsed))
  list(decision = decision, status = status, message = msg, parsed = if (is.null(cite)) NULL else cite$parsed)
}

# The tab as read back, row by row, against the queue: each tab row is
# matched on source_label + native_key + queued_at to its queue row (an
# unknown key, or a key twice on the tab, is an error); a row still open in
# the queue takes the resolved decision (`decided_by`, `decided_at` =
# `pulled_at`, `owner_note`, and the parsed_* fields of a `cite:` note); a
# row already decided in the queue is left as it is -- its status says
# `pulled <decided_at>` when the cell agrees with the queue (an empty cell
# beside a `cite:` note agrees with `nodoi`), else `ignored: already pulled
# ...` (a change of mind after the pull is made in the CSV). Pure: nothing is
# written. Returns list(queue,
# results): `results` has one row per tab row in the tab's order (source_label,
# native_key, queued_at, cell, decision, status, message), which is what the
# status column is written from.
PullDecisions <- function(queue, tab, pulled_at = format(Sys.Date()), decided_by = 'owner', cfg = NULL) {
  need <- c('source_label', 'native_key', 'queued_at', 'decision')
  miss <- setdiff(need, names(tab))
  if (length(miss) > 0) stop('the decisions tab lacks column(s) ', paste(miss, collapse = ', '), call. = FALSE)
  tab <- as.data.frame(tab, stringsAsFactors = FALSE)
  Key <- function(d) paste(ifelse(is.na(d$source_label), '', d$source_label), ifelse(is.na(d$native_key), '', d$native_key), ifelse(is.na(d$queued_at), '', d$queued_at), sep = '\r')
  tkey <- Key(tab); qkey <- Key(queue)
  open <- is.na(queue$decision) | !nzchar(trimws(queue$decision))
  dup <- tkey %in% tkey[duplicated(tkey)]
  n <- nrow(tab)
  results <- data.frame(source_label = tab$source_label, native_key = tab$native_key, queued_at = tab$queued_at,
                        cell = vapply(seq_len(n), function(i) Cell(tab$decision[i]), character(1)),
                        decision = rep(NA_character_, n), status = rep(NA_character_, n), message = rep(NA_character_, n), stringsAsFactors = FALSE)
  for (i in seq_len(n)) {
    if (dup[i]) { results$status[i] <- 'error: duplicate tab rows for this key'; next }
    j <- which(qkey == tkey[i])
    if (length(j) == 0) { results$status[i] <- 'error: no queue row for this key'; next }
    if (length(j) > 1) j <- if (any(open[j])) j[open[j]][1] else j[1]
    note <- if ('owner_note' %in% names(tab)) Cell(tab$owner_note[i]) else NA_character_
    if (!open[j]) {
      cell <- results$cell[i]
      shown <- if (!is.na(cell) && tolower(cell) == 'accept') Cell(if ('recommendation' %in% names(tab)) tab$recommendation[i] else NA)
               else if (is.na(cell) && !is.na(CiteNote(note))) 'nodoi' else cell
      results$status[i] <- if (!is.na(shown) && shown == queue$decision[j]) sprintf('pulled %s', queue$decided_at[j])
                           else sprintf('ignored: already pulled %s as %s (change it in the CSV)', queue$decided_at[j], queue$decision[j])
      next
    }
    r <- ResolveTabDecision(tab[i, ], queue[j, ], cfg, pulled_at, decided_by)
    results$decision[i] <- r$decision; results$status[i] <- r$status; results$message[i] <- r$message
    if (!is.na(r$decision)) {
      queue$decision[j] <- r$decision; queue$decided_by[j] <- decided_by; queue$decided_at[j] <- pulled_at
      queue$owner_note[j] <- note
      for (col in names(r$parsed)) queue[[col]][j] <- r$parsed[[col]]    # the fields of a cite: note
      open[j] <- FALSE
    }
  }
  list(queue = queue, results = results)
}

# pulled / deferred / errors / ignored per source of a pull's results.
PullSummary <- function(results) {
  kind <- ifelse(startsWith(results$status, 'pulled'), 'pulled', ifelse(startsWith(results$status, 'error'), 'errors',
                 ifelse(startsWith(results$status, 'ignored'), 'ignored', 'deferred')))
  src <- ifelse(is.na(results$source_label), '(no source)', results$source_label)
  tab <- table(factor(src, levels = sort(unique(src))), factor(kind, levels = c('pulled', 'deferred', 'errors', 'ignored')))
  out <- data.frame(source_label = rownames(tab), stringsAsFactors = FALSE)
  for (k in colnames(tab)) out[[k]] <- as.integer(tab[, k])
  rownames(out) <- NULL
  out
}

# A dated entry at the end of the round log: a blank line, '## <date> --
# <title>', a blank line, the lines (bullets as given), each terminated.
AppendRoundLog <- function(path, title, lines, date = format(Sys.Date())) {
  cat(c('', sprintf('## %s -- %s', date, title), '', lines), file = path, sep = '\n', append = TRUE)
  invisible(path)
}

# ---- the decision items ----------------------------------------------------------------------
# The questions that are not a queue row (Bib/decision_items.csv,
# decision_item_columns): pushed to BM_decision_items on item_id, the
# owner's `answer` pulled back with the pull date; the agents implement the
# answer by hand and the round log keeps 'item_id: question -> answer'.
EmptyDecisionItems <- function()
  as.data.frame(setNames(rep(list(character()), length(decision_item_columns)), decision_item_columns), stringsAsFactors = FALSE)

ReadDecisionItems <- function(path) {
  if (!file.exists(path)) return(EmptyDecisionItems())
  d <- read.csv(path, stringsAsFactors = FALSE, colClasses = 'character', na.strings = c('', 'NA'),
                check.names = FALSE, encoding = 'UTF-8', fileEncoding = 'UTF-8')
  miss <- setdiff(decision_item_columns, names(d))
  if (length(miss) > 0) stop(basename(path), ' lacks column(s) ', paste(miss, collapse = ', '), call. = FALSE)
  if (anyDuplicated(d$item_id)) stop(basename(path), ': duplicated item_id ', paste(unique(d$item_id[duplicated(d$item_id)]), collapse = ', '), call. = FALSE)
  d[, decision_item_columns]
}

WriteDecisionItems <- function(items, path) {
  write.csv(items[, decision_item_columns], path, row.names = FALSE, na = '', fileEncoding = 'UTF-8')
  invisible(items)
}

# Every item as a tab row (the answered ones too: the tab is the record),
# `status` empty.
BuildDecisionItemRows <- function(items) {
  out <- as.data.frame(items[, decision_item_columns], stringsAsFactors = FALSE)
  out$status <- rep(NA_character_, nrow(out))
  rownames(out) <- NULL
  out[, sheet_decision_items_columns]
}

PushDecisionItems <- function(items, url = citations_sheet_url, tab = sheet_tab_decision_items, dry_run = TRUE, snapshot_path = NULL, io = DecisionsSheetIO())
  AppendKeyedRows(BuildDecisionItemRows(items), 'item_id', url, tab, sheet_decision_items_columns,
                  dry_run = dry_run, snapshot_path = snapshot_path, io = io, what = 'item')

# The items tab read back against the file: an item with a non-empty
# `answer` on the tab and no `answered_at` in the file takes the answer and
# `pulled_at`; an item already answered in the file keeps its answer
# ('pulled <answered_at>', or 'ignored: already answered ...' when the tab
# differs); an unanswered item stays as it is (status empty); a tab row
# whose item_id the file lacks is an error. Pure. Returns list(items,
# results, log): `results` one row per tab row (item_id, answer, status) in
# the tab's order, `log` the round-log lines of the newly answered items.
PullDecisionItems <- function(items, tab, pulled_at = format(Sys.Date())) {
  need <- c('item_id', 'answer')
  miss <- setdiff(need, names(tab))
  if (length(miss) > 0) stop('the items tab lacks column(s) ', paste(miss, collapse = ', '), call. = FALSE)
  tab <- as.data.frame(tab, stringsAsFactors = FALSE)
  n <- nrow(tab)
  results <- data.frame(item_id = tab$item_id, answer = vapply(seq_len(n), function(i) Cell(tab$answer[i]), character(1)),
                        status = rep(NA_character_, n), stringsAsFactors = FALSE)
  log <- character(0)
  for (i in seq_len(n)) {
    j <- match(tab$item_id[i], items$item_id)
    if (is.na(j)) { results$status[i] <- 'error: no item with this item_id'; next }
    ans <- results$answer[i]
    if (Nz(items$answered_at[j])) {
      results$status[i] <- if (!is.na(ans) && !is.na(items$answer[j]) && ans == items$answer[j]) sprintf('pulled %s', items$answered_at[j])
                           else sprintf('ignored: already answered %s (change it in the CSV)', items$answered_at[j])
      next
    }
    if (is.na(ans)) next
    items$answer[j] <- ans; items$answered_at[j] <- pulled_at
    results$status[i] <- sprintf('pulled %s', pulled_at)
    log <- c(log, sprintf('%s: %s -> %s', items$item_id[j], items$question[j], ans))
  }
  list(items = items, results = results, log = log)
}
