# =============================================================================
# 04_visualize.R - Create Visualizations
# European Tech & Engineering Job Market Analysis
# =============================================================================

cli::cli_h1("Creating Visualizations")

# Ensure setup is loaded
if (!exists("CONFIG")) {
  source(here::here("R", "00_setup.R"))
}

# Load panel data
panel <- readRDS(file.path(CONFIG$PATHS$processed, "panel_annual.rds"))

# Load monthly unemployment if exists
unemp_monthly_path <- file.path(CONFIG$PATHS$processed, "unemp_monthly_2020_2025.rds")
if (file.exists(unemp_monthly_path)) {
  unemp_monthly <- readRDS(unemp_monthly_path)
} else {
  unemp_monthly <- NULL
}

# Define color palette
colors_highlight <- c(
  "EU27_2020" = "#003399",  # EU blue
  "DE" = "#000000",         # Germany
  "FR" = "#0055A4",         # France
  "NL" = "#FF6600",         # Netherlands
  "SE" = "#006AA7",         # Sweden
  "IE" = "#169B62",         # Ireland
  "PL" = "#DC143C",         # Poland
  "ES" = "#AA151B",         # Spain
  "IT" = "#009246",         # Italy
  "Other" = "#CCCCCC"
)

# =============================================================================
# HELPER FUNCTIONS FOR VISUALIZATION
# =============================================================================

# Get top N countries by a metric in the latest year
get_top_countries <- function(data, metric, n = 10, exclude_aggregates = TRUE) {
  latest_year <- max(data$year, na.rm = TRUE)

  top <- data |>
    filter(
      year == latest_year,
      !is.na(.data[[metric]])
    )

  if (exclude_aggregates) {
    top <- top |> filter(!is_aggregate)
  }

  top |>
    arrange(desc(.data[[metric]])) |>
    head(n) |>
    pull(geo)
}

# =============================================================================
# FIGURE 1: ICT SHARE TREND
# =============================================================================

cli::cli_h2("Figure 1: ICT Share Trend")

if ("ict_share_pc_emp" %in% names(panel)) {
  top_ict_countries <- get_top_countries(panel, "ict_share_pc_emp", n = 8)
  highlight_geos <- c("EU27_2020", top_ict_countries)

  plot_data <- panel |>
    filter(geo %in% highlight_geos, !is.na(ict_share_pc_emp)) |>
    mutate(
      geo_label = if_else(geo == "EU27_2020", "EU27", geo_name),
      is_eu = geo == "EU27_2020"
    )

  fig01 <- ggplot(plot_data, aes(x = year, y = ict_share_pc_emp, color = geo_label, group = geo)) +
    geom_line(aes(linewidth = is_eu), show.legend = FALSE) +
    geom_point(size = 1.5) +
    scale_linewidth_manual(values = c("TRUE" = 1.5, "FALSE" = 0.7)) +
    scale_color_manual(
      values = setNames(
        c("#003399", scales::hue_pal()(length(top_ict_countries))),
        c("EU27", unique(plot_data$geo_label[plot_data$geo != "EU27_2020"]))
      )
    ) +
    scale_x_continuous(breaks = seq(2014, 2024, 2)) +
    labs(
      title = "Employed ICT Specialists as Share of Total Employment",
      subtitle = "EU27 and top 8 countries by latest ICT share",
      x = NULL,
      y = "% of total employment",
      color = "Country",
      caption = "Source: Eurostat (isoc_sks_itspt)"
    ) +
    theme_project() +
    theme(legend.position = "right")

  save_figure(fig01, "fig01_ict_share_trend.png", width = 10, height = 6)
} else {
  cli::cli_alert_warning("Skipping Figure 1: ICT share data not available")
}

# =============================================================================
# FIGURE 2: ICT EMPLOYED (ABSOLUTE)
# =============================================================================

cli::cli_h2("Figure 2: ICT Employed (Absolute)")

