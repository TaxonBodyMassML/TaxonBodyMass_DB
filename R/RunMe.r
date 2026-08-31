# TaxonBodyMass_DB — compile body mass from all sources
########################################################
# Set working directory to TaxonBodyMass_DB/R/ before running.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Authentications
#~~~~~~~~~~~~~~~~

# Authenticate with Google Sheets upfront so the browser prompt (if needed)
# fires before any computation rather than mid-run.
if (!googlesheets4::gs4_has_token()){googlesheets4::gs4_auth()}

# NCBI/Entrez API key — raises rate limit from 3 to 10 req/sec during taxonomy
# enrichment. Get a free key at https://www.ncbi.nlm.nih.gov/account/
if (nchar(Sys.getenv('ENTREZ_KEY')) == 0) {
  key <- readline('ENTREZ_KEY not set. Paste your NCBI API key (or press Enter to skip): ')
  if (nchar(trimws(key)) > 0) {
    Sys.setenv(ENTREZ_KEY = trimws(key))
    message('ENTREZ_KEY set for this session. To persist it, add ENTREZ_KEY=',
            trimws(key), ' to ~/.Renviron (one entry per line, blank line at end).')
  } else {
    message('No key provided — NCBI queries will be rate-limited to 3/sec.')
  }
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Control flags
#~~~~~~~~~~~~~~~
# TRUE: re-parse all raw source files to Rdata files
recompile    <- FALSE
# TRUE: re-download from rdataretriever (requires Python + Retriever)
DataRetrieve <- FALSE
# TRUE: ignore enrichment cache and re-enrich all taxa from scratch
fresh_start  <- TRUE
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

library(plyr)
library(dplyr)
library(googlesheets4)
library(stringr)
library(rgbif)
library(taxize)
library(worrms)
library(ritis)
library(httr2)
library(cli)
Sys.setenv(PYTHONWARNINGS = "ignore::urllib3.exceptions.NotOpenSSLWarning")
library(rdataretriever)

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
source(file.path(wd_root, 'R', 'library', 'fix_taxonomy_ranks.r'))
source(file.path(wd_root, 'R', 'library', 'enrich_taxonomy.r'))
source(file.path(wd_root, 'R', 'library', 'check_enriched.r'))
source(file.path(wd_root, 'R', 'library', 'filter_autotrophs.r'))

dir.create(file.path(wd_root, 'tmp'),     showWarnings = FALSE)
dir.create(file.path(wd_root, 'reports'), showWarnings = FALSE)

##########################################################################
# DataRetriever sources
# http://retriever.readthedocs.io/en/latest/index.html
##########################################################################
if (DataRetrieve){
  source(file.path(wd_root, 'R', 'library', 'data_retrieve.r'))
}

##########################################################################
# 1. Re-generate per-source Rdata files (optional)
##########################################################################
if (recompile) {
  scripts <- list.files(wd_db, pattern = '^BodyMass_.*\\.[Rr]$',
                        recursive = TRUE, full.names = TRUE)
  n        <- length(scripts)
  null_con  <- file(nullfile(), open = 'w')
  out_depth <- sink.number()
  msg_depth <- sink.number('message')
  for (i in seq_along(scripts)) {
    cat(sprintf('  [%d/%d] %s\n', i, n, basename(dirname(scripts[i]))),
        file = stderr())
    wd_source <- dirname(scripts[i])
    sink(nullfile()); sink(null_con, type = 'message')
    tryCatch(source(scripts[i]),
             error   = function(e) cat(sprintf('    ERROR: %s\n', conditionMessage(e)), file = stderr()),
             finally = {
               while (sink.number('message') > msg_depth) sink(type = 'message')
               while (sink.number()           > out_depth) sink()
             })
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
source_list <- lapply(source_list, FixTaxonomyRanks)


##########################################################################
# 3. Bind all per-source rows (no cross-source averaging yet)
##########################################################################
tax_cols <- c('kingdom', 'phylum', 'class', 'order', 'family')
source_list <- lapply(source_list, function(df) {
  for (col in tax_cols)
    if (!col %in% names(df)) df[[col]] <- NA_character_
  df
})

adat_raw <- bind_rows(source_list)

# Separate genus-only entries: included in genus averages but excluded from
# species export.
genus_only <- adat_raw[!grepl('_', adat_raw$taxon), ]
adat_raw   <- adat_raw[ grepl('_', adat_raw$taxon), ]


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
for (col in tax_cols)
  if (!col %in% names(ddat)) ddat[[col]] <- NA_character_

sel  <- adat_raw$taxon %!in% ddat$taxon
adat <- bind_rows(ddat[, c('taxon', 'mass_g', 'source_mass', 'n',
                           'kingdom', 'phylum', 'class', 'order', 'family')],
                  adat_raw[sel, ])


##########################################################################
# 5. Enrich unique taxa, join back, filter autotrophs, two-pass averaging
##########################################################################

# Enrich each unique taxon name exactly once
unique_taxa <- adat %>%
  group_by(taxon) %>%
  summarise(
    kingdom = first(na.omit(kingdom)),
    phylum  = first(na.omit(phylum)),
    class   = first(na.omit(class)),
    order   = first(na.omit(order)),
    family  = first(na.omit(family)),
    .groups = 'drop'
  ) %>% as.data.frame()
cache_path <- file.path(wd_root, 'sources', 'enrich_cache.Rdata')

if (!fresh_start && file.exists(cache_path)) {
  load(cache_path)                                            # loads `enrich_cache`
  new_taxa    <- unique_taxa[unique_taxa$taxon %!in% enrich_cache$taxon, ]
  cached_taxa <- unique_taxa[unique_taxa$taxon %in%  enrich_cache$taxon, ]
  cli::cli_inform(c(
    'i' = 'Enrichment cache: {nrow(cached_taxa)} cached, {nrow(new_taxa)} new taxa to enrich.'
  ))
  if (nrow(new_taxa) > 0) {
    new_enriched <- EnrichTaxonomy(new_taxa)
    enrich_cache <- bind_rows(enrich_cache, new_enriched)
  }
} else {
  if (fresh_start)
    cli::cli_inform(c('i' = 'fresh_start = TRUE: skipping cache, re-enriching all taxa.'))
  enrich_cache <- EnrichTaxonomy(unique_taxa)                 # This step will take a while
}

save(enrich_cache, file = cache_path)

# Backfill higher ranks for cached taxa enriched before Stage 7 existed.
# Self-extinguishing: once the cache is updated the condition is false on
# all subsequent runs.
rank_fill_cols <- c('kingdom', 'phylum', 'class', 'order', 'family')
cache_needs_backfill <- !is.na(enrich_cache$species) &
  rowSums(is.na(enrich_cache[, rank_fill_cols, drop = FALSE])) > 0
if (any(cache_needs_backfill)) {
  cli::cli_inform(c('i' = '{sum(cache_needs_backfill)} cached taxa need rank backfill; running now...'))
  enrich_cache[cache_needs_backfill, ] <-
    BackfillRanks(enrich_cache[cache_needs_backfill, ])
  save(enrich_cache, file = cache_path)
}

# Normalize rank-level synonyms and apply manual fills before inference.
# Actinopteri (GBIF backbone name) → Actinopterygii unblocks 7 fish orders;
# other fixes handle reptile class synonyms, cross-kingdom noise, and fringe
# protist/flatworm/nematode taxa that all APIs leave incomplete.
enrich_cache <- FixTaxonomyRanks(enrich_cache)
save(enrich_cache, file = cache_path)

# Infer missing ranks from unambiguous within-cache mappings.
# GBIF's backbone omits CLASS for many fish; order→class inference fills the gap
# reliably because fish orders don't cross class boundaries.
# Only unambiguous (one-to-one) mappings are applied.
infer_map <- function(dat, from_col, to_col) {
  sub <- dat[!is.na(dat[[from_col]]) & !is.na(dat[[to_col]]), ]
  if (nrow(sub) == 0) return(character(0))
  m <- tapply(sub[[to_col]], sub[[from_col]], function(x) {
    u <- unique(x); if (length(u) == 1L) u else NA_character_
  })
  m[!is.na(m)]
}

cache_updated <- FALSE
for (pairs in list(c('order', 'class'), c('family', 'class'),
                   c('family', 'order'), c('order', 'kingdom'),
                   c('family', 'kingdom'), c('order', 'phylum'),
                   c('family', 'phylum'))) {
  from_col <- pairs[1]; to_col <- pairs[2]
  lut <- infer_map(enrich_cache, from_col, to_col)
  if (length(lut) == 0) next
  fill_idx <- which(
    !is.na(enrich_cache$species) &
    is.na(enrich_cache[[to_col]]) &
    !is.na(enrich_cache[[from_col]]) &
    enrich_cache[[from_col]] %in% names(lut)
  )
  if (length(fill_idx) > 0) {
    enrich_cache[[to_col]][fill_idx] <- lut[enrich_cache[[from_col]][fill_idx]]
    cache_updated <- TRUE
    cli::cli_inform(c('i' = 'Rank inference: filled {length(fill_idx)} missing `{to_col}` from `{from_col}`.'))
  }
}
if (cache_updated) save(enrich_cache, file = cache_path)

unique_taxa <- enrich_cache[enrich_cache$taxon %in% unique_taxa$taxon, ]

# Join enrichment results back to all per-source rows
enrich_cols  <- c('taxon', 'species', 'genus', 'kingdom', 'phylum', 'class', 'order',
                  'family', 'taxon_provided', 'taxonomy_source', 'gbif_confidence',
                  'gbif_status', 'gbif_family', 'gbif_order', 'species_changed',
                  'gbif_usageKey')
adat_nm       <- adat[, setdiff(names(adat), c('kingdom', 'phylum', 'class', 'order', 'family'))]
adat_enriched <- merge(adat_nm, unique_taxa[, enrich_cols], by = 'taxon', all.x = TRUE)
adat_enriched <- FilterAutotrophs(adat_enriched)

# Pass 1: within-source geometric mean per accepted species
within_source <- adat_enriched %>%
  filter(!is.na(species)) %>%
  group_by(genus, species, source_mass) %>%
  summarise(
    taxon           = first(taxon),
    taxon_provided  = paste(unique(taxon_provided), collapse = '; '),
    mass_g          = 10^mean(log10(mass_g), na.rm = TRUE), # geometric mean
    n               = n(),
    kingdom         = first(na.omit(kingdom)),
    phylum          = first(na.omit(phylum)),
    class           = first(na.omit(class)),
    order           = first(na.omit(c(gbif_order, order))),
    family          = first(na.omit(c(gbif_family, family))),
    taxonomy_source = first(na.omit(taxonomy_source)),
    gbif_confidence = suppressWarnings(min(gbif_confidence, na.rm = TRUE)),
    gbif_status     = first(na.omit(gbif_status)),
    gbif_family     = first(na.omit(gbif_family)),
    gbif_order      = first(na.omit(gbif_order)),
    species_changed = any(species_changed, na.rm = TRUE),
    .groups         = 'drop'
  )
within_source$gbif_confidence[is.infinite(within_source$gbif_confidence)] <- NA_real_

# Pass 2: across-source arithmetic mean per accepted species
enriched <- within_source %>%
  group_by(genus, species) %>%
  summarise(
    taxon           = first(taxon),
    taxon_provided  = paste(unique(unlist(strsplit(taxon_provided, '; '))), collapse = '; '),
    log10_range     = if (n() > 1) log10(max(mass_g) / min(mass_g)) else 0,
    mass_g          = mean(mass_g, na.rm = TRUE), # arithmetic mean
    source_mass     = paste(unique(source_mass), collapse = '; '),
    n               = sum(n, na.rm = TRUE),
    kingdom         = first(na.omit(kingdom)),
    phylum          = first(na.omit(phylum)),
    class           = first(na.omit(class)),
    order           = first(na.omit(order)),
    family          = first(na.omit(family)),
    taxonomy_source = paste(unique(taxonomy_source), collapse = '; '),
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

# Primary source citations from per-source Citation.bib files.
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

