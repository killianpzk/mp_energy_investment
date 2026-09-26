## Env -------------------------------------------------------------------------

rm(list=ls())

### Common Variables -----------------------------------------------------------

raw_path   <- 'raw_data'
clean_path <- 'cleaned_data'

### Imports --------------------------------------------------------------------

source(here::here('code/dependencies.R'))

#### Data ----------------------------------------------------------------------

##### Base ---------------------------------------------------------------------

queued_up <- read_excel(here(raw_path, 'queued_up.xlsx'), 
                        sheet = '03. Complete Queue Data', skip = 1,
                        na = c('NA', 'N/A', 'vide', ''))

mp_shocks_bs <-  read_excel(here(raw_path, 
                                 'mpshocks_bs.xlsx'), sheet = 2)

mp_shocks_bs_monthly <-  read_excel(here(raw_path, 
                                         'mpshocks_bs.xlsx'), sheet = 3)

mp_shocks_miranda_daily <-  read_excel(here(raw_path, 
                                            'mpshocks_miranda.xlsx'), sheet = 1)

mp_shocks_miranda_monthly <-  read_excel(here(raw_path, 
                                              'mpshocks_miranda.xlsx'), sheet = 2)

usmpd <-  read_excel(here(raw_path, 'USMPD.xlsx'), sheet = 4)

mp_shocks_ns <- read_excel(here(raw_path, 'mpshocks_ns.xlsx'), sheet = 'Data')

mp_shocks_swanson <- read_excel(here(raw_path, 
                                     'mpshocks_swanson.xlsx'), sheet = 'Data',
                                range = cell_limits(c(2, 2), c(NA, NA)))

mp_shocks_brw <- read.csv(here(raw_path, 'mpshocks_brw.csv'))

data_eia <- excel_sheets(here( raw_path, 'data_eia_costs_v2_raw.xlsx')) %>% 
  set_names() %>% 
  map(~ read_excel(here( raw_path, 'data_eia_costs_v2_raw.xlsx'), sheet = .x)) %>% 
  list_rbind(names_to = 'sheet_name')

nfci_raw <- read.csv(here(raw_path, 'nfci.csv'), stringsAsFactors = FALSE)

##### Bonds  -------------------------------------------------------------------

# bonds_3mo_hand <- read.csv(here(raw_path, 'bonds/DGS3MO.csv'))
# bonds_6mo_hand <- read.csv(here(raw_path, 'bonds/DGS6MO.csv'))
# bonds_1_hand <- read.csv(here(raw_path, 'bonds/DGS1.csv'))
# bonds_2_hand <- read.csv(here(raw_path, 'bonds/DGS2.csv'))
# bonds_5_hand <- read.csv(here(raw_path, 'bonds/DGS5.csv'))
# bonds_10_hand <- read.csv(here(raw_path, 'bonds/DGS10.csv'))
# bonds_20_hand <- read.csv(here(raw_path, 'bonds/DGS20.csv'))
# bonds_30_hand <- read.csv(here(raw_path, 'bonds/DGS30.csv'))

bonds_3mo <- fredr(series_id = 'DGS3MO', 
                   frequency = 'm',
                   aggregation_method = 'avg',
                   observation_start = as.Date('1988-01-01'),
                   observation_end = as.Date('2026-06-30')) %>% 
  select(date, DGS3MO = value)

bonds_6mo <- fredr(series_id = 'DGS6MO', 
                   frequency = 'm',
                   aggregation_method = 'avg',
                   observation_start = as.Date('1988-01-01'),
                   observation_end = as.Date('2026-06-30')) %>% 
  select(date, DGS6MO = value)

bonds_1 <- fredr(series_id = 'DGS1', 
                 frequency = 'm',
                 aggregation_method = 'avg',
                 observation_start = as.Date('1988-01-01'),
                 observation_end = as.Date('2026-06-30')) %>% 
  select(date, DGS1 = value)

bonds_2 <- fredr(series_id = 'DGS2', 
                 frequency = 'm',
                 aggregation_method = 'avg',
                 observation_start = as.Date('1988-01-01'),
                 observation_end = as.Date('2026-06-30')) %>% 
  select(date, DGS2 = value)

