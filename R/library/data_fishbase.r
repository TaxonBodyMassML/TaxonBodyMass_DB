# Download FishBase and SeaLifeBase body-mass records via rfishbase.
# Requires: rfishbase package and network access.
# Saves: sources/Rdata/BodyMass_Fishbase.Rdata
#        sources/Rdata/BodyMass_Sealifebase.Rdata

for (db in c('Fishbase', 'Sealifebase')) {
  script <- file.path(wd_root, 'sources', 'databases', db,
                      paste0('BodyMass_', db, '.r'))
  cli::cli_inform(c('i' = 'Downloading {db} via rfishbase ...'))
  wd_source <- dirname(script)
  tryCatch(
    source(script),
    error = function(e)
      cli::cli_warn(c('!' = '{db} download failed: {conditionMessage(e)}'))
  )
}
