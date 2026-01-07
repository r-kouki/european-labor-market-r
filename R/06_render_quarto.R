# =============================================================================
# 06_render_quarto.R - Render Quarto Documents
# European Tech & Engineering Job Market Analysis
# =============================================================================

cli::cli_h1("Rendering Quarto Documents")

library(here)
library(quarto)
library(cli)

# Define paths
quarto_dir <- here::here("quarto")
output_dir <- here::here("outputs")

# Ensure output directory exists
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# =============================================================================
# RENDER REPORT
# =============================================================================

cli::cli_h2("Rendering Report")

report_qmd <- file.path(quarto_dir, "report.qmd")
report_output <- file.path(output_dir, "report.html")

if (file.exists(report_qmd)) {
  tryCatch({
    cli::cli_alert_info("Rendering {report_qmd}...")

    quarto::quarto_render(
      input = report_qmd,
      output_format = "html",
      output_file = "report.html"
    )

    # Move to outputs if rendered in quarto directory
    rendered_in_quarto <- file.path(quarto_dir, "report.html")
    if (file.exists(rendered_in_quarto) && !file.exists(report_output)) {
      file.copy(rendered_in_quarto, report_output, overwrite = TRUE)
      file.remove(rendered_in_quarto)
    }

    if (file.exists(report_output)) {
      cli::cli_alert_success("Report rendered: {report_output}")
    } else if (file.exists(rendered_in_quarto)) {
      cli::cli_alert_success("Report rendered: {rendered_in_quarto}")
    }
  }, error = function(e) {
    cli::cli_alert_danger("Failed to render report: {e$message}")
  })
} else {
  cli::cli_alert_warning("Report file not found: {report_qmd}")
}

# =============================================================================
# RENDER SLIDES
# =============================================================================

cli::cli_h2("Rendering Slides")

slides_qmd <- file.path(quarto_dir, "slides.qmd")
slides_output <- file.path(output_dir, "slides.html")

if (file.exists(slides_qmd)) {
  tryCatch({
    cli::cli_alert_info("Rendering {slides_qmd}...")

    quarto::quarto_render(
      input = slides_qmd,
      output_format = "revealjs",
      output_file = "slides.html"
    )

    # Move to outputs if rendered in quarto directory
    rendered_in_quarto <- file.path(quarto_dir, "slides.html")
    if (file.exists(rendered_in_quarto) && !file.exists(slides_output)) {
      file.copy(rendered_in_quarto, slides_output, overwrite = TRUE)
      file.remove(rendered_in_quarto)
    }

    if (file.exists(slides_output)) {
      cli::cli_alert_success("Slides rendered: {slides_output}")
    } else if (file.exists(rendered_in_quarto)) {
      cli::cli_alert_success("Slides rendered: {rendered_in_quarto}")
    }
  }, error = function(e) {
    cli::cli_alert_danger("Failed to render slides: {e$message}")
  })
} else {
  cli::cli_alert_warning("Slides file not found: {slides_qmd}")
}

# =============================================================================
# SUMMARY
# =============================================================================

cli::cli_h1("Render Summary")

# Check what outputs exist
outputs <- list(
  "Report (HTML)" = c(report_output, file.path(quarto_dir, "report.html")),
  "Slides (HTML)" = c(slides_output, file.path(quarto_dir, "slides.html"))
)

for (name in names(outputs)) {
  paths <- outputs[[name]]
  found <- FALSE
  for (p in paths) {
    if (file.exists(p)) {
      cli::cli_alert_success("{name}: {p}")
      found <- TRUE
      break
    }
  }
  if (!found) {
    cli::cli_alert_warning("{name}: Not found")
  }
}

cli::cli_alert_success("Quarto rendering complete!")
