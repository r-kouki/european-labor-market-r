# =============================================================================
# 05_export_outputs.R - Export Polished Outputs
# European Tech & Engineering Job Market Analysis
# =============================================================================

cli::cli_h1("Exporting Polished Outputs")

# Ensure setup is loaded
if (!exists("CONFIG")) {
  source(here::here("R", "00_setup.R"))
}

# Load panel data
panel <- readRDS(file.path(CONFIG$PATHS$processed, "panel_annual.rds"))

# =============================================================================
# PRESENTATION-READY DATASET
# =============================================================================

cli::cli_h2("Creating presentation-ready dataset")

panel_presentation <- panel |>
  select(
    any_of(c(
      "geo",
      "geo_name",
      "year",
      "is_eu27",
      # Core indicators
      "ict_share_pc_emp",
      "ict_employed_ths",
      "unemp_rate_pc_act",
      "vacancy_rate_total",
      "vacancy_rate_J",
      "vacancy_rate_M",
      "vacancy_rate_C",
      "grads_ict_tertiary",
      "grads_eng_tertiary",
      "wbl_exposure_share",
      "median_hourly_earnings_eur"
    ))
  ) |>
  # Round numeric columns
  mutate(across(
    where(is.numeric) & !matches("year|ths|grads"),
    ~ round(.x, 2)
  )) |>
  mutate(across(
    matches("ths|grads"),
    ~ round(.x, 0)
  )) |>
  arrange(geo, year)

write_csv(panel_presentation, file.path(CONFIG$PATHS$tables, "panel_annual_presentation.csv"))
cli::cli_alert_success("Saved panel_annual_presentation.csv ({nrow(panel_presentation)} rows)")

# =============================================================================
# DATA DICTIONARY
# =============================================================================

cli::cli_h2("Creating data dictionary")

data_dictionary <- tribble(
  ~variable, ~description, ~unit, ~source,
  "geo", "Country/region code", "Eurostat geo code", "All datasets",
  "geo_name", "Country/region name", "Text", "Derived",
  "year", "Reference year", "Integer", "All datasets",
  "is_eu27", "EU27 member state flag", "Boolean", "Derived",
  "ict_share_pc_emp", "ICT specialists as share of employment", "% of total employment", "isoc_sks_itspt",
  "ict_employed_ths", "Number of employed ICT specialists", "Thousands of persons", "isoc_sks_itspt",
  "unemp_rate_pc_act", "Unemployment rate (ages 15-74)", "% of active population", "une_rt_a",
  "vacancy_rate_total", "Job vacancy rate (total economy)", "% of occupied + vacant posts", "jvs_a_rate_r2",
  "vacancy_rate_J", "Job vacancy rate (Info & Communication)", "% of occupied + vacant posts", "jvs_a_rate_r2",
  "vacancy_rate_M", "Job vacancy rate (Professional/Scientific)", "% of occupied + vacant posts", "jvs_a_rate_r2",
  "vacancy_rate_C", "Job vacancy rate (Manufacturing)", "% of occupied + vacant posts", "jvs_a_rate_r2",
  "grads_ict_tertiary", "Tertiary graduates in ICT field", "Number of graduates", "educ_uoe_grad02",
  "grads_eng_tertiary", "Tertiary graduates in Engineering", "Number of graduates", "educ_uoe_grad02",
  "wbl_exposure_share", "VET graduates with work-based learning", "% of VET graduates", "Various",
  "median_hourly_earnings_eur", "Median hourly earnings", "EUR", "earn_ses_pub2s"
)

# Write as markdown
dictionary_md <- c(
  "# Data Dictionary",
  "",
  "## Panel Dataset (panel_annual.csv)",
  "",
  "| Variable | Description | Unit | Source |",
  "|----------|-------------|------|--------|",
  apply(data_dictionary, 1, function(row) {
    sprintf("| %s | %s | %s | %s |", row[1], row[2], row[3], row[4])
  }),
  "",
  "## Data Sources",
  "",
  "All data sourced from Eurostat (https://ec.europa.eu/eurostat).",
  "",
  "### Dataset Codes:",
  "",
  "| Code | Name | Description |",
  "|------|------|-------------|",
  "| isoc_sks_itspt | ICT specialists | Employed ICT specialists - total |",
  "| une_rt_a | Unemployment | Unemployment by sex and age - annual |",
  "| une_rt_m | Unemployment monthly | Unemployment by sex and age - monthly |",
  "| jvs_a_rate_r2 | Job vacancies | Job vacancy rate by NACE Rev.2 |",
  "| educ_uoe_grad02 | Graduates | Graduates by field of education |",
  "| earn_ses_pub2s | Earnings | Median hourly earnings (SES) |",
  "",
  "## Notes",
  "",
  "- Time coverage varies by indicator (generally 2014-2024)",
  "- EU27 refers to EU27_2020 composition (post-Brexit)",
  "- Missing values (NA) indicate data not available",
  "- Earnings data available only for select years (2014, 2018, 2022)",
  "",
  sprintf("Generated: %s", Sys.Date())
)

