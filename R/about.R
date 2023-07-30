
aboutUI <- function(id) {
  ns <- NS(id)
  fluidPage(
    tabPanel(
      "About",
      h2("About the PATH Database"),
      p("The goal of PATH is to facilitate a collaborative data exchange network of data owned by a variety of agencies and institutions curated by UC Davis. If you are interested in learning more about our database or sharing your telemetry data with us please reach out to path@ucdavis.edu or visit our website https://path.wfcb.ucdavis.edu/"),
      h2("About the PATH Shiny app"),
      p("This Shiny app was created so users could explore, filter, and download PATH data."),
      p("The Stations tab allows users to filter data by species, year, project and tag and visualize receiver locations. "),
      p("The Summary tab lets users filter and download metadata with summary detection data."),
      p("The Tag History tab allows users to track selected tagged fish movement between receivers."),
      p(" The Raw Detections tab directs users to links for downloading raw detection files that are to large to download on this app.")   
         
       
    )
  )
}

about <- function(input, output, session) {
  
}

 