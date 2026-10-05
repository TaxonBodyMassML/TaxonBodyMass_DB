# Builds references.csv for Smith_etal_2003 (issue #1) from the REFERENCES sheet
# of 'MOM v10.2.xlsx' (the unpublished lab version of Smith et al. 2003, #4):
# one row per numbered entry, the text verbatim (blank runs collapsed; a
# continuation line without a number, entry 196, joined to its entry), plus
# one row per alias key of text_keys.csv (the text and URL keys of the
# 'Mass Reference' column: WalkersOnline, Goheen, web.vienna.sorex.asper, ...),
# whose citation is the longest (then most frequent) verbatim spelling found
# in the data sheet and whose note comes from text_keys.csv. Columns: key, citation, note.
#
#     Rscript sources/databases/Smith_etal_2003/build_references.r
wd <- dirname(normalizePath(sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE)[1])))
f  <- file.path(wd, 'MOM v10.2.xlsx')
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
