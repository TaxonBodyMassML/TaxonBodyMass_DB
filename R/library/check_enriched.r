# `unresolved`: an optional data frame (taxon, sources, rows) of the cleaned
# names that no enrichment stage resolved to an accepted species (#38); they
# are listed in reports/warnings_taxonomy.md, where the run log used to print
# only their count.
# `kingdom_conflicts`: an optional data frame (taxon, kingdom_conflict,
# kingdom, phylum, class, order, family, species, taxonomy_source, sources,
# rows) of the names whose authority kingdom was a plant, alga or fungus over
# animal ranks and that Part 2b of fix_taxonomy_ranks.r corrected (#81); taken
# before FilterAutotrophs(), which dropped them unreported until then.
# `exclusions`: the result of ExcludeDiscordantValues() (#34): its per-value
# exclusion table is written as its own section of warnings_mass_values.md
# (the excluded value beside the kept ones), and its unresolved table gives
# the reason each species in the range sections was left to the filter.
# `within_source` then holds the independent values, excluded ones included
# (columns excluded, exclusion_rule, value_tier).
check_enriched <- function(dat, within_source = NULL, remove_flagged = FALSE,
                           unresolved = NULL, kingdom_conflicts = NULL, exclusions = NULL) {
  dir.create(file.path(wd_root, "reports"), showWarnings = FALSE)
  warn <- character(0)
  warn_summary <- character(0)
  warn_namechange <- character(0)
  errs <- character(0)
  mass_summary <- character(0)
  excl_block <- character(0)

  # 1. Mass validity
  bad_mass <- dat[!is.finite(dat$mass_g) | dat$mass_g <= 0, ]
  if (nrow(bad_mass) > 0)
    errs <- c(errs, sprintf("## Non-positive or non-finite mass_g (%d rows)\n\n%s",
      nrow(bad_mass), paste(bad_mass$taxon, collapse = "\n")))

  # 2. Taxonomy completeness
  rank_cols <- c("kingdom", "phylum", "class", "order", "family", "genus", "species")
  for (col in rank_cols) {
    n_na <- sum(is.na(dat[[col]]))
    if (n_na > 0) {
      warn <- c(warn, sprintf("\n## Missing `%s` after all enrichment stages (%d rows)\n\n%s",
        col, n_na, paste(dat$taxon[is.na(dat[[col]])], collapse = "\n\n")))
      warn_summary <- c(warn_summary, sprintf("- Missing `%s` after all enrichment stages: %d rows",
        col, n_na))
    }
  }

  # 3. Duplicate species (should be zero post-deduplication)
  dup_key <- paste(dat$genus, dat$species)
  dups <- dat[duplicated(dup_key) | duplicated(dup_key, fromLast = TRUE), ]
  if (nrow(dups) > 0)
    errs <- c(errs, sprintf("## Duplicate genus+species after deduplication (%d rows)\n\n%s",
      nrow(dups), paste(dups$taxon, collapse = "\n")))

  # 4. Species name format: "Genus epithet"
  bad_fmt <- dat[!is.na(dat$species) & !grepl("^[A-Z][a-z]+ ([a-z]{2,}|[a-z]-[a-z]+)$", dat$species), ]
  if (nrow(bad_fmt) > 0) {
    warn <- c(warn, sprintf("\n## Species names not in 'Genus epithet' format (%d rows)\n\n%s",
      nrow(bad_fmt), paste(bad_fmt$species, collapse = "\n\n")))
    warn_summary <- c(warn_summary, sprintf("- Species names not in 'Genus epithet' format: %d rows",
      nrow(bad_fmt)))
  }

  # 5. Genus/species prefix consistency
  has_both <- !is.na(dat$genus) & !is.na(dat$species)
  mismatch <- dat[has_both & !startsWith(dat$species, dat$genus), ]
  if (nrow(mismatch) > 0) {
    warn <- c(warn, sprintf("\n## genus column does not match species prefix (%d rows)\n\n%s",
      nrow(mismatch), paste(sprintf("%s | genus=%s | species=%s",
        mismatch$taxon, mismatch$genus, mismatch$species), collapse = "\n\n")))
    warn_summary <- c(warn_summary, sprintf("- genus column does not match species prefix: %d rows",
      nrow(mismatch)))
  }

  # 6. Low GBIF confidence (75-89)
  if ("gbif_confidence" %in% names(dat)) {
    low_conf <- dat[!is.na(dat$gbif_confidence) &
      dat$gbif_confidence >= 75 & dat$gbif_confidence < 90, ]
    if (nrow(low_conf) > 0) {
      warn <- c(warn, sprintf("\n## Low GBIF confidence (75-89) (%d rows)\n\n%s",
        nrow(low_conf), paste(sprintf("%s [conf=%d]",
          low_conf$taxon, low_conf$gbif_confidence), collapse = "\n\n")))
      warn_summary <- c(warn_summary, sprintf("- Low GBIF confidence (75-89): %d rows",
        nrow(low_conf)))
    }
  }

  # 7. GBIF DOUBTFUL status
  if ("gbif_status" %in% names(dat)) {
    doubtful <- dat[!is.na(dat$gbif_status) & dat$gbif_status == "DOUBTFUL", ]
    if (nrow(doubtful) > 0) {
      warn <- c(warn, sprintf("\n## GBIF status DOUBTFUL (%d rows)\n\n%s",
        nrow(doubtful), paste(doubtful$taxon, collapse = "\n\n")))
      warn_summary <- c(warn_summary, sprintf("- GBIF status DOUBTFUL: %d rows",
        nrow(doubtful)))
    }
  }

  # 8. Species name changed during enrichment
  if ("species_changed" %in% names(dat)) {
    changed <- dat[!is.na(dat$species_changed) & dat$species_changed, ]
    if (nrow(changed) > 0) {
      warn_namechange <- c(warn_namechange, sprintf("\n## Species name changed during enrichment (%d rows)\n\n%s",
        nrow(changed), paste(sprintf("%s -> %s [%s]",
          changed$taxon_provided, changed$species, changed$taxonomy_source),
          collapse = "\n\n")))
    }
  }

  # 9. High mass disagreement across collapsed taxon strings: every
  #    independent value of the species (label, value, records, tier), the
  #    extremes first, and the reason the record-level rule left it (#34)
  unres_tab <- if (!is.null(exclusions)) exclusions$unresolved else NULL
  fmt_value <- function(ws) {
    tier <- if ("value_tier" %in% names(ws)) sprintf(", T%d", ws$value_tier) else ""
    sprintf("%s %.4g g (n %d%s)", ws$source_mass, ws$mass_g, ws$n, tier)
  }
  fmt_mass_line <- function(row, ws_all) {
    base <- sprintf("%s [range=%.2f]", row$species, row$log10_range)
    if (!is.null(unres_tab)) {
      r <- unres_tab$reason[unres_tab$genus == row$genus & unres_tab$species == row$species]
      if (length(r) == 1) base <- sprintf("%s [unresolved: %s]", base, r)
    }
    if (!is.null(ws_all)) {
      ws <- ws_all[ws_all$genus == row$genus & ws_all$species == row$species, ]
      if ("excluded" %in% names(ws)) ws <- ws[!ws$excluded, ]
      if (nrow(ws) > 1) {
        ws <- ws[order(ws$mass_g), ]
        base <- sprintf("%s\n        Min_source: %s %.4g\n        Max_source: %s %.4g\n        Values: %s",
          base,
          ws$source_mass[1], ws$mass_g[1],
          ws$source_mass[nrow(ws)], ws$mass_g[nrow(ws)],
          paste(fmt_value(ws), collapse = "; "))
      }
    }
    base
  }

  tally_suspicious_sources <- function(species_df, ws_all) {
    if (is.null(ws_all) || nrow(species_df) == 0) return(character(0))
    src <- character(0)
    for (i in seq_len(nrow(species_df))) {
      ws <- ws_all[ws_all$genus == species_df$genus[i] & ws_all$species == species_df$species[i], ]
      if (nrow(ws) > 1)
        src <- c(src, ws$source_mass[which.min(ws$mass_g)], ws$source_mass[which.max(ws$mass_g)])
    }
    if (length(src) == 0) return(character(0))
    tbl <- sort(table(src), decreasing = TRUE)
    paste(sprintf("  - %s (%d)", names(tbl), as.integer(tbl)), collapse = "\n")
  }

  if ("log10_range" %in% names(dat)) {
    if (remove_flagged)
      mass_summary <- c(
        "**Note: All species listed in the two range sections below (log10 range > 1 after the record-level range rule) have been removed from TaxonBodyMass.csv.**",
        mass_summary)
    # 9a. Values excluded from the cross-source mean by the record-level range
    #     rule (#34): the species are kept; the section lists the excluded
    #     value beside the kept ones.
    if (!is.null(exclusions)) {
      ex <- exclusions$exclusions
      ie <- ex[is.na(ex$copy_of), , drop = FALSE]
      cnt <- exclusions$counts
      by_rule <- cnt$by_rule[cnt$by_rule > 0]
      by_reason <- cnt$unresolved_by_reason[cnt$unresolved_by_reason > 0]
      mass_summary <- c(mass_summary,
        sprintf("- Record-level range rule (#34): %d species over the threshold; %d rescued by excluding %d values (%d collapsed copies with them); %d unresolved and removed",
                cnt$species_flagged, cnt$species_rescued, cnt$values_excluded_independent, cnt$values_excluded_copies, cnt$species_unresolved),
        if (length(by_rule) > 0) sprintf("- Exclusions by rule: %s", paste(sprintf("%s %d", names(by_rule), by_rule), collapse = ", ")),
        if (length(by_reason) > 0) sprintf("- Unresolved by reason: %s", paste(sprintf("%s %d", names(by_reason), by_reason), collapse = ", ")))
      if (nrow(ie) > 0) {
        src_tab <- sort(table(ie$source_label), decreasing = TRUE)
        tier_tab <- table(factor(ie$value_tier, levels = 1:3))
        lines_ex <- sprintf("%s [%s, %+.2f log10, T%d]\n        Excluded: %s %.4g g (n %d)%s\n        Kept: %s -> %.4g g",
          ie$species, ie$rule, ie$distance_log10, ie$value_tier,
          ie$source_mass, ie$mass_g, ie$n,
          vapply(seq_len(nrow(ie)), function(i) {
            cp <- ex$source_label[!is.na(ex$copy_of) & ex$copy_of == ie$source_label[i] & ex$genus == ie$genus[i] & ex$species == ie$species[i]]
            if (length(cp) == 0) "" else sprintf(" [+ copies %s]", paste(cp, collapse = ", "))
          }, character(1)),
          ie$kept_values, ie$kept_mass_g)
        excl_block <- c(
          sprintf("## Values excluded from the cross-source mean by the record-level range rule (%d values in %d species; issue #34)",
                  nrow(ie), length(unique(paste(ie$genus, ie$species)))),
          "",
          paste("These species are kept in TaxonBodyMass.csv: the listed value is left out of their mean (and of n_independent and log10_range),",
                "stays in source_mass and n, and is flagged in sources_excluded and in TaxonBodyMass_Provenance.csv.gz (record_status).",
                "Rules: loo_unique (the one value whose exclusion brings the rest within the threshold, the rest spanning two registry-independent",
                "evidence groups), tier_tiebreak / distance_tiebreak (several such values: the lowest trust tier, else the farthest from the median),",
                "two_value_tier (two values or one evidence group against one value: the lower-trust side). Tiers: value_tier in",
                "Bib/source_provenance_classes.csv (1 compiled/measured, 2 maxima-based, 3 specimens, individuals, converted and web-level values;",
                "a converted value is tier 3). The distance is log10 of the excluded value over the median of the kept values. Live list: reports/excluded_records.csv."),
          "",
          sprintf("- Excluded values by tier: T1 %d, T2 %d, T3 %d", tier_tab[["1"]], tier_tab[["2"]], tier_tab[["3"]]),
          sprintf("- Excluded values by source:\n%s", paste(sprintf("  - %s (%d)", names(src_tab), as.integer(src_tab)), collapse = "\n")),
          "",
          paste(lines_ex, collapse = "\n"))
        # 9b. the rescued species that rest on a single kept value (owner
        #     decision 2026-10-06: flagged SUSPICIOUS in the register; the kept
        #     value has no second source behind it)
        sv <- ie[ie$single_value_rescue, , drop = FALSE]
        sv_key <- paste(sv$genus, sv$species)
        sv1 <- sv[!duplicated(sv_key), , drop = FALSE]
        if (nrow(sv1) > 0) {
          lines_sv <- sprintf("%s: kept %s | excluded %s [%s]", sv1$species, sv1$kept_values,
            vapply(paste(sv1$genus, sv1$species), function(k) paste(sprintf("%s %.4g g (n %d, T%d)", sv$source_mass[sv_key == k], sv$mass_g[sv_key == k], sv$n[sv_key == k], sv$value_tier[sv_key == k]), collapse = "; "), character(1)),
            sv1$rule)
          excl_block <- c(excl_block, "",
            sprintf("### Rescued species resting on a single kept value (%d species; single_value_rescue in reports/excluded_records.csv, SUSPICIOUS rows in audit/flagged_species.csv)", nrow(sv1)),
            "",
            paste("The exclusion left one value in the mean; the kept value has no second source behind it and the tiers, not the data, decided which side was wrong.",
                  "Owner decision 2026-10-06: kept, flagged for review."),
            "",
            paste(lines_sv, collapse = "\n"))
          mass_summary <- c(mass_summary, sprintf("- Rescued species resting on a single kept value (flagged SUSPICIOUS): %d", nrow(sv1)))
        }
      }
    }

    high_range <- dat[!is.na(dat$log10_range) & dat$log10_range > 2.0, ]
    high_range <- high_range[order(-high_range$log10_range), ]
    if (nrow(high_range) > 0) {
      mass_summary <- c(mass_summary, sprintf(
        "- High mass disagreement (log10 range > 2): %d species", nrow(high_range)))
      src_high <- tally_suspicious_sources(high_range, within_source)
      if (length(src_high) > 0)
        mass_summary <- c(mass_summary, sprintf(
          "- Suspicious sources (log10 > 2, by frequency):\n%s", src_high))
      lines_high <- vapply(seq_len(nrow(high_range)), function(i)
        fmt_mass_line(high_range[i, ], within_source), character(1))
      errs <- c(errs, sprintf(
        "## log10(max/min mass) > 2 after dedup (%d species) -- likely misresolution or unit error\n\n%s",
        nrow(high_range), paste(lines_high, collapse = "\n")))
    }

    moderate_range <- dat[!is.na(dat$log10_range) &
      dat$log10_range > 1.0 & dat$log10_range <= 2.0, ]
    moderate_range <- moderate_range[order(-moderate_range$log10_range), ]
    if (nrow(moderate_range) > 0) {
      mass_summary <- c(mass_summary, sprintf(
        "- Moderate mass disagreement (log10 range 1-2): %d species", nrow(moderate_range)))
      src_mod <- tally_suspicious_sources(moderate_range, within_source)
      if (length(src_mod) > 0)
        mass_summary <- c(mass_summary, sprintf(
          "- Suspicious sources (log10 1-2, by frequency):\n%s", src_mod))
      lines_mod <- vapply(seq_len(nrow(moderate_range)), function(i)
        fmt_mass_line(moderate_range[i, ], within_source), character(1))
      errs <- c(errs, sprintf(
        "\n## Moderate mass disagreement (log10 range 1-2) (%d species)\n\n%s",
        nrow(moderate_range), paste(lines_mod, collapse = "\n")))
    }
  }

  # 10. Source family/order differs from GBIF-returned family/order
  if (all(c("gbif_family", "family") %in% names(dat))) {
    fam_mm <- dat[!is.na(dat$family) & !is.na(dat$gbif_family) &
      tolower(trimws(dat$family)) != tolower(trimws(dat$gbif_family)), ]
    if (nrow(fam_mm) > 0) {
      warn <- c(warn, sprintf(
        "\n## Source family != GBIF family (%d rows -- review for misresolution)\n\n%s",
        nrow(fam_mm), paste(sprintf("%s | source=%s | GBIF=%s",
          fam_mm$taxon, fam_mm$family, fam_mm$gbif_family), collapse = "\n\n")))
      warn_summary <- c(warn_summary, sprintf("- Source family != GBIF family: %d rows",
        nrow(fam_mm)))
    }
  }
  if (all(c("gbif_order", "order") %in% names(dat))) {
    ord_mm <- dat[!is.na(dat$order) & !is.na(dat$gbif_order) &
      tolower(trimws(dat$order)) != tolower(trimws(dat$gbif_order)), ]
    if (nrow(ord_mm) > 0) {
      warn <- c(warn, sprintf(
        "\n## Source order != GBIF order (%d rows -- review for misresolution)\n\n%s",
        nrow(ord_mm), paste(sprintf("%s | source=%s | GBIF=%s",
          ord_mm$taxon, ord_mm$order, ord_mm$gbif_order), collapse = "\n\n")))
      warn_summary <- c(warn_summary, sprintf("- Source order != GBIF order: %d rows",
        nrow(ord_mm)))
    }
  }

  # 11. Kingdom conflicts: a non-Animalia kingdom paired with an order or
  #     family that otherwise occurs under Animalia. This is the signature of a
  #     cross-kingdom homonym mis-resolution (e.g. the lizard Abronia aurita
  #     resolved by NCBI to the plant Abronia villosa var. aurita) and of
  #     autotrophs that slipped past FilterAutotrophs().
  if (all(c("kingdom", "order", "family") %in% names(dat))) {
    is_animal <- !is.na(dat$kingdom) & dat$kingdom == "Animalia"
    animal_orders   <- unique(na.omit(dat$order[is_animal]))
    animal_families <- unique(na.omit(dat$family[is_animal]))
    other <- dat[!is.na(dat$kingdom) & !is_animal, ]
    conflict <- other[(!is.na(other$order)  & other$order  %in% animal_orders) |
                      (!is.na(other$family) & other$family %in% animal_families), ]
    if (nrow(conflict) > 0) {
      warn <- c(warn, sprintf(
        "\n## Non-Animalia kingdom with an Animalia order/family (%d rows -- likely cross-kingdom misresolution)\n\n%s",
        nrow(conflict), paste(sprintf("%s | kingdom=%s | order=%s | family=%s [%s]",
          conflict$taxon, conflict$kingdom, conflict$order, conflict$family,
          conflict$taxonomy_source), collapse = "\n\n")))
      warn_summary <- c(warn_summary, sprintf(
        "- Non-Animalia kingdom with an Animalia order/family: %d rows", nrow(conflict)))
    }
  }

  # 12. Names unresolved after all enrichment stages (#38): every cleaned name
  #     without an accepted species, with its source labels and row counts.
  #     Before #38 the run log printed only the count, so a name mangled by the
  #     cleaning chain (Crithidia_strigomonas, Rhytonomus_isabellina) vanished
  #     silently.
  if (!is.null(unresolved) && nrow(unresolved) > 0) {
    unresolved <- unresolved[order(-unresolved$rows, unresolved$taxon), ]
    warn <- c(warn, sprintf(
      "\n## Names unresolved after all enrichment stages (%d names, %d rows -- dropped from the output)\n\n%s",
      nrow(unresolved), sum(unresolved$rows),
      paste(sprintf("%s | %s | %d row%s", unresolved$taxon, unresolved$sources,
                    unresolved$rows, ifelse(unresolved$rows == 1, "", "s")), collapse = "\n\n")))
    warn_summary <- c(warn_summary, sprintf(
      "- Names unresolved after all enrichment stages: %d names, %d rows",
      nrow(unresolved), sum(unresolved$rows)))
  }

  # 13. Cross-kingdom conflicts corrected before the autotroph filter (#81):
  #     the kingdom the authority returned and the final one, the ranks, the
  #     final species ('unresolved' when the species came from the wrong
  #     kingdom's authority and was cleared, so the name is also in section
  #     12), the sources and record counts. Check 11 above cannot see these
  #     rows: it runs on the post-filter frame.
  if (!is.null(kingdom_conflicts) && nrow(kingdom_conflicts) > 0) {
    kc <- kingdom_conflicts[order(kingdom_conflicts$taxon), ]
    na_dash <- function(x) ifelse(is.na(x), "-", as.character(x))
    warn <- c(warn, sprintf(
      "\n## Kingdom conflicts corrected before the autotroph filter (%d names, %d rows -- an authority's plant, alga or fungus kingdom over animal ranks; #81)\n\n%s",
      nrow(kc), sum(kc$rows),
      paste(sprintf("%s | %s -> %s | %s / %s / %s / %s | species=%s [%s] | %s | %d row%s",
                    kc$taxon, kc$kingdom_conflict, na_dash(kc$kingdom),
                    na_dash(kc$phylum), na_dash(kc$class), na_dash(kc$order), na_dash(kc$family),
                    ifelse(is.na(kc$species), "unresolved", kc$species), na_dash(kc$taxonomy_source),
                    kc$sources, kc$rows, ifelse(kc$rows == 1, "", "s")), collapse = "\n\n")))
    warn_summary <- c(warn_summary, sprintf(
      "- Kingdom conflicts corrected before the autotroph filter: %d names, %d rows (%d unresolved)",
      nrow(kc), sum(kc$rows), sum(is.na(kc$species))))
  }

  # Write reports
  now <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  if (length(warn_namechange) > 0) {
    writeLines(c(sprintf("# TaxonBodyMass_DB Species Name Changes -- %s\n", now),
      warn_namechange),
      file.path(wd_root, "reports", "warnings_name_change.md"))
  } else {
    writeLines(c(sprintf("# TaxonBodyMass_DB Species Name Changes -- %s\n", now),
      "No name changes."),
      file.path(wd_root, "reports", "warnings_name_change.md"))
  }
  if (length(errs) > 0 || length(excl_block) > 0) {
    summary_block_mass <- paste0("## Summary\n\n", paste(mass_summary, collapse = "\n"))
    writeLines(c(sprintf("# TaxonBodyMass_DB Mass Value Warnings -- %s\n", now),
      summary_block_mass, if (length(excl_block) > 0) c("", excl_block), errs),
      file.path(wd_root, "reports", "warnings_mass_values.md"))
    if (length(errs) > 0)
      warning(sprintf("%d error type(s) found -- see reports/warnings_mass_values.md", length(errs)),
        immediate. = TRUE)
  } else {
    writeLines(c(sprintf("# TaxonBodyMass_DB Mass Value Warnings -- %s\n", now),
      "No errors found."),
      file.path(wd_root, "reports", "warnings_mass_values.md"))
  }
  if (length(warn) > 0) {
    summary_block <- paste0("## Summary\n\n", paste(warn_summary, collapse = "\n"))
    writeLines(c(sprintf("# TaxonBodyMass_DB Taxonomy Warnings -- %s\n", now),
      summary_block, warn),
      file.path(wd_root, "reports", "warnings_taxonomy.md"))
    message(sprintf("%d warning type(s) -- see reports/warnings_taxonomy.md", length(warn)))
  } else {
    writeLines(c(sprintf("# TaxonBodyMass_DB Taxonomy Warnings -- %s\n", now),
      "No warnings."),
      file.path(wd_root, "reports", "warnings_taxonomy.md"))
  }

  invisible(list(errors = errs, warnings = warn))
}
