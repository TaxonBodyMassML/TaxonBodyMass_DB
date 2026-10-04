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
recompile    <- TRUE
# TRUE: re-download from rdataretriever (requires Python + Retriever)
DataRetrieve <- TRUE
# TRUE: re-download VertNet Sept2016 from CyVerse and extract body mass (~3 GB)
DataVertNet  <- TRUE
# TRUE: re-download FishBase and SeaLifeBase via rfishbase
DataFishbase <- TRUE
# TRUE: ignore enrichment cache and re-enrich all taxa from scratch (hours of
# API calls). FALSE: reuse sources/enrich_cache.Rdata and enrich only new taxa.
fresh_start  <- FALSE
# Remove taxa occurring in multiple sources whose sources differ by more than
# and order of magnitude in the value they ascribe to the taxa
RemoveHighMaxMinRatio <- TRUE
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Sys.setenv(PYTHONWARNINGS = "ignore::urllib3.exceptions.NotOpenSSLWarning")
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
library(rdataretriever)
library(rfishbase)

wd_root  <- dirname(getwd())  # TaxonBodyMass_DB/
wd_db    <- file.path(wd_root, 'sources', 'databases')
wd_rdata <- file.path(wd_root, 'sources', 'Rdata')
wd_out   <- file.path(wd_root)
wd_bib   <- file.path(wd_root, 'bib')

source(file.path(wd_root, 'R', 'library', 'helpers.r'))
source(file.path(wd_root, 'R', 'library', 'mass_conversion.r'))
source(file.path(wd_root, 'R', 'library', 'foodweb_units.r'))
source(file.path(wd_root, 'R', 'library', 'fix_formatting.r'))
source(file.path(wd_root, 'R', 'library', 'fix_misspellings.r'))
source(file.path(wd_root, 'R', 'library', 'fix_nontaxa.r'))
source(file.path(wd_root, 'R', 'library', 'fix_taxonomy_ranks.r'))
source(file.path(wd_root, 'R', 'library', 'enrich_taxonomy.r'))
source(file.path(wd_root, 'R', 'library', 'check_enriched.r'))
source(file.path(wd_root, 'R', 'library', 'remove_high_range.r'))
source(file.path(wd_root, 'R', 'library', 'filter_autotrophs.r'))
source(file.path(wd_root, 'R', 'library', 'filter_extinct.r'))
source(file.path(wd_root, 'R', 'library', 'check_source_docs.r'))
source(file.path(wd_root, 'R', 'library', 'check_cache.r'))
source(file.path(wd_root, 'R', 'library', 'check_taxon_names.r'))
source(file.path(wd_root, 'R', 'library', 'dedupe_sources.r'))
source(file.path(wd_root, 'R', 'library', 'enrich_genus.r'))

# The raw-name vocabulary FixFormatting() applies (#38): tracked in audit/,
# validated on loading (columns, classes, actions, regexes).
raw_name_patterns <- LoadRawNamePatterns(file.path(wd_root, 'audit', 'raw_name_patterns.csv'))

dir.create(file.path(wd_root, 'tmp'),          showWarnings = FALSE)
dir.create(file.path(wd_root, 'reports'),      showWarnings = FALSE)
dir.create(file.path(wd_root, 'sources', 'Rdata'), showWarnings = FALSE)

##########################################################################
# DataRetriever sources
# http://retriever.readthedocs.io/en/latest/index.html
##########################################################################
if (DataRetrieve){
  # Use a persistent venv (Python 3.11 + retriever 2.4.0 + setuptools<70).
  # Create it once with: uv venv --python 3.11 ~/.local/share/r-rdataretriever
  #   then: uv pip install --python ~/.local/share/r-rdataretriever "retriever==2.4.0" "setuptools<70"
  # and apply the scripts.py InvalidVersion guard described in README.md (Prerequisites).
  venv_py <- path.expand("~/.local/share/r-rdataretriever")
  if (!file.exists(file.path(venv_py, 'bin', 'python')))
    stop("DataRetrieve = TRUE but the retriever venv is missing: ", venv_py,
         "\nCreate it as described in README.md (Prerequisites), or set DataRetrieve = FALSE.")
  Sys.setenv(RETICULATE_PYTHON_ENV = venv_py)
  source(file.path(wd_root, 'R', 'library', 'data_retrieve.r'))
}

