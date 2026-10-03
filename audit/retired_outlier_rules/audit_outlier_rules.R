# Staleness audit of the retired outlier rule files (issue #24, 2026-10-03).
#
# Parses every RemoveRecord()/RemoveSource() call in fix_outliers.r and
# fix_outliers_multisource.r together with the value quoted in the comment
# above it (`<Source>=<value>` in the multi-source file; `# <value> g →` or
# `# <value> g;` in the single-source file, where a `# — → ... same value`
# comment refers to the preceding rule for the taxon's old name and inherits
# its value), rebuilds the per-source frames exactly as the retired
# rules would have seen them, and compares the quoted value with the current
# geometric mean of that taxon x source. Run from the repository root with a
# complete sources/Rdata/ (recompile = TRUE in R/RunMe.r regenerates it):
#
#   Rscript audit/retired_outlier_rules/audit_outlier_rules.R
#
# Pipeline stage reproduced
# -------------------------
# The rules ran in R/RunMe.r section 2b at main 39dd7fd (the last commit that
# contained the mechanism) as
#   if (FixOutlierValues) { source_list <- lapply(source_list, FixOutliersMultiSource)
#                           source_list <- lapply(source_list, FixOutliers) }
# after the steps below, which this script repeats in the same order with the
# same functions sourced from R/library/ (the current R/RunMe.r applies the
# identical chain, minus the retired block):
#   section 2   load the first object of every sources/Rdata/*.Rdata
#   section 2b  FixFormatting()         fix_formatting.r    ' ' -> '_', diacritics
#                                                            to ASCII, strip
#                                                            non-alpha, Genus_species
#               NormaliseSourceLabel()  helpers.r           on source_mass
#               FixMisspellings()       fix_misspellings.r  taxon renames, e.g.
#                                                            Corophium_acutum ->
#                                                            Apocorophium_acutum
#               RemoveNonTaxa()         fix_nontaxa.r       drop non-species rows
#               RemoveExtinct()         filter_extinct.r    drop extinct taxa
# The first version of this script (PR #25) grouped the raw cached frames with
# ad-hoc approximations (' ' -> '_' on taxon, source_mass truncated at ';'), so
# a taxon renamed by FixMisspellings() was reported as present under its old
# name and as "record gone" under its new one (Copilot review of PR #25).
#
# Matching
# --------
# The retired helpers (helpers.r at 39dd7fd) compared the rule's `source`
# argument with source_mass exactly: RemoveRecord() dropped the rows with
# `dat$taxon == taxon & dat$source_mass == source`, and RemoveSource() set
# mass_g to NA where `dat$source_mass == src` (its gsub() only edited the label
# string of composite rows and removed no value). Conversion-suffix labels such
# as 'McCoy_2008; Brey_2010' or 'Ikeda_2014; Kiorboe_2013' are still present at
# this stage, so a rule naming the bare label would not have touched those
# rows. This audit matches exactly as the helpers did (taxon == rule taxon and
# source_mass == rule source), and `label_exists` means the exact label occurs
# as a source_mass value in some frame. Rules whose taxon has rows carrying the
# label only inside a composite string are listed on the console so that case
# stays visible.
#
# Prints the status counts and writes outlier_rules_audit_2026-10-03.csv in
# this directory, one row per rule: file, line, fun, taxon, source, quoted,
# cur_gm, n_rows, label_exists, status.
suppressPackageStartupMessages(library(dplyr))
if (!file.exists('R/RunMe.r')) stop('run this script from the repository root')
wd_root  <- getwd()          # filter_extinct.r reads R/library/extinct_taxa.csv through it
rdata    <- 'sources/Rdata'
rule_dir <- 'audit/retired_outlier_rules'
for (f in c('helpers.r', 'fix_formatting.r', 'fix_misspellings.r', 'fix_nontaxa.r', 'filter_extinct.r'))
  source(file.path('R', 'library', f))

# Section 2: one frame per file, the first object, as RunMe loads it.
source_list <- lapply(list.files(rdata, full.names = TRUE, pattern = '\\.Rdata$'), function(f) {
  e <- new.env(); load(f, envir = e); get(ls(e)[1], envir = e) })
n_rows_step <- c(loaded = sum(sapply(source_list, nrow)))
# Section 2b, in RunMe order, up to the point where the retired block ran.
source_list <- lapply(source_list, FixFormatting)
n_rows_step['FixFormatting'] <- sum(sapply(source_list, nrow))
source_list <- lapply(source_list, function(df) { df$source_mass <- NormaliseSourceLabel(df$source_mass); df })
source_list <- lapply(source_list, FixMisspellings)
n_rows_step['FixMisspellings'] <- sum(sapply(source_list, nrow))
source_list <- lapply(source_list, RemoveNonTaxa)
n_rows_step['RemoveNonTaxa'] <- sum(sapply(source_list, nrow))
source_list <- suppressMessages(lapply(source_list, RemoveExtinct))   # it reports each frame's drops
n_rows_step['RemoveExtinct'] <- sum(sapply(source_list, nrow))

