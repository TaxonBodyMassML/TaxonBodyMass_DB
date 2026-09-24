check_enriched <- function(dat, within_source = NULL, remove_flagged = FALSE) {
  dir.create(file.path(wd_root, "reports"), showWarnings = FALSE)
  warn <- character(0)
  warn_summary <- character(0)
  warn_namechange <- character(0)
  errs <- character(0)
  mass_summary <- character(0)

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

  # 9. High mass disagreement across collapsed taxon strings
  fmt_mass_line <- function(row, ws_all) {
    base <- sprintf("%s [range=%.2f]", row$species, row$log10_range)
    if (!is.null(ws_all)) {
      ws <- ws_all[ws_all$genus == row$genus & ws_all$species == row$species, ]
      if (nrow(ws) > 1) {
        min_row <- ws[which.min(ws$mass_g), ]
        max_row <- ws[which.max(ws$mass_g), ]
        base <- sprintf("%s\n        Min_source: %s %.4g\n        Max_source: %s %.4g",
          base,
          min_row$source_mass, min_row$mass_g,
          max_row$source_mass, max_row$mass_g)
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
        "**Note: All species listed below (log10 range > 1) have been removed from TaxonBodyMass.csv.**",
        mass_summary)

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
  if (length(errs) > 0) {
    summary_block_mass <- paste0("## Summary\n\n", paste(mass_summary, collapse = "\n"))
    writeLines(c(sprintf("# TaxonBodyMass_DB Mass Value Warnings -- %s\n", now),
      summary_block_mass, errs),
      file.path(wd_root, "reports", "warnings_mass_values.md"))
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
