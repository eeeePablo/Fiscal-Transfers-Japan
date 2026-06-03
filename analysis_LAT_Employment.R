#library
library(haven)
library(readxl)
library(tidyr)
library(dplyr)
library(fixest)
library(broom)
library(modelsummary)
library(rstudioapi)
library(flextable)
library(tibble)
library(gt)

#Preparation
data <- read_excel("MASTERS.xlsx")
 #rename 
data <- data %>% rename ( 
  muncode = muncode1998B,
  year = year, 
  lnLATPC = lnLATPC, 
  logMal = logMal, 
  share_primary = "ratio of primary sector workers", 
  share_secondary = "ration of secondary sector", 
  share_tertiary = "ration of population in tertary", 
  lnPop = "log pop", 
  r_Young_pop = "r_Young_pop", 
  r_Old_pop = "r_Old_pop", 
  HOR_district = "HOR_district", 
  d_city = "d_city", 
  sample9697 = "sample9697",
  LATPC = "LATper capita",
  ratio_unen = "ratio unen"
  )
#filters the data 
f_data <- data %>%
  filter(d_city == 1, year %in% c(1996,1997)) 
#summary statistics 
variables <- c("logMal", "log tax inc", "lnPop", "r_Young_pop", "r_Old_pop", "number of seats",
               "fiscal strenght", "share_primary", "share_secondary", "share_tertiary", "ratio_unen", "lnLATPC", 
               "taxable income per capita", "log of previous wins")
