# Record of how references.csv and MOM_v10.2_masses.csv were built from the
# workbook 'MOM v10.2.xlsx' (the unpublished Smith-lab version of Smith et al.
# 2003; issue #4). THE WORKBOOK IS NO LONGER TRACKED: it was removed on
# 2026-10-08 (owner decision, issue #4; it remains in the git history before
# that date) and only the two derived files are kept, so this script is kept
# for the record and stops with a message unless a local copy of the workbook
# sits beside it. Nothing in the pipeline runs it.
#
# references.csv (issue #1): from the REFERENCES sheet, one row per numbered
# entry, the text verbatim (blank runs collapsed; a continuation line without
# a number, entry 196, joined to its entry), plus one row per alias key of
# text_keys.csv (the text and URL keys of the 'Mass Reference' column:
# WalkersOnline, Goheen, web.vienna.sorex.asper, ...), whose citation is the
# longest (then most frequent) verbatim spelling found in the data sheet and
# whose note comes from text_keys.csv. Columns: key, citation, note.
#
# MOM_v10.2_masses.csv (issue #4): the minimal extract of the data sheet
# 'MOM v10.0' that the pipeline reads (BodyMass_Smith_etal_2003.r and
# R/library/build_extinct_taxa.r): all 5,734 rows and the eight columns Genus,
# Species, Order, FAMILY, Status, Combined.Mass (g), Mass Reference and
# Mass Status, cell values verbatim (-999 kept, empty cells empty), UTF-8,
# written by write.csv() from the readxl frame the parser used to read, so
# that read.csv(na.strings = '') returns the identical frame (checked below).
#
#     Rscript sources/databases/Smith_etal_2003/build_references.r
wd <- dirname(normalizePath(sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE)[1])))
f  <- file.path(wd, 'MOM v10.2.xlsx')
if (!file.exists(f))
  stop('build_references.r: the workbook ', basename(f), ' is no longer tracked (removed 2026-10-08, ',
       'issue #4; it is in the git history before that date). The script is kept as the record of how ',
       'references.csv and MOM_v10.2_masses.csv were built; put a local copy of the workbook in ',
       wd, ' to rerun it.', call. = FALSE)
Squeeze <- function(x) trimws(gsub('[[:space:] ]+', ' ', x, perl = TRUE))

# ---- the numbered list ----
ReadSheet <- function(...) suppressWarnings(suppressMessages(as.data.frame(readxl::read_excel(f, ...))))
r   <- ReadSheet(sheet = 'REFERENCES', col_names = FALSE)
txt <- Squeeze(apply(r, 1, function(x) paste(na.omit(trimws(x)), collapse = ' ')))
txt <- txt[nzchar(txt)]
stopifnot(txt[1] == 'Literature added'); txt <- txt[-1]
is_entry <- grepl('^[0-9]+\\.[[:space:]]', txt)
entry_of <- cumsum(is_entry)
stopifnot(entry_of[1] == 1)
joined <- vapply(split(txt, entry_of), paste, character(1), collapse = ' ')
key <- sub('^([0-9]+)\\..*$', '\\1', joined)
cit <- Squeeze(sub('^[0-9]+\\.[[:space:]]*', '', joined))
stopifnot(!anyDuplicated(key), identical(as.integer(key), seq_along(key)))
refs <- data.frame(key = key, citation = cit, note = NA_character_, stringsAsFactors = FALSE)

# ---- the alias keys of the Mass Reference column ----
tk <- read.csv(file.path(wd, 'text_keys.csv'), stringsAsFactors = FALSE, colClasses = 'character',
               na.strings = character(0), encoding = 'UTF-8')
d  <- ReadSheet(sheet = 'MOM v10.0'); names(d) <- trimws(names(d))
toks <- trimws(unlist(strsplit(trimws(as.character(d[['Mass Reference']])), '_[[:space:]]+', perl = TRUE)))
toks <- toks[!is.na(toks) & nzchar(toks) & !grepl('^[0-9]+$', toks)]
low  <- tolower(Squeeze(toks))
alias <- tk[nzchar(tk$key) & !grepl('^[0-9]+$', tk$key), ]
stopifnot(!anyDuplicated(alias$key[nzchar(alias$note)]))
rows <- lapply(unique(alias$key), function(k) {
  spellings <- toks[low %in% tk$text[tk$key == k]]
  if (length(spellings) == 0) stop('alias key ', k, ' matches no Mass Reference cell')
  tab <- table(spellings); tab <- tab[order(-nchar(names(tab)), -as.integer(tab), names(tab))]
  note <- alias$note[alias$key == k & nzchar(alias$note)]
  data.frame(key = k, citation = names(tab)[1], note = if (length(note)) note[1] else NA_character_,
             stringsAsFactors = FALSE)
})
refs <- rbind(refs, do.call(rbind, rows))
stopifnot(!anyDuplicated(refs$key))
out <- file.path(wd, 'references.csv')
write.csv(refs, out, row.names = FALSE, na = '', fileEncoding = 'UTF-8')
cat(sprintf('%s: %d numbered entries + %d alias keys = %d rows\n', basename(out), length(key), length(rows), nrow(refs)))

# ---- the minimal extract of the data sheet (issue #4) ----
extract_cols <- c('Genus', 'Species', 'Order', 'FAMILY', 'Status', 'Combined.Mass (g)', 'Mass Reference', 'Mass Status')
ex <- d[extract_cols]
out_ex <- file.path(wd, 'MOM_v10.2_masses.csv')
write.csv(ex, out_ex, row.names = FALSE, na = '', fileEncoding = 'UTF-8')
back <- read.csv(out_ex, stringsAsFactors = FALSE, check.names = FALSE, na.strings = '', encoding = 'UTF-8')
stopifnot(identical(back, ex))      # every cell round-trips (numbers, NAs, the non-ASCII and quoted cells)
cat(sprintf('%s: %d rows x %d columns, round-trip identical\n', basename(out_ex), nrow(ex), ncol(ex)))
