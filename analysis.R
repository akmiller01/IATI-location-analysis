list.of.packages <- c("data.table","sp","readr","xml2")
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
# countries = c("ug","ke","ng","rw","pk","af","mz","gh","et","tz","lr")
# 
# map_url = paste0(
#   "http://www.d-portal.org/ctrack/q?select=*&from=act%2Clocation%2Ccountry&form=csv&limit=-1&country_code=",
#   paste(countries,collapse="%7C"),
#   "&view=map&country_percent=100&human="
# )
# 
# dat = read_csv(map_url,col_types = cols(.default = "c"))
# save(dat,file="d_portal_raw.RData")
# load("d_portal_raw.RData")
# 
# # Divide by the number of locations per project
# dat = data.table(dat)
# dat[,num_locats:=nrow(.SD),by=.(aid)]
# dat$commitment = as.numeric(dat$commitment)/dat$num_locats
# dat$commitment_cad = as.numeric(dat$commitment_cad)/dat$num_locats
# dat$commitment_eur = as.numeric(dat$commitment_eur)/dat$num_locats
# dat$commitment_gbp = as.numeric(dat$commitment_gbp)/dat$num_locats
# dat$spend = as.numeric(dat$spend)/dat$num_locats
# dat$spend_cad = as.numeric(dat$spend_cad)/dat$num_locats
# dat$spend_eur = as.numeric(dat$spend_eur)/dat$num_locats
# dat$spend_gbp = as.numeric(dat$spend_gbp)/dat$num_locats
# 
# dat$location_latitude = as.numeric(dat$location_latitude)
# dat$location_longitude = as.numeric(dat$location_longitude)
# wgs = subset(dat,
#              location_latitude >= -180 &
#                location_latitude <= 180 &
#                location_longitude >= -180 &
#                location_longitude <= 180
#              )
# nonwgs = subset(dat,
#                 location_latitude < -180 |
#                   location_latitude > 180 |
#                   location_longitude < -180 |
#                   location_longitude > 180
# )
# # NL accidentally forgot decimal points
# # http://d-portal.org/q.xml?aid=NL-KVK-41009723-AFG228-1
# nonwgs$location_latitude = nonwgs$location_latitude/10000
# nonwgs$location_longitude = nonwgs$location_longitude/10000
# 
# dat = rbind(wgs,nonwgs)
# 
# save(dat, file="d_portal_map.RData")
load("d_portal_map.RData")

calculate_sectors = function(d_port_url){
  aid_id = substr(d_port_url,32,nchar(d_port_url))
  xml_url = URLencode(paste0("http://d-portal.org/q.xml?aid=",aid_id))
  xml_root = read_xml(xml_url)
  activity = xml_children(xml_root)[1]
  activity_children = xml_children(activity)
  child_names = sapply(activity_children,xml_name)
  if("transaction" %in% child_names){
    trans_sectors = c()
    transactions = xml_find_all(activity, ".//transaction")
    for(trans in transactions){
      trans_children = xml_children(trans)
      trans_child_names = sapply(trans_children,xml_name)
      value_elem = xml_find_first(trans,".//value")
      value = as.numeric(xml_text(value_elem))
      if("sector" %in% trans_child_names){
        sector_elem = xml_find_first(trans,".//sector")
        sector_vocab = xml_attr(sector_elem,"vocabulary")
        if(sector_vocab %in% c("1","2","DAC","DAC-3")){
          sector_code = xml_attr(sector_elem,"code")
          purpose_code = substr(sector_code,1,2)
          trans_sectors[purpose_code]=value
        }
      }
    }
    trans_sectors = trans_sectors/sum(trans_sectors)
    if(length(trans_sectors)>0){
      if(!(length(trans_sectors)==1 & names(trans_sectors)[1]=="")){
        return(trans_sectors) 
      }
    }
  }
  if("sector" %in% child_names){
    act_sectors = c()
    act_sector_elems = xml_find_all(activity,".//sector")
    for(act_sector_elem in act_sector_elems){
      sector_vocab = xml_attr(act_sector_elem,"vocabulary")
      value = as.numeric(xml_attr(act_sector_elem,"percentage"))
      if(sector_vocab %in% c("1","2","DAC","DAC-3")){
        sector_code = xml_attr(act_sector_elem,"code")
        purpose_code = substr(sector_code,1,2)
        act_sectors[purpose_code]=value
      }
    }
    act_sectors = act_sectors/sum(act_sectors)
    return(act_sectors)
  }
}

unique.activities = unique(dat$aid)
sec_df_list = list()
sec_df_index = 1
pb = txtProgressBar(min=1,max=length(unique.activities),style=3)
for(i in 1:length(unique.activities)){
  unique.activity = unique.activities[i]
  sec_vec = calculate_sectors(unique.activity)
  if(length(sec_vec)>0){
    sec_df_tmp = data.frame(
      purpose_code=names(sec_vec),
      purpose_percentage=sec_vec,
      aid = unique.activity
    )
    sec_df_tmp = data.table(sec_df_tmp)[,.(purpose_percentage=sum(purpose_percentage,na.rm=T)),by=.(purpose_code,aid)]
    sec_df_list[[sec_df_index]] = sec_df_tmp
    sec_df_index = sec_df_index + 1
  }
  setTxtProgressBar(pb, i)
}
close(pb)

sec_df = rbindlist(sec_df_list)
sec_df = subset(sec_df,purpose_code!="")
sec_df[,num_secs:=nrow(.SD),by=.(aid)]
sec_df$purpose_percentage[which(sec_df$purpose_percentage=="0")] = 1/sec_df$num_secs[which(sec_df$purpose_percentage=="0")]

dat_sectors = merge(dat, sec_df, by="aid")

dat_sectors$commitment = as.numeric(dat_sectors$commitment)*dat_sectors$purpose_percentage
dat_sectors$commitment_cad = as.numeric(dat_sectors$commitment_cad)*dat_sectors$purpose_percentage
dat_sectors$commitment_eur = as.numeric(dat_sectors$commitment_eur)*dat_sectors$purpose_percentage
dat_sectors$commitment_gbp = as.numeric(dat_sectors$commitment_gbp)*dat_sectors$purpose_percentage
dat_sectors$spend = as.numeric(dat_sectors$spend)*dat_sectors$purpose_percentage
dat_sectors$spend_cad = as.numeric(dat_sectors$spend_cad)*dat_sectors$purpose_percentage
dat_sectors$spend_eur = as.numeric(dat_sectors$spend_eur)*dat_sectors$purpose_percentage
dat_sectors$spend_gbp = as.numeric(dat_sectors$spend_gbp)*dat_sectors$purpose_percentage

save(dat_sectors,file="d_portal_sectors.RData")
