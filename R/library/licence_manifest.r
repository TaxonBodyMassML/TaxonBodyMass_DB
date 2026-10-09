# Licence manifest of the raw source files (issue #6).
#
# `sources/source_files.csv` lists every tracked file under sources/databases
# and sources/conversion_factors (one row per file) plus one `live` row per
# source that is downloaded at run time and stores nothing (FishBase,
# SeaLifeBase, the rdataretriever data papers, the VertNet snapshots). The
# generated columns (`bytes`, `sha256`, and the folder/path of new files) are
# rewritten by BuildLicenceManifest(); the hand-maintained columns (`label`,
# `role`, `licence_class`, `statement_source`, `redistributable`,
# `attribution`, `check_url`, `notes`) are kept for every path that is still
# tracked, a newly tracked file enters with `role` guessed from its name and
# `licence_class` "unknown; owner to check", and a file no longer tracked
# leaves the manifest. `sources/LICENSES.md` is written from the manifest by
# WriteLicensesMd(). Regenerate both with
#
#   Rscript R/library/licence_manifest.r        (from the repository root)
#
# Columns:
#   folder            `databases/<Src>` or `conversion_factors/<Src>` (or `VertNet`)
#   label             the `source_mass` label(s) of the folder (`;`-separated)
#   path              repository-relative path (a folder path for `live` rows)
#   role              raw (upstream file or export), parsed (our transcription of
#                     an upstream table: facts), derived (our own working table),
#                     code, doc, live (nothing stored)
#   bytes, sha256     of the tracked file (empty for `live`)
#   licence_class     the upstream terms of a raw/live file as recorded on disk
#                     or decided by the owner; "transcription (facts)" for
#                     parsed files; "repository (CC BY-NC 4.0)" for our own files;
#                     "unknown; owner to check" when the terms are not on disk
#   statement_source  where the class is stated: README, Citation.bib, in-file,
#                     owner decision <date>, repository LICENSE, not on disk
#   redistributable   yes | non-commercial | share-alike | no | unknown
#   attribution       the attribution text to use (title, creators, source, licence)
#   check_url         the deposit or terms page the owner checks
#   notes             free text
#
# CheckSourceDocs() (R/library/check_source_docs.r) reads the manifest at every
# run and stops when a source folder has no row in it.

LICENCE_UNKNOWN <- 'unknown; owner to check'
LICENCE_REPO    <- 'repository (CC BY-NC 4.0)'
LICENCE_FACTS   <- 'transcription (facts)'
LICENCE_PUB     <- 'publisher file'

manifest_columns <- c('folder', 'label', 'path', 'role', 'bytes', 'sha256',
                      'licence_class', 'statement_source', 'redistributable',
                      'attribution', 'check_url', 'notes')
manifest_hand_columns <- setdiff(manifest_columns, c('folder', 'path', 'bytes', 'sha256'))

# Classes whose terms restrict reuse beyond attribution (the carve-outs of
# sources/LICENSES.md) and the classes that need no carve-out. The repository
# class is itself CC BY-NC 4.0 (owner decision 2026-10-06) but is not a
# third-party carve-out, so it is excluded here.
LicenceIsRestricted <- function(cls)
  grepl('NC|SA|non-commercial', cls) & !grepl('^unknown', cls) & cls != LICENCE_REPO
LicenceIsUnknown <- function(cls) grepl('^unknown', cls)

# ---- hashing -----------------------------------------------------------------
Sha256File <- function(path) {
  if (requireNamespace('digest', quietly = TRUE))
    return(digest::digest(path, algo = 'sha256', file = TRUE))
  if (requireNamespace('openssl', quietly = TRUE))
    return(as.character(openssl::sha256(file(path, 'rb'))))
  tool <- Sys.which(c('sha256sum', 'shasum'))
  tool <- tool[nzchar(tool)][1]
  if (is.na(tool)) stop('Sha256File: no digest/openssl package and no sha256sum/shasum on PATH')
  args <- if (basename(tool) == 'shasum') c('-a', '256', shQuote(path)) else shQuote(path)
  strsplit(system2(tool, args, stdout = TRUE), ' ')[[1]][1]
}

# ---- reading -----------------------------------------------------------------
ReadLicenceManifest <- function(path) {
  if (!file.exists(path)) stop('licence manifest not found: ', path)
  m <- read.csv(path, stringsAsFactors = FALSE, colClasses = 'character',
                na.strings = character(0), encoding = 'UTF-8', check.names = FALSE)
  missing <- setdiff(manifest_columns, names(m))
  if (length(missing) > 0)
    stop('licence manifest ', path, ' lacks column(s): ', paste(missing, collapse = ', '))
  m[manifest_columns]
}

