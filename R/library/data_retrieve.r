# Fetch body mass data from rdataretriever datasets and save to Rdata.
# Requires Python + retriever package (see README Prerequisites).
# Called from RunMe.r when DataRetrieve = TRUE.
# Depends on: wd_rdata, FixFormatting(), FixMisspellings(), RemoveNonTaxa()

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


# bird-size: family column is an integer code, not a name — drop it
# Terje Lislevand, Jordi Figuerola, and Tam´as Sz´ekely. 
# Avian body sizes in relation to fecundity, mating
# system, display behavior, and resource sharing: Ecological archives 
# e088-096. Ecology, 88(6):1605–1605,  2007.
bir <- rdataretriever::fetch('bird-size')[[1]]
bir <- bir[, c('species_name', 'm_mass')]
colnames(bir) <- c('taxon', 'mass_g')
bir <- bir[which(!is.na(bir$mass_g) & bir$mass_g > 0), ]
bir$n <- 1
bir$source_mass <- 'Lislevand_etal_2007'

# predator-prey-body-ratio: no taxonomy beyond binomial
# Brose U, Cushing L, Berlow EL, Jonsson T, Banasek-Richter C, Bersier LF, 
# Blanchard JL, Brey T, Carpenter SR, Blandenier MF, Cohen JE. 
# BODY SIZES OF CONSUMERS AND THEIR RESOURCES: Ecological Archives 
# E086‐135. Ecology. 2005 Sep;86(9):2545-.
ppb <- rdataretriever::fetch('predator-prey-body-ratio')[[1]]
ppb <- ppb[which(ppb$taxonomy_consumer != '' & ppb$taxonomy_resource != ''), ]
ppb1 <- ppb[, c('taxonomy_consumer', 'mean_mass_g_consumer')]
ppb2 <- ppb[, c('taxonomy_resource', 'mean_mass_g_resource')]
colnames(ppb1) <- colnames(ppb2) <- c('taxon', 'mass_g')
ppb <- bind_rows(ppb1, ppb2)
ppb <- ppb[which(!is.na(ppb$mass_g) & ppb$mass_g > 0), ]
ppb$n <- 1
ppb$source_mass <- 'Brose_2005'

# pantheria: order and family available
# Jones KE, Bielby J, Cardillo M, Fritz SA, O'Dell J, Orme CD, Safi K, 
#  Sechrest W, Boakes EH, Carbone C, Connolly C. PanTHERIA: 
#  a species‐level database of life history, ecology, and geography of 
#  extant and recently extinct mammals: Ecological Archives E090‐184. 
#  Ecology. 2009 Sep;90(9):2648-.
pan <- rdataretriever::fetch('pantheria')[[1]]
pan <- pan[, c('msw05_binomial', 'adultbodymass_g', 'msw05_order', 'msw05_family')]
colnames(pan) <- c('taxon', 'mass_g', 'order', 'family')
pan$order  <- as.character(pan$order)
pan$family <- as.character(pan$family)
pan <- pan[which(!is.na(pan$mass_g) & pan$mass_g > 0), ]
pan$n <- 1
pan$source_mass <- 'Jones_2009'

# amniote-life-hist: EAV format — filter to adult body mass; class/order/family available
# Myhrvold NP, Baldridge E, Chan B, Sivam D, Freeman DL, Ernest SM. An amniote 
#  life‐history database to perform comparative analyses with birds, mammals, 
#  and reptiles: Ecological Archives E096‐269. Ecology. 2015 Nov;96(11):3109-.
amn <- rdataretriever::fetch('amniote-life-hist')[[1]]
amn <- amn[amn$trait == 'adult_body_mass_g', ]
amn$taxon  <- paste(amn$genus, amn$species)
amn$mass_g <- as.numeric(amn$trait_value)
amn <- amn[, c('taxon', 'mass_g', 'classes', 'ordered', 'family')]
colnames(amn)[3:4] <- c('class', 'order')
amn$class  <- as.character(amn$class)
amn$order  <- as.character(amn$order)
amn$family <- as.character(amn$family)
amn <- amn[which(!is.na(amn$mass_g) & amn$mass_g > 0), ]
amn$n <- 1
amn$source_mass <- 'Myrhvold_2015'

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

adat <- bind_rows(mlh, bir, ppb, pan, amn, sdd)

adat <- FixFormatting(adat)
adat <- FixMisspellings(adat)
adat <- RemoveNonTaxa(adat)
adat <- adat[which(!is.na(adat$mass_g) & adat$mass_g > 0), ]

# Calculate geometric mean for each taxon within each dataset
adat <- adat %>%
  group_by(taxon, source_mass) %>%
  mutate(mass_g = 10^mean(log10(mass_g), na.rm = TRUE), n = n()) %>%
  slice(1) %>%
  ungroup()

for (col in c('class', 'order', 'family'))
  if (!col %in% names(adat)) adat[[col]] <- NA_character_
DR <- adat[adat$taxon != 0, ]

save(DR, file = file.path(wd_rdata, 'BodyMass_DataRetrieverAll.Rdata'))
