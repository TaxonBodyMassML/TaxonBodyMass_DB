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

raw_file <- Sys.getenv('BROSE2005_RAW', path.expand('~/.retriever/raw_data/predator-prey-body-ratio/5595857'))
if (!file.exists(raw_file)) stop('raw retriever file not found: ', raw_file)
raw <- read.delim(raw_file, fileEncoding = 'latin1', check.names = FALSE, stringsAsFactors = FALSE,
                  na.strings = c('-999', 'NA', ''))
names(raw) <- trimws(names(raw))
# Warren (1989) rows carry page-range typos in the reference; one study
raw$study <- raw$`Link reference`
raw$study[grepl('^Warren, P\\. H\\. 1989', raw$study)] <- 'Warren (1989)'

Stack <- function(side, stage_col) {
  data.frame(study       = raw$study,
             size_ref    = raw$`Body size reference`,
             location    = raw$`Geographic location`,
             habitat     = raw$`General habitat`,
             method      = raw$`Body size methodology`,
             notes       = raw$Notes,
             role        = side,
             taxon       = raw[[paste('Taxonomy', side)]],
             lifestage   = raw[[stage_col]],
             metab       = raw[[paste('Metabolic category', side)]],
             mass_g      = suppressWarnings(as.numeric(raw[[paste('Mean mass (g)', side)]])),
             stringsAsFactors = FALSE)
}
dat <- rbind(Stack('consumer', 'Lifestage consumer'), Stack('resource', 'Lifestage - resource'))
dat <- dat[!is.na(dat$taxon) & dat$taxon != '' & !is.na(dat$mass_g) & dat$mass_g > 0, ]
dat$n <- 1
dat$source_mass <- 'Brose_2005'
message(sprintf('  %d stacked rows with a positive mass (no life-stage filter in data_retrieve.r)', nrow(dat)))
stage_tab <- dat %>% mutate(stage = tolower(trimws(lifestage))) %>% count(stage, sort = TRUE)

# every study of the file, including those whose rows carry no taxonomy or no
# mass and therefore never reach the pipeline (Yodzis 1998, Warren 1989, ...)
raw_study <- raw %>% group_by(study) %>%
  summarise(size_ref = paste(unique(`Body size reference`), collapse = ' | '),
            location = first(`Geographic location`),
            habitat  = paste(unique(`General habitat`), collapse = '|'),
            method   = paste(unique(`Body size methodology`), collapse = ' | '),
            notes    = paste(head(unique(na.omit(Notes)), 2), collapse = ' | '),
            n_links  = n(), .groups = 'drop') %>%
  left_join(dat %>% group_by(study) %>%
              summarise(n_rows_parser = n(), n_names_parser = n_distinct(taxon),
                        frac_nonadult = round(mean(!is.na(lifestage) & !grepl('^adult', lifestage, ignore.case = TRUE)), 2),
                        .groups = 'drop'), by = 'study')
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
                   'factor', 'evidence', 'refs')]
write.csv(tracked, file.path(wd_src, 'brose2005_units.csv'), row.names = FALSE, na = '')
write.csv(out, file.path(wd_tmp, 'brose2005_units_evidence.csv'), row.names = FALSE, na = '')
write.csv(ws,  file.path(wd_tmp, 'brose2005_units_species.csv'), row.names = FALSE, na = '')
message('Life stages of the stacked rows:'); print(as.data.frame(stage_tab))
print(as.data.frame(out[, c('study', 'n_rows', 'n_species', 'n_placeholder', 'n_shared', 'median_log10_ratio',
                            'iqr_log10_ratio', 'med_ratio_np', 'n_shared_inv', 'med_ratio_inv',
                            'n_shared_vert', 'med_ratio_vert', 'frac_nonadult')]), width = 200)
