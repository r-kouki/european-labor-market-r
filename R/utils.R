# =============================================================================
# utils.R - Helper Functions for Eurostat Tech Job Market Analysis
# =============================================================================

#' Create directory if it doesn't exist
#' @param path Path to create
safe_mkdir <- function(path) {
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE, showWarnings = FALSE)
    cli::cli_alert_success("Created directory: {path}")
  }
}

#' Save data frame as both RDS and CSV
#' @param df Data frame to save
#' @param basename Base name without extension (can include path)
#' @param verbose Print message
save_rds_csv <- function(df, basename, verbose = TRUE) {
  rds_path <- paste0(basename, ".rds")
  csv_path <- paste0(basename, ".csv")

  saveRDS(df, rds_path)
  readr::write_csv(df, csv_path)

  if (verbose) {
    cli::cli_alert_success("Saved {nrow(df)} rows to {basename}.[rds|csv]")
  }
}

#' Check that required columns exist in a data frame
#' @param df Data frame to check
#' @param cols Character vector of required column names
#' @param df_name Name for error messages
assert_required_cols <- function(df, cols, df_name = "data frame") {
  missing <- setdiff(cols, names(df))
  if (length(missing) > 0) {
    cli::cli_abort("Missing columns in {df_name}: {paste(missing, collapse = ', ')}")
  }
  invisible(df)
}

#' Standardize geographic codes and add country names
#' @param df Data frame with 'geo' column
#' @param geo_col Name of the geography column (default: "geo")
standardize_geo_names <- function(df, geo_col = "geo") {
  assert_required_cols(df, geo_col)

  # Get country labels from eurostat
  geo_labels <- tryCatch(
    eurostat::get_eurostat_dic("geo"),
    error = function(e) NULL
  )

  if (!is.null(geo_labels)) {
    names(geo_labels) <- c("geo", "geo_name")
    df <- df |>
      dplyr::left_join(geo_labels, by = stats::setNames("geo", geo_col))
  } else {
    # Fallback: use countrycode package
    df <- df |>
      dplyr::mutate(
        geo_name = countrycode::countrycode(
          .data[[geo_col]],
          origin = "eurostat",
          destination = "country.name",
          warn = FALSE
        )
      )
  }

  # Fill in missing names with the code itself

df <- df |>
    dplyr::mutate(geo_name = dplyr::coalesce(geo_name, .data[[geo_col]]))

  df
}

#' Custom ggplot2 theme for the project
#' @param base_size Base font size
theme_project <- function(base_size = 12) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = base_size * 1.2),
      plot.subtitle = ggplot2::element_text(color = "gray40", size = base_size * 0.9),
      plot.caption = ggplot2::element_text(color = "gray50", size = base_size * 0.7, hjust = 0),
      legend.position = "bottom",
      legend.title = ggplot2::element_text(face = "bold", size = base_size * 0.9),
      panel.grid.minor = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(face = "bold")
    )
}

#' Download Eurostat dataset with error handling and caching
#' @param id Dataset ID (e.g., "isoc_sks_itspt")
#' @param filters Named list of filters
#' @param time_format Time format: "num" (numeric year), "date", or "raw"
#' @param cache Whether to use caching
download_dataset <- function(id, filters = NULL, time_format = "num", cache = TRUE) {
  cli::cli_alert_info("Downloading dataset: {id}")

  result <- tryCatch({
    df <- eurostat::get_eurostat(
      id = id,
      filters = filters,
      time_format = time_format,
      cache = cache
    )
    cli::cli_alert_success("Downloaded {nrow(df)} rows from {id}")
    df
  }, error = function(e) {
    cli::cli_alert_danger("Failed to download {id}: {e$message}")
    NULL
  })

  result
}

#' Get Eurostat dictionary for a dimension
#' @param dic Dimension name (e.g., "geo", "nace_r2")
get_dic_safe <- function(dic) {
  tryCatch(
    eurostat::get_eurostat_dic(dic),
    error = function(e) {
      cli::cli_alert_warning("Could not fetch dictionary for {dic}")
      NULL
    }
  )
}

#' Save a ggplot figure to PNG
#' @param p ggplot object
#' @param filename Filename (without path)
#' @param path Directory path
#' @param width Width in inches
#' @param height Height in inches
#' @param dpi Resolution
save_figure <- function(p, filename, path = here::here("outputs", "figures"),
                        width = 10, height = 6, dpi = 300) {
  safe_mkdir(path)
  filepath <- file.path(path, filename)

  ggplot2::ggsave(
    filename = filepath,
    plot = p,
    width = width,
    height = height,
    dpi = dpi,
    bg = "white"
  )

  cli::cli_alert_success("Saved figure: {filename}")
  invisible(filepath)
}

#' Format percentage for display
#' @param x Numeric vector
#' @param digits Number of decimal places
fmt_pct <- function(x, digits = 1) {
  scales::percent(x / 100, accuracy = 10^(-digits))
}

#' Get EU27 and associated country codes
#' @return Character vector of country codes
get_eu_countries <- function() {
  # EU27 member states (2020 composition, post-Brexit)
  eu27 <- c(
    "AT", "BE", "BG", "CY", "CZ", "DE", "DK", "EE", "EL", "ES",
    "FI", "FR", "HR", "HU", "IE", "IT", "LT", "LU", "LV", "MT",
    "NL", "PL", "PT", "RO", "SE", "SI", "SK"
  )

  # Additional countries of interest
  extra <- c("UK", "CH", "NO", "IS")

  # EU aggregate codes
  aggregates <- c("EU27_2020", "EA20", "EA19")

  c(aggregates, eu27, extra)
}

#' Check if a geo code is an EU aggregate
#' @param geo Character vector of geo codes
is_eu_aggregate <- function(geo) {
  geo %in% c("EU27_2020", "EU28", "EU27_2007", "EA20", "EA19", "EA18", "EA17")
}

#' Filter data to keep only relevant geographies
#' @param df Data frame with geo column
#' @param keep_aggregates Whether to keep EU aggregates
filter_geo <- function(df, keep_aggregates = TRUE) {
  geo_keep <- get_eu_countries()

  if (!keep_aggregates) {
    geo_keep <- geo_keep[!is_eu_aggregate(geo_keep)]
  }

  df |>
    dplyr::filter(geo %in% geo_keep)
}

#' Extract year from various time formats
#' @param time_col Time column (character, Date, or numeric)
extract_year <- function(time_col) {
  if (is.numeric(time_col)) {
    return(as.integer(time_col))
  }
  if (inherits(time_col, "Date")) {
    return(lubridate::year(time_col))
  }
  # Try to extract year from string like "2020" or "2020M01"
  as.integer(stringr::str_extract(as.character(time_col), "^\\d{4}"))
}
