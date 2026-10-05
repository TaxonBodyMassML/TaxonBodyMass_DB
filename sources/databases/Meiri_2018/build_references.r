# Build references.csv and key_map.csv for Meiri_2018 (issue #1, Stage 2) from
# the two supplements of Meiri (2018, Global Ecol. Biogeogr. 27:1168, doi
# 10.1111/geb.12773): Appendix S3 (geb12773-sup-0003-appendixs3.txt, the key
# table 'paper of' / 'paper' / 'Taxa', tab-separated, cp1252) and Appendix S1
# (geb12773-sup-0001-appendixs1.csv, the trait table whose three SVL reference
# columns hold the author-year keys of the length sources of every species).
#
#     Rscript sources/databases/Meiri_2018/build_references.r      (from the repository root)
#
# references.csv (key, citation, note): one row per entry of Appendix S3, the
# citation verbatim. The table's keys are not unique: 875 author-year keys
# stand for two or more different papers (the trait table tells them apart
# only through its own 'a'/'b' year letters, which the key table does not
# carry) and five keys repeat the same citation. A repeated citation is kept
# once; a key shared by different papers becomes '<key> [n]', n the entry's
# position among the rows of that key in the table's order, and `note` holds
# the entry's Taxa text ('taxa: ...'), the only field that tells the papers
# apart.
#
# key_map.csv (taxon, raw_key, key, method): how each record's raw key (the
# three SVL reference cells of Appendix S1 joined and split at ',' or ';' --
# SplitRefKeys(), as the parse script does) was mapped to a references.csv
# key, for the pairs where the mapping is not the identity: the key with a
# year letter ('Boulenger 1885b') or a spelling the table does not use
# ('Mcranie et al. 2005') looked up by the letter-less / folded form
# (method 'letter', 'normalised'); a key the table holds several times
# resolved to the one entry whose Taxa names the species, its genus or its
# family, or the one generic (family-less) entry when none does (method
# 'taxa:species', 'taxa:genus', 'taxa:family', 'taxa:generic'); a key that
# stays ambiguous after that ('ambiguous') or has no entry at all
# ('not_in_list') keeps the raw key, which the provenance table then reports
# as unmatched_key. Pairs resolved by an exact, unique key are not written.
# The parse script joins ref_keys through this file.
wd <- if (file.exists('sources/databases/Meiri_2018')) 'sources/databases/Meiri_2018' else '.'
source(file.path(wd, '..', '..', '..', 'R', 'library', 'citations', 'parse_reflists.r'))
source(file.path(wd, '..', '..', '..', 'R', 'library', 'citations', 'normalise_citation.r'))

# ---- Appendix S3 -> references.csv ----
s3 <- read.table(file.path(wd, 'geb12773-sup-0003-appendixs3.txt'), header = TRUE, sep = '\t', quote = '"',
                 stringsAsFactors = FALSE, fileEncoding = 'cp1252', encoding = 'UTF-8', comment.char = '',
                 fill = TRUE, na.strings = c('', 'NA'), check.names = FALSE)
names(s3) <- c('s3_key', 'citation', 'taxa')
s3$s3_key   <- trimws(s3$s3_key)
s3$citation <- trimws(gsub('\\s+', ' ', s3$citation))
s3$taxa     <- trimws(sub('[,. ]+$', '', trimws(s3$taxa)))
s3$row      <- seq_len(nrow(s3))
stopifnot(!anyNA(s3$s3_key), !anyNA(s3$citation))
# a key repeated with the same citation is one entry
s3 <- s3[!duplicated(paste(s3$s3_key, s3$citation)), ]
n_same <- 9911 - nrow(s3)
dup <- ave(seq_len(nrow(s3)), s3$s3_key, FUN = length) > 1
ord <- ave(seq_len(nrow(s3)), s3$s3_key, FUN = seq_along)
s3$key <- ifelse(dup, sprintf('%s [%d]', s3$s3_key, ord), s3$s3_key)
stopifnot(!anyDuplicated(s3$key))
refs <- data.frame(key = s3$key, citation = s3$citation,
                   note = ifelse(is.na(s3$taxa), NA_character_, paste0('taxa: ', s3$taxa)),
                   stringsAsFactors = FALSE)
