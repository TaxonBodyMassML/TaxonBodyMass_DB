# Fetch body mass data from rdataretriever datasets and save to Rdata.
# Requires Python + retriever package (see README Prerequisites).
# Called from RunMe.r when DataRetrieve = TRUE.
# Depends on: wd_root, wd_rdata, wd_db, StackBrose2005(), DropPlaceholders(),
# ApplyUnitActions(), WebReferenceKeys(), AmnioteValueSources()
# (R/library/foodweb_units.r), SplitRefKeys(), ExplodeRefKeys()
# (R/library/citations/parse_reflists.r), imputed_log, ImputedEntriesSince(),
# SaveImputedLive() (R/library/helpers.r).
# The frame holds every record as the source wrote it (issue #69): the name
# cleaning (FixFormatting(), FixMisspellings(), RemoveNonTaxa()) and the
# per-species pooling are section 2b and Pass 1 of RunMe.r, as for every
# parse-script frame.

# Patch rdataretriever::fetch for retriever 2.x compatibility.
# In retriever 2.x, dataset_names() returns a flat character vector, but the
# R package's fetch() indexes it as all_datasets["offline"] (expecting a named
# list), so data_sets is always empty and every fetch() call fails.
local({
  retriever_py <- reticulate::import('retriever')

  patched_fetch <- function(dataset, quiet = TRUE, data_names = NULL) {
    all_datasets <- retriever_py$dataset_names()
    if (!dataset %in% all_datasets) {
      stop(
        "The dataset requested isn't currently available in the rdataretriever.\n\n",
        "Run rdataretriever::datasets() to get a list of available datasets\n\n",
        "Or run rdataretriever::get_updates() to get the newest available datasets."
      )
    }
    temp_path <- tolower(tempdir())
    if (!dir.exists(temp_path)) dir.create(temp_path)
    datasets <- vector("list", length(dataset))
    if (is.null(data_names)) {
      names(datasets) <- gsub("-", "_", dataset)
    }
    for (i in seq_along(dataset)) {
      if (quiet) {
        retriever_py$install_csv(dataset = dataset[i],
                                 table_name = "{db}_{table}.csv",
                                 data_dir   = temp_path)
      } else {
        retriever_py$install_csv(dataset = dataset[i],
                                 table_name = "{db}_{table}.csv",
                                 data_dir   = temp_path, debug = TRUE)
      }
      files <- dir(temp_path)
      dataset_underscores <- gsub("-", "_", dataset[i])
      files <- files[grep(dataset_underscores, files)]
      tempdata <- vector("list", length(files))
      list_names <- sub(".csv", "", files)
      list_names <- sub(paste0(dataset_underscores, "_"), "", list_names)
      names(tempdata) <- list_names
      for (j in seq_along(files)) {
        tempdata[[j]] <- utils::read.csv(file.path(temp_path, files[j]))
      }
      datasets[[i]] <- tempdata
    }
    if (length(datasets) == 1) datasets <- datasets[[1]]
    return(datasets)
  }

  assignInNamespace('fetch', patched_fetch, 'rdataretriever')
})

# The DropImputed() entries this script adds (the Brose_2005 placeholder rows,
# DropPlaceholders() below) are saved to audit/imputed_rows_live.csv at the end,
# so that a run with DataRetrieve = FALSE still writes them to
# audit/imputed_rows.csv (#40).
n_log_before <- length(imputed_log)

# mammal-life-hist: family available; no order column
# Ernest SM. Life history characteristics of placental nonvolant mammals: 
# ecological archives E084‐093. Ecology. 2003 Dec;84(12):3402-.
mlh <- rdataretriever::fetch('mammal-life-hist')[[1]]
mlh$taxon <- paste(mlh$genus, mlh$species)
mlh <- mlh[, c('taxon', 'mass_g', 'family')]
mlh$family <- as.character(mlh$family)
mlh <- mlh[which(!is.na(mlh$mass_g) & mlh$mass_g > 0), ]
mlh$n <- 1
mlh$source_mass <- 'Ernest_2003'


# bird-size (Lislevand et al. 2007, Ecological Archives E088-096) is no longer
# fetched here (issue #102, 2026-10-05): the same data file is parsed by
# sources/databases/Lislevand_etal_2007/BodyMass_Lislevand_etal_2007.r, which
# averages the male, female and unsexed masses and keeps the per-record
# reference numbers as ref_keys; the retriever copy (male mass only, no
# references) duplicated it under the same label.

