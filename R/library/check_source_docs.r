# Documentation check for the per-source folders. Every
# sources/databases/<Source>/README.md (and sources/conversion_factors/<Source>/README.md)
# should state the row filters applied (`Filters:`), the mass type reported and
# any conversion (`Mass type:`), how rows the source flags as imputed,
# genus-averaged or copied from another species were handled (`Imputed rows:`)
# and the terms of the raw files (`Licence:`, issue #6); see README.md,
# pipeline step 1 and "Data licences".
#
# Filters, Mass type and Imputed rows warn only (never stop), so an
# undocumented source does not block a run. The licence line is different:
# with `stop_on_missing_licence = TRUE` (the default) the run stops when a
# folder has no row in the licence manifest `sources/source_files.csv`
# (R/library/licence_manifest.r) or its README has no `Licence:` line, so a
# new source cannot land without a licence statement. A licence recorded as
# "unknown; owner to check", a README class that is not among the manifest's
# classes for the folder, and the non-commercial / share-alike sources are
# warned about and written to reports/warnings_licences.md.
CheckSourceDocs <- function(wd_db,
                            required = c('Filters:', 'Mass type:', 'Imputed rows:', 'Licence:'),
                            manifest = file.path(dirname(wd_db), 'source_files.csv'),
                            folders  = c(list.dirs(wd_db, recursive = FALSE),
                                         list.dirs(file.path(dirname(wd_db), 'conversion_factors'),
                                                   recursive = FALSE)),
                            report   = file.path(dirname(dirname(wd_db)), 'reports',
                                                 'warnings_licences.md'),
                            stop_on_missing_licence = TRUE) {
  keys <- sub(':$', '', gsub(' ', '_', tolower(required)))
  res <- do.call(rbind, lapply(folders, function(d) {
    f   <- file.path(d, 'README.md')
    out <- data.frame(folder = basename(d), has_readme = file.exists(f),
                      stringsAsFactors = FALSE)
    has <- rep(NA, length(required))
    lic <- NA_character_
    if (out$has_readme) {
      lines <- readLines(f, warn = FALSE, encoding = 'UTF-8')
      has   <- vapply(required, function(k) any(startsWith(lines, k)), logical(1))
      ll    <- lines[startsWith(lines, 'Licence:')]
      if (length(ll) > 0) lic <- trimws(sub('^Licence:', '', ll[1]))
    }
    out[keys] <- as.list(has)
    out$licence_line <- lic
    out$manifest_key <- paste0(basename(dirname(d)), '/', basename(d))
    out
  }))
  rownames(res) <- NULL

  # ---- the baseline keys: warn only --------------------------------------------
  base_keys <- setdiff(keys, 'licence')
  base_req  <- required[keys != 'licence']
  no_readme  <- res$folder[!res$has_readme]
  incomplete <- res[res$has_readme & rowSums(!res[, base_keys, drop = FALSE]) > 0, , drop = FALSE]
  if (length(no_readme) > 0)
    message(sprintf('CheckSourceDocs: %d of %d source folders have no README.md: %s',
                    length(no_readme), nrow(res), paste(no_readme, collapse = ', ')))
  if (nrow(incomplete) > 0) {
    missing <- apply(incomplete[base_keys], 1, function(h) paste(base_req[!h], collapse = ' '))
    message(sprintf('CheckSourceDocs: %d README.md files lack required lines:\n%s',
                    nrow(incomplete),
                    paste0('  ', incomplete$folder, ': ', missing, collapse = '\n')))
  }
  if (length(no_readme) == 0 && nrow(incomplete) == 0)
    message('CheckSourceDocs: all source READMEs document Filters, Mass type and Imputed rows.')

  # ---- the licence line and the manifest --------------------------------------
  if (!'licence' %in% keys) return(invisible(res))
  if (!file.exists(manifest)) {
    msg <- paste0('CheckSourceDocs: licence manifest not found: ', manifest,
                  ' (regenerate with Rscript R/library/licence_manifest.r)')
    if (stop_on_missing_licence) stop(msg) else message(msg)
    return(invisible(res))
  }
  m <- read.csv(manifest, stringsAsFactors = FALSE, colClasses = 'character',
                na.strings = character(0), encoding = 'UTF-8')
  in_manifest <- res$manifest_key %in% m$folder
  no_line     <- res$has_readme & !res$licence
  problems <- c(
    if (any(!in_manifest))
      paste0('  no row in ', basename(manifest), ': ', paste(res$folder[!in_manifest], collapse = ', ')),
    if (any(!res$has_readme))
      paste0('  no README.md (so no Licence: line): ', paste(res$folder[!res$has_readme], collapse = ', ')),
    if (any(no_line))
      paste0('  README.md without a Licence: line: ', paste(res$folder[no_line], collapse = ', ')))
  if (length(problems) > 0) {
    msg <- paste0('CheckSourceDocs: every source folder needs a Licence: line in its README and a row ',
                  'in sources/source_files.csv (issue #6; see sources/LICENSES.md):\n',
                  paste(problems, collapse = '\n'))
    if (stop_on_missing_licence) stop(msg, call. = FALSE) else message(msg)
  }

  # the README class must be one the manifest records for the folder's raw,
  # live or parsed files (a file-level class is allowed after the headline one)
  data_rows <- m[m$role %in% c('raw', 'live', 'parsed'), ]
  res$manifest_classes <- vapply(res$manifest_key, function(k) {
    cls <- unique(data_rows$licence_class[data_rows$folder == k])
    if (length(cls) == 0) cls <- unique(m$licence_class[m$folder == k])
    paste(cls, collapse = ' | ')
  }, character(1))
  res$class_ok <- mapply(function(line, cls) {
    if (is.na(line) || !nzchar(cls)) return(NA)
    any(vapply(strsplit(cls, ' \\| ')[[1]], function(c) startsWith(line, c), logical(1)))
  }, res$licence_line, res$manifest_classes)
  res$unknown    <- !is.na(res$licence_line) & startsWith(res$licence_line, 'unknown')
  res$restricted <- !is.na(res$licence_line) &
    grepl('^(CC BY-NC|CC BY-SA|non-commercial)', res$licence_line)
  mismatch <- res[!is.na(res$class_ok) & !res$class_ok, , drop = FALSE]
  if (nrow(mismatch) > 0)
    message(sprintf(paste('CheckSourceDocs: %d README Licence: line(s) do not start with a class the',
                          'manifest records for the folder:\n%s'), nrow(mismatch),
                    paste0('  ', mismatch$folder, ': "', substr(mismatch$licence_line, 1, 60),
                           '" vs manifest "', mismatch$manifest_classes, '"', collapse = '\n')))
  if (any(res$unknown))
    message(sprintf('CheckSourceDocs: %d source folder(s) have Licence: unknown; owner to check: %s',
                    sum(res$unknown), paste(res$folder[res$unknown], collapse = ', ')))
  if (any(res$restricted))
    message(sprintf('CheckSourceDocs: %d non-commercial / share-alike source(s) (carve-outs, sources/LICENSES.md): %s',
                    sum(res$restricted), paste(res$folder[res$restricted], collapse = ', ')))
  if (!any(res$unknown) && nrow(mismatch) == 0 && length(problems) == 0)
    message('CheckSourceDocs: every source folder has a Licence: line that matches the manifest.')

  WriteLicenceReport(res, m, manifest, report)
  invisible(res)
}

