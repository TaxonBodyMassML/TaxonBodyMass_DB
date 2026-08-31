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
  # A small number of animal taxa have plant class values (Magnoliopsida) in
  # source records, presumably from join artifacts. Clear these so rank inference
  # can fill them from the correct order mapping.
  if (all(c('kingdom', 'class') %in% names(dat))) {
    noise_idx <- !is.na(dat$kingdom) & !is.na(dat$class) &
      dat$kingdom %in% c('Animalia', 'Chromista', 'Fungi', 'Protozoa') &
      dat$class == 'Magnoliopsida'
    if (any(noise_idx)) dat$class[noise_idx] <- NA_character_
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
    'Mononchida'         = 'Enoplea'
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
    'Hartmannellidae'  = 'Tubulinida'          # Glaeseria mira
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
    # Ceriantharia — order absent from all APIs
    'Ceriantheopsis americanus' = c(order = 'Ceriantharia'),
    # Platyhelminthes — order absent from all APIs for these species
    'Euplana gracilis'          = c(order = 'Polycladida'),
    'Stenostomum virginianum'   = c(order = 'Catenulida'),
    'Stylochus ellipticus'      = c(order = 'Polycladida'),
    # Amoebozoa — order absent from all APIs; family Hartmannellidae → Tubulinida
    'Glaseria mira'             = c(order = 'Tubulinida'),
    # Aves — order absent from all APIs
    'Dendrocopus major'         = c(order = 'Piciformes'),
    # Kinetoplastida — order absent from all APIs
    'Trypanosoma lewisi'        = c(order = 'Trypanosomatida'),
    'Tritrichomonas foetus'     = c(order = 'Tritrichomonadida'),
    # Pylopulmonata — freshwater gastropod; order absent from all APIs
    'Spiralinella spiralis'     = c(order = 'Pylopulmonata'),
    # Myriapoda — order absent from all APIs
    'Scutigerella immaculata'   = c(order = 'Scutigerellida'),
    # Bryozoa / Amoebozoa — family absent from all APIs
    'Austroflustra vulgaris'   = c(family = 'Flustridae'),
    'Chaos carolinense'        = c(family = 'Amoebidae')
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
    'Lythrichthys longimanus' = 'Lythrichthys'
  )
  if (all(c('species', 'genus') %in% names(dat))) {
    for (sp_name in names(genus_overwrites)) {
      idx <- which(!is.na(dat$species) & dat$species == sp_name)
      if (length(idx) == 0) next
      dat$genus[idx] <- genus_overwrites[[sp_name]]
    }
  }

  dat
}
