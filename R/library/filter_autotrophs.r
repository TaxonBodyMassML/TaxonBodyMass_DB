FilterAutotrophs <- function(dat) {
  # Remove autotrophic (photosynthetic) taxa so the database describes
  # heterotrophs only. Rank names follow what the enrichment authorities
  # actually return: GBIF uses "Plantae", NCBI uses "Viridiplantae"; GBIF files
  # dinoflagellates under phylum Myzozoa (class Dinophyceae), not
  # "Dinoflagellata"; cyanobacteria are a bacterial phylum and were never
  # covered by the kingdom/phylum lists before v5.1.0.
  #
  # Three levels are needed because algae are polyphyletic:
  #   1. whole kingdoms that are autotrophic (or non-consumers) by definition;
  #   2. phyla that are predominantly or exclusively photosynthetic;
  #   3. genera inside mixed phyla (Myzozoa, Euglenozoa) whose members are
  #      photosynthetic or mixotrophic, so that heterotrophic relatives
  #      (e.g. Noctiluca, Oxyrrhis, Protoperidinium; Astasia, Peranema) stay.
  # Rows with NA in the rank being tested are retained at every level.

  autotroph_kingdoms <- c("Plantae", "Viridiplantae", "Fungi")
  dat <- dat[is.na(dat$kingdom) | !dat$kingdom %in% autotroph_kingdoms, ]

  algal_phyla <- c(
    "Ochrophyta",      # brown algae, diatoms, kelps (Chromista)
    "Bacillariophyta", # diatoms when ranked as a phylum
    "Haptophyta",      # coccolithophores
    "Cryptophyta",     # cryptomonads
    "Chlorophyta",     # green algae (when outside Plantae)
    "Rhodophyta",      # red algae
    "Charophyta",      # stoneworts
    "Glaucophyta",     # glaucophytes
    "Streptophyta",    # land plants and charophytes under NCBI naming
    "Euglenophyta",    # photosynthetic euglenids when ranked as a phylum
    "Cyanobacteria",   # cyanobacteria (GBIF / NCBI legacy name)
    "Cyanobacteriota"  # cyanobacteria (current bacterial nomenclature)
  )
  dat <- dat[is.na(dat$phylum) | !dat$phylum %in% algal_phyla, ]

  autotroph_genera <- c(
    # Dinoflagellates (Myzozoa: Dinophyceae): photosynthetic or mixotrophic
    "Alexandrium", "Amphidinium", "Ceratium", "Cochlodinium", "Dinophysis",
    "Fragilidium", "Glenodinium", "Gonyaulax", "Gymnodinium", "Heterocapsa",
    "Lingulodinium", "Parvodinium", "Peridinium", "Prorocentrum",
    "Scrippsiella", "Spiniferodinium", "Takayama", "Thecadinium", "Tripos",
    "Yihiella",
    # Euglenids (Euglenozoa: Euglenoidea): photosynthetic
    "Euglena", "Eutreptiella", "Lepocinclis"
  )
  if ("genus" %in% names(dat)) {
    dat <- dat[is.na(dat$genus) | !dat$genus %in% autotroph_genera, ]
  }

  dat
}
