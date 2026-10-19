server <- 'sealifebase'
sp    <- rfishbase::species_names(server = server)[, c('SpecCode', 'Species')]
rfish <- rfishbase::popchar(server = server)
rfish <- dplyr::right_join(sp, rfish, by = 'SpecCode')
rfish <- rfish[!is.na(rfish$Wmax), c('Species', 'Wmax', 'PopCharRefNo')]
colnames(rfish) <- c('taxon', 'mass_g', 'ref_keys')
rfish$ref_keys <- as.character(rfish$ref_keys)
rfish <- rfish[!is.na(rfish$mass_g), ]
rfish$n <- 1
SB <- rfish
SB$source_mass <- server
save(SB, file = file.path(wd_rdata, 'BodyMass_Sealifebase.Rdata'))