# The tracked files under the two source trees, repository-relative. With git
# available the index is authoritative (an untracked local copy of a publisher
# file must not enter the manifest); without it (a fixture tree in a test) the
# file system is listed.
ListSourceFiles <- function(wd_root, use_git = TRUE,
                            trees = c('sources/databases', 'sources/conversion_factors')) {
  files <- character(0)
  if (use_git && nzchar(Sys.which('git'))) {
    files <- suppressWarnings(
      system2('git', c('-C', shQuote(wd_root), 'ls-files', '--', shQuote(trees)),
              stdout = TRUE, stderr = FALSE))
    if (!is.null(attr(files, 'status'))) files <- character(0)
  }
  if (length(files) == 0) {
    files <- unlist(lapply(trees, function(t) {
      d <- file.path(wd_root, t)
      if (!dir.exists(d)) return(character(0))
      file.path(t, list.files(d, recursive = TRUE, all.files = FALSE))
    }))
  }
  sort(unique(files[nzchar(files)]))
}

GuessRole <- function(path) {
  b <- basename(path)
  ifelse(b %in% c('README.md', 'Citation.bib'), 'doc',
  ifelse(grepl('(^BodyMass_.*\\.r$)|(\\.py$)|(_analysis\\.r$)|(^build_references\\.(r|py)$)', b),
         'code', 'raw'))
}

# ---- building ----------------------------------------------------------------
BuildLicenceManifest <- function(wd_root,
                                 manifest = file.path(wd_root, 'sources', 'source_files.csv'),
                                 use_git = TRUE, write = TRUE, quiet = FALSE) {
  old <- if (file.exists(manifest)) ReadLicenceManifest(manifest) else
    as.data.frame(setNames(replicate(length(manifest_columns), character(0), simplify = FALSE),
                           manifest_columns), stringsAsFactors = FALSE)
  files  <- ListSourceFiles(wd_root, use_git = use_git)
  folder <- sub('^sources/', '', dirname(files))
  folder <- sub('^((databases|conversion_factors)/[^/]+).*$', '\\1', folder)
  new <- data.frame(folder = folder, label = NA_character_, path = files, role = GuessRole(files),
                    bytes = as.character(file.size(file.path(wd_root, files))),
                    sha256 = vapply(file.path(wd_root, files), Sha256File, character(1), USE.NAMES = FALSE),
                    licence_class = LICENCE_UNKNOWN, statement_source = 'not on disk',
                    redistributable = 'unknown', attribution = '', check_url = '', notes = '',
                    stringsAsFactors = FALSE)
  # keep the hand columns of every path still tracked
  keep <- match(new$path, old$path)
  has  <- !is.na(keep)
  for (col in manifest_hand_columns) new[[col]][has] <- old[[col]][keep[has]]
  # a new file in a known folder: its label, and the repository class for our own files
  known <- old[old$role != 'live', ]
  for (i in which(!has)) {
    lab <- unique(known$label[known$folder == new$folder[i]])
    new$label[i] <- if (length(lab) == 1) lab else basename(new$folder[i])
    if (new$role[i] %in% c('doc', 'code')) {
      new$licence_class[i]    <- LICENCE_REPO
      new$statement_source[i] <- 'repository LICENSE'
      new$redistributable[i]  <- 'yes'
    }
  }
  live <- old[old$role == 'live', ]
  live$bytes <- ''; live$sha256 <- ''
  out <- rbind(new[order(new$path, method = 'radix'), ], live[order(live$path, method = 'radix'), ])
  rownames(out) <- NULL
  out <- out[manifest_columns]
  added   <- new$path[!has]
  dropped <- setdiff(old$path[old$role != 'live'], new$path)
  if (!quiet) {
    message(sprintf('licence manifest: %d tracked files in %d folders, %d live rows; %d added, %d dropped',
                    nrow(new), length(unique(new$folder)), nrow(live), length(added), length(dropped)))
    if (length(added) > 0)
      message('  added (raw files enter as "', LICENCE_UNKNOWN, '", scripts and READMEs under the ',
              'repository licence): ', paste(added, collapse = ', '))
    if (length(dropped) > 0) message('  dropped: ', paste(dropped, collapse = ', '))
  }
  if (write) write.csv(out, manifest, row.names = FALSE, na = '', fileEncoding = 'UTF-8')
  attr(out, 'added') <- added
  attr(out, 'dropped') <- dropped
  invisible(out)
}

