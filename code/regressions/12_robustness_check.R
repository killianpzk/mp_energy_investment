# Robustness Checks
# 1. Extensive Margin
# 2. Level Margin

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

panel <- readRDS(here(clean_path, 'panel_state_type.rds'))

### Parameters -----------------------------------------------------------------

start_date   <- as.Date('2018-01-01')
end_date     <- as.Date('2023-12-31')

INSTRUMENT   <- 'shock_bs_orth'  
SHOCK        <- 'yield_10y'      
H_MAX        <- 9                
N_LAGS       <- 4                 
N_LAGS_DV   <- 2  # MO-PM lags

OUTCOMES     <- c('mw_dummy', 'mw_level')

MACRO_CTRL   <- c('inflation_logdiff', 'chomage_lvl', 'fedfunds_lvl', 'NFCI')
TECHNOLOGIES <- c('Renewable', 'Fossil', 'Battery')

### Useful Functions -----------------------------------------------------------

make_lags <- function(df, vars, n) {
  for (v in vars) {
    for (l in 1:n) {
      df <- df %>%
        group_by(group_id) %>%
        mutate(!!paste0(v, '_l', l) := lag(.data[[v]], l)) %>%
        ungroup()
    }
  }
  df
}

lag_names <- function(vars, n) {
  as.vector(outer(vars, 1:n, function(v, l) paste0(v, '_l', l)))
}

## Formatting Datasets ---------------------------------------------------------

df_global <- panel %>%
  rename(
    yield_5y  = `5y_bonds`,
    yield_10y = `10y_bonds`,
    yield_30y = `30y_bonds`
  ) %>%
  mutate(
    mw_cleaned = ifelse(mw_entered < 0, NA_real_, mw_entered),
    
    mw_dummy   = as.numeric(mw_cleaned > 0),
    mw_level   = mw_cleaned,
    
    group_id   = paste(state, county, broad_type, sep = '_'),
    year       = as.character(lubridate::year(month_date)),
    month      = as.character(lubridate::month(month_date)),
    broad_type = factor(broad_type)
  ) %>%
  arrange(group_id, month_date)

VARS_TO_LAG <- c(MACRO_CTRL, SHOCK, OUTCOMES)
df_global   <- make_lags(df_global, VARS_TO_LAG, N_LAGS)

df_global <- df_global %>%
  filter(
    if_all(all_of(lag_names(c(MACRO_CTRL, SHOCK), N_LAGS)), ~ !is.na(.)),
    broad_type %in% TECHNOLOGIES
  )

macro_lags <- lag_names(c(MACRO_CTRL, SHOCK), N_LAGS)

## Estimation ------------------------------------------------------------------

lpiv_results_list <- list()

