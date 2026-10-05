# Kiørboe (2013) Limnology and Oceanography 58:1843-1850, Web Appendix Table A1:
# per-record wet, dry and carbon masses (mg) of marine zooplankton and protists
# compiled from 18 literature sources. The parsed table (Kiorboe2013_TableA1.csv) is
# kept in this folder; a copy also sits in sources/conversion_factors/Kiorboe_2013,
# where it supplies the zooplankton conversion factors. Wet mass is used where reported; otherwise
# dry mass, then carbon mass, is converted to wet grams with the group factors in
# R/library/mass_conversion.r. Protist 'wet mass' in the source is cell volume at
# density 1; gastropod wet mass includes the shell.
# Juvenile stages (copepodite CI-CV, Roman-numeral stages below VI, larvae, juv) are
# dropped; adult markers (female, male, CVI/VI, aggregate, solitary) are stripped.
a1_path <- file.path(wd_source, 'Kiorboe2013_TableA1.csv')
adat <- read.csv(a1_path, header = TRUE, check.names = FALSE, stringsAsFactors = FALSE,
                 na.strings = c('', 'NA'), encoding = 'UTF-8')
Num <- function(x) suppressWarnings(as.numeric(gsub('[−–]', '-', x)))
adat$wet <- Num(adat[['Wet mass (mg)']]) / 1000
adat$dry <- Num(adat[['Dry mass (mg)']]) / 1000
adat$carb <- Num(adat[['C (mg)']]) / 1000
sp <- trimws(adat$Species)
juv <- grepl('\\b(C?I{1,3}|C?IV|CV|V|V\\+VI|juv|larva[e]?|naupli[a-z]*|zoea|megalopa|mysis|furcilia|calyptopis|cypris|veliger|Polychaet)\\b', sp, ignore.case = TRUE) &
       !grepl('\\b(CVI|VI)\\b', sp)
adat <- adat[!juv, ]; sp <- sp[!juv]
sp <- gsub('\\b(female|male|aggregate|solitary|adult|CVI|VI|CV\\+VI|V\\+VI)\\b', '', sp)
sp <- gsub('\\s+', ' ', trimws(sp))
sp <- sub('^([a-z])', '\\U\\1', sp, perl = TRUE)                       # 'sagitta elegans'
sp <- sub('^([A-Z][a-z]+) ([A-Z])', '\\1 \\L\\2', sp, perl = TRUE)      # 'Salpa Thompsoni'
adat$taxon <- sp
adat <- adat[grepl('^[A-Z][a-z]+ [a-z]+$', adat$taxon) & !grepl('\\b(sp|spp|cf|aff)\\b', adat$taxon), ]
group_map <- c(Copepoda = 'crustacean_zooplankton', Euphausiacea = 'crustacean_zooplankton',
               Amphipoda = 'crustacean_zooplankton', Decapoda = 'crustacean_zooplankton',
               Mysidacea = 'crustacean_zooplankton', Ostracoda = 'crustacean_zooplankton',
               Cumacea = 'crustacean_zooplankton', Isopoda = 'crustacean_zooplankton',
               Stomatopoda = 'crustacean_zooplankton', Tanaidacea = 'crustacean_zooplankton',
               Cnidaria = 'gelatinous_zooplankton', Ctenophora = 'gelatinous_zooplankton',
               Tunicata = 'gelatinous_zooplankton', Protista = 'protist',
               Chaetognatha = 'chaetognath', Gastropoda = 'mollusc', Bivalvia = 'mollusc',
               Cephalopoda = 'mollusc', Polychaeta = 'annelid', Phoronida = 'invertebrate')
unknown <- setdiff(unique(adat$Group), names(group_map))
if (length(unknown) > 0) stop('Kiorboe_2013: unmapped group(s): ', paste(unknown, collapse = ', '))
grp <- unname(group_map[adat$Group])
# prefer wet > dry > carbon
from <- ifelse(!is.na(adat$wet), 'wet', ifelse(!is.na(adat$dry), 'dry', ifelse(!is.na(adat$carb), 'carbon', NA)))
val  <- ifelse(from == 'wet', adat$wet, ifelse(from == 'dry', adat$dry, adat$carb))
keep <- !is.na(from) & !is.na(val) & val > 0
adat <- adat[keep, ]; grp <- grp[keep]; from <- from[keep]; val <- val[keep]
adat$mass_g <- ToWetMass(val, from = from, group = grp)
lab <- ifelse(from == 'wet', 'Kiorboe_2013', LabelWithConversion('Kiorboe_2013', grp))
# drop a self-citation token when the conversion reference is the source itself
lab <- vapply(strsplit(lab, ';', fixed = TRUE), function(t) paste(unique(trimws(t)), collapse = '; '), '')
adat$n <- 1
adat$source_mass <- lab
# The per-record reference number (1-18) of Table A1, resolved in
# Kiorboe2013_TableA1_references.csv, is kept as `ref_keys` for the
# primary-source attribution of issue #1 (SplitRefKeys(), R/library/citations/).
adat$ref_keys <- SplitRefKeys(adat$Reference, ';')
if (anyNA(adat$ref_keys)) warning('Kiorboe_2013: ', sum(is.na(adat$ref_keys)), ' record(s) without a reference number')
KIO13 <- adat[, c('taxon', 'mass_g', 'n', 'source_mass', 'ref_keys')]
save(KIO13, file = file.path(wd_rdata, 'BodyMass_Kiorboe_2013.Rdata'))
