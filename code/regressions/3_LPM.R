# Reduced Form Duration Model --------------------------------------------------
# 1. Global Dynamic
# 2. Technology breakdown

## Env -------------------------------------------------------------------------

rm(list=ls())

### Imports --------------------------------------------------------------------

code_path <- 'code'
source(here::here(code_path, 'dependencies.R'))

### Common Variables -----------------------------------------------------------

raw_path    <- 'raw_data'
clean_path  <- 'cleaned_data'
output_path <- 'outputs'

### Data -----------------------------------------------------------------------

panel_raw <- readRDS(here(clean_path,'panel.rds'))

### Parameters  ----------------------------------------------------------------

SHOCK          <- 'shock_bs_orth'
N_LAGS_DYN     <- 6
N_LAGS_HET     <- 3

start_date     <- as.Date('2018-01-01')
end_date       <- as.Date('2023-12-31')

renewables_list <- c('Solar', 'Wind', 'Offshore Wind', 'Hydrogen')
fossils_list    <- c('Gas', 'Coal', 'Biofuel', 'Diesel', 'Oil', 'Nuclear')
batteries_list  <- c('Battery', 'Flywheel')

MACRO_CTRL     <- c('inflation_logdiff', 'chomage_lvl', 'NFCI')
VARS_MACRO     <- c(SHOCK, MACRO_CTRL)

## Formatting Datasets ---------------------------------------------------------

macro_raw <- panel_raw %>%
  select(month_date, all_of(VARS_MACRO)) %>%
  distinct(month_date, .keep_all = TRUE) %>%
  arrange(month_date)

# Sanity Check on completness
cal_grid <- tibble(
  month_date = seq(min(macro_raw$month_date, na.rm = TRUE),
                   max(macro_raw$month_date, na.rm = TRUE),
                   by = 'month')
)

macro_series <- cal_grid %>%
  left_join(macro_raw, by = 'month_date') %>%
  arrange(month_date)

# Lag Function
max_lags <- max(N_LAGS_DYN, N_LAGS_HET)
for (v in VARS_MACRO) {
  for (l in 1:max_lags) {
    macro_series[[paste0(v, '_l', l)]] <- dplyr::lag(macro_series[[v]], l)
  }
}


df_micro <- panel_raw %>%
  select(-any_of(setdiff(names(macro_series), 'month_date'))) %>%
  left_join(macro_series, by = 'month_date') %>%
  
  mutate(
    broad_type = case_when(
      type1 %in% renewables_list ~ 'Renewable',
      type1 %in% fossils_list    ~ 'Fossil',
      type1 %in% batteries_list  ~ 'Battery',
      TRUE                       ~ NA_character_
    ),
    # Fossil as Baseline (omitted)
    broad_type = factor(broad_type, levels = c('Fossil', 'Renewable', 'Battery')),
    log_mw     = log(pmax(mw1, 0.1))
  ) %>%
  
  filter(
    in_queue == 1L,
    !is.na(broad_type),
    !is.na(mw1),
    month_date >= start_date,
    month_date <= end_date,
    if_all(all_of(paste0(SHOCK, '_l', 1:N_LAGS_DYN)), ~ !is.na(.))
  ) %>%
  
  mutate(
    log_mw_c = log_mw - mean(log_mw, na.rm = TRUE)
  )

cat('Unique Projects:', n_distinct(df_micro$proj_id))

## Global Dynamic Model

shock_vars_dyn <- c(SHOCK, paste0(SHOCK, '_l', 1:N_LAGS_DYN))
ctrl_vars      <- paste0(MACRO_CTRL, '_l1')

fml_dynamic <- as.formula(paste0(
  'withdrew_this_month ~ ',
  paste(shock_vars_dyn, collapse = ' + '), ' + ',
  paste(ctrl_vars, collapse = ' + '), ' + ',
  'log_mw_c + poly(tenure_months, 2) | ',
  'state + entry_cohort'
))

mod_dyn <- feols(fml_dynamic, data = df_micro, cluster = ~month_date)
print(summary(mod_dyn, keep = shock_vars_dyn))

# Wald Test on the Cumulated Effect (6 months != 0)
sum_fml <- paste(shock_vars_dyn, collapse = ' + ')
test_sum_dyn <- wald(mod_dyn, c(paste0(sum_fml, ' = 0')))
print(test_sum_dyn)

