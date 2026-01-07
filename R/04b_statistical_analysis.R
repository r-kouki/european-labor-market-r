# =============================================================================
# 04b_statistical_analysis.R - Statistical Hypothesis Testing
# European Tech & Engineering Job Market Analysis
# =============================================================================

cli::cli_h1("Statistical Analysis & Hypothesis Testing")

# Ensure setup is loaded
if (!exists("CONFIG")) {
  source(here::here("R", "00_setup.R"))
}

# Load required packages
library(broom)
library(lmtest)

# Load panel data
panel <- readRDS(file.path(CONFIG$PATHS$processed, "panel_annual.rds"))

# Create output list for test results
test_results <- list()

# =============================================================================
# TEST 1: TIME TREND - ICT Employment Growth Significance
# =============================================================================

cli::cli_h2("Test 1: Time Trend Analysis (ICT Employment Growth)")

eu27_trend <- panel |>
  filter(geo == "EU27_2020", !is.na(ict_share_pc_emp))

if (nrow(eu27_trend) > 5) {
  model_trend <- lm(ict_share_pc_emp ~ year, data = eu27_trend)
  trend_summary <- tidy(model_trend)
  trend_glance <- glance(model_trend)
  
  # Extract key statistics
  slope <- trend_summary$estimate[2]
  p_value <- trend_summary$p.value[2]
  r_squared <- trend_glance$r.squared
  
  test_results$trend <- list(
    test_name = "Linear Time Trend",
    hypothesis = "ICT employment share has increased significantly over time",
    statistic = slope,
    p_value = p_value,
    r_squared = r_squared,
    result = ifelse(p_value < 0.05, "SIGNIFICANT", "NOT SIGNIFICANT"),
    interpretation = sprintf("ICT share increases by %.3f percentage points per year", slope)
  )
  
  cli::cli_alert_success("Time trend: slope = {round(slope, 4)}, p = {format.pval(p_value, digits = 3)}, R² = {round(r_squared, 3)}")
} else {
  cli::cli_alert_warning("Insufficient data for time trend analysis")
}

# =============================================================================
# TEST 2: PAIRED T-TEST - Tech Sector vs Total Economy Vacancy Rates
# =============================================================================

cli::cli_h2("Test 2: Vacancy Rates - Tech Sector vs Overall Economy")

vacancy_data <- panel |>
  filter(!is.na(vacancy_rate_J), !is.na(vacancy_rate_total))

if (nrow(vacancy_data) > 10) {
  vacancy_test <- t.test(
    vacancy_data$vacancy_rate_J,
    vacancy_data$vacancy_rate_total,
    paired = TRUE
  )
  
  vacancy_tidy <- tidy(vacancy_test)
  mean_diff <- vacancy_tidy$estimate
  
  test_results$vacancy_comparison <- list(
    test_name = "Paired t-test",
    hypothesis = "ICT sector vacancy rates exceed overall economy vacancy rates",
    statistic = vacancy_tidy$statistic,
    p_value = vacancy_tidy$p.value,
    mean_difference = mean_diff,
    result = ifelse(vacancy_tidy$p.value < 0.05, "SIGNIFICANT", "NOT SIGNIFICANT"),
    interpretation = sprintf("Tech sector vacancies are %.2f%% higher on average", mean_diff)
  )
  
  cli::cli_alert_success("Vacancy comparison: mean diff = {round(mean_diff, 3)}%, p = {format.pval(vacancy_tidy$p.value, digits = 3)}")
} else {
  cli::cli_alert_warning("Insufficient data for vacancy rate comparison")
  test_results$vacancy_comparison <- list(
    test_name = "Paired t-test",
    result = "INSUFFICIENT DATA"
  )
}

# =============================================================================
# TEST 3: CORRELATION - Earnings vs ICT Employment
# =============================================================================

cli::cli_h2("Test 3: Earnings-ICT Employment Correlation")

earnings_data <- panel |>
  filter(!is.na(median_hourly_earnings_eur), !is.na(ict_share_pc_emp))

if (nrow(earnings_data) > 10) {
  cor_test <- cor.test(
    earnings_data$ict_share_pc_emp,
    earnings_data$median_hourly_earnings_eur,
    method = "pearson"
  )
  
  cor_tidy <- tidy(cor_test)
  
  test_results$earnings_correlation <- list(
    test_name = "Pearson Correlation",
    hypothesis = "Higher ICT employment correlates with higher earnings",
    statistic = cor_tidy$estimate,
    p_value = cor_tidy$p.value,
    conf_low = cor_tidy$conf.low,
    conf_high = cor_tidy$conf.high,
    n_obs = nrow(earnings_data),
    result = ifelse(cor_tidy$p.value < 0.05, "SIGNIFICANT", "NOT SIGNIFICANT"),
    interpretation = sprintf("Correlation = %.3f (95%% CI: %.3f to %.3f)", 
                           cor_tidy$estimate, cor_tidy$conf.low, cor_tidy$conf.high)
  )
  
  cli::cli_alert_success("Earnings correlation: r = {round(cor_tidy$estimate, 3)}, p = {format.pval(cor_tidy$p.value, digits = 3)}")
} else {
  cli::cli_alert_warning("Insufficient data for earnings correlation")
}

# =============================================================================
# TEST 4: BEVERIDGE CURVE - Unemployment-Vacancy Relationship
# =============================================================================

cli::cli_h2("Test 4: Beveridge Curve Relationship")

beveridge_data <- panel |>
  filter(
    geo == "EU27_2020",
    !is.na(unemp_rate_pc_act),
    !is.na(vacancy_rate_total)
  )

