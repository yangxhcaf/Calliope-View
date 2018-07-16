FROM rocker/shiny:latest
LABEL title = "Calliope-View" maintainer = "Daniel Lee"

# update shell, upgrade packages
RUN apt-get update
RUN apt-get -y dist-upgrade \

# install git and dependencies for "sf" and "rgdal" packages
RUN apt-get install -y git \
libproj-dev \
libgdal-dev \
libudunits2-dev

# download packages needed for app
RUN Rscript -e 'install.packages(c("leaflet","leaflet.extras","shinythemes","dplyr","jsonlite","sf","rgdal","curl"))'

# remove preexisting items in server directory
RUN rm -rf /srv/shiny-server/* 

# get Calliope Shiny app, move into shiny-server
RUN git clone https://github.com/Danielslee51/Calliope-View.git && mv Calliope-View/* /srv/shiny-server/