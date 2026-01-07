# =============================================================================
# 02_clean.R - Clean and Transform Eurostat Data
# European Tech & Engineering Job Market Analysis
# =============================================================================

cli::cli_h1("Cleaning Eurostat Data")

# Ensure setup is loaded
if (!exists("CONFIG")) {
  source(here::here("R", "00_setup.R"))
}

# Helper to safely load raw data
load_raw <- function(filename) {
  path <- file.path(CONFIG$PATHS$raw, filename)
  if (file.exists(path)) {
    readRDS(path)
  } else {
    cli::cli_alert_warning("File not found: {filename}")
    NULL
  }
}

# =============================================================================
# 1. ICT SPECIALISTS
# =============================================================================

cli::cli_h2("1. Cleaning ICT Specialists Data")

ict_raw <- load_raw("isoc_sks_itspt.rds")

if (!is.null(ict_raw)) {
  ict_clean <- ict_raw |>
    janitor::clean_names() |>
    filter(
      time >= min(CONFIG$YEARS_ANNUAL),
      time <= max(CONFIG$YEARS_ANNUAL),
      geo %in% CONFIG$GEO_KEEP
    ) |>
    select(geo, year = time, unit, values) |>
    filter(!is.na(values)) |>
    pivot_wider(
      names_from = unit,
      values_from = values,
      names_prefix = "ict_"
    ) |>
    rename_with(tolower) |>
    rename(
      ict_share_pc_emp = any_of(c("ict_pc_emp", "ict_PC_EMP")),
      ict_employed_ths = any_of(c("ict_ths_per", "ict_THS_PER"))
    ) |>
    # Handle case where columns might not exist
    mutate(across(starts_with("ict_"), as.numeric))

  # Standardize column names if pivot didn't work as expected
  if (!"ict_share_pc_emp" %in% names(ict_clean) && "ict_pc_emp" %in% names(ict_clean)) {
    ict_clean <- ict_clean |> rename(ict_share_pc_emp = ict_pc_emp)
  }
  if (!"ict_employed_ths" %in% names(ict_clean) && "ict_ths_per" %in% names(ict_clean)) {
    ict_clean <- ict_clean |> rename(ict_employed_ths = ict_ths_per)
  }

  save_rds_csv(ict_clean, file.path(CONFIG$PATHS$processed, "ict_specialists_clean"))

  cli::cli_alert_info("Rows: {nrow(ict_clean)}, Years: {min(ict_clean$year)}-{max(ict_clean$year)}")
} else {
  ict_clean <- NULL
}

# =============================================================================
# 2. UNEMPLOYMENT - ANNUAL
# =============================================================================

cli::cli_h2("2. Cleaning Annual Unemployment Data")

unemp_annual_raw <- load_raw("une_rt_a.rds")

if (!is.null(unemp_annual_raw)) {
  unemp_annual_clean <- unemp_annual_raw |>
    janitor::clean_names() |>
    filter(
      time >= min(CONFIG$YEARS_ANNUAL),
      time <= max(CONFIG$YEARS_ANNUAL),
      geo %in% CONFIG$GEO_KEEP
    ) |>
    select(geo, year = time, unemp_rate_pc_act = values) |>
    filter(!is.na(unemp_rate_pc_act)) |>
    distinct(geo, year, .keep_all = TRUE)

  save_rds_csv(unemp_annual_clean, file.path(CONFIG$PATHS$processed, "unemployment_annual_clean"))

  cli::cli_alert_info("Rows: {nrow(unemp_annual_clean)}, Years: {min(unemp_annual_clean$year)}-{max(unemp_annual_clean$year)}")
} else {
  unemp_annual_clean <- NULL
}

# =============================================================================
# 3. UNEMPLOYMENT - MONTHLY
# =============================================================================

cli::cli_h2("3. Cleaning Monthly Unemployment Data")

unemp_monthly_raw <- load_raw("une_rt_m.rds")

