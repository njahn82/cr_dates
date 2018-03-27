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
             created = result$created$`date-time`, 
             published_print = paste(result$`published-print`$`date-parts`, collapse = "-"),
             published_online = paste(result$`published-online`$`date-parts`, collapse = "-"),
             issued = paste(result$issued$`date-parts`, collapse = "-")
  )
}
#' Loop over offsetting DOIs 
cr_oapc <- purrr::map(oapc$doi, purrr::safely(cr_date_parser)) 
cr_oapc_df <- purrr::map_df(cr_oapc, "result")
readr::write_csv(cr_oapc_df, "cr_dates.csv")
readr::write_csv(oapc, "oapc_data.csv")
