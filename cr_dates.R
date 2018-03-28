#' get offsetting data
library(tidyverse)
library(jsonlite)
library(rcrossref)
#' get offsetting data from open apc
oapc <- readr::read_csv("https://raw.githubusercontent.com/OpenAPC/openapc-de/master/data/offsetting/offsetting.csv") %>%
  # only springer pubs
  filter(publisher == "Springer Nature")
oapc
#' helper function to parse crossref json for the different date types
#' 
#' @param doi
cr_date_parser <- function(doi) {
  req <- rcrossref::cr_works_(doi, parse = FALSE) %>%
    jsonlite::fromJSON()
  result <- req$message
  data_frame(doi = result$DOI, 
             # doi created
             created = result$created$`date-time`, 
             # print publication date
             published_print = paste(result$`published-print`$`date-parts`, collapse = "-"),
             # online publication date
             published_online = paste(result$`published-online`$`date-parts`, collapse = "-"),
             # issued date (earliest known publication date)
             issued = paste(result$issued$`date-parts`, collapse = "-")
  )
}
#' Loop over offsetting DOIs 
cr_oapc <- purrr::map(oapc$doi, purrr::safely(cr_date_parser)) 
cr_oapc_df <- purrr::map_df(cr_oapc, "result")
#' backup
readr::write_csv(cr_oapc_df, "cr_dates.csv")
readr::write_csv(oapc, "oapc_data.csv")
#' 
oapc <- readr::read_csv("oapc_data.csv")
cr_dates <- readr::read_csv("cr_dates.csv")
oapc %>% 
  select(doi, period, institution) %>% 
  inner_join(cr_dates) %>% 
  mutate_at(vars(published_print:issued), funs(lubridate::parse_date_time(., c('y', 'ymd', 'ym')))) %>%
  mutate_at(vars(created:issued), funs(lubridate::year(.))) %>%
  mutate(`Earliest publication year` = issued - period,
         `Year DOI created` = created - period,
         `Print publication year` = published_print - period,
         `Online publication year` = published_online - period) %>%
  #' backup 
  readr::write_csv("cr_dates_apc_yearly_diffs.csv")