bonds_5 <- fredr(series_id = 'DGS5', 
                 frequency = 'm',
                 aggregation_method = 'avg',
                 observation_start = as.Date('1988-01-01'),
                 observation_end = as.Date('2026-06-30')) %>% 
  select(date, DGS5 = value)

bonds_10 <- fredr(series_id = 'DGS10', 
                  frequency = 'm',
                  aggregation_method = 'avg',
                  observation_start = as.Date('1988-01-01'),
                  observation_end = as.Date('2026-06-30')) %>% 
  select(date, DGS10 = value)

bonds_20 <- fredr(series_id = 'DGS20', 
                  frequency = 'm',
                  aggregation_method = 'avg',
                  observation_start = as.Date('1988-01-01'),
                  observation_end = as.Date('2026-06-30')) %>% 
  select(date, DGS20 = value)

bonds_30 <- fredr(series_id = 'DGS30', 
                  frequency = 'm',
                  aggregation_method = 'avg',
                  observation_start = as.Date('1988-01-01'),
                  observation_end = as.Date('2026-06-30')) %>% 
  select(date, DGS30 = value)

##### Controls -----------------------------------------------------------------

cpi      <- fredr(series_id = 'CPIAUCSL',
                  observation_start = as.Date('1988-01-01'),
                  observation_end = as.Date('2026-06-30')) %>% 
  select(date, cpi = value)

unrate   <- fredr(series_id = 'UNRATE',
                  observation_start = as.Date('1988-01-01'),
                  observation_end = as.Date('2026-06-30'))   %>% 
  select(date, chomage_lvl = value)

fedfunds <- fredr(series_id = 'FEDFUNDS',
                  observation_start = as.Date('1988-01-01'),
                  observation_end = as.Date('2026-06-30')) %>% 
  select(date, fedfunds_lvl = value)

## Cleaning --------------------------------------------------------------------

queued_up_clean <- queued_up %>%
  mutate(
    across(
      ends_with('_date'), 
      ~ .x %>% 
        as.numeric() %>% 
        excel_numeric_to_date()
    )
  )

### MPS

mp_shocks_bs_clean <- mp_shocks_bs %>%
  mutate(
    date = as_date(Date),
    time = parse_time(Time, format = '%I:%M%p'),
    timestamp = parse_date_time(paste(date, Time), orders = 'ymd IMp')
  ) %>%
  select(-Date, -Time)

mp_shocks_bs_monthly_clean <- mp_shocks_bs_monthly %>%
  mutate(
    date = ym(paste(Year, Month))
  ) %>%
  select(-Year, -Month)

mp_shocks_miranda_daily_clean <- mp_shocks_miranda_daily %>%
  rename(
    hf_dates = `HF Dates`,
    fomc_dates = `FOMC Dates`,
    gb_dates = `GB Dates`
  ) %>%
  mutate(
    across(ends_with('_dates'), as_date)
  )

mp_shocks_miranda_monthly_clean <- mp_shocks_miranda_monthly %>%
  rename(date = time) %>%
  mutate(date = ym(date))

usmpd_clean <- usmpd %>%
  rename(date = Date) %>%
  mutate(date = as.Date(date),
         date_time = ymd_hms(date_time))

mp_shocks_ns_clean <- mp_shocks_ns %>%
  mutate(date = as.Date(date))

mp_shocks_swanson_clean <- mp_shocks_swanson %>%
  rename(date = ...1) %>%
  mutate(date = case_when(
    str_detect(date, '/') ~ parse_date_time(date, orders = c('dmy', 'mdy')),
    TRUE ~ as.Date(as.numeric(date), origin = '1899-12-30')
  ))

mp_shocks_brw_clean <- mp_shocks_brw %>%
  rename(date_month = date) %>%
  rename(date = Month) %>%
  mutate(date = ym(date)) %>%
  mutate(
    date_month = na_if(date_month, ''),
    date_month = dmy(date_month, tz = 'UTC') %>% as.POSIXct()
  )

### Bonds