if (DataVertNet){
  source(file.path(wd_root, 'R', 'library', 'data_vertnet.r'))
}

if (DataFishbase) {
  source(file.path(wd_root, 'R', 'library', 'data_fishbase.r'))
}

##########################################################################
# 1. Re-generate per-source Rdata files (optional)
##########################################################################
if (recompile) {
  scripts <- list.files(wd_db, pattern = '^BodyMass_.*\\.[Rr]$',
                        recursive = TRUE, full.names = TRUE)
  # Fishbase/Sealifebase are handled by the DataFishbase block above;
  # exclude them here to avoid a redundant network download.
  scripts <- scripts[!grepl('/(?:Fishbase|Sealifebase)/', scripts, perl = TRUE)]
  n        <- length(scripts)
  null_con  <- file(nullfile(), open = 'w')
  out_depth <- sink.number()
  msg_depth <- sink.number('message')
  t0 <- Sys.time()   # every frame the loop owns must be rewritten after this
  parser_errors <- list()
  for (i in seq_along(scripts)) {
    cat(sprintf('  [%d/%d] %s\n', i, n, basename(dirname(scripts[i]))),
        file = stderr())
    wd_source <- dirname(scripts[i])
    # While the message sink is active stderr() is diverted to null_con, so a
    # message printed inside the error handler is lost. Capture it here and
    # print it once `finally` has restored the sinks.
    err_msg <- NULL
    sink(nullfile()); sink(null_con, type = 'message')
    tryCatch(source(scripts[i]),
             error   = function(e) err_msg <<- conditionMessage(e),
             finally = {
               while (sink.number('message') > msg_depth) sink(type = 'message')
               while (sink.number()           > out_depth) sink()
             })
    if (!is.null(err_msg)) {
      cat(sprintf('    ERROR: %s\n', err_msg), file = stderr())
      parser_errors[[basename(dirname(scripts[i]))]] <- err_msg
    }
  }
  close(null_con)
  # A parser that fails with no frame to leave behind (fresh checkout, newly
  # added source) is otherwise invisible to the stale check below, and step 2
  # would build an incomplete database. Failures are accumulated so one run
  # reports them all, then the run stops.
  if (length(parser_errors) > 0)
    stop(length(parser_errors), ' parse script(s) failed (ERROR lines above); ',
         'fix them and rerun with recompile = TRUE:\n',
         paste0('  ', names(parser_errors), ': ', unlist(parser_errors),
                collapse = '\n'))
  # A parser that fails leaves its previous .Rdata in place, which step 2 would
  # load as if it were current. Stop on any cached frame the loop did not
  # rewrite; the four live-download frames are written by the blocks above and
  # are exempt. One second of tolerance covers coarse file-system timestamps.
  live_frames <- c('BodyMass_DataRetrieverAll.Rdata', 'BodyMass_VertNetAll.Rdata',
                   'BodyMass_Fishbase.Rdata', 'BodyMass_Sealifebase.Rdata')
  cached <- list.files(wd_rdata, pattern = '\\.Rdata$', full.names = TRUE)
  cached <- cached[basename(cached) %!in% live_frames]
  stale  <- cached[file.mtime(cached) < t0 - 1]
  if (length(stale) > 0)
    stop('recompile = TRUE but ', length(stale), ' cached frame(s) in sources/Rdata ',
         'were not rewritten (parser error above, or an orphaned file):\n',
         paste0('  ', basename(stale), collapse = '\n'))
}

# Every source README should document its Filters, Mass type and Imputed rows.
# (The imputed-rows log itself is printed and written after FixFormatting() in
# section 2b, which adds the records dropped by the raw-name rules, #38.)
CheckSourceDocs(wd_db)


