# Documentation check for the per-source folders. Every
# sources/databases/<Source>/README.md should state the row filters applied
# (`Filters:`), the mass type reported and any conversion (`Mass type:`) and how
# rows the source flags as imputed, genus-averaged or copied from another
# species were handled (`Imputed rows:`); see README.md, pipeline step 1.
# Warns only (never stops), so an undocumented source does not block a run.
CheckSourceDocs <- function(wd_db,
                            required = c('Filters:', 'Mass type:', 'Imputed rows:')) {
  folders <- list.dirs(wd_db, recursive = FALSE)
  keys    <- sub(':$', '', gsub(' ', '_', tolower(required)))
  res <- do.call(rbind, lapply(folders, function(d) {
    f   <- file.path(d, 'README.md')
    out <- data.frame(folder = basename(d), has_readme = file.exists(f),
                      stringsAsFactors = FALSE)
    has <- rep(NA, length(required))
    if (out$has_readme) {
      lines <- readLines(f, warn = FALSE, encoding = 'UTF-8')
      has   <- vapply(required, function(k) any(startsWith(lines, k)), logical(1))
    }
    out[keys] <- as.list(has)
    out
  }))
  no_readme  <- res$folder[!res$has_readme]
  incomplete <- res[res$has_readme & rowSums(!res[keys]) > 0, , drop = FALSE]
  if (length(no_readme) > 0)
    message(sprintf('CheckSourceDocs: %d of %d source folders have no README.md: %s',
                    length(no_readme), nrow(res), paste(no_readme, collapse = ', ')))
  if (nrow(incomplete) > 0) {
    missing <- apply(incomplete[keys], 1, function(h) paste(required[!h], collapse = ' '))
    message(sprintf('CheckSourceDocs: %d README.md files lack required lines:\n%s',
                    nrow(incomplete),
                    paste0('  ', incomplete$folder, ': ', missing, collapse = '\n')))
  }
  if (length(no_readme) == 0 && nrow(incomplete) == 0)
    message('CheckSourceDocs: all source READMEs document Filters, Mass type and Imputed rows.')
  invisible(res)
}
