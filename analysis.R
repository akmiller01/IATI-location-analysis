list.of.packages <- c("data.table","sp","readr")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

wd = "~/git/IATI-location-analysis"
setwd(wd)

# Uganda
# Kenya
# Nigeria
# Rwanda
# Pakistan
# Afghanistan
# Moz
# Ghana
# Ethiopia
# Tanz
# Liberia
countries = c("ug","ke","ng","rw","pk","af","mz","gh","et","tz","lr")

# map_url = paste0(
#   "http://www.d-portal.org/ctrack/q?select=*&from=act%2Clocation%2Ccountry&form=csv&limit=-1&country_code=",
#   paste(countries,collapse="%7C"),
#   "&view=map&country_percent=100&human="
# )
# 
# dat = read_csv(map_url,col_types = cols(.default = "c"))
# save(dat,file="d_portal_map.RData")
load("d_portal_map.RData")

# Divide by the number of locations per project
dat = data.table(dat)
dat[,num_locats:=nrow(.SD),by=.(aid)]
dat$commitment = as.numeric(dat$commitment)/dat$num_locats
dat$commitment_cad = as.numeric(dat$commitment_cad)/dat$num_locats
dat$commitment_eur = as.numeric(dat$commitment_eur)/dat$num_locats
dat$commitment_gbp = as.numeric(dat$commitment_gbp)/dat$num_locats
dat$spend = as.numeric(dat$spend)/dat$num_locats
dat$spend_cad = as.numeric(dat$spend_cad)/dat$num_locats
dat$spend_eur = as.numeric(dat$spend_eur)/dat$num_locats
dat$spend_gbp = as.numeric(dat$spend_gbp)/dat$num_locats

dat$location_latitude = as.numeric(dat$location_latitude)
dat$location_longitude = as.numeric(dat$location_longitude)
wgs = subset(dat,
             location_latitude >= -180 &
               location_latitude <= 180 &
               location_longitude >= -180 &
               location_longitude <= 180
             )
nonwgs = subset(dat,
                location_latitude < -180 |
                  location_latitude > 180 |
                  location_longitude < -180 |
                  location_longitude > 180
)
# NL accidentally forgot decimal points
# http://d-portal.org/q.xml?aid=NL-KVK-41009723-AFG228-1
nonwgs$location_latitude = nonwgs$location_latitude/10000
nonwgs$location_longitude = nonwgs$location_longitude/10000

iati_loc = rbind(wgs,nonwgs)

coordinates(iati_loc) = ~location_longitude+location_latitude
proj4string(iati_loc) = CRS("+init=epsg:4326")
plot(iati_loc)