##########################################################################
# 2. Load all per-source Rdata files
##########################################################################
# Whatever `recompile` was, every frame a parse script or download block
# writes must be present (else the database is built incomplete) and nothing
# else should be (an orphan would be loaded as current). check_cache.r.
CheckCacheComplete(wd_db, wd_rdata)
# The saved imputed-row entries of the live frames (audit/imputed_rows_live.csv,
# written by the download scripts) must belong to the frames in the cache; a
# frame that is not the one its entries were saved with is warned about
# (check_cache.r, #40).
CheckImputedLive(wd_rdata, ImputedLivePath(wd_root))
rdata_files <- list.files(wd_rdata, pattern = '\\.Rdata$', full.names = TRUE)

source_list <- lapply(rdata_files, function(f) {
  e <- new.env()
  load(f, envir = e)
  get(ls(e)[1], envir = e)
})


##########################################################################
# 2b. Apply taxon name corrections and  filters prior to merging
##########################################################################
# Reduce every raw name to Genus_species or Genus by the explicit rules of
# audit/raw_name_patterns.csv (#38): subgenera, sex marks, form/strain/size
# annotations, synonyms and authorities are removed, subspecies fold into the
# species, placeholders and qualifiers leave as Genus_sp / Genus_cf markers
# for RemoveNonTaxa(), hybrids and alternative names are credited to the
# first name written, and life stages and small size classes are dropped
# through DropImputed(). Encoding is normalised first (#37).
raw_name_log <- list()
source_list <- lapply(source_list, FixFormatting)
# Rows removed because the source flags them as imputed, genus-averaged or
# copied from another species (DropImputed() in the parse scripts, helpers.r)
# or because the raw name marks a life stage or a small size class
# (FixFormatting(), #38), together with the saved entries of the live download
# frames that were not downloaded in this run (audit/imputed_rows_live.csv,
# written by the download scripts; #40), ordered by source. Written only when
# the parse scripts ran, so that a recompile = FALSE run does not overwrite
# the file with the section-2b and saved entries alone.
imputed_tab <- MergeImputedLog(imputed_log, ReadImputedLive(ImputedLivePath(wd_root)),
                               downloaded = DownloadedLiveFrames(DataRetrieve, DataVertNet, DataFishbase))
if (nrow(imputed_tab) > 0) {
  cat('  Imputed rows removed by the parse scripts, the raw-name rules and the live downloads:\n',
      paste0('    ', capture.output(print(imputed_tab, row.names = FALSE)), '\n'),
      sep = '', file = stderr())
  if (recompile)
    write.csv(imputed_tab, file.path(wd_root, 'audit', 'imputed_rows.csv'),
              row.names = FALSE)
}
# Every raw name FixFormatting() changed or classified, by class and source
# (reports/warnings_raw_names.md); then stop if any raw name carried brackets
# or trailing tokens that no rule covers (class error), so that a new pattern
# is classified by hand instead of being folded into a plausible binomial.
WriteRawNameReport(file.path(wd_root, 'reports', 'warnings_raw_names.md'))
CheckRawNames()
# normalise source labels to ASCII so they match BM_citations CiteIDs exactly
source_list <- lapply(source_list, function(df) {
  df$source_mass <- NormaliseSourceLabel(df$source_mass)
  df
})
# rename misspelled taxa (depends on FixFormatting)
source_list <- lapply(source_list, FixMisspellings)
# drop non-species and (some) non-autotroph entries
source_list <- lapply(source_list, RemoveNonTaxa)
# drop extinct taxa (list compiled from MOM, PHYLACINE and AVONET status columns)
source_list <- lapply(source_list, RemoveExtinct)
# Every cleaned name must be one token, Genus_species or Genus: section 3
# files names without an underscore as genus-level records, so a replacement
# value typed with a space ('Rhytonomus isabellina', #28) demotes a species to
# a bogus genus. FixFormatting leaves only letters and one underscore, hence
# any whitespace, bracket, digit or third token found here comes from a rename
# table; stop and name the offenders with their sources (#28, #38).
CheckTaxonNames(source_list)
# Single-record mass corrections are not applied here; they are made in the
# lab Google Sheet override (section 4).

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
# species export. They are resolved at genus rank, filtered, weighted and
# de-duplicated in section 5b (#49).
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
ddat$source_mass <- NormaliseSourceLabel(ddat$source_mass)
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
    kingdom = na.omit(kingdom)[1],
    phylum  = na.omit(phylum)[1],
    class   = na.omit(class)[1],
    order   = na.omit(order)[1],
    family  = na.omit(family)[1],
    .groups = 'drop'
  ) %>% as.data.frame()
