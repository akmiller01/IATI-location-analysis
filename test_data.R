list.of.packages <- c("data.table","varhandle")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

wd = "~/git/IATI-location-analysis"
setwd(wd)

load("d_portal_map.RData")

dat$start_year = as.numeric(substr(dat$day_start,1,4))
dat$end_year = as.numeric(substr(dat$day_end,1,4))

country_tab = data.table(dat)[,.(spend=sum(spend),commitment=sum(commitment)),by=.(country_code,start_year)]
country_tab = country_tab[order(country_tab$country_code,country_tab$start_year),]
# write.csv(country_tab,"country_tab.csv",na="",row.names=F)

table2a = read.csv("TABLE2A_export.csv")
table2a = data.table(table2a)[,.(crs_spend=sum(Value)),by=.(Recipient,Year)]
names(table2a) = c("country_code","start_year","crs_spend")
table2a$country_code = unfactor(table2a$country_code)
table2a$country_code[which(table2a$country_code=="Tanzania")] = "Tanzania, United Republic of"

country_tab = merge(country_tab,table2a,by=c("country_code","start_year"),all.x=T)
country_tab$spend = country_tab$spend+country_tab$commitment
country_tab$spend = country_tab$spend/1000000

cor(country_tab$spend,country_tab$crs_spend,use="pairwise.complete.obs")

fit = lm(crs_spend~spend+country_code+start_year,data=country_tab)
summary(fit)

plot(crs_spend~spend,data=country_tab)
abline(0,1)

country_tab$prox = (country_tab$spend/country_tab$crs_spend)
within_70 = subset(country_tab,prox>=0.7 & prox<=1.3)
countryyears = paste0(within_70$country_code,within_70$start_year)

dat$countryyear = paste0(dat$country_code,dat$start_year)
dat_70 = subset(dat,countryyear %in% countryyears)

dat_precise = subset(dat,location_precision=="1")
country_tab_precision = data.table(dat_precise)[,.(spend=sum(spend),commitment=sum(commitment)),by=.(country_code,start_year,location_precision)]
country_tab_precision = country_tab_precision[order(country_tab_precision$country_code,country_tab_precision$start_year),]
