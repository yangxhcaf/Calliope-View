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
                popup = paste0("<strong>Site Name: </strong>",
                              FieldSite_point$SiteName,
                              "<br><strong>Region: </strong>",
                              FieldSite_point$DomainName,
                              "<br><strong>State: </strong>",
                              FieldSite_point$Full_State,
                              "<br><strong>Host: </strong>",
                              FieldSite_point$SiteHost),
                clusterOptions = markerClusterOptions(),
                label = paste0(FieldSite_point$SiteName)
                ) %>%

      # Polygons for NEON domains (blue)
      addPolygons(data = domain_data,
                  weight=2,
                  fillOpacity = '0.05',
                  popup = paste0(domain_data$DomainName)
                  ) %>%
      # Areas for NEON flight paths (green)
      addPolygons(data = flight_data$geometry,
                  color = "green",
                  popup = paste0("<strong>Site: </strong><br>",
                                 flight_data$Site,
                                 "<br><strong>Domain: </strong>",
                                 domains[flight_data$DomainID,2],
                                 "<br><strong>Core/Relocatable: </strong>",
                                 flight_data$'Core or Relocatable',
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
    
    for (i in 1:10) {
      if (is.array(FieldSite_poly$coordinates[[i]])) {
        map <- map %>%
          addPolygons(lng = FieldSite_poly$coordinates[[i]][1,,1],
                      lat = FieldSite_poly$coordinates[[i]][1,,2],
                      color = "purple",
                      popup = paste0("Boundaries for ",
                                     FieldSite_poly$siteDescription[i]
                                     )
                      )
      } else {
        map <- map %>%
          addPolygons(lng = FieldSite_poly$coordinates[[i]][[1]][,1],
                      lat = FieldSite_poly$coordinates[[i]][[1]][,2],
                      color = "purple",
                      popup = paste0("Boundaries for ",
                                     FieldSite_poly$siteDescription[i]
                                     )
                     
          )}
    }
      map
    

  })
    
  # Allow zooming in on Santa Rita Region
  observe({
    proxy <- leafletProxy("map")
    if (input$SR_center) {
      proxy %>% setView(lng = -110.453707, lat = 31.681433, zoom = 9)
    }
  })
  # Allow user to filter Sanimal data
  Sanimal_filtered_data <- reactive({
    Sanimal_data %>%
      dplyr::filter(Sanimal_data$`Common Name` %in% input$Sanimal_species) %>%
      dplyr::filter(between(Count, left = input$Sanimal_range[1], right = input$Sanimal_range[2]))
  })
  # Display filtered Sanimal data on map
  observe({
    proxy <- leafletProxy("map")
    proxy %>%
      clearGroup(group = "Sanimal") %>%
      addMarkers(data = Sanimal_filtered_data(),
                 popup = paste0("<strong> Species:  </strong>",
                                Sanimal_filtered_data()$`Common Name`,
                                "<br><strong> Scientific Name: </strong>",
                                Sanimal_filtered_data()$`Scientific Name`,
                                "<br><strong> Count: </strong>",
                                Sanimal_filtered_data()$Count),
                 group = "Sanimal",
                 clusterOptions = markerClusterOptions())
  })
  #Allow user to filter drone data
  Drone_filtered_NEON <- reactive({
    if (input$only_neon) {
      drone_data[(!(drone_data$neonSiteCode %in% NA)),]
    } else {
      drone_data
    }
  })
  # Display filtered Drone data on map
  observe({
    proxy <- leafletProxy("map")
    proxy %>%
      clearGroup(group = "Drone") %>%
      addMarkers(data = Drone_filtered_NEON(),
                 popup = paste0("<b>Date: </b>",
                                Drone_filtered_NEON()$dateTaken,
                                "<br><b>Altitude: </b>",
                                Drone_filtered_NEON()$altitude, " m"),
                 group = "Drone")
  })
  
  ####INPUT FILE TAB####
  
  # Input files test
  user_file_info <- reactive({
    input$user_input_file
  })
  user_file_name <- reactive({
    user_file_info()$name
  })
  user_file_read <- reactive({
    readOGR(user_file_info()$datapath)
  })
  output$contents <- renderTable({
    if (is.null(user_file_info())) {
      return(NULL)
    }
    user_file_read()
  })
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

  
  ####SANIMAL DATA TAB####
  
  output$Sanimal_table <- renderTable(Sanimal_filtered_data())
  
  ####DRONE DATA TAB####
  
  output$Drone_table <- renderTable(Drone_filtered_NEON())
  
  ####FOR ME TAB####
  
  output$text_me <- renderText(
    paste0(is.null(input$user_input_file)
           )
    )
  #output$table_me <- renderTable(flight_frame)
}