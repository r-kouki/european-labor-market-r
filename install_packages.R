options(repos = c(CRAN = "https://cloud.r-project.org"))

pkgs <- unique(c(
  # Tidyverse ecosystem
  "tidyverse",
  "ggplot2",
  "dplyr",
  "readr",
  "tidyr",
  "purrr",
  "stringr",
  "lubridate",

  # Eurostat data access
  "eurostat",

  # Project utilities
  "here",
  "janitor",
  "cli",
  "scales",
  "countrycode",

  # Visualization extras
  "corrplot",
  "ggrepel",
  "patchwork",

  # Statistical modeling (optional, kept for compatibility)
  "tidymodels",
  "caret",
  "MASS",
  "forecast",

  # Data exploration
  "skimr",

  # Documentation & reporting
  "knitr",
  "rmarkdown",
  "quarto"
))

ncpus <- max(1L, parallel::detectCores() - 1L)
options(Ncpus = ncpus)

installed <- rownames(installed.packages())
to_install <- setdiff(pkgs, installed)
if (length(to_install) > 0) {
  install.packages(to_install)
}

message("CRAN packages installed: ", paste(pkgs, collapse = ", "))
