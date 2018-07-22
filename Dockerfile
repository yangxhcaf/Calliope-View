FROM rocker/shiny:latest
LABEL title = "Calliope-View" maintainer = "Daniel Lee"

# update shell, upgrade packages
RUN apt-get update && apt-get -y dist-upgrade

# install git and dependencies for "sf", "rgdal", and "devtools" packages
RUN apt-get install -y git \
libproj-dev \
libgdal-dev \
libudunits2-dev \
libssl-dev \
libgit2-dev

# download packages needed for app
RUN Rscript -e 'install.packages(c("leaflet","leaflet.extras","shinythemes","dplyr","jsonlite","sf","rgdal","curl", "shinyWidgets", "devtools"))'

RUN Rscript -e 'devtools::install_github("NEONScience/NEON-utilities/neonUtilities", dependencies=TRUE)'

# remove preexisting items in server directory
RUN rm -rf /srv/shiny-server/* 

# get Calliope Shiny app, move into shiny-server
RUN git clone https://github.com/Danielslee51/Calliope-View.git && mkdir /srv/shiny-server/Calliope-View && mv Calliope-View/* /srv/shiny-server/Calliope-View && rm -r /Calliope-View
