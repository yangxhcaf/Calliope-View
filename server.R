# Shiny server
function(input, output, session) {
  
  ####INTERACTIVE MAP TAB####
  
  # Reactive value for layer control
  legend <- reactiveValues(group = c("Drone", "Field Sites", "Domains", "Flightpaths"))
  
  # Map
  output$map <- renderLeaflet({

    map <- (
    leaflet() %>%
      addProviderTiles(provider = providers$OpenStreetMap.Mapnik,
                       options = providerTileOptions(noWrap = TRUE)
                       ) %>%
      # Add measuring tool
      addMeasure(position = "topleft",
                 primaryLengthUnit = "kilometers",
                 primaryAreaUnit = "sqmeters",
                 activeColor = "#3D535D",
                 completedColor = "#7D4479"
                 ) %>%
      # Add layer control
      addLayersControl(overlayGroups = legend$group,
                       options = layersControlOptions(collapsed = FALSE)
                       ) %>%
      # Add option for fullscreen
      leaflet.extras::addFullscreenControl(pseudoFullscreen = TRUE) %>%
      # Markers for NEON field site locations
      addMarkers(data = FieldSite_point,
                 lng = FieldSite_point$siteLongitude,
                 lat = FieldSite_point$siteLatitude,
                 group = "Field Sites",
                 popup = paste0("<strong>Site Name: </strong>",
                                FieldSite_point$siteDescription, " (",
                                FieldSite_point$siteCode, ")",
                                "<br><strong>Region: </strong>",
                                FieldSite_point$domainName,
                                "<br><strong>State: </strong>",
                                FieldSite_point$stateName,
                                "<br><strong>Site Type: </strong>",
                                FieldSite_point$siteType),
                 clusterOptions = markerClusterOptions(),
                 label = paste0(FieldSite_point$siteDescription),
                 icon = NEON_icon
                 ) %>%
      # Polygons for NEON domains (green)
      addPolygons(data = domain_data,
                  weight = 2,
                  fillOpacity = '0.05',
                  group = "Domains",
                  popup = paste0(domain_data$DomainName),
                  color = "green"
                  ) %>%
      # Areas for NEON flight paths (purple)
      addPolygons(data = flight_data$geometry,
                  color = "purple",
                  group = "Flightpaths",
                  popup = paste0("<strong>Site: </strong><br>",
                                 flight_data$Site,
                                 "<br><strong>Domain: </strong>",
                                 domains[flight_data$DomainID,2],
                                 "<br><strong>Core/Relocatable: </strong>",
                                 flight_data$'Core.or.Relocatable',
                                 "<br><strong>Flight Priority: </strong>",
                                 flight_data$Priority,
                                 "<br><strong>Version: </strong>",
                                 flight_info$Version)
                  )
    )
    # Add polygon boundaries for field sites (blue)
    for (i in 1:10) {
      if (is.array(FieldSite_poly$coordinates[[i]])) {
        map <- map %>%
          addPolygons(lng = FieldSite_poly$coordinates[[i]][1,,1],
                      lat = FieldSite_poly$coordinates[[i]][1,,2],
                      group = "Field Sites",
                      popup = paste0("Boundaries for ",
                                     FieldSite_poly$siteDescription[i])
                      )
        } else {
        map <- map %>%
          addPolygons(lng = FieldSite_poly$coordinates[[i]][[1]][,1],
                      lat = FieldSite_poly$coordinates[[i]][[1]][,2],
                      group = "Field Sites",
                      popup = paste0("Boundaries for ",
                                     FieldSite_poly$siteDescription[i])
          )}
      }
      map
  })
    
  # Allow zooming in on Santa Rita Region, currenly disabled by hashtags in Ui
  observe({
    proxy <- leafletProxy("map")
    observeEvent(input$SR_center, proxy %>% setView(lng = -110.453707, lat = 31.681433, zoom = 9))
  })
  
  # Allow user to filter drone data
  Drone_filtered_NEON_only <- reactive({
    if (input$only_neon) {
      drone_data[(!(drone_data$neonSiteCode %in% NA)),]
    } else {
      drone_data
    }
  })
  Drone_filtered_NEON <- reactive({
    if (is.na(unique(drone_data$neonSiteCode)) & length(drone_data$neonSiteCode)==1) {
      Drone_filtered_NEON_only()
    } else {
    Drone_filtered_NEON_only() %>%
      dplyr::filter(Drone_filtered_NEON_only()$neonSiteCode %in% c(NA, input$Drone_site))
    }
  })
  
  # Display filtered Drone data on map
  observe({
    proxy <- leafletProxy("map")
    proxy %>%
      clearGroup(group = "Drone") %>%
      addMarkers(data = Drone_filtered_NEON(),
                 popup = paste0("<b>Date taken: </b>",
                                Drone_filtered_NEON()$yearTaken, "/", Drone_filtered_NEON()$monthTaken, "/", Drone_filtered_NEON()$dayTaken,
                                "<br><b>Altitude: </b>",
                                Drone_filtered_NEON()$altitude, " m",
                                "<br><b>NEON site (if applicable): </b>",
                                Drone_filtered_NEON()$neonSiteCode),
                 group = "Drone",
                 icon = drone_image_icon) #%>%
      # Added polygon drawer, but has no functionality at the moment (took out)
#      leaflet.extras::addDrawToolbar(targetGroup = "Drone",
#                                     polylineOptions = FALSE, rectangleOptions = FALSE, circleOptions = FALSE, markerOptions = FALSE, circleMarkerOptions = FALSE,
#                                     editOptions = leaflet.extras::editToolbarOptions())
  })
  
  # NEON: Step 1- Find/Download Data
  Product_ID_general <- reactive(req(gsub(pattern = " ", replacement = "", x = input$dpID_general)))
  Product_ID_specific <- reactive(req(gsub(pattern = " ", replacement = "", x = input$dpID_specific)))
  Field_Site_general <- reactive(req(
    if (input$location_NEON_general == "All (default)") {
      "all"
    } else {
      input$location_NEON_general
    })
    )
  Field_Site_specific <- reactive(req(input$location_NEON_specific))
  Package_type_general <- reactive(req(input$package_type_general))
  Package_type_specific <- reactive(req(input$package_type_specific))
  Date_specific_long <- reactive(req(as.character(input$date_NEON)))
  Date_specific_parts <- reactive(req(strsplit(Date_specific_long(), "-")[[1]]))
  Date_specific <- reactive(req(paste0(Date_specific_parts()[1], "-", Date_specific_parts()[2])))
  Folder_path_specific <- reactive(paste0("../NEON_", Field_Site_specific(), "_", Date_specific()))
  # Download NEON data: general
  observeEvent(input$download_NEON_general,
               zipsByProduct(dpID = Product_ID_general(), site = Field_Site_general(), package = Package_type_general(), check.size = FALSE, savepath = '..') &
                 sendSweetAlert(session, title = "File downloaded", text = "Check the directory containing 'Calliope View'. Go to step 2 to unzip files and make them more accesible.", type = 'success')
               )
  # Download NEON data: specific — creates a folder and adds files to folder
  observeEvent(input$download_NEON_specific,
               dir.create(path = Folder_path_specific()) &
                 getPackage(dpID = Product_ID_specific(), site_code = Field_Site_specific(), year_month = Date_specific(), package = Package_type_specific(), savepath = Folder_path_specific()) &
                 sendSweetAlert(session, title = "File downloaded", text = "Check the directory containing 'Calliope View'. Go to step 2 to unzip files and make them more accesible.", type = 'success')
               )
  # NEON: Step 2- Unzip/Join Downloads
  NEON_folder_path <- reactive(req(readDirectoryInput(session, 'NEON_unzip_folder')))
  NEON_file_name <- reactive(req(input$NEON_unzip_file))
  NEON_file_path <- reactive(req(paste0("../", NEON_file_name())))
  # Server function needed by directoryInput (https://github.com/wleepang/shiny-directory-input)
  observeEvent(ignoreNULL = TRUE,
    eventExpr = {input$NEON_unzip_folder},
    handlerExpr = {
      if (input$NEON_unzip_folder > 0) {
        # condition prevents handler execution on initial app launch, launch the directory selection dialog with initial path read from the widget
        path = choose.dir(default = readDirectoryInput(session, 'NEON_unzip_folder'))
        # update the widget value
        updateDirectoryInput(session, 'NEON_unzip_folder', value = path)}
      })
  # Unzip data: general/specific
  observeEvent(input$unzip_NEON_folder,
               stackByTable(filepath = NEON_folder_path(), folder = TRUE) &
                 sendSweetAlert(session, title = "File unzipped", text = "The outer appearance of the folder should be the same. On the inside, there should be a new folder called 'stackedFiles' which contains the datasets.", type = "success")
               )
  # Unzip data: manual
  observeEvent(input$unzip_NEON_file,
               stackByTable(filepath = NEON_file_path(), folder = FALSE) &
                 sendSweetAlert(session, title = "File unzipped", text = paste0("There should now be a new folder titled '", strsplit(NEON_file_name(), ".zip")[[1]][1], "' with all of the datasets."), type = "success")
               )
  
  ####INPUT FILE TAB####
  # Currently disabled by hashtags in Ui
  # Get info for input files (Point GEOJSON only!!)
  user_file_info <- reactive({
    input$user_input_file
  })
  user_file_name <- reactive({
    user_file_info()$name
  })
  user_file_read <- reactive({
    readOGR(user_file_info()$datapath)
  })
  # Display input file in "Input File" tab
  output$contents <- renderTable({
    if (is.null(user_file_info())) {
      return(NULL)
    }
    user_file_read()
  })
  # Add user file to map, create legend
  observeEvent(input$add_user_file, legend$group <- c(legend$group, user_file_name()))
  observeEvent(input$add_user_file,
               if (!is.null(input$user_input_file)) {
                 leafletProxy("map") %>% addMarkers(data = user_file_read(),
                                                    group = as.character(user_file_name())
                 ) %>%
                   addLayersControl(overlayGroups = c(legend$group, as.character(user_file_name())),
                                    options = layersControlOptions(collapsed = FALSE)) 
               }
               )
  
  ####DRONE DATA TAB####
  
  # Display data via table
  output$Drone_table <- renderTable(Drone_filtered_NEON())
  
  ####FOR ME TAB####
  
  #Text for troublshooting
  output$text_me <- renderText("Current directory: (this should be Calliope-View)")
  #Text for troublshooting 2
  output$text_me_two <- renderText(getwd())
  #Table for troubleshooting
  #output$table_me <- renderTable()
}