# reports/warnings_licences.md in the style of the check_enriched() reports:
# a timestamp line, then the folders whose licence is unknown (with the URL the
# owner checks), the non-commercial / share-alike carve-outs, the README lines
# that disagree with the manifest and the folders that lack the line.
WriteLicenceReport <- function(res, m, manifest, report) {
  dir.create(dirname(report), showWarnings = FALSE, recursive = TRUE)
  now <- format(Sys.time(), '%Y-%m-%d %H:%M:%S')
  Url <- function(key) {
    u <- unique(m$check_url[m$folder == key & nzchar(m$check_url)])
    paste(u, collapse = ' ')
  }
  Files <- function(key, roles = c('raw', 'live')) {
    p <- m$path[m$folder == key & m$role %in% roles]
    paste0('`', basename(sub('/$', '', p)), '`', collapse = ', ')
  }
  Row <- function(r) sprintf('| %s | %s | %s | %s |', r$folder,
                             gsub('\\|', '\\\\|', substr(r$licence_line, 1, 160)),
                             Files(r$manifest_key), Url(r$manifest_key))
  hdr <- c('| Folder | Licence line (first 160 characters) | Raw files | URL to check |',
           '|---|---|---|---|')
  unknown    <- res[res$unknown, , drop = FALSE]
  restricted <- res[res$restricted, , drop = FALSE]
  mismatch   <- res[!is.na(res$class_ok) & !res$class_ok, , drop = FALSE]
  missing    <- res[!res$has_readme | !res$licence, , drop = FALSE]
  not_in_m   <- res[!res$manifest_key %in% m$folder, , drop = FALSE]
  Block <- function(title, intro, df) {
    c(paste0('## ', title), '', intro, '',
      if (nrow(df) == 0) '(none)' else c(hdr, vapply(seq_len(nrow(df)), function(i) Row(df[i, ]), character(1))),
      '')
  }
  lines <- c(
    sprintf('# TaxonBodyMass_DB Licence Warnings -- %s\n', now),
    paste0('Written by `CheckSourceDocs()` (`R/library/check_source_docs.r`) from the `Licence:` lines ',
           'of the source READMEs and the manifest `', basename(manifest), '` (issue #6). ',
           'The full record is `sources/LICENSES.md`.'), '',
    sprintf('Folders checked: %d; unknown licence: %d; non-commercial / share-alike: %d.',
            nrow(res), nrow(unknown), nrow(restricted)),
    '',
    Block('Licence unknown: owner to check',
          paste('Sources whose terms are not stated on disk. The owner checks the URL, records the',
                'licence in the README `Licence:` line and in `sources/source_files.csv`, and',
                'regenerates `sources/LICENSES.md` (`Rscript R/library/licence_manifest.r`).'), unknown),
    Block('Non-commercial and share-alike sources (carve-outs)',
          paste('Tracked and redistributed under their own terms, not under the repository licence;',
                'the compiled values that incorporate them are facts (position in `sources/LICENSES.md`).'),
          restricted),
    Block('README Licence: line not matching the manifest',
          'The line must start with a class the manifest records for the folder.', mismatch),
    Block('Folders without a Licence: line', 'The run stops on these unless `stop_on_missing_licence = FALSE`.', missing),
    Block('Folders absent from the manifest', 'Regenerate the manifest and record the licence of the new files.', not_in_m))
  writeLines(lines, report, useBytes = TRUE)
  invisible(report)
}
