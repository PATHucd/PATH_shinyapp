tagUI <- function(id, label = 'Tag History UI') {
  ns <- NS(id)

  tagList(
    fluidRow(
      column(width = 3, selectInput(ns("year"), "Year",
                                    choices = seq(year_range$min, year_range$max),
                                    selected = 2017L)),
      column(width = 3, selectInput(ns("tag_code"), "Tag Code",
                                       choices = initial_tags)),
    ),
    fluidRow(
      leafletOutput(ns("map"), height = "500px")
    )
  )
}

tagServer <- function(id, parent) {
  moduleServer(
    id,
    function(input, output, session) {

      # update list of tags based on year
      observeEvent(input$year, {

        dbtable <- tbl(con, in_schema("ucdhist", paste0("otn_detections_", input$year)))
        tags <- dbtable |>
          select(fieldnumber) |>
          distinct() |>
          collect()

        updateSelectInput(session, "tag_code", choices = tags)

      })


      tag_history <- reactive({

        if (is.null(input$tag_code)) return(NULL)

        # will not work on some years - fix!
        dbtable <- tbl(con, in_schema("ucdhist", paste0("otn_detections_", input$year)))
        df <- dbtable |>
          filter(fieldnumber == !!input$tag_code) |>
          collect() |>
          mutate(dt_num = as.numeric(datecollected))

      })

      output$map <- renderLeaflet({

        leaflet() |>
          addProviderTiles("Esri.WorldGrayCanvas", group = "Gray") |>
          addProviderTiles("OpenStreetMap.Mapnik", group = "Mapnik") |>
          addProviderTiles("USGS.USTopo", group = "USTopo") |>
          addProviderTiles("USGS.USImageryTopo", group = "USImageTopo") |>
          addProviderTiles("Esri.NatGeoWorldMap", group = "NatGeo") |>
          setView(-120, 39, zoom = 7) |>
          addLayersControl(baseGroups = c("Mapnik", "USTopo",
                                          "USImageTopo", "NatGeo", "Gray"))

      })

      # An extension of the leaflet label formatter to support dates
      myLabelFormat = function(...,dates=FALSE){
        if(dates){
          function(type = "numeric", cuts){
            as.Date(as.POSIXct(cuts, origin="1970-01-01"))
          }
        }else{
          labelFormat(...)
        }
      }

      # Update the map when something changes
      observe({

        # Only update if this is the currently active tab - otherwise leafletProxy
        # will not work
        if (parent$input$tabs != "Tag History") {
          return(NULL)
        }

        d <- tag_history()
        if (is.null(d)) {
          return(NULL)
        }

        # Color palette for the map
        pal <- colorNumeric(
          palette = "viridis",
          domain = d$dt_num
        )

        # Clear out the previous data
        lp <- leafletProxy("map", session = session, data = d) |>
          clearMarkers() |>
          clearControls() |>
          clearMarkerClusters()

        # Add the new data
        # Add legend not working with difftime data for some reason
        if (nrow(d) > 0) {
          lp <- lp |>
            addCircleMarkers(radius = 2, lng = ~longitude, lat = ~latitude,
                             color = ~pal(dt_num),
                             label = ~datecollected) |>
            addLegend(position = "bottomleft", pal = pal,
                      values = ~dt_num,
                      labFormat = myLabelFormat(dates = TRUE))
        }
        lp

      })

    }
  )
}
