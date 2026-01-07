# =============================================================================
# 01_download.R - Download Eurostat Datasets
# European Tech & Engineering Job Market Analysis
# =============================================================================

cli::cli_h1("Downloading Eurostat Data")

# Ensure setup is loaded
if (!exists("CONFIG")) {
  source(here::here("R", "00_setup.R"))
}

# =============================================================================
# 1. ICT SPECIALISTS (isoc_sks_itspt)
# =============================================================================

cli::cli_h2("1. ICT Specialists Employment")

ict_specialists <- download_dataset(
  id = "isoc_sks_itspt",
  filters = list(
    unit = c("PC_EMP", "THS_PER"),
    geo = CONFIG$GEO_KEEP
  ),
  time_format = "num"
)

if (!is.null(ict_specialists)) {
  saveRDS(ict_specialists, file.path(CONFIG$PATHS$raw, "isoc_sks_itspt.rds"))

  # Summary
  cli::cli_alert_info("Years available: {min(ict_specialists$time, na.rm=TRUE)}-{max(ict_specialists$time, na.rm=TRUE)}")
  cli::cli_alert_info("Countries: {length(unique(ict_specialists$geo))}")
  cli::cli_alert_info("Units: {paste(unique(ict_specialists$unit), collapse=', ')}")
}

# =============================================================================
# 2. UNEMPLOYMENT - ANNUAL (une_rt_a)
# =============================================================================

cli::cli_h2("2. Unemployment Rate - Annual")

unemp_annual <- download_dataset(
  id = "une_rt_a",
  filters = list(
    sex = "T",
    age = "Y15-74",
    unit = "PC_ACT",
    geo = CONFIG$GEO_KEEP
  ),
  time_format = "num"
)

if (!is.null(unemp_annual)) {
  saveRDS(unemp_annual, file.path(CONFIG$PATHS$raw, "une_rt_a.rds"))

  cli::cli_alert_info("Years available: {min(unemp_annual$time, na.rm=TRUE)}-{max(unemp_annual$time, na.rm=TRUE)}")
  cli::cli_alert_info("Countries: {length(unique(unemp_annual$geo))}")
}

# =============================================================================
# 3. UNEMPLOYMENT - MONTHLY (une_rt_m)
# =============================================================================

cli::cli_h2("3. Unemployment Rate - Monthly")

unemp_monthly <- download_dataset(
  id = "une_rt_m",
  filters = list(
    sex = "T",
    age = "Y15-74",
    unit = "PC_ACT",
    s_adj = "SA",  # Seasonally adjusted
    geo = CONFIG$GEO_KEEP
  ),
  time_format = "date"
)

if (!is.null(unemp_monthly)) {
  # Filter to 2020 onwards
  unemp_monthly <- unemp_monthly |>
    filter(time >= as.Date(CONFIG$MONTHLY_START))

  saveRDS(unemp_monthly, file.path(CONFIG$PATHS$raw, "une_rt_m.rds"))

  cli::cli_alert_info("Date range: {min(unemp_monthly$time)} to {max(unemp_monthly$time)}")
  cli::cli_alert_info("Countries: {length(unique(unemp_monthly$geo))}")
}

# =============================================================================
# 4. JOB VACANCIES (jvs_a_rate_r2)
# =============================================================================

cli::cli_h2("4. Job Vacancy Rate")

# Try to download with NACE sectors
vacancies <- download_dataset(
  id = "jvs_a_rate_r2",
  filters = list(
    sizeclas = "TOTAL",
    nace_r2 = c("B-S", "J", "M", "C"),
    s_adj = "NSA",
    geo = CONFIG$GEO_KEEP
  ),
  time_format = "num"
)

if (!is.null(vacancies)) {
  saveRDS(vacancies, file.path(CONFIG$PATHS$raw, "jvs_a_rate_r2.rds"))

  cli::cli_alert_info("Years available: {min(vacancies$time, na.rm=TRUE)}-{max(vacancies$time, na.rm=TRUE)}")
  cli::cli_alert_info("NACE sectors: {paste(unique(vacancies$nace_r2), collapse=', ')}")
  cli::cli_alert_info("Countries: {length(unique(vacancies$geo))}")
}

# =============================================================================
# 5. GRADUATES (educ_uoe_grad02)
# =============================================================================

cli::cli_h2("5. Tertiary Graduates - ICT & Engineering")

# First, get the field of education dictionary to find correct codes
isced_f_dic <- get_dic_safe("isced11")
if (!is.null(isced_f_dic)) {
  cli::cli_alert_info("ISCED-F dictionary loaded")
}

# Download graduates data - filter heavily
# ISCED-F 2013 field codes:
# F06 = Information and Communication Technologies (ICTs)
# F07 = Engineering, manufacturing and construction

graduates <- download_dataset(
  id = "educ_uoe_grad02",
  filters = list(
    sex = "T",
    isced11 = c("ED5-8"),  # All tertiary levels combined
    iscedf13 = c("F06", "F07", "F0610", "F0710", "F0720", "F0730"),
    geo = CONFIG$GEO_KEEP
  ),
  time_format = "num"
)

