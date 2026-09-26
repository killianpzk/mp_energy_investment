## Env -------------------------------------------------------------------------

rm(list=ls())

### Common Variables -----------------------------------------------------------

raw_path   <- 'raw_data'
clean_path <- 'cleaned_data'

### Imports --------------------------------------------------------------------

source(here::here('code','dependencies.R'))

#### Data ----------------------------------------------------------------------

##### RDS ----------------------------------------------------------------------

queued_up <- readRDS(here(clean_path, 'queued_up.rds'))

master_vars <- readRDS(here(clean_path, 'master_vars.rds')) 

macro_controls <- readRDS(here(clean_path, 'macro_controls.rds'))

nfci_monthly <- readRDS(here(clean_path, 'nfci_monthly.rds'))

##### Clean --------------------------------------------------------------------

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
      # Filtering
      q_status == 'withdrawn'   ~ wd_date,
      q_status == 'operational' ~ pmax(on_date, q_date, na.rm = TRUE),
      TRUE                      ~ mps_end
    ),
    is_withdrawal = as.integer(q_status == 'withdrawn')
  ) %>%
  filter(!is.na(end_date))

cat('Total Projects:', nrow(projects_clean), '\n')

## Building Monthly Panel ------------------------------------------------------

panel_long <- projects_clean %>%
  rowwise() %>%
  mutate(
    month_seq = list(seq(
      floor_date(q_date, 'month'),
      floor_date(end_date, 'month'),
      by = 'month'
    ))
  ) %>%
  ungroup() %>%
  unnest(cols = month_seq) %>%
  rename(month_date = month_seq) %>%
  mutate(
    in_queue = if_else(
      month_date >= floor_date(q_date, 'month') &
        (is.na(wd_date) | month_date <= floor_date(wd_date, 'month')) &
        (is.na(on_date) | month_date <= floor_date(on_date, 'month')),
      1L, 0L
    ),
    withdrew_this_month = if_else(
      is_withdrawal == 1L & floor_date(wd_date, 'month') == month_date,
      1L, 0L
    )
  ) %>%
  filter(in_queue == 1L, month_date <= floor_date(mps_end, 'month'))

cat('Number of Observations:', nrow(panel_long), '\n')

### Merging with Macro Data ------------------------------------------------------

panel <- panel_long %>%
  left_join(master_vars,  by = c('month_date'='date')) %>%
  left_join(macro_controls,  by = c('month_date'='date')) %>%
  left_join(nfci_monthly,   by = 'month_date') %>%
  mutate(
    time_trend     = as.numeric(month_date - min(month_date, na.rm = TRUE)) / 30.4,
    tenure_months  = as.numeric(interval(floor_date(q_date, 'month'), month_date) / months(1)),
    state          = as.factor(state),
    entry_cohort   = as.factor(entry_cohort)
  )


## Building Aggregated Panel ---------------------------------------------------

panel_group <- panel %>%
  group_by(month_date, region, state, county, type1, type2) %>%
  summarise(
    # Nb projects
    nb_in_queue = n(),
    nb_entered   = sum(floor_date(q_date, 'month') == month_date, na.rm = TRUE),
    nb_withdrew  = sum(withdrew_this_month, na.rm = TRUE),
    
    # Size
    mw_in_queue = sum(mw1, na.rm = TRUE),
    mw_entered   = sum(if_else(floor_date(q_date, 'month') == month_date, mw1, 0), na.rm = TRUE),
    mw_withdrew  = sum(if_else(withdrew_this_month == 1L, mw1, 0), na.rm = TRUE),
    
    # Mean tenure
    mean_tenure_months = mean(tenure_months, na.rm = TRUE),
    
    across(shock_brw:NFCI, ~ first(.x)),
    time_trend = first(time_trend),
    .groups = 'drop'
  ) %>%
  
  # Variations
  mutate(
    projets_net_variation = nb_entered - nb_withdrew,
    mw_net_variation     = mw_entered - mw_withdrew
  )

cat('Number of Observations (Aggregated Panel):', nrow(panel_group), '\n')

# Check
setdiff(union(names(panel), names(panel_group)), intersect(names(panel), names(panel_group)))

## Construction State-Type Panel -----------------------------------------------

### Technologies ---------------------------------------------------------------

renewables_list <- c('Solar', 'Wind', 'Offshore Wind', 'Hydrogen')
fossils_list    <- c('Gas', 'Coal', 'Biofuel', 'Diesel', 'Oil', 'Nuclear') 
batteries_list <- c('Battery', 'Flywheel')

### Flagging -------------------------------------------------------------------

panel_group_flagged <- panel_group %>%
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

### Building -------------------------------------------------------------------

panel_state_type <- panel_group_flagged %>%
  group_by(month_date, region, state, county, broad_type) %>%   
  summarise(
    mean_tenure_months = weighted.mean(mean_tenure_months, w = nb_in_queue, na.rm = TRUE),
    nb_in_queue        = sum(nb_in_queue, na.rm = TRUE),
    nb_entered         = sum(nb_entered, na.rm = TRUE),
    nb_withdrew        = sum(nb_withdrew, na.rm = TRUE),
    mw_in_queue        = sum(mw_in_queue, na.rm = TRUE),
    mw_entered         = sum(mw_entered, na.rm = TRUE),
    mw_withdrew        = sum(mw_withdrew, na.rm = TRUE),
    .groups = 'drop'
  ) %>%
  complete(
    month_date, 
    nesting(state, broad_type),
    fill = list(
      nb_in_queue = 0, nb_entered = 0, nb_withdrew = 0,
      mw_in_queue = 0, mw_entered = 0, mw_withdrew = 0,
      mean_tenure_months = 0
    )
  ) %>%
  left_join(master_vars,    by = c('month_date' = 'date')) %>%
  left_join(macro_controls, by = c('month_date' = 'date')) %>%
  left_join(nfci_monthly,   by = 'month_date') %>%
  mutate(
    time_trend            = as.numeric(month_date - min(month_date, na.rm = TRUE)) / 30.4,
    projets_net_variation = nb_entered - nb_withdrew,
    mw_net_variation      = mw_entered - mw_withdrew
  )

## Export -----------------------------------------------------------------

### CSV  -----------------------------------------------------------------
# write.csv(panel,here(clean_path, 'panel.csv'),row.names = FALSE)
# write.csv(panel_group,here(clean_path, 'panel_group.csv'),row.names = FALSE)
# write.csv(panel_state_type,here(clean_path, 'panel_state_type.csv'),row.names = FALSE)

### Parquet  -----------------------------------------------------------------
# write_parquet(panel,here(clean_path, 'panel.parquet'))
# write_parquet(panel_group,here(clean_path, 'panel_group.parquet'))
# write_parquet(panel_state_type,here(clean_path, 'panel_state_type.parquet'))

### RDS   -----------------------------------------------------------------
# saveRDS(panel,here(clean_path, 'panel.rds'))
# saveRDS(panel_group,here(clean_path, 'panel_group.rds'))
# saveRDS(panel_state_type,here(clean_path, 'panel_state_type.rds'))