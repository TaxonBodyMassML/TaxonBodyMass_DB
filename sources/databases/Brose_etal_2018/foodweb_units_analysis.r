# Issue #14 (Phase A): per-food-web evidence on the unit of the GATEWAy body
# masses (283_2_FoodWebDataBase_2018_12_10.csv), using R/library/unit_audit.r.
#
# For every `foodweb.name` the script reproduces what BodyMass_Brose_etal_2018.r
# and RunMe.r let through (adult/unspecified life stages, positive masses, name
# cleaning, species resolution, autotroph filter), takes the within-web geometric
# mean per accepted species and compares it with the median of the other
# sources' Pass-1 values (see unit_audit.r). Labels known to re-publish a web's
# own values are excluded for that web (dependent_labels). Mass values shared by
# >= 5 species of one citation are flagged as group-level placeholders and the
# ratio is also given without them (med_ratio_np).
#
# Run from the repository root with a complete sources/Rdata/:
#   Rscript sources/databases/Brose_etal_2018/foodweb_units_analysis.r
# Reads  foodweb_units_decisions.csv (hand-made unit class / action per
#        link.citation; a row with a foodweb.name overrides its citation row)
# Writes foodweb_units.csv (one row per web; tracked)
#        tmp/foodweb_units_species.csv  (web x species detail)
#        tmp/foodweb_units_citation.csv (pooled per link.citation)
#        tmp/foodweb_units_evidence.csv (per web, all computed columns)

wd_root  <- normalizePath(if (file.exists('R/RunMe.r')) '.' else '..')
source(file.path(wd_root, 'R', 'library', 'unit_audit.r'))
UnitAuditInit(wd_root)
wd_rdata <- file.path(wd_root, 'sources', 'Rdata')
wd_src   <- file.path(wd_root, 'sources', 'databases', 'Brose_etal_2018')
wd_tmp   <- file.path(wd_root, 'tmp')
dir.create(wd_tmp, showWarnings = FALSE)

# Labels whose values are (in part) the same data as a GATEWAy web, by link.citation.
dependent_labels <- list(
  'Lafferty et al. (2006)' = 'Hechinger_etal_2011',
  'Warren (1989)'          = 'Brose_2005'           # con.size.citation = 'Brose et al. 2005'
)
# Brose_2005 (Data Retriever predator-prey-body-ratio) is the ancestor of several
# GATEWAy webs and is kept out of the comparison set altogether.
excluded_labels <- c('Brose_etal_2018', 'Brose_2005')

##########################################################################
# 1. GATEWAy rows as the parser stacks them, with their web metadata
##########################################################################
message('Reading GATEWAy csv ...')
raw <- read.csv(file.path(wd_src, '283_2_FoodWebDataBase_2018_12_10.csv'), header = TRUE)
n_links_web <- raw %>% mutate(link.citation = trimws(link.citation)) %>% count(foodweb.name, link.citation, name = 'n_links')
# the parser's stacking and life-stage filter (R/library/foodweb_units.r)
dat <- StackGateway(raw, extra = c('taxonomy.level', 'lifestage', 'size.method', 'size.citation', 'length.mean.cm.'))
names(dat)[names(dat) %in% c('taxonomy.level', 'size.method', 'size.citation', 'length.mean.cm.')] <-
  c('tax_level', 'size_method', 'size_citation', 'length_cm')
dat$length_cm <- suppressWarnings(as.numeric(dat$length_cm))
dat$ecosystem <- raw$ecosystem.type[match(dat$foodweb.name, raw$foodweb.name)]
dat$location  <- raw$geographic.location[match(dat$foodweb.name, raw$foodweb.name)]
dat$taxon_raw <- dat$taxon
message(sprintf('  %d stacked rows after the parser filters', nrow(dat)))

raw_web <- dat %>% group_by(foodweb.name, link.citation) %>%
  summarise(ecosystem = first(ecosystem), location = first(location),
            n_rows_parser = n(), n_names_parser = n_distinct(taxon),
            size_methods = paste(sort(unique(trimws(gsub('\\s+', ' ', na.omit(size_method))))), collapse = ' | '),
            size_citations = paste(sort(unique(substr(na.omit(size_citation), 1, 60))), collapse = ' | '),
            .groups = 'drop')

##########################################################################
# 2. Species resolution, other sources, web x species table
##########################################################################
bro <- CleanResolve(dat)
message(sprintf('  %d GATEWAy rows resolve to %d accepted species', nrow(bro), n_distinct(bro$species)))

message('Loading other sources ...')
oth_p1 <- LoadOtherPass1(wd_rdata, exclude_files = 'BodyMass_Brose_etal_2018.Rdata',
                         exclude_labels = excluded_labels)
message(sprintf('  %d species x label values from %d other labels', nrow(oth_p1), n_distinct(oth_p1$label)))
oth_all <- OtherSummary(oth_p1)

ws <- bro %>% group_by(foodweb.name, link.citation, species) %>%
  summarise(web_lg      = mean(log10(mass_g)),
            n_rows      = n(),
            n_values    = n_distinct(signif(mass_g, 6)),
            metab       = ModeOf(metab),
            size_method = ModeOf(trimws(gsub('\\s+', ' ', size_method))),
            length_cm   = suppressWarnings(median(length_cm[!is.na(length_cm) & length_cm > 0])),
            phylum      = first(phylum), class = first(class),
            .groups = 'drop')