if (!is.null(graduates)) {
  # Filter to years of interest
  graduates <- graduates |>
    filter(time >= min(CONFIG$YEARS_GRADS) & time <= max(CONFIG$YEARS_GRADS))

  saveRDS(graduates, file.path(CONFIG$PATHS$raw, "educ_uoe_grad02.rds"))

  cli::cli_alert_info("Years available: {min(graduates$time, na.rm=TRUE)}-{max(graduates$time, na.rm=TRUE)}")
  cli::cli_alert_info("Fields: {paste(unique(graduates$iscedf13), collapse=', ')}")
  cli::cli_alert_info("Countries: {length(unique(graduates$geo))}")
} else {
  # Fallback: try broader filter
  cli::cli_alert_warning("Trying broader graduate filter...")
  graduates <- download_dataset(
    id = "educ_uoe_grad02",
    filters = list(
      sex = "T",
      geo = CONFIG$GEO_KEEP
    ),
    time_format = "num"
  )

  if (!is.null(graduates)) {
    # Filter post-download
    graduates <- graduates |>
      filter(
        time >= min(CONFIG$YEARS_GRADS),
        time <= max(CONFIG$YEARS_GRADS),
        str_detect(isced11, "ED5|ED6|ED7|ED8") | isced11 == "ED5-8",
        str_detect(iscedf13, "^F0[67]")
      )

    saveRDS(graduates, file.path(CONFIG$PATHS$raw, "educ_uoe_grad02.rds"))
    cli::cli_alert_info("Downloaded and filtered graduates data")
  }
}

# =============================================================================
# 6. VET WORK-BASED LEARNING (trng_vet_wbl or tps00215)
# =============================================================================

cli::cli_h2("6. VET Work-Based Learning Exposure")

# Try primary dataset
wbl <- download_dataset(
  id = "edat_lfs_9919",  # VET graduates employed with work-based learning
  filters = list(
    sex = "T",
    age = "Y15-34",
    geo = CONFIG$GEO_KEEP
  ),
  time_format = "num"
)

if (is.null(wbl)) {
  # Try alternative dataset
  cli::cli_alert_info("Trying alternative WBL dataset...")
  wbl <- download_dataset(
    id = "trng_vet_wbl",
    filters = list(
      geo = CONFIG$GEO_KEEP
    ),
    time_format = "num"
  )
}

if (is.null(wbl)) {
  # Try tps00215 as final fallback
  cli::cli_alert_info("Trying tps00215 dataset...")
  wbl <- download_dataset(
    id = "tps00215",
    filters = list(
      geo = CONFIG$GEO_KEEP
    ),
    time_format = "num"
  )
}

if (!is.null(wbl)) {
  saveRDS(wbl, file.path(CONFIG$PATHS$raw, "wbl_exposure.rds"))

  cli::cli_alert_info("Years available: {min(wbl$time, na.rm=TRUE)}-{max(wbl$time, na.rm=TRUE)}")
  cli::cli_alert_info("Countries: {length(unique(wbl$geo))}")
} else {
  cli::cli_alert_warning("Could not download WBL data - will proceed without it")
}

# =============================================================================
# 7. EARNINGS (earn_ses_pub2s)
# =============================================================================

cli::cli_h2("7. Median Hourly Earnings")

earnings <- download_dataset(
  id = "earn_ses_pub2s",
  filters = list(
    sex = "T",
    geo = CONFIG$GEO_KEEP
  ),
  time_format = "num"
)

if (!is.null(earnings)) {
  saveRDS(earnings, file.path(CONFIG$PATHS$raw, "earn_ses_pub2s.rds"))

  cli::cli_alert_info("Years available: {unique(earnings$time)}")
  cli::cli_alert_info("Countries: {length(unique(earnings$geo))}")
} else {
  # Try alternative earnings dataset
  cli::cli_alert_info("Trying alternative earnings dataset (earn_ses_annual)...")
  earnings <- download_dataset(
    id = "earn_ses_annual",
    filters = list(
      sex = "T",
      geo = CONFIG$GEO_KEEP
    ),
    time_format = "num"
  )

  if (!is.null(earnings)) {
    saveRDS(earnings, file.path(CONFIG$PATHS$raw, "earn_ses_pub2s.rds"))
  }
}

# =============================================================================
# SUMMARY
# =============================================================================

cli::cli_h1("Download Summary")

raw_files <- list.files(CONFIG$PATHS$raw, pattern = "\\.rds$", full.names = TRUE)

cli::cli_alert_success("Downloaded {length(raw_files)} datasets to {CONFIG$PATHS$raw}")

for (f in raw_files) {
  df <- readRDS(f)
  cli::cli_alert_info("{basename(f)}: {nrow(df)} rows, {ncol(df)} columns")
}

cli::cli_alert_success("Data download complete!")
