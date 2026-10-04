# Download FishBase and SeaLifeBase body-mass records via rfishbase.
# Requires: rfishbase package and network access.
# Saves: sources/Rdata/BodyMass_Fishbase.Rdata
#        sources/Rdata/BodyMass_Sealifebase.Rdata
#        and each frame's DropImputed() entries (none yet) to
#        audit/imputed_rows_live.csv (SaveImputedLive(), helpers.r; #40),
#        replacing the frame's previous rows; a failed download leaves them.

for (db in c('Fishbase', 'Sealifebase')) {
  script <- file.path(wd_root, 'sources', 'databases', db,
                      paste0('BodyMass_', db, '.r'))
  cli::cli_inform(c('i' = 'Downloading {db} via rfishbase ...'))
  wd_source <- dirname(script)
  n_log_before <- length(imputed_log)
  ok <- tryCatch(
    { source(script); TRUE },
    error = function(e) {
      cli::cli_warn(c('!' = '{db} download failed: {conditionMessage(e)}'))
      FALSE
    }
  )
  if (ok) SaveImputedLive(db, ImputedEntriesSince(n_log_before), ImputedLivePath(wd_root), wd_rdata)
}
