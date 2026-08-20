gmean <- function(x){
  exp(mean(log(x[!is.infinite(x)]), na.rm = TRUE))
}

'%!in%' <- function(x, y)!('%in%'(x, y))

firstup <-
  function(x) {
    substr(x, 1, 1) <- toupper(substr(x, 1, 1))
    x
  }

FixNames <- function(dat) {
  require('stringr')
  dat$taxon <- gsub(' ', '_', iconv(dat$taxon, from = "ISO-8859-1", to = "UTF-8"))
  dat$taxon <- gsub("[^[:alpha:]_]", "", dat$taxon)
  # Strip genus-only qualifiers (leaves bare Genus)
  dat$taxon <- gsub("_sp$",  "", dat$taxon)
  dat$taxon <- gsub("_spp$", "", dat$taxon)
  dat$taxon <- gsub("_cf$",  "", dat$taxon)
  dat$taxon <- gsub("_unk$", "", dat$taxon)
  dat$taxon <- firstup(dat$taxon)
  # Strip subspecific epithets: keep only Genus_species
  dat$taxon <- sub("^([^_]+_[^_]+)_.*$", "\\1", dat$taxon)
  dat <- subset(dat, taxon != '')
  # Remove uninformative genus-level placeholders (bare or with species epithet)
  dat <- subset(dat, !grepl('^(Unk|Unknown)($|_)', dat$taxon))
  # Remove placeholder "species" tokens (whole word, underscore-delimited)
  dat <- subset(dat, !grepl('(^|_)[Ss]pecies($|_)', dat$taxon))
  return(dat)
}

# Test cases — uncomment and run interactively to verify FixNames behaviour:
# test_dat <- data.frame(taxon = c(
#   'Acanthopagrus schlegelii schlegelii',  # subspecies          -> Acanthopagrus_schlegelii
#   'Salmo trutta trutta',                  # subspecies          -> Salmo_trutta
#   'Homo sapiens',                         # normal binomial     -> Homo_sapiens
#   'Thunnus albacares',                    # normal binomial     -> Thunnus_albacares
#   'Genus sp',                             # genus-level sp      -> Genus
#   'Genus spp',                            # genus-level spp     -> Genus
#   'Genus cf',                             # genus-level cf      -> Genus
#   'Genus unk',                            # genus-level unk     -> Genus
#   'Unk',                                  # unknown genus       -> dropped
#   'Unknown',                              # unknown genus       -> dropped
#   'Unk species',                          # unknown genus       -> dropped
#   'Unknown species',                      # unknown genus       -> dropped
#   'Genus species',                        # placeholder epithet -> dropped
#   'species',                              # bare placeholder    -> dropped
#   'Unidentified species',                 # placeholder         -> dropped
#   ''                                      # empty               -> dropped
# ), stringsAsFactors = FALSE)
# FixNames(test_dat)$taxon
# # Expected: c('Acanthopagrus_schlegelii', 'Salmo_trutta', 'Homo_sapiens',
# #             'Thunnus_albacares', 'Genus', 'Genus', 'Genus', 'Genus')