# ---- the folder view ---------------------------------------------------------
# One row per folder: its label(s), the classes of its raw/live/parsed files,
# the headline class (the class of the raw or live files; several when they
# differ) and the attribution, URL and notes of the folder.
ManifestFolders <- function(m) {
  data_rows <- m[m$role %in% c('raw', 'live', 'parsed'), ]
  folders <- unique(m$folder)
  do.call(rbind, lapply(folders, function(f) {
    rows <- data_rows[data_rows$folder == f, ]
    upstream <- rows[rows$role %in% c('raw', 'live'), ]
    classes <- unique(if (nrow(upstream) > 0) upstream$licence_class else rows$licence_class)
    if (length(classes) == 0) classes <- LICENCE_REPO
    data.frame(folder = f,
               label = paste(unique(m$label[m$folder == f]), collapse = '; '),
               classes = paste(classes, collapse = ' | '),
               n_raw = sum(m$folder == f & m$role == 'raw'),
               bytes = sum(as.numeric(m$bytes[m$folder == f & m$role == 'raw']), na.rm = TRUE),
               live = any(m$folder == f & m$role == 'live'),
               unknown = any(LicenceIsUnknown(classes)),
               restricted = any(LicenceIsRestricted(classes)),
               attribution = paste(unique(upstream$attribution[nzchar(upstream$attribution)]), collapse = ' / '),
               check_url = paste(unique(upstream$check_url[nzchar(upstream$check_url)]), collapse = ' '),
               notes = paste(unique(upstream$notes[nzchar(upstream$notes)]), collapse = ' / '),
               stringsAsFactors = FALSE)
  }))
}

# ---- LICENSES.md ---------------------------------------------------------------
FormatBytes <- function(b) {
  b <- as.numeric(b)
  ifelse(is.na(b) | b == 0, '', ifelse(b >= 1e6, sprintf('%.1f MB', b / 1e6),
                               ifelse(b >= 1e3, sprintf('%.0f kB', b / 1e3), sprintf('%d B', as.integer(b)))))
}
MdCell <- function(x) { x <- gsub('\\|', '\\\\|', x); x <- gsub('\n', ' ', x); ifelse(is.na(x), '', x) }
MdTable <- function(df) {
  df[] <- lapply(df, as.character)
  cols <- names(df)
  c(paste0('| ', paste(cols, collapse = ' | '), ' |'),
    paste0('|', paste(rep('---', length(cols)), collapse = '|'), '|'),
    apply(df, 1, function(r) paste0('| ', paste(MdCell(r), collapse = ' | '), ' |')))
}

# The files of a folder with a given set of roles, as "`name` (size)".
FileList <- function(m, folder, roles = c('raw', 'live'), classes = NULL) {
  rows <- m[m$folder == folder & m$role %in% roles, ]
  if (!is.null(classes)) rows <- rows[rows$licence_class %in% classes, ]
  if (nrow(rows) == 0) return('')
  sz <- FormatBytes(rows$bytes)
  paste0('`', basename(sub('/$', '', rows$path)), '`', ifelse(nzchar(sz), paste0(' (', sz, ')'), ''),
         collapse = ', ')
}

