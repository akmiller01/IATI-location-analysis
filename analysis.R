list.of.packages <- c("xml2","data.table","varhandle","readr","purrr")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

wd = "~/git/IATI-location-analysis"
setwd(wd)

# dat = read_csv("iati.csv",col_types=cols(.default = "c"))
# dat$long_description = NULL
# dat$short_description = NULL
# dat = subset(dat,!is.na(location_xml))
# save(dat,file="iati.RData")

load("iati.RData")

location_xmls = unique(dat$location_xml)

loc_list = list()

pb <- txtProgressBar(min = 1, max = length(location_xmls), style = 3)

for(i in 1:length(location_xmls)){
  setTxtProgressBar(pb, i)
  location_xml = location_xmls[i]
  locations = read_xml(location_xml)
  location_elems = xml_children(locations)
  loc_df = data.frame(location_xml = location_xml)
  for(j in 1:length(location_elems)){
    location = location_elems[j]
    location_children = xml_children(location)
    for(child in location_children){
      child_name = xml_name(child)
      # Capture all child attributes
      child_attribs = xml_attrs(child)
      for(k in 1:length(child_attribs)){
        child_attrib_name = names(child_attribs)[k]
        var_name = paste(j,child_name,child_attrib_name,sep=".")
        var_value = child_attribs[k]
        loc_df[,var_name] = var_value
      }
      # Including text
      var_name = paste(j,child_name,"text",sep=".")
      var_value = xml_text(child)
      if(var_value!=""){
        loc_df[,var_name] = var_value
      }
      location_grandchildren = xml_children(child)
      if(length(location_grandchildren)>0){
        for(m in 1:length(location_grandchildren)){
          grandchild = location_grandchildren[m]
          grandchild_name = xml_name(grandchild)
          # Capture all grandchild attributes
          grandchild_attribs = xml_attrs(grandchild)
          for(n in 1:length(grandchild_attribs)){
            grandchild_attrib_name = names(grandchild_attribs)[n]
            var_name = paste(j,grandchild_name,grandchild_attrib_name,sep=".")
            var_value = grandchild_attribs[n]
            loc_df[,var_name] = var_value
          }
          # Including text
          var_name = paste(j,grandchild_name,"text",sep=".")
          var_value = xml_text(grandchild)
          if(var_value!=""){
            loc_df[,var_name] = var_value
          }
        }
      }
    }
  }
  loc_list[[i]] = loc_df
}
close(pb)
