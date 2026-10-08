# Tests for the licence manifest (R/library/licence_manifest.r) and the
# Licence: check of CheckSourceDocs() (R/library/check_source_docs.r), issue #6.
#
# Part 1 builds a throwaway source tree in a temporary directory (no git, no
# network): the generator is run on it twice (new file -> "unknown; owner to
# check", hand columns kept, dropped file removed, sha256 correct, live rows
# kept, idempotent) and LICENSES.md is written from it; CheckSourceDocs() is
# then exercised on READMEs with and without the Licence: line, on a folder
# absent from the manifest, on an unknown licence and on a carve-out.
# Part 2 checks the real tree: the committed manifest lists exactly the tracked
# files with their current size and SHA-256, every source folder has a
# Licence: line whose class the manifest records, sources/LICENSES.md is
# the current regeneration, and LICENSE, LICENSES.md, the manifest class and
# the README name the repository licence CC BY-NC 4.0 (owner decision 2026-10-06).
#
#   Rscript R/library/tests/test_licence_docs.R      (from any directory)
#
# Prints one line per expectation and exits with status 1 if any failed.

this_file <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE))
if (length(this_file) == 0)
  this_file <- file.path('R', 'library', 'tests', 'test_licence_docs.R')
repo <- normalizePath(file.path(dirname(this_file), '..', '..', '..'))
source(file.path(repo, 'R', 'library', 'licence_manifest.r'))
source(file.path(repo, 'R', 'library', 'check_source_docs.r'))

failures <- character(0)
n_checks <- 0L
Expect <- function(ok, what) {
  n_checks <<- n_checks + 1L
  if (!isTRUE(ok)) failures <<- c(failures, what)
  cat(sprintf('  %s %s\n', if (isTRUE(ok)) 'ok  ' else 'FAIL', what))
}
Messages <- function(expr) {
  msgs <- character(0)
  withCallingHandlers(expr, message = function(m) {
    msgs <<- c(msgs, conditionMessage(m)); invokeRestart('muffleMessage') })
  msgs
}
ErrorOf <- function(expr) tryCatch({ expr; NULL }, error = function(e) conditionMessage(e))

# ---- Part 1: a throwaway tree -------------------------------------------------
cat('Part 1: fixture tree\n')
root <- file.path(tempdir(), paste0('licence_test_', as.integer(Sys.time())))
db   <- file.path(root, 'sources', 'databases')
cf   <- file.path(root, 'sources', 'conversion_factors')
for (d in c('SrcA', 'SrcB', 'SrcC')) dir.create(file.path(db, d), recursive = TRUE)
dir.create(file.path(cf, 'ConvD'), recursive = TRUE)
writeLines('taxon,mass_g\nA_a,1', file.path(db, 'SrcA', 'data.csv'))
writeLines('x <- 1', file.path(db, 'SrcA', 'BodyMass_SrcA.r'))
writeLines('@misc{a}', file.path(db, 'SrcA', 'Citation.bib'))
writeLines('taxon,mass_g\nB_b,2', file.path(db, 'SrcB', 'table.csv'))
writeLines('taxon,mass_g\nC_c,3', file.path(db, 'SrcC', 'raw.txt'))
writeLines('ratio\n0.2', file.path(cf, 'ConvD', 'ratios.csv'))
Readme <- function(folder, licence = NULL, base = TRUE) {
  lines <- c('# Src', '', 'Source: x', 'Data: y',
             if (!is.null(licence)) paste0('Licence: ', licence),
             if (base) c('Filters: none', 'Mass type: wet', 'Imputed rows: none'))
  writeLines(lines, file.path(folder, 'README.md'))
}
Readme(file.path(db, 'SrcA'), 'CC BY 4.0 (in-file; https://example.org/a). Tracked.')
Readme(file.path(db, 'SrcB'), 'CC BY-NC 4.0 (owner decision; https://example.org/b). Carve-out.')
Readme(file.path(db, 'SrcC'))                                   # no Licence: line
Readme(file.path(cf, 'ConvD'), 'unknown; owner to check https://example.org/d (nothing on disk).')

