# Tests for the byte-stability of the output tables (#53): OrderForPass1() in
# R/library/helpers.r (the fixed row order before the Pass-1 summarise of
# RunMe.r section 5, so that the within-source geometric means, and with them
# log10_range, do not depend on the order in which the sources were parsed and
# merged), the write-time rounding of log10_range by RunMe.r section 7 (the
# real section is run on synthetic tables under tempdir(), so the code under
# test is RunMe.r itself), the range filter's use of the unrounded value, and
# the wiring in RunMe.r. No network access, no cached frames and no packages
# beyond base R are needed.
#
#   Rscript R/library/tests/test_output_stability.R      (from any directory)
#
# Prints one line per expectation and exits with status 1 if any failed.

this_file <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE))
if (length(this_file) == 0)
  this_file <- file.path('R', 'library', 'tests', 'test_output_stability.R')
repo <- normalizePath(file.path(dirname(this_file), '..', '..', '..'))
source(file.path(repo, 'R', 'library', 'helpers.r'))
source(file.path(repo, 'R', 'library', 'remove_high_range.r'))

failures <- character(0)
n_checks <- 0L
Expect <- function(ok, what) {
  n_checks <<- n_checks + 1L
  if (!isTRUE(ok)) failures <<- c(failures, what)
  cat(sprintf('  %s %s\n', if (isTRUE(ok)) 'ok  ' else 'FAIL', what))
}
Skip <- function(what) cat(sprintf('  skip %s\n', what))

# ---- 1. mean() depends on the summation order ----------------------------------
cat('mean(log10()) and the row order\n')
# Six values (g) whose log10 values sum to different doubles in different
# orders when the accumulator is a double. R's mean() accumulates in long
# double, which is a double on arm64 macOS and wherever long doubles are
# disabled; with a wider accumulator the demonstration is skipped (the property
# that matters, section 2, holds either way).
fixture <- c(1.96, 1.69, 33.9, 70.7, 44, 1.46)
Permutations <- function(v) {
  if (length(v) <= 1) return(list(v))
  do.call(c, lapply(seq_along(v), function(i)
    lapply(Permutations(v[-i]), function(p) c(v[i], p))))
}
perms <- Permutations(seq_along(fixture))
means <- vapply(perms, function(p) mean(log10(fixture[p])), numeric(1))
asc   <- order(fixture)
double_accumulator <- .Machine$sizeof.longdouble <= 8L   # a double is 8 bytes
if (double_accumulator) {
  Expect(length(unique(means)) > 1,
         sprintf('the %d permutations of the fixture give %d distinct means (ascending %.17g, descending %.17g)',
                 length(perms), length(unique(means)),
                 mean(log10(fixture[asc])), mean(log10(fixture[rev(asc)]))))
} else Skip('order dependence of mean(): the long double accumulator is wider than a double here')
Expect(all(abs(means - means[1]) < 1e-12), 'no permutation moves the mean by more than 1e-12')
# a permutation whose mean differs from the ascending order's (any permutation
# where the accumulator cannot tell them apart), for section 2
differing <- perms[means != mean(log10(fixture[asc]))]
flip <- if (length(differing) > 0) differing[[1]] else rev(asc)

# ---- 2. OrderForPass1() ----------------------------------------------------------
cat('OrderForPass1()\n')
Records <- function(taxon, genus, species, source_label, mass_g, source_mass = source_label,
                    source_group = source_label) {
  data.frame(taxon = taxon, genus = genus, species = species, source_label = source_label,
             source_group = source_group, source_mass = source_mass, mass_g = mass_g,
             taxon_provided = gsub('_', ' ', taxon), stringsAsFactors = FALSE)
}
# One species with the fixture's six records in a pooled source group, one
# accepted species reached through two input names (a synonym and the accepted
# name, each with a value in the same source), one species with a record whose
# value is NA and a value carrying a conversion CiteID.
recs <- rbind(
  Records('Aus_bus', 'Aus', 'Aus bus', 'vertnet-aves-sept2016', fixture, source_group = 'vertnet'),
  Records('Raja_erinacea',      'Leucoraja', 'Leucoraja erinacea', 'Cai_etal_2025', 520),
  Records('Leucoraja_erinacea', 'Leucoraja', 'Leucoraja erinacea', 'Cai_etal_2025', 500),
  Records('Cus_dus', 'Cus', 'Cus dus', 'Brose_etal_2018', c(NA, 12, 9.5)),
  Records('Cus_dus', 'Cus', 'Cus dus', 'Brey_2010', 11, source_mass = 'Brey_2010; Brey_2010_conv'))