write.csv(refs, file.path(wd, 'references.csv'), row.names = FALSE, na = '', fileEncoding = 'UTF-8')
cat(sprintf('references.csv: %d entries from %d rows of Appendix S3 (%d repeated citations dropped); %d distinct author-year keys, %d of them shared by %d entries\n',
            nrow(refs), 9911, n_same, length(unique(s3$s3_key)), length(unique(s3$s3_key[dup])), sum(dup)))

# ---- Appendix S1 -> the records' raw keys ----
adat <- read.csv(file.path(wd, 'geb12773-sup-0001-appendixs1.csv'), stringsAsFactors = FALSE,
                 fileEncoding = 'cp1252', encoding = 'UTF-8')
adat$taxon <- gsub('.*: (.*)', '\\1', adat$Binomial)
mass <- round(10^(as.numeric(adat$intercept) + as.numeric(adat$slope) *
                  log10(suppressWarnings(as.numeric(adat$maximum.SVL)))), 3)
adat <- adat[!is.na(mass), ]
svl_cols <- c('References..SVL.of.unsexed.individuals..neonates.and.hatchlings',
              'References..SVL.of.females', 'References..SVL.of.males')
stopifnot(all(svl_cols %in% names(adat)))
cells <- apply(adat[, svl_cols], 1, function(r) {
  r <- r[!is.na(r) & nzchar(trimws(r))]
  if (length(r) == 0) NA_character_ else paste(r, collapse = ';')
})
raw <- SplitRefKeys(cells, '[,;]')
ex  <- ExplodeRefKeys(raw)
# the previous token of the same cell (for a bare year), from the same split
prev_of <- unlist(lapply(cells, function(s) {
  if (is.na(s)) return(character(0))
  toks <- trimws(strsplit(s, '[,;]', perl = TRUE)[[1]])
  toks <- toks[nzchar(toks) & !toupper(toks) %in% c('NA', 'N/A', '-', '--', '?')]
  toks <- toks[!duplicated(toks)]
  c(NA_character_, toks[-length(toks)])[seq_along(toks)]
}))
stopifnot(length(prev_of) == nrow(ex))
pairs <- data.frame(taxon = adat$taxon[ex$record], genus = adat$Genus[ex$record],
                    family = adat$Family[ex$record], raw_key = ex$native_key, prev = prev_of, stringsAsFactors = FALSE)
pairs <- pairs[!duplicated(paste(pairs$taxon, pairs$raw_key, sep = '\r')), ]
cat(sprintf('Appendix S1: %d records with a mass, %d with an SVL reference, %d record x key links, %d distinct raw keys\n',
            nrow(adat), sum(!is.na(raw)), nrow(ex), length(unique(ex$native_key))))

# ---- resolution ----
Norm <- function(x) gsub('[^a-z0-9]', '', tolower(FoldASCII(x)))
norm_s3 <- Norm(s3$s3_key)
genera  <- unique(adat$Genus)
Specific <- function(tokens)   # Taxa tokens that name a family, a genus of the table or a binomial
  grepl('(idae|inae)$', tokens) | grepl(' ', tokens) | tokens %in% genera
owner_rules <- c('Boulenger 1885' = 'Boulenger 1885 [1]', 'Boulenger 1885b' = 'Boulenger 1885 [2]',
                 'Boulenger 1887' = 'Boulenger 1887 [2]')