summary_stats <- f_data %>%
  select(all_of(variables)) %>%
  pivot_longer(
    everything(),
    names_to = "Variable",
    values_to = "Value"
  ) %>%
  group_by(Variable) %>%
  summarise(
    N = sum(!is.na(Value)),
    Mean = mean(Value, na.rm = TRUE),
    SD = sd(Value, na.rm = TRUE),
    Min = min(Value, na.rm = TRUE),
    Max = max(Value, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    across(c(Mean, SD, Min, Max), ~ round(.x, 2))
  )

summary_stats %>%
  gt() %>%
  tab_header(
    title = md("**Table 1. Descriptive Statistics**")
  ) %>%
  fmt_number(
    columns = c(Mean, SD, Min, Max),
    decimals = 2
  ) %>%
  cols_align(
    align = "center",
    columns = c(N, Mean, SD, Min, Max)
  )
print(summary_stats)
#variables groups
political <- c("number of seats", "log of previous wins")
economic  <- c("log tax inc", "fiscal strenght", "taxable income per capita")
demographic <- c("lnPop", "r_Young_pop", "r_Old_pop","ratio_unen")
controls <- c("politica", "economic", "demographic")
#averages of the variables in the regression
f_data <- f_data %>%
  mutate(
    political   = rowMeans(select(., all_of(political)), na.rm = TRUE),
    economic    = rowMeans(select(., all_of(economic)), na.rm = TRUE),
    demographic = rowMeans(select(., all_of(demographic)), na.rm = TRUE)
  ) 
#First stage regression
stg1_m1 <- feols(lnLATPC ~ logMal| year + muncode, data = f_data, cluster = ~muncode )
stg1_m2 <- feols(lnLATPC ~ logMal + political + economic + demographic | year + muncode, data = f_data, cluster = ~muncode )


# F statistic 
fstat_m1 <- fitstat(stg1_m1, type = "f")[["f"]][1]
fstat_m2 <- fitstat(stg1_m2, type = "f")[["f"]][1]

# summary table
extra_rows <- data.frame(
  term = c("Control variables", "First-stage F statistic"),
  `(1) No controls` = c("", sprintf("%.2f", fstat_m1)),
  `(2) With controls` = c("✓", sprintf("%.2f", fstat_m2)),
  stringsAsFactors = FALSE
)

# summary table
modelsummary(
  list("(1) No controls" = stg1_m1,
       "(2) With controls" = stg1_m2),
  coef_map = c("logMal" = "Malapportionment(log)"),
  statistic = "({std.error})",
  stars = TRUE,
  gof_omit = "AIC|BIC|Log.Lik|Std.Errors|R2|ADJ",
  add_rows = extra_rows,
  output = "flextable"
) %>%
  flextable::set_caption("First-stage regression of local allocation tax per capita on malapportionment (log)")

#second stage OLS
ols_m1 <- feols(share_primary ~ LATPC | year + muncode,  data = f_data, cluster = ~muncode)
ols_m2 <- feols(share_secondary ~ LATPC | year + muncode, data = f_data, cluster = ~muncode)
ols_m3 <- feols(share_tertiary ~ LATPC | year + muncode, data = f_data, cluster = ~muncode)
olsfix_m1 <- feols(share_primary ~ LATPC + political + economic + demographic | year + muncode, data = f_data, cluster = ~muncode)
olsfix_m2 <- feols(share_secondary ~ LATPC + political + economic + demographic | year + muncode, data = f_data, cluster = ~muncode)
olsfix_m3 <- feols(share_tertiary ~ LATPC + political + economic + demographic | year + muncode, data = f_data, cluster = ~muncode)
#second satge IV 
iv_m1 <- feols(share_primary ~ 1  | year + muncode | LATPC ~ logMal, data = f_data, cluster = ~muncode)
iv_m2 <- feols(share_secondary ~ 1  | year + muncode | LATPC ~ logMal, data = f_data, cluster = ~muncode)
iv_m3 <- feols(share_tertiary ~ 1  | year + muncode | LATPC ~ logMal, data = f_data, cluster = ~muncode)
ivfix_m1 <- feols(share_primary ~ political + economic + demographic | year + muncode  | LATPC ~ logMal, data = f_data, cluster = ~muncode)
ivfix_m2 <- feols(share_secondary ~ political + economic + demographic | year + muncode | LATPC ~ logMal, data = f_data, cluster = ~muncode)
ivfix_m3 <- feols(share_tertiary ~ political + economic + demographic | year + muncode | LATPC ~ logMal, data = f_data, cluster = ~muncode)
#table (OLS + IV)
modelsummary(
  list(
    "(1) OLS primary no controls" = ols_m1,
    "(2) OLS secondary no controls" = ols_m2,
    "(3) OLS tertiary no controls" = ols_m3,
    "(4) OLS primary with controls" = olsfix_m1,
    "(5) OLS secondary with controls" = olsfix_m2,
    "(6) OLS tertiary with controls" = olsfix_m3
  ),
  coef_map = c("LATPC" = "Local allocation tax per capita"),
  statistic = "({std.error})",
  stars = TRUE,
  gof_omit = "AIC|BIC|Log.lik|F|std.errors|RMSE|R2|ADJ",
  output = "flextable",
  add_rows = data.frame(
    term = c("Control variables", "Municipality FE", "Year FE"),
    `(1) OLS primary no controls` = c("", "✓", "✓"),
    `(2) OLS secondary no controls` = c("", "✓", "✓"),
    `(3) OLS tertiary no controls` = c("", "✓", "✓"),
    `(4) OLS primary with controls` = c("✓", "✓", "✓"),
    `(5) OLS secondary with controls` = c("✓", "✓", "✓"),
    `(6) OLS tertiary with controls` = c("✓", "✓", "✓")
  )
) %>%
  flextable::set_caption("OLS regression of local allocation tax per capita on sector mix")
# IV
gof_map <- data.frame(
  raw = c("nobs", "r.squared", "adj.r.squared", "se_type"),
  clean = c("Num.Obs.", "R2", "R2 Adj.", "Std.Errors"),
  fmt = c(0, 3, 3, NA)
)

modelsummary(
  list(
    "(1) IV primary no controls" = iv_m1,
    "(2) IV secondary no controls" = iv_m2,
    "(3) IV tertiary no controls" = iv_m3,
    "(4) IV primary with controls" = ivfix_m1,
    "(5) IV secondary with controls" = ivfix_m2,
    "(6) IV tertiary with controls" = ivfix_m3
  ),
  coef_map = c(
    "(Intercept)" = "Constant",
    "fit_LATPC" = "Local allocation tax per capita"),
  statistic = "({std.error})",
  stars = TRUE,
  gof_omit = "AIC|BIC|Log.lik|std.errors|RMSE|R2|ADJ",
  output = "flextable",
  add_rows = tibble::tribble(
    ~term, ~`(1) IV primary no controls`, ~`(2) IV secondary no controls`, 
    ~`(3) IV tertiary no controls`, ~`(4) IV primary with controls`, 
    ~`(5) IV secondary with controls`, ~`(6) IV tertiary with controls`,
    "Control variables", "", "", "", "✓", "✓", "✓"
    )
) %>%
  flextable::set_caption("IV regression of local allocation tax per capita on sector mix")
#prefecture clustering 
f_data$prefecture <- as.numeric(substr(f_data$muncode, 1, 2))

#second satge IV 
iv_m1_p <- feols(share_primary ~ 1  | year + muncode | LATPC ~ logMal, data = f_data, cluster = ~prefecture)
iv_m2_p <- feols(share_secondary ~ 1  | year + muncode | LATPC ~ logMal, data = f_data, cluster = ~prefecture)
iv_m3_p <- feols(share_tertiary ~ 1  | year + muncode | LATPC ~ logMal, data = f_data, cluster = ~prefecture)
ivfix_m1_p <- feols(share_primary ~ political + economic + demographic | year + muncode  | LATPC ~ logMal, data = f_data, cluster = ~prefecture)
ivfix_m2_p <- feols(share_secondary ~ political + economic + demographic | year + muncode | LATPC ~ logMal, data = f_data, cluster = ~prefecture)
ivfix_m3_p <- feols(share_tertiary ~ political + economic + demographic | year + muncode | LATPC ~ logMal, data = f_data, cluster = ~prefecture)

modelsummary(
  list(
    "(1) IV primary no controls" = iv_m1_p,
    "(2) IV secondary no controls" = iv_m2_p,
    "(3) IV tertiary no controls" = iv_m3_p,
    "(4) IV primary with controls" = ivfix_m1_p,
    "(5) IV secondary with controls" = ivfix_m2_p,
    "(6) IV tertiary with controls" = ivfix_m3_p
  ),
  coef_map = c(
    "(Intercept)" = "Constant",
    "fit_LATPC" = "Local allocation tax per capita"),
  statistic = "({std.error})",
  stars = TRUE,
  gof_omit = "AIC|BIC|Log.lik|std.errors|RMSE",
  output = "flextable",
  add_rows = tibble::tribble(
    ~term, ~`(1) IV primary no controls`, ~`(2) IV secondary no controls`, 
    ~`(3) IV tertiary no controls`, ~`(4) IV primary with controls`, 
    ~`(5) IV secondary with controls`, ~`(6) IV tertiary with controls`,
    "Control variables", "", "", "", "✓", "✓", "✓"
  )
) %>%
  flextable::set_caption("IV regression of local allocation tax per capita on sector mix")
#agri employment
median_agri <- median(f_data$share_primary, na.rm = TRUE)

f_data$agri_group <- ifelse(f_data$share_primary >= median_agri, "high", "low")

feols(share_primary ~ LATPC | muncode + year,
      data = subset(f_data, agri_group == "high"),
      cluster = ~muncode)

feols(share_primary ~ LATPC | muncode + year,
      data = subset(f_data, agri_group == "low"),
      cluster = ~muncode)



datasummary_balance(
  (share_primary + LATPC) ~ agri_group,
  data = f_data,
  stars = TRUE,
  fmt = 3
)

#rural vs city

median_pop <- median(f_data$Pop, na.rm = TRUE)
f_data$urban_rural <- ifelse(f_data$Pop >= median_pop, "urban", "rural")

feols(share_primary ~ LATPC | muncode + year,
      data = subset(f_data,urban_rural == "urban"),
      cluster = ~muncode)

feols(share_primary ~ LATPC | muncode + year,
      data = subset(f_data, urban_rural == "rural"),
      cluster = ~muncode)

datasummary_balance(
  (share_primary + LATPC) ~ urban_rural,
  data = f_data,
  stars = TRUE,
  fmt = 3
)

#lagged

f_data <- f_data %>%
  arrange(muncode, year) %>%
  group_by(muncode) %>%
  mutate(
    share_primary_lag = lag(share_primary),
    share_secondary_lag = lag(share_secondary),
    share_teritary_lag = lag(share_tertiary),
     ) %>%
ungroup()
#IV lag

iv_lag_p <- feols(share_primary ~ share_primary_lag | LATPC ~ logMal,
                  data = f_data, cluster = ~muncode)

iv_lag_s <- feols(share_secondary ~ share_secondary_lag | LATPC ~ logMal,
                  data = f_data, cluster = ~muncode)

iv_lag_t <- feols(share_tertiary ~ share_teritary_lag | LATPC ~ logMal,
                  data = f_data, cluster = ~muncode)
modelsummary(
  list(
    "(1) IV primary lag" = iv_lag_p,
    "(2) IV secondary lag" = iv_lag_s,
    "(3) IV tertiary lag" = iv_lag_t
  ),
  coef_map = c(
    "(Intercept)" = "Constant",
    "fit_LATPC" = "Local allocation tax per capita",
    "share_primary_lag" = "Lagged dependent variable",
    "share_secondary_lag" = "Lagged dependent variable",
    "share_teritary_lag" = "Lagged dependent variable"
  ),
  statistic = "({std.error})",
  stars = TRUE,
  gof_omit = "AIC|BIC|Log.lik|std.errors|RMSE",
  output = "flextable",
  add_rows = tibble::tribble(
    ~term, ~`(1) IV primary lag`, ~`(2) IV secondary lag`, ~`(3) IV tertiary lag`,
    "Lagged dependent variable", "✓", "✓", "✓",
    "Year FE", "✓", "✓", "✓",
    "Municipality FE", "", "", ""
  )
) %>%
  flextable::set_caption("IV regression with lagged dependent variables")

#trimmed sample

q10 <- quantile(f_data$Pop, 0.10, na.rm = TRUE)
q90 <- quantile(f_data$Pop, 0.90, na.rm = TRUE)

f_trim <- subset(f_data, Pop >= q10 & Pop <=q90)

iv_trim_p <- feols(share_primary ~ 1 | muncode + year | LATPC ~ logMal,
                   data = f_trim, cluster = ~muncode)

iv_trim_s <- feols(share_secondary ~ 1 | muncode + year | LATPC ~ logMal,
                   data = f_trim, cluster = ~muncode)

iv_trim_t <- feols(share_tertiary ~ 1 | muncode + year | LATPC ~ logMal,
                   data = f_trim, cluster = ~muncode)

modelsummary(
  list(
    "(1) IV primary trim" = iv_trim_p,
    "(2) IV secondary trim" = iv_trim_s,
    "(3) IV tertiary trim" = iv_trim_t
  ),
  coef_map = c(
    "(Intercept)" = "Constant",
    "fit_LATPC" = "Local allocation tax per capita",
    "share_primary_lag" = "Lagged dependent variable",
    "share_secondary_lag" = "Lagged dependent variable",
    "share_teritary_lag" = "Lagged dependent variable"
  ),
  statistic = "({std.error})",
  stars = TRUE,
  gof_omit = "AIC|BIC|Log.lik|std.errors|RMSE",
  output = "flextable",
  add_rows = tibble::tribble(
    ~term, ~`(1) IV primary lag`, ~`(2) IV secondary lag`, ~`(3) IV tertiary lag`,
    "Lagged dependent variable", "✓", "✓", "✓",
    "Year FE", "✓", "✓", "✓",
    "Municipality FE", "", "", ""
  )
) %>%
  flextable::set_caption("Trimmed IV regression ")


