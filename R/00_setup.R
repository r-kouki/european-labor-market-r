# =============================================================================
# 00_setup.R - Project Setup and Configuration
# European Tech & Engineering Job Market Analysis
# =============================================================================

# Load required packages -------------------------------------------------------

required_packages <- c(
  "tidyverse",
  "eurostat",
  "here",
  "janitor",
  "cli",
  "scales",
  "countrycode",
  "corrplot",
  "ggrepel",
  "patchwork",
  "knitr"
)

# Check and load packages
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cli::cli_alert_warning("Package '{pkg}' not installed. Run install_packages.R first.")
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

cli::cli_alert_success("All required packages loaded")

# Source utility functions -----------------------------------------------------
source(here::here("R", "utils.R"))

# Project configuration --------------------------------------------------------

CONFIG <- list(
  # Time ranges
  YEARS_ANNUAL = 2014:2024,
  YEARS_GRADS = 2014:2023,
  YEARS_EARN = c(2014, 2018, 2022),
  MONTHLY_START = "2020-01-01",

  # Geographies to include
  GEO_KEEP = get_eu_countries(),

  # NACE Rev.2 sectors for vacancy analysis
  NACE_KEEP = c(
    "B-S",     # Total business economy (alternative to A-S)
    "J",       # Information and communication
    "M",       # Professional, scientific and technical activities
    "C"        # Manufacturing
  ),

  # Dataset codes
  DATASETS = list(
    ict_specialists = "isoc_sks_itspt",
    unemployment_annual = "une_rt_a",
    unemployment_monthly = "une_rt_m",
    vacancies = "jvs_a_rate_r2",
    graduates = "educ_uoe_grad02",
    wbl_exposure = "trng_vet_wbl",
    earnings = "earn_ses_pub2s"
  ),

  # Paths
  PATHS = list(
    raw = here::here("data", "raw"),
    processed = here::here("data", "processed"),
    cache = here::here("data", "cache"),
    figures = here::here("outputs", "figures"),
    tables = here::here("outputs", "tables")
  )
)

# Create directories -----------------------------------------------------------

cli::cli_h2("Setting up project directories")

for (path_name in names(CONFIG$PATHS)) {
  safe_mkdir(CONFIG$PATHS[[path_name]])
}

# Set Eurostat cache directory -------------------------------------------------

eurostat::set_eurostat_cache_dir(CONFIG$PATHS$cache)
cli::cli_alert_info("Eurostat cache directory: {CONFIG$PATHS$cache}")

# Set ggplot2 defaults ---------------------------------------------------------

ggplot2::theme_set(theme_project())

# Print configuration summary --------------------------------------------------

cli::cli_h2("Configuration Summary")
cli::cli_alert_info("Annual data years: {min(CONFIG$YEARS_ANNUAL)}-{max(CONFIG$YEARS_ANNUAL)}")
cli::cli_alert_info("Graduate data years: {min(CONFIG$YEARS_GRADS)}-{max(CONFIG$YEARS_GRADS)}")
cli::cli_alert_info("Monthly data from: {CONFIG$MONTHLY_START}")
cli::cli_alert_info("Number of geographies: {length(CONFIG$GEO_KEEP)}")
cli::cli_alert_info("NACE sectors: {paste(CONFIG$NACE_KEEP, collapse = ', ')}")

cli::cli_alert_success("Setup complete!")
