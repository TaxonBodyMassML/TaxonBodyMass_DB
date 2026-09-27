# Barnes et al. (2008) Predator and prey body sizes in marine food webs.
# Ecology 89:881, Ecological Archives E089-051-D1 (data file version 4, 2014-03-05).
# 34,931 predator-prey records; predator and prey masses are in separate column
# sets, each with its own unit column.
adat <- read.delim(
  file.path(wd_source, 'Predator_and_prey_body_sizes_in_marine_food_webs_vsn4.txt'),
  sep = '\t', quote = '"', fileEncoding = 'latin1', stringsAsFactors = FALSE
)
unit_to_g <- c(g = 1, mg = 1e-3, kg = 1e3)

# Predators: keep adult (any sex) and unspecified lifestages. Records sharing an
# Individual ID are one fish with several prey items, so keep one row per individual.
ls <- tolower(trimws(adat$Predator.lifestage))
keep_pred <- is.na(ls) | ls == '' | grepl('^adult|female|male', ls)
pred <- adat[keep_pred, ]
pred <- pred[!duplicated(pred[, c('Predator', 'Individual.ID')]), ]
pred <- data.frame(taxon  = pred$Predator,
                   mass_g = pred$Predator.mass * unit_to_g[pred$Predator.mass.unit])

# Prey: no lifestage column, so all are "unspecified" unless the name or the
# Prey taxon field marks eggs or a developmental stage.
stage_re  <- 'naupli|copepodit|egg|larv|zoea|megalop|juv|furcilia|calyptop|postlarv'
keep_prey <- adat$Prey.taxon != 'egg' & !grepl(stage_re, adat$Prey, ignore.case = TRUE)
prey <- adat[keep_prey, ]
prey <- data.frame(taxon  = prey$Prey,
                   mass_g = prey$Prey.mass * unit_to_g[prey$Prey.mass.unit])

adat <- rbind(pred, prey)
adat$taxon <- trimws(gsub('\\s+', ' ', adat$taxon))
# Keep Latin binomials and 'Genus sp.' only (the latter are dropped by
# RemoveNonTaxa). This excludes common-name and functional-group prey labels
# ('fish unidentified', 'Amphipod', 'teleosts/molluscs/crustaceans') that
# would otherwise pass through as bogus genus-level entries, and pooled
# names such as 'Loligo pealei or Illex illecebrosus' that FixFormatting
# would truncate to the first binomial.
adat <- adat[grepl('^[A-Z][a-z]+ ([a-z]+|sp\\.)$', adat$taxon), ]
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
adat$n <- 1
adat$source_mass <- 'Barnes_2008'
BA <- adat
save(BA, file = file.path(wd_rdata, 'BodyMass_Barnes_2008.Rdata'))
