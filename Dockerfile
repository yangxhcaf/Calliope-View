FROM rocker/shiny:latest
LABEL title = "Calliope-View" maintainer = "Daniel Lee"

# update shell
RUN apt-get update

# install git and dependencies for "sf" and "rgdal" packages
RUN apt-get install -y git \
libproj-dev \
libgdal-dev \
libudunits2-dev

# download packages needed for app
RUN Rscript -e 'install.packages(c("leaflet","dplyr","jsonlite","sf","rgdal","curl"))'

RUN rm -rf /srv/shiny-server/* 
 
# Copy the source code of the app from my hard drive to the container (in this case we use the app "wordcloud" from http://shiny.rstudio.com/gallery/word-cloud.html)

COPY . /srv/shiny-server/
# change permission of the shiny folder where the app sits
RUN chmod -R 777 /srv/shiny-server
# Start the server with the container
CMD ["Rscript", "/srv/shiny-server/test.R"]