if (!is.null(unemp_monthly_raw)) {
  # Handle both old (time) and new (TIME_PERIOD) column names
  unemp_monthly_clean <- unemp_monthly_raw |>
    janitor::clean_names() |>
    filter(geo %in% CONFIG$GEO_KEEP)

  # Check for time_period (from new eurostat 4.0.0) or time (old version)
  if ("time_period" %in% names(unemp_monthly_clean)) {
    unemp_monthly_clean <- unemp_monthly_clean |>
      select(geo, date = time_period, unemp_rate_pc_act = values)
  } else {
    unemp_monthly_clean <- unemp_monthly_clean |>
      select(geo, date = time, unemp_rate_pc_act = values)
  }

  unemp_monthly_clean <- unemp_monthly_clean |>
    filter(!is.na(unemp_rate_pc_act)) |>
    mutate(
      year = year(date),
      month = month(date),
      year_month = format(date, "%Y-%m")
    ) |>
    arrange(geo, date) |>
    distinct(geo, date, .keep_all = TRUE)

  save_rds_csv(unemp_monthly_clean, file.path(CONFIG$PATHS$processed, "unemployment_monthly_clean"))

  cli::cli_alert_info("Rows: {nrow(unemp_monthly_clean)}, Date range: {min(unemp_monthly_clean$date)} to {max(unemp_monthly_clean$date)}")
} else {
  unemp_monthly_clean <- NULL
}

# =============================================================================
# 4. JOB VACANCIES
# =============================================================================

cli::cli_h2("4. Cleaning Job Vacancies Data")

vacancies_raw <- load_raw("jvs_a_rate_r2.rds")

if (!is.null(vacancies_raw)) {
  vacancies_clean <- vacancies_raw |>
    janitor::clean_names()

  # Handle both old (time) and new (time_period) column names
  time_col <- if ("time_period" %in% names(vacancies_clean)) "time_period" else "time"

  vacancies_clean <- vacancies_clean |>
    filter(
      .data[[time_col]] >= min(CONFIG$YEARS_ANNUAL),
      .data[[time_col]] <= max(CONFIG$YEARS_ANNUAL),
      geo %in% CONFIG$GEO_KEEP
    ) |>
    rename(year = all_of(time_col)) |>
    select(geo, year, nace_r2, values) |>
    filter(!is.na(values)) |>
    # Create clean NACE labels
    mutate(
      nace_label = case_when(
        nace_r2 %in% c("B-S", "B-S_X_O", "TOTAL") ~ "total",
        nace_r2 == "J" ~ "J",
        nace_r2 == "M" ~ "M",
        nace_r2 == "C" ~ "C",
        TRUE ~ nace_r2
      )
    ) |>
    filter(nace_label %in% c("total", "J", "M", "C")) |>
    select(geo, year, nace_label, values) |>
    distinct(geo, year, nace_label, .keep_all = TRUE) |>
    pivot_wider(
      names_from = nace_label,
      values_from = values,
      names_prefix = "vacancy_rate_"
    )

  save_rds_csv(vacancies_clean, file.path(CONFIG$PATHS$processed, "vacancies_clean"))

  cli::cli_alert_info("Rows: {nrow(vacancies_clean)}, Years: {min(vacancies_clean$year)}-{max(vacancies_clean$year)}")
} else {
  vacancies_clean <- NULL
}

# =============================================================================
# 5. GRADUATES
# =============================================================================

cli::cli_h2("5. Cleaning Graduates Data")

graduates_raw <- load_raw("educ_uoe_grad02.rds")

