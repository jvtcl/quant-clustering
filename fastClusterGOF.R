fastClusterGOF<-function(dat,clust){
  
  "
  Quick cluster goodness of fit function.
  
  Output should match GOF from kmeans function. Allows
  for computation of GOF in the same way without 
  performing kmeans.
  "
  
  tss=sum(scale(dat,scale=FALSE)^2)
  cls=sort(unique(clust))
  wss=lapply(cls,function(cl){
    if(!is.vector(dat)){ # multiple variables
      sum(scale(dat[clust==cl,],scale=F)^2)  
    }else{ # single vector of variables
      sum(scale(dat[clust==cl],scale=F)^2)
    }
  })
  
  ## I haven't gotten to BSS yet ##  
  # bss=lapply(cls,function(cl){
  #   tcl=dat[dat$cluster==cl,][,-c(1:2)]
  #   sum(scale(,scale=F)^2)  
  # })
  
  (tss-sum(unlist(wss)))/tss
  
}
