packages <- c(
  "arrow",
  "corrplot",
  "dplyr",
  "fastDummies",
  "fixest",
  "fredr",
  "ggplot2",
  "ggpattern",
  "haven",
  "here",
  "janitor",
  "lubridate",
  "purrr",
  "readr",
  "readxl",
  "stringr",
  "tidylog",
  "tidyr",
  "tseries",
  "xtable"
)

missing_pkgs <- packages[!(packages %in% installed.packages()[, "Package"])]

if (length(missing_pkgs) > 0) {
  install.packages(missing_pkgs)
}

invisible(lapply(packages, library, character.only = TRUE))

fredr_set_key("c5db2a2e4c6bd887a47320bb788d8c54") 