# a seed manifest: SrcA and SrcB classified, SrcC absent, one stale path, one live row
seed <- data.frame(
  folder = c('databases/SrcA', 'databases/SrcA', 'databases/SrcB', 'databases/SrcA', 'databases/Live'),
  label = c('SrcA', 'SrcA', 'SrcB', 'SrcA', 'live'),
  path = c('sources/databases/SrcA/data.csv', 'sources/databases/SrcA/Citation.bib',
           'sources/databases/SrcB/table.csv', 'sources/databases/SrcA/gone.csv',
           'sources/databases/Live/'),
  role = c('raw', 'doc', 'raw', 'raw', 'live'),
  bytes = '0', sha256 = 'stale',
  licence_class = c('CC BY 4.0', LICENCE_REPO, 'CC BY-NC 4.0', 'CC0 1.0', 'CC BY-NC 4.0'),
  statement_source = c('in-file', 'repository LICENSE', 'owner decision', 'README', 'owner decision'),
  redistributable = c('yes', 'yes', 'non-commercial', 'yes', 'non-commercial'),
  attribution = c('A (2020) Data A; CC BY 4.0', '', 'B (2021) Data B; CC BY-NC 4.0', '', 'Live DB'),
  check_url = c('https://example.org/a', '', 'https://example.org/b', '', 'https://example.org/live'),
  notes = c('', '', 'carve-out', '', 'nothing stored'),
  stringsAsFactors = FALSE)
manifest <- file.path(root, 'sources', 'source_files.csv')
write.csv(seed, manifest, row.names = FALSE)

m1 <- Messages(m <- BuildLicenceManifest(root, manifest, use_git = FALSE))
Expect(nrow(m) == 10 + 1, 'manifest has one row per file in the tree (10, READMEs included) plus the live row')
Expect(all(m$path[m$role != 'live'] == sort(m$path[m$role != 'live'], method = 'radix')),
       'file rows are in byte order of the path')
Expect(!'sources/databases/SrcA/gone.csv' %in% m$path, 'a path no longer present is dropped')
Expect(identical(attr(m, 'dropped'), 'sources/databases/SrcA/gone.csv'), 'the dropped path is reported')
a <- m[m$path == 'sources/databases/SrcA/data.csv', ]
Expect(a$licence_class == 'CC BY 4.0' && a$attribution == 'A (2020) Data A; CC BY 4.0' &&
         a$check_url == 'https://example.org/a', 'hand columns of a known path are kept')
Expect(a$sha256 == digest::digest(file.path(root, a$path), algo = 'sha256', file = TRUE) &&
         a$bytes == as.character(file.size(file.path(root, a$path))),
       'bytes and sha256 are recomputed')
Expect(a$sha256 == Sha256File(file.path(root, a$path)), 'Sha256File() agrees with digest')
c3 <- m[m$path == 'sources/databases/SrcC/raw.txt', ]
Expect(c3$licence_class == LICENCE_UNKNOWN && c3$role == 'raw' && c3$redistributable == 'unknown' &&
         c3$label == 'SrcC' && c3$folder == 'databases/SrcC',
       'a new raw file enters as unknown; owner to check with the folder name as label')
sc <- m[m$path == 'sources/databases/SrcA/BodyMass_SrcA.r', ]
Expect(sc$role == 'code' && sc$licence_class == LICENCE_REPO && sc$label == 'SrcA',
       'a new parse script enters as code under the repository licence with the folder label')
d <- m[m$path == 'sources/conversion_factors/ConvD/ratios.csv', ]
Expect(d$folder == 'conversion_factors/ConvD' && d$licence_class == LICENCE_UNKNOWN,
       'conversion-factor files are listed under conversion_factors/<Src>')
