# Tests for the non-taxon labels of R/library/fix_nontaxa.r added by #44: the
# COMBINE placeholder 'Not recognised', the fragment / immature group labels of
# Hrycik_2024, the bare VertNet placeholders and the one-token functional-group
# words and common names that the food-web compilations use as names (which
# RunMe.r would otherwise file as genus-level records). Each is removed by
# RemoveNonTaxa() after the real cleaning chain; genuine genera that merely
# fail to resolve (Amphinemura, Caroperla, ...) and Latin names of ranks above
# genus are kept; every quoted entry of the file removes itself. No network
# access, no cached frames and no packages beyond base R are needed.
#
#   Rscript R/library/tests/test_nontaxa_labels.R      (from any directory)
#
# Prints one line per expectation and exits with status 1 if any failed.

this_file <- sub('^--file=', '', grep('^--file=', commandArgs(), value = TRUE))
if (length(this_file) == 0)         # sourced interactively from the repo root
  this_file <- file.path('R', 'library', 'tests', 'test_nontaxa_labels.R')
repo <- normalizePath(file.path(dirname(this_file), '..', '..', '..'))
lib  <- file.path(repo, 'R', 'library')
source(file.path(lib, 'helpers.r'))               # DropImputed(), imputed_log
source(file.path(lib, 'fix_formatting.r'))
source(file.path(lib, 'fix_misspellings.r'))
source(file.path(lib, 'fix_nontaxa.r'))
raw_name_patterns <- LoadRawNamePatterns(file.path(repo, 'audit', 'raw_name_patterns.csv'))

failures <- character(0)
n_checks <- 0L
Expect <- function(ok, what) {
  n_checks <<- n_checks + 1L
  if (!isTRUE(ok)) failures <<- c(failures, what)
  cat(sprintf('  %s %s\n', if (isTRUE(ok)) 'ok  ' else 'FAIL', what))
}
Frame <- function(taxon, source = 'SrcA')
  data.frame(taxon = taxon, mass_g = seq_along(taxon), n = 1, source_mass = source, stringsAsFactors = FALSE)
# The chain of RunMe.r section 2b on raw names: FixFormatting, FixMisspellings, RemoveNonTaxa.
Chain <- function(taxon, source = 'SrcA') {
  raw_name_log <<- list(); imputed_log <<- list()
  RemoveNonTaxa(FixMisspellings(suppressMessages(FixFormatting(Frame(taxon, source)))))
}
Cleaned <- function(taxon) { raw_name_log <<- list(); imputed_log <<- list(); suppressMessages(FixFormatting(Frame(taxon)))$taxon }

# ---- the labels as the sources write them --------------------------------------
cat('raw labels of #44 through the cleaning chain\n')
Expect(identical(Cleaned(c('Not recognised', 'Oligochaeta Fragments', 'Tubificid fragment', 'Naidid fragment', 'Oligochaeta immature')),
                 c('Not_recognised', 'Oligochaeta_fragments', 'Tubificid_fragment', 'Naidid_fragment', 'Oligochaeta_immature')),
       'FixFormatting() leaves the COMBINE and Hrycik labels as two-token names (the forms the unresolved-names report listed)')
Expect(nrow(Chain('Not recognised', 'Soria_etal_2021')) == 0, "'Not recognised' (Soria_etal_2021) is removed")
hry <- c('Oligochaeta Fragments', 'Tubificid fragment', 'Naidid fragment', 'Oligochaeta immature',
         'Enchytraeid fragment', 'Lumbriculid fragment', 'Immature lumbriculid')
Expect(nrow(Chain(hry, 'Hrycik_2024')) == 0,
       'the four Hrycik_2024 fragment / immature labels and the three siblings of its SpeciesList.csv are removed')
Expect(nrow(Chain(c('Undefinable', 'Unidentifiable'), 'vertnet-traits-sept2016')) == 0,
       "the bare VertNet placeholders 'Undefinable' and 'Unidentifiable' are removed")
