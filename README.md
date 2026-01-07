# European Tech & Engineering Job Market Evolution (2014-2024)

A comprehensive analysis of the European tech and engineering labor market using Eurostat data. This project examines ICT employment trends, job vacancies, unemployment dynamics, graduate pipelines, and earnings relationships across EU27 and associated countries.

## Overview

This repository contains a fully reproducible R + Quarto analysis that answers key questions about the European tech workforce:

- How has ICT specialist employment evolved across Europe?
- What is the relationship between unemployment and job vacancies?
- How do vacancy rates in tech sectors compare to the overall economy?
- Is the educational pipeline meeting market demands?
- What factors correlate with higher ICT employment shares?

## Indicators Analyzed

| Indicator | Eurostat Code | Description | Coverage |
|-----------|---------------|-------------|----------|
| ICT Employment | `isoc_sks_itspt` | Employed ICT specialists (% of employment + thousands) | 2014-2024 |
| Unemployment (Annual) | `une_rt_a` | Unemployment rate, ages 15-74 | 2014-2024 |
| Unemployment (Monthly) | `une_rt_m` | Seasonally adjusted monthly rate | 2020-2025 |
| Job Vacancies | `jvs_a_rate_r2` | Vacancy rate by NACE sector (J, M, C, Total) | 2014-2024 |
| Graduates | `educ_uoe_grad02` | Tertiary graduates in ICT & Engineering fields | 2014-2023 |
| Earnings | `earn_ses_pub2s` | Median hourly earnings (SES) | 2014, 2018, 2022 |

## Repository Structure

```
├── R/
│   ├── utils.R              # Helper functions
│   ├── 00_setup.R           # Configuration and package loading
│   ├── 01_download.R        # Download Eurostat data
│   ├── 02_clean.R           # Clean and transform datasets
│   ├── 03_build_panel.R     # Build master panel dataset
│   ├── 04_visualize.R       # Generate figures and tables
│   ├── 05_export_outputs.R  # Export polished outputs
│   └── 06_render_quarto.R   # Render report and slides
├── data/
│   ├── raw/                 # Raw Eurostat downloads (gitignored)
│   ├── processed/           # Cleaned datasets
│   └── cache/               # Eurostat API cache (gitignored)
├── outputs/
│   ├── figures/             # PNG visualizations
│   ├── tables/              # CSV summary tables
│   ├── report.html          # Full analysis report
│   └── slides.html          # Presentation slides
├── quarto/
│   ├── report.qmd           # Report source
│   └── slides.qmd           # Slides source (revealjs)
├── install_packages.R       # R package installation
├── environment.yml          # Conda environment
└── README.md
```

## How to Reproduce

### Prerequisites

- R >= 4.3
- Quarto
- Conda (recommended) or R packages installed manually

### Setup

1. **Create and activate the Conda environment:**

```bash
conda env create -f environment.yml
conda activate statistical-analysis
```

2. **Install R packages:**

```r
source("install_packages.R")
```

### Run the Analysis

Execute the scripts in order:

```r
# 1. Setup configuration and load packages
source("R/00_setup.R")

# 2. Download data from Eurostat (requires internet)
source("R/01_download.R")

# 3. Clean and transform datasets
source("R/02_clean.R")

# 4. Build master panel dataset
source("R/03_build_panel.R")

# 5. Generate visualizations and summary tables
source("R/04_visualize.R")

# 6. Export polished outputs
source("R/05_export_outputs.R")

# 7. Render Quarto report and slides
source("R/06_render_quarto.R")
```

Or run everything in one command:

```bash
Rscript -e "source('R/00_setup.R'); source('R/01_download.R'); source('R/02_clean.R'); source('R/03_build_panel.R'); source('R/04_visualize.R'); source('R/05_export_outputs.R'); source('R/06_render_quarto.R')"
```

## Key Outputs

### Datasets

| File | Description |
|------|-------------|
| `data/processed/panel_annual.csv` | Master panel dataset (geo × year) |
| `data/processed/unemp_monthly_2020_2025.csv` | Monthly unemployment series |

### Figures

| Figure | Description |
|--------|-------------|
| `fig01_ict_share_trend.png` | ICT employment share over time |
| `fig02_ict_employed_trend.png` | Absolute ICT employment |
| `fig03_vacancy_rate_J_trend.png` | Info & Comm sector vacancies |
| `fig04_unemp_vs_vacancy.png` | Beveridge curve |
| `fig05_graduates_ict_vs_eng.png` | Graduate trends |
| `fig06_salary_vs_ict_share.png` | Earnings correlation |
| `fig07_wbl_exposure_bar.png` | Work-based learning exposure |
| `fig08_ict_share_ranking.png` | Country rankings |

### Reports

- `outputs/report.html` - Full analytical report
- `outputs/slides.html` - Presentation slides (revealjs)

### Tables

- `outputs/tables/panel_annual_presentation.csv` - Presentation-ready panel
- `outputs/tables/latest_year_ranking.csv` - Country rankings
- `outputs/tables/correlations.csv` - Variable correlations
- `outputs/tables/data_dictionary.md` - Variable definitions

## Data Attribution

**Source**: Eurostat (https://ec.europa.eu/eurostat)

All data are subject to the [Eurostat copyright policy](https://ec.europa.eu/eurostat/about-us/policies/copyright). Reuse is authorized provided the source is acknowledged.

### Eurostat Dataset Codes

- `isoc_sks_itspt` - Employed ICT specialists - total
- `une_rt_a` - Unemployment by sex and age - annual data
- `une_rt_m` - Unemployment by sex and age - monthly data
- `jvs_a_rate_r2` - Job vacancy rate by NACE Rev.2 activity
- `educ_uoe_grad02` - Graduates by education level and field
- `earn_ses_pub2s` - Median hourly earnings (SES)

## Technical Notes

- Raw data is downloaded via the Eurostat API and cached locally
- The `eurostat` R package handles data retrieval and caching
- Missing values are handled with NA-tolerant operations
- EU27 refers to the 2020 composition (post-Brexit)

## License

Code in this repository is available under the MIT License.
Data are subject to Eurostat terms of use.