lv <- m[m$role == 'live', ]
Expect(nrow(lv) == 1 && lv$path == 'sources/databases/Live/' && lv$bytes == '' && lv$sha256 == '' &&
         lv$attribution == 'Live DB', 'the live row is kept without size or hash')
Expect(any(grepl('7 added, 1 dropped', m1)) && any(grepl('SrcC/raw.txt', m1)) && any(grepl('dropped: sources/databases/SrcA/gone.csv', m1)),
       'the run reports the added and dropped paths')
m2 <- BuildLicenceManifest(root, manifest, use_git = FALSE, quiet = TRUE)
Expect(identical(m[manifest_columns], m2[manifest_columns]), 'a second run is idempotent')
mr <- ReadLicenceManifest(manifest)
Expect(identical(mr$path, m$path) && identical(mr$sha256, m$sha256), 'the written manifest reads back')

lic_md <- file.path(root, 'sources', 'LICENSES.md')
lines <- WriteLicensesMd(mr, root, lic_md)
Expect(file.exists(lic_md) && any(grepl('^## Summary by licence class', lines)) &&
         any(grepl('^## Non-commercial and share-alike sources', lines)) &&
         any(grepl('^## Unknown: owner to check', lines)) && any(grepl('^## Not redistributed', lines)),
       'LICENSES.md has the summary, carve-out, not-redistributed and unknown sections')
Expect(any(grepl('databases/SrcB (`SrcB`)', lines, fixed = TRUE)) && any(grepl('A (2020) Data A', lines, fixed = TRUE)),
       'LICENSES.md lists the carve-out source and the attribution text')
Expect(any(grepl('databases/SrcC (`SrcC`)', lines, fixed = TRUE)) && any(grepl('databases/Live (`live`)', lines, fixed = TRUE)),
       'LICENSES.md lists the unknown folder and the live row')
Expect(sum(grepl('^\\| CC BY-NC 4.0 \\| 2 \\| 1 \\|', lines)) == 1, 'the summary counts folders and raw files per class')

# ---- the check: stops --------------------------------------------------------
cat('Part 1b: CheckSourceDocs() on the fixture tree\n')
report <- file.path(root, 'reports', 'warnings_licences.md')
Check <- function(...) CheckSourceDocs(db, manifest = manifest, report = report, ...)
err <- ErrorOf(Messages(Check()))
Expect(!is.null(err) && grepl('without a Licence: line: SrcC', err), 'a README without a Licence: line stops the run')
Readme(file.path(db, 'SrcC'), 'unknown; owner to check https://example.org/c (nothing on disk).')
msgs <- Messages(res <- Check())
Expect(nrow(res) == 4 && all(res$licence), 'after the fix every folder passes the stop')
Expect(any(grepl('2 source folder\\(s\\) have Licence: unknown; owner to check: SrcC, ConvD', msgs)),
       'unknown licences are warned about')
Expect(any(grepl('1 non-commercial / share-alike source\\(s\\).*: SrcB', msgs)), 'the carve-out is listed')
Expect(all(res$class_ok[!is.na(res$class_ok)]), 'every README class matches the manifest')
rep <- readLines(report)
Expect(any(grepl('^\\| SrcC \\| unknown; owner to check https://example.org/c', rep)) &&
         any(grepl('^\\| SrcB \\| CC BY-NC 4.0', rep)) && any(grepl('^# TaxonBodyMass_DB Licence Warnings -- ', rep)),
       'reports/warnings_licences.md lists the unknown and the carve-out folders')
Expect(any(grepl('^Folders checked: 4; unknown licence: 2; non-commercial / share-alike: 1\\.$', rep)), 'the report counts')

