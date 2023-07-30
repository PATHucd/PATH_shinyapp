
raw_detectionsUI <- function(id) {
  ns <- NS(id)
  fluidPage(
    tabPanel(
      "Raw Detections",
      h2("Links to Raw Detections by species common name"),
      p("https://path-fishdetections.wfcb.ucdavis.edu/green_sturgeon"),
      p("https://path-fishdetections.wfcb.ucdavis.edu/white_sturgeon"),
      p("https://path-fishdetections.wfcb.ucdavis.edu/chinook_salmon"),
      p("https://path-fishdetections.wfcb.ucdavis.edu/steelhead"),
      p("https://path-fishdetections.wfcb.ucdavis.edu/rainbow_trout"),
      p("https://path-fishdetections.wfcb.ucdavis.edu/largemouth_bass"),
      p("https://path-fishdetections.wfcb.ucdavis.edu/smallmouth_bass"),
      p("https://path-fishdetections.wfcb.ucdavis.edu/spotted_bass"),
      p("https://path-fishdetections.wfcb.ucdavis.edu/striped_bass"),
      p("https://path-fishdetections.wfcb.ucdavis.edu/sacramento_pikeminnow"),
      p("https://path-fishdetections.wfcb.ucdavis.edu/white_catfish"),
      p("https://path-fishdetections.wfcb.ucdavis.edu/channel_catfish"),
      p("https://path-fishdetections.wfcb.ucdavis.edu/sevengill_shark")
      
      
    )
  )
}

raw_detections <- function(input, output, session) {
  
}

