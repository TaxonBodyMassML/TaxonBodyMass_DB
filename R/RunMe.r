# TaxonBodyMass_DB — compile body mass from all sources
########################################################
# Set working directory to TaxonBodyMass_DB/R/ before running.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
library(plyr)
library(dplyr)
library(googlesheets4)
library(stringr)

wd_root  <- dirname(getwd())  # TaxonBodyMass_DB/
wd_db    <- file.path(wd_root, 'sources', 'databases')
wd_rdata <- file.path(wd_root, 'sources', 'Rdata')
wd_out   <- file.path(wd_root)
wd_bib   <- file.path(wd_root, 'bib')

source(file.path(wd_root, 'R', 'library', 'helpers.r'))
source(file.path(wd_root, 'R', 'library', 'fix_formatting.r'))
source(file.path(wd_root, 'R', 'library', 'fix_misspellings.r'))
source(file.path(wd_root, 'R', 'library', 'fix_nontaxa.r'))
source(file.path(wd_root, 'R', 'library', 'fix_outliers.r'))
source(file.path(wd_root, 'R', 'library', 'fix_outliers_multisource.r'))
source(file.path(wd_root, 'R', 'library', 'enrich_taxonomy.r'))
source(file.path(wd_root, 'R', 'library', 'check_enriched.r'))
source(file.path(wd_root, 'R', 'library', 'filter_autotrophs.r'))

dir.create(file.path(wd_root, 'tmp'),     showWarnings = FALSE)
dir.create(file.path(wd_root, 'reports'), showWarnings = FALSE)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Control flags
#~~~~~~~~~~~~~~~
# TRUE: re-parse all raw source files to Rdata files
recompile    <- FALSE
# TRUE: re-download from rdataretriever (requires Python + Retriever)
DataRetrieve <- FALSE
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


##########################################################################
# DataRetriever sources (currently disabled; requires external tools)
# http://retriever.readthedocs.io/en/latest/index.html
##########################################################################
if (DataRetrieve) {
  wd_drdata <- file.path(wd_root, 'sources', 'databases', 'DataRetriever')
  dir.create(wd_drdata, showWarnings = FALSE)

  rdataretriever::install_csv('mammal-life-hist', data_dir = wd_drdata)
  mlh <- read.csv(file.path(wd_drdata, 'mammal_life_hist_species.csv'))
  mlh <- mlh[, 1:5]
  mlh$taxon <- paste(mlh$genus, mlh$species)
  mlh <- mlh[, c('taxon', 'mass_g')]
  mlh <- mlh[which(!is.na(mlh$mass_g) & mlh$mass_g > 0), ]
  mlh <- ddply(mlh, .(taxon), summarise,
               mass_g = gmean(mass_g), n = length(mass_g))
  mlh$source_mass <- 'rdataretriever-mammal-life-hist'

  rdataretriever::install_csv('bird_size', data_dir = wd_drdata)
  bir <- read.csv(file.path(wd_drdata, 'bird_size_species.csv'))
  bir <- bir[, c('species_name', 'm_mass')]
  colnames(bir) <- c('taxon', 'mass_g')
  bir <- bir[which(!is.na(bir$mass_g) & bir$mass_g > 0), ]
  bir <- ddply(bir, .(taxon), summarise,
               mass_g = gmean(mass_g), n = length(mass_g))
  bir$source_mass <- 'rdataretriever-bird-size'

  rdataretriever::install_csv('predator-prey-body-ratio', data_dir = wd_drdata)
  ppb <- read.csv(
    file.path(wd_drdata, 'predator_prey_body_ratio_bodysizes.csv'))
  ppb <- ppb[which(ppb$taxonomy_consumer != '' & ppb$taxonomy_resource != ''), ]
  ppb1 <- ppb[, c('taxonomy_consumer', 'mean_mass_g_consumer')]
  ppb2 <- ppb[, c('taxonomy_resource', 'mean_mass_g_resource')]
  colnames(ppb1) <- colnames(ppb2) <- c('taxon', 'mass_g')
  ppb <- rbind(ppb1, ppb2)
  ppb <- ppb[which(!is.na(ppb$mass_g) & ppb$mass_g > 0), ]
  ppb <- ddply(ppb, .(taxon), summarise,
               mass_g = gmean(mass_g), n = length(mass_g))
  ppb$source_mass <- 'rdataretriever-predator-prey-body-ratio'

  rdataretriever::install_csv('pantheria', data_dir = wd_drdata)
  pan <- read.csv(file.path(wd_drdata, 'pantheria_species.csv'))
  pan <- pan[, c('msw05_binomial', 'adultbodymass_g')]
  colnames(pan) <- c('taxon', 'mass_g')
  pan <- pan[which(!is.na(pan$mass_g) & pan$mass_g > 0), ]
  pan <- ddply(pan, .(taxon), summarise,
               mass_g = gmean(mass_g), n = length(mass_g))
  pan$source_mass <- 'rdataretriever-pantheria'

  load(file.path(wd_rdata, 'BodyMass_amniote-life-hist.Rdata'))  # amn

  rdataretriever::install_csv('socean-diet-data', data_dir = wd_drdata)
  sdd <- read.csv(file.path(wd_drdata, 'socean_diet_data_diet.csv'))
  sdd1 <- sdd[, c('predator_name', 'predator_mass_mean')]
  sdd2 <- sdd[, c('prey_name',     'prey_mass_mean')]
  colnames(sdd1) <- colnames(sdd2) <- c('taxon', 'mass_g')
  sdd <- rbind(sdd1, sdd2)
  sdd <- sdd[which(!is.na(sdd$mass_g) & sdd$mass_g > 0), ]
  sdd <- ddply(sdd, .(taxon), summarise,
               mass_g = gmean(mass_g), n = length(mass_g))
  sdd$source_mass <- 'rdataretriever-socean-diet-data'

  load(file.path(wd_rdata, 'BodyMass_vertnet-amphibians.Rdata'))  # vra
  load(file.path(wd_rdata, 'BodyMass_vertnet-reptiles.Rdata'))    # vrr

  adat <- rbind(mlh, bir, ppb, pan, amn, sdd, vra, vrr)
  adat <- FixFormatting(adat)
  adat <- FixMisspellings(adat)
  adat <- RemoveNonTaxa(adat)
  adat <- adat[which(!is.na(adat$mass_g) & adat$mass_g > 0), ]
  adat <- ddply(adat, .(taxon), summarise,
                mass_g      = gmean(mass_g),
                n           = sum(n),
                source_mass = paste(unique(source_mass), collapse = '_'))
  DR <- adat[adat$taxon != 0, ]
  save(DR, file = file.path(wd_rdata, 'BodyMass_DataRetrieverAll.Rdata'))
}


