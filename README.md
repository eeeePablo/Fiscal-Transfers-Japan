# Fiscal Transfers and Sectoral Employment in Japan (1995–1998)

Master's thesis project — Hiroshima University, Graduate School of Humanities and Social Sciences, International Economic Development Program (2024–2025)

## Overview

This study estimates the **causal effect of fiscal transfers on sectoral employment composition** across Japanese municipalities in the mid-1990s. Main question: did Japan's Local Allocation Tax (LAT)  — helped to shift employment to more profitable sectors?

The key methodological challenge is endogeneity: municipalities receiving more transfers tend to be economically weaker, making OLS estimates biased. This study addresses the problem using an **instrumental variable (IV) strategy**.

## Research Design

**Outcome variables**
- Share of municipal workforce in primary sector (agriculture)
- Share in secondary sector (manufacturing)
- Share in tertiary sector (services)

**Treatment variable**
- Local Allocation Tax per capita

**Instrumental variable**
- Municipal malapportionment (log) — the difference in per-capita representation created by Japan's 1994 electoral reform 

The instrument exploits the fact that overrepresented municipalities secured larger fiscal transfers through greater bargaining power in the House of Representatives, while malapportionment itself had no direct effect on local employment outcomes. This allows for **causal identification** via two-stage least squares (2SLS).

**Fixed effects**
- Municipality fixed effects (absorb time-invariant local characteristics)
- Year fixed effects (absorb national trends)

**Clustered standard errors** at both municipality and prefecture level.

## Methods

| Stage | Model | Purpose |
|-------|-------|---------|
| First stage | OLS with FE | Malapportionment → LAT per capita |
| Second stage | 2SLS with FE | LAT per capita → sectoral employment share |
| Robustness | Lagged DV, trimmed sample, prefecture clustering | Sensitivity checks |

## Robustness Checks

- **Prefecture-level clustering** — tests sensitivity of standard errors to spatial correlation
- **Lagged dependent variable** — controls for pre-existing employment trends
- **Trimmed sample** (10th–90th population percentile) — removes influence of very small and very large municipalities
- **Subsample analysis** — high vs. low agricultural employment municipalities; urban vs. rural

## Tech Stack

- **Language:** R
- **Key packages:** `fixest` , `modelsummary`,  `tidyverse`, `haven`, `gt`, `flextable`

## Data Sources


- "Distributive Politics and Crime" Masataka Harada and Daniel M. Smith
- Statistic Berou of Japan
- Malapportionment measure: based on Horiuchi & Saito (2003)

## Key Files

```
Master.R        # Full analysis: data prep, summary stats, first stage,
                # OLS, IV estimation, robustness checks
MASTERS.xlsx    # Municipal-level panel dataset (not included — contact author)
```

## Author

Mateusz Piesiak  
M. Logistics and Transportation, University of Gdansk
Graduate School of Humanities and Social Sciences, International Economic Development Program, Hiroshima University 
[LinkedIn](linkedin.com/in/mateusz-piesiak-aa964124b) · [Email](mailto: mateusz.pie321@gmail.com)