if ("ict_employed_ths" %in% names(panel) && any(!is.na(panel$ict_employed_ths))) {
  top_ict_abs <- get_top_countries(panel, "ict_employed_ths", n = 8)
  highlight_geos <- c("EU27_2020", top_ict_abs)

  plot_data <- panel |>
    filter(geo %in% highlight_geos, !is.na(ict_employed_ths)) |>
    mutate(geo_label = if_else(geo == "EU27_2020", "EU27", geo_name))

  fig02 <- ggplot(plot_data, aes(x = year, y = ict_employed_ths, color = geo_label, group = geo)) +
    geom_line() +
    geom_point(size = 1.5) +
    scale_x_continuous(breaks = seq(2014, 2024, 2)) +
    scale_y_continuous(labels = scales::comma) +
    labs(
      title = "Number of Employed ICT Specialists",
      subtitle = "Thousands of persons",
      x = NULL,
      y = "Thousands",
      color = "Country",
      caption = "Source: Eurostat (isoc_sks_itspt)"
    ) +
    theme_project() +
    theme(legend.position = "right")

  save_figure(fig02, "fig02_ict_employed_trend.png", width = 10, height = 6)
} else {
  cli::cli_alert_warning("Skipping Figure 2: ICT employed absolute data not available")
}

# =============================================================================
# FIGURE 3: VACANCY RATE TREND (SECTOR J)
# =============================================================================

cli::cli_h2("Figure 3: Vacancy Rate Trend (Sector J)")

if ("vacancy_rate_J" %in% names(panel) && any(!is.na(panel$vacancy_rate_J))) {
  top_vacancy <- get_top_countries(panel, "vacancy_rate_J", n = 8)
  highlight_geos <- c("EU27_2020", top_vacancy)

  plot_data <- panel |>
    filter(geo %in% highlight_geos, !is.na(vacancy_rate_J)) |>
    mutate(geo_label = if_else(geo == "EU27_2020", "EU27", geo_name))

  fig03 <- ggplot(plot_data, aes(x = year, y = vacancy_rate_J, color = geo_label, group = geo)) +
    geom_line() +
    geom_point(size = 1.5) +
    scale_x_continuous(breaks = seq(2014, 2024, 2)) +
    labs(
      title = "Job Vacancy Rate in Information & Communication Sector",
      subtitle = "NACE Rev.2 Section J",
      x = NULL,
      y = "Vacancy rate (%)",
      color = "Country",
      caption = "Source: Eurostat (jvs_a_rate_r2)"
    ) +
    theme_project() +
    theme(legend.position = "right")

  save_figure(fig03, "fig03_vacancy_rate_J_trend.png", width = 10, height = 6)
} else {
  cli::cli_alert_warning("Skipping Figure 3: Vacancy rate J data not available")
}

# =============================================================================
# FIGURE 4: BEVERIDGE CURVE (UNEMPLOYMENT VS VACANCY)
# =============================================================================

cli::cli_h2("Figure 4: Beveridge Curve")

vacancy_col <- if ("vacancy_rate_total" %in% names(panel)) "vacancy_rate_total" else "vacancy_rate_J"

if (vacancy_col %in% names(panel) && "unemp_rate_pc_act" %in% names(panel)) {
  plot_data <- panel |>
    filter(
      geo == "EU27_2020",
      !is.na(.data[[vacancy_col]]),
      !is.na(unemp_rate_pc_act)
    )

  if (nrow(plot_data) > 0) {
    fig04 <- ggplot(plot_data, aes(x = unemp_rate_pc_act, y = .data[[vacancy_col]])) +
      geom_path(color = "gray50", alpha = 0.5) +
      geom_point(aes(color = year), size = 3) +
      geom_text(aes(label = year), vjust = -0.8, size = 3) +
      scale_color_viridis_c(option = "plasma") +
      labs(
        title = "Beveridge Curve: EU27 Unemployment vs Job Vacancies",
        subtitle = "Each point represents one year",
        x = "Unemployment rate (%)",
        y = "Job vacancy rate (%)",
        color = "Year",
        caption = "Source: Eurostat (une_rt_a, jvs_a_rate_r2)"
      ) +
      theme_project() +
      theme(legend.position = "right")

    save_figure(fig04, "fig04_unemp_vs_vacancy.png", width = 9, height = 7)
  }
} else {
  cli::cli_alert_warning("Skipping Figure 4: Missing unemployment or vacancy data")
}

# =============================================================================
# FIGURE 5: GRADUATES TREND (ICT VS ENGINEERING)
# =============================================================================

cli::cli_h2("Figure 5: Graduates Trend")

