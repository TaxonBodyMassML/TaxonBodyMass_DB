# Issue #14 (Phase A): per-study evidence on the unit of the Brose et al. (2005)
# body masses (Data Retriever dataset predator-prey-body-ratio, label
# 'Brose_2005'), using R/library/unit_audit.r.
#
# R/library/data_retrieve.r keeps every consumer and resource row with a
# positive mean mass (no life-stage filter) and averages per taxon. This script
# reads the raw Ecological Archives file that the retriever downloaded
# (~/.retriever/raw_data/predator-prey-body-ratio/5595857 = bodysizes_2008.txt),
# keeps the same rows, resolves species as RunMe.r does and compares each study's
# ('Link reference') within-study geometric means with the other sources.
#
# Run from the repository root:
#   Rscript sources/databases/DataRetriever/brose2005_units_analysis.r
# Reads  brose2005_units_decisions.csv (hand-made unit class / action per study)
# Writes brose2005_units.csv (one row per study; tracked)
#        tmp/brose2005_units_species.csv (study x species detail)

wd_root  <- normalizePath(if (file.exists('R/RunMe.r')) '.' else '..')
source(file.path(wd_root, 'R', 'library', 'unit_audit.r'))
UnitAuditInit(wd_root)
wd_rdata <- file.path(wd_root, 'sources', 'Rdata')
wd_src   <- file.path(wd_root, 'sources', 'databases', 'DataRetriever')
wd_tmp   <- file.path(wd_root, 'tmp')
dir.create(wd_tmp, showWarnings = FALSE)

# The retriever's own csv of the table (what rdataretriever::fetch() reads in
# data_retrieve.r): produced into tmp/retriever/ by the venv python when absent.
csv_file <- Sys.getenv('BROSE2005_CSV', file.path(wd_tmp, 'retriever', 'predator_prey_body_ratio_bodysizes.csv'))
if (!file.exists(csv_file)) {
  py <- path.expand('~/.local/share/r-rdataretriever/bin/python')
  if (!file.exists(py)) stop('retriever venv missing (README, Prerequisites); or set BROSE2005_CSV to the retriever csv')
  dir.create(dirname(csv_file), showWarnings = FALSE, recursive = TRUE)
  system2(py, c('-c', shQuote(sprintf(
    "import retriever; retriever.install_csv('predator-prey-body-ratio', table_name='{db}_{table}.csv', data_dir='%s')",
    dirname(csv_file)))), stdout = FALSE, stderr = FALSE)
}
ppb <- utils::read.csv(csv_file)                     # as rdataretriever's fetch() does
ppb$link_reference <- trimws(as.character(ppb$link_reference))
ppb$link_reference[grepl('^Warren, P\\. H\\. 1989', ppb$link_reference)] <- 'Warren (1989)'

dat <- StackBrose2005(ppb, extra = c('body_size_reference', 'geographic_location', 'general_habitat',
                                     'body_size_methodology', 'notes'))
names(dat)[names(dat) %in% c('body_size_reference', 'geographic_location', 'general_habitat', 'body_size_methodology')] <-
  c('size_ref', 'location', 'habitat', 'method')
dat$taxon_raw <- dat$taxon
message(sprintf('  %d stacked rows after the life-stage filter (no filter in data_retrieve.r before #14)', nrow(dat)))
NonAdult <- function(stage) !AdultOrUnspecified(stage)
stage_tab <- data.frame(stage = c(ppb$lifestage_consumer, ppb$lifestage_resource)) %>% count(stage, sort = TRUE)

# every study of the file, including those whose rows carry no taxonomy or no
# mass and therefore never reach the pipeline (Yodzis 1998, Warren 1989, ...)
raw_study <- ppb %>% group_by(study = link_reference) %>%
  summarise(size_ref = paste(unique(body_size_reference), collapse = ' | '),
            location = first(geographic_location),
            habitat  = paste(unique(general_habitat), collapse = '|'),
            method   = paste(unique(body_size_methodology), collapse = ' | '),
            notes    = paste(head(unique(notes[!notes %in% c('-999', '')]), 2), collapse = ' | '),
            n_links  = n(),
            frac_nonadult = round(mean(NonAdult(lifestage_consumer) | NonAdult(lifestage_resource)), 2),
            .groups = 'drop') %>%
  left_join(dat %>% group_by(study) %>%
              summarise(n_rows_parser = n(), n_names_parser = n_distinct(taxon), .groups = 'drop'), by = 'study')