p1 <- recs
p2 <- recs[c(flip, rev(seq_len(nrow(recs))[-seq_along(fixture)])), ]
rownames(p2) <- NULL

# Pass 1 as RunMe.r computes it (dplyr evaluates these base functions per
# group, over the group's rows in their input order), in base R.
Pass1 <- function(dat) {
  idx <- split(seq_len(nrow(dat)), paste(dat$genus, dat$species, dat$source_group))
  data.frame(
    taxon          = vapply(idx, function(i) dat$taxon[i][1], character(1)),
    taxon_provided = vapply(idx, function(i) paste(unique(dat$taxon_provided[i]), collapse = '; '), character(1)),
    mass_g         = vapply(idx, function(i) 10^mean(log10(dat$mass_g[i]), na.rm = TRUE), numeric(1)),
    stringsAsFactors = FALSE)
}
g_fix <- 'Aus Aus bus vertnet'
g_syn <- 'Leucoraja Leucoraja erinacea Cai_etal_2025'
u1 <- Pass1(p1); u2 <- Pass1(p2)
Expect(identical(rownames(u1), rownames(u2)) && nrow(u1) == 4,
       'the two permutations form the same four species x source groups')
if (double_accumulator) {
  Expect(u1[g_fix, 'mass_g'] != u2[g_fix, 'mass_g'],
         'unsorted, the two permutations give different within-source means for the fixture species')
} else Skip('unsorted means differ: not demonstrable with this accumulator')
Expect(u1[g_syn, 'taxon'] != u2[g_syn, 'taxon'],
       'unsorted, the representative taxon of the two-name species follows the input order')

s1 <- OrderForPass1(p1); s2 <- OrderForPass1(p2)
Expect(identical(s1, s2), 'OrderForPass1() returns the identical frame for both permutations')
Expect(nrow(s1) == nrow(recs) && identical(rownames(s1), as.character(seq_len(nrow(recs)))),
       'all rows are kept and the row names are reset')
v1 <- Pass1(s1); v2 <- Pass1(s2)
Expect(identical(v1, v2), 'after OrderForPass1() the Pass-1 summaries of both permutations are identical')
Expect(identical(v1[g_fix, 'mass_g'], 10^mean(log10(fixture[asc]))),
       'the within-source mean is the one of the values in ascending order')
Expect(v1[g_syn, 'taxon'] == 'Leucoraja_erinacea',
       'the representative taxon is the first input name in byte order')
Expect(v1[g_syn, 'taxon_provided'] == 'Leucoraja erinacea; Raja erinacea',
       'taxon_provided lists the input names in that order')
cus <- s1[s1$taxon == 'Cus_dus', ]
Expect(identical(cus$source_label, c('Brey_2010', rep('Brose_etal_2018', 3))) &&
         identical(cus$mass_g, c(11, 9.5, 12, NA)),
       'within a name the rows are ordered by source label, then value, NA last')
loc <- Sys.getlocale('LC_COLLATE')
invisible(Sys.setlocale('LC_COLLATE', 'C'))
sC <- OrderForPass1(p2)
invisible(Sys.setlocale('LC_COLLATE', loc))
Expect(identical(sC, s1), 'the order is the same in the C locale')
Expect(inherits(try(OrderForPass1(recs[, setdiff(names(recs), 'source_label')]), silent = TRUE), 'try-error'),
       'a frame without one of the key columns stops')

# ---- 3. write-time rounding: RunMe.r section 7 on synthetic tables --------------
cat('RunMe.r section 7: write-time rounding\n')
runme <- readLines(file.path(repo, 'R', 'RunMe.r'))
from  <- grep('^# 7\\. Write outputs', runme)
to    <- grep('^# 8\\. Write citations CSV', runme) - 1L
stopifnot(length(from) == 1, length(to) == 1, from < to)
section <- parse(text = runme[from:to])
wd_root <- file.path(tempdir(), 'issue53_outputs')
dir.create(wd_root, showWarnings = FALSE)
ranges <- c(0, 0.807405972371, 0.0465070413625369, 0.652820406262793, 0.2,
            1.0000004, 2.5e-7, 3.34073963289288e-06)
