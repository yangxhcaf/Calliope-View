# Shiny server
function(input, output, session) {
  
  ####INTERACTIVE MAP TAB####
  
  
  # Reactive value for layer control
  legend <- reactiveValues(group = "LiDAR")
  
  
  output$map <- renderLeaflet({
    
    basemap <- leaflet()
    
    map <- (
    basemap %>%
      addProviderTiles(provider = providers$OpenStreetMap.Mapnik,
                       options = providerTileOptions(noWrap = TRUE)
                       ) %>%
      # Add measuring tool
      addMeasure(primaryLengthUnit = "kilometers",
                 primaryAreaUnit = "sqmeters",
                 activeColor = "#3D535D",
                 completedColor = "#7D4479"
                 ) %>%
      # Add layer control
      addLayersControl(overlayGroups = legend$group,
                       options = layersControlOptions(collapsed = FALSE)
                       ) %>%
      # Markers for NEON field site locations
      addMarkers(data = FieldSite_point,
                 lng = FieldSite_point$siteLongitude,
                 lat = FieldSite_point$siteLatitude,
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
                  popup = paste0(domain_data$DomainName),
                  color = "green"
                  ) %>%
      # Areas for NEON flight paths (purple)
      addPolygons(data = flight_data$geometry,
                  color = "purple",
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
                  ) %>%
      # Markers for ARS flume locations (stream of water icon)
      addMarkers(data = ARS_Flume,
                 popup = paste0(ARS_Flume$WS_ID,
                                "<br>Elevation= ",
                                as.numeric(as.character(ARS_Flume$Elevation)),
                                " m"),
                 icon = flume_icon
                 ) %>%
      # Boundary for PAG 2011 LiDAR Township and Range Sections (red)
      addPolygons(data = PAG,
                  weight = 2,
                  group = "LiDAR",
                  color = "red",
                  popup = paste0("PAG 2011 LiDAR Township and Range Sections")
                  ) %>%
      # Boundary for Santa Rita Experimental Range (orange)
      addPolygons(data = SantaRita_Exp_Range,
                  weight = 3,
                  color = "orange",
                  popup = paste0("Santa Rita Experimental Range")
                  ) %>%
      # Markers for Santa Rita flux tower locations (tower icon)
      addMarkers(data = SantaRita_Flux_Tower,
                 popup = paste0(SantaRita_Flux_Tower$Name),
                 icon = tower_icon,
                 clusterOptions = NULL #markerClusterOptions()
                 ) %>%
      # Boundaries for Walnut Gulch subwatersheds
      addPolygons(data = Walnut_Gulch,
                  weight=3,
                  color = "yellow",
                  popup = paste0("Walnut Gulch Subwatersheds")
                  ) %>%
      # Markers for Walnut Gulch flux tower locations (nut icon)
      addMarkers(data = WalnutGulch_Flux_Tower,
                 popup = paste0(WalnutGulch_Flux_Tower$Name),
                 icon = nut_icon,
                 clusterOptions = NULL #markerClusterOptions()
                 ) %>%
      # Area around Walnuyt Gulch towers (brown)
      addPolygons(data = WalnutGulch_Flux_Tower_400m_Buffer,
                  weight = 2,
                  color = "brown",
                  popup = paste0(WalnutGulch_Flux_Tower_400m_Buffer$Name)
                  )
    )
    # Add polygon boundaries for field sites (blue)
    for (i in 1:10) {
      if (is.array(FieldSite_poly$coordinates[[i]])) {
        map <- map %>%
          addPolygons(lng = FieldSite_poly$coordinates[[i]][1,,1],
                      lat = FieldSite_poly$coordinates[[i]][1,,2],
                      popup = paste0("Boundaries for ",
                                     FieldSite_poly$siteDescription[i])
                      )}
      else {
        map <- map %>%
          addPolygons(lng = FieldSite_poly$coordinates[[i]][[1]][,1],
                      lat = FieldSite_poly$coordinates[[i]][[1]][,2],
                      popup = paste0("Boundaries for ",
                                     FieldSite_poly$siteDescription[i])
          )}
    }
      map

  })
    
  # Allow zooming in on Santa Rita Region
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
    if (is.na(unique(drone_data$neonSiteCode))) {
      Drone_filtered_NEON_only()
    } else {
    Drone_filtered_NEON_only() %>%
      dplyr::filter(Drone_filtered_NEON_only()$neonSiteCode %in% input$Drone_site)
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
                 icon = drone_image_icon) %>%
      # Added polygon drawer, but has no functionality at the moment
      leaflet.extras::addDrawToolbar(targetGroup = "Drone",
                                     polylineOptions = FALSE, rectangleOptions = FALSE, circleOptions = FALSE, markerOptions = FALSE, circleMarkerOptions = FALSE,
                                     editOptions = leaflet.extras::editToolbarOptions())
  })
  
  # Browse NEON data: general
  Product_ID_general <- reactive(input$dpID_general)
  Product_ID_specific <- reactive(input$dpID_specific)
  Field_Site_general <- reactive(
    if (input$location_NEON_general == "All (default)") {
      "all"
    } else {
      input$location_NEON_general
    })
  Field_Site_specific <- reactive(input$location_NEON_specific)
  Date_specific_long <- reactive(as.character(input$date_NEON))
  Date_specific_parts <- reactive(strsplit(Date_specific_long(), "-")[[1]])
  Date_specific <- reactive(paste0(Date_specific_parts()[1], "-", Date_specific_parts()[2]))
  # Download NEON data: general
  observeEvent(input$download_NEON_general,
               if (TRUE) {
                 zipsByProduct(dpID = Product_ID_general(), site = Field_Site_general(), check.size = FALSE, savepath = '..')
               }
               )
  # Download NEON data: specific
  observeEvent(input$download_NEON_specific,
               if (!is.null(Product_ID_specific()) & !is.null(Field_Site_specific()) & !is.null(Date_specific())) {
                 getPackage(dpID = Product_ID_specific(), site_code = Field_Site_specific(), year_month = Date_specific(), savepath = '..')
                 }
               )
  
  ####INPUT FILE TAB####
  
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
  output$text_me <- renderText(Date_specific())
  
  #Table for troubleshooting
  #output$table_me <- renderTable()
}