if (all(c("grads_ict_tertiary", "grads_eng_tertiary") %in% names(panel))) {
  plot_data <- panel |>
    filter(geo == "EU27_2020") |>
    select(year, grads_ict_tertiary, grads_eng_tertiary) |>
    filter(!is.na(grads_ict_tertiary) | !is.na(grads_eng_tertiary)) |>
    pivot_longer(
      cols = c(grads_ict_tertiary, grads_eng_tertiary),
      names_to = "field",
      values_to = "graduates"
    ) |>
    mutate(
      field_label = case_when(
        field == "grads_ict_tertiary" ~ "ICT",
        field == "grads_eng_tertiary" ~ "Engineering & Manufacturing",
        TRUE ~ field
      )
    ) |>
    filter(!is.na(graduates))

  if (nrow(plot_data) > 0) {
    fig05 <- ggplot(plot_data, aes(x = year, y = graduates / 1000, color = field_label)) +
      geom_line(linewidth = 1) +
      geom_point(size = 2) +
      scale_x_continuous(breaks = seq(2014, 2024, 2)) +
      scale_y_continuous(labels = scales::comma) +
      scale_color_manual(values = c("ICT" = "#E69F00", "Engineering & Manufacturing" = "#56B4E9")) +
      labs(
        title = "Tertiary Graduates in ICT and Engineering Fields",
        subtitle = "EU27 total",
        x = NULL,
        y = "Graduates (thousands)",
        color = "Field",
        caption = "Source: Eurostat (educ_uoe_grad02)"
      ) +
      theme_project()

    save_figure(fig05, "fig05_graduates_ict_vs_eng.png", width = 10, height = 6)
  }
} else {
  cli::cli_alert_warning("Skipping Figure 5: Graduates data not available")
}

# =============================================================================
# FIGURE 6: SALARY VS ICT SHARE
# =============================================================================

cli::cli_h2("Figure 6: Salary vs ICT Share")

if (all(c("median_hourly_earnings_eur", "ict_share_pc_emp") %in% names(panel))) {
  # Use latest available year for both variables
  plot_data <- panel |>
    filter(
      !is_aggregate,
      !is.na(median_hourly_earnings_eur),
      !is.na(ict_share_pc_emp)
    ) |>
    group_by(geo) |>
    filter(year == max(year)) |>
    ungroup()

  if (nrow(plot_data) >= 5) {
    # Calculate correlation
    corr <- cor(plot_data$ict_share_pc_emp, plot_data$median_hourly_earnings_eur, use = "complete.obs")

    fig06 <- ggplot(plot_data, aes(x = ict_share_pc_emp, y = median_hourly_earnings_eur)) +
      geom_point(aes(color = is_eu27), size = 3, alpha = 0.7) +
      geom_smooth(method = "lm", se = TRUE, color = "gray40", linetype = "dashed") +
      geom_text(aes(label = geo), size = 2.5, vjust = -0.8, check_overlap = TRUE) +
      scale_color_manual(values = c("TRUE" = "#003399", "FALSE" = "#999999"), guide = "none") +
      labs(
        title = "Relationship Between ICT Employment Share and Hourly Earnings",
        subtitle = sprintf("Correlation: r = %.2f (latest available year per country)", corr),
        x = "ICT specialists (% of employment)",
        y = "Median hourly earnings (EUR)",
        caption = "Source: Eurostat (isoc_sks_itspt, earn_ses_pub2s)"
      ) +
      theme_project()

    save_figure(fig06, "fig06_salary_vs_ict_share.png", width = 10, height = 8)
  } else {
    cli::cli_alert_warning("Skipping Figure 6: Not enough data points for salary vs ICT correlation")
  }
} else {
  cli::cli_alert_warning("Skipping Figure 6: Missing earnings or ICT share data")
}

# =============================================================================
# FIGURE 7: WBL EXPOSURE BAR CHART
# =============================================================================

cli::cli_h2("Figure 7: Work-Based Learning Exposure")

if ("wbl_exposure_share" %in% names(panel) && any(!is.na(panel$wbl_exposure_share))) {
  latest_year_wbl <- panel |>
    filter(!is.na(wbl_exposure_share), !is_aggregate) |>
    pull(year) |>
    max()

  plot_data <- panel |>
    filter(
      year == latest_year_wbl,
      !is.na(wbl_exposure_share),
      !is_aggregate
    ) |>
    arrange(desc(wbl_exposure_share)) |>
    head(20) |>
    mutate(geo_name = fct_reorder(geo_name, wbl_exposure_share))

  if (nrow(plot_data) > 0) {
    fig07 <- ggplot(plot_data, aes(x = wbl_exposure_share, y = geo_name)) +
      geom_col(aes(fill = is_eu27), show.legend = FALSE) +
      scale_fill_manual(values = c("TRUE" = "#003399", "FALSE" = "#999999")) +
      labs(
        title = "Exposure of VET Graduates to Work-Based Learning",
        subtitle = sprintf("Top 20 countries (%d)", latest_year_wbl),
        x = "Share (%)",
        y = NULL,
        caption = "Source: Eurostat"
      ) +
      theme_project()

    save_figure(fig07, "fig07_wbl_exposure_bar.png", width = 9, height = 8)
  }
} else {
  cli::cli_alert_warning("Skipping Figure 7: WBL exposure data not available")
}