if (nrow(beveridge_data) > 5) {
  # Test negative relationship
  beveridge_cor <- cor.test(
    beveridge_data$unemp_rate_pc_act,
    beveridge_data$vacancy_rate_total,
    method = "pearson"
  )
  
  beveridge_tidy <- tidy(beveridge_cor)
  
  # Linear model for additional insight
  beveridge_lm <- lm(vacancy_rate_total ~ unemp_rate_pc_act, data = beveridge_data)
  beveridge_lm_tidy <- tidy(beveridge_lm)
  
  test_results$beveridge <- list(
    test_name = "Beveridge Curve (Correlation)",
    hypothesis = "Unemployment and vacancy rates are negatively correlated",
    correlation = beveridge_tidy$estimate,
    p_value = beveridge_tidy$p.value,
    slope = beveridge_lm_tidy$estimate[2],
    result = ifelse(beveridge_tidy$p.value < 0.05, "SIGNIFICANT", "NOT SIGNIFICANT"),
    interpretation = sprintf("Correlation = %.3f (negative = tighter labor market)", beveridge_tidy$estimate)
  )
  
  cli::cli_alert_success("Beveridge relationship: r = {round(beveridge_tidy$estimate, 3)}, p = {format.pval(beveridge_tidy$p.value, digits = 3)}")
} else {
  cli::cli_alert_warning("Insufficient data for Beveridge curve analysis")
  test_results$beveridge <- list(
    test_name = "Beveridge Curve",
    result = "INSUFFICIENT DATA"
  )
}

# =============================================================================
# TEST 5: COVID-19 STRUCTURAL BREAK - Pre vs Post 2020
# =============================================================================

cli::cli_h2("Test 5: COVID-19 Impact (Structural Break)")

eu27_full <- panel |>
  filter(geo == "EU27_2020", !is.na(ict_share_pc_emp)) |>
  mutate(
    post_covid = as.numeric(year >= 2020),
    year_centered = year - 2020
  )

if (nrow(eu27_full) > 8) {
  # Model with interaction term for structural break
  covid_model <- lm(ict_share_pc_emp ~ year_centered * post_covid, data = eu27_full)
  covid_summary <- tidy(covid_model)
  
  # Test if the interaction term (slope change) is significant
  interaction_row <- covid_summary |> filter(term == "year_centered:post_covid")
  
  if (nrow(interaction_row) > 0) {
    test_results$covid_break <- list(
      test_name = "Structural Break Test (2020)",
      hypothesis = "ICT employment growth rate changed after COVID-19",
      slope_change = interaction_row$estimate,
      p_value = interaction_row$p.value,
      result = ifelse(interaction_row$p.value < 0.10, "SIGNIFICANT", "NOT SIGNIFICANT"),
      interpretation = sprintf("Slope changed by %.4f pp/year after 2020", interaction_row$estimate)
    )
    
    cli::cli_alert_success("COVID break: slope change = {round(interaction_row$estimate, 4)}, p = {format.pval(interaction_row$p.value, digits = 3)}")
  }
} else {
  cli::cli_alert_warning("Insufficient data for structural break analysis")
}

# =============================================================================
# EXPORT RESULTS
# =============================================================================

cli::cli_h2("Exporting Statistical Test Results")

# Convert to data frame for export - safer approach
results_list <- list()
for (test_id in names(test_results)) {
  result <- test_results[[test_id]]
  results_list[[test_id]] <- list(
    test_id = test_id,
    test_name = result[["test_name"]],
    hypothesis = result[["hypothesis"]],
    statistic = result[["statistic"]],
    p_value = result[["p_value"]],
    result_status = result[["result"]],
    interpretation = result[["interpretation"]]
  )
}

results_df <- bind_rows(results_list)

# Save results
output_path <- file.path(CONFIG$PATHS$tables, "statistical_tests_summary")
save_rds_csv(results_df, output_path)

cli::cli_alert_success("Statistical analysis complete! Results saved to {output_path}.[rds|csv]")

# Print summary table
cli::cli_h2("Summary of Statistical Tests")
print(results_df |> select(test_name, result_status, p_value))

# =============================================================================
# ADDITIONAL: REGRESSION MODEL FOR REPORT
# =============================================================================

cli::cli_h2("Additional Analysis: Panel Regression Model")

# Simple cross-sectional model for interpretation
panel_latest <- panel |>
  filter(
    year == max(year),
    !is_aggregate,
    !is.na(ict_share_pc_emp)
  )

if (nrow(panel_latest) > 20) {
  # Include available predictors
  model_data <- panel_latest |>
    select(
      ict_share_pc_emp,
      unemp_rate_pc_act,
      grads_per_ict_job,
      wbl_exposure_share
    ) |>
    na.omit()
  
  if (nrow(model_data) > 15) {
    regression_model <- lm(
      ict_share_pc_emp ~ unemp_rate_pc_act + grads_per_ict_job + wbl_exposure_share,
      data = model_data
    )
    
    regression_summary <- tidy(regression_model)
    regression_fit <- glance(regression_model)
    
    # Save regression results
    regression_output <- regression_summary |>
      mutate(
        r_squared = regression_fit$r.squared,
        adj_r_squared = regression_fit$adj.r.squared,
        n_obs = nrow(model_data)
      )
    
    saveRDS(regression_output, file.path(CONFIG$PATHS$tables, "regression_results.rds"))
    readr::write_csv(regression_output, file.path(CONFIG$PATHS$tables, "regression_results.csv"))
    
    cli::cli_alert_success("Regression model saved (R² = {round(regression_fit$r.squared, 3)})")
  }
}

cli::cli_alert_success("All statistical analyses complete!")