enriched <- data.frame(genus = 'Aus', species = paste('Aus', letters[seq_along(ranges)]),
                       log10_range = ranges,
                       mass_g = signif(c(17.76, 43.83, 0.3126, 1300.123, 1, 2, 3, 4), 4),
                       stringsAsFactors = FALSE)
gdat <- data.frame(taxon = c('Aus', 'Bus', 'Cus'), mass_g = c(1234.5678, 0.000123456, 2543),
                   source_mass = 'x', n = 1L, n_independent = 1L, stringsAsFactors = FALSE)
eval(section)
sp <- read.csv(file.path(wd_root, 'TaxonBodyMass.csv'), colClasses = 'character')
Expect(identical(sp$log10_range, c('0', '0.807406', '0.046507', '0.65282', '0.2', '1', '0', '3e-06')),
       'log10_range is written to six decimals (trailing zeros dropped, below 5e-7 as 0, write.csv notation)')
Expect(identical(sp$mass_g, c('17.76', '43.83', '0.3126', '1300', '1', '2', '3', '4')),
       'mass_g is written as Pass 2 leaves it (four significant figures)')
gl <- read.csv(file.path(wd_root, 'TaxonBodyMass_GenusLevel.csv'), colClasses = 'character')
Expect(identical(gl$mass_g, c('1235', '0.0001235', '2543')),
       'genus-level mass_g is written to four significant figures')
unlink(wd_root, recursive = TRUE)

# ---- 4. the range filter compares the unrounded value ---------------------------
cat('remove_high_range_taxa() and the rounding\n')
edge <- data.frame(taxon = c('a', 'b', 'c', 'd'), log10_range = c(1.0000004, 0.9999996, 1, NA),
                   stringsAsFactors = FALSE)
res  <- remove_high_range_taxa(edge, threshold = 1)
Expect(res$n_removed == 1 && identical(res$dat$taxon, c('b', 'c', 'd')),
       'a species at log10_range 1.0000004 is removed; 0.9999996, 1 and NA are kept')
Expect(round(1.0000004, 6) <= 1,
       'rounded to six decimals first, that species would have passed the filter')

# ---- 5. wiring in RunMe.r ---------------------------------------------------------
cat('R/RunMe.r wiring\n')
i_group <- grep('^adat_enriched\\$source_group <- SourceGroup\\(adat_enriched\\$source_label\\)', runme)
i_order <- grep('^adat_enriched <- OrderForPass1\\(adat_enriched\\)', runme)
i_pass1 <- grep('^within_source <- adat_enriched %>%', runme)
Expect(length(i_group) == 1 && length(i_order) == 1 && length(i_pass1) == 1 &&
         i_group < i_order && i_order < i_pass1,
       'OrderForPass1() is called once, after the source group is set and before the Pass-1 summarise')
i_check  <- grep('^check_enriched\\(enriched', runme)
i_filter <- grep('remove_high_range_taxa\\(enriched, threshold = 1\\)', runme)
i_round  <- grep('^enriched\\$log10_range <- round\\(enriched\\$log10_range, 6\\)', runme)
i_write  <- grep("^write\\.csv\\(enriched, file = file\\.path\\(wd_root, 'TaxonBodyMass\\.csv'\\)", runme)
Expect(length(i_check) == 1 && length(i_filter) == 1 && length(i_round) == 1 && length(i_write) == 1 &&
         i_check < i_filter && i_filter < i_round && i_round < i_write,
       'log10_range is rounded once, after check_enriched() and the range filter and before write.csv()')
Expect(!any(grepl('round\\(.*log10_range', runme[seq_len(i_round - 1L)])),
       'nothing rounds log10_range earlier in RunMe.r')

# ---- summary -------------------------------------------------------------------
cat(sprintf('\n%d expectations, %d failed\n', n_checks, length(failures)))
if (length(failures) > 0) {
  cat(paste0('  FAIL: ', failures, '\n'), sep = '')
  quit(status = 1)
}
