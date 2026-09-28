# LP-IVs on log Capacity Withdrawn (with MO-PM correction and Technology Breakdown)

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

start_date <- as.Date('2018-01-01')
end_date   <- as.Date('2023-12-31')

INSTRUMENT   <- 'shock_bs_orth'  
SHOCK        <- 'yield_10y'      
H_MAX        <- 9                
N_LAGS       <- 4                 
N_LAGS_DV    <- 2  # MO-PM lags

DV_VAR       <- 'log_mw_withdrew'
MACRO_CTRL   <- c('inflation_logdiff', 'chomage_lvl', 'fedfunds_lvl', 'NFCI')
VARS_TO_LAG  <- c(MACRO_CTRL, SHOCK, DV_VAR)

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
    log_mw_withdrew = log(1 + mw_withdrew),
    group_id        = paste(state, county, broad_type, sep = '_'),
    year            = as.character(lubridate::year(month_date)),
    month           = as.character(lubridate::month(month_date))
  ) %>%
  arrange(group_id, month_date) %>%
  make_lags(VARS_TO_LAG, N_LAGS) %>%
  filter(
    if_all(all_of(lag_names(VARS_TO_LAG, N_LAGS)), ~ !is.na(.)),
    broad_type %in% TECHNOLOGIES
  )

macro_lags <- lag_names(c(MACRO_CTRL, SHOCK), N_LAGS)
dv_lags    <- paste0(DV_VAR, '_l', 1:N_LAGS_DV)
all_ctrls  <- c(macro_lags, dv_lags)


## Estimation ------------------------------------------------------------------

lpiv_all_tech <- list()

for (tech in TECHNOLOGIES) {
  
  cat('\n=== Estimation for:', tech, '===\n')
  df_tech <- df_global %>% filter(broad_type == tech)
  lpiv_results_list <- list()
  
  for (h in 0:H_MAX) {
    
    dh <- df_tech %>%
      arrange(group_id, month_date) %>%
      group_by(group_id) %>%
      mutate(y_h = lead(.data[[DV_VAR]], h)) %>%
      ungroup() %>%
      filter(month_date >= start_date & month_date <= end_date) %>%
      filter(!is.na(y_h), !is.na(.data[[INSTRUMENT]]))
    
    # First-Stage (F-Stat)
    fml_fs <- as.formula(paste0(
      SHOCK, ' ~ mean_tenure_months + ', INSTRUMENT, ' + ', paste(all_ctrls, collapse = ' + '),
      ' | state^month^broad_type'
    ))
    
    mod_fs <- tryCatch(
      feols(fml_fs, data = dh, cluster = ~month_date + state, notes = FALSE),
      error = function(e) NULL
    )
    if (is.null(mod_fs)) next
    
    fs_stat <- tryCatch(wald(mod_fs, keep = INSTRUMENT)$stat, error = function(e) NA_real_)
    
    # Second Stage (LP-IV)
    fml_iv <- as.formula(paste0(
      'y_h ~ mean_tenure_months + ', paste(all_ctrls, collapse = ' + '),
      ' | state^month^broad_type | ',
      SHOCK, ' ~ ', INSTRUMENT
    ))
    
    mod_iv <- tryCatch(
      feols(fml_iv, data = dh, cluster = ~month_date + state, notes = FALSE),
      error = function(e) NULL
    )
    
    # Extracting Table
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
          technology = tech,
          term       = ifelse(term == paste0('fit_', SHOCK), SHOCK, term),
          h          = h,
          ci_lo      = coef - 1.96 * se,
          ci_hi      = coef + 1.96 * se,
          f_stat     = fs_stat
        ) %>%
        select(technology, h, term, coef, se, t_stat, p_value, ci_lo, ci_hi, f_stat)
      
      lpiv_results_list[[as.character(h)]] <- coef_df
    }
  }
  
  lpiv_all_tech[[tech]] <- bind_rows(lpiv_results_list)
}

lpiv_results <- bind_rows(lpiv_all_tech)


## Plot and Export -------------------------------------------------------------

output_dir <- here(output_path, 'section2')
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

saveRDS(lpiv_results, file.path(output_dir, 'lpiv_log_mw_wd_type_mopm.rds'))

period_title     <- paste(format(start_date, '%b %Y'), '-', format(end_date, '%b %Y'))
weak_iv_threshold <- 10

colors_tech <- c(
  'Renewable' = '#2166AC',
  'Fossil'    = '#B2182B',
  'Storage'   = '#1B7837'
)

displayed_names <- c('Renewable', 'Fossil', 'Storage')

p_lpiv <- lpiv_results %>%
  filter(term == SHOCK) %>%
  mutate(technology = factor(technology, levels = TECHNOLOGIES, labels = displayed_names)) %>%
  ggplot(aes(x = h, y = coef, colour = technology, fill = technology)) +
  geom_hline(yintercept = 0, linetype = 'dashed', colour = 'grey50', linewidth = 0.6) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.15, colour = NA) +
  geom_line(linewidth = 1) +
  geom_point(
    aes(shape = !is.na(f_stat) & f_stat >= weak_iv_threshold),
    size = 2.2
  ) +
  facet_wrap(~ technology, ncol = 1, scales = 'free_y') +
  scale_colour_manual(values = colors_tech) +
  scale_fill_manual(values = colors_tech) +
  scale_shape_manual(
    values = c(`TRUE` = 19, `FALSE` = 4),
    labels = c(`TRUE` = paste0('F >= ', weak_iv_threshold),
               `FALSE` = paste0('F < ', weak_iv_threshold)),
    name   = 'First Stage'
  ) +
  scale_x_continuous(breaks = seq(0, H_MAX, by = 2), labels = paste0('t+', seq(0, H_MAX, by = 2))) +
  labs(
    title    = 'Impact of Yield on Project Capacity Withdrawals by Technology',
    subtitle = paste0('Endogenous: ', SHOCK, ' | IV: ', INSTRUMENT, ' | Period: ', period_title),
    x        = 'Horizon (months)',
    y        = 'Change in log(1 + MW Withdrawn)',
    caption  = '95% CI. Cluster SE: date + state. FE: type x state x month. Macro lags (4) + MO-PM (2).'
  ) +
  theme_bw(base_size = 11) +
  theme(
    plot.title       = element_text(face = 'bold'),
    legend.position  = 'bottom',
    strip.text       = element_text(face = 'bold', size = 11),
    strip.background = element_rect(fill = 'grey95', colour = 'grey80')
  )

print(p_lpiv)

file_name <- paste0('lpiv_log_mw_wd_type_mopm_', format(start_date, '%Y'), '_', format(end_date, '%Y'), '.png')
ggsave(file.path(output_dir, file_name), plot = p_lpiv, width = 7, height = 9, dpi = 300)

## Printing Table --------------------------------------------------------------

print(lpiv_results[lpiv_results$term=='yield_10y',])