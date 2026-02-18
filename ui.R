fluidPage(
  theme = bs_theme(bootswatch = "cerulean"), # pick a theme at https://bootswatch.com/
  titlePanel("Pacific Aquatic Telemetry Hub (PATH) Database Tool"),

  sidebarLayout(
    sidebarPanel(width = 3,
                 sharedUI("shared")
    ),
   mainPanel(width = 9,
             tabsetPanel(
               id = "tabs",
      #          tabPanel("About",
       #                  wellPanel( 
        #                 h2("About the Pacific Aquatic Telemetry Hub (PATH)", align = "center"),
         #                h4("The PATH database contains acoustic biotelemetry records for multiple fish species and telemetry technologies. 
          #      The goal of PATH is to facilitate a collaborative data exchange network of data owned by a variety of agencies and institutions curated by UC Davis. 
           #     Once researchers send PATH database managers their data they will be run through a quality assurance and control (QA/QC) process and the final product
            #    will be stored in a file on this data repository accessible to the researcher who submitted it through a secure link.")
             #   )
            #  ),     
                         
                tabPanel("About", aboutUI("about")),
                tabPanel("Tag History", tagUI("tag")),
                tabPanel("Stations", stationsUI("stations")),
                tabPanel("Summary", summaryUI("summary"))
              )
    )

  )
)
