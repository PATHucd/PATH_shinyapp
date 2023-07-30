shinyServer(function(input, output, session) {


  
  data_query <- sharedServer("shared")
  station_map <- stationsServer("stations", data_query, parent = session)
  summary_data <- summaryServer("summary", data_query)
  tag_history <- tagServer("tag", parent = session)
  callModule(about, "about")
})