# a folder that is not in the manifest stops; with stop_on_missing_licence = FALSE it only warns
dir.create(file.path(db, 'SrcE'))
Readme(file.path(db, 'SrcE'), 'CC0 1.0 (README; https://example.org/e).')
err <- ErrorOf(Messages(Check()))
Expect(!is.null(err) && grepl('no row in source_files.csv: SrcE', err), 'a folder absent from the manifest stops the run')
msgs <- Messages(res <- Check(stop_on_missing_licence = FALSE))
Expect(any(grepl('no row in source_files.csv: SrcE', msgs)) && nrow(res) == 5, 'stop_on_missing_licence = FALSE warns instead')
rep <- readLines(report)
Expect(any(grepl('^\\| SrcE \\| CC0 1.0', rep)), 'the report lists the folder absent from the manifest')
# a mismatching class is a warning, not a stop
Readme(file.path(db, 'SrcA'), 'CC0 1.0 (README; https://example.org/a).')
msgs <- Messages(res <- Check(stop_on_missing_licence = FALSE))
Expect(any(grepl('do not start with a class the manifest records.*SrcA', msgs)) && isFALSE(res$class_ok[res$folder == 'SrcA']),
       'a README class the manifest does not record is warned about')
# the baseline keys stay warn-only
Readme(file.path(db, 'SrcA'), 'CC BY 4.0 (in-file).', base = FALSE)
msgs <- Messages(res <- Check(stop_on_missing_licence = FALSE))
Expect(any(grepl('README.md files lack required lines', msgs)) && any(grepl('SrcA: Filters: Mass type: Imputed rows:', msgs)),
       'Filters, Mass type and Imputed rows still warn only')
unlink(root, recursive = TRUE)

# ---- Part 2: the real tree -----------------------------------------------------
cat('Part 2: the repository\n')
real_manifest <- file.path(repo, 'sources', 'source_files.csv')
mr <- ReadLicenceManifest(real_manifest)
files <- ListSourceFiles(repo, use_git = TRUE)
Expect(length(files) > 400, 'the tracked source files are listed')
Expect(setequal(files, mr$path[mr$role != 'live']), 'the manifest lists exactly the tracked files')
sizes <- as.character(file.size(file.path(repo, mr$path[mr$role != 'live'])))
Expect(identical(sizes, mr$bytes[mr$role != 'live']), 'every manifest size matches the file')
hashes <- vapply(file.path(repo, mr$path[mr$role != 'live']), Sha256File, character(1), USE.NAMES = FALSE)
Expect(identical(hashes, mr$sha256[mr$role != 'live']), 'every manifest sha256 matches the file')
Expect(all(mr$role %in% c('raw', 'parsed', 'derived', 'code', 'doc', 'live')), 'roles are from the vocabulary')
Expect(all(mr$redistributable %in% c('yes', 'non-commercial', 'share-alike', 'no', 'unknown')),
       'redistributable values are from the vocabulary')
Expect(all(mr$licence_class[mr$role %in% c('code', 'doc', 'derived')] == LICENCE_REPO),
       'our own files are under the repository licence')
Expect(all(mr$licence_class[mr$role == 'parsed'] == LICENCE_FACTS), 'parsed files are transcriptions (facts)')
unk <- mr$role %in% c('raw', 'live') & LicenceIsUnknown(mr$licence_class)
Expect(all(nzchar(mr$check_url[unk])), 'every unknown row names the URL to check')
Expect(all(mr$redistributable[unk] == 'unknown'), 'unknown rows are not marked redistributable')
nc <- LicenceIsRestricted(mr$licence_class)
Expect(all(mr$redistributable[nc] %in% c('non-commercial', 'share-alike')), 'NC/SA rows are marked as carve-outs')
Expect(all(mr$redistributable[mr$licence_class %in% c(LICENCE_PUB, 'unpublished')] == 'no'),
       'publisher and unpublished files are not redistributable')
Expect(all(nzchar(mr$attribution[mr$role %in% c('raw', 'live') & !unk & mr$licence_class != LICENCE_REPO])),
       'every classified raw or live row has an attribution text')

msgs <- Messages(res <- CheckSourceDocs(file.path(repo, 'sources', 'databases'),
                                        report = file.path(tempdir(), 'warnings_licences_test.md')))
