# Data Dictionary

## Panel Dataset (panel_annual.csv)

| Variable | Description | Unit | Source |
|----------|-------------|------|--------|
| geo | Country/region code | Eurostat geo code | All datasets |
| geo_name | Country/region name | Text | Derived |
| year | Reference year | Integer | All datasets |
| is_eu27 | EU27 member state flag | Boolean | Derived |
| ict_share_pc_emp | ICT specialists as share of employment | % of total employment | isoc_sks_itspt |
| ict_employed_ths | Number of employed ICT specialists | Thousands of persons | isoc_sks_itspt |
| unemp_rate_pc_act | Unemployment rate (ages 15-74) | % of active population | une_rt_a |
| vacancy_rate_total | Job vacancy rate (total economy) | % of occupied + vacant posts | jvs_a_rate_r2 |
| vacancy_rate_J | Job vacancy rate (Info & Communication) | % of occupied + vacant posts | jvs_a_rate_r2 |
| vacancy_rate_M | Job vacancy rate (Professional/Scientific) | % of occupied + vacant posts | jvs_a_rate_r2 |
| vacancy_rate_C | Job vacancy rate (Manufacturing) | % of occupied + vacant posts | jvs_a_rate_r2 |
| grads_ict_tertiary | Tertiary graduates in ICT field | Number of graduates | educ_uoe_grad02 |
| grads_eng_tertiary | Tertiary graduates in Engineering | Number of graduates | educ_uoe_grad02 |
| wbl_exposure_share | VET graduates with work-based learning | % of VET graduates | Various |
| median_hourly_earnings_eur | Median hourly earnings | EUR | earn_ses_pub2s |

## Data Sources

All data sourced from Eurostat (https://ec.europa.eu/eurostat).

### Dataset Codes:

| Code | Name | Description |
|------|------|-------------|
| isoc_sks_itspt | ICT specialists | Employed ICT specialists - total |
| une_rt_a | Unemployment | Unemployment by sex and age - annual |
| une_rt_m | Unemployment monthly | Unemployment by sex and age - monthly |
| jvs_a_rate_r2 | Job vacancies | Job vacancy rate by NACE Rev.2 |
| educ_uoe_grad02 | Graduates | Graduates by field of education |
| earn_ses_pub2s | Earnings | Median hourly earnings (SES) |

## Notes

- Time coverage varies by indicator (generally 2014-2024)
- EU27 refers to EU27_2020 composition (post-Brexit)
- Missing values (NA) indicate data not available
- Earnings data available only for select years (2014, 2018, 2022)

Generated: 2026-01-06
