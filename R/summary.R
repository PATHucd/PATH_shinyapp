
summaryUI <- function(id, label = 'Data Summary Table UI') {
  ns <- NS(id)

  tagList(
    # Set padding on the datatable cells
    tags$style('#dt td {padding: 0 1em}'),
    downloadButton(ns("download")),
    br(), br(),
    DT::dataTableOutput(ns("dt"), height = "600px")
  )
}


summaryServer <- function(id, data_query) {
  moduleServer(
    id,
    function(input, output, session) {

      output$dt <- DT::renderDataTable({
        df <- data_query() |>
          filter(!is.na(scientificname) & scientificname != "") |>
          distinct(weekcollected, station, scientificname, .keep_all = TRUE) |>
          collect()
        datatable(df [, c("commonname", "scientificname", "station", "latitude", "longitude", "detection_count", "weekcollected", "min_detectdate", "max_detectdate",
                           "collectioncode", "trackercode")],  # Keep specified columns
                  class = "compact stripe hover nowrap",
                  rownames = FALSE,
                  fillContainer = TRUE,
                  options = list(
                    pageLength = 30,
                    dom = "ftpi"
                  )
        )

      })

      output$download <- downloadHandler(
        filename = function() {
          paste0("PATH_extract_", Sys.Date(), ".csv")
        },
        content = function(filename) {
          df <- data_query() |>
            filter(!is.na(scientificname) & scientificname != "") |>
            distinct(weekcollected, station, scientificname, .keep_all = TRUE) |>
            collect()
          write_csv(df, filename)
        }
      )

    }
  )
}