Candidates <- function(key) {
  cand <- which(s3$s3_key == key); how <- 'exact'
  if (length(cand) == 0 && grepl('[0-9]{4}[a-z]$', key)) {
    cand <- which(s3$s3_key == sub('([0-9]{4})[a-z]$', '\\1', key)); how <- 'letter'
  }
  if (length(cand) == 0) { cand <- which(norm_s3 == Norm(key)); how <- 'normalised' }
  list(cand = cand, how = how)
}
# the cleaned forms of a token, tried in order after the token itself
Cleaned <- function(tok, prev) {
  out <- character(0)
  if (grepl('^[0-9]{4}[a-z]?$', tok) && !is.na(prev) && grepl('[0-9]{4}', prev))
    out <- c(out, paste(trimws(sub(' ?[0-9]{4}[a-z]?.*$', '', prev)), tok))
  if (grepl('^[0-9.]+ \\(', tok)) out <- c(out, sub('\\)?$', '', sub('^[0-9.]+ \\(', '', tok)))
  if (grepl('[0-9]{4}[a-z]? \\(.*\\)?$', tok)) out <- c(out, sub(' \\(.*$', '', tok))
  out <- sub('^(see also|also) ', '', out, ignore.case = TRUE)
  unique(out[nzchar(out)])
}
Resolve <- function(raw_key, taxon, genus, family, prev) {
  cc <- Candidates(raw_key); how <- cc$how
  if (length(cc$cand) == 0) {
    for (ck in Cleaned(raw_key, prev)) {
      cc <- Candidates(ck)
      if (length(cc$cand) > 0) { how <- paste0('cleaned:', cc$how); break }
    }
  }
  cand <- cc$cand
  if (length(cand) == 0) return(c(raw_key, 'not_in_list'))
  if (length(cand) == 1) return(c(s3$key[cand], how))
  toks <- lapply(strsplit(s3$taxa[cand], ',', fixed = TRUE), function(t) trimws(t[nzchar(t)]))
  tier <- list(species = vapply(toks, function(t) any(t == taxon | grepl(paste0('\\b', taxon, '\\b'), t)), logical(1)),
               genus   = vapply(toks, function(t) any(t == genus | grepl(paste0('\\b', genus, '\\b'), t)), logical(1)),
               family  = vapply(toks, function(t) any(t == family), logical(1)),
               generic = vapply(toks, function(t) length(t) == 0 || !any(Specific(t)), logical(1)))
  for (nm in names(tier)) if (sum(tier[[nm]]) == 1) return(c(s3$key[cand[tier[[nm]]]], paste0('taxa:', nm))) else if (sum(tier[[nm]]) > 1) break
  if (raw_key %in% names(owner_rules)) return(c(unname(owner_rules[raw_key]), 'owner_rule'))
  c(raw_key, 'ambiguous')
}
res <- t(mapply(Resolve, pairs$raw_key, pairs$taxon, pairs$genus, pairs$family, pairs$prev, USE.NAMES = FALSE))
pairs$key <- res[, 1]; pairs$method <- res[, 2]
stopifnot(all(pairs$key[!pairs$method %in% c('ambiguous', 'not_in_list')] %in% s3$key))
cat('resolution of the record x key pairs:\n')
print(table(pairs$method))
km <- pairs[pairs$method != 'exact' | pairs$key != pairs$raw_key, c('taxon', 'raw_key', 'key', 'method')]
km <- km[order(km$taxon, km$raw_key, method = 'radix'), ]
write.csv(km, file.path(wd, 'key_map.csv'), row.names = FALSE, na = '', fileEncoding = 'UTF-8')
cat(sprintf('key_map.csv: %d (taxon, raw key) pairs written (the %d exact unique matches are not)\n', nrow(km), nrow(pairs) - nrow(km)))
cat(sprintf('distinct references.csv keys cited by the records: %d; distinct raw keys left unresolved: %d; links resolved: %d of %d (%.1f%%)\n',
            length(unique(pairs$key[!pairs$method %in% c('ambiguous', 'not_in_list')])),
            length(unique(pairs$raw_key[pairs$method %in% c('ambiguous', 'not_in_list')])),
            sum(!pairs$method %in% c('ambiguous', 'not_in_list')), nrow(pairs), 100 * mean(!pairs$method %in% c('ambiguous', 'not_in_list'))))
