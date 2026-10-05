# Builds references.csv (the reference list of Gonzalez_2025 for the citation
# tooling, R/library/citations/README.md) from the Dryad sheet 'References'
# exported as datapaper_2025_02_11_references.csv, which is kept verbatim.
# Run from anywhere: Rscript sources/databases/Gonzalez_2025/build_references.r
#
# The records' native key is `data.source1`. The upstream list keys its rows
# the same way for the 'paper' and 'template' rows, but
#  - the six database rows ('Vanni_database', 'Ikeda_database', ...) carry '-'
#    as data.source1 and are keyed here by their data.type; the records of the
#    Ikeda database cite 'Ikeda database' and are mapped to that row; the 22
#    sub-sources of the Vanni database ('Vanni et al 2002', 'McIntyre et al
#    2008', 'Milanovitch_2007', 'Vanni, MJ unpubl', ...) and 'Urabe 1993' of the
#    Elser database are not in the upstream list: their key is kept as the
#    citation text, with the database reference in `note`;
#  - the one row that names two papers ('Jochum et al. 2016 / Drescher et al.
#    2016', two DOIs) is split into two rows at the ' /' line break;
#  - the 'unpublished - <contributor>' template rows cite the StoichLife paper
#    itself; the key is prepended to that citation so that the entry reads as
#    unpublished data of the compilers (role `self` in the tooling, which looks
#    for 'unpubl' and the compiler's name); 'unpublished - Jackson' and
#    'unpublished - Potapov' (one row with a trailing blank) are listed twice
#    upstream and once here; 'unpublished - Rosanova' is cited by the
#    records but absent from the list (the list has 'unpublished - Rosanova /
#    Tiunov') and is added as a template row with a note.
# Columns: key, citation, doi, note (the upstream data.type, with the
# mapping notes above).
this_file <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE))
src_dir <- if (length(this_file) == 1) dirname(normalizePath(this_file)) else getwd()
up <- read.csv(file.path(src_dir, 'datapaper_2025_02_11_references.csv'), check.names = FALSE,
               stringsAsFactors = FALSE, colClasses = 'character', na.strings = c('', 'NA', '#N/A'),
               fileEncoding = 'UTF-8-BOM')
dat <- read.csv(file.path(src_dir, 'datapaper_2025_02_11_data.csv'), check.names = FALSE,
                stringsAsFactors = FALSE, na.strings = c('', 'NA', '#N/A'), fileEncoding = 'UTF-8-BOM')
dat <- dat[dat$kingdom_revised %in% 'Animalia' & !is.na(dat$body.weight.gr), ]
up$reference <- trimws(up$reference)
up$data.source1 <- trimws(up$data.source1)      # one 'unpublished - Potapov' row carries a trailing blank
dat$data.source1 <- trimws(dat$data.source1)
up <- up[!duplicated(up[, c('data.source1', 'data.type', 'reference')]), ]

out <- list()
Row <- function(key, citation, doi, note) data.frame(key = key, citation = citation, doi = doi, note = note,
                                                     stringsAsFactors = FALSE)
for (i in seq_len(nrow(up))) {
  key <- up$data.source1[i]; typ <- up$data.type[i]; cit <- up$reference[i]; doi <- up$DOI[i]
  if (key == '-') {                                   # database rows: keyed by data.type
    out[[length(out) + 1]] <- Row(typ, cit, doi, paste0(typ, ' (the compilers\' reference for the database)'))
  } else if (grepl(' /\\s*\\n', cit)) {               # two papers in one row
    cits <- trimws(strsplit(cit, ' /\\s*\\n')[[1]]); dois <- trimws(strsplit(doi, ' / ')[[1]])
    keys <- trimws(strsplit(key, ' / ')[[1]])
    stopifnot(length(cits) == length(dois), length(cits) == length(keys))
    for (j in seq_along(cits))
      out[[length(out) + 1]] <- Row(keys[j], cits[j], dois[j], paste0(typ, ' (upstream row \'', key, '\' split into its two papers)'))
  } else if (typ == 'template' && grepl('^unpublished - ', key)) {
    out[[length(out) + 1]] <- Row(key, paste0(key, '. ', cit), NA_character_,
                                  'template (unpublished data contributed to StoichLife; key prepended to the upstream citation of the compilation)')
  } else {
    out[[length(out) + 1]] <- Row(key, cit, doi, typ)
  }
}
out <- do.call(rbind, out)
# records' keys the list lacks
used <- unique(dat$data.source1)
used <- unique(unlist(strsplit(sub('^Jochum et al. 2016 / Drescher et al. 2016$',
                                   'Jochum et al. 2016; Drescher et al. 2016', used), '; ')))
miss <- setdiff(used, out$key)
db_ref <- setNames(out$citation[grepl('_database$', out$key)], out$key[grepl('_database$', out$key)])
db_doi <- setNames(out$doi[grepl('_database$', out$key)], out$key[grepl('_database$', out$key)])
for (k in sort(miss)) {
  typ <- unique(dat$data.type[dat$data.source1 == k])
  stopifnot(length(typ) == 1)
  if (k == 'Ikeda database') {
    out <- rbind(out, Row(k, db_ref[['Ikeda_database']], db_doi[['Ikeda_database']],
                          'Ikeda_database (records cite \'Ikeda database\'; mapped to the compilers\' database reference)'))
  } else if (typ == 'template') {
    stoich <- unique(up$reference[up$data.type == 'template' & grepl('^unpublished - ', up$data.source1)])
    stopifnot(length(stoich) == 1)
    out <- rbind(out, Row(k, paste0(k, '. ', stoich), NA_character_,
                          'template (not in the upstream list, which has \'unpublished - Rosanova / Tiunov\'; added as the other unpublished template rows)'))
  } else {
    out <- rbind(out, Row(k, k, NA_character_,
                          sprintf('%s sub-source; not in the upstream list, key kept as the citation (the database reference is %s DOI %s)',
                                  typ, db_ref[[typ]], db_doi[[typ]])))
  }
}
stopifnot(!anyDuplicated(out$key))
out <- out[order(out$key, method = 'radix'), ]
rownames(out) <- NULL
write.csv(out, file.path(src_dir, 'references.csv'), row.names = FALSE, na = '', fileEncoding = 'UTF-8')
cat(sprintf('references.csv: %d keys (%d used by animal rows with a mass, %d of them added for keys the upstream list lacks)\n',
            nrow(out), sum(out$key %in% used), length(miss)))