WriteLicensesMd <- function(m, wd_root, path = file.path(wd_root, 'sources', 'LICENSES.md')) {
  fo <- ManifestFolders(m)
  upstream <- m[m$role %in% c('raw', 'live'), ]
  class_order <- c('CC0 1.0', 'CC BY 4.0', 'CC BY 3.0',
                   'no copyright restrictions (Ecological Archives)',
                   'author permission (free to use with attribution)',
                   'transcription (facts)',
                   'CC BY-SA 4.0', 'CC BY-NC 4.0', 'CC BY-NC-ND 4.0', 'CC BY-NC-SA 3.0',
                   'non-commercial (author statement)',
                   'publisher file', 'unpublished', LICENCE_UNKNOWN)
  classes <- unique(c(class_order, sort(unique(c(upstream$licence_class, m$licence_class[m$role == 'parsed'])))))
  classes <- classes[classes %in% c(upstream$licence_class, m$licence_class[m$role == 'parsed'])]

  ClassTable <- function(cls, roles = c('raw', 'live')) {
    rows <- m[m$role %in% roles & m$licence_class == cls, ]
    if (nrow(rows) == 0) return(character(0))
    folders <- unique(rows$folder)
    df <- do.call(rbind, lapply(folders, function(f) {
      r <- rows[rows$folder == f, ]
      data.frame(Source = paste0(f, ' (`', paste(unique(r$label), collapse = '; '), '`)'),
                 Files = FileList(m, f, roles, cls),
                 `Stated in` = paste(unique(r$statement_source), collapse = '; '),
                 Redistributable = paste(unique(r$redistributable), collapse = '; '),
                 Attribution = paste(unique(r$attribution[nzchar(r$attribution)]), collapse = ' / '),
                 `URL to check` = paste(unique(r$check_url[nzchar(r$check_url)]), collapse = ' '),
                 Notes = paste(unique(r$notes[nzchar(r$notes)]), collapse = ' / '),
                 check.names = FALSE, stringsAsFactors = FALSE)
    }))
    MdTable(df)
  }

  summary <- do.call(rbind, lapply(classes, function(cls) {
    rows <- upstream[upstream$licence_class == cls, ]
    prow <- m[m$role == 'parsed' & m$licence_class == cls, ]
    data.frame(`Licence class` = cls,
               Folders = length(unique(c(rows$folder, prow$folder))),
               `Raw files` = sum(rows$role == 'raw') + nrow(prow),
               Size = FormatBytes(sum(as.numeric(c(rows$bytes, prow$bytes)), na.rm = TRUE)),
               Redistributable = paste(unique(c(rows$redistributable, prow$redistributable)), collapse = '; '),
               check.names = FALSE, stringsAsFactors = FALSE)
  }))

  n_tracked <- sum(m$role != 'live')
  n_raw     <- sum(m$role == 'raw')
  restricted <- fo[fo$restricted, ]
  unknown    <- fo[fo$unknown, ]
  pub        <- m[m$role == 'raw' & m$licence_class == LICENCE_PUB, ]
  unpub      <- m[m$role == 'raw' & m$licence_class == 'unpublished', ]

  lines <- c(
    '# Licences of the source files',
    '',
    sprintf(paste('Generated from `sources/source_files.csv` by `R/library/licence_manifest.r`',
                  '(`Rscript R/library/licence_manifest.r`); do not edit by hand. The manifest lists',
                  'the %d tracked files under `sources/databases/` and `sources/conversion_factors/`',
                  '(%d raw upstream files or exports, %d parsed transcriptions, the rest our own tables,',
                  'scripts and documentation) with their size, SHA-256, role and licence class, plus',
                  '%d `live` rows for the sources that are downloaded at run time and store nothing.',
                  'Every source folder states the same class in the `Licence:` line of its README',
                  '(checked by `CheckSourceDocs()` at every pipeline run; a folder absent from the',
                  'manifest or without the line stops the run). Issue #6; licence audit of 2026-10-02',
                  'and 2026-10-06. This file is a record of what the files, READMEs, bibliographies and',
                  'deposit records say; it is not legal advice.'),
            n_tracked, n_raw, sum(m$role == 'parsed'), sum(m$role == 'live')),
    '',
    '## Scope of the repository licence',
    '',
    paste('The repository `LICENSE` (CC BY-NC 4.0, Creative Commons Attribution-NonCommercial 4.0',
          'International; owner decision of 2026-10-06, replacing the CC BY 4.0 of earlier commits',
          'and releases, which keep the licence they carried) covers what the lab wrote: the',
          'pipeline code, the per-source parse scripts and READMEs, the parsed and transcribed',
          'tables, our reference and unit tables, the compiled outputs `TaxonBodyMass.csv`,',
          '`TaxonBodyMass_GenusLevel.csv` and `TaxonBodyMass_Provenance.csv.gz`, and the',
          'bibliographies, to the extent the lab holds rights in them. The NonCommercial term',
          'applies to all of it: this material may be shared and adapted with attribution for',
          'non-commercial purposes only. It does not relicense any third-party file. Every raw upstream file kept',
          'under `sources/` stays under the terms of its licensor, listed below and in the folder',
          'README (the Creative Commons licences ask licensors to "clearly mark any material not',
          'subject to the license"; this file and the `Licence:` lines are that marking). All tracked',
          'files are kept tracked (owner decision of 2026-10-06): nothing was untracked, no',
          'download-on-demand helper was added and the git history was not rewritten.'),
    '',
    '## Position on values from non-commercial and share-alike sources',
    '',
    paste('Individual body-mass values are facts; the database redistributes them as facts with',
          'attribution to every contributing source (`source_mass`, the bibliographies and the',
          'provenance table). Several sources publish their files under terms that go beyond',
          'attribution: CC BY-NC 4.0 (FishBase, SeaLifeBase, Lane 2019), CC BY-NC-ND 4.0 (Cai et al.',
          '2025, Hoehler et al. 2023), CC BY-NC-SA 3.0 (Animal Diversity Web through Quaardvark),',
          'CC BY-SA 4.0 (Pata & Hunt 2025) and an author statement limiting use to non-commercial',
          'scientific use (Hechinger et al. 2011). Their raw files, where tracked, are redistributed',
          'here for non-commercial use under those terms and are marked as such; the compiled',
          'species means that incorporate their values are published under the repository licence,',
          'CC BY-NC 4.0, as aggregated facts, which aligns the repository with the non-commercial',
          'term of these sources. Whether a downstream use, in particular one in a jurisdiction',
          'with sui generis database rights, is also bound by the share-alike term of Pata & Hunt',
          '2025 (CC BY-SA 4.0) or the no-derivatives term of Cai et al. 2025 and Hoehler et al.',
          '2023 (CC BY-NC-ND 4.0) is for the user of the aggregated values to decide; the sources',
          'behind every value are listed so that a user can exclude them (`source_mass`,',
          '`TaxonBodyMass_Provenance.csv.gz`). Owner decisions of 2026-10-06 (issue #6, option A',
          'of the audit; relicensing to CC BY-NC 4.0).'),
    '',
    '## Summary by licence class',
    '',
    MdTable(summary),
    '',
    paste('Classes: the CC and "no copyright restrictions" classes are the licensors\' statements;',
          '"author permission" is a statement in the data paper; "transcription (facts)" marks tables',
          'the lab typed or parsed from a publication (facts, attributed to the publication);',
          '"publisher file" marks verbatim article or supplementary files whose copyright is with the',
          'publisher; "unpublished" marks a private file; "unknown; owner to check" marks a source',
          'whose terms are not stated on disk (file, README or bibliography), listed at the end with',
          'the page to check. Nothing in this file is guessed from a deposit page that is not quoted',
          'on disk; the audit\'s readings of such pages are given in the notes as readings to confirm.'),
    '')

  Section <- function(title, cls, intro = NULL, roles = c('raw', 'live')) {
    tab <- ClassTable(cls, roles)
    if (length(tab) == 0) return(character(0))
    c(paste0('### ', title), '', intro, if (!is.null(intro)) '', tab, '')
  }
  lines <- c(lines,
    '## Open sources (attribution only)', '',
    paste('Files redistributed under their upstream licence; the attribution text is the one to use',
          'when citing the file itself. The lab\'s modifications are column selection, unit',
          'conversion and averaging within and across sources.'), '',
    Section('CC0 1.0', 'CC0 1.0'),
    Section('CC BY 4.0', 'CC BY 4.0'),
    Section('CC BY 3.0', 'CC BY 3.0'),
    Section('Ecological Archives data papers: "Copyright restrictions: None"',
            'no copyright restrictions (Ecological Archives)',
            paste('The metadata file of each data paper states that there are no copyright or',
                  'proprietary restrictions; the authors ask to be cited and, for the SIZEWEB and',
                  'nematode data, to be notified of publications.')),
    Section('Author permission', 'author permission (free to use with attribution)'),
    Section('Transcriptions of published tables (facts)', LICENCE_FACTS, roles = 'parsed',
            paste('Tables the lab typed or parsed from a publication or a publisher file. The values',
                  'are facts and are attributed to the publication; the publication itself is not',
                  'redistributed unless listed under "Publisher files". Makarieva et al. (2008):',
                  'the PNAS notice applies, "Copyright (2008) National Academy of Sciences".')),
    '## Non-commercial and share-alike sources (carve-outs)', '',
    paste('The files below are tracked and redistributed under their own terms, not under the',
          'repository licence: non-commercial use only (CC BY-NC, CC BY-NC-ND, the Hechinger',
          'statement), share-alike (CC BY-SA, CC BY-NC-SA). The compiled values that incorporate them',
          'are facts; see the position above. The citation form the licensor asks for is given in',
          'the attribution column (Animal Diversity Web: `Author. Year. "Species" (On-line), Animal',
          'Diversity Web. Accessed <date> at <URL>`). FishBase and SeaLifeBase store nothing here:',
          'the records are downloaded at run time through `rfishbase` under the sites\' CC BY-NC 4.0',
          'terms, and the species means derived from them carry the labels `fishbase` and',
          '`sealifebase`.'), '',
    Section('CC BY-SA 4.0', 'CC BY-SA 4.0'),
    Section('CC BY-NC 4.0', 'CC BY-NC 4.0'),
    Section('CC BY-NC-ND 4.0', 'CC BY-NC-ND 4.0'),
    Section('CC BY-NC-SA 3.0', 'CC BY-NC-SA 3.0'),
    Section('Non-commercial scientific use (author statement)', 'non-commercial (author statement)'),
    '## Publisher files', '',
    paste('Verbatim article or supplementary files (PDF, .doc/.docx, html, csv/xlsx supplements of',
          'Wiley, Springer Nature, PNAS and Cambridge University Press). Their copyright is with',
          'the publisher or the authors under the publisher\'s terms; they are kept tracked so that',
          'the parsers that read them stay reproducible (owner decision of 2026-10-06) and are not',
          'covered by the repository licence. Where a parsed table exists beside the file, the',
          'pipeline reads the parsed table. PNAS supplements: "Copyright (year) National Academy of',
          'Sciences". The publisher files of AyalaBerdon_2025 (Springer ESM), Cai_etal_2025 (SI',
          'appendix), Hudson_2013 (Appendix S1-S4), McCoy_2008 (Wiley Appendix S1) and Vanni_2017',
          '(Metadata S1) are kept locally and not committed.'), '',
    ClassTable(LICENCE_PUB), '',
    '## Unpublished', '',
    paste('`MOM v10.2` (Smith_etal_2003) is the unpublished Smith-lab version of the MOM data set',
          'underlying Smith et al. 2018 (Science 360:310-313); the route by which the workbook',
          'reached the lab and its terms are not recorded (issue #4). The full workbook is no longer',
          'tracked (removed 2026-10-08, owner decision; it remains in the git history before that',
          'date); only the minimal extract `MOM_v10.2_masses.csv` of the columns the pipeline reads',
          'is redistributed, as facts with attribution, not under the repository licence. The',
          'compiled values that rest on it are labelled `Smith_2003`.'), '',
    ClassTable('unpublished'), '',
    '## Not redistributed', '',
    paste('Sources the pipeline downloads at run time and stores nowhere in the repository (their',
          'cached frames in `sources/Rdata/` and the VertNet snapshots in `sources/VertNet/` are',
          'git-ignored): FishBase and SeaLifeBase (`rfishbase`; CC BY-NC 4.0 site terms), the five',
          'Ecological Archives data papers fetched by `rdataretriever` (Ernest 2003, Brose et al.',
          '2005, Jones et al. 2009, Myhrvold et al. 2015, Raymond et al. 2011; each data paper\'s',
          'metadata states its terms), and the six VertNet September 2016 CyVerse snapshots, whose',
          'records carry their own per-record licences. The publisher files listed above as "kept',
          'locally" are not committed either.'), '',
    MdTable(data.frame(Source = paste0(m$folder[m$role == 'live'], ' (`', m$label[m$role == 'live'], '`)'),
                       `Licence class` = m$licence_class[m$role == 'live'],
                       `Stated in` = m$statement_source[m$role == 'live'],
                       `URL to check` = m$check_url[m$role == 'live'],
                       Notes = m$notes[m$role == 'live'], check.names = FALSE, stringsAsFactors = FALSE)), '',
    '## Unknown: owner to check', '',
    sprintf(paste('%d source folders whose terms are not stated on disk. Each is marked `Licence: unknown;',
                  'owner to check <URL>` in its README and listed in `reports/warnings_licences.md` at',
                  'every run until the owner records the licence (in the README `Licence:` line and in',
                  '`sources/source_files.csv`). The notes give the audit\'s reading of the deposit page,',
                  'to confirm, never asserted here.'), nrow(unknown)), '',
    ClassTable(LICENCE_UNKNOWN), '')
  writeLines(lines, path, useBytes = TRUE)
  invisible(lines)
}

# ---- command line ------------------------------------------------------------
if (!interactive()) {
  this_file <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE))
  if (length(this_file) == 1 && basename(this_file) == 'licence_manifest.r') {
    wd_root <- normalizePath(file.path(dirname(this_file), '..', '..'))
    m <- BuildLicenceManifest(wd_root)
    WriteLicensesMd(m, wd_root)
    message('wrote sources/source_files.csv and sources/LICENSES.md')
  }
}
