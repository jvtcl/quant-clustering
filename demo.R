library(rgdal)
library(sf)
library(cluster)
library(RColorBrewer)
library(ggplot2)
library(reshape2)
source('fastClusterGOF.R') # custom goodness of fit measure

den = readOGR(getwd(), 'denver12')
den = den[den$GEOID!='08031980100',] # remove empty tract


## remove geographic identifiers, x/y coords, 
## and test variable (health insurance coverage) from cluster inputs
clust_vars = names(den)[!names(den) %in% c('GEOID', 'Nghbrhd', 'INTPTLA', 'INTPTLO', 'Hlth_Un', 'Hlth_In')]

## generate clustering input dataframe
clust_dat = den@data[,clust_vars]

## standardize (z-score) cluster inputs
clust_dat_z = scale(clust_dat)

## add neighborhood ids to rownames for readability
rownames(clust_dat_z) = den$Nghbrhd

## generate distance matrix
d = dist(clust_dat_z)

## ward clustering object
wclust = hclust(d = d, method = 'ward.D2')

## view the dendrogram 
plot(wclust)

## identify a suitable number of clusters
krange = 5:15

# goodness of variance fit
gof = sapply(krange, function(k){
  
  kclust = cutree(wclust, k)
  fastClusterGOF(dat = clust_dat, clust = kclust)
  
})

# average silhouette width
sil = sapply(krange, function(k){
  
  kclust = cutree(wclust, k)
  mean(silhouette(x = kclust, dist = d)[,3])
  
})


## output diagnostics 
cl_diag = cbind(k = krange, gof = gof, sil = sil)
par(mfrow=c(1,2))
plot(gof ~ k, data = cl_diag, type='l')
plot(sil ~ k, data = cl_diag, type='l')
cl_diag

## at k = 12, the GOF is still locally high, 
## but silhouette width has improved from the minimum at k = 11
best_k = 12
den@data$cluster = factor(cutree(wclust, best_k))
# clust = kmeans(clust_dat_z[,1:4],centers=10)$cluster
# library(RColorBrewer)
# par(mfrow=c(1,1))
# plot(den,col=brewer.pal(12,'Set3')[sort(unique(clust))])

den_map = as(den,'sf')
# den_map$cluster = factor(cutree(wclust, best_k))
par(mfrow = c(1,2))
plot(den_map['cluster'],main = paste('Denver Tracts 2012:\nk =',best_k,'clusters'))

## plot outcome variable
health_uninsured_by_cluster = with(den@data, aggregate(Hlth_Un ~ cluster, FUN = 'median'))
health_uninsured_by_cluster = health_uninsured_by_cluster[order(health_uninsured_by_cluster$Hlth_Un, decreasing = T),]
den$cluster = factor(den$cluster, levels = health_uninsured_by_cluster$cluster)
# with(den@data, plot(Hlth_Un ~ cluster, col = brewer.pal(12, 'Set3')[sort(unique(cluster))]))
cols = brewer.pal(12, 'Set3')[sort(unique(den$cluster))]
with(den@data, plot(Hlth_Un ~ cluster, col = cols))
abline(h = median(den$Hlth_Un), col = 'red')

## plot average profile
den_cent = colMeans(clust_dat) # the data centroid
cl = levels(den$cluster)[1] # our target cluster
cl_cent = colMeans(clust_dat[den$cluster==cl,]) # the cluster centroid
avp = (cl_cent - den_cent) / den_cent # difference from data mean

avp_melt = melt(avp)
var_order = rownames(avp_melt)[order(avp_melt$value, decreasing = T)] # plot vars greatest to smallest
avp_melt$variable = factor(rownames(avp_melt), levels = var_order) 

cl_col = cols[as.numeric(cl)]

ggplot(avp_melt, aes(x = variable, y = value)) + 
  geom_bar(fill = cl_col, color = 'black', stat = 'identity') +
  theme_bw() + 
  theme(axis.text.x=element_text(angle=45,hjust=1)) +
  ggtitle(paste('Average Profile for Cluster',cl))
  
