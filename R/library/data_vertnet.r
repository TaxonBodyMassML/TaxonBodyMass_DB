# Download VertNet Sept 2016 snapshots from CyVerse, extract body mass, save Rdata.
# Called from RunMe.r when DataVertNet = TRUE.
# Depends on: wd_root, wd_rdata, data.table
#
# Total download ~3 GB across 6 archives; expect 30-60+ min on typical broadband.
# Each ZIP is deleted immediately after the body mass records are extracted.
# Only the compact BodyMass_VertNetAll.Rdata persists (in sources/Rdata/, gitignored).
#
# Bloom D. VertNet_Mammalia_Sept2016 / _Amphibia / _Traits / _Reptilia / _Fishes / _Aves.
# CyVerse Data Commons, 2016. (Bloom:2016aa-af)

library(data.table)

# Large files (~600 MB each): raise timeout well above the 60-second default.
old_timeout <- getOption('timeout')
options(timeout = 3600)
on.exit(options(timeout = old_timeout), add = TRUE)

base_url <- 'https://data.cyverse.org/dav-anon/iplant/home/shared/commons_repo/curated/'

vn_datasets <- list(
  list(name = 'Mammalia', cite = 'Bloom:2016aa',
       url  = paste0(base_url, 'Vertnet_Mammalia_Sep2016/VertNet_Mammalia_Sept2016.zip')),
  list(name = 'Amphibia', cite = 'Bloom:2016ab',
       url  = paste0(base_url, 'Vertnet_Amphibia_Sep2016/VertNet_Amphibia_Sept2016.zip')),
  list(name = 'Traits',   cite = 'Bloom:2016ac',
       url  = paste0(base_url, 'VertNet_Traits/VertNet_Traits_Sept2016.zip')),
  list(name = 'Reptilia', cite = 'Bloom:2016ad',
       url  = paste0(base_url, 'Vertnet_Reptilia_Sep2016/VertNet_Reptilia_Sept2016.zip')),
  list(name = 'Fishes',   cite = 'Bloom:2016ae',
       url  = paste0(base_url, 'Vertnet_Fishes_Sep2016/VertNet_Fishes_Sept2016.zip')),
  list(name = 'Aves',     cite = 'Bloom:2016af',
       url  = paste0(base_url, 'Vertnet_Aves_Sep2016/VertNet_Aves_Sept2016.zip'))
)

vn_dir <- file.path(wd_root, 'sources', 'VertNet')
dir.create(vn_dir, showWarnings = FALSE)

needed_cols <- c('genus', 'specificepithet', 'class', 'order', 'family',
                 'hasmass', 'massing')

records_list <- vector('list', length(vn_datasets))

