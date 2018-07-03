library(shiny)
library(shinythemes)
library(leaflet)

fluidPage(theme = shinytheme("cerulean"),
          tags$a(href = "https://github.com/cyverse-gis/suas-metadata", tags$b("Github")),
          navbarPage(tags$b("Calliope"),
                     id='nav',
                     tabPanel("Interactive Map",
                              sidebarLayout(
                                sidebarPanel(width = 4,
                                             tags$b("Zoom to:"),
                                             tags$br(),
                                             actionButton(inputId = "SR_center", label = "Santa Rita Mountains", width = '70%'),
                                             tags$br(),
                                             tags$br(),
                                             fileInput(inputId = "user_input_file", label = "Upload GeoJSON file: ", accept = ".json"),
                                             actionButton("add_user_file", label = "Add file to map"),
                                             tags$br(),
                                             tags$br(),
                                             tags$b("Filter Sanimal Data"),
                                             selectInput(inputId = "Sanimal_species", label = "Choose species:", choices = unique(Sanimal_data$`Common Name`), selected = unique(Sanimal_data$`Common Name`), multiple = TRUE),
                                             sliderInput(inputId = "Sanimal_range", label = "Choose count range:", min = 1, max = max(Sanimal_data$Count), value = c(1,max(Sanimal_data$Count)))
                                             ),
                                             
                                mainPanel(
                                  leafletOutput(outputId = "map", width = '100%', height = '600px')
                                  )
                              )
                     ),
                     tabPanel("Potential Table",
                              "*Hoping to add table for datapoints*"),
                     tabPanel("About the Calliope Project",
                              "*Hoping to eventually add description of project*"),
                     tabPanel("Input File",
                              tableOutput("contents")),
                     tabPanel("Sanimal Data",
                              tableOutput("Sanimal_table")),
                     tabPanel("For me",
                              textOutput("text_me"),
                              tableOutput("table_me"))
                     
          )
)