ws$grp <- MetabGroup(ws$metab)
ph <- PlaceholderValues(ws, 'link.citation', min_species = 5)
ws$placeholder <- paste(ws$link.citation, signif(10^ws$web_lg, 4)) %in% paste(ph$link.citation, ph$mass)

ws <- bind_rows(lapply(split(ws, ws$link.citation), function(d) {
  dep <- dependent_labels[[d$link.citation[1]]]
  o   <- if (is.null(dep)) oth_all else OtherSummary(oth_p1, dep)
  left_join(d, o, by = 'species')
}))
ws$ratio <- ws$web_lg - ws$other_lg
ws <- ws[order(ws$link.citation, ws$foodweb.name, ws$ratio), ]

##########################################################################
# 3. Per-web and per-citation summaries, decisions, outputs
##########################################################################
web_sum <- ws %>% group_by(foodweb.name, link.citation) %>% group_modify(~RatioSummary(.x)) %>% ungroup()
web_sum <- raw_web %>% left_join(n_links_web, by = c('foodweb.name', 'link.citation')) %>%
  left_join(web_sum, by = c('foodweb.name', 'link.citation'))
for (col in c('n_rows', 'n_species', 'n_shared', 'n_placeholder'))
  web_sum[[col]][is.na(web_sum[[col]])] <- 0L

cit_sum <- ws %>% group_by(link.citation) %>% group_modify(~RatioSummary(.x)) %>% ungroup() %>%
  left_join(raw_web %>% group_by(link.citation) %>%
              summarise(n_webs = n(), ecosystem = paste(unique(ecosystem), collapse = '|'),
                        n_rows_parser = sum(n_rows_parser), .groups = 'drop'),
            by = 'link.citation') %>%
  arrange(desc(n_rows))

out <- MergeDecisions(web_sum, file.path(wd_src, 'foodweb_units_decisions.csv'),
                      key = 'link.citation', subkey = 'foodweb.name')
# per-web facts appended to the citation-level evidence text
web_note <- sprintf('web: %d spp, %d on placeholder values, median log10 ratio %s (n=%d), %s without placeholders (n=%d)',
                    out$n_species, out$n_placeholder,
                    ifelse(is.na(out$median_log10_ratio), 'NA', out$median_log10_ratio), out$n_shared,
                    ifelse(is.na(out$med_ratio_np), 'NA', out$med_ratio_np), out$n_shared_np)
out$evidence <- ifelse(is.na(out$evidence), web_note, paste(out$evidence, web_note, sep = ' | '))

tracked <- out[, c('foodweb.name', 'link.citation', 'n_rows', 'n_species', 'n_shared',
                   'median_log10_ratio', 'iqr_log10_ratio', 'unit_class', 'proposed_action',
                   'factor', 'evidence', 'refs', 'action', 'mass_group', 'log_reason')]
tracked <- tracked[order(tracked$link.citation, tracked$foodweb.name), ]
write.csv(tracked, file.path(wd_src, 'foodweb_units.csv'), row.names = FALSE, na = '')

# taxon-level conversion groups for the convert_dry webs (read by the parser)
convert_cits <- unique(trimws(out$link.citation[out$action == 'convert_dry']))
ExcludeGateway <- function(tab) {
  cit  <- trimws(tab$link.citation)
  lumbricid <- '^(Lumbricus|Aporrectodea|Allolobophora|Octolasion|Dendrobaena|Dendrodrilus|Eiseniella|Eisenia|Satchellius|Murchieona|Lumbricidae)\\b'
  worm <- cit == 'Mulder & Elser (2009)' & (tab$family %in% 'Lumbricidae' | grepl(lumbricid, tab$taxon))
  fish <- cit == 'Layer et al. (2010)' & tab$mass_group == 'fish'
  list(flag = worm | fish,
       note = ifelse(worm, 'not converted: earthworm values already match wet masses (owner decision 2026-10-03)',
              ifelse(fish, 'not converted: trout stay as wet mass (owner decision 2026-10-03)', '')))
}
groups <- BuildGroupsTable(dat, bro, convert_cits, 'link.citation', ExcludeGateway)
write.csv(groups, file.path(wd_src, 'foodweb_units_groups.csv'), row.names = FALSE, na = '')
message(sprintf('  groups table: %d taxa in %d convert_dry citations, %d not converted',
                nrow(groups), length(convert_cits), sum(!groups$convert)))
print(as.data.frame(groups %>% group_by(link.citation, mass_group, whole, convert) %>% summarise(n_taxa = n(), .groups = 'drop')))
write.csv(out,     file.path(wd_tmp, 'foodweb_units_evidence.csv'), row.names = FALSE, na = '')
write.csv(cit_sum, file.path(wd_tmp, 'foodweb_units_citation.csv'), row.names = FALSE, na = '')
write.csv(ws,      file.path(wd_tmp, 'foodweb_units_species.csv'), row.names = FALSE, na = '')

message(sprintf('Wrote %s (%d webs), species detail %d rows', file.path(wd_src, 'foodweb_units.csv'),
                nrow(tracked), nrow(ws)))
print(as.data.frame(cit_sum[, c('link.citation', 'n_webs', 'n_rows', 'n_species', 'n_placeholder', 'n_shared',
                                'median_log10_ratio', 'iqr_log10_ratio', 'n_shared_np', 'med_ratio_np',
                                'n_shared_inv', 'med_ratio_inv', 'n_shared_vert', 'med_ratio_vert')]),
      width = 200)