# Resolution-chain counts reported in the manuscript (written to numbers_db.tex below)
n_names_submitted <- nrow(unique_taxa)
cache_path <- file.path(wd_root, 'sources', 'enrich_cache.Rdata')

if (!fresh_start && file.exists(cache_path)) {
  load(cache_path)                                            # loads `enrich_cache` (and `genus_cache`, #49)
  if (!exists('genus_cache')) genus_cache <- EmptyGenusCache()  # a cache file written before #49
  new_taxa    <- unique_taxa[unique_taxa$taxon %!in% enrich_cache$taxon, ]
  cached_taxa <- unique_taxa[unique_taxa$taxon %in%  enrich_cache$taxon, ]
  cli::cli_inform(c(
    'i' = 'Enrichment cache: {nrow(cached_taxa)} cached, {nrow(new_taxa)} new taxa to enrich.'
  ))
  if (nrow(new_taxa) > 0) {
    new_enriched <- EnrichTaxonomy(new_taxa)
    # When an API chunk fails outright the new rows carry all-NA columns of the
    # wrong type (e.g. character gbif_usageKey); coerce to the cache's types
    # before binding so a transient outage cannot abort the run.
    for (col in intersect(names(enrich_cache), names(new_enriched))) {
      if (!identical(class(enrich_cache[[col]]), class(new_enriched[[col]])))
        new_enriched[[col]] <- methods::as(new_enriched[[col]], class(enrich_cache[[col]])[1])
    }
    enrich_cache <- bind_rows(enrich_cache, new_enriched)
  }
} else {
  if (fresh_start)
    cli::cli_inform(c('i' = 'fresh_start = TRUE: skipping cache, re-enriching all taxa.'))
  enrich_cache <- EnrichTaxonomy(unique_taxa)                 # This step will take a while
  genus_cache  <- EmptyGenusCache()                           # genus-rank resolutions (section 5b, #49)
}

save(enrich_cache, genus_cache, file = cache_path)

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
  save(enrich_cache, genus_cache, file = cache_path)
}

# Normalize rank-level synonyms and apply manual fills before inference.
# Actinopteri (GBIF backbone name) → Actinopterygii unblocks 7 fish orders;
# other fixes handle reptile class synonyms, cross-kingdom noise, and fringe
# protist/flatworm/nematode taxa that all APIs leave incomplete.
enrich_cache <- FixTaxonomyRanks(enrich_cache)
save(enrich_cache, genus_cache, file = cache_path)

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
if (cache_updated) save(enrich_cache, genus_cache, file = cache_path)

unique_taxa <- enrich_cache[enrich_cache$taxon %in% unique_taxa$taxon, ]
n_names_resolved <- sum(!is.na(unique_taxa$species))

# Join enrichment results back to all per-source rows
enrich_cols  <- c('taxon', 'species', 'genus', 'kingdom', 'phylum', 'class', 'order',
                  'family', 'taxon_provided', 'taxonomy_source', 'gbif_confidence',
                  'gbif_status', 'gbif_family', 'gbif_order', 'species_changed',
                  'gbif_usageKey')
adat_nm       <- adat[, setdiff(names(adat), c('kingdom', 'phylum', 'class', 'order', 'family'))]
adat_enriched <- merge(adat_nm, unique_taxa[, enrich_cols], by = 'taxon', all.x = TRUE)
# Names no stage resolved, with their sources and row counts, for the
# taxonomy report (#38); their rows leave at Pass 1 (filter(!is.na(species))).
unresolved_names <- adat_enriched %>%
  filter(is.na(species)) %>%
  group_by(taxon) %>%
  summarise(rows    = n(),
            sources = paste(sort(unique(SourceLabel(source_mass))), collapse = ', '),
            .groups = 'drop') %>% as.data.frame()
