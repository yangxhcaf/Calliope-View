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
                                             #tags$b("Zoom to:"),
                                             #tags$br(),
                                             #actionButton(inputId = "SR_center", label = "Santa Rita Mountains", width = '70%'),
                                             #tags$hr(),
                                             #fileInput(inputId = "user_input_file", label = "Upload GeoJSON file: ", accept = ".json"),
                                             #actionButton("add_user_file", label = "Add file to map"),
                                             #tags$hr(),
                                             tags$h4("Filter Drone Data"),
                                             checkboxInput(inputId = "only_neon", label = "Only include NEON"),
                                             selectInput(inputId = "Drone_site", label = "Filter by NEON Site", choices = unique(drone_data$neonSiteCode)[!(unique(drone_data$neonSiteCode) %in% NA)], selected = unique(drone_data$neonSiteCode), multiple = TRUE),
                                             tags$hr(),
                                             tags$h4("Browse NEON Data:"),
                                             radioButtons(inputId = "NEON_choices", label = "Browsing method", choices = list("By Data Product— General" = "general", "By Data Product— Specific" = "specific")),
                                             tags$hr(),
                                             conditionalPanel("input.NEON_choices == 'general'",
                                                              includeMarkdown('Rmd/NEON_browsing_general.Rmd'),
                                                              textInput(inputId = "dpID_general", label = "Product ID"),
                                                              selectInput(inputId = "location_NEON_general", label = "Field Site", choices = c("All (default)", unique(FieldSite_point$siteCode)), selected = "All (default)"),
                                                              checkboxInput(inputId = "extra_options_general", label = "Show extra options"),
                                                              conditionalPanel("input.extra_options_general",
                                                                               selectInput(inputId = "package_type_general", label = "Package Type", choices = c("basic", "expanded"))),
                                                              actionButton(inputId = "download_NEON_general", label = "Download items")
                                                              ),
                                             conditionalPanel("input.NEON_choices == 'specific'",
                                                              includeMarkdown('Rmd/NEON_browsing_specific.Rmd'),
                                                              textInput(inputId = "dpID_specific", label = "Product ID"),
                                                              selectInput(inputId = "location_NEON_specific", label = "Field Site", choices = unique(FieldSite_point$siteCode)),
                                                              dateInput(inputId = "date_NEON", label = "Year-Month combination", format = "yyyy-mm", startview = "decade"),
                                                              checkboxInput(inputId = "extra_options_specific", label = "Show extra options"),
                                                              conditionalPanel("input.extra_options_specific",
                                                                               selectInput(inputId = "package_type_specific", label = "Package Type", choices = c("basic", "expanded"))),
                                                              actionButton(inputId = "download_NEON_specific", label = "Download items")
                                             )
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
                                         includeMarkdown('Rmd/About Calliope.Rmd')),
                                tabPanel("Credits",
                                         includeMarkdown('Rmd/Credits.Rmd')))
                              ),
                     ####Tab 3: Display contents of input file####
                     tabPanel("Input File",
                              tableOutput("contents")),
                     ####Tab 4: Display contents of drone data####
                     tabPanel("Drone Data",
                              tableOutput("Drone_table")),
                     ####Tab 5: Includes outputs to help with testing or troubleshooting####
                     tabPanel("For me (troubleshooting)",
                              textOutput("text_me"),
                              tableOutput("table_me"))
          )
)