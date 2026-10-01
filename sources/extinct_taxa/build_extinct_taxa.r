# Build R/library/extinct_taxa.csv: binomials of extinct (including historically
# and prehistorically extinct, and extinct-in-the-wild) species, compiled from the
# status columns of sources already in the database:
#   - MOM v10.2 (Smith et al. 2003 update), sheet 'MOM v10.0', column 'Status'
#     in {extinct, historical}; 'introduction'/'introduced' rows are extant.
#   - PHYLACINE 1.2 (Faurby et al. 2018), IUCN.Status.1.2 in {EP, EX, EW}.
#   - AVONET (Tobias et al. 2022), sheet AVONET3_BirdTree, Species.Status == 'Extinct',
#     mapped to BirdLife names through the BirdLife-BirdTree crosswalk.
# The list is applied to every source by RemoveExtinct() (R/library/filter_extinct.r)
# after FixFormatting, so taxa are stored as Genus_species.
# Run from TaxonBodyMass_DB/R (like RunMe.r) or set wd_root first.
if (!exists('wd_root')) wd_root <- dirname(getwd())
wd_db <- file.path(wd_root, 'sources', 'databases')
Bin <- function(x) gsub(' ', '_', trimws(x))

mom <- readxl::read_excel(file.path(wd_db, 'Smith_etal_2003', 'MOM v10.2.xlsx'), sheet = 'MOM v10.0')
mom <- as.data.frame(mom); names(mom) <- trimws(names(mom))
mom <- mom[!is.na(mom$Genus) & tolower(trimws(mom$Status)) %in% c('extinct', 'historical'), ]
mom_out <- data.frame(taxon = Bin(paste(mom$Genus, mom$Species)),
                      status = paste0('MOM:', tolower(trimws(mom$Status))),
                      source = 'Smith_2003', stringsAsFactors = FALSE)

phy <- read.csv(file.path(wd_db, 'Faurby_etal_2018', 'Trait_data.csv'), stringsAsFactors = FALSE)
phy <- phy[phy$IUCN.Status.1.2 %in% c('EP', 'EX', 'EW'), ]
phy_out <- data.frame(taxon = Bin(phy$Binomial.1.2), status = paste0('IUCN:', phy$IUCN.Status.1.2),
                      source = 'Faurby_etal_2018', stringsAsFactors = FALSE)

av_file <- file.path(wd_db, 'Tobias_etal_2022', 'AVONET_Supplementary_dataset_1.xlsx')
bt <- as.data.frame(readxl::read_excel(av_file, sheet = 'AVONET3_BirdTree'))
bt <- bt[bt$Species.Status %in% 'Extinct', ]
cw <- as.data.frame(readxl::read_excel(av_file, sheet = 'BirdLife–BirdTree crosswalk'))
av_names <- unique(c(bt$Species3, cw$Species1[cw$Species3 %in% bt$Species3]))
av_out <- data.frame(taxon = Bin(av_names), status = 'AVONET:Extinct', source = 'Tobias_2022',
                     stringsAsFactors = FALSE)

# MOM's 'historical'/'extinct' status is overridden where PHYLACINE assigns a
# clearly extant IUCN category (LC, NT, VU, EN, CR): e.g. MOM lists Acerodon
# jubatus and Ovibos moschatus as historical. Data-deficient (DD) species keep
# MOM's verdict.
phy_all <- read.csv(file.path(wd_db, 'Faurby_etal_2018', 'Trait_data.csv'), stringsAsFactors = FALSE)
extant_in_phylacine <- Bin(phy_all$Binomial.1.2[phy_all$IUCN.Status.1.2 %in% c('LC', 'NT', 'VU', 'EN', 'CR')])
mom_out <- mom_out[!(mom_out$taxon %in% extant_in_phylacine), ]
out <- rbind(mom_out, phy_out, av_out)
out <- out[grepl('^[A-Z][a-z]+_[a-z]+$', out$taxon), ]
out <- aggregate(cbind(status, source) ~ taxon, data = out,
                 FUN = function(x) paste(sort(unique(x)), collapse = '; '))
out <- out[order(out$taxon), ]
write.csv(out, file.path(wd_root, 'R', 'library', 'extinct_taxa.csv'), row.names = FALSE)
cat(nrow(out), 'extinct taxa written to R/library/extinct_taxa.csv\n')