message(sprintf('%d cleaned names (%d rows) unresolved after all enrichment stages; listed in reports/warnings_taxonomy.md',
                nrow(unresolved_names), sum(unresolved_names$rows)))
n_resolved_pre_autotroph <- n_distinct(adat_enriched$taxon[!is.na(adat_enriched$species)])
adat_enriched <- FilterAutotrophs(adat_enriched)
n_names_autotroph <- n_resolved_pre_autotroph -
  n_distinct(adat_enriched$taxon[!is.na(adat_enriched$species)])

# Pass 1: within-source geometric mean per accepted species. Records are
# grouped by the source label (the first token of source_mass: the conversion
# CiteIDs that LabelWithConversion() appends after ';' must not split a source)
# and the VertNet dumps are pooled as one source (SourceGroup(): the 'traits'
# dump re-exports specimens of the class dumps). source_mass keeps every label
# and conversion CiteID of the group for citation (dedupe_sources.r, #5).
adat_enriched$source_label <- SourceLabel(adat_enriched$source_mass)
adat_enriched$source_group <- SourceGroup(adat_enriched$source_label)
within_source <- adat_enriched %>%
  filter(!is.na(species)) %>%
  group_by(genus, species, source_group) %>%
  summarise(
    taxon           = first(taxon),
    taxon_provided  = paste(unique(taxon_provided), collapse = '; '),
    source_label    = paste(sort(unique(source_label)), collapse = '+'),
    source_mass     = paste(unique(trimws(unlist(strsplit(sort(unique(source_mass)), ';', fixed = TRUE)))), collapse = '; '),
    mass_g          = 10^mean(log10(mass_g), na.rm = TRUE), # geometric mean
    n               = n(),
    kingdom         = na.omit(kingdom)[1],
    phylum          = na.omit(phylum)[1],
    class           = na.omit(class)[1],
    order           = na.omit(c(gbif_order, order))[1],
    family          = na.omit(c(gbif_family, family))[1],
    taxonomy_source = na.omit(taxonomy_source)[1],
    gbif_confidence = suppressWarnings(min(gbif_confidence, na.rm = TRUE)),
    gbif_status     = na.omit(gbif_status)[1],
    gbif_family     = na.omit(gbif_family)[1],
    gbif_order      = na.omit(gbif_order)[1],
    species_changed = any(species_changed, na.rm = TRUE),
    .groups         = 'drop'
  )
within_source$gbif_confidence[is.infinite(within_source$gbif_confidence)] <- NA_real_

# De-duplicate values that enter through several compilations (#5): the
# registry Bib/source_dependencies.csv and value identity decide which
# per-source values are independent; the others are collapsed into the value
# they copy (dedupe_sources.r). A registry label that matches no source stops
# the run. The summary goes to reports/dedupe_summary.md.
source_deps <- LoadSourceDependencies(file.path(wd_root, 'Bib', 'source_dependencies.csv'),
                                      known_labels = unique(adat_enriched$source_label))
dedupe        <- DedupeSources(within_source, source_deps)
within_source <- dedupe$values
WriteDedupeReport(dedupe, source_deps, file.path(wd_root, 'reports', 'dedupe_summary.md'))
message(sprintf(paste('DedupeSources: %d of %d per-source values collapsed as copies',
                      '(%d by the %d-edge registry, %d by the blind rule).'),
                sum(!within_source$independent), nrow(within_source),
                sum(within_source$dedupe_rule %in% 'registry'), nrow(source_deps),
                sum(grepl('^blind', within_source$dedupe_rule))))

