library(shiny)
library(shinythemes)
library(leaflet)
library(leaflet.extras)
library(dplyr)
library(jsonlite)
library(sf)
library(rgdal)
library(neonUtilities)
library(shinyWidgets)
library(nneo)
source('directoryWidget/directoryInput.R')

####———MAP DATA———####




###NEON Field Sites####
## Retrieve point data for NEON Field Sites in JSON format

FieldSite_point_JSON <- fromJSON('http://data.neonscience.org/api/v0/sites') #'NEON_data/NEON_Field_Sites.json'
# Create a data frame using cbind()
FieldSite_point <- FieldSite_point_JSON$data #cbind(FieldSite_point_JSON$features$properties,FieldSite_point_JSON$features$geometry)
FieldSite_point$domainCode <- as.numeric(gsub(pattern = "D", replacement = "", x = FieldSite_point$domainCode))
FieldSite_abbs <- FieldSite_point$siteCode
## Retrieve polygon data for NEON Field Sites
FieldSite_poly_JSON <- fromJSON('http://calliopeView:cvPass@128.196.38.73:9200/neon_sites/_search?size=500')
# Unhashtag when index is down:
#FieldSite_poly_JSON <- fromJSON('Field Sites.json')
FieldSite_poly <- cbind(FieldSite_poly_JSON$hits$hits$`_source`$site, FieldSite_poly_JSON$hits$hits$`_source`$boundary)
FieldSite_poly$domainCode <- as.numeric(gsub(pattern = "D", replacement = "", x = FieldSite_poly$domainCode))

####NEON Domains####
## Retrive data from NEON Domains in JSON format
domains <- fromJSON('NEON_data/NEON_Domains.json')
# Retrieve just the DomainID and Domain Name
domains <- cbind("DomainID" = domains$features$properties$DomainID,"Domain"=domains$features$properties$DomainName)
# Remove Duplicates, make data frame
domains <- as.data.frame(unique(domains))
domains$Domain <- as.character(domains$Domain)
# Retrieve geometry data using st_read()
domain_data <- st_read('NEON_data/NEON_Domains.json')

####NEON Flightpaths####
## Retrieve info for NEON flightpaths
# Get human info about flightpaths
FieldSite_table <- data.frame("Abb"=c("BART","HARV","BLAN","SCBI","SERC","DSNY","JERC","OSBS","STEI-CHEQ","STEI-TREE","UNDE","KONZ-KONA","GRSM","MLBS","ORNL","DELA","LENO","TALL","DCFS-WOOD","NOGP","CLBJ","OAES"),
                           "Site"=c("Bartlett Experimental Forest North-South flight box", "Harvard Forest flight box","Blandy Experimental Farm flight box","Smithsonian Conservation Biology Institute flight box","Smithsonian Ecological Research Center flight box","Disney Wilderness Preserve flight box","Jones Ecological Research Center Priority 1 flight box","Ordway-Swisher Biological Station Priority 1 flight box","Chequamegon-Nicolet National Forest flight box","Steigerwaldt-Treehaven Priority 2 flight box","UNDERC flight box","Konza Prairie Biological Station and KONA agricultural site flight box","Great Smoky Mountains National Park priority 2 flight box","Mountain Lake Biological Station flight box","Oak Ridge National Laboratory flight box","Dead Lake flight box","Lenoir Landing flight box","Talladega National Forest flight box","Woodworth and Dakota Coteau Field School flight box","Northern Great Plains flight box","LBJ Grasslands flight box","Klemme Range Research Station flight box"))
CR_table <- data.frame("Abb"=c(as.character("C"),as.character("R")),"Actual"=c(as.character("Core"),as.character("Relocatable")),
                       stringsAsFactors = FALSE)
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
  file_info <- cbind("Name" = name_part,
                     "DomainID" = domain_part,
                     "SiteAbb" = site_part,
                     "Site" = as.character(FieldSite_table$Site[FieldSite_table$Abb %in% site_part]),
                     "SiteType" = toupper(CR_table[grep(RC_part_type,CR_table$Abb),2]),
                     "SiteType_number" = RC_part_num,
                     "Priority" = priority_part,
                     "Version" = version_part)
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

### TOS ####
# Point markers
TOS_data <- st_read('TOS/NEON_TOS_Polygon.json')
for (i in 1:length(TOS_data$siteID)) {
  TOS_data$siteType[i] <- FieldSite_point$siteType[FieldSite_point$siteCode %in% TOS_data$siteID[i]]
}
TOS_data$domanID <- as.numeric(gsub(pattern = "D", replacement = "", x = TOS_data$domanID))

#### DRONE ####
drone_json <- fromJSON('http://calliopeView:cvPass@128.196.38.73:9200/metadata/_search?size=75')
# Unhashtag when index is down:
# drone_json <- fromJSON('Drone Images.json')
drone_data <- cbind(drone_json$hits$hits[names(drone_json$hits$hits)!="_source"],
                    drone_json$hits$hits$`_source`[names(drone_json$hits$hits$`_source`)!="imageMetadata"],
                    drone_json$hits$hits$`_source`$imageMetadata[!(names(drone_json$hits$hits$`_source`$imageMetadata) %in% c("speed", "rotation"))],
                    drone_json$hits$hits$`_source`$imageMetadata$speed,
                    drone_json$hits$hits$`_source`$imageMetadata$rotation)

for (i in 1:length(drone_data$position)) {
  # New columns for lat/long, from position
  drone_data$Latitude[i] <- strsplit(drone_data$position, ", ")[[i]][1]
  drone_data$Longitude[i] <- strsplit(drone_data$position, ", ")[[i]][2]
  # New column for day of month, from dateTaken
  day_chunk <- strsplit(drone_data$dateTaken[i], "-")[[1]][3]
  drone_data$dayTaken[i] <- strsplit(day_chunk, "T")[[1]][1]
  # New column for time of day, from dateTaken
  drone_data$timeTaken[i] <- strsplit(drone_data$dateTaken[i], "T")[[1]][2]
}
drone_data$Longitude <- as.numeric(drone_data$Longitude)
drone_data$Latitude <- as.numeric(drone_data$Latitude)
# Remove columns, reorder
drone_data <- drone_data[,!(names(drone_data) %in% c("position", "dateTaken", "hourTaken"))]
drone_data <- drone_data[c("_id", "neonSiteCode", "Latitude", "Longitude", "altitude", "yearTaken", "monthTaken", "dayTaken", "timeTaken",
                           "dayOfYearTaken", "dayOfWeekTaken", "x", "y", "z", "roll", "pitch", "yaw",
                           "collectionID", "storagePath", "_type", "_index", "_score")]
drone_data <- unique(drone_data)

####———MAP ICONS———####
NEON_icon <- makeIcon(iconUrl = "Img/NEON.png",
                      iconWidth = 30, iconHeight = 30,
                      iconAnchorX = 15, iconAnchorY = 15,
                      popupAnchorX = -1, popupAnchorY = -15)
drone_image_icon <- makeIcon(iconUrl = "https://png.icons8.com/color/48/000000/map-pin.png",
                             iconAnchorX = 24, iconAnchorY = 48,
                             popupAnchorX = -1, popupAnchorY = -48)
           