Expect(all(res$has_readme) && all(res$licence), 'every source folder has a README with a Licence: line')
Expect(all(res$class_ok), 'every README Licence: class is one the manifest records for the folder')
Expect(sum(res$restricted) == 8 && setequal(res$folder[res$restricted],
       c('Cai_etal_2025', 'Fishbase', 'Hechinger_etal_2011', 'Hoehler_etal_2023', 'Lane_2019',
         'Pata_2025', 'Quaardvark', 'Sealifebase')), 'the eight carve-out sources are flagged')
Expect(sum(res$unknown) == sum(ManifestFolders(mr)$unknown[ManifestFolders(mr)$folder != 'VertNet']),
       'the READMEs flag the same unknown folders as the manifest')

current <- readLines(file.path(repo, 'sources', 'LICENSES.md'), warn = FALSE)
regen   <- WriteLicensesMd(mr, repo, file.path(tempdir(), 'LICENSES_test.md'))
Expect(identical(current, regen), 'sources/LICENSES.md is the current regeneration of the manifest')
# the repository licence is CC BY-NC 4.0 (owner decision 2026-10-06) in the class label,
# the LICENSE file, the Scope and Position sections of LICENSES.md and the README
Expect(LICENCE_REPO == 'repository (CC BY-NC 4.0)', 'the repository licence class names CC BY-NC 4.0')
lic <- readLines(file.path(repo, 'LICENSE'), warn = FALSE)
Expect(startsWith(lic[1], 'Creative Commons Attribution-NonCommercial 4.0 International') &&
         any(lic == 'Attribution-NonCommercial 4.0 International') &&
         any(grepl('^Section 1 -- Definitions', lic)) && any(grepl('NonCommercial means not primarily intended', lic)) &&
         any(grepl('^Scope: ', lic)) && any(grepl('until 2026-10-06', lic)),
       'LICENSE is the CC BY-NC 4.0 legal code with the scope paragraph and the change date')
Expect(!any(grepl('Attribution 4.0 International \\(CC BY 4.0\\)', lic)), 'LICENSE no longer carries the CC BY 4.0 heading')
scope <- current[grep('^## Scope of the repository licence', current) + 2]
Expect(grepl('`LICENSE` (CC BY-NC 4.0', scope, fixed = TRUE) && grepl('NonCommercial term', scope),
       'LICENSES.md names CC BY-NC 4.0 and the NonCommercial term in the scope section')
pos <- current[grep('^## Position on values from non-commercial', current) + 2]
Expect(grepl('under the repository licence, CC BY-NC 4.0, as aggregated facts', pos, fixed = TRUE) &&
         grepl('share-alike term of Pata & Hunt', pos, fixed = TRUE) && grepl('no-derivatives term of Cai', pos, fixed = TRUE),
       'the position names CC BY-NC 4.0 and keeps the share-alike and no-derivatives carve-outs')
Expect(!any(grepl('repository (CC BY 4.0)', c(current, mr$licence_class), fixed = TRUE)),
       'neither LICENSES.md nor the manifest names the old repository class')
rd <- readLines(file.path(repo, 'README.md'), warn = FALSE)
Expect(any(grepl('The repository `LICENSE` is CC BY-NC 4.0', rd, fixed = TRUE)) &&
         !any(grepl('The repository `LICENSE` is CC BY 4.0', rd, fixed = TRUE)),
       'the README Data licences section states CC BY-NC 4.0')
regen_m <- BuildLicenceManifest(repo, real_manifest, use_git = TRUE, write = FALSE, quiet = TRUE)
Expect(identical(as.data.frame(regen_m)[manifest_columns], mr[manifest_columns]),
       'sources/source_files.csv is the current regeneration (no file added or dropped)')

cat(sprintf('\n%d checks, %d failed\n', n_checks, length(failures)))
if (length(failures) > 0) {
  cat(paste0('  FAIL ', failures, collapse = '\n'), '\n')
  quit(status = 1)
}
