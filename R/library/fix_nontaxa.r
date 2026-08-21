RemoveNonTaxa <- function(dat) {

  # Family-level entries from Brose_etal_2018 (genus field is literally "Family").
  dat <- dat[!grepl("^Family_", dat$taxon), ]

  # Placeholder identification qualifiers used in place of species epithets:
  # _sp   = species indeterminate (most common)
  # _spp  = species plural (unresolved group)
  # _cf   = confer (compare; identification uncertain)
  # _nr   = near (closely related to but not identical to the named species)
  # _unk  = unknown species
  # _spX  = informal morphospecies code (e.g., spA, spB, spC, spD)
  dat <- dat[!grepl("_sp$",     dat$taxon, ignore.case = FALSE), ]
  dat <- dat[!grepl("_spp$",    dat$taxon, ignore.case = FALSE), ]
  dat <- dat[!grepl("_cf$",     dat$taxon, ignore.case = FALSE), ]
  dat <- dat[!grepl("_nr$",     dat$taxon, ignore.case = FALSE), ]
  dat <- dat[!grepl("_unk$",    dat$taxon, ignore.case = FALSE), ]
  dat <- dat[!grepl("_sp[A-Z]$", dat$taxon), ]

  # Uninformative genus-level unknown placeholders.
  dat <- dat[!grepl('^(Unk|Unknown)($|_)', dat$taxon), ]

  # Placeholder "species" token as genus or epithet.
  dat <- dat[!grepl('(^|_)[Ss]pecies($|_)', dat$taxon), ]

  # Functional-group labels used as taxon names in food-web databases.
  nontaxa <- c(
    "Acari_phyto",
    "Acari_pred",
    "Bacterivorous_nematodes",
    "Calanoid_copepods",
    "Calanoid_nauplii",        # DeLong_etal_2018 (capitalised form caught by FixFormatting)
    "Fish_eggs",
    "Fish_eggslarvae",
    "Fish_larvae",
    "Root_feeding",
    "Sea_anemones"
  )

  # Entries that cannot be linked to a valid species binomial.
  invalid <- c(
    "Candiacervus_spii",           # informal sp. II designation (no valid binomial)
    "Crayvertebrate_cambarus",     # malformed entry in Brown_etal_2018
    "Cricotopus_i",                # single-letter placeholder epithet; not a species name
    "Cricotopus_iI",               # two-letter placeholder epithet; not a species name
    "Homo_spdenisova",             # Denisovans have no formal binomial
    "Larsia_i",                    # single-letter placeholder epithet
    "Larsia_iI",                   # two-letter placeholder epithet
    "Lepidostoma_(genus_in_Opisthokonta)", # parenthetical descriptor, not a binomial
    "Magistrate_armhook",          # not a real taxon in Brown_etal_2018
    "Naia_io",                     # OCR corruption of unknown Naja species
    "Octolasion_tyrtaeumxxl",      # size-class code appended to species name
    "Octolasion_tyrtaeumxxxl",     # size-class code appended to species name
    "Tanytarsini_i",               # Tanytarsini is a tribe name, not a genus; i not a valid epithet
    "Tanytarsini_iI"               # same
  )

  # Match after lowercasing to handle any remaining capitalisation variants.
  dat <- dat[!(tolower(dat$taxon) %in% c(tolower(nontaxa), tolower(invalid))), ]

  return(dat)
}
