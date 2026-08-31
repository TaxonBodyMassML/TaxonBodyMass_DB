check_enriched <- function(dat) {
  dir.create(file.path(wd_root, "reports"), showWarnings = FALSE)
  warn <- character(0)
  warn_summary <- character(0)
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
      warn <- c(warn, sprintf("\n## Species name changed during enrichment (%d rows)\n\n%s",
        nrow(changed), paste(sprintf("%s -> %s [%s]",
          changed$taxon_provided, changed$species, changed$taxonomy_source),
          collapse = "\n\n")))
      warn_summary <- c(warn_summary, sprintf("- Species name changed during enrichment: %d rows",
        nrow(changed)))
    }
  }

  # 9. High mass disagreement across collapsed taxon strings
  if ("log10_range" %in% names(dat)) {
    high_range <- dat[!is.na(dat$log10_range) & dat$log10_range > 2.0, ]
    high_range <- high_range[order(-high_range$log10_range), ]
    if (nrow(high_range) > 0) {
      mass_summary <- c(mass_summary, sprintf(
        "- High mass disagreement (log10 range > 2): %d species", nrow(high_range)))
      errs <- c(errs, sprintf(
        "## log10(max/min mass) > 2 after dedup (%d species) -- likely misresolution or unit error\n\n%s",
        nrow(high_range), paste(sprintf("%s [range=%.2f]",
          high_range$species, high_range$log10_range), collapse = "\n")))
    }

    moderate_range <- dat[!is.na(dat$log10_range) &
      dat$log10_range > 1.0 & dat$log10_range <= 2.0, ]
    moderate_range <- moderate_range[order(-moderate_range$log10_range), ]
    if (nrow(moderate_range) > 0) {
      mass_summary <- c(mass_summary, sprintf(
        "- Moderate mass disagreement (log10 range 1-2): %d species", nrow(moderate_range)))
      errs <- c(errs, sprintf(
        "\n## Moderate mass disagreement (log10 range 1-2) (%d species)\n\n%s",
        nrow(moderate_range), paste(sprintf("%s [range=%.2f]",
          moderate_range$species, moderate_range$log10_range), collapse = "\n")))
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

  # Write reports
  now <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
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