# Pass 2: across-source arithmetic mean per accepted species over the
# independent values only (#5; the arithmetic mean is kept by owner decision,
# #16). source_mass still lists every contributing label and n every record;
# n_sources counts the per-source values, n_independent those entering the
# mean, and source_dependencies records each collapsed value as 'dropped<kept'.
enriched <- within_source %>%
  group_by(genus, species) %>%
  summarise(
    taxon           = first(taxon),
    taxon_provided  = paste(unique(unlist(strsplit(taxon_provided, '; '))), collapse = '; '),
    log10_range     = if (sum(independent) > 1) log10(max(mass_g[independent]) / min(mass_g[independent])) else 0,
    mass_g          = mean(mass_g[independent], na.rm = TRUE), # arithmetic mean
    source_mass     = paste(unique(trimws(unlist(strsplit(source_mass, ';', fixed = TRUE)))), collapse = '; '),
    n               = sum(n, na.rm = TRUE),
    n_sources       = n(),
    n_independent   = sum(independent),
    source_dependencies = if (any(!independent))
      paste(paste0(source_label[!independent], '<', collapsed_into[!independent]), collapse = '; ')
      else NA_character_,
    kingdom         = na.omit(kingdom)[1],
    phylum          = na.omit(phylum)[1],
    class           = na.omit(class)[1],
    order           = na.omit(order)[1],
    family          = na.omit(family)[1],
    taxonomy_source = paste(unique(taxonomy_source), collapse = '; '),
    gbif_confidence = suppressWarnings(min(gbif_confidence, na.rm = TRUE)),
    gbif_status     = na.omit(gbif_status)[1],
    gbif_family     = na.omit(gbif_family)[1],
    gbif_order      = na.omit(gbif_order)[1],
    species_changed = any(species_changed, na.rm = TRUE),
    .groups         = 'drop'
  )
enriched$gbif_confidence[is.infinite(enriched$gbif_confidence)] <- NA_real_
enriched$mass_g <- signif(enriched$mass_g, digits = 4)


##########################################################################
# 5b. Genus-only records: resolve at genus rank, filter, weight, de-duplicate
##########################################################################
# The records identified to genus only (section 3) get the machinery of the
# species path (enrich_genus.r, #49). Every bare name is resolved once to an
# accepted GBIF genus, or found to be a rank above genus, through the
# enrichment cache and the GBIF backbone, with the class/order/family hints
# the frames carry (VertNet, Castro_2025, Pata_2025, Makarieva_2008); the
# answers are cached in sources/enrich_cache.Rdata (object genus_cache).
genus_only$source_label <- SourceLabel(genus_only$source_mass)
genus_only$source_group <- SourceGroup(genus_only$source_label)
genus_cache <- ResolveGenusNames(genus_only, genus_cache, enrich_cache)
save(enrich_cache, genus_cache, file = cache_path)
genus_res <- FixTaxonomyRanks(genus_cache[genus_cache$taxon %in% genus_only$taxon, ])
genus_res$outcome <- ifelse(is.na(genus_res$rank), 'unresolved',
                            ifelse(genus_res$rank == 'GENUS', 'genus', 'above genus'))
genus_only <- merge(genus_only[, setdiff(names(genus_only), tax_cols)],
                    genus_res[, c('taxon', 'genus', 'rank', 'gbif_status', 'match_type', 'outcome', tax_cols)],
                    by = 'taxon', all.x = TRUE)
# Names resolved above genus (families, orders, tribes, ...) leave the genus
# table; HigherRankRecords() keeps one row per name for the optional
# TaxonBodyMass_HigherRank.csv (owner decision pending, #49). Names no stage
# resolved leave too and join the unresolved-names section of
# warnings_taxonomy.md (check_enriched() below).
higher_rank_records <- HigherRankRecords(genus_only[genus_only$outcome == 'above genus', ])
unresolved_genus_names <- genus_only %>%
  filter(outcome == 'unresolved') %>%
  group_by(taxon) %>%
  summarise(rows    = n(),
            sources = paste(sort(unique(source_label)), collapse = ', '),
            .groups = 'drop') %>% as.data.frame()