if (!is.null(graduates_raw)) {
  graduates_clean <- graduates_raw |>
    janitor::clean_names() |>
    filter(
      time >= min(CONFIG$YEARS_GRADS),
      time <= max(CONFIG$YEARS_GRADS),
      geo %in% CONFIG$GEO_KEEP
    ) |>
    # Identify field type
    mutate(
      field_type = case_when(
        str_detect(iscedf13, "^F06|^06") ~ "ict",
        str_detect(iscedf13, "^F07|^07") ~ "eng",
        TRUE ~ "other"
      )
    ) |>
    filter(field_type != "other") |>
    select(geo, year = time, field_type, values) |>
    filter(!is.na(values)) |>
    # Aggregate if multiple sub-fields exist
    group_by(geo, year, field_type) |>
    summarise(values = sum(values, na.rm = TRUE), .groups = "drop") |>
    pivot_wider(
      names_from = field_type,
      values_from = values,
      names_prefix = "grads_"
    ) |>
    rename(
      grads_ict_tertiary = any_of(c("grads_ict")),
      grads_eng_tertiary = any_of(c("grads_eng"))
    )

  # Ensure columns exist
  if (!"grads_ict_tertiary" %in% names(graduates_clean)) {
    graduates_clean$grads_ict_tertiary <- NA_real_
  }
  if (!"grads_eng_tertiary" %in% names(graduates_clean)) {
    graduates_clean$grads_eng_tertiary <- NA_real_
  }

  save_rds_csv(graduates_clean, file.path(CONFIG$PATHS$processed, "graduates_clean"))

  cli::cli_alert_info("Rows: {nrow(graduates_clean)}, Years: {min(graduates_clean$year)}-{max(graduates_clean$year)}")
} else {
  graduates_clean <- NULL
}

# =============================================================================
# 6. WORK-BASED LEARNING
# =============================================================================

cli::cli_h2("6. Cleaning Work-Based Learning Data")

wbl_raw <- load_raw("wbl_exposure.rds")

if (!is.null(wbl_raw)) {
  wbl_clean <- wbl_raw |>
    janitor::clean_names() |>
    filter(geo %in% CONFIG$GEO_KEEP) |>
    select(geo, year = time, wbl_exposure_share = values) |>
    filter(!is.na(wbl_exposure_share)) |>
    distinct(geo, year, .keep_all = TRUE)

  save_rds_csv(wbl_clean, file.path(CONFIG$PATHS$processed, "wbl_exposure_clean"))

  cli::cli_alert_info("Rows: {nrow(wbl_clean)}, Years: {min(wbl_clean$year)}-{max(wbl_clean$year)}")
} else {
  wbl_clean <- NULL
  cli::cli_alert_warning("No WBL data available - creating empty placeholder")
}

# =============================================================================
# 7. EARNINGS
# =============================================================================

cli::cli_h2("7. Cleaning Earnings Data")

earnings_raw <- load_raw("earn_ses_pub2s.rds")

if (!is.null(earnings_raw)) {
  earnings_clean <- earnings_raw |>
    janitor::clean_names() |>
    filter(geo %in% CONFIG$GEO_KEEP) |>
    select(geo, year = time, median_hourly_earnings_eur = values) |>
    filter(!is.na(median_hourly_earnings_eur)) |>
    # Keep only years in our config
    filter(year %in% CONFIG$YEARS_EARN | year >= 2014) |>
    distinct(geo, year, .keep_all = TRUE)

  save_rds_csv(earnings_clean, file.path(CONFIG$PATHS$processed, "earnings_clean"))

  cli::cli_alert_info("Rows: {nrow(earnings_clean)}, Years: {paste(unique(earnings_clean$year), collapse=', ')}")
} else {
  earnings_clean <- NULL
  cli::cli_alert_warning("No earnings data available")
}

# =============================================================================
# SUMMARY
# =============================================================================

cli::cli_h1("Cleaning Summary")

processed_files <- list.files(CONFIG$PATHS$processed, pattern = "\\.rds$", full.names = TRUE)

cli::cli_alert_success("Created {length(processed_files)} cleaned datasets in {CONFIG$PATHS$processed}")

for (f in processed_files) {
  df <- readRDS(f)
  cli::cli_alert_info("{basename(f)}: {nrow(df)} rows, {ncol(df)} columns")
}

cli::cli_alert_success("Data cleaning complete!")
