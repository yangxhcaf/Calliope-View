library(ggplot2)
library(leaflet)
library(dplyr)
library(tidyr)
library(jsonlite)
library(curl)
library(lubridate)
library(sf)
library(rgdal)
library(shinyjs)

####—DATA RETRIEVAL####


## Retrieve data from NEON Field Sites in JSON format
FieldSite_JSON <- fromJSON('NEON_Field_Sites.json')
# Create a data frame usaing cbind()
FieldSite_data <- cbind(FieldSite_JSON$features$properties,FieldSite_JSON$features$geometry)

## Retrive data from NEON Domains in JSON format
domains <- fromJSON('NEON_Domains.json')
# Retrieve just the DomainID and Domain Name
domains <- cbind("DomainID" = domains$features$properties$DomainID,"Domain"=domains$features$properties$DomainName)
# Remove Duplicates, make data frame
domains <- as.data.frame(unique(domains))
# Retrieve geometry data using st_read()
domain_data <- st_read('NEON_Domains.json')

## Retrieve info for NEON flightpaths
# Get human info about flightpaths
domain_table <- data.frame("Abb"=c("BART","HARV","BLAN","SCBI","SERC","DSNY","JERC","OSBS","STEI-CHEQ","STEI-TREE","UNDE","KONZ-KONA","GRSM","MLBS","ORNL","DELA","LENO","TALL","DCFS-WOOD","NOGP","CLBJ","OAES"),"Site"=c("Bartlett Experimental Forest North-South flight box", "Harvard Forest flight box","Blandy Experimental Farm flight box","Smithsonian Conservation Biology Institute flight box","Smithsonian Ecological Research Center flight box","Disney Wilderness Preserve flight box","Jones Ecological Research Center Priority 1 flight box","Ordway-Swisher Biological Station Priority 1 flight box","Chequamegon-Nicolet National Forest flight box","Steigerwaldt-Treehaven Priority 2 flight box","UNDERC flight box","Konza Prairie Biological Station and KONA agricultural site flight box","Great Smoky Mountains National Park priority 2 flight box","Mountain Lake Biological Station flight box","Oak Ridge National Laboratory flight box","Dead Lake flight box","Lenoir Landing flight box","Talladega National Forest flight box","Woodworth and Dakota Coteau Field School flight box","Northern Great Plains flight box","LBJ Grasslands flight box","Klemme Range Research Station flight box"))
CR_table <- data.frame("Abb"=c(as.character("C"),as.character("R")),"Actual"=c(as.character("Core"),as.character("Relocatable")))
# filesnames needed for loopz
flight_filenames_all <- Sys.glob('Flightdata/Flight_boundaries_2016/D*')
flight_filenames <- Sys.glob('Flightdata/Flight_boundaries_2016/D*.geojson')
# loop to combine files
flight_info <- data.frame()
for (file in flight_filenames_all) {
  parts <- strsplit(file, "_")
  #EX: "Flightdata/Flight_boundaries_2016/D01_BART_R1_P1_v1.geojson"
  name_part <- strsplit(file, "/")[[1]][3]
  # D01_BART_R1_P1_v1.geojson
  domain_part <- strsplit(parts[[1]][3],"D")[[1]][2]
  # 1
  site_part <- parts[[1]][4]
  #BART
  RC_part_type <- strsplit(parts[[1]][5],"")[[1]][1]
  # R
  RC_part_num <- strsplit(parts[[1]][5],"")[[1]][2]
  # 1
  priority_part <- strsplit(parts[[1]][6],"")[[1]][2]
  # 1
  version_part <- strsplit(parts[[1]][7],"")[[1]][2]
  # 1
  file_info <- cbind("Name"=name_part,"DomainID"=domain_part,"Site"=as.character(domain_table$Site[domain_table$Abb %in% site_part]),"Core or Relocatable"=paste0(CR_table[grep(RC_part_type,CR_table$Abb),2]," #",RC_part_num),"Priority"=priority_part,"Version"=version_part)
  flight_info <- rbind(flight_info, file_info)
}
flight_info$DomainID <- as.numeric(as.character(flight_info$DomainID))
# Get geometries for flightpaths
flight_geo <- st_read(flight_filenames[1])
flight_geo <- flight_geo[names(flight_geo) %in% "geometry"]
for (file in flight_filenames[-1]) {
  file_geo <- st_read(file)
  file_geo <- file_geo[names(file_geo) %in% "geometry"]
  flight_geo <- rbind(flight_geo,file_geo)
}
# Final data table
flight_data <- data.frame(flight_info, flight_geo)

## Retrieve data from Santa Rita range
ARS_Flume <- st_read('Walnut_Gulch__Santa_Rita_Experimental_Range/ARS_Flume.geojson')
PAG <- st_read('Walnut_Gulch__Santa_Rita_Experimental_Range/PAG_2011_LiDAR_Township_and_Range_Sections.geojson')
SantaRita_Exp_Range <- st_read('Walnut_Gulch__Santa_Rita_Experimental_Range/Santa_Rita_Experimental_Range_Boundary.geojson')
SantaRita_Flux_Tower <- st_read('Walnut_Gulch__Santa_Rita_Experimental_Range/SantaRita_Flux_Tower_Locations.geojson')
Walnut_Gulch <- st_read('Walnut_Gulch__Santa_Rita_Experimental_Range/Walnut_Gulch_Subwatersheds.geojson')
WalnutGulch_Flux_Tower <- st_read('Walnut_Gulch__Santa_Rita_Experimental_Range/WG_Flux_Tower_Locations.geojson')
WalnutGulch_Flux_Tower_400m_Buffer <- st_read('Walnut_Gulch__Santa_Rita_Experimental_Range/WG_Flux_Towers_Locations_400m_Buffer_Square.geojson')

