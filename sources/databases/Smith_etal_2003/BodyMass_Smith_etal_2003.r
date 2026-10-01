# MOM v10.2 (Smith et al. 2003, updated). The xlsx sheet 'MOM v10.0' carries a
# 'Status' column (extant / extinct / historical / introduction) that the csv
# export lacks; only extant (incl. introduced) species are kept so that Late
# Quaternary and historically extinct mammals do not enter the database.
adat <- readxl::read_excel(file.path(wd_source, 'MOM v10.2.xlsx'), sheet = 'MOM v10.0')
adat <- as.data.frame(adat); names(adat) <- trimws(names(adat))
adat <- adat[!is.na(adat$Genus) & tolower(trimws(adat$Status)) %in% c('extant', 'introduction', 'introduced'), ]
names(adat)[names(adat) == 'Combined.Mass (g)'] <- 'Combined.Mass..g.'
taxon_tax <- adat[, c('Genus', 'Species', 'Order', 'FAMILY')]
taxon_tax$taxon  <- paste(taxon_tax$Genus, taxon_tax$Species, sep = '_')
taxon_tax$order  <- iconv(as.character(taxon_tax$Order),  to = 'ASCII//TRANSLIT')
taxon_tax$family <- iconv(as.character(taxon_tax$FAMILY), to = 'ASCII//TRANSLIT')
taxon_tax <- taxon_tax[!duplicated(taxon_tax$taxon), c('taxon', 'order', 'family')]
adat <- adat[, c('Genus', 'Species', 'Combined.Mass..g.')]
adat$taxon <- paste(adat$Genus, adat$Species, sep = '_')
colnames(adat)[3] <- 'mass_g'
adat <- adat[, c('taxon', 'mass_g')]
adat <- adat[which(adat$mass_g != -999), ]
adat <- adat[!is.na(adat$mass_g), ]
adat$n <- 1
adat$source_mass <- 'Smith_2003'
adat <- merge(adat, taxon_tax, by = 'taxon', all.x = TRUE)
MM <- adat
save(MM, file = file.path(wd_rdata, 'BodyMass_Smith_2003.Rdata'))