all <- bind_rows(lapply(source_list, function(df)
  data.frame(taxon = as.character(df$taxon), mass_g = as.numeric(df$mass_g),
             source_mass = as.character(df$source_mass), stringsAsFactors = FALSE)))
cur <- all %>% filter(!is.na(mass_g), mass_g > 0) %>% group_by(taxon, source_mass) %>%
  summarise(cur_gm = 10^mean(log10(mass_g)), n_rows = n(), .groups = 'drop')
parse_rules <- function(file) {
  lines <- readLines(file)
  idx <- grep('^\\s*dat <- (RemoveRecord|RemoveSource)\\(', lines)
  m <- regmatches(lines[idx], regexec('(RemoveRecord|RemoveSource)\\(dat, "([^"]+)", "([^"]+)"', lines[idx]))
  out <- data.frame(file = basename(file), line = idx, fun = sapply(m, `[`, 2), taxon = sapply(m, `[`, 3),
                    source = sapply(m, `[`, 4), quoted = NA_real_, stringsAsFactors = FALSE)
  for (k in seq_along(idx)) {
    start <- if (k == 1) 1 else idx[k-1] + 1
    block <- lines[start:(idx[k]-1)]
    src <- out$source[k]
    tok <- regmatches(block, regexpr(paste0(gsub('([.])', '\\\\\\1', src), '=[0-9.eE+-]+'), block))
    if (length(tok) > 0) out$quoted[k] <- as.numeric(sub('.*=', '', tok[1]))
    else {
      # single-source file: `# <value> g → <expected> g; ...` or `# <value> g; ...`
      v <- regmatches(block, regexpr('# ([0-9.,eE+-]+) g(;| (→|->))', block))
      if (length(v) > 0) out$quoted[k] <- as.numeric(gsub(',', '', sub('# ([0-9.,eE+-]+) g.*', '\\1', v[1])))
      # `# — → <expected> g; corrected name; same value [as above]`: the rule for
      # a renamed taxon written directly after the rule for its old name (same
      # source) quotes no value of its own; it saw the value quoted above it.
      else if (k > 1 && out$source[k-1] == src && any(grepl('^\\s*# — →.*same value', block)))
        out$quoted[k] <- out$quoted[k-1]
    }
  }
  out
}
rules <- bind_rows(parse_rules(file.path(rule_dir, 'fix_outliers.r')),
                   parse_rules(file.path(rule_dir, 'fix_outliers_multisource.r')))
labels_present <- unique(all$source_mass[!is.na(all$source_mass)])
rules <- rules %>% left_join(cur, by = c('taxon', 'source' = 'source_mass')) %>%
  mutate(label_exists = source %in% labels_present,
         status = case_when(!label_exists ~ 'label gone',
                            is.na(cur_gm) ~ 'record gone',
                            is.na(quoted) ~ 'present (no quoted value)',
                            abs(log10(cur_gm / quoted)) < log10(1.01) ~ 'present, value unchanged',
                            TRUE ~ 'present, value CHANGED'))
cat('Rows per step:', paste(names(n_rows_step), n_rows_step, sep = ' = ', collapse = ', '), '\n')
cat('Rules:', nrow(rules), ' (', sum(rules$file == 'fix_outliers.r'), 'single-source,', sum(rules$file != 'fix_outliers.r'), 'multi-source )\n\n')
print(as.data.frame(rules %>% count(status)))
cat('\nStale rules (record gone / value changed / label gone) by source:\n')
print(as.data.frame(rules %>% filter(status != 'present, value unchanged') %>% count(source, status) %>% arrange(desc(n))), row.names = FALSE)
cat('\nDeLong_etal_2010 rules in detail:\n')
print(as.data.frame(rules %>% filter(source == 'DeLong_etal_2010') %>% select(file, line, taxon, quoted, cur_gm, status) %>% mutate(ratio = cur_gm / quoted)), row.names = FALSE)
cat('\nOther changed-value rules:\n')
print(as.data.frame(rules %>% filter(status == 'present, value CHANGED', source != 'DeLong_etal_2010') %>% select(file, line, taxon, source, quoted, cur_gm) %>% mutate(ratio = signif(cur_gm / quoted, 3))), row.names = FALSE)
# Rows of a rule's taxon whose source_mass carries the rule's label only inside
# a composite string ('<label>; <conversion ref>'); the retired helpers would
# not have matched them (see the header), and neither does the join above.
composite <- all %>% filter(grepl(';', source_mass, fixed = TRUE)) %>%
  inner_join(distinct(rules, taxon, source), by = 'taxon', relationship = 'many-to-many') %>%
  filter(mapply(function(s, lab) lab %in% trimws(strsplit(s, ';', fixed = TRUE)[[1]]), source_mass, source)) %>%
  count(taxon, source, source_mass, name = 'n_rows')
cat('\nRule taxa with rows carrying the label only inside a composite source_mass (not matched):\n')
if (nrow(composite) > 0) print(as.data.frame(composite), row.names = FALSE) else cat('  none\n')
write.csv(rules, file.path(rule_dir, 'outlier_rules_audit_2026-10-03.csv'), row.names = FALSE)
