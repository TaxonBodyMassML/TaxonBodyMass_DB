server <- 'fishbase'
sp    <- rfishbase::species_names(server = server)[, c('SpecCode', 'Species')]
rfish <- rfishbase::popchar(server = server)
rfish <- dplyr::right_join(sp, rfish, by = 'SpecCode')
rfish <- rfish[!is.na(rfish$Wmax), c('Species', 'Wmax')]
colnames(rfish) <- c('taxon', 'mass_g')
rfish <- FixNames(rfish)
rfish <- rfish[!is.na(rfish$mass_g), ]
FB <- ddply(rfish, .(taxon), summarise, mass_g = gmean(mass_g), n = length(mass_g))
FB$source_mass <- server
save(FB, file = file.path(wd_rdata, 'BodyMass_Fishbase.Rdata'))