# Need to do it manually
coefs_shock <- coef(mod_dyn)[shock_vars_dyn]
vcov_shock  <- vcov(mod_dyn)[shock_vars_dyn, shock_vars_dyn]
beta_cumul <- sum(coefs_shock)
se_cumul <- sqrt(sum(vcov_shock))
t_stat_cumul <- beta_cumul / se_cumul
df_res       <- degrees_freedom(mod_dyn, type = 'resid')
p_val_cumul  <- 2 * (1 - pt(abs(t_stat_cumul), df = df_res))


# Cumulated IRF
coefs_s <- coef(mod_dyn)[shock_vars_dyn]
vcov_s  <- vcov(mod_dyn)[shock_vars_dyn, shock_vars_dyn]

cumul_irf <- tibble(
  lag       = 0:N_LAGS_DYN,
  coef_marg = coefs_s,
  coef_cum  = cumsum(coefs_s),
  se_cum    = sapply(1:(N_LAGS_DYN + 1), function(k) sqrt(sum(vcov_s[1:k, 1:k])))
) %>%
  mutate(
    ci_lo = coef_cum - 1.96 * se_cum,
    ci_hi = coef_cum + 1.96 * se_cum
  )

p_dyn <- ggplot(cumul_irf, aes(x = lag, y = coef_cum)) +
  geom_hline(yintercept = 0, linetype = 'dashed', color = 'grey50') +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = '#2166AC', alpha = 0.2) +
  geom_line(color = '#2166AC', linewidth = 1) +
  geom_point(color = '#2166AC', size = 2.5) +
  scale_x_continuous(breaks = 0:N_LAGS_DYN, labels = paste0('t-', 0:N_LAGS_DYN)) +
  labs(
    title    = 'Cumulative Impact of the Bauer-Swanson Shock on the Exit Rate',
    subtitle = 'Discrete-Time Duration Model (Global Reduced Form)',
    x        = 'Shock lag (months)',
    y        = 'Cumulative change in probability',
    caption  = '95% CI. Clustered SE: month_date. FE: state + entry_cohort. Controls: macro, log_mw, tenure.'
  ) +
  theme_bw(base_size = 12)

print(p_dyn)

## Technology Breakdown --------------------------------------------------------

shock_vars_het <- c(SHOCK, paste0(SHOCK, '_l', 1:N_LAGS_HET))

# Interactions
tech_interactions <- paste0('i(broad_type, ', shock_vars_het, ', ref = "Fossil")',
                            collapse = ' + ')
size_interactions <- paste0('log_mw_c:', shock_vars_het, collapse = ' + ')

fml_hetero <- as.formula(paste0(
  'withdrew_this_month ~ ',
  tech_interactions, ' + ',
  'log_mw_c + ',
  size_interactions, ' + ',
  'poly(tenure_months, 2) | ',
  'month_date + state + entry_cohort + broad_type'
))

mod_hetero <- feols(fml_hetero, data = df_micro, cluster = ~month_date)
print(summary(mod_hetero))

# Joint significance tests for interactions
test_tech <- wald(mod_hetero, keep = 'Renewable')
test_size <- wald(mod_hetero, keep = 'log_mw_c:')

cat('Joint heterogeneity test - Renewables vs. Fossil fuels:')
print(test_tech)

cat('Joint heterogeneity test - Role of size:')
print(test_size)

## Plot and Export -------------------------------------------------------------

output_dir <- here(output_path, 'section1')
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

ggsave(file.path(output_dir, 'irf_reduced_form_cumul.png'), plot = p_dyn, 
       width = 7, height = 4.5, dpi = 300)
saveRDS(list(mod_dyn = mod_dyn, mod_hetero = mod_hetero, cumul = cumul_irf),
        file.path(output_dir, 'results_section1.rds'))

print(p_dyn)

# Technology Interactions
p_tech <- coefplot(
  mod_hetero, 
  keep = 'broad_type::.*shock', 
  main = 'Sensitivity by Technology (Ref: Fossil)',
  xlab = 'Interaction Coefficient'
)

# Size Interactions
p_size <- coefplot(
  mod_hetero, 
  keep = 'log_mw_c:shock', 
  main = 'Size Effect (log MW)',
  xlab = 'Interaction Coefficient'
  )