## Retrieve animal images from Sanimal JSON
Sanimal_JSON <- fromJSON('http://128.196.142.26:9200/metadata/_search?size=5000')
Sanimal_species <- Sanimal_JSON$hits$hits$`_source`$imageMetadata$speciesEntries
Sanimal_position <- Sanimal_JSON$hits$hits$`_source`$imageMetadata$location$position
# Extract Lat/Long values from Sanimal position coordinates
Latitude <- data.frame()
for (i in 1:length(Sanimal_species)) {
  Latitude <- rbind(Latitude, data.frame("Latitude" = strsplit(Sanimal_position, ", ")[[i]][1]))
}
Longitude <-data.frame()
for (i in 1:length(Sanimal_species)) {
  Longitude <- rbind(Longitude, data.frame("Longitude" = strsplit(Sanimal_position, ", ")[[i]][2]))
}
# Extract species data (common/sientific name, count) from species list
Sanimal_commonname <- data.frame()
Sanimal_scientificname <- data.frame()
Sanimal_count <- data.frame()
for (i in 1:length(Sanimal_species)) {
  Sanimal_commonname <- rbind(Sanimal_commonname, data.frame("Common_name" = Sanimal_species[[i]]$species$commonName))
}
for (i in 1:length(Sanimal_species)) {
  Sanimal_scientificname <- rbind(Sanimal_scientificname, data.frame("Scientific_name" = Sanimal_species[[i]]$species$scientificName))
}
for (i in 1:length(Sanimal_species)) {
  Sanimal_count <- rbind(Sanimal_count, data.frame("Count" = Sanimal_species[[i]]$count))
}
# Create final data frame
Sanimal_data <- as.data.frame(cbind("took" = Sanimal_JSON$took,
                                    #"StoragePath" = Sanimal_JSON$hits$hits$`_source`$storagePath,
                                    "Elevation" = Sanimal_JSON$hits$hits$`_source`$imageMetadata$location$elevation,
                                    "Latitude" = as.numeric(as.character(Latitude$Latitude)),
                                    "Longitude" = as.numeric(as.character(Longitude$Longitude)),
                                    "Common Name" = as.character(Sanimal_commonname$Common_name),
                                    "Scientific Name" = as.character(Sanimal_scientificname$Scientific_name),
                                    "Count" = Sanimal_count$Count
                                    ))
# Edit certain columns, delete repeats
Sanimal_data$Longitude <- as.numeric(as.character(Sanimal_data$Longitude))
Sanimal_data$Latitude <- as.numeric(as.character(Sanimal_data$Latitude))
Sanimal_data$`Common Name` <- as.character(Sanimal_data$`Common Name`)
Sanimal_data$`Scientific Name` <- as.character(Sanimal_data$`Scientific Name`)
Sanimal_data$Count <- as.numeric(as.character(Sanimal_data$Count))
Sanimal_data <- unique(Sanimal_data)

# Shiny server
function(input, output, session) {
  points_field <- cbind(FieldSite_data$Longitude,FieldSite_data$Latitude)
  
  ####—INTERACTIVE MAP TAB####
  
  #icons
  nut_icon <- makeIcon(iconUrl = "https://png.icons8.com/color/48/000000/nut.png",
                       iconWidth = 30, iconHeight = 30,
                       iconAnchorX = 0, iconAnchorY = 0)
  tower_icon <- makeIcon(iconUrl = "https://png.icons8.com/color/48/000000/water-tower.png",
                         iconWidth = 30, iconHeight = 30,
                         iconAnchorX = 0, iconAnchorY = 0)
  flume_icon <- makeIcon(iconUrl = "https://png.icons8.com/color/48/000000/creek.png",
                         iconWidth = 30, iconHeight = 30,
                         iconAnchorX = 0, iconAnchorY = 0)
  
  # Reactive value for layer control
  legend <- reactiveValues(group = "LiDAR")
  
  output$map <- renderLeaflet({
    
    leaflet() %>%
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
      addMarkers(data = FieldSite_data,
                popup = paste0("<strong>Site Name: </strong>",
                              FieldSite_data$SiteName,
                              "<br><strong>Region: </strong>",
                              FieldSite_data$DomainName,
                              "<br><strong>State: </strong>",
                              FieldSite_data$Full_State,
                              "<br><strong>Host: </strong>",
                              FieldSite_data$SiteHost),
                clusterOptions = markerClusterOptions(),
                label = paste0(FieldSite_data$SiteName)
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
                                " (m)"),
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
  # Display filtered data on map
  observe({
    proxy <- leafletProxy("map")
    proxy %>%
      clearGroup(group = "Sanimal") %>%
      addMarkers(data=Sanimal_filtered_data(),
                 popup = paste0("<strong> Species:  </strong>",
                                Sanimal_filtered_data()$`Common Name`,
                                "<br><strong> Scientific Name: </strong>",
                                Sanimal_filtered_data()$`Scientific Name`,
                                "<br><strong> Count: </strong>",
                                Sanimal_filtered_data()$Count),
                 group = "Sanimal",
                 clusterOptions = markerClusterOptions())
  })
  
  ####—INPUT FILE TAB####
  
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
  observeEvent(input$remove_user_file,
               leafletProxy("map") %>% clearGroup(group = as.character(user_file_name()))
               )
  
  ####—SANIMAL DATA TAB####
  
  output$Sanimal_table <- renderTable(Sanimal_filtered_data())
  
  ####—FOR ME TAB####
  
  output$text_me <- renderText(
    paste0(is.null(input$user_input_file)
           )
    )
  #output$table_me <- renderTable(flight_frame)
}