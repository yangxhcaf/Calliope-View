library(shiny)
library(shinythemes)
library(leaflet)

fluidPage(theme = shinytheme('cerulean'),
          tags$a(href = "https://github.com/Danielslee51/Calliope-View", tags$b("Github")),
          tags$br(),
          tags$a(href = "https://icons8.com", tags$b("Icon pack by Icons8")),
          navbarPage(tags$b("Calliope-View"),
                     id='nav',
                     ####Tab 1: Includes the map, and key with features like filtering data####
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
                                             selectInput(inputId = "Sanimal_species", label = "Choose species:", choices = unique(Sanimal_data$`Common Name`), selected = NA, multiple = TRUE),
                                             sliderInput(inputId = "Sanimal_range", label = "Choose count range:", min = 1, max = max(Sanimal_data$Count), value = c(1,max(Sanimal_data$Count))),
                                             tags$b("Filter Drone Data"),
                                             checkboxInput(inputId = "only_neon", label = "Only include NEON"),
                                             selectInput(inputId = "Drone_site", label = "Filter by NEON Site", choices = unique(drone_data$neonSiteCode), selected = unique(drone_data$neonSiteCode), multiple = TRUE)
                                             ),
                                             
                                mainPanel(
                                  leafletOutput(outputId = "map", width = '100%', height = '600px')
                                  )
                              )
                     ),
                     ####Tab 2: Description of project + contributors####
                     tabPanel("About the Calliope Project",
                              tabsetPanel(
                                tabPanel("About",
                                         includeMarkdown('About Calliope.Rmd')),
                                tabPanel("Credits",
                                         includeMarkdown('Credits.Rmd')))
                              ),
                     ####Tab 3: Display contents of input file####
                     tabPanel("Input File",
                              tableOutput("contents")),
                     ####Tab 4: Display contents of drone data####
                     tabPanel("Drone Data",
                              tableOutput("Drone_table")),
                     ####Tab 4: Display contents of Sanimal data####
                     tabPanel("Sanimal Data",
                              tableOutput("Sanimal_table")),
                     ####Tab 5: Includes outputs to help with testing or troubleshooting####
                     tabPanel("For me (troubleshooting)",
                              textOutput("text_me"),
                              tableOutput("table_me"))
          )
)