##########################################################################
# 1. Re-generate per-source Rdata files (optional)
##########################################################################
if (recompile) {
  scripts <- list.files(wd_db, pattern = '^BodyMass_.*\\.[Rr]$',
                        recursive = TRUE, full.names = TRUE)
  n        <- length(scripts)
  null_con <- file(nullfile(), open = 'w')
  for (i in seq_along(scripts)) {
    cat(sprintf('  [%d/%d] %s\n', i, n, basename(dirname(scripts[i]))),
        file = stderr())
    wd_source <- dirname(scripts[i])
    sink(nullfile()); sink(null_con, type = 'message')
    tryCatch(source(scripts[i]), finally = { sink(type = 'message'); sink() })
  }
  close(null_con)
}


##########################################################################
# 2. Load all per-source Rdata files
##########################################################################
rdata_files <- list.files(wd_rdata, pattern = '\\.Rdata$', full.names = TRUE)

source_list <- lapply(rdata_files, function(f) {
  e <- new.env()
  load(f, envir = e)
  get(ls(e)[1], envir = e)
})


##########################################################################
# 2b. Apply taxon name corrections prior to merging
##########################################################################
# normalise encoding/spacing, strip non-alpha, capitalise, truncate to binomial
source_list <- lapply(source_list, FixFormatting)
# rename misspelled taxa (depends on FixFormatting)
source_list <- lapply(source_list, FixMisspellings)
# drop non-species and (some) non-autotroph entries
source_list <- lapply(source_list, RemoveNonTaxa)

# Apply audit-flagged mass corrections
# (Additional single-source corrections are applied in the lab Google Sheet override.)
source_list <- lapply(source_list, FixOutliersMultiSource)
source_list <- lapply(source_list, FixOutliers)


##########################################################################
# 3. Merge/Average across sources
##########################################################################
tax_cols <- c('kingdom', 'phylum', 'class', 'order', 'family')
source_list <- lapply(source_list, function(df) {
  for (col in tax_cols)
    if (!col %in% names(df)) df[[col]] <- NA_character_
  df
})

compiled <- bind_rows(source_list) %>%
  group_by(taxon) %>%
  summarise(mass_g      = 10^mean(log10(mass_g), na.rm = TRUE),
            n           = sum(n, na.rm = TRUE),
            source_mass = paste(unique(source_mass), collapse = '; '),
            kingdom     = first(na.omit(kingdom)),
            phylum      = first(na.omit(phylum)),
            class       = first(na.omit(class)),
            order       = first(na.omit(order)),
            family      = first(na.omit(family)),
            .groups     = 'drop')

# Separate genus-only entries: included in genus averages but excluded from
# species export.
compiled   <- as.data.frame(compiled)
genus_only <- compiled[!grepl('_', compiled$taxon), ]
compiled   <- compiled[grepl( '_', compiled$taxon), ]


##########################################################################
# 4. Lab Google Sheet override (lab-curated values take priority)
##########################################################################
bm_sheet_url <- paste0(
  'https://docs.google.com/spreadsheets/d/',
  '1_TzVFXjcUrDBGHbpRuLh3NwYIF1I8AucsJh8heIFulY/edit?usp=sharing'
)
ddat <- read_sheet(
  bm_sheet_url,
  sheet     = 'BM_data',
  col_types = 'ccncnnn'
)
ddat <- ddat[which(!is.na(ddat$mass_g)), 1:4]
ddat$n <- 1