unresolved_names <- rbind(unresolved_names, unresolved_genus_names)
message(sprintf(paste('Genus-only records: %d rows / %d bare names; %d names resolved to %d accepted genera (%d rows),',
                      '%d names above genus (%d rows), %d unresolved (%d rows)'),
                nrow(genus_only), nrow(genus_res),
                sum(genus_res$outcome == 'genus'), n_distinct(genus_res$genus[genus_res$outcome == 'genus']),
                sum(genus_only$outcome == 'genus'),
                sum(genus_res$outcome == 'above genus'), sum(genus_only$outcome == 'above genus'),
                sum(genus_res$outcome == 'unresolved'), sum(genus_only$outcome == 'unresolved')))
# FilterAutotrophs() on the resolved classification (plants, algae,
# cyanobacteria and the listed dinoflagellate and euglenid genera, as for
# species). The extinct list (audit/extinct_taxa.csv) is species-level and
# does not apply to genus-only records.
genus_rows      <- genus_only[genus_only$outcome == 'genus', ]
genus_rows_kept <- FilterAutotrophs(genus_rows)
removed_autotrophs <- genus_rows[genus_rows$genus %!in% genus_rows_kept$genus, ] %>%
  group_by(genus, kingdom, phylum) %>%
  summarise(rows    = n(),
            names   = paste(sort(unique(taxon)), collapse = ', '),
            sources = paste(sort(unique(source_label)), collapse = ', '),
            .groups = 'drop') %>%
  arrange(-rows) %>% as.data.frame()
message(sprintf('  FilterAutotrophs: %d autotroph genera removed from the genus-only records (%d rows)',
                nrow(removed_autotrophs), sum(removed_autotrophs$rows)))
# Pass 1 (geometric mean per genus and source group), de-duplication with the
# registry, Pass 2 (arithmetic mean of the independent values): one genus-only
# record per genus, the pseudo-taxon that enters the genus mean in section 6
# with the weight of one species. The alternative weighting (each independent
# per-source value entering the genus mean separately) is kept for comparison.
genus_values <- GenusOnlyValues(genus_rows_kept)
genus_dedupe <- DedupeGenusValues(genus_values, source_deps)
genus_values <- genus_dedupe$values
genus_records     <- GenusOnlyRecords(genus_values, variant = 'pseudo-taxon')
genus_records_alt <- GenusOnlyRecords(genus_values, variant = 'per-source')
message(sprintf('  %d genus x source values, %d collapsed as copies; %d genus-only records',
                nrow(genus_values), sum(!genus_values$independent), nrow(genus_records)))

# QC reports name the extreme sources among the independent values, the ones
# log10_range is computed from.
check_enriched(enriched, within_source[within_source$independent, ],
               remove_flagged = RemoveHighMaxMinRatio, unresolved = unresolved_names)

n_species_after_filter <- nrow(enriched)   # accepted species before the range filter
# De-duplication counts (#5), taken like nSpeciesAfterFilter before the range filter
n_values_collapsed     <- sum(!within_source$independent)
n_species_single_datum <- sum(enriched$n_sources > 1 & enriched$n_independent == 1)
n_dependency_edges     <- nrow(source_deps)
n_removed_high_range <- 0L
if (RemoveHighMaxMinRatio) {
  res      <- remove_high_range_taxa(enriched, threshold = 1)
  enriched <- res$dat
  n_removed_high_range <- res$n_removed
  message(sprintf("RemoveHighMaxMinRatio: removed %d taxa with log10(max/min) > 1 from output.",
                  n_removed_high_range))
}

