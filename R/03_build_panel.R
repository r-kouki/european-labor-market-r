# =============================================================================
# 03_build_panel.R - Build Master Panel Dataset
# European Tech & Engineering Job Market Analysis
# =============================================================================

cli::cli_h1("Building Master Panel Dataset")

# Ensure setup is loaded
if (!exists("CONFIG")) {
  source(here::here("R", "00_setup.R"))
}

# Helper to safely load processed data
load_processed <- function(filename) {
  path <- file.path(CONFIG$PATHS$processed, filename)
  if (file.exists(path)) {
    readRDS(path)
  } else {
    cli::cli_alert_warning("Processed file not found: {filename}")
    NULL
  }
}

# =============================================================================
# LOAD CLEANED DATASETS
# =============================================================================

cli::cli_h2("Loading cleaned datasets")

ict <- load_processed("ict_specialists_clean.rds")
unemp_annual <- load_processed("unemployment_annual_clean.rds")
unemp_monthly <- load_processed("unemployment_monthly_clean.rds")
vacancies <- load_processed("vacancies_clean.rds")
graduates <- load_processed("graduates_clean.rds")
wbl <- load_processed("wbl_exposure_clean.rds")
earnings <- load_processed("earnings_clean.rds")

# =============================================================================
# CREATE PANEL SKELETON
# =============================================================================

cli::cli_h2("Creating panel skeleton")

# Get all unique geographies from available data
all_geos <- unique(c(
  if (!is.null(ict)) ict$geo else character(0),
  if (!is.null(unemp_annual)) unemp_annual$geo else character(0),
  if (!is.null(vacancies)) vacancies$geo else character(0)
))

# Filter to configured geographies
panel_geos <- intersect(all_geos, CONFIG$GEO_KEEP)

cli::cli_alert_info("Panel will include {length(panel_geos)} geographies")

# Create skeleton
panel <- expand_grid(
  geo = panel_geos,
  year = CONFIG$YEARS_ANNUAL
)

cli::cli_alert_info("Panel skeleton: {nrow(panel)} rows ({length(panel_geos)} geos x {length(CONFIG$YEARS_ANNUAL)} years)")

# =============================================================================
# JOIN DATASETS
# =============================================================================

cli::cli_h2("Joining datasets to panel")

# 1. ICT Specialists
if (!is.null(ict)) {
  panel <- panel |>
    left_join(ict, by = c("geo", "year"))
  cli::cli_alert_success("Joined ICT specialists data")
}

# 2. Unemployment (annual)
if (!is.null(unemp_annual)) {
  panel <- panel |>
    left_join(unemp_annual, by = c("geo", "year"))
  cli::cli_alert_success("Joined unemployment data")
}

# 3. Vacancies
if (!is.null(vacancies)) {
  panel <- panel |>
    left_join(vacancies, by = c("geo", "year"))
  cli::cli_alert_success("Joined vacancies data")
}

# 4. Graduates
if (!is.null(graduates)) {
  panel <- panel |>
    left_join(graduates, by = c("geo", "year"))
  cli::cli_alert_success("Joined graduates data")
}

# 5. Work-based learning
if (!is.null(wbl)) {
  panel <- panel |>
    left_join(wbl, by = c("geo", "year"))
  cli::cli_alert_success("Joined WBL data")
}

# 6. Earnings (only certain years available)
if (!is.null(earnings)) {
  panel <- panel |>
    left_join(earnings, by = c("geo", "year"))
  cli::cli_alert_success("Joined earnings data")
}

# =============================================================================
# ADD DERIVED COLUMNS
# =============================================================================

cli::cli_h2("Adding derived columns")

# Add country names
panel <- panel |>
  standardize_geo_names()

# Add EU membership flag
eu27_members <- c(
  "AT", "BE", "BG", "CY", "CZ", "DE", "DK", "EE", "EL", "ES",
  "FI", "FR", "HR", "HU", "IE", "IT", "LT", "LU", "LV", "MT",
  "NL", "PL", "PT", "RO", "SE", "SI", "SK"
)

panel <- panel |>
  mutate(
    is_eu27 = geo %in% eu27_members,
    is_aggregate = is_eu_aggregate(geo)
  )

# Calculate year-over-year changes
panel <- panel |>
  arrange(geo, year) |>
  group_by(geo) |>
  mutate(
    # ICT share change (percentage points)
    ict_share_change_pp = if ("ict_share_pc_emp" %in% names(panel))
      ict_share_pc_emp - lag(ict_share_pc_emp) else NA_real_,

    # Vacancy rate change (only if vacancy data exists)
    vacancy_rate_J_change = if ("vacancy_rate_J" %in% names(panel))
      vacancy_rate_J - lag(vacancy_rate_J) else NA_real_,

    # Unemployment change
    unemp_rate_change = if ("unemp_rate_pc_act" %in% names(panel))
      unemp_rate_pc_act - lag(unemp_rate_pc_act) else NA_real_,

    # ICT share growth rate (%)
    ict_share_growth_pct = if ("ict_share_pc_emp" %in% names(panel))
      (ict_share_pc_emp / lag(ict_share_pc_emp) - 1) * 100 else NA_real_
  ) |>
  ungroup()