sel      <- compiled$taxon %!in% ddat$taxon
compiled <- compiled[sel, ]

adat <- merge(ddat[, c('taxon', 'mass_g', 'source_mass')], compiled, all = TRUE)


##########################################################################
# 5. Taxonomy enrichment, autotroph filter, deduplication, and QC
##########################################################################
adat <- EnrichTaxonomy(adat)
adat <- FilterAutotrophs(adat)

enriched <- adat %>%
  filter(!is.na(species)) %>%
  group_by(kingdom, phylum, class, order, family, genus, species) %>%
  summarise(
    taxon           = first(taxon),
    taxon_provided  = paste(unique(taxon_provided), collapse = '; '),
    log10_range     = if (n() > 1) log10(max(mass_g) / min(mass_g)) else 0,
    mass_g          = 10^mean(log10(mass_g)),
    source_mass     = paste(unique(source_mass), collapse = '; '),
    n               = sum(n, na.rm = TRUE) + n(),
    taxonomy_source = paste(unique(taxonomy_source[!is.na(taxonomy_source)]), collapse = '; '),
    gbif_confidence = suppressWarnings(min(gbif_confidence, na.rm = TRUE)),
    gbif_status     = first(na.omit(gbif_status)),
    gbif_family     = first(na.omit(gbif_family)),
    gbif_order      = first(na.omit(gbif_order)),
    species_changed = any(species_changed, na.rm = TRUE),
    .groups         = 'drop'
  )
enriched$gbif_confidence[is.infinite(enriched$gbif_confidence)] <- NA_real_
enriched$mass_g <- signif(enriched$mass_g, digits = 4)

check_enriched(enriched)


##########################################################################
# 6. Genus-level averages
##########################################################################
gdat <- bind_rows(enriched, genus_only)
gdat$taxon <- sub('\\_.*', '', gdat$taxon)
gdat <- gdat[nchar(gdat$taxon) > 0, ]
gdat <- ddply(gdat, .(taxon), summarise,
              mass_g = mean(mass_g),   # arithmetic mean
              n      = sum(n, na.rm = TRUE),
              source_mass = paste(source_mass, collapse = '-'))
gdat <- gdat[, c('taxon', 'mass_g', 'source_mass', 'n')]



##########################################################################
# 7. Write outputs
##########################################################################
gdat$mass_g <- signif(gdat$mass_g, digits = 4)

write.csv(enriched, file = file.path(wd_root, 'TaxonBodyMass.csv'),
          row.names = FALSE)
write.csv(gdat, file = file.path(wd_root, 'TaxonBodyMass_GenusLevel.csv'),
          row.names = FALSE)


##########################################################################
# 8. Write citations CSV (committed to output/)
#    All bib entries are included; Google Sheet BM_citations provides the
#    CiteID (source_mass label) → Bibcite (bib key) mapping. Bib entries
#    absent from the Google Sheet are retained with CiteID = NA and a
#    warning is issued.
##########################################################################
bib_lines <- readLines(file.path(wd_root, 'Bib', 'TaxonBodyMass_Citations.bib'))
bib_keys  <- sub('^@\\w+\\{([^,]+),.*', '\\1',
                 bib_lines[grepl('^@', bib_lines)], perl = TRUE)

gmap <- read_sheet(
  bm_sheet_url,
  sheet     = 'BM_citations',
  col_types = 'cc-'
)

gmap$Bibcite <- gsub('.*\\{(.+)\\}', '\\1', gmap$Bibcite, perl = TRUE)

dcite <- merge(data.frame(Bibcite = bib_keys, stringsAsFactors = FALSE),
               gmap, by = 'Bibcite', all.x = TRUE)

# Auto-discover primary source citations from per-source Citation.bib files.
# Keys found there are intentionally unmapped and suppressed from the warning.
cite_bibs   <- list.files(wd_db, pattern = '^Citation\\.bib$',
                          recursive = TRUE, full.names = TRUE)
source_keys <- unlist(lapply(cite_bibs, function(f) {
  lines <- readLines(f)
  sub('^@\\w+\\{([^,]+),.*', '\\1', lines[grepl('^@', lines)], perl = TRUE)
}))

unmapped <- dcite$Bibcite[is.na(dcite$CiteID) & !dcite$Bibcite %in% source_keys]
if (length(unmapped) > 0) {
  warning(
    length(unmapped),
    ' bib entries have no CiteID mapping and no Citation.bib:\n',
    paste(unmapped, collapse = '\n'), immediate. = TRUE)
}

dcite <- dcite[order(dcite$CiteID, dcite$Bibcite), ]
write.csv(dcite, file = file.path(wd_bib, 'TaxonBodyMass_CitationCiteIDs.csv'),
          row.names = FALSE)


##########################################################################
##########################################################################
##########################################################################