# =============================================================================
# FIGURE 8: ICT SHARE CROSS-COUNTRY COMPARISON (LATEST YEAR)
# =============================================================================

cli::cli_h2("Figure 8: ICT Share Cross-Country Comparison")

if ("ict_share_pc_emp" %in% names(panel)) {
  latest_year <- max(panel$year[!is.na(panel$ict_share_pc_emp)])

  plot_data <- panel |>
    filter(
      year == latest_year,
      !is.na(ict_share_pc_emp),
      !is_aggregate
    ) |>
    arrange(desc(ict_share_pc_emp)) |>
    mutate(
      rank = row_number(),
      position = case_when(
        rank <= 10 ~ "Top 10",
        rank > n() - 10 ~ "Bottom 10",
        TRUE ~ "Middle"
      )
    ) |>
    filter(position != "Middle") |>
    mutate(geo_name = fct_reorder(geo_name, ict_share_pc_emp))

  if (nrow(plot_data) > 0) {
    fig08 <- ggplot(plot_data, aes(x = ict_share_pc_emp, y = geo_name)) +
      geom_col(aes(fill = position)) +
      scale_fill_manual(values = c("Top 10" = "#003399", "Bottom 10" = "#CC3333")) +
      labs(
        title = "ICT Specialists Share: Top and Bottom 10 Countries",
        subtitle = sprintf("Year: %d", latest_year),
        x = "% of total employment",
        y = NULL,
        fill = NULL,
        caption = "Source: Eurostat (isoc_sks_itspt)"
      ) +
      theme_project() +
      theme(legend.position = "top")

    save_figure(fig08, "fig08_ict_share_ranking.png", width = 9, height = 8)
  }
}

# =============================================================================
# SUMMARY TABLES
# =============================================================================

cli::cli_h2("Creating Summary Tables")

# Latest year ranking
latest_year <- max(panel$year, na.rm = TRUE)

# Select columns that exist
ranking_cols <- c("geo", "geo_name", "ict_share_pc_emp", "unemp_rate_pc_act")
if ("vacancy_rate_J" %in% names(panel)) {
  ranking_cols <- c(ranking_cols, "vacancy_rate_J")
}

ranking_table <- panel |>
  filter(year == latest_year, !is_aggregate) |>
  select(any_of(ranking_cols)) |>
  filter(!is.na(ict_share_pc_emp)) |>
  arrange(desc(ict_share_pc_emp)) |>
  mutate(
    ict_rank = rank(-ict_share_pc_emp, na.last = "keep")
  )

if ("vacancy_rate_J" %in% names(ranking_table)) {
  ranking_table <- ranking_table |>
    mutate(vacancy_J_rank = rank(-vacancy_rate_J, na.last = "keep"))
}

write_csv(ranking_table, file.path(CONFIG$PATHS$tables, "latest_year_ranking.csv"))
cli::cli_alert_success("Saved latest_year_ranking.csv")

# Correlation matrix
numeric_cols <- panel |>
  select(where(is.numeric)) |>
  select(-year, -matches("change|growth|rank")) |>
  select(where(~ sum(!is.na(.x)) > 50))

if (ncol(numeric_cols) >= 3) {
  corr_matrix <- cor(numeric_cols, use = "pairwise.complete.obs")
  corr_df <- as.data.frame(corr_matrix) |>
    rownames_to_column("variable")

  write_csv(corr_df, file.path(CONFIG$PATHS$tables, "correlations.csv"))
  cli::cli_alert_success("Saved correlations.csv")
}

# =============================================================================
# SUMMARY
# =============================================================================

cli::cli_h1("Visualization Summary")

fig_files <- list.files(CONFIG$PATHS$figures, pattern = "\\.png$")
table_files <- list.files(CONFIG$PATHS$tables, pattern = "\\.csv$")

cli::cli_alert_success("Created {length(fig_files)} figures in {CONFIG$PATHS$figures}")
cli::cli_alert_success("Created {length(table_files)} tables in {CONFIG$PATHS$tables}")

for (f in fig_files) {
  cli::cli_alert_info("  {f}")
}

cli::cli_alert_success("Visualization complete!")