# Calculate graduates per ICT job (where both exist)
if (all(c("grads_ict_tertiary", "ict_employed_ths") %in% names(panel))) {
  panel <- panel |>
    mutate(
      grads_per_ict_job = grads_ict_tertiary / (ict_employed_ths * 1000) * 100
    )
}

cli::cli_alert_success("Added derived columns")

# =============================================================================
# ARRANGE COLUMNS
# =============================================================================

# Define preferred column order
col_order <- c(
  "geo", "geo_name", "year", "is_eu27", "is_aggregate",
  "ict_share_pc_emp", "ict_employed_ths", "ict_share_change_pp", "ict_share_growth_pct",
  "unemp_rate_pc_act", "unemp_rate_change",
  "vacancy_rate_total", "vacancy_rate_J", "vacancy_rate_M", "vacancy_rate_C", "vacancy_rate_J_change",
  "grads_ict_tertiary", "grads_eng_tertiary", "grads_per_ict_job",
  "wbl_exposure_share",
  "median_hourly_earnings_eur"
)

# Select existing columns in order
existing_cols <- intersect(col_order, names(panel))
other_cols <- setdiff(names(panel), col_order)

panel <- panel |>
  select(all_of(existing_cols), all_of(other_cols))

# =============================================================================
# SAVE PANEL
# =============================================================================

cli::cli_h2("Saving panel dataset")

save_rds_csv(panel, file.path(CONFIG$PATHS$processed, "panel_annual"))

# =============================================================================
# CREATE MONTHLY UNEMPLOYMENT FILE
# =============================================================================

cli::cli_h2("Creating monthly unemployment file")

if (!is.null(unemp_monthly)) {
  unemp_monthly_export <- unemp_monthly |>
    standardize_geo_names() |>
    select(geo, geo_name, date, year, month, year_month, unemp_rate_pc_act) |>
    arrange(geo, date)

  save_rds_csv(unemp_monthly_export, file.path(CONFIG$PATHS$processed, "unemp_monthly_2020_2025"))

  cli::cli_alert_info("Monthly unemployment: {nrow(unemp_monthly_export)} observations")
  cli::cli_alert_info("Date range: {min(unemp_monthly_export$date)} to {max(unemp_monthly_export$date)}")
}

# =============================================================================
# PANEL SUMMARY
# =============================================================================

cli::cli_h1("Panel Summary")

cli::cli_alert_success("Panel dimensions: {nrow(panel)} rows x {ncol(panel)} columns")
cli::cli_alert_info("Year range: {min(panel$year)} - {max(panel$year)}")
cli::cli_alert_info("Countries: {length(unique(panel$geo))}")

# Data availability summary
cli::cli_h3("Data Availability (non-missing observations)")
if ("ict_share_pc_emp" %in% names(panel)) {
  cli::cli_alert_info("ict_share: {sum(!is.na(panel$ict_share_pc_emp))}")
}
if ("unemp_rate_pc_act" %in% names(panel)) {
  cli::cli_alert_info("unemployment: {sum(!is.na(panel$unemp_rate_pc_act))}")
}
if ("vacancy_rate_J" %in% names(panel)) {
  cli::cli_alert_info("vacancies_J: {sum(!is.na(panel$vacancy_rate_J))}")
}
if ("grads_ict_tertiary" %in% names(panel)) {
  cli::cli_alert_info("graduates_ict: {sum(!is.na(panel$grads_ict_tertiary))}")
}
if ("median_hourly_earnings_eur" %in% names(panel)) {
  cli::cli_alert_info("earnings: {sum(!is.na(panel$median_hourly_earnings_eur))}")
}

# Latest year summary for EU27
latest_year <- max(panel$year)
eu27_latest <- panel |>
  filter(geo == "EU27_2020", year == latest_year)

if (nrow(eu27_latest) > 0) {
  cli::cli_h3("EU27 Latest Values ({latest_year})")
  if ("ict_share_pc_emp" %in% names(eu27_latest) && !is.na(eu27_latest$ict_share_pc_emp)) {
    cli::cli_alert_info("ICT Share: {round(eu27_latest$ict_share_pc_emp, 1)}%")
  }
  if ("unemp_rate_pc_act" %in% names(eu27_latest) && !is.na(eu27_latest$unemp_rate_pc_act)) {
    cli::cli_alert_info("Unemployment Rate: {round(eu27_latest$unemp_rate_pc_act, 1)}%")
  }
  if ("vacancy_rate_J" %in% names(eu27_latest) && !is.na(eu27_latest$vacancy_rate_J)) {
    cli::cli_alert_info("Vacancy Rate (Info & Comm): {round(eu27_latest$vacancy_rate_J, 1)}%")
  }
}

cli::cli_alert_success("Panel construction complete!")
