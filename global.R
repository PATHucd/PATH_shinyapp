#global

library(shiny)
library(DBI)
library(dbplyr)
library(pool)
library(tidyverse)
library(config)
library(bslib)
library(leaflet)
library(V8)
library(DT)
library(tidyverse)
library(RPostgres)
library(plotly)
library(htmltools)

# add to git ignore so this info doesnt get uploaded
args <- config::get("dataconnection")
con <- pool::dbPool(odbc::odbc(),
                    driver = args$driver,
                    database = args$database,
                    uid = args$uid,
                    pwd = args$pwd,
                    server = args$server,
                    port = args$port
)

# Table hooks
all_animals <- tbl(con, in_schema("discovery", "all_animals"))
pre_summary <- tbl(con, in_schema("discovery", "detection_pre_summary"))
stations <- tbl(con, in_schema("discovery", "stations_header"))

#Changed code

#added the obis table 
obis.otn_animals <- tbl(con, in_schema("obis", "otn_animals"))
obis.publication_control <- tbl(con, in_schema("obis", "publication_control"))

#This should work and is a better solution to excluding projects that don't want to share data but doesn't

# Static date
#static_date <- as.Date('2023-12-22')

# Filter obis.otn_animals dataset based on datedetectionsreleased using the static date
#filtered_catalog_numbers <- obis.otn_animals %>%
#  filter(datedetectionsreleased > static_date) %>%
#  pull(catalognumber)

# Filter pre_summary based on relatedcatalogitem matching filtered catalog numbers
#result <- pre_summary %>%
#  filter(relatedcatalogitem %in% filtered_catalog_numbers)


#This will need to be updated when they want to share data or someone else doesn't want to share. I can't make the more elegant code work
# I am also filtering out all scientific name is na data so its only animal detections instead of unmatched tags (myster tags etc.)
result <- pre_summary %>%
  filter(collectioncode != 'CDFWA15') %>%
  filter(trackercode != 'CDFWA15')

pre_summary <- result

#normal code

species_available <- all_animals |>
  select(scientificname) |>
  distinct() |>
  pull(scientificname) |>
  sort()

species_tbl <- tbl(con, in_schema("discovery", "species_list")) |>
  select(scientificname, commonname) |>
  filter(scientificname %in% species_available) |>
  distinct()

# Available options for the UI
year_range <- pre_summary |>
  summarise(min = lubridate::year(min(min_detectdate, na.rm = TRUE)),
            max = lubridate::year(max(max_detectdate, na.rm = TRUE))) |>
  collect()

projects_available <- tbl(con, in_schema("discovery", "mstr_resources")) |>
  pull(collectioncode) |>
  sort()

locations_available <- pre_summary |>
  select(station) |>
  distinct() |>
  pull(station) |>
  sort()

species <- tbl(con, in_schema("discovery", "species_list")) |>
  select(scientificname, commonname) |>
  filter(scientificname %in% species_available) |>
  distinct() |>
  collect()

common_names <- species_tbl |>
  pull(commonname)

default_year <- 2017L
initial_tags <- tbl(con, in_schema("ucdhist", paste0("otn_detections_", default_year))) |>
  select(fieldnumber) |>
  distinct() |>
  collect()

# Update leaflet providers to get some of the newer maps
leaflet.providers::use_providers(leaflet.providers::get_providers())


# A simple function to add single quotes around a string.  Useful in constructing SQL clauses.
sq <- function(x) {
  paste0("\'", as.character(x), "\'")
}

# Shutdown chores
onStop(function() {
  poolClose(con)
})

# SQL Queries to PATH details that are too complex to do in R
sql_receiver_meta <- "select
	rcv.otn_array, --otn_array varchar NULL,
	rcv.station_name as station_no, --station_no varchar NULL,
	replace(rcv.deploy_date::text, ' ', 'T') as deploy_date_time, --deploy_date_time varchar NULL,
	rcv.dep_lat::text as deploy_lat, --deploy_lat varchar NULL,
	rcv.dep_long::text as deploy_long, --deploy_long varchar NULL,
	rcv.bottom_depth, --bottom_depth varchar NULL,
	rcv.receiver_depth::text as instrument_depth,--instrument_depth varchar NULL,
	rcv.rcv_model_no as ins_model_no, --ins_model_no varchar NULL,
	rcv.rcv_serial_no as ins_serial_no, --ins_serial_no varchar NULL,
	moor_tra.fieldnumber as transmitter, --transmitter varchar NULL,
	moor_tra.instrumentmodel as transmit_model, --transmit_model varchar NULL,
	coalesce(interim_recover_ind, rcv.recover_ind) as recovered, --recovered varchar NULL,
	replace(rcv.recover_date::text, ' ', 'T') as recover_date_time, --recover_date_time varchar NULL,
	rcv.recover_lat::text as recover_lat, --recover_lat varchar NULL,
	rcv.recover_long::text as recover_long, --recover_long varchar NULL,
	case when moor_down.catalognumber is null then 'n' else 'y' end as data_downloaded, --data_downloaded varchar NULL,
	moor_down.dat as download_date_time, --download_date_time varchar NULL,
	rcv.notes as comments --comments varchar NULL
from ucdhist.rcvr_locations rcv
left join (select * from ucdhist.moorings where basisofrecord ='TRANSMITTER') moor_tra
on moor_tra.collectornumber = rcv.rcv_serial_no and moor_tra.relatedcatalogitem = rcv.station_name
left join (
	select catalognumber, relatedcatalogitem, coalesce(enddatetime, startdatetime) as dat from ucdhist.moorings where basisofrecord = 'DOWNLOAD' and
	(relatedcatalogitem, coalesce(enddatetime, startdatetime)) in (
		select relatedcatalogitem, max(coalesce(enddatetime, startdatetime))
		from ucdhist.moorings where basisofrecord = 'DOWNLOAD'
		group by 1
	)
) moor_down
on moor_down.relatedcatalogitem = rcv.catalognumber
where rcv.station_name = ?station"