words <- c('bacteria', 'Bacteria', 'amoebae', 'plankton', 'Ciliates', 'Flagellates', 'Diatoms', 'Rotifers', 'algae', 'Fungi',
           'PhytoP', 'Microfauna', 'lemmings', 'waterfowl', 'Shorebirds', 'Nematodes', 'NonOribatida', 'Crabs', 'Shrimps',
           'Chambo', 'Mbuna', 'Usipa', 'Nkhono')
Expect(nrow(Chain(words, 'Brose_etal_2018')) == 0,
       'the Brose_etal_2018 functional-group words and Lake Malawi common names are removed, whatever their case')
Expect(nrow(Chain(c('Scuticociliate', 'Cryptophyte', 'Eubactaria', 'Fish', 'Herring', 'Insect'),
                  c('DeLong_etal_2010', 'DeLong_etal_2018', 'DeLong_etal_2018', 'Raymond_2011', 'Brose_2005', 'Hirt_etal_2017'))) == 0,
       'the one-row labels of the other sources are removed')

# ---- what must survive ------------------------------------------------------------
cat('genuine names are kept\n')
genera <- c('Amphinemura', 'Caroperla', 'Kiotina', 'Paragnetina', 'Stavsolus', 'Evermannella',
            'Hydra', 'Octopus', 'Amoeba', 'Natrix', 'Fridericia', 'Lagopus', 'Draco', 'Thalia', 'Lemmus')
Expect(identical(Chain(genera)$taxon, genera),
       'genuine genera that merely failed to resolve or share a vernacular stem (Amphinemura, Hydra, Octopus, Amoeba, Lemmus) are kept')
ranks <- c('Oligochaeta', 'Chironomidae', 'Araneae', 'Cyanobacteria', 'Insecta', 'Copepoda', 'Polychaeta', 'Nemertea')
Expect(identical(Chain(ranks)$taxon, ranks),
       'Latin names of ranks above genus are taxa and are not touched (their fate is a separate decision)')
species <- c('Gnathophausia zoea', 'Trypoxylon medium', 'Laeonereis fragilis', 'Clubiona juvenis', 'Nausithoe rubra')
Expect(identical(Chain(species)$taxon, c('Gnathophausia_zoea', 'Trypoxylon_medium', 'Laeonereis_fragilis', 'Clubiona_juvenis', 'Nausithoe_rubra')),
       'species whose epithet resembles a stage or group word are kept; _fragment(s) and _immature(s) match whole epithets only')
Expect(identical(RemoveNonTaxa(Frame(c('Canis_undefinable', 'Immaturus_rex')))$taxon, c('Canis_undefinable', 'Immaturus_rex')),
       'the placeholder rule is anchored at the start of the name and the Immature_ rule needs the underscore')

# ---- every quoted entry of the file removes itself ----------------------------------
cat('static check of the entries\n')
txt <- readLines(file.path(lib, 'fix_nontaxa.r'), warn = FALSE)
m <- regmatches(txt, regexec('^\\s*"([^"]+)"\\s*,?\\s*(#.*)?$', txt))
ents <- unlist(lapply(m, function(x) if (length(x) >= 2) x[2] else character(0)))
Expect(length(ents) > 170, sprintf('%d entries read from fix_nontaxa.r', length(ents)))
left <- RemoveNonTaxa(Frame(ents))$taxon
Expect(length(left) == 0, paste('every entry is removed when fed as a cleaned name:', paste(left, collapse = ', ')))
Expect(all(c('Not_recognised', 'Bacteria', 'Amoebae', 'Plankton', 'PhytoP', 'Mbuna', 'Scuticociliate') %in% ents),
       'the #44 entries are present')
i_fg <- grep('^\\s*functional_groups <- c\\(', txt)
Expect(length(i_fg) == 1 && any(grepl('tolower\\(functional_groups\\)', txt)),
       'the functional_groups vector exists and enters the lowercased match')

cat(sprintf('\n%d checks, %d failed\n', n_checks, length(failures)))
if (length(failures)) { cat(paste0('  FAIL ', failures, '\n'), sep = ''); quit(status = 1) }
