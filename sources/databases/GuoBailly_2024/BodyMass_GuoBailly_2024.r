adat <- read.csv(file.path(wd_source, 'GuoBailly_2024_AppendixTable1.csv'), header = TRUE)
adat <- adat[, c('Species', 'Weight_g')]
colnames(adat) <- c('taxon', 'mass_g')
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g), ]
adat$n <- 1
adat$source_mass <- 'GuoBailly_2024'
GUO <- adat
# This source was labelled Pauly_2024 and cached as BodyMass_Pauly_2024.Rdata
# until 2026-10 (issue #3). sources/Rdata is git-ignored, so an existing
# checkout keeps that orphan after pulling the rename: with recompile = TRUE
# RunMe stops on it at the stale-frame check, with recompile = FALSE it would
# load both frames. Remove it here so the checkout migrates by itself.
legacy <- file.path(wd_rdata, 'BodyMass_Pauly_2024.Rdata')
if (file.exists(legacy)) {
  unlink(legacy)
  message('GuoBailly_2024: removed the legacy frame BodyMass_Pauly_2024.Rdata')
}
save(GUO, file = file.path(wd_rdata, 'BodyMass_GuoBailly_2024.Rdata'))