raw_study$n_rows_parser[is.na(raw_study$n_rows_parser)] <- 0L

bro <- CleanResolve(dat)
message(sprintf('  %d rows resolve to %d accepted species', nrow(bro), n_distinct(bro$species)))

oth_p1 <- LoadOtherPass1(wd_rdata, exclude_files = 'BodyMass_Brose_etal_2018.Rdata',
                         exclude_labels = c('Brose_etal_2018', 'Brose_2005'))
oth_all <- OtherSummary(oth_p1)

ws <- bro %>% group_by(study, species) %>%
  summarise(web_lg = mean(log10(mass_g)), n_rows = n(), n_values = n_distinct(signif(mass_g, 6)),
            metab = ModeOf(metab), size_method = ModeOf(method), phylum = first(phylum), class = first(class),
            .groups = 'drop')
ws$grp <- MetabGroup(tolower(ws$metab))
ph <- PlaceholderValues(ws, 'study', min_species = 5)
ws$placeholder <- paste(ws$study, signif(10^ws$web_lg, 4)) %in% paste(ph$study, ph$mass)
ws <- left_join(ws, oth_all, by = 'species')
ws$ratio <- ws$web_lg - ws$other_lg
ws <- ws[order(ws$study, ws$ratio), ]

study_sum <- ws %>% group_by(study) %>% group_modify(~RatioSummary(.x)) %>% ungroup()
study_sum <- raw_study %>% left_join(study_sum, by = 'study')
for (col in c('n_rows', 'n_species', 'n_shared', 'n_placeholder'))
  study_sum[[col]][is.na(study_sum[[col]])] <- 0L
study_sum <- study_sum[order(-study_sum$n_rows_parser), ]

out <- MergeDecisions(study_sum, file.path(wd_src, 'brose2005_units_decisions.csv'), key = 'study')
tracked <- out[, c('study', 'size_ref', 'location', 'method', 'n_rows', 'n_species', 'n_shared',
                   'median_log10_ratio', 'iqr_log10_ratio', 'unit_class', 'proposed_action',
                   'factor', 'evidence', 'refs', 'action', 'mass_group', 'log_reason')]
write.csv(tracked, file.path(wd_src, 'brose2005_units.csv'), row.names = FALSE, na = '')
convert_studies <- unique(out$study[out$action == 'convert_dry'])
ExcludeBrose2005 <- function(tab) {           # Cattin: vertebrate values are the GATEWAy fresh masses
  vert <- trimws(tab$study) == 'Cattin Blandenier (2004)' & tab$mass_group %in% c('fish', 'vertebrate')
  list(flag = vert, note = ifelse(vert, 'not converted: vertebrate values identical to the GATEWAy fresh masses', ''))
}
groups <- BuildGroupsTable(dat, bro, convert_studies, 'study', ExcludeBrose2005)
write.csv(groups, file.path(wd_src, 'brose2005_units_groups.csv'), row.names = FALSE, na = '')
message(sprintf('  groups table: %d taxa in %d convert_dry studies', nrow(groups), length(convert_studies)))
print(as.data.frame(groups %>% group_by(study, mass_group, whole, convert) %>% summarise(n_taxa = n(), .groups = 'drop')))
write.csv(out, file.path(wd_tmp, 'brose2005_units_evidence.csv'), row.names = FALSE, na = '')
write.csv(ws,  file.path(wd_tmp, 'brose2005_units_species.csv'), row.names = FALSE, na = '')
message('Life stages in the file (consumer and resource columns):'); print(as.data.frame(stage_tab))
print(as.data.frame(out[, c('study', 'n_rows', 'n_species', 'n_placeholder', 'n_shared', 'median_log10_ratio',
                            'iqr_log10_ratio', 'med_ratio_np', 'n_shared_inv', 'med_ratio_inv',
                            'n_shared_vert', 'med_ratio_vert', 'frac_nonadult')]), width = 200)
