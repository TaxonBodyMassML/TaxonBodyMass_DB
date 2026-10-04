# Remove extinct taxa so the database describes extant species only.
# The list audit/extinct_taxa.csv (Genus_species; built by
# sources/extinct_taxa/build_extinct_taxa.r from the status columns of MOM v10.2,
# PHYLACINE 1.2 and AVONET) is applied to every source after FixFormatting,
# whichever source a record comes from. Sources with their own status column
# (Smith_2003, Faurby_etal_2018) additionally drop extinct rows in their scripts.
extinct_taxa <- read.csv(file.path(wd_root, 'audit', 'extinct_taxa.csv'),
                         stringsAsFactors = FALSE)$taxon

RemoveExtinct <- function(dat) {
  drop <- dat$taxon %in% extinct_taxa
  if (any(drop)) {
    attr_removed <- unique(dat$taxon[drop])
    message(sprintf('  RemoveExtinct: %s - dropped %d record(s) of %d extinct taxa',
                    dat$source_mass[1], sum(drop), length(attr_removed)))
  }
  dat[!drop, ]
}