# predator-prey-body-ratio: no taxonomy beyond binomial
# Brose U, Cushing L, Berlow EL, Jonsson T, Banasek-Richter C, Bersier LF, 
# Blanchard JL, Brey T, Carpenter SR, Blandenier MF, Cohen JE. 
# BODY SIZES OF CONSUMERS AND THEIR RESOURCES: Ecological Archives 
# E086-135. Ecology. 2005 Sep;86(9):2545-.
# Consumer and resource rows are stacked with the adult-or-unspecified
# life-stage filter of the GATEWAy parser (StackBrose2005(),
# R/library/foodweb_units.r), group-level placeholder values (a mean mass
# shared by >= 5 taxa of one study) are dropped as imputed, and the per-study
# actions of sources/databases/DataRetriever/brose2005_units.csv are applied:
# the two Woodward-group stream studies (Broadstone Stream, Mill Stream) report
# dry mass and are converted to wet grams with brose2005_units_groups.csv,
# every other study is kept as reported (issue #14, owner decisions 2026-10-03).
# Every row then cites its study (the Link reference) as its primary reference,
# one key per cited work from brose2005_references.csv (study-level
# attribution, issue #64; WebReferenceKeys()); the keys are kept per row as
# `ref_keys` (Pass 1 of RunMe.r collapses them per species with JoinRefKeys()).
ppb <- rdataretriever::fetch('predator-prey-body-ratio')[[1]]
ppb <- StackBrose2005(ppb)
ppb <- DropPlaceholders(ppb, 'study', 'Brose_2005')
ppb_units  <- read.csv(file.path(wd_db, 'DataRetriever', 'brose2005_units.csv'),
                       stringsAsFactors = FALSE, na.strings = c('', 'NA'))
ppb_groups <- read.csv(file.path(wd_db, 'DataRetriever', 'brose2005_units_groups.csv'),
                       stringsAsFactors = FALSE, na.strings = c('', 'NA'))
ppb <- ApplyUnitActions(ppb, ppb_units, key = 'study', groups = ppb_groups,
                        group_key = 'study', label = 'Brose_2005')
ppb_refs <- read.csv(file.path(wd_db, 'DataRetriever', 'brose2005_references.csv'),
                     stringsAsFactors = FALSE, na.strings = c('', 'NA'), encoding = 'UTF-8')
ppb$ref_keys <- WebReferenceKeys(ppb$study, ppb_refs, 'link_reference', 'Brose_2005')
ppb <- ppb[, c('taxon', 'mass_g', 'n', 'source_mass', 'ref_keys')]

# pantheria: order and family available
# Jones KE, Bielby J, Cardillo M, Fritz SA, O'Dell J, Orme CD, Safi K, 
#  Sechrest W, Boakes EH, Carbone C, Connolly C. PanTHERIA: 
#  a species‐level database of life history, ecology, and geography of 
#  extant and recently extinct mammals: Ecological Archives E090‐184. 
#  Ecology. 2009 Sep;90(9):2648-.
# The `References` column of the data file (the retriever names it `refs`)
# cites the numbered entries of the Ecological Archives E090-184 metadata
# reference list (1-3143; sources/databases/Jones_2009/references.csv, written
# by build_references.py) ';'-separated for the whole species row, every trait
# and not body mass alone (the Lislevand_etal_2007 situation); the numbers are
# kept per record as `ref_keys` (issue #1, Stage 2). 18 cells glue two
# four-digit numbers without the separator ('30483049' for 3048;3049): a
# token of eight digits whose halves are both entries of the list is split.
pan <- rdataretriever::fetch('pantheria')[[1]]
pan_refs <- read.csv(file.path(wd_db, 'Jones_2009', 'references.csv'),
                     stringsAsFactors = FALSE, colClasses = 'character', encoding = 'UTF-8')
pan_max  <- max(as.integer(pan_refs$key))
pan_cited <- trimws(as.character(pan$refs))
pan_cited[pan_cited %in% c('', '-999')] <- NA_character_      # no reference (none among the rows with a mass)
pan_cited <- gsub('(?<=^|;)([0-9]{4})([0-9]{4})(?=;|$)', '\\1;\\2', pan_cited, perl = TRUE)
pan$ref_keys <- SplitRefKeys(pan_cited, ';')
pan <- pan[, c('msw05_binomial', 'adultbodymass_g', 'msw05_order', 'msw05_family', 'ref_keys')]
colnames(pan)[1:4] <- c('taxon', 'mass_g', 'order', 'family')
pan$order  <- as.character(pan$order)
pan$family <- as.character(pan$family)
pan <- pan[which(!is.na(pan$mass_g) & pan$mass_g > 0), ]
pan_bad <- setdiff(unique(ExplodeRefKeys(pan$ref_keys)$native_key), pan_refs$key)
if (length(pan_bad) > 0)
  warning('Jones_2009: ', length(pan_bad), ' cited reference number(s) not in references.csv (1-', pan_max, '): ',
          paste(head(pan_bad, 5), collapse = ', '))
pan$n <- 1
pan$source_mass <- 'Jones_2009'

