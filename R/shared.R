sharedUI <- function(id, label = 'Shared data selection UI') {
  ns <- NS(id)

  tagList(
    selectInput(ns("species"), "Species", choices = common_names,
                multiple = TRUE),
    sliderInput(ns("year"), "Years", min = year_range$min, max = year_range$max,
                value = c(2017, year_range$max),
                step = 1, dragRange = TRUE, sep = ""),
    selectInput(ns("locations"), "Detection Locations",
                choices = locations_available, multiple = TRUE),
    selectInput(ns("project"), "Projects", choices = projects_available,
                selected = "UCDHIST", multiple = TRUE),
    actionButton(ns("tags"), "Tag Codes")
  )
}


sharedServer <- function(id) {
  moduleServer(
    id,
    function(input, output, session) {

      # Dynamic UI ----

      observeEvent(input$tags, {

        if (is.null(tag_code_list())) {
          input_text <- ""
        } else {
          input_text <- paste(tag_code_list(), collapse = "\n")
        }

        showModal(modalDialog(
          title = "Specify Tag Codes",
          size = "l",
          textAreaInput("tag_codes", "Enter or copy tag codes here, separated by commas or whitespace",
                        value = input_text,
                        placeholder = "A69-1206-776\nA69-1303-17245",
                        width = "100%",
                        rows = 6),
          footer = tagList(
            modalButton("Cancel"),
            actionButton("tag_ok", "OK")
          )
        ))

      })

      tag_code_list <- reactiveVal(NULL)
      observeEvent(input$tag_ok, {

        removeModal()
        # extract the tag codes
        tag_code_list(str_split_1(input$tag_codes, pattern = "\\s+|,\\s*"))

      })

      # Data reactives ----

      data_query <- reactive({

        dfq <- pre_summary |>
          left_join(select(all_animals, catalognumber, collectioncode, scientificname),
                    by = c("relatedcatalogitem"="catalognumber",
                           "collectioncode"="collectioncode")) |>
          left_join(select(stations, station_name, latitude, longitude, depth),
                    by = c("station"="station_name")) |>
          left_join(species_tbl, by = "scientificname")

        dt_from <- as.Date(paste(input$year[1], "01", "01", sep = "-"))
        dt_to <- as.Date(paste(input$year[2], "12", "31", sep = "-"))
        dfq <- dfq |>
          filter(min_detectdate >= dt_from,
                 max_detectdate <= dt_to)

        if (!is.null(input$project)) {
          dfq <- dfq |>
            filter(collectioncode %in% !!input$project)
        }

        if (!is.null(input$locations)) {
          dfq <- dfq |>
            filter(station %in% !!input$locations)
        }

        if (!is.null(input$species)) {
          dfq <- dfq |>
            filter(commonname %in% !!input$species)
        }

        if (!is.null(tag_code_list())) {
          if (length(tag_code_list()) > 1) {
            dfq <- dfq |>
              filter(fieldnumber %in% !!tag_code_list())
          } else if (tag_code_list() != "") {
            dfq <- dfq |>
              filter(fieldnumber %in% !!tag_code_list())
          }
        }

        dfq
      })


      return(reactive(data_query()))

    }
  )
}
