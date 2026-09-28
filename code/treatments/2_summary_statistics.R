## Env -------------------------------------------------------------------------

rm(list=ls())

### Common Variables -----------------------------------------------------------

raw_path   <- 'raw_data'
clean_path <- 'cleaned_data'

### Imports --------------------------------------------------------------------

code_path <- 'code'
source(here::here(code_path, 'dependencies.R'))

#### Data ----------------------------------------------------------------------

##### RDS ----------------------------------------------------------------------

queued_up <- readRDS(here(clean_path, 'queued_up.rds'))
master_vars <- readRDS(here(clean_path, 'master_vars.rds')) 
macro_controls <- readRDS(here(clean_path, 'macro_controls.rds'))
data_eia <- readRDS(here(clean_path, 'data_eia_monthly.rds'))
nfci_monthly <- readRDS(here(clean_path, 'nfci_monthly.rds'))
panel_group <- readRDS(here(clean_path,'panel_group.rds'))
panel <- readRDS(here(clean_path,'panel.rds'))

###### Daily Data --------------------------------------------------------------

mp_shocks_bs_clean <-  readRDS(here(clean_path,'mp_shocks_bs.rds'))
mp_shocks_miranda_daily_clean <-  readRDS(here(clean_path,'mp_shocks_miranda_daily.rds'))
usmpd_clean <-  readRDS(here(clean_path,'usmpd.rds'))
mp_shocks_ns_clean <- readRDS(here(clean_path,'mp_shocks_ns.rds'))
mp_shocks_swanson_clean <- readRDS(here(clean_path,'mp_shocks_swanson.rds'))
mp_shocks_brw_clean <- readRDS(here(clean_path,'mp_shocks_brw.rds'))

## Clean -----------------------------------------------------------------------

### Copy of "build_panel"'s steps

mps_end <- master_vars %>%
  filter(!is.na(shock_bs_orth)) %>%
  pull(date) %>%
  max(na.rm = TRUE)
cat('End of Panel :', format(mps_end), '\n')

projects <- queued_up %>%
  mutate(
    q_date  = as.Date(q_date,  origin = '1970-01-01'),
    wd_date = suppressWarnings(as.Date(as.character(wd_date))),
    on_date = suppressWarnings(as.Date(as.character(on_date)))
  )

### FE Entry Cohort

projects_clean <- projects %>%
  filter(
    !is.na(q_date),
    q_status %in% c('withdrawn', 'operational', 'active', 'suspended'),
    !(q_status == 'withdrawn' & is.na(wd_date)),
    is.na(wd_date) | wd_date >= q_date,
    q_date <= mps_end
  ) %>%
  mutate(
    proj_id      = paste(q_id, format(q_date, '%Y%m%d'), type_clean, sep = '_'),
    entry_cohort = as.factor(q_year),
    end_date = case_when(
      q_status == 'withdrawn'   ~ wd_date,
      q_status == 'operational' ~ pmax(on_date, q_date, na.rm = TRUE),
      TRUE                      ~ mps_end   
    ),
    is_withdrawal = as.integer(q_status == 'withdrawn')
  ) %>%
  filter(!is.na(end_date))

cat('Total Projects:', nrow(projects_clean), '\n')

projects_clean_months <- projects_clean %>%
  mutate(
    q_date = as_date(q_date),
    end_date = as_date(end_date),
    duree_jours = as.numeric(end_date - q_date),
    duree_semaines = as.numeric(difftime(end_date, q_date, units = 'weeks')),
    duree_mois = time_length(interval(q_date, end_date), unit = 'months'),
    duree_annees = time_length(interval(q_date, end_date), unit = 'years')
  )

projects_lifetime <- projects_clean %>%
  mutate(
    across(c(q_date, wd_date, on_date), ymd),
    date_cible = coalesce(wd_date, on_date, ymd('2023-12-12')),
    
    lifetime = ceiling(time_length(interval(q_date, date_cible), unit = 'month'))
  )

### Flagging

renewables_list <- c('Solar', 'Wind', 'Offshore Wind', 'Hydrogen') 
fossils_list    <- c('Gas', 'Coal', 'Biofuel', 'Diesel', 'Oil', 'Nuclear') 
batteries_list <- c('Battery', 'Flywheel')

panel <- panel %>%
  mutate(
    renewable = if_else(type1 %in% renewables_list, 1L, 0L),
    fossil    = if_else(type1 %in% fossils_list, 1L, 0L),
    battery   = if_else(type1 %in% batteries_list, 1L, 0L),
    other     = if_else(renewable == 0L & fossil == 0L, 1L, 0L),
    
    broad_type = case_when(
      renewable == 1L ~ 'Renewable',
      fossil == 1L    ~ 'Fossil',
      battery == 1L    ~ 'Battery',
      TRUE            ~ 'Other'
    )
  )

### Building Micro-Level Panel with Flags

projects_clean_cat <- projects_clean %>%
  mutate(
    renewable = if_else(type1 %in% renewables_list, 1L, 0L),
    fossil    = if_else(type1 %in% fossils_list, 1L, 0L),
    battery   = if_else(type1 %in% batteries_list, 1L, 0L),
    other     = if_else(renewable == 0L & fossil == 0L, 1L, 0L),
    
    broad_type = case_when(
      renewable == 1L ~ 'Renewable',
      fossil == 1L    ~ 'Fossil',
      battery == 1L    ~ 'Battery',
      TRUE            ~ 'Other'
    )
  )


## Treatments   ----------------------------------------------------------------
# I did not automate this part. To compute Table 2, run this script
# for each of the variables.
# Depending on the dataset, some variables might need adjustment.

