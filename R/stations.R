
stationsUI <- function(id, label = 'Station Map UI') {
  ns <- NS(id)

  tagList(
    leafletOutput(ns("map"), height = "500px"),
    plotlyOutput(ns("selected")),
    DT::dataTableOutput(ns("receiver"))
  )
}

stationsServer <- function(id, data_query, parent) {
  moduleServer(
    id,
    function(input, output, session) {


      station_data <- reactive({

        df <- data_query() |>
          group_by(station, commonname) |>
          summarise(detection_count = sum(detection_count, na.rm = TRUE),
                    latitude = max(latitude, na.rm = TRUE),
                    longitude = max(longitude, na.rm = TRUE),
                    .groups = "drop") |>
          collect()
        df
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

      # Color palette for the map
      pal <- colorNumeric(
        palette = "viridis",
        domain = NULL
      )

      # Update the map when something changes
      observe({

        # Only update if this is the currently active tab - otherwise leafletProxy
        # will not work
        if (parent$input$tabs != "Stations") {
          return(NULL)
        }

        d <- station_data()
        if (is.null(d)) {
          return(NULL)
        }

        # Clear out the previous data
        lp <- leafletProxy("map", session = session, data = d) |>
          clearMarkers() |>
          clearControls() |>
          clearMarkerClusters()

        # Add the new data
        if (nrow(d) > 0) {
          lp <- lp |>
            addCircleMarkers(radius = 2, lng = ~longitude, lat = ~latitude,
                             color = ~pal(detection_count),
                             label = ~station,
                             layerId = ~station) |>
            addLegend(position = "bottomleft", pal = pal, values = ~detection_count)
        }
        lp

      })

      # A plot to display when a station on the map is clicked
      output$selected <- renderPlotly({

        click <- input$map_marker_click
        validate(need(!is.null(click), "Select a point"))

        id <- click$id

        df <- data_query() |>
          filter(station == id) |>
          collect() |>
          mutate(detection_count = as.numeric(detection_count),
                 commonname = if_else(is.na(commonname), " Not Listed",
                                      commonname))

        g <- ggplot(df, aes(x = min_detectdate, y = commonname,
                            color = detection_count)) +
          geom_point() +
          scale_color_viridis_c() +
          scale_x_datetime(labels = scales::label_date_short()) +
          labs(title = id,
               x = "detection date",
               color = "detection count") +
          theme(axis.title.y = element_blank())

        ggplotly(g)

      })

      # Receiver metadata to display when plot is clicked
      output$receiver <- DT::renderDataTable({

        click <- input$map_marker_click
        validate(need(!is.null(click), "Select a point"))

        station <- click$id

        q <- sqlInterpolate(con, sql_receiver_meta, station = station)
        df <- dbGetQuery(con, q)
        datatable(df)

      })



    }
  )
}