# Manuscript macros owned by the DB pipeline (the ML pipeline's numbers.tex holds
# everything derived from the released CSV and the models; these counts are only
# knowable here, before deduplication and filtering).
ms_dir <- file.path(dirname(wd_root), 'TaxonBodyMassML', 'ms')
if (dir.exists(ms_dir)) {
  # '{,}' (not ',') so the number also renders correctly inside math mode,
  # matching the ML pipeline's numbers.tex convention.
  tex_int <- function(x) formatC(x, format = 'd', big.mark = '{,}')
  db_macros <- c(
    nNamesSubmitted     = n_names_submitted,     # distinct cleaned species-level names
    nNamesResolved      = n_names_resolved,      # ... resolved to an accepted species
    nNamesAutotroph     = n_names_autotroph,     # ... resolved names removed as autotrophs
    nSpeciesAfterFilter = n_species_after_filter,# accepted species before the range filter
    nRemovedHighRange   = n_removed_high_range,  # species removed by log10_range > 1
    nValuesCollapsed    = n_values_collapsed,    # per-source values collapsed as copies (#5)
    nSpeciesSingleDatum = n_species_single_datum,# multi-source species left with one independent value
    nDependencyEdges    = n_dependency_edges     # edges in Bib/source_dependencies.csv
  )
  writeLines(c(
    '% TaxonBodyMass_DB pipeline macros -- auto-generated by TaxonBodyMass_DB/R/RunMe.r',
    sprintf('%% Generated %s (fresh_start = %s, recompile = %s)',
            format(Sys.Date()), fresh_start, recompile),
    sprintf('\\newcommand{\\%s}{%s\\xspace}', names(db_macros), tex_int(db_macros))
  ), file.path(ms_dir, 'numbers_db.tex'))
}


##########################################################################
# 6. Genus-level averages
##########################################################################
# Species rows aggregate by their resolved (accepted) genus, so synonyms and
# misspelt input genera fold into the accepted name (Raja erinacea -> Leucoraja);
# the genus-only record of a genus (section 5b: one value per genus, the
# arithmetic mean of its independent per-source values) enters the mean with
# the weight of one species. n_independent sums the species' independent
# values and the independent sources of the genus-only record (#5, #49).
gdat <- GenusLevelTable(enriched, genus_records)

# The report on the genus-only path (reports/genus_only_records.md): names
# above genus, autotroph genera removed, fuzzy matches and homonym choices,
# synonyms folded, collapsed values, and the genus-only records more than an
# order of magnitude from the genus's species-based mean. The intermediates
# go to tmp/ (git-ignored) for audits of the weighting variants.
species_genus_means <- enriched %>%
  group_by(genus) %>%
  summarise(species_mean = mean(mass_g), n_species = n(), .groups = 'drop') %>% as.data.frame()
genus_name_summary <- genus_only %>%
  group_by(taxon) %>%
  summarise(rows    = n(),
            sources = paste(sort(unique(source_label)), collapse = ', '),
            gm      = 10^mean(log10(mass_g), na.rm = TRUE),
            .groups = 'drop') %>% as.data.frame()
WriteGenusOnlyReport(file.path(wd_root, 'reports', 'genus_only_records.md'),
                     res = merge(genus_res, genus_name_summary, by = 'taxon'),
                     removed_autotrophs = removed_autotrophs, dedupe = genus_dedupe,
                     records = genus_records, species_genus_means = species_genus_means,
                     deps = source_deps)
save(genus_res, genus_values, genus_records, genus_records_alt, higher_rank_records,
     file = file.path(wd_root, 'tmp', 'genus_only_records.Rdata'))



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
gmap$CiteID  <- NormaliseSourceLabel(gmap$CiteID)

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

# The reverse check: every source_mass label in the exported data must have a
# CiteID row, otherwise downstream tools (e.g. TaxonBodyMassML::create_bib())
# cannot cite it. Labels are counted by the number of species rows using them.
used_labels <- trimws(unlist(strsplit(enriched$source_mass, ';', fixed = TRUE)))
used_labels <- used_labels[!is.na(used_labels) & used_labels != '']
label_tab   <- sort(table(used_labels), decreasing = TRUE)
uncited     <- label_tab[names(label_tab) %!in% dcite$CiteID]
if (length(uncited) > 0) {
  warning(
    length(uncited),
    ' source_mass labels in TaxonBodyMass.csv have no CiteID row in BM_citations:\n',
    paste0(names(uncited), ' (', as.integer(uncited), ' rows)', collapse = '\n'),
    immediate. = TRUE)
}

dcite <- dcite[order(dcite$CiteID, dcite$Bibcite), ]
write.csv(dcite, file = file.path(wd_bib, 'TaxonBodyMass_CitationCiteIDs.csv'),
          row.names = FALSE)


##########################################################################
##########################################################################
##########################################################################

