FixTaxonomyRanks <- function(dat) {
  rank_cols <- c('kingdom', 'phylum', 'class', 'order', 'family', 'genus')

  # Part 0 ── Empty-string normalization
  # Some API responses write '' instead of NA for missing ranks. These pass
  # is.na() checks and prevent rank inference from identifying unambiguous
  # mappings (e.g. all squamate families blocked from order→Squamata inference
  # by a handful of empty-string entries). Convert to NA across all rank columns.
  for (col in intersect(rank_cols, names(dat))) {
    dat[[col]][!is.na(dat[[col]]) & dat[[col]] == ''] <- NA_character_
  }

  # Part 1 ── Class synonym normalization
  # Different taxonomic authorities and API versions use alternate names for the
  # same class. Normalize to the form used by the GBIF backbone majority.
  class_synonyms <- c(
    'Actinopteri'  = 'Actinopterygii',  # GBIF backbone current name; older literature uses Actinopterygii
    'Teleostei'    = 'Actinopterygii',  # Teleostei is an infraclass/cohort, not a class-rank taxon
    'Lepidosauria' = 'Reptilia',        # NCBI uses Lepidosauria as class; GBIF uses Reptilia
    'Squamata'     = 'Reptilia'         # Squamata is an order; appears as class in some source records
  )
  if ('class' %in% names(dat)) {
    for (old in names(class_synonyms)) {
      idx <- !is.na(dat$class) & dat$class == old
      if (any(idx)) dat$class[idx] <- class_synonyms[[old]]
    }
  }

  # Part 2 ── Cross-kingdom noise clearing
  # A small number of animal taxa have plant class values (Magnoliopsida; the
  # snake Calamaria muelleri carried Lycopodiopsida, found by the inverse scan
  # of #81) in source records, presumably from join artifacts. Clear these so
  # rank inference can fill them from the correct order mapping.
  if (all(c('kingdom', 'class') %in% names(dat))) {
    noise_idx <- !is.na(dat$kingdom) & !is.na(dat$class) &
      dat$kingdom %in% c('Animalia', 'Chromista', 'Fungi', 'Protozoa') &
      dat$class %in% c('Magnoliopsida', 'Liliopsida', 'Lycopodiopsida',
                       'Pinopsida', 'Polypodiopsida')
    if (any(noise_idx)) dat$class[noise_idx] <- NA_character_
  }

  # Part 2b ── Cross-kingdom conflicts (#81)
  # An authority matched the name to a plant, alga or fungus while the lower
  # ranks are an animal's. Two ways: an exact homonym in two kingdoms, where
  # GBIF abstains (matchType NONE) and NCBI's first row is the plant (Myrmecia
  # pyriformis, the bull ant and a green alga; Centropogon australis, the
  # fortescue and a campanula), or a GBIF fuzzy match below confidence 90 into
  # the other kingdom (Parus humilis -> Pyrus humilis = Cotoneaster humilis).
  # Both stages fill NA ranks only (as does the COL stage, #103, whose exact
  # match of a cross-kingdom homonym lands here the same way), so the
  # source's pre-seeded phylum, class, order and family survive under the
  # plant kingdom; FilterAutotrophs() then
  # dropped the row on the kingdom alone and no report saw it (check 11 of
  # check_enriched() runs on the post-filter frame). Here, on frames with a
  # species column (the enrichment cache; per-source frames and the genus
  # cache are not touched), such a row keeps the animal's ranks: the kingdom
  # the authority returned goes to kingdom_conflict (listed by
  # check_enriched()), kingdom becomes Animalia, the ranks that are not animal
  # ranks (Tracheophyta, Magnoliopsida, Asterales, ...) are cleared for rank
  # inference (RunMe.r) or a Part 7 entry to refill, and the species is kept
  # only when it is the input binomial (the homonym case: NCBI's annotation
  # '(in: green algae)' is stripped). A species of another genus came from the
  # wrong kingdom's authority and is cleared with the genus and the source: the
  # name is then unresolved and listed as such instead of vanishing. A row is
  # a conflict when its phylum or class is in the animal lists below, or its
  # order or family occurs more often under Animalia than under the autotroph
  # kingdoms in the frame (the majority rule keeps a plant class a source wrote
  # on an animal record, Lycopodiopsida, from counting as animal; a row whose
  # only animal rank is a family no other row has is not detected). A rank
  # value is cleared when it is in the plant lists below or occurs under an
  # autotroph kingdom in a row that is no conflict; anything else (the
  # source's family, say) is kept.
  autotroph_kingdoms <- c('Plantae', 'Viridiplantae', 'Fungi')   # as FilterAutotrophs()
  animal_phyla <- c(
    'Acanthocephala', 'Annelida', 'Arthropoda', 'Brachiopoda', 'Bryozoa',
    'Chaetognatha', 'Chordata', 'Cnidaria', 'Ctenophora', 'Cycliophora',
    'Echinodermata', 'Echiura', 'Entoprocta', 'Gastrotricha', 'Gnathostomulida',
    'Hemichordata', 'Kinorhyncha', 'Loricifera', 'Micrognathozoa', 'Mollusca',
    'Nematoda', 'Nematomorpha', 'Nemertea', 'Onychophora', 'Orthonectida',
    'Phoronida', 'Placozoa', 'Platyhelminthes', 'Porifera', 'Priapulida',
    'Rhombozoa', 'Rotifera', 'Sipuncula', 'Tardigrada', 'Xenacoelomorpha'
  )
  animal_classes <- c(
    'Actinopterygii', 'Amphibia', 'Anthozoa', 'Arachnida', 'Ascidiacea',
    'Asteroidea', 'Aves', 'Bivalvia', 'Branchiopoda', 'Cephalopoda',
    'Chilopoda', 'Chondrichthyes', 'Clitellata', 'Collembola', 'Copepoda',
    'Crinoidea', 'Demospongiae', 'Diplopoda', 'Echinoidea', 'Elasmobranchii',
    'Entognatha', 'Gastropoda', 'Hexanauplia', 'Holocephali', 'Holothuroidea',
    'Hydrozoa', 'Insecta', 'Malacostraca', 'Mammalia', 'Maxillopoda',
    'Monogononta', 'Myxini', 'Ophiuroidea', 'Ostracoda', 'Petromyzonti',
    'Polychaeta', 'Polyplacophora', 'Pycnogonida', 'Reptilia', 'Scyphozoa',
    'Thecostraca', 'Trematoda', 'Cestoda', 'Turbellaria', 'Rhabditophora',
    'Chromadorea', 'Enoplea', 'Eutardigrada', 'Heterotardigrada', 'Gymnolaemata'
  )
  autotroph_phyla <- c(                                          # the algal phyla of FilterAutotrophs() and the land plant and fungal phyla
    'Ochrophyta', 'Bacillariophyta', 'Haptophyta', 'Cryptophyta', 'Chlorophyta',
    'Rhodophyta', 'Charophyta', 'Glaucophyta', 'Streptophyta', 'Euglenophyta',
    'Cyanobacteria', 'Cyanobacteriota', 'Tracheophyta', 'Magnoliophyta',
    'Bryophyta', 'Marchantiophyta', 'Anthocerotophyta', 'Pteridophyta',
    'Pinophyta', 'Ascomycota', 'Basidiomycota', 'Mucoromycota', 'Chytridiomycota'
  )
  autotroph_classes <- c(
    'Magnoliopsida', 'Liliopsida', 'Lycopodiopsida', 'Pinopsida', 'Polypodiopsida',
    'Bryopsida', 'Equisetopsida', 'Trebouxiophyceae', 'Chlorophyceae', 'Ulvophyceae',
    'Florideophyceae', 'Bangiophyceae', 'Klebsormidiophyceae', 'Zygnematophyceae',
    'Charophyceae', 'Phaeophyceae', 'Bacillariophyceae', 'Agaricomycetes',
    'Sordariomycetes', 'Dothideomycetes', 'Lecanoromycetes', 'Eurotiomycetes'
  )
  if (all(c('kingdom', 'species') %in% names(dat))) {
    if (!'kingdom_conflict' %in% names(dat)) dat$kingdom_conflict <- NA_character_
    lower <- intersect(c('phylum', 'class', 'order', 'family'), names(dat))
    is_animal    <- !is.na(dat$kingdom) & dat$kingdom == 'Animalia'
    is_autotroph <- !is.na(dat$kingdom) & dat$kingdom %in% autotroph_kingdoms
    animal_vals <- lapply(setNames(lower, lower), function(r) {
      n_animal <- table(dat[[r]][is_animal]); n_auto <- table(dat[[r]][is_autotroph])
      n_auto_of <- n_auto[names(n_animal)]; n_auto_of[is.na(n_auto_of)] <- 0L
      unique(c(names(n_animal)[n_animal > n_auto_of],
               if (r == 'phylum') animal_phyla else if (r == 'class') animal_classes))
    })
    has_animal_rank <- Reduce(`|`, lapply(lower, function(r)
      !is.na(dat[[r]]) & dat[[r]] %in% animal_vals[[r]]), init = rep(FALSE, nrow(dat)))
    conflict <- which(is_autotroph & has_animal_rank)
    if (length(conflict) > 0) {
      plain_autotroph <- is_autotroph; plain_autotroph[conflict] <- FALSE
      plant_vals <- lapply(setNames(lower, lower), function(r)
        unique(c(na.omit(dat[[r]][plain_autotroph]),
                 if (r == 'phylum') autotroph_phyla else if (r == 'class') autotroph_classes)))
      dat$kingdom_conflict[conflict] <- dat$kingdom[conflict]
      dat$kingdom[conflict]          <- 'Animalia'
      for (r in lower) {
        clear <- conflict[!is.na(dat[[r]][conflict]) & dat[[r]][conflict] %in% plant_vals[[r]]]
        dat[[r]][clear] <- NA_character_
      }
      input    <- if ('taxon_provided' %in% names(dat)) dat$taxon_provided[conflict]
                  else gsub('_', ' ', dat$taxon[conflict])
      binomial <- sub('^([A-Z][a-z]+ [a-z][a-z-]+).*', '\\1', dat$species[conflict])
      keep     <- !is.na(binomial) & !is.na(input) & binomial == input   # the homonym case
      dat$species[conflict[keep]] <- binomial[keep]
      if ('genus' %in% names(dat)) dat$genus[conflict[keep]] <- sub(' .*', '', binomial[keep])
      gone <- conflict[!keep]
      dat$species[gone] <- NA_character_
      for (col in intersect(c('genus', 'taxonomy_source'), names(dat))) dat[[col]][gone] <- NA_character_
      if ('species_changed' %in% names(dat)) dat$species_changed[conflict] <- FALSE
    }
  }

  # Part 3 ── Order-level class fills
  # Some orders have no anchor taxa in the cache with class set, so rank
  # inference cannot fill them. Values verified against NCBI Taxonomy and GBIF.
  order_class_fills <- c(
    # Fish orders where GBIF backbone lacks class anchor taxa
    'Amiiformes'         = 'Actinopterygii',
    'Gobiesociformes'    = 'Actinopterygii',
    'Aulopiformes'       = 'Actinopterygii',
    'Batrachoidiformes'  = 'Actinopterygii',
    'Osmeriformes'       = 'Actinopterygii',
    # Flatworms — order present in cache but class missing (GBIF backbone gap)
    'Tricladida'         = 'Rhabditophora',
    # Nematodes — GBIF backbone omits class for these orders
    'Dorylaimida'        = 'Enoplea',
    'Triplonchida'       = 'Enoplea',
    'Enoplida'           = 'Enoplea',
    'Mononchida'         = 'Enoplea',
    # Flatworms — Prolecithophora is within class Rhabditophora; GBIF backbone omits class for this order
    'Prolecithophora'    = 'Rhabditophora'
  )
  if (all(c('order', 'class') %in% names(dat))) {
    for (ord in names(order_class_fills)) {
      fill_idx <- !is.na(dat$order) & dat$order == ord & is.na(dat$class)
      if (any(fill_idx)) dat$class[fill_idx] <- order_class_fills[[ord]]
    }
  }

  # Part 4 ── Family-level order fills
  # Families whose order is absent from GBIF backbone AND no anchor taxa exist
  # anywhere in the cache to allow inference. Values sourced from NCBI Taxonomy
  # and WoRMS; only fills NA slots.
  family_order_fills <- c(
    # Polychaeta — GBIF backbone omits order for these benthic worm families
    'Spionidae'        = 'Spionida',
    'Ampharetidae'     = 'Terebellida',
    'Flabelligeridae'  = 'Terebellida',   # NCBI Terebellida; traditional Flabelligerida
    'Orbiniidae'       = 'Orbiniida',
    'Terebellidae'     = 'Terebellida',
    'Maldanidae'       = 'Capitellida',
    'Pectinariidae'    = 'Terebellida',
    'Capitellidae'     = 'Capitellida',
    # Gastropoda — order missing for these families across all APIs
    'Lottiidae'        = 'Patellogastropoda',
    'Patellidae'       = 'Patellogastropoda',
    'Lymnaeidae'       = 'Hygrophila',
    'Planorbidae'      = 'Hygrophila',
    'Limapontiidae'    = 'Sacoglossa',
    # Ophiuroidea — GBIF backbone uses Amphilepidida (confirmed NCBI + 7 cache anchors)
    'Ophiuridae'       = 'Amphilepidida',
    'Ophiopyrgidae'    = 'Amphilepidida',
    # Additional Gastropoda — all confirmed via NCBI Taxonomy
    'Nacellidae'       = 'Patellogastropoda',  # Nacella spp.
    'Lepetidae'        = 'Patellogastropoda',  # Lepeta caeca
    'Acroloxidae'      = 'Hygrophila',         # Acroloxus lacustris
    'Physidae'         = 'Hygrophila',         # Physa fontinalis
    'Elysiidae'        = 'Sacoglossa',         # Elysia spp.
    'Hermaeididae'     = 'Sacoglossa',         # Hermaea cruciata
    'Epitoniidae'      = 'Caenogastropoda',    # Epitonium spp.
    'Cerithiidae'      = 'Caenogastropoda',    # Cerithium atratum
    'Potamididae'      = 'Caenogastropoda',    # Cerithidea, Telescopium
    # Additional Polychaeta — confirmed via NCBI Taxonomy and WoRMS
    'Arenicolidae'     = 'Capitellida',        # Arenicola marina
    'Chaetopteridae'   = 'Chaetopterida',      # Chaetopterus, Spiochaetopterus
    'Cirratulidae'     = 'Cirratulida',        # Cirratulus cirratus
    'Trichobranchidae' = 'Terebellida',        # Terebellides stroemi
    # Amoebozoa (Tubulinea)
    'Hartmannellidae'    = 'Tubulinida',         # Glaeseria mira
    # Squamata — GBIF backbone lacks order for all Scincidae genera (covers 69 species in warnings)
    'Scincidae'          = 'Squamata',
    # Ceriantharia — tube anemones; GBIF backbone omits order for Cerianthidae across all APIs
    'Cerianthidae'       = 'Ceriantharia',
    # Omalogyroida — minute heterobranch marine gastropods; order absent from GBIF backbone (per WoRMS)
    'Omalogyridae'       = 'Omalogyroida',
    # Tritrichomonadida — covers Tritrichomonas suis (= T. foetus synonym); order absent from GBIF backbone
    'Tritrichomonadidae' = 'Tritrichomonadida'
  )
  if (all(c('family', 'order') %in% names(dat))) {
    for (fam in names(family_order_fills)) {
      fill_idx <- !is.na(dat$family) & dat$family == fam & is.na(dat$order)
      if (any(fill_idx)) dat$order[fill_idx] <- family_order_fills[[fam]]
    }
  }

  # Part 5 ── Manual species-level fills
  # Fringe taxa for which all six enrichment APIs return incomplete classification.
  # Values sourced from NCBI Taxonomy and GBIF backbone; only fills NA slots.
  #
  # Plasmodium spp.: kingdom absent from GBIF and NCBI for these avian/primate
  # malaria parasites; phylum–family confirmed via NCBI (Sayers 2022).
  # Vexillifera bacillipedes: kingdom='Protozoa' consistent with GBIF's treatment
  # of Discosea (cf. Acanthamoeba castellanii kingdom in GBIF backbone).
  # Corythion dubium: phylum='Cercozoa' consistent with GBIF class=Filosia
  # (Filosia is a class within Cercozoa) and confirmed by NCBI.
  manual_fills <- list(
    'Plasmodium cathemerium'   = c(kingdom = 'Chromista',   phylum = 'Apicomplexa',
                                   class   = 'Aconoidasida', order  = 'Haemosporida',
                                   family  = 'Plasmodiidae'),
    'Plasmodium gallinaceum'   = c(kingdom = 'Chromista',   phylum = 'Apicomplexa',
                                   class   = 'Aconoidasida', order  = 'Haemosporida',
                                   family  = 'Plasmodiidae'),
    'Plasmodium knowlesi'      = c(kingdom = 'Chromista',   phylum = 'Apicomplexa',
                                   class   = 'Aconoidasida', order  = 'Haemosporida',
                                   family  = 'Plasmodiidae'),
    'Vexillifera bacillipedes' = c(kingdom = 'Protozoa',   phylum = 'Discosea',
                                   class   = 'Flabellinia', order = 'Dactylopodida',
                                   family  = 'Vexilliferidae'),
    'Corythion dubium'         = c(phylum = 'Cercozoa'),
    # Bigyra/Bicosoecida flagellates — class absent from GBIF backbone
    'Caecitellus parvulus'     = c(class = 'Bicoecea',           order = 'Anoecida'),
    'Cafeteria roenbergensis'  = c(class = 'Stramenopiles',      order = 'Bicosoecida'),
    'Pseudobodo tremulans'     = c(class = 'Bicosoecophyceae',   order = 'Caecitellales'),
    # Priapulida — two classes within the phylum
    'Halicryptus spinulosus'   = c(class = 'Halicryptomorpha'),
    'Priapulus caudatus'       = c(class = 'Priapulimorphida'),
    # Cyanobacteria — class absent from GBIF backbone
    'Coelosphaerium pallidum'  = c(class = 'Cyanophyceae',  order = 'Synechococcales'),
    'Rhabdoderma lineare'      = c(class = 'Cyanophyceae',  order = 'Synechococcales'),
    # Foraminifera — class absent from GBIF backbone
    'Lenticulina antarctica'   = c(class = 'Nodosariata'),
    'Reticulammina labyrinthica' = c(class = 'Monothalamea', order = 'Psamminida'),
    # Barnacle — order and class both absent from all APIs
    'Austrominius modestus'    = c(class = 'Thecostraca',   order = 'Sessilia'),
    # Heterolobosea amoebas — phylum Percolozoa omitted by GBIF backbone
    'Vahlkampfia baltica'      = c(kingdom = 'Protozoa',    phylum = 'Percolozoa',
                                   class   = 'Heterolobosea', order = 'Acrasida'),
    'Vahlkampfia damariscottae' = c(kingdom = 'Protozoa',  phylum = 'Percolozoa',
                                    class   = 'Heterolobosea', order = 'Acrasida'),
    # Gastropoda — order absent from all APIs for these species
    'Acroloxus lacustris'       = c(order = 'Hygrophila'),
    'Bittiolum varium'          = c(order = 'Caenogastropoda'),
    'Boonea jadisi'             = c(order = 'Pyramidellida'),
    'Cerithidea californica'    = c(order = 'Caenogastropoda'),
    'Cerithiopsis tubercularis' = c(order = 'Caenogastropoda'),
    'Cerithium atratum'         = c(order = 'Sorbeoconcha'),
    'Elysia catula'             = c(order = 'Sacoglossa'),
    'Elysia chlorotica'         = c(order = 'Sacoglossa'),
    'Erginus rubellus'          = c(order = 'Nacellida'),
    'Hermaea cruciata'          = c(order = 'Sacoglossa'),
    'Lepeta caeca'              = c(order = 'Patellogastropoda'),
    'Menestho albula'           = c(order = 'Pyramidellida'),
    'Menestho truncatula'       = c(order = 'Heterobranchia'),
    'Nacella concinna'          = c(order = 'Patellogastropoda'),
    'Nacella delesserti'        = c(order = 'Patellogastropoda'),
    'Physa fontinalis'          = c(order = 'Basommatophora'),
    'Telescopium telescopium'   = c(order = 'Caenogastropoda'),
    'Valvata piscinalis'        = c(order = 'Ectobranchia'),
    # Bivalvia — order absent from all APIs for these species
    'Laternula elliptica'       = c(order = 'Anomalodesmata'),
    'Lyonsia arenosa'           = c(order = 'Anomalodesmata'),
    'Pandora glacialis'         = c(order = 'Anomalodesmata'),
    'Pandora gouldiana'         = c(order = 'Pandorida'),
    'Thracia myopsis'           = c(order = 'Thraciida'),
    # Polychaeta — order absent from all APIs for these species
    'Arenicola marina'          = c(order = 'Scolecida'),
    'Chaetopterus variopedatus' = c(order = 'Spionida'),
    'Cirratulus cirratus'       = c(order = 'Terebellida'),
    'Cossura longocirrata'      = c(order = 'Cossurida'),
    'Levinsenia gracilis'       = c(order = 'Scolecida'),
    'Spiochaetopterus oculatus' = c(order = 'Canalipalpata'),
    'Terebellides stroemi'      = c(order = 'Terebellida'),
    # Nemertea — order absent from all APIs for these species
    'Carinoma mutabilis'        = c(order = 'Carinomiformes'),
    'Carinoma tremaphorus'      = c(order = 'Palaeonemertea'),
    # Ceriantharia — order absent from all APIs; GBIF resolves to 'Ceriantheopsis americana' (not -us)
    'Ceriantheopsis americana'  = c(order = 'Ceriantharia'),
    # Platyhelminthes — order absent from all APIs for these species
    'Euplana gracilis'          = c(order = 'Polycladida'),
    'Stenostomum virginianum'   = c(order = 'Catenulida'),
    'Stylochus ellipticus'      = c(order = 'Polycladida'),
    # Amoebozoa — order and family absent from all APIs; key was 'Glaseria mira' (typo) in prior versions
    'Glaeseria mira'            = c(order = 'Tubulinida', family = 'Hartmannellidae'),
    # Aves — order absent from all APIs
    'Dendrocopus major'         = c(order = 'Piciformes'),
    # Kinetoplastida — GBIF misresolved Trypanosoma lewisi to Pleurocera acuta (gastropod); handled
    # by Part 7 taxon overwrite instead; Tritrichomonas foetus synonymized to T. suis by GBIF
    'Tritrichomonas suis'       = c(order = 'Tritrichomonadida'),
    # Pylopulmonata — freshwater gastropod; GBIF synonymized Spiralinella → Spiralina spiralis
    'Spiralina spiralis'        = c(order = 'Pylopulmonata'),
    # Myriapoda — order absent from all APIs
    'Scutigerella immaculata'   = c(order = 'Scutigerellida'),
    # Bryozoa / Amoebozoa — family absent from all APIs
    'Austroflustra vulgaris'   = c(family = 'Flustridae'),
    'Chaos carolinense'        = c(family = 'Amoebidae'),
    # Phoronida — GBIF backbone defines no class or order for this phylum; ITIS uses Phoronidea/Phoronida
    'Phoronis psammophila'     = c(class = 'Phoronidea',   order = 'Phoronida'),
    # Aves — GBIF backbone match returned only Animalia root (matchType=HIGHERRANK); genus left NA by all APIs
    'Orthorhynchus cristatus'  = c(genus = 'Orthorhynchus', class = 'Aves',
                                   order = 'Apodiformes',   family = 'Trochilidae'),
    'Cephalodiscus gilchristi' = c(order = 'Cephalodiscida')
  )
  if ('species' %in% names(dat)) {
    for (sp_name in names(manual_fills)) {
      idx <- which(!is.na(dat$species) & dat$species == sp_name)
      if (length(idx) == 0) next
      fill <- manual_fills[[sp_name]]
      for (rk in names(fill)) {
        if (rk %in% names(dat))
          dat[[rk]][idx[is.na(dat[[rk]][idx])]] <- fill[[rk]]
      }
    }
  }

  # Part 6 ── Explicit genus overwrites
  # For species where the taxonomy API returned an incorrect/outdated genus
  # (non-NA, so Part 5 NA-fills do not apply) but the species name is correct.
  # Only the genus column is overwritten; other ranks are left unchanged.
  genus_overwrites <- list(
    # Physosterna is accepted per GBIF/CoL; API returns Adesmia (junior synonym)
    'Physosterna cribripes'  = 'Physosterna',
    # Turrum reinstated by Kimura et al. (2022); API returns Carangoides
    'Turrum gymnostethus'    = 'Turrum',
    # Palaeoloxodon accepted per GBIF/Wikispecies; API returns Elephas
    'Palaeoloxodon naumanni' = 'Palaeoloxodon',
    # Paranotropis accepted per AFS 2023/ITIS; API returns Notropis (outdated)
    'Paranotropis volucellus' = 'Paranotropis',
    # Lythrichthys resurrected by Wada et al. (2021); API returns Setarches
    'Lythrichthys longimanus' = 'Lythrichthys',
    # GBIF backbone synonymizes Spreo → Lamprotornis; preserve original to match species prefix
    'Spreo superbus'          = 'Spreo',
    # GBIF backbone places Aegintha temporalis in genus Neochmia; preserve original to match species prefix
    'Aegintha temporalis'     = 'Aegintha'
  )
  if (all(c('species', 'genus') %in% names(dat))) {
    for (sp_name in names(genus_overwrites)) {
      idx <- which(!is.na(dat$species) & dat$species == sp_name)
      if (length(idx) == 0) next
      dat$genus[idx] <- genus_overwrites[[sp_name]]
    }
  }

  # Part 7 ── Full taxonomy overwrites for cross-kingdom mis-resolutions
  # Keyed by the source `taxon` string (Genus_species). Used when an authority
  # matched the name to a homonym in another kingdom, so the species name and
  # every rank are wrong and the Part 5 NA-fills cannot repair them. Only the
  # columns present in `dat` are written, so this is safe both on per-source
  # frames (no species/genus columns) and on the enrichment cache. An entry
  # that sets the kingdom corrects a match to another organism, so the GBIF
  # match fields of the row (confidence, status, usageKey, gbif_family,
  # gbif_order) and the COL match fields (col_match_type, col_status,
  # col_usageKey, col_matched_name; stage 4, #103) are cleared as well: they
  # describe the wrong organism, and Pass 1 of RunMe.r prefers
  # gbif_family/gbif_order over family/order (until #81 Trypanosoma lewisi
  # kept the gastropod family Pleuroceridae in the output this way).
  # species_changed is set from the comparison with the input name, as the
  # enrichment stages do.
  taxon_overwrites <- list(
    # Alligator lizard (Anguidae; Feldman et al. 2016, Meiri 2018). GBIF
    # returned no match and NCBI resolved the name to the plant Abronia villosa
    # var. aurita, yielding Viridiplantae/Streptophyta/Magnoliopsida above the
    # pre-seeded Squamata/Anguidae.
    'Abronia_aurita'      = c(species = 'Abronia aurita', genus = 'Abronia',
                              kingdom = 'Animalia', phylum = 'Chordata',
                              class = 'Reptilia', order = 'Squamata',
                              family = 'Anguidae', taxonomy_source = 'manual'),
    # Trypanosoma lewisi: GBIF backbone misresolved to Pleurocera acuta (Pleuroceridae gastropod) at
    # conf=84 via a homonym match. Correct taxonomy from NCBI: rat kinetoplastid parasite.
    'Trypanosoma_lewisi'       = c(species = 'Trypanosoma lewisi', genus = 'Trypanosoma',
                                   kingdom = 'Protozoa', phylum = 'Euglenozoa',
                                   class = 'Kinetoplastea', order = 'Trypanosomatida',
                                   family = 'Trypanosomatidae', taxonomy_source = 'manual'),
    # Alcippe abyssinica / atriceps: GBIF backbone returned only Animalia root (matchType=HIGHERRANK);
    # accepted genus is Sylvia (Sylviidae) per GBIF search. Species name updated accordingly.
    'Alcippe_abyssinica'       = c(species = 'Sylvia abyssinica', genus = 'Sylvia',
                                   class = 'Aves', order = 'Passeriformes',
                                   family = 'Sylviidae', taxonomy_source = 'manual'),
    'Alcippe_atriceps'         = c(species = 'Sylvia atriceps', genus = 'Sylvia',
                                   class = 'Aves', order = 'Passeriformes',
                                   family = 'Sylviidae', taxonomy_source = 'manual'),
    # Bernieria madagascariensis: species column contains author citation string from source data;
    # strip to canonical binomial so downstream checks and API re-queries work correctly.
    'Bernieria_madagascariensis' = c(species = 'Bernieria madagascariensis',
                                     taxonomy_source = 'manual'),
    # Valid species the GBIF backbone lacks (#85, 2026-10-05): GBIF matches the
    # genus only (matchType HIGHERRANK) and no other stage knows the name, so the
    # record was dropped as unresolved. Ranks from the Catalogue of Life
    # (ChecklistBank dataset 3LR, match/nameusage: status accepted) unless stated.
    # Philorea aracniformis and P. maritima Vidal & Flores 2000 (Physogasterini;
    # Gonzalez_2025, 28 and 13 rows of Gonzalez et al. 2011): the CoL checklist
    # lists aracniformis; maritima is in the ChileFauna catalogue of Chilean
    # Tenebrionidae from the same description; GBIF has the genus (4725706) only.
    'Philorea_aracniformis'    = c(species = 'Philorea aracniformis', genus = 'Philorea',
                                   kingdom = 'Animalia', phylum = 'Arthropoda',
                                   class = 'Insecta', order = 'Coleoptera',
                                   family = 'Tenebrionidae', taxonomy_source = 'manual'),
    'Philorea_maritima'        = c(species = 'Philorea maritima', genus = 'Philorea',
                                   kingdom = 'Animalia', phylum = 'Arthropoda',
                                   class = 'Insecta', order = 'Coleoptera',
                                   family = 'Tenebrionidae', taxonomy_source = 'manual'),
    # Zonateres lanei Bailey, Thomas & da Silva 2005 (Oskyrko_2024, 1 row): CoL accepted.
    'Zonateres_lanei'          = c(species = 'Zonateres lanei', genus = 'Zonateres',
                                   kingdom = 'Animalia', phylum = 'Chordata',
                                   class = 'Reptilia', order = 'Squamata',
                                   family = 'Colubridae', taxonomy_source = 'manual'),
    # Caribicus anelpistus (Schwartz, Graham & Duval 1979) (Feldman_etal_2016, Meiri_2018):
    # the target of the Celestus_anelpistus rule of fix_misspellings.r; GBIF has the
    # genus only (11344845, PROVISIONALLY_ACCEPTED), so the record was lost; CoL accepted.
    'Caribicus_anelpistus'     = c(species = 'Caribicus anelpistus', genus = 'Caribicus',
                                   kingdom = 'Animalia', phylum = 'Chordata',
                                   class = 'Reptilia', order = 'Squamata',
                                   family = 'Diploglossidae', taxonomy_source = 'manual'),
    # Ancylodactylus gigas (Perret 1986) (Meiri_2024, 1 row): CoL accepted.
    'Ancylodactylus_gigas'     = c(species = 'Ancylodactylus gigas', genus = 'Ancylodactylus',
                                   kingdom = 'Animalia', phylum = 'Chordata',
                                   class = 'Reptilia', order = 'Squamata',
                                   family = 'Gekkonidae', taxonomy_source = 'manual'),
    # Urostrophus grilli (Boulenger 1891) (Meiri_2024, 1 row): CoL accepted.
    'Urostrophus_grilli'       = c(species = 'Urostrophus grilli', genus = 'Urostrophus',
                                   kingdom = 'Animalia', phylum = 'Chordata',
                                   class = 'Reptilia', order = 'Squamata',
                                   family = 'Leiosauridae', taxonomy_source = 'manual'),
    # Dichotomius opacus (Blanchard 1845) (Anunciacao_etal_2025, 9 rows): CoL accepted as
    # Dichotomius (Selenocopris) opacus; GBIF has the genus only (1092917).
    'Dichotomius_opacus'       = c(species = 'Dichotomius opacus', genus = 'Dichotomius',
                                   kingdom = 'Animalia', phylum = 'Arthropoda',
                                   class = 'Insecta', order = 'Coleoptera',
                                   family = 'Scarabaeidae', taxonomy_source = 'manual'),
    # Cross-kingdom conflicts found by the scan of #81 (2026-10-05; Part 2b
    # above keeps such rows out of the autotroph filter from now on). GBIF
    # verified the same day.
    # Bull ant (Formicidae; Herberstein_etal_2022, Leahy_2025). An exact
    # homonym of the green alga Myrmecia pyriformis J.B.Petersen (GBIF
    # 2638665), so GBIF abstained and NCBI answered with the alga,
    # 'Myrmecia pyriformis (in: green algae)', kingdom Viridiplantae over the
    # pre-seeded Hymenoptera/Formicidae. GBIF 1317766, Smith 1858, ACCEPTED.
    'Myrmecia_pyriformis'      = c(species = 'Myrmecia pyriformis', genus = 'Myrmecia',
                                   kingdom = 'Animalia', phylum = 'Arthropoda',
                                   class = 'Insecta', order = 'Hymenoptera',
                                   family = 'Formicidae', taxonomy_source = 'manual'),
    # Ground tit (Paridae; Myhrvold_2015 as 'Parus humilis', the old name).
    # The GBIF backbone lacks the synonym and fuzzy-matched Pyrus humilis =
    # Cotoneaster humilis (Rosaceae) at 81 over the pre-seeded Aves/Paridae.
    # Accepted name Pseudopodoces humilis, under which Myhrvold_2015 also has a
    # record, so this record folds into that species.
    'Parus_humilis'            = c(species = 'Pseudopodoces humilis', genus = 'Pseudopodoces',
                                   kingdom = 'Animalia', phylum = 'Chordata',
                                   class = 'Aves', order = 'Passeriformes',
                                   family = 'Paridae', taxonomy_source = 'manual'),
    # Fortescue (Tetrarogidae). An exact homonym of the campanula Centropogon
    # australis (E.Wimm.) Gleason (GBIF 3165329); NCBI answered 'Centropogon
    # australis (in: eudicots)', Viridiplantae/Streptophyta/Magnoliopsida over
    # the pre-seeded Scorpaeniformes/Tetrarogidae. GBIF 2335165, White 1790,
    # ACCEPTED; class as the cache has it for Notesthes robusta.
    'Centropogon_australis'    = c(species = 'Centropogon australis', genus = 'Centropogon',
                                   kingdom = 'Animalia', phylum = 'Chordata',
                                   class = 'Actinopterygii', order = 'Scorpaeniformes',
                                   family = 'Tetrarogidae', taxonomy_source = 'manual'),
    # Springtail (Neanuridae; Hishi_etal_2019). GBIF fuzzy-matched Lobelia
    # decipiens = Monopsis decipiens (Campanulaceae) at 83 over the pre-seeded
    # Collembola/Neanuridae. Lobella decipiens Yosii, 1965 is accepted in the
    # Catalogue of Life; the GBIF backbone's accepted name is Lobellina
    # decipiens (R.Yosii, 1965), 10776730, as for Lobella_mizunasiana ->
    # Lobellina mizunasiana in the cache.
    'Lobella_decipiens'        = c(species = 'Lobellina decipiens', genus = 'Lobellina',
                                   kingdom = 'Animalia', phylum = 'Arthropoda',
                                   class = 'Collembola', order = 'Poduromorpha',
                                   family = 'Neanuridae', taxonomy_source = 'manual')
  )
  if ('taxon' %in% names(dat)) {
    for (tx in names(taxon_overwrites)) {
      idx <- which(!is.na(dat$taxon) & dat$taxon == tx)
      if (length(idx) == 0) next
      fill <- taxon_overwrites[[tx]]
      for (col in intersect(names(fill), names(dat)))
        dat[[col]][idx] <- fill[[col]]
      if ('kingdom' %in% names(fill))
        for (col in intersect(c('gbif_confidence', 'gbif_status', 'gbif_usageKey',
                                'gbif_family', 'gbif_order', 'col_match_type',
                                'col_status', 'col_usageKey', 'col_matched_name'), names(dat)))
          dat[[col]][idx] <- NA
      if (all(c('species_changed', 'species') %in% names(dat))) {
        input <- if ('taxon_provided' %in% names(dat)) dat$taxon_provided[idx]
                 else gsub('_', ' ', dat$taxon[idx])
        dat$species_changed[idx] <- !is.na(dat$species[idx]) & !is.na(input) &
                                    dat$species[idx] != input
      }
    }
  }

  dat
}
