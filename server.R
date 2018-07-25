# Shiny server
function(input, output, session) {
  
  ####INTERACTIVE MAP TAB####
  
  # Reactive value for layer control
  legend <- reactiveValues(group = c("Drone", "Field Sites", "Domains", "Flightpaths", "TOS"))
  
  #### Map ####
  output$map <- renderLeaflet({

    map <- (
    leaflet() %>%
      addProviderTiles(provider = providers$OpenStreetMap.Mapnik,
                       group = "Basic"
                       ) %>%
      addProviderTiles(provider = providers$Esri.NatGeoWorldMap,
                       group = "Nat geo") %>%
      addProviderTiles(provider = providers$OpenTopoMap,
                       group = "Topo") %>%
      addProviderTiles(provider = providers$Esri.WorldImagery,
                       group = "Satellite") %>%
      # Add measuring tool
      addMeasure(position = "topleft",
                 primaryLengthUnit = "kilometers",
                 primaryAreaUnit = "sqmeters",
                 activeColor = "#3D535D",
                 completedColor = "#7D4479"
                 ) %>%
      # Add layer control
      addLayersControl(baseGroups = c("Basic", "Satellite", "Nat geo", "Topo"),
                       overlayGroups = legend$group,
                       options = layersControlOptions(collapsed = FALSE)
                       ) %>%
      # Add option for fullscreen
      leaflet.extras::addFullscreenControl(pseudoFullscreen = TRUE) %>%
      # Markers for NEON field site locations
      addMarkers(data = FieldSite_point,
                 lng = FieldSite_point$siteLongitude,
                 lat = FieldSite_point$siteLatitude,
                 group = "Field Sites",
                 popup = paste0("<b>Site Name: </b>",
                                FieldSite_point$siteDescription, " (",
                                FieldSite_point$siteCode, ")",
                                "<br><b>Region: </b>",
                                FieldSite_point$domainName,
                                "<br><b>State: </b>",
                                FieldSite_point$stateName,
                                "<br><b>Site Type: </b>",
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
      # Areas for NEON flight paths (red)
      addPolygons(data = flight_data$geometry,
                  color = "red",
                  group = "Flightpaths",
                  popup = paste0("<b>Site: </b><br>",
                                 flight_data$Site,
                                 "<br><b>Domain: </b>",
                                 domains[flight_data$DomainID,2],
                                 "<br><b>Core/Relocatable: </b>",
                                 flight_data$'Core.or.Relocatable',
                                 "<br><b>Flight Priority: </b>",
                                 flight_data$Priority,
                                 "<br><b>Version: </b>",
                                 flight_info$Version)
                  ) %>%
      # Markers for TOS
      addMarkers(data = TOS_data,
                 lng = TOS_data$longitd,
                 lat = TOS_data$latitud,
                 popup = paste0("<b>Site: </b>",
                                TOS_data$siteID,
                                "<br><b>Plot ID: </b>",
                                TOS_data$plotID,
                                "<br><b>Dimensions: </b>",
                                TOS_data$plotDim,
                                "<br><b>Plot Type: </b>",
                                TOS_data$plotTyp, "/",
                                TOS_data$subtype),
                 group = "TOS",
                 clusterOptions = markerClusterOptions()
                 ) %>%
      # Boundaries for TOS (gray)
      addPolygons(data = TOS_data,
                  popup = paste0("Area of ", TOS_data$plotID),
                  group = "TOS",
                  color = "gray")
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
  
  ####— DRONE ####
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
                 icon = drone_image_icon)
  })
  ####— NEON ####
  
  ####—— NEON: Step 1- Find data ####
  ####——— 1a: By Site####
  # Variables
  NEONproducts_site <- reactive(nneo_site(x = input$NEONsite_site)$dataProducts)
  NEONproducts_product <- nneo_products() # Added this variable up here because one item in finding by "site" needed it
  # list: getting data frame of availability based on site code
  NEONproductlist_site <- reactive(cbind("Product Name" = NEONproducts_site()$dataProductTitle, "Product ID" = NEONproducts_site()$dataProductCode))
  # single: filtering column of products for one site through ID
  NEONproductID_site <- reactive(req(
    if (gsub(pattern = " ", replacement = "", x = input$NEONproductID_site) == "") {
      "random string that will not match to anything"
    } else {
      gsub(pattern = " ", replacement = "", x = input$NEONproductID_site)
    }
  ))
  NEONproductinfo_site <- reactive(req(filter(.data = NEONproducts_site(), dataProductCode == NEONproductID_site())))
  # Display products: list
  output$NEONproductoptions_site <- renderDataTable(NEONproductlist_site())
  # Display products: single
  output$NEONproductname_site <- renderPrint(req(NEONproductinfo_site()$dataProductTitle))
  output$NEONproductdesc_site <- renderPrint(req(ifelse(is.null(req(NEONproductinfo_site()$dataProductTitle)),
                                                        yes = NULL,
                                                        no = NEONproducts_product$productDescription[NEONproducts_product$productCode %in% NEONproductID_site()]
    )))
  output$NEONproductdates_site <- renderPrint({
    dates <- if (length(NEONproductinfo_site()$availableMonths) == 0) {
      NA
    } else {
      NEONproductinfo_site()$availableMonths[[1]]}
    req(dates)
    })
  output$NEONproductURL_site <- renderPrint({
    urls <- if (length(NEONproductinfo_site()$availableDataUrl) == 0) {
      NA 
    } else {
      NEONproductinfo_site()$availableDataUrl[[1]]}
    req(urls)
  })
  
  ####——— 1b: By product:####
  # Variables
  # NEONproducts_product <- nneo_products()
  # list: getting data table with products and IDs
  NEONproductlist_product <- NEONproducts_product[c("productName", "productCode")]
  names(NEONproductlist_product) <- c('Product Name', 'Product ID')
  # single: filtering one column of parent NEON products table through ID
  NEONproductID_product <- reactive(req(
    ifelse(gsub(pattern = " ", replacement = "", x = input$NEONproductID_product) == "",
      yes = "random string that will not match to anything",
      no = gsub(pattern = " ", replacement = "", x = input$NEONproductID_product))
    ))
  NEONproductinfo_product <- reactive(req(filter(.data = NEONproducts_product, productCode == NEONproductID_product())))
  # Display products: list
  output$NEON_product_options <- renderDataTable(NEONproductlist_product)
  # Display products: single
  output$NEONproductname_product <- renderPrint(req(NEONproductinfo_product()$productName))
  output$NEONproductdesc_product <- renderPrint(req(NEONproductinfo_product()$productDescription))
  output$ui_product<- renderUI({
    sites <- if (length(NEONproductinfo_product()$siteCodes) == 0) {
      NA} else {
        sort(NEONproductinfo_product()$siteCodes[[1]]$siteCode)}
    selectInput(inputId = "NEONsite_product", label = "Available sites:", choices = req(sites))
  })
  output$NEONproductdates_product <- renderPrint({
    dates <- if (length(NEONproductinfo_product()$siteCodes) == 0) {
      NA
    } else { 
      NEONproductinfo_product()$siteCodes[[1]]$availableMonths[NEONproductinfo_product()$siteCodes[[1]]$siteCode %in% input$NEONsite_product][[1]]}
    req(dates)
  })
  output$NEONproductURL_product <- renderPrint({
    Urls <- if (length(NEONproductinfo_product()$siteCodes) == 0) {
      NA
    } else {
      NEONproductinfo_product()$siteCodes[[1]]$availableDataUrls[NEONproductinfo_product()$siteCodes[[1]]$siteCode %in% input$NEONsite_product][[1]]}
    req(Urls)
  })
  
  ####—— NEON: Step 2- Download Data: variables ####
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
  
  ####—— NEON: Step 3- Unzip/Join Downloads: variables ####
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
  # Functions needed to make list of files reactive
  has.new.files <- function() {
    unique(list.files(path = '..', pattern = ".zip"))
  }
  get.files <- function() {
    list.files(path = '..', pattern = ".zip")
  }
  NEON_unzip_files <- reactivePoll(intervalMillis = 10, session, checkFunc = has.new.files, valueFunc = get.files)
  observeEvent(NEON_unzip_files(), ignoreInit = TRUE, ignoreNULL = TRUE, {
    updateSelectInput(session, inputId = 'NEON_unzip_file', choices = NEON_unzip_files())
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
  
  ####DRONE DATA TAB####
  
  # Display data via table
  output$Drone_table <- renderTable(Drone_filtered_NEON())
  
  ####FOR ME TAB####
  
  #Text for troublshooting
  output$text_me <- renderText(getwd())
  #Text for troublshooting 2
  output$text_me_two <- renderText("")
  #Table for troubleshooting
  #output$table_me <- renderDataTable()
}