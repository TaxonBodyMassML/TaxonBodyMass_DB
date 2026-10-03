# DeLong, Okie, Moses, Sibly & Brown (2010) Shifts in metabolic scaling,
# production, and efficiency across major evolutionary transitions of life.
# PNAS 107:12941-12945, https://doi.org/10.1073/pnas.1007783107.
# Body masses of the two SI data sets, transcribed from the Word tables in this
# folder: sd01.csv = Dataset S1 (metabolic rates; group, rate_type, species,
# mass_g, metabolic_rate_W) and sd02.csv = Dataset S2 (r_max; group, species,
# body_mass_g, rmax_per_day). README.md gives the per-group sources and the
# unit audit of issue #13 (2026-10-03), whose decisions are implemented here:
#  1. Dataset S2 metazoans (16 rows, all from Savage et al. 2004) are headed
#     'Body mass (g)' but are in micrograms: every row sits 1e5-1e7 above the
#     other sources of this database (median 10^5.4 over 11 matched species),
#     Daphnia magna is 8.85e2 here against 9.39e-4 g in Dataset S1 of the same
#     paper (factor 9.4e5), and all 16 rows are plausible after x 1e-6 (Gadus
#     morhua 1.5e10 -> 15 kg, Daphnia magna 0.89 mg, Filinia 0.25 ug) and
#     impossible before. The whole group is multiplied by 1e-6.
#  2. Dataset S1, 'Entamoeba hystolitica' active-rate row: 8.6e-6 g against
#     8.6e-9 g in the endogenous-rate row of the same table (the Makarieva 2008
#     value, the mass of a 20-30 um cell); same mantissa, factor 1e3. The
#     active-rate row is dropped with DropImputed(); the endogenous row stays.
#  3. Every other row (Dataset S1 all groups, Dataset S2 prokaryotes and
#     protists) agrees with the other sources (median log10 ratio 0.0) and is
#     used as grams.
#  4. A plausibility guard stops the parse if any value exceeds its group's
#     ceiling, so a unit regression cannot reach the database silently.

adat1 <- read.csv(file.path(wd_source, 'sd01.csv'), header = TRUE, stringsAsFactors = FALSE)
adat2 <- read.csv(file.path(wd_source, 'sd02.csv'), header = TRUE, stringsAsFactors = FALSE)
adat <- rbind(
  data.frame(taxon = adat1$species, mass_g = adat1$mass_g, dataset = 'sd01',
             group = adat1$group, rate_type = adat1$rate_type, stringsAsFactors = FALSE),
  data.frame(taxon = adat2$species, mass_g = adat2$body_mass_g, dataset = 'sd02',
             group = adat2$group, rate_type = NA_character_, stringsAsFactors = FALSE))
adat$mass_g <- suppressWarnings(as.numeric(adat$mass_g))
adat <- adat[!is.na(adat$mass_g) & adat$mass_g > 0, ]
unknown <- setdiff(unique(adat$group), c('Prokaryotes', 'Protists', 'Metazoans'))
if (length(unknown) > 0) stop('DeLong_etal_2010: unexpected group(s): ', paste(unknown, collapse = ', '))

# ---- 1. Dataset S2 metazoans: micrograms -> grams (issue #13) -----------------
sd02_metazoa <- adat$dataset == 'sd02' & adat$group == 'Metazoans'
if (sum(sd02_metazoa) != 16)
  stop('DeLong_etal_2010: expected the 16 Savage et al. (2004) metazoan rows of sd02.csv, found ',
       sum(sd02_metazoa))
adat$mass_g[sd02_metazoa] <- adat$mass_g[sd02_metazoa] * 1e-6

# ---- 2. Dataset S1 Entamoeba active-rate row: 1e3 unit slip, dropped ---------
entamoeba_active <- adat$dataset == 'sd01' & adat$rate_type %in% 'active' &
  adat$taxon == 'Entamoeba hystolitica'
if (sum(entamoeba_active) != 1)
  stop('DeLong_etal_2010: expected one active-rate Entamoeba hystolitica row in sd01.csv, found ',
       sum(entamoeba_active))
adat <- DropImputed(adat, entamoeba_active, 'DeLong_etal_2010',
                    'sd01 active-rate Entamoeba hystolitica row 1e3 above the endogenous-rate row of the same species (unit slip)')

# ---- 3. Plausibility guard ---------------------------------------------------
# Group ceilings in grams: the largest fish in these tables is a 15 kg cod,
# the largest metazoan a 700 g lobster (Jasus edwardsii), the largest protist
# a 2.2e-4 g Noctiluca miliaris and the largest prokaryote a 3.6e-11 g
# Amoebobacter purpureus. A factor-1e3 slip in any group crosses its ceiling.
fish_genera <- c('Alburnus', 'Etheostoma', 'Gadus', 'Gobio', 'Hippoglossoides',
                 'Leuciscus', 'Pimephales', 'Pagrus', 'Solea')
genus   <- sub('[ _].*$', '', adat$taxon)
too_big <- (genus %in% fish_genera   & adat$mass_g > 1e6)  |
           (adat$group == 'Metazoans'   & adat$mass_g > 2e8)  |
           (adat$group == 'Protists'    & adat$mass_g > 1e-2) |
           (adat$group == 'Prokaryotes' & adat$mass_g > 1e-9)
if (any(too_big))
  stop('DeLong_etal_2010: implausible body mass (unit error?): ',
       paste(sprintf('%s %s %.3g g', adat$dataset[too_big], adat$taxon[too_big],
                     adat$mass_g[too_big]), collapse = '; '))

adat$n <- 1
adat$source_mass <- 'DeLong_etal_2010'
DLa <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'dataset', 'group')]
save(DLa, file = file.path(wd_rdata, 'BodyMass_DeLong_etal_2010.Rdata'))
