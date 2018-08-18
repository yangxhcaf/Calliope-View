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
library(elasticsearchr)
source('Functions/directoryWidget/directoryInput.R')
source('Functions/flight_function.R')
source('Functions/filter_keyword_function.R')
source('Functions/filter_site_function.R')
source('Functions/keyword_lists_function.R')

####———MAP DATA———####

#Fieldsites_JSON <- fromJSON('http://guest:guest@128.196.38.73:9200/sites/_search?size=500')
# Unhashtag line below and hashtag line above when index down
Fieldsites_JSON <- fromJSON('NEON-data/Fieldsites.json')
Fieldsites <- cbind(Fieldsites_JSON$hits$hits[-5], Fieldsites_JSON$hits$hits$`_source`[-4], Fieldsites_JSON$hits$hits$`_source`$boundary)
names(Fieldsites)[9] <- "geo_type"

####——LTAR——####

Fieldsites_LTAR <- Fieldsites %>% filter(type %in% "LTAR")
for (i in 1:nrow(Fieldsites_LTAR)) {
  Fieldsites_LTAR$code[i] <- strsplit(Fieldsites_LTAR$code[i], "LTAR-")[[1]][2]
  Fieldsites_LTAR$acronym[i] <- strsplit(Fieldsites_LTAR$details[[i]][1], ":")[[1]][2]
  Fieldsites_LTAR$city[i] <- strsplit(Fieldsites_LTAR$details[[i]][2], ":")[[1]][2]
  Fieldsites_LTAR$state[i] <- strsplit(Fieldsites_LTAR$details[[i]][3], ":")[[1]][2]
}

####——NEON——####

###NEON Field Sites####
## Retrieve point data for NEON Field Sites in JSON format

FieldSite_point_JSON <- fromJSON('http://data.neonscience.org/api/v0/sites')
# Create a data frame using cbind()
FieldSite_point <- FieldSite_point_JSON$data #cbind(FieldSite_point_JSON$features$properties,FieldSite_point_JSON$features$geometry)
FieldSite_point$domainCode <- as.numeric(gsub(pattern = "D", replacement = "", x = FieldSite_point$domainCode))
FieldSite_abbs <- FieldSite_point$siteCode
## Retrieve polygon data for NEON Field Sites
Fieldsites_NEON <- Fieldsites %>% filter(type %in% "NEON")
for (i in 1:nrow(Fieldsites_NEON)) {
  Fieldsites_NEON$code[i] <- strsplit(Fieldsites_NEON$code[i], "-")[[1]][2]
  Fieldsites_NEON$siteType[i] <- strsplit(Fieldsites_NEON$name[i], ", ")[[1]][2]
  Fieldsites_NEON$name[i] <- strsplit(Fieldsites_NEON$name[i], ", ")[[1]][1]
  Fieldsites_NEON$domainName[i] <- strsplit(Fieldsites_NEON$details[[i]][1], ":")[[1]][2]
  Fieldsites_NEON$domainCode[i] <- strsplit(Fieldsites_NEON$details[[i]][2], ":")[[1]][2]
  Fieldsites_NEON$domainCode[i] <- strsplit(Fieldsites_NEON$domainCode[i], "D")[[1]][2]  
  Fieldsites_NEON$stateCode[i] <- strsplit(Fieldsites_NEON$details[[i]][5], ":")[[1]][2]
  Fieldsites_NEON$stateName[i] <- strsplit(Fieldsites_NEON$details[[i]][6], ":")[[1]][2]
}
Fieldsites_NEON$domainCode <- as.numeric(Fieldsites_NEON$domainCode)

####NEON Domains####
## Retrive data from NEON Domains in JSON format
domains <- fromJSON('NEON-data/NEON_Domains.json')
# Retrieve just the DomainID and Domain Name
domains <- cbind("DomainID" = domains$features$properties$DomainID,"Domain"=domains$features$properties$DomainName)
# Remove Duplicates, make data frame
domains <- as.data.frame(unique(domains))
domains$Domain <- as.character(domains$Domain)
# Retrieve geometry data using st_read()
domain_data <- st_read('NEON-data/NEON_Domains.json')

####NEON Flightpaths####
## Retrieve info for NEON flightpaths
# Get human info about flightpaths
FieldSite_table <- data.frame("Abb"=c("BART","HARV","BLAN","SCBI","SERC","DSNY","JERC","OSBS","STEI-CHEQ","STEI-TREE","UNDE","KONZ-KONA","GRSM","MLBS","ORNL","DELA","LENO","TALL","DCFS-WOOD","NOGP","CLBJ","OAES","CHEQ", "BARO"),
                           "Site"=c("Bartlett Experimental Forest North-South flight box", "Harvard Forest flight box","Blandy Experimental Farm flight box","Smithsonian Conservation Biology Institute flight box","Smithsonian Ecological Research Center flight box","Disney Wilderness Preserve flight box","Jones Ecological Research Center Priority 1 flight box","Ordway-Swisher Biological Station Priority 1 flight box","Chequamegon-Nicolet National Forest flight box","Steigerwaldt-Treehaven Priority 2 flight box","UNDERC flight box","Konza Prairie Biological Station and KONA agricultural site flight box","Great Smoky Mountains National Park priority 2 flight box","Mountain Lake Biological Station flight box","Oak Ridge National Laboratory flight box","Dead Lake flight box","Lenoir Landing flight box","Talladega National Forest flight box","Woodworth and Dakota Coteau Field School flight box","Northern Great Plains flight box","LBJ Grasslands flight box","Klemme Range Research Station flight box",
                                   "Chequamegon-Nicolet National Forest", "Barrow"))
