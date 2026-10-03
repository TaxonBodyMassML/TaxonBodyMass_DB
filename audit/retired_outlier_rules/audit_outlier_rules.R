# Staleness audit of the retired outlier rule files (issue #24, 2026-10-03).
#
# Parses every RemoveRecord()/RemoveSource() call in fix_outliers.r and
# fix_outliers_multisource.r together with the value quoted in the comment
# above it (`<Source>=<value>` in the multi-source file, `# <value> g →` in the
# single-source file), loads the current per-source frames from sources/Rdata/
# and compares the quoted value with the current geometric mean of that
# taxon x source. Run from the repository root with a complete sources/Rdata/
# (recompile = TRUE in R/RunMe.r regenerates it):
#
#   Rscript audit/retired_outlier_rules/audit_outlier_rules.R
#
# Prints the status counts and writes outlier_rules_audit_2026-10-03.csv in
# this directory, one row per rule: file, line, fun, taxon, source, quoted,
# cur_gm, n_rows, label_exists, status.
suppressPackageStartupMessages(library(dplyr))
if (!file.exists('R/RunMe.r')) stop('run this script from the repository root')
rdata <- 'sources/Rdata'
rule_dir <- 'audit/retired_outlier_rules'
files <- list.files(rdata, full.names = TRUE, pattern = '\\.Rdata$')
frames <- list()
for (f in files) { e <- new.env(); load(f, envir = e)
  for (nm in ls(e)) { x <- get(nm, e)
    if (is.data.frame(x) && all(c('taxon','mass_g','source_mass') %in% names(x))) {
      x <- x[, c('taxon','mass_g','source_mass')]; x$taxon <- as.character(x$taxon); x$mass_g <- as.numeric(x$mass_g)
      frames[[length(frames)+1]] <- x } } }
all <- bind_rows(frames)
all$label <- sub(';.*$', '', all$source_mass)
all$taxon_us <- gsub(' ', '_', trimws(all$taxon))
cur <- all %>% filter(!is.na(mass_g), mass_g > 0) %>% group_by(taxon_us, label) %>%
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
    else { v <- regmatches(block, regexpr('# ([0-9.,eE+-]+) g (→|->)', block))
      if (length(v) > 0) out$quoted[k] <- as.numeric(gsub(',', '', sub('# ([0-9.,eE+-]+) g.*', '\\1', v[1]))) }
  }
  out
}
rules <- bind_rows(parse_rules(file.path(rule_dir, 'fix_outliers.r')),
                   parse_rules(file.path(rule_dir, 'fix_outliers_multisource.r')))
labels_present <- unique(all$label)
rules <- rules %>% left_join(cur, by = c('taxon' = 'taxon_us', 'source' = 'label')) %>%
  mutate(label_exists = source %in% labels_present,
         status = case_when(!label_exists ~ 'label gone',
                            is.na(cur_gm) ~ 'record gone',
                            is.na(quoted) ~ 'present (no quoted value)',
                            abs(log10(cur_gm / quoted)) < log10(1.01) ~ 'present, value unchanged',
                            TRUE ~ 'present, value CHANGED'))
cat('Rules:', nrow(rules), ' (', sum(rules$file == 'fix_outliers.r'), 'single-source,', sum(rules$file != 'fix_outliers.r'), 'multi-source )\n\n')
print(as.data.frame(rules %>% count(status)))
cat('\nStale rules (record gone / value changed / label gone) by source:\n')
print(as.data.frame(rules %>% filter(status != 'present, value unchanged') %>% count(source, status) %>% arrange(desc(n))), row.names = FALSE)
cat('\nDeLong_etal_2010 rules in detail:\n')
print(as.data.frame(rules %>% filter(source == 'DeLong_etal_2010') %>% select(file, line, taxon, quoted, cur_gm, status) %>% mutate(ratio = cur_gm / quoted)), row.names = FALSE)
cat('\nOther changed-value rules:\n')
print(as.data.frame(rules %>% filter(status == 'present, value CHANGED', source != 'DeLong_etal_2010') %>% select(file, line, taxon, source, quoted, cur_gm) %>% mutate(ratio = signif(cur_gm / quoted, 3))), row.names = FALSE)
write.csv(rules, file.path(rule_dir, 'outlier_rules_audit_2026-10-03.csv'), row.names = FALSE)
