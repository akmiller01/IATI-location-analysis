list.of.packages <- c("data.table","sp","readr","rgdal")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

wd = "~/git/IATI-location-analysis"
setwd(wd)

load("d_portal_sectors.RData")

coordinates(dat_sectors) = ~location_longitude+location_latitude
proj4string(dat_sectors) = CRS("+init=epsg:4326")

educ = subset(dat_sectors,purpose_code=="11")
health = subset(dat_sectors,purpose_code=="12")

writeOGR(educ,"educ","educ","ESRI Shapefile")
writeOGR(health,"health","health","ESRI Shapefile")