writeLines(dictionary_md, file.path(CONFIG$PATHS$tables, "data_dictionary.md"))
cli::cli_alert_success("Saved data_dictionary.md")

# Also save as CSV for convenience
write_csv(data_dictionary, file.path(CONFIG$PATHS$tables, "data_dictionary.csv"))

# =============================================================================
# KEY STATISTICS SUMMARY
# =============================================================================

cli::cli_h2("Creating key statistics summary")

# EU27 summary statistics
eu27_data <- panel |>
  filter(geo == "EU27_2020")

eu27_summary <- tibble(
  years_covered = sprintf("%d-%d", min(eu27_data$year), max(eu27_data$year)),
  # ICT share
  ict_share_first = eu27_data$ict_share_pc_emp[eu27_data$year == min(eu27_data$year[!is.na(eu27_data$ict_share_pc_emp)])],
  ict_share_latest = eu27_data$ict_share_pc_emp[eu27_data$year == max(eu27_data$year[!is.na(eu27_data$ict_share_pc_emp)])],
  # Unemployment
  unemp_first = eu27_data$unemp_rate_pc_act[eu27_data$year == min(eu27_data$year[!is.na(eu27_data$unemp_rate_pc_act)])],
  unemp_latest = eu27_data$unemp_rate_pc_act[eu27_data$year == max(eu27_data$year[!is.na(eu27_data$unemp_rate_pc_act)])]
)

write_csv(eu27_summary, file.path(CONFIG$PATHS$tables, "eu27_summary_statistics.csv"))
cli::cli_alert_success("Saved eu27_summary_statistics.csv")

# Country rankings (latest year)
latest_year <- max(panel$year, na.rm = TRUE)

country_rankings <- panel |>
  filter(year == latest_year, !is_aggregate, is_eu27) |>
  select(any_of(c("geo", "geo_name", "ict_share_pc_emp", "unemp_rate_pc_act", "vacancy_rate_J"))) |>
  mutate(
    ict_rank = rank(-ict_share_pc_emp, na.last = "keep"),
    unemp_rank = rank(unemp_rate_pc_act, na.last = "keep")
  ) |>
  arrange(ict_rank)

write_csv(country_rankings, file.path(CONFIG$PATHS$tables, "country_rankings_latest.csv"))
cli::cli_alert_success("Saved country_rankings_latest.csv")

# =============================================================================
# EUROSTAT ATTRIBUTION FILE
# =============================================================================

cli::cli_h2("Creating attribution file")

attribution <- c(
  "# Data Attribution",
  "",
  "## Source",
  "",
  "All data in this project are sourced from **Eurostat**, the statistical office",
  "of the European Union.",
  "",
  "Website: https://ec.europa.eu/eurostat",
  "",
  "## Datasets Used",
  "",
  "| Dataset Code | Full Name |",
  "|--------------|-----------|",
  "| isoc_sks_itspt | Employed ICT specialists - total |",
  "| une_rt_a | Unemployment by sex and age - annual data |",
  "| une_rt_m | Unemployment by sex and age - monthly data |",
  "| jvs_a_rate_r2 | Job vacancy rate by NACE Rev.2 activity |",
  "| educ_uoe_grad02 | Graduates by education level and field |",
  "| earn_ses_pub2s | Median hourly earnings (SES) |",
  "",
  "## License",
  "",
  "Eurostat data are subject to the Eurostat copyright policy.",
  "Reuse is authorised provided the source is acknowledged.",
  "",
  "See: https://ec.europa.eu/eurostat/about-us/policies/copyright",
  "",
  "## Citation",
  "",
  "Data processed from Eurostat datasets. Source: Eurostat.",
  "",
  "## Processing",
  "",
  "Data were downloaded using the R `eurostat` package and processed",
  "to create derived indicators and visualizations.",
  "",
  sprintf("Processing date: %s", Sys.Date())
)

writeLines(attribution, file.path(CONFIG$PATHS$tables, "ATTRIBUTION.md"))
cli::cli_alert_success("Saved ATTRIBUTION.md")

# =============================================================================
# SUMMARY
# =============================================================================

cli::cli_h1("Export Summary")

output_files <- list.files(CONFIG$PATHS$tables, full.names = FALSE)
cli::cli_alert_success("Created {length(output_files)} files in {CONFIG$PATHS$tables}")

for (f in output_files) {
  cli::cli_alert_info("  {f}")
}

cli::cli_alert_success("Export complete!")