bonds_clean <- bonds_3mo %>%
  full_join(bonds_6mo, by = 'date') %>%
  full_join(bonds_1,   by = 'date') %>%
  full_join(bonds_2,   by = 'date') %>%
  full_join(bonds_5,   by = 'date') %>%
  full_join(bonds_10,  by = 'date') %>%
  full_join(bonds_20,  by = 'date') %>%
  full_join(bonds_30,  by = 'date') %>%
  arrange(date) %>%
  mutate(date = as.Date(date))

macro_controls <- cpi %>%
  left_join(unrate, by = 'date') %>%
  left_join(fedfunds, by = 'date') %>%
  arrange(date) %>%
  mutate(
    inflation_logdiff = log(cpi) - log(lag(cpi, n = 1)),
    month_date = floor_date(date, 'month')
  ) %>%
  filter(!is.na(inflation_logdiff)) %>%
  select(month_date, inflation_logdiff, chomage_lvl, fedfunds_lvl) %>%
  rename(date = month_date)

### Costs

data_eia_monthly <- data_eia %>%
  uncount(12, .id = 'Month') %>%
  mutate(date = make_date(year = Year, month = Month, day = 1)) %>%
  select(date, everything(), -Year, -Month)

nfci_monthly <- nfci_raw %>%
  mutate(month_date = floor_date(as.Date(Friday_of_Week, format = "%m/%d/%Y"), "month")) %>%
  group_by(month_date) %>%
  summarise(NFCI = mean(NFCI, na.rm = TRUE), .groups = "drop")

## Construction of the Master DF -----------------------------------------------

vars_list <- list(
  mp_shocks_brw           = mp_shocks_brw_clean %>% select(date, shock_brw = BRW_monthly),
  mp_shocks_bs            = mp_shocks_bs_monthly_clean %>% select(date, shock_bs = MPS, shock_bs_orth = MPS_ORTH),
  mp_shocks_miranda       = mp_shocks_miranda_monthly_clean %>% select(date, shock_miranda_1 = MM_IV1, shock_miranda_5 = MM_IV5),
  mp_shocks_ns            = mp_shocks_ns_clean %>% select(date, shock_ns = NS),
  mp_shocks_swanson       = mp_shocks_swanson_clean %>% select(date, shock_swanson_FFR = `Federal Funds Rate factor`, 
                                                               shock_swanson_FG = `Forward Guidance factor`, 
                                                               shock_swanson_LSAP = `LSAP factor`),
  usmpd                   = usmpd_clean %>% select(date, usmpd_mp1 = MP1, usmpd_mp2 = MP2, usmpd_ust10y = UST10Y, 
                                                   usmpd_ust30y = UST30Y, usmpd_tips10y = TIPS10Y, usmpd_tips30y = TIPS30Y),
  bonds                   = bonds_clean %>% select(date, `2y_bonds` = DGS2,`5y_bonds` = DGS5,`10y_bonds` = DGS10, `30y_bonds` = DGS30)
)

aggregate_monthly <- function(df) {
  df %>%
    rename(date = any_of(c('month_date', 'date'))) %>% 
    mutate(date = floor_date(date, 'month')) %>% 
    group_by(date) %>% 
    summarise(across(everything(), ~ sum(.x, na.rm = TRUE)), .groups = 'drop') %>% 
    
    complete(
      date = seq(from = min(date, na.rm = TRUE), 
                 to = max(date, na.rm = TRUE), 
                 by = 'month'),
      fill = list()
    ) %>% 
    
    # Replace NAs with 0
    mutate(across(-date, ~ replace_na(.x, 0)))
}

monthly_vars <- map(vars_list, aggregate_monthly)

prepared_monthly_vars <- map(monthly_vars, function(df) {
  df %>%
    mutate(date = as.Date(date))
})

summary_matrix <- prepared_monthly_vars %>%
  reduce(full_join, by = 'date') %>%
  arrange(date)


## Export -----------------------------------------------------------------