FieldSite_table <- bind_rows(FieldSite_table, as.data.frame(cbind(Abb = FieldSite_point$siteCode, Site =FieldSite_point$siteDescription)))
FieldSite_table <- FieldSite_table[c(-29, -31, -37, -44, -45, -47, -50, -53, -60, -67, -70, -71, -74, -75, -83, -84, -92, -100),]
CR_table <- data.frame("Abb" = c("C", "R", "A"),"Actual" = c("Core", "Relocatable", "Aquatic"),
                       stringsAsFactors = FALSE)
# filesnames needed for loops
flight_filenames_all_2016 <- Sys.glob('NEON-data/Flightdata/Flight_boundaries_2016/D*')
flight_filenames_2016 <- Sys.glob('NEON-data/Flightdata/Flight_boundaries_2016/D*.geojson')
flight_data(flightlist_info = flight_filenames_all_2016, flightlist_geo = flight_filenames_2016, year = "2016", name = "flight_data_2016")
flight_filenames_all_2017 <- Sys.glob('NEON-data/Flightdata/Flight_boundaries_2017/D*')
flight_filenames_2017 <- Sys.glob('NEON-data/Flightdata/Flight_boundaries_2017/D*.geojson')
flight_data(flightlist_info = flight_filenames_all_2017, flightlist_geo = flight_filenames_2017, year = "2017", name = "flight_data_2017")
flight_data <- rbind(flight_data_2016, flight_data_2017)

### TOS ####
# Point markers
TOS_data <- st_read('TOS/NEON_TOS_Polygon.json')
for (i in 1:length(TOS_data$siteID)) {
  TOS_data$siteType[i] <- FieldSite_point$siteType[FieldSite_point$siteCode %in% TOS_data$siteID[i]]
}
TOS_data$domanID <- as.numeric(gsub(pattern = "D", replacement = "", x = TOS_data$domanID))

#### Miscellaneous Variables ####

NEON_datatypes <- c("Airborne Observation Platform (AOP)", "Aquatic Instrument System (AIS)", "Aquatic Observation System (AOS)","Terrestrial Instrument System (TIS)", "Terrestrial Observation System (TOS)")

#### DRONE ####
#drone_json <- fromJSON('http://guest:guest@128.196.38.73:9200/metadata/_search?size=75')
# Unhashtag when index is down:
drone_json <- fromJSON('NEON-data/Drone Images.json')
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

#### — Indexing ####
index <- elastic(cluster_url = 'http://guest:guest@128.196.38.73:9200', index = "metadata", doc_type = "_doc")
# drone_dates <- index %search% aggs('{
#   "dates": {
#     "stats": {
#       "field": "imageMetadata.dateTaken"
#     }
#   }
# }')
# drone_dayofweek <- index %search% aggs('{
#   "dayofweek": {
#     "terms": {
#       "field": "imageMetadata.dayOfWeekTaken",
#       "size": 500
#     }
#   }
# }')
# drone_sites <- index %search% aggs('{
#   "sites": {
#     "terms": {
#       "field": "imageMetadata.siteCode",
#       "size": 500
#     }
#   }
# }')
# drone_altitude <- index %search% aggs('{
#   "altitude": {
#     "stats": {
#       "field": "imageMetadata.altitude"
#     }
#   }
# }')
# drone_elevation <- index %search% aggs('{
#   "elevation": {
#     "stats": {
#       "field": "imageMetadata.elevation"
#     }
#   }
# }')
# drone_maker <- index %search% aggs('{
#   "maker": {
#     "terms": {
#       "field": "imageMetadata.droneMaker",
#       "size": 500
#     }
#   }
# }')
# drone_camera <- index %search% aggs('{
#   "camera": {
#     "terms": {
#       "field": "imageMetadata.cameraModel",
#       "size": 500
#     }
#   }
# }')
# drone_filtype <- index %search% aggs('{
#   "filetype": {
#     "terms": {
#       "field": "imageMetadata.fileType"
#     }
#   }
# }')


####———MAP ICONS———####
NEON_icon <- makeIcon(iconUrl = "Img/NEON.png",
                      iconWidth = 30, iconHeight = 30,
                      iconAnchorX = 15, iconAnchorY = 15,
                      popupAnchorX = -1, popupAnchorY = -15)
drone_image_icon <- makeIcon(iconUrl = "https://png.icons8.com/color/48/000000/map-pin.png",
                             iconAnchorX = 24, iconAnchorY = 48,
                             popupAnchorX = -1, popupAnchorY = -48)
dropdown_icon <- awesomeIcons(icon = "information-circle", library = "ion")
