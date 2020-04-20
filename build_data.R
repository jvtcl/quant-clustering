load('source/den_data_FINAL.RData')

# name fixes
names(den_age)[names(den_age)=='Age.35.65']='Age.35.64'
names(den_race)[-1]=paste0('r',names(den_race)[-1])
names(den_hage)[-1]=paste0('HS.',names(den_hage)[-1])
names(den_hage)=gsub('HS.HS.','HS.',names(den_hage)) # fix redundant labels
names(den_pov)[2]='Below_Poverty'
den_pov$Above_Poverty=rowSums(den_pov[,3:4])
names(den_ivd)[2]='Res_Value'

# assemble data
dat=den_age
dat=merge(dat,den_race,by='FIPS')
dat=merge(dat,den_pov[,c('FIPS','Below_Poverty','Above_Poverty')],by='FIPS')
dat=merge(dat,den_tnr,by='FIPS')
dat=merge(dat,den_noauto,by.x='FIPS',by.y='Geo_GEOID')
dat=merge(dat,den_hcov,by='FIPS')
dat=merge(dat,den_hunits,by='FIPS')
dat=merge(dat,den_hage,by='FIPS')
dat=merge(dat,den_ivd,by.x='FIPS',by.y='GEOID')
dat=merge(dat,den_bdg,by.x='FIPS',by.y='GEOID')
dat=merge(dat,den_imp,by.x='FIPS',by.y='GEOID')
dat=merge(dat,den_cpy,by.x='FIPS',by.y='GEOID')
names(dat)[1]='GEOID'

# join data to tracts and write output
library(rgdal)
library(plyr)
trt=readOGR('source','den_tracts')
trt@data=trt@data[,c('GEOID','INTPTLAT','INTPTLON')]
trt@data[,2]=as.numeric(as.character(trt@data[,2]))
trt@data[,3]=as.numeric(as.character(trt@data[,3]))
trt@data=join(trt@data,dat)

# add neighborhood ids
nbh_lookup = read.csv('source/den_acs14_5yr_trt_in_nbh.csv',stringsAsFactors = F)[,-1]
nbh_lookup$GEOID = paste0('0', nbh_lookup$GEOID)
nbh_lookup=nbh_lookup[match(trt@data$GEOID,nbh_lookup$GEOID),]
trt@data = join(nbh_lookup, trt@data)
names(trt@data)[2] = 'Neighborhood'

## assign unique neighborhood IDs
trtx <- trt@data[,c('GEOID', 'Neighborhood')]
trtx <- split(trtx, trtx$Neighborhood)
for(i in 1:length(trtx)){
  if(nrow(trtx[[i]]) > 1){
    trtx[[i]]$Neighborhood <- paste(trtx[[i]]$Neighborhood, 
                               toupper(letters[1:nrow(trtx[[i]])]))  
  }
}
trtx <- do.call(rbind, trtx)

trt@data <- data.frame(id.nbh = trtx$Neighborhood[match(trt$GEOID, trtx$GEOID)],
                  trt@data,
                  stringsAsFactors = F)

## write outputs
# writeOGR(trt,dsn=getwd(),layer='denver12',driver='ESRI Shapefile',overwrite_layer = T)
writeOGR(trt,dsn=getwd(),layer='denver12',driver='GeoJSON',overwrite_layer = T)