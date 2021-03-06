fluidPage(theme = shinytheme('cerulean'),
          tags$a(href = "https://github.com/Danielslee51/Calliope-View", tags$b("Github")),
          " | ",
          tags$a(href = "https://icons8.com", tags$b("Icon pack by Icons8")),
          title = ("Calliope View"),
          navbarPage(tags$b("Calliope-View"),
                     ####Tab 1: Includes the map, and key with features like filtering data####
                     tabPanel("Interactive Map",
                              dropdown(right = FALSE, status = "primary", size = "sm", icon = icon("info-circle"), width = "45vw",
                                       selectInput(inputId = "NEONsite_zoom", label = "Site info:", choices = FieldSite_abbs),
                                       tags$b("Name and type"),
                                       verbatimTextOutput(outputId = "dropdown_site", placeholder = TRUE),
                                       tags$b("Number of data products available"),
                                       verbatimTextOutput(outputId = "dataproduct_number", placeholder = TRUE),
                                       actionButton(inputId = "addsublocs", label = "Add sub-locations for site"),
                                       shiny::actionButton(inputId = "zoomtosite", label = "Zoom to site")
                              ),
                              sidebarLayout(
                                sidebarPanel(width = 6,
                                             tabsetPanel(
                                               #### — NEON ####
                                               tabPanel(tags$h5("NEON Data"),
                                                 tabsetPanel(
                                                   #### —— STEP 1: Find Data####
                                                   tabPanel("Data",
                                                            radioButtons(inputId = "NEON_browsing_type", label = "Browsing method", choices = list("Start with Site" = "site", "Start with Product" = "product"), inline = TRUE),
                                                            conditionalPanel("input.NEON_browsing_type == 'site'",
                                                                             includeMarkdown('Rmd/NEON_browsing_site.Rmd'),
                                                                             radioButtons(inputId = "NEONbrowsingstep_site", label = NULL, choices = list("Find Product" = "list", "Get Availability" = "single"), inline = TRUE),
                                                                             conditionalPanel("input.NEONbrowsingstep_site == 'list'",
                                                                                              selectInput(inputId = "NEONsite_site", label = "Select site:", choices = FieldSite_abbs),
                                                                                              checkboxInput(inputId = "showmorefilters_site", label = "Show filters"),
                                                                                              conditionalPanel("input.showmorefilters_site",
                                                                                                               uiOutput(outputId = "ui_selectkeywords_site"),
                                                                                                               selectInput(inputId = "selectproducttype_site", label = "Product Type", choices = NEON_datatypes, multiple = TRUE)),
                                                                                              dataTableOutput(outputId = "NEONproductoptions_site")
                                                                             ),
                                                                             conditionalPanel("input.NEONbrowsingstep_site == 'single'",
                                                                                              tags$b("Site:"),
                                                                                              verbatimTextOutput(outputId = "NEONproductsite_site", placeholder = TRUE),
                                                                                              textInput(inputId = "NEONproductID_site", label = "Product ID"),
                                                                                              tags$b("Name:"),
                                                                                              verbatimTextOutput(outputId = "NEONproductname_site", placeholder = TRUE),
                                                                                              tags$b("Description:"),
                                                                                              verbatimTextOutput(outputId = "NEONproductdesc_site", placeholder = TRUE),
                                                                                              checkboxInput(inputId = "showmoreinfo_site", label = "Show more info"),
                                                                                              conditionalPanel("input.showmoreinfo_site",
                                                                                                               tags$b("Product Design:"),
                                                                                                               verbatimTextOutput(outputId = "NEONproductdesign_site", placeholder = TRUE),
                                                                                                               tags$b("Notes (if any):"),
                                                                                                               verbatimTextOutput(outputId = "NEONproductnotes_site", placeholder = TRUE)
                                                                                              ),
                                                                                              tags$b("Available dates at this site:"),
                                                                                              verbatimTextOutput(outputId = "NEONproductdates_site", placeholder = TRUE),
                                                                                              checkboxInput(inputId = "showURL_site", label = "Show Urls"),
                                                                                              conditionalPanel("input.showURL_site",
                                                                                                               tags$b("Available Urls:"),
                                                                                                               verbatimTextOutput("NEONproductURL_site", placeholder = TRUE)
                                                                                              )
                                                                             )
                                                            ),
                                                            conditionalPanel("input.NEON_browsing_type == 'product'",
                                                                             includeMarkdown('Rmd/NEON_browsing_product.Rmd'),
                                                                             radioButtons(inputId = "NEON_browsing_step_product", label = NULL, choices = list("Find Product" = "list", "Get Availability" = "single"), inline = TRUE),
                                                                             conditionalPanel("input.NEON_browsing_step_product == 'list'",
                                                                                              checkboxInput(inputId = "showmorefilters_product", label = "Show filters"),
                                                                                              conditionalPanel("input.showmorefilters_product",
                                                                                                               uiOutput(outputId = "ui_selectkeywords_product"),
                                                                                                               selectInput(inputId = "selectproducttype_product", label = "Product Type", choices = NEON_datatypes, multiple = TRUE)
                                                                                              ),
                                                                                              dataTableOutput(outputId = "NEON_product_options")
                                                                             ),
                                                                             conditionalPanel("input.NEON_browsing_step_product == 'single'",
                                                                                              textInput(inputId = "NEONproductID_product", label = "Product ID"),
                                                                                              tags$b("Name:"),
                                                                                              verbatimTextOutput(outputId = "NEONproductname_product", placeholder = TRUE),
                                                                                              tags$b("Description:"),
                                                                                              verbatimTextOutput(outputId = "NEONproductdesc_product", placeholder = TRUE),  
                                                                                              checkboxInput(inputId = "showmoreinfo_product", label = "Show more info"),
                                                                                              conditionalPanel("input.showmoreinfo_product",
                                                                                                               tags$b("Product Design:"),
                                                                                                               verbatimTextOutput(outputId = "NEONproductdesign_product", placeholder = TRUE),
                                                                                                               tags$b("Notes: (if any)"),
                                                                                                               verbatimTextOutput(outputId = "NEONproductnotes_product", placeholder = TRUE)
                                                                                              ),
                                                                                              uiOutput(outputId = "ui_selectsite"),
                                                                                              tags$b("Available dates:"),
                                                                                              verbatimTextOutput(outputId = "NEONproductdates_product", placeholder = TRUE),
                                                                                              checkboxInput(inputId = "showURL_product", label = "Show Urls"),
                                                                                              conditionalPanel("input.showURL_product",
                                                                                                               tags$b("Available Urls:"),
                                                                                                               verbatimTextOutput("NEONproductURL_product", placeholder = TRUE)
                                                                                              )
                                                                             )
                                                            )
                                                   ),
                                                   #### —— STEP 2: Download Data####
                                                   tabPanel("Download",
                                                            radioButtons(inputId = "NEON_download_type", label = "Download method", choices = list("By Data Product— General" = "general", "By Data Product— Specific" = "specific", "By Data Product— AOP" = "AOP","By Data Product— Manual" = "manual"), inline = TRUE),
                                                            conditionalPanel("input.NEON_download_type == 'general'",
                                                                             includeMarkdown('Rmd/NEON_download_general.Rmd'),
                                                                             textInput(inputId = "dpID_general", label = "Product ID"),
                                                                             selectInput(inputId = "location_NEON_general", label = "Field Site", choices = c("All (default)", unique(FieldSite_point$siteCode)), selected = "All (default)"),
                                                                             checkboxInput(inputId = "extra_options_general", label = "Show extra options"),
                                                                             conditionalPanel("input.extra_options_general",
                                                                                              selectInput(inputId = "package_type_general", label = "Package Type", choices = c("basic", "expanded"))),
                                                                             includeMarkdown('Rmd/NEON_download_message.Rmd'),
                                                                             actionButton(inputId = "download_NEON_general", label = "Download items")
                                                            ),
                                                            conditionalPanel("input.NEON_download_type == 'specific'",
                                                                             includeMarkdown('Rmd/NEON_download_specific.Rmd'),
                                                                             textInput(inputId = "dpID_specific", label = "Product ID"),
                                                                             selectInput(inputId = "location_NEON_specific", label = "Field Site", choices = unique(FieldSite_point$siteCode)),
                                                                             airMonthpickerInput(inputId = "date_NEON", label = "Year-Month combination"),
                                                                             checkboxInput(inputId = "extra_options_specific", label = "Show extra options"),
                                                                             conditionalPanel("input.extra_options_specific",
                                                                                              selectInput(inputId = "package_type_specific", label = "Package Type", choices = c("basic", "expanded"))),
                                                                             includeMarkdown('Rmd/NEON_download_message.Rmd'),
                                                                             actionButton(inputId = "download_NEON_specific", label = "Download items")
                                                            ),
                                                            conditionalPanel("input.NEON_download_type == 'AOP'",
                                                                             includeMarkdown('Rmd/NEON_download_AOP.Rmd'),
                                                                             textInput(inputId = "dpID_AOP", label = "Product ID"),
                                                                             tags$b("Is AOP?"),
                                                                             verbatimTextOutput(outputId = "check_AOP", placeholder = TRUE),
                                                                             selectInput(inputId = "location_NEON_AOP", label = "Field Site", choices = FieldSite_abbs),
                                                                             airYearpickerInput(inputId = "year_AOP", label = "Year"),
                                                                             checkboxInput(inputId = "AOP_size", label = "Calculate download size"),
                                                                             conditionalPanel("input.AOP_size",
                                                                                              actionLink(inputId = "get_AOP_size", label = "Calculate size"),
                                                                                              verbatimTextOutput(outputId = "AOP_size", placeholder = TRUE)),
                                                                             shiny::actionButton(inputId = "download_NEON_AOP", label = "Download items")
                                                            ),
                                                            conditionalPanel("input.NEON_download_type == 'manual'",
                                                                             includeMarkdown('Rmd/NEON_download_manual.Rmd')
                                                            )
                                                   ),
                                                   #### —— STEP 3: Unzip/Join Downloads ####
                                                   tabPanel("Unzip/Join",
                                                            includeMarkdown('Rmd/NEON_unzip.Rmd'),
                                                            radioButtons(inputId = "NEON_unzip_type", label = "Method of browsing (from step 1)", choices = list("By Data Product— General/Specific" = "general/specific", "By Data Product— Manual" = "manual")),
                                                            tags$hr(),
                                                            conditionalPanel("input.NEON_unzip_type == 'general/specific'",
                                                                             includeMarkdown('Rmd/NEON_unzip_general:specific.Rmd'),
                                                                             directoryInput('NEON_unzip_folder', label = 'Select the directory', value = '..'),
                                                                             actionButton(inputId = "unzip_NEON_folder", label = "Unzip/join folder")
                                                            ),
                                                            conditionalPanel("input.NEON_unzip_type == 'manual'",
                                                                             includeMarkdown('Rmd/NEON_unzip_manual.Rmd'),
                                                                             selectInput(inputId = 'NEON_unzip_file', label = "Choose .zip file", choices = list.files(path = '..', pattern = ".zip")),
                                                                             actionButton(inputId = "unzip_NEON_file", label = "Unzip/join file")
                                                            )
                                                   )
                                                 )
                                               ),
                                               #### — DRONE ####
                                               tabPanel(tags$h5("Drone Data"),
                                                        tabsetPanel(
                                                          #### —— Access data ####
                                                          tabPanel("Access drone data",
                                                                   textInput(inputId = "drone_username", label = "Username", placeholder = "guest"),
                                                                   passwordInput(inputId = "drone_password", label = "Password", placeholder = "guest"),
                                                                   actionButton(inputId = "drone_login", label = "Pull data")),
                                                          #### —— Filter Data ####
                                                          tabPanel("Filter data",
                                                                   checkboxInput(inputId = "only_neon", label = "Only include NEON"),
                                                                   selectInput(inputId = "drone_site", label = "Filter by NEON Site", choices = unique(drone_data$neonSiteCode)[!(unique(drone_data$neonSiteCode) %in% NA)], selected = unique(drone_data$neonSiteCode), multiple = TRUE)
                                                                   )
                                                        )
                                                 ),
                                               #### — MAP FEATURES ####
                                               tabPanel(tags$h5("Filter Map Features"),
                                                 radioButtons(inputId = "map_features", label = "Map feature:", choices = list("Field Sites"= "fieldsites", "Domains" = "domains", "Flightpaths" = "flightpath")),
                                                 conditionalPanel("input.map_features == 'fieldsites'",
                                                                  selectInput(inputId = "fieldsite_type", label = "Site Type:", choices = c("CORE", "RELOCATABLE"), selected = c("CORE", "RELOCATABLE"), multiple = TRUE),
                                                                  selectInput(inputId = "fieldsite_habitat", label = "Site Habitat", choices = c("Terrestrial", "Aquatic"), selected = c("Terrestrial", "Aquatic"), multiple = TRUE),
                                                                  pickerInput(inputId = "fieldsite_sublocs", label = "Add sub-locations to sites", choices = FieldSite_abbs, multiple = TRUE,
                                                                              options = list(`actions-box` = TRUE, `live-search` = TRUE, title = "Select sub-locations to include:", `multiple-separator` = ", ")),
                                                                  checkboxInput(inputId = "sublocs_key", label = "Show map key"),
                                                                  conditionalPanel("input.sublocs_key",
                                                                                   tabsetPanel(
                                                                                     tabPanel("Terrestrial",
                                                                                              tags$b("Hover over the checkbox to see more info:"),
                                                                                              materialSwitch(inputId = "sublocs_tes_selectall", label = "All", value = TRUE, status = "info"),
                                                                                              checkboxInput(inputId = "sublocs_baseplot", label = HTML("<img src='https://www.neonscience.org/sites/all/themes/neon/img/fieldsiteicons/distributedBaseplot.png' width=20><small> Distributed Base Plot</small>"), value = TRUE),
                                                                                              bsTooltip(id = "sublocs_baseplot", title = baseplot_text, placement = "top"),
                                                                                              checkboxInput(inputId = "sublocs_birdgrid", label = HTML("<img src='https://www.neonscience.org/sites/all/themes/neon/img/fieldsiteicons/birdGrid.png' width=20><small> Distributed Bird Grid</small>"), value = TRUE),
                                                                                              bsTooltip(id = "sublocs_birdgrid", title = birdgrid_text, placement = "top"),
                                                                                              checkboxInput(inputId = "sublocs_mammalgrid", label = HTML("<img src='https://www.neonscience.org/sites/all/themes/neon/img/fieldsiteicons/mammal.png' width=20><small> Distributed Mammal Grid</small>"), value = TRUE),
                                                                                              bsTooltip(id = "sublocs_mammalgrid", title = "", placement = "top"),
                                                                                              checkboxInput(inputId = "sublocs_mosquitoplot", label = HTML("<img src='https://www.neonscience.org/sites/all/themes/neon/img/fieldsiteicons/mosquito.png' width=20><small> Distributed Mosquito Plot</small>"), value = TRUE),
                                                                                              bsTooltip(id = "sublocs_mosquitoplot", title = mosquitoplot_text, placement = "top"),
                                                                                              checkboxInput(inputId = "sublocs_tickplot", label = HTML("<img src='https://www.neonscience.org/sites/all/themes/neon/img/fieldsiteicons/tick.png' width=20><small> Distributed Tick Plot</small>"), value = TRUE),
                                                                                              bsTooltip(id = "sublocs_tickplot", title = "", placement = "top"),
                                                                                              checkboxInput(inputId = "sublocs_phenologyplot", label = HTML("<img src='https://www.neonscience.org/sites/all/themes/neon/img/fieldsiteicons/phenology.png' width=20><small> Tower Phenology Plot</small>"), value = TRUE),
                                                                                              bsTooltip(id = "sublocs_phenologyplot", title = phenologyplot_text, placement = "top"))))),
                                                 conditionalPanel("input.map_features == 'domains'",
                                                                  pickerInput(inputId = "fieldsite_domain", label = "Domains:", choices = domains$Domain, selected = domains$Domain, multiple = TRUE,
                                                                              options = list(`actions-box` = TRUE, `live-search` = TRUE, title = "Select Domains to include:", `selected-text-format`= "static"))),
                                                 conditionalPanel("input.map_features == 'flightpath'",
                                                                  selectInput(inputId = "flightpath_year", label = "Year", choices = c(2016, 2017), selected = c(2016, 2017), multiple = TRUE))
                                               )
                                             )
                                ),
                                mainPanel(width = 6,
                                          leafletOutput(outputId = "map", width = 'auto', height = '85vh')
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
                     #### Tab 3: Description of NEON ####
                     tabPanel("About NEON",
                              navlistPanel(well = FALSE, widths = c(2,10),
                                           tabPanel("Objective",
                                                    includeMarkdown('Rmd/NEON_info_about.Rmd')),
                                           tabPanel("Field Site Selection",
                                                    includeMarkdown('Rmd/NEON_info_site_selection.Rmd')),
                                           tabPanel("Field Site Types",
                                                    includeMarkdown('Rmd/NEON_info_site_types.Rmd'))
                              )),
                     ####Tab 4: Display contents of drone data####
                     tabPanel("Drone Data",
                              tableOutput("Drone_table")),
                     ####Tab 5: Includes outputs to help with testing or troubleshooting####
                     tabPanel("For me (troubleshooting)",
                              textOutput("text_me"),
                              textOutput("text_me_two"),
                              dataTableOutput("table_me"))
          )
)