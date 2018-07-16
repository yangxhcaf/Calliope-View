# Calliope-View
An interactive leaflet interface designed to display ecological data alongside drone imaging.
## Overview
This R Shiny app uses leaflet to display ecological data provided by [NEON](https://www.neonscience.org/) alongside drone imaging under one map. Users will then be able to compare biological statistics such as precipitation, soil temperature, humidity, and pressure with their own data to generate analyses ranging from the effects of climate change to the relationship between geographical factors and the ecosystem.

[NEON](https://www.neonscience.org/) is a "continental-scale ecological observation facility" that provides open data on our ecosystems. [NEON](https://www.neonscience.org/) is the source that this app pulls from to get ecological data.
## Features

## Use and Installation
### Git
To install, change the working directory on your shell to the desired directory, and clone from git:
``` bash
cd /Desktop
git clone https://github.com/Danielslee51/Calliope-View/
```
Then, run server.R in an R IDE (such as Rstudio).

<img src="Img/RStudio.png" width="600"/>

### Docker
Alternatively, there is a [docker image](https://hub.docker.com/r/danielslee/calliope-view/) available to run this app.
```bash
docker pull danielslee/calliope-view
```
After pulling from Docker Hub, expose a port and run the image.
``` bash
docker run --rm -d -p 80:3838 danielslee/calliope-view
```
Then, access the app by visiting the host's exposed port: http://localhost:80/
