list.of.packages <- c("data.table")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

wd = "~/git/IATI-location-analysis"
setwd(wd)

load("d_portal_map.RData")

dat$start_year = as.numeric(substr(dat$day_start,1,4))
dat$end_year = as.numeric(substr(dat$day_end,1,4))