# amniote-life-hist: EAV format — filter to adult body mass; class/order/family available
# Myhrvold NP, Baldridge E, Chan B, Sivam D, Freeman DL, Ernest SM. An amniote 
#  life‐history database to perform comparative analyses with birds, mammals, 
#  and reptiles: Ecological Archives E096‐269. Ecology. 2015 Nov;96(11):3109-.
# The dataset's second table (`references`, the Amniote_Database_References
# csv in the same EAV layout, joined by the retriever's `record_id` = row of the
# data file) names the sources of every value: the value-providing names of
# the adult_body_mass_g cell ("Dunning, 1992", "mean of Dunning, 1992 & Bennett,
# 1986 from median of 4(...)") are mapped by AmnioteValueSources()
# (R/library/foodweb_units.r) to the keys of
# sources/databases/Myhrvold_2015/references.csv (build_references.py: one
# row per name on the body-mass records, the literature-cited entry matched
# to it) and kept per record as `ref_keys`, '; '-joined (issue #1, Stage 2).
amn_all <- rdataretriever::fetch('amniote-life-hist')
amn <- amn_all$main
amn <- amn[amn$trait == 'adult_body_mass_g', ]
amn_ref <- amn_all$references
amn_ref <- amn_ref[amn_ref$trait == 'adult_body_mass_g', c('record_id', 'reference')]
if (anyDuplicated(amn_ref$record_id) || !all(amn$record_id %in% amn_ref$record_id))
  stop('Myhrvold_2015: the references table does not join the data table one to one by record_id')
amn_refs <- read.csv(file.path(wd_db, 'Myhrvold_2015', 'references.csv'),
                     stringsAsFactors = FALSE, colClasses = 'character', encoding = 'UTF-8')
amn$taxon  <- paste(amn$genus, amn$species)
amn$mass_g <- as.numeric(amn$trait_value)
amn <- amn[which(!is.na(amn$mass_g) & amn$mass_g > 0), ]
# the references table names the sources of the kept cells only
amn$ref_keys <- AmnioteValueSources(amn_ref$reference[match(amn$record_id, amn_ref$record_id)], amn_refs)
amn <- amn[, c('taxon', 'mass_g', 'classes', 'ordered', 'family', 'ref_keys')]
colnames(amn)[3:4] <- c('class', 'order')
amn$class  <- as.character(amn$class)
amn$order  <- as.character(amn$order)
amn$family <- as.character(amn$family)
amn$n <- 1
amn$source_mass <- 'Myhrvold_2015'

# socean-diet-data: multi-table dataset — must index by name; no taxonomy beyond binomial
# Raymond B, Marshall M, Nevitt G, Gillies CL, Van Den Hoff J, Stark JS, Losekoot M, 
#  Woehler EJ, Constable AJ. A Southern Ocean dietary database: 
#  Ecological Archives E092‐097. Ecology. 2011 May;92(5):1188-.
sdd <- rdataretriever::fetch('socean-diet-data')$diet
sdd1 <- sdd[, c('predator_name', 'predator_mass_mean')]
sdd2 <- sdd[, c('prey_name',     'prey_mass_mean')]
colnames(sdd1) <- colnames(sdd2) <- c('taxon', 'mass_g')
sdd <- bind_rows(sdd1, sdd2)
sdd <- sdd[which(!is.na(sdd$mass_g) & sdd$mass_g > 0), ]
sdd$n <- 1
sdd$source_mass <- 'Raymond_2011'

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Every record is one frame row, named as the source wrote it (issue #69):
# no name cleaning and no per-taxon collapse happen here, so that the raw-name
# rules of audit/raw_name_patterns.csv, fix_misspellings.r and fix_nontaxa.r
# are applied by section 2b of RunMe.r at every run (recompile = TRUE
# re-cleans a live frame like any parse-script frame, and CheckRawNames()
# sees its raw names) and Pass 1 pools the records per cleaned species and
# source. Until 2026-10-05 the download applied FixFormatting(),
# FixMisspellings() and RemoveNonTaxa() and saved one geometric mean per
# cleaned taxon, which froze the cleaning rules of the download date in the
# cache: 60 Brose_2005 authorities without a year would have stopped section
# 2b as unclassified bracket groups, 157 records of Chartoscirta cincta were
# lost to the pre-#37 encoding step, and the frame kept Aspilota and
# Orthostigma as genus-level records after #43 had decided that
# morphospecies codes drop (#69).
adat <- bind_rows(mlh, ppb, pan, amn, sdd)
adat <- adat[which(!is.na(adat$mass_g) & adat$mass_g > 0), ]
adat$taxon <- as.character(adat$taxon)
for (col in c('class', 'order', 'family'))
  if (!col %in% names(adat)) adat[[col]] <- NA_character_
# a missing or empty name (the Brose table writes '0' once) is no record
DR <- adat[!is.na(adat$taxon) & !adat$taxon %in% c('', '0'), ]

save(DR, file = file.path(wd_rdata, 'BodyMass_DataRetrieverAll.Rdata'))
SaveImputedLive('DataRetrieverAll', ImputedEntriesSince(n_log_before),
                ImputedLivePath(wd_root), wd_rdata)