for (outcome_var in OUTCOMES) {
  
  dv_lags <- paste0(outcome_var, '_l', 1:N_LAGS_DV)
  ctrl_lags <- c(macro_lags, dv_lags)
  
  for (h in 0:H_MAX) {
    
    dh <- df_global %>%
      arrange(group_id, month_date) %>%
      group_by(group_id) %>%
      mutate(y_h = lead(.data[[outcome_var]], h)) %>%
      ungroup() %>%
      filter(month_date >= start_date & month_date <= end_date) %>%
      filter(!is.na(y_h), !is.na(.data[[INSTRUMENT]]))
    
    # First Stage (F-stat)
    fml_fs <- as.formula(paste0(
      SHOCK, ' ~ mean_tenure_months + ', INSTRUMENT, ' + ', paste(ctrl_lags, collapse = ' + '),
      ' | broad_type^state^month'
    ))
    
    mod_fs <- tryCatch(
      feols(fml_fs, data = dh, cluster = ~month_date + state, notes = FALSE),
      error = function(e) NULL
    )
    if (is.null(mod_fs)) next
    
    fs_stat <- tryCatch(wald(mod_fs, keep = INSTRUMENT)$stat, error = function(e) NA_real_)
    
    # Second Stage (LP-IV)
    fml_iv <- as.formula(paste0(
      'y_h ~ mean_tenure_months + ', paste(ctrl_lags, collapse = ' + '),
      ' | broad_type^month^state | ',
      SHOCK, ' ~ ', INSTRUMENT
    ))
    
    mod_iv <- tryCatch(
      feols(fml_iv, data = dh, cluster = ~month_date + state, notes = FALSE),
      error = function(e) NULL
    )
    
    if (!is.null(mod_iv)) {
      coef_df <- coeftable(mod_iv) %>%
        as.data.frame() %>%
        tibble::rownames_to_column(var = 'term') %>%
        rename(
          coef    = Estimate,
          se      = `Std. Error`,
          t_stat  = `t value`,
          p_value = `Pr(>|t|)`
        ) %>%
        mutate(
          outcome = outcome_var,
          term    = ifelse(term == paste0('fit_', SHOCK), SHOCK, term),
          h       = h,
          ci_lo   = coef - 1.96 * se,
          ci_hi   = coef + 1.96 * se,
          f_stat  = fs_stat
        ) %>%
        select(outcome, h, term, coef, se, t_stat, p_value, ci_lo, ci_hi, f_stat)
      
      lpiv_results_list[[paste(outcome_var, h, sep = '_')]] <- coef_df
    }
  }
}

lpiv_results <- bind_rows(lpiv_results_list)

## Plot and Export -------------------------------------------------------------

output_dir <- here(output_path, 'robustness')
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

saveRDS(lpiv_results, file.path(output_dir, 'lpiv_decomposed_mopm.rds'))

plot_data <- lpiv_results %>%
  filter(term == SHOCK) %>%
  mutate(
    outcome_label = case_when(
      outcome == 'mw_dummy' ~ 'Extensive Margin (Probability P(MW > 0))',
      outcome == 'mw_level' ~ 'Overall Level (Gross MW)'
    )
  )

p_comp <- ggplot(plot_data, aes(x = h, y = coef)) +
  geom_hline(yintercept = 0, linetype = 'dashed', colour = 'grey50', linewidth = 0.6) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = '#2166AC', alpha = 0.15) +
  geom_line(colour = '#2166AC', linewidth = 1) +
  geom_point(aes(shape = !is.na(f_stat) & f_stat >= 10), colour = '#2166AC', size = 2) +
  facet_wrap(~outcome_label, scales = 'free_y', ncol = 1) +
  scale_x_continuous(breaks = seq(0, H_MAX, by = 2), labels = paste0('t+', seq(0, H_MAX, by = 2))) +
  labs(
    title    = 'Impact of Yield on Queue Capacity Entries',
    subtitle = paste0('Extensive margin vs. MW level| Endogenous: ', SHOCK),
    x        = 'Horizon (months)',
    y        = 'Estimated Effect',
    caption  = '95% CI. Clustered SE: date + state. FE: type x month x state. Macro Lags (4) + MO-PM (2).'
  ) +
  theme_bw(base_size = 11) +
  theme(
    plot.title     = element_text(face = 'bold'),
    strip.text     = element_text(face = 'bold'),
    legend.position= 'bottom'
  ) +
  scale_shape_manual(
    name   = NULL, 
    values = c(`TRUE` = 16, `FALSE` = 1),
    labels = c(`TRUE` = 'F-stat \u2265 10', `FALSE` = 'F-stat < 10')
  ) 

print(p_comp)

ggsave(file.path(output_dir, 'lpiv_extensive_vs_level.png'), plot = p_comp, width = 8, height = 7, dpi = 300)

## Printing Table --------------------------------------------------------------

print(lpiv_results[lpiv_results$term=='yield_10y' & lpiv_results$outcome=='mw_dummy',])

print(lpiv_results[lpiv_results$term=='yield_10y' & lpiv_results$outcome=='mw_level',])