for (i in seq_along(vn_datasets)) {
  ds <- vn_datasets[[i]]
  message('\n--- VertNet ', ds$name, ' (', ds$cite, ') ---')

  zip_path <- file.path(vn_dir, basename(ds$url))

  if (!file.exists(zip_path)) {
    message('Downloading ', basename(ds$url), ' ...')
    download.file(ds$url, destfile = zip_path, mode = 'wb')
  } else {
    message('Using cached ', basename(ds$url))
  }

  # Find the CSV inside the ZIP (internal filename varies by dataset)
  zip_contents <- unzip(zip_path, list = TRUE)
  csv_name <- zip_contents$Name[grep('\\.csv$', zip_contents$Name, ignore.case = TRUE)][1]
  if (is.na(csv_name)) {
    message('No CSV found in ', basename(ds$url), ' — skipping')
    file.remove(zip_path)
    next
  }
  message('Extracting ', csv_name, ' ...')
  csv_path <- unzip(zip_path, files = csv_name, exdir = vn_dir)

  # Peek at the header to determine which schema this archive uses
  header_cols <- names(suppressWarnings(fread(csv_path, nrows = 0, showProgress = FALSE)))

  if (all(c('hasmass', 'massing') %in% header_cols)) {
    # Standard VertNet Sept 2016 class-level schema
    dat <- suppressWarnings(fread(csv_path, select = needed_cols, showProgress = FALSE))
    file.remove(csv_path); file.remove(zip_path)

    dat <- dat[as.logical(hasmass) %in% TRUE]
    dat[, massing := suppressWarnings(as.numeric(massing))]
    dat <- dat[!is.na(massing) & massing > 0]

  } else if ('dynamicproperties' %in% header_cols) {
    # Older Darwin Core format (e.g. Traits): mass buried in dynamicproperties
    message('Parsing mass from dynamicproperties ...')
    traits_cols <- intersect(
      c('genus', 'specificepithet', 'class', 'order', 'family',
        'dynamicproperties', 'lifestage'),
      header_cols
    )
    dat <- suppressWarnings(fread(csv_path, select = traits_cols, showProgress = FALSE))
    file.remove(csv_path); file.remove(zip_path)

    # Keep only rows that mention weight or mass
    dat <- dat[grepl('(?:weight|mass)\\s*[=:]', dynamicproperties,
                     ignore.case = TRUE, perl = TRUE)]

    # Drop known juvenile / non-adult lifestages
    juv_pat <- '^(?:juvenile|juv\\.?|nestling|young.*|immature|subadult|hy|u-imm.*)$'
    if ('lifestage' %in% names(dat))
      dat <- dat[!grepl(juv_pat, trimws(tolower(lifestage)), perl = TRUE)]

    # Extract numeric value and unit; non-greedy so first occurrence is taken
    dp        <- dat$dynamicproperties
    val_pat   <- '^.*?(?:weight|mass)\\s*[=:]\\s*([0-9]+(?:\\.[0-9]+)?).*$'
    unit_pat  <- '^.*?(?:weight|mass)\\s*[=:]\\s*[0-9]+(?:\\.[0-9]+)?\\s*([a-z]*).*$'
    mass_val  <- suppressWarnings(as.numeric(
                   gsub(val_pat,  '\\1', dp, ignore.case = TRUE, perl = TRUE)))
    mass_unit <- tolower(trimws(
                   gsub(unit_pat, '\\1', dp, ignore.case = TRUE, perl = TRUE)))

    # Convert all units to grams; mark length/ambiguous units as NA
    skip_units <- c('mm', 'cm', 'totallength', 'svl')
    to_g <- ifelse(mass_unit %in% skip_units,              NA_real_,
            ifelse(mass_unit %in% c('kg'),                 mass_val * 1000,
            ifelse(mass_unit %in% c('lb', 'lbs', 'pounds'), mass_val * 453.592,
            ifelse(mass_unit %in% c('oz'),                 mass_val * 28.3495,
            ifelse(mass_unit %in% c('mg'),                 mass_val / 1000,
                   mass_val)))))   # g, gm, gms, grams, gr, og, '' → grams

    dat[, massing := to_g]
    dat <- dat[!is.na(massing) & massing > 0]

  } else {
    message(ds$name, ' has unrecognized schema — skipping')
    file.remove(csv_path); file.remove(zip_path)
    next
  }

  if (nrow(dat) == 0) {
    message('No mass records found in ', ds$name, ' — skipping')
    next
  }

  dat[, taxon       := trimws(paste(genus, specificepithet))]
  dat[, mass_g      := massing]
  dat[, n           := 1L]
  dat[, source_mass := paste0('vertnet-', tolower(ds$name), '-sept2016')]

  records_list[[i]] <- dat[, .(taxon, mass_g, class, order, family, n, source_mass)]
  message(format(nrow(records_list[[i]]), big.mark = ','),
          ' mass records retained for ', ds$name)
}

VN <- rbindlist(records_list, fill = TRUE, use.names = TRUE)
message('\nTotal VertNet mass records: ', format(nrow(VN), big.mark = ','))

save(VN, file = file.path(wd_rdata, 'BodyMass_VertNetAll.Rdata'))
message('Saved BodyMass_VertNetAll.Rdata')