### Micro-Level (Overall) ------------------------------------------------------

df <- projects_lifetime
var_oi <- 'lifetime'
col_date <- 'q_date'

#### Computations

sub_df <- df[!is.na(df[[var_oi]]) & !is.na(df[[col_date]]), ]

vals <- sub_df[[var_oi]]
dates <- as.Date(sub_df[[col_date]])
q <- quantile(vals, probs = c(0.01, 0.50, 0.99))

outcome <- data.frame(
  Variable = var_oi,
  available_dates = paste(format(min(dates), '%Y-%m'), 'to', format(max(dates), '%Y-%m')),
  N_Obs = length(vals),
  Mean = round(mean(vals), 2),
  Median = round(median(vals), 2),
  SD = round(sd(vals), 2),
  P1 = round(q[1], 2),
  P50 = round(q[2], 2),
  P99 = round(q[3], 2),
  row.names = NULL
)

print(outcome)

#### Export

if (!dir.exists(here('outputs', 'stats'))) dir.create(here('outputs', 'stats'))

write.table(outcome, file = paste0('outputs/stats/statistics_panel_overall_',var_oi,'.txt'), 
            sep = '\t', row.names = FALSE, quote = FALSE)


### Technology -----------------------------------------------------------------

#### Setup

df <- projects_lifetime
var_oi <- 'lifetime'
col_date <- 'q_date'
col_cat <- 'type1'

sub_df <- df[!is.na(df[[var_oi]]) & !is.na(df[[col_date]]) & !is.na(df[[col_cat]]), ]

outcome <- do.call(rbind, lapply(split(sub_df, sub_df[[col_cat]]), function(sub) {
  vals <- sub[[var_oi]]
  dates <- as.Date(sub[[col_date]])
  q <- quantile(vals, probs = c(0.01, 0.50, 0.99))
  
  data.frame(
    Categorie = unique(sub[[col_cat]]),
    Variable = var_oi,
    available_dates = paste(format(min(dates), '%Y-%m'), 'à', format(max(dates), '%Y-%m')),
    N_Obs = length(vals),
    Mean = round(mean(vals), 2),
    Median = round(median(vals), 2),
    SD = round(sd(vals), 2),
    P1 = round(q[1], 2),
    P50 = round(q[2], 2),
    P99 = round(q[3], 2),
    row.names = NULL
  )
}))

print(outcome)

#### Export

if (!dir.exists(here('outputs', 'stats'))) dir.create(here('outputs', 'stats'))

write.table(
  outcome, 
  file = paste0('outputs/stats/statistics_', var_oi, '_by_', col_cat, '.txt'), 
  sep = '\t', 
  row.names = FALSE, 
  quote = FALSE
)

### Costs ----------------------------------------------------------------------

#### Setup
df <- data_eia
var_oi <- 'Avg_Construction_Cost_USD_per_kW'
col_date <- 'date'
col_cat1 <- 'sheet_name'
col_cat2 <- 'Category'

#### Computation

sub_df <- df[df$sheet_name == 'major_energy_source' & 
                !is.na(df[[var_oi]]) & 
                !is.na(df[[col_date]]) & 
                !is.na(df[[col_cat1]]) & 
                !is.na(df[[col_cat2]]), ]

groups <- split(sub_df, list(sub_df[[col_cat1]], sub_df[[col_cat2]]), drop = TRUE)

outcome <- do.call(rbind, lapply(groups, function(sub) {
  vals <- sub[[var_oi]]
  dates <- as.Date(sub[[col_date]])
  q <- quantile(vals, probs = c(0.01, 0.50, 0.99))
  
  data.frame(
    Groupe_1 = unique(sub[[col_cat1]]),
    Groupe_2 = unique(sub[[col_cat2]]),
    Variable = var_oi,
    available_dates = paste(format(min(dates), '%Y-%m'), 'to', format(max(dates), '%Y-%m')),
    N_Obs = length(vals),
    Mean = round(mean(vals), 2),
    Median = round(median(vals), 2),
    SD = round(sd(vals), 2),
    P1 = round(q[1], 2),
    P50 = round(q[2], 2),
    P99 = round(q[3], 2),
    row.names = NULL
  )
}))

print(outcome)

#### Export
if (!dir.exists(here('outputs', 'stats'))) dir.create(here('outputs', 'stats'))

write.table(
  outcome, 
  file = paste0('outputs/stats/statistics_', var_oi, '_cross.txt'), 
  sep = '\t', 
  row.names = FALSE, 
  quote = FALSE
)

## Queue Statistics ------------------------------------------------------------

panel |> 
  summarize(n = sum(renewable == 1 & q_status == 'withdrawn', na.rm = TRUE))

mean(panel$q_status[panel$renewable == 1] == 'withdrawn', na.rm = TRUE)

panel |> 
  filter(
    renewable == 1,
    between(q_date, as.Date('2000-01-01'), as.Date('2023-12-31'))
  ) |> 
  summarize(
    n_withdrawn = sum(q_status == 'withdrawn', na.rm = TRUE),
    total       = n(),
    proportion  = mean(q_status == 'withdrawn', na.rm = TRUE)
  )

projects_clean_cat |> 
  filter(
    renewable == 1,
    between(q_date, as.Date('2000-01-01'), as.Date('2020-12-31'))
  ) |> 
  summarize(
    n_withdrawn = sum(q_status == 'withdrawn', na.rm = TRUE),
    total       = n(),
    proportion  = mean(q_status == 'withdrawn', na.rm = TRUE)
  )
