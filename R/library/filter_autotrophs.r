FilterAutotrophs <- function(dat) {
  autotroph_kingdoms <- c("Plantae", "Fungi")
  dat <- dat[is.na(dat$kingdom) | !dat$kingdom %in% autotroph_kingdoms, ]

  # Algae are polyphyletic; these phyla are predominantly or exclusively
  # photosynthetic across kingdoms Chromista, Protista, etc.
  algal_phyla <- c(
    "Ochrophyta",    # brown algae, diatoms, kelps (Chromista)
    "Haptophyta",    # coccolithophores
    "Cryptophyta",   # cryptomonads
    "Dinoflagellata",# dinoflagellates (mostly)
    "Chlorophyta",   # green algae (when outside Plantae)
    "Rhodophyta",    # red algae
    "Charophyta",    # stoneworts
    "Glaucophyta"    # glaucophytes
  )
  dat <- dat[is.na(dat$phylum) | !dat$phylum %in% algal_phyla, ]

  dat
}
