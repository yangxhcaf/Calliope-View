# Calliope-View
An interactive leaflet interface designed to display ecological data alongside drone imaging.
## Overview
This R Shiny app uses leaflet to display ecological data provided by [NEON](https://www.neonscience.org/) alongside drone imaging under one map. Users will then be able to compare biological statistics such as precipitation, soil temperature, humidity, and pressure with their own data to generate analyses ranging from the effects of climate change to the relationship between geographical factors and the ecosystem.

[NEON](https://www.neonscience.org/) is a "continental-scale ecological observation facility" that provides open data on our ecosystems. [NEON](https://www.neonscience.org/) is the source that this app pulls from to get ecological data.
## Features
The app offers a map, which displays items such as NEON sites and domains, alongside custom data which can be filtered and displayed based on multiple variables. Here is an example of Calliope View’s display of NEON sites and their boundaries:
<br><br>
<img src="Img/Calliope-View1.gif" height="500"/>
<br><br>
Here is a display of the user's ability to filter datasets via multiple varibales:
<br><br>
<img src="Img/Calliope-View2.gif" height="500"/>
> The dataset being queried and shown describes animal locations because we originally used an animal dataset as placeholder for the drone data while it was being developed. The app no longer includes this data, but it is still useful in demonstrating the app, functionality.
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
Alternatively, access the app at http://128.196.142.101/.

This link is launched by a [virtual machine](https://atmo.cyverse.org/) running the [docker image](https://hub.docker.com/r/danielslee/calliope-view/) to use this app. This image is also available:
```bash
docker pull danielslee/calliope-view
```
After pulling from Docker Hub, expose a port and run the image.
``` bash
docker run --rm -d -p 80:3838 danielslee/calliope-view
```
Then, access the app by visiting the host's exposed port: http://localhost:80/
> This image is very large, measuring over 2 gigabytes. Due to this, I recommend using the link above.