### CSV  -----------------------------------------------------------------
# write.csv(queued_up_clean,here(clean_path, 'queued_up.csv'),row.names = FALSE)
# write.csv(mp_shocks_bs_clean,here(clean_path, 'mp_shocks_bs.csv'),row.names = FALSE)
# write.csv(mp_shocks_bs_monthly_clean,here(clean_path, 'mp_shocks_bs_monthly.csv'),row.names = FALSE)
# write.csv(mp_shocks_miranda_daily_clean,here(clean_path, 'mp_shocks_miranda_daily.csv'),row.names = FALSE)
# write.csv(mp_shocks_miranda_monthly_clean,here(clean_path, 'mp_shocks_miranda_monthly.csv'),row.names = FALSE)
# write.csv(usmpd_clean,here(clean_path, 'usmpd.csv'),row.names = FALSE)
# write.csv(bonds_clean,here(clean_path, 'bonds.csv'),row.names = FALSE)
# write.csv(mp_shocks_ns_clean,here(clean_path, 'mp_shocks_ns.csv'),row.names = FALSE)
# write.csv(mp_shocks_swanson_clean,here(clean_path, 'mp_shocks_swanson.csv'),row.names = FALSE)
# write.csv(mp_shocks_brw_clean,here(clean_path, 'mp_shocks_brw.csv'),row.names = FALSE)
# write.csv(summary_matrix,here(clean_path, 'master_vars.csv'),row.names = FALSE)
# write.csv(macro_controls,here(clean_path, 'macro_controls.csv'),row.names = FALSE)
# write.csv(data_eia_monthly,here(clean_path, 'data_eia_monthly.csv'),row.names = FALSE)

### Parquet  -----------------------------------------------------------------
# write_parquet(queued_up_clean,here(clean_path, 'queued_up.parquet'))
# write_parquet(mp_shocks_bs_clean,here(clean_path, 'mp_shocks_bs.parquet'))
# write_parquet(mp_shocks_bs_monthly_clean,here(clean_path, 'mp_shocks_bs_monthly.parquet'))
# write_parquet(mp_shocks_miranda_daily_clean,here(clean_path, 'mp_shocks_miranda_daily.parquet'))
# write_parquet(mp_shocks_miranda_monthly_clean,here(clean_path, 'mp_shocks_miranda_monthly.parquet'))
# write_parquet(usmpd_clean,here(clean_path, 'usmpd.parquet'))
# write_parquet(bonds_clean,here(clean_path, 'bonds.parquet'))
# write_parquet(mp_shocks_ns_clean,here(clean_path, 'mp_shocks_ns.parquet'))
# write_parquet(mp_shocks_swanson_clean,here(clean_path, 'mp_shocks_swanson.parquet'))
# write_parquet(mp_shocks_brw_clean,here(clean_path, 'mp_shocks_brw.parquet'))
# write_parquet(summary_matrix,here(clean_path, 'master_vars.parquet'))
# write_parquet(macro_controls,here(clean_path, 'macro_controls.parquet'))
# write_parquet(data_eia_monthly,here(clean_path, 'data_eia_monthly.parquet'))

### RDS   -----------------------------------------------------------------
# saveRDS(queued_up_clean,here(clean_path, 'queued_up.rds'))
# saveRDS(mp_shocks_bs_clean,here(clean_path, 'mp_shocks_bs.rds'))
# saveRDS(mp_shocks_bs_monthly_clean,here(clean_path, 'mp_shocks_bs_monthly.rds'))
# saveRDS(mp_shocks_miranda_daily_clean,here(clean_path, 'mp_shocks_miranda_daily.rds'))
# saveRDS(mp_shocks_miranda_monthly_clean,here(clean_path, 'mp_shocks_miranda_monthly.rds'))
# saveRDS(usmpd_clean,here(clean_path, 'usmpd.rds'))
# saveRDS(bonds_clean,here(clean_path, 'bonds.rds'))
# saveRDS(mp_shocks_ns_clean,here(clean_path, 'mp_shocks_ns.rds'))
# saveRDS(mp_shocks_swanson_clean,here(clean_path, 'mp_shocks_swanson.rds'))
# saveRDS(mp_shocks_brw_clean,here(clean_path, 'mp_shocks_brw.rds'))
# saveRDS(summary_matrix,here(clean_path, 'master_vars.rds'))
# saveRDS(macro_controls,here(clean_path, 'macro_controls.rds'))
# saveRDS(data_eia_monthly,here(clean_path, 'data_eia_monthly.rds'))
# saveRDS(nfci_monthly,here(clean_path, 'nfci_monthly.rds'))