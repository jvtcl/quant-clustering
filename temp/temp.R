
#### assign unique neighborhood labels ####
denx <- den@data[,c('GEOID', 'Nghbrhd')]
denx <- split(denx, denx$Nghbrhd)
for(i in 1:length(denx)){
  if(nrow(denx[[i]]) > 1){
    denx[[i]]$Nghbrhd <- paste(denx[[i]]$Nghbrhd, 
                               toupper(letters[1:nrow(denx[[i]])]))  
  }
}
denx <- do.call(rbind, denx)

den$Nghbrhd <- denx$Nghbrhd[match(den$GEOID, denx$GEOID)]


#### PCA clustering ####
library(FactoMineR)
library(fpc)

pca_in <- den@data[,c('Hlth_Un', clust_vars)]
rownames(pca_in) <- den$Nghbrhd
pca <- PCA(pca_in, scale.unit = T, quanti.sup = 1,  ncp = 2, graph = F)

cowplot::plot_grid(
  plot(pca, choix = 'var'),
  plot(pca, choix = 'ind', cex = 0.5),
  nrow = 1
)
pca.scores <- data.frame(scale(pca$ind$coord))

plt_pca <- plot(pca, choix = 'var', shadowtext = T, cex = 0.8) +
  geom_point(data = pca.scores, aes(x = Dim.1, y = Dim.2), color = 'gray40', inherit.aes = F) + 
  scale_color_brewer(type = 'qual', palette = 'Set2') + 
  labs(color = 'Cluster')

map_pca <- ggplot(data = den_map, aes(fill = clust_pca)) + 
  geom_sf(size = 0.1, color = 'black') + 
  scale_fill_brewer(type = 'qual', palette = 'Set2') +
  theme_void() +
  theme(legend.position = 'none')

cowplot::plot_grid(map_pca, plt_pca, ncol = 1)

dp = dist(pca.scores)

## ward dendrogram
dendp = hclust(d = dp, method = 'ward.D2')

clust_pca <- cutree(dendp, k = best_k) # use same k for comparison's sake

den_map['clust_pca'] <- factor(clust_pca)

plot(den_map['clust_pca'], lwd = 0.1)
plot(den_map[c('cluster', 'clust_pca')], lwd = 0.1)

plot(pca, choix = 'ind', col.ind = brewer.pal(8, 'Set2')[clust_pca])

#### PCA (alt) ####
library(vegan)
pca <- rda(clust_dat_z ~ 1)

plot(pca, type = 'text')

dp = dist(pca.scores)

## ward dendrogram
dendp = hclust(d = dp, method = 'ward.D2')

clust_pca <- cutree(dendp, k = best_k) # use same k for comparison's sake


biplot(pca)
plot(pca, type = 'text', scaling = 1, add = T)
text(pca$CCA$u[,1:2])


blah <- with(summary(pca), list(X = sites, Y = species))
# blah <- purrr::map(blah, data.frame)
with(blah, biplot(X, Y, cex = 0.5))
abline(v = 0, lty = 'dotted', col = 'gray50')
abline(h = 0, lty = 'dotted', col = 'gray50')

blah$Y <- data.frame(origin = 0, blah$Y)

text(blah$X, plot(blah$X, cex = 0), labels = rownames(blah$X), col = brewer.pal(8, 'Set2')[clust_pca])
arrows(blah$Y, x0 = blah$Y$origin, x1 = blah$Y$PC1, y0 = blah$Y$origin, y1 = blah$Y$PC2, add = T)

library(ggplot2)
library(ggrepel)
blah <- purrr::map(blah, data.frame)

ggplot() + 
  geom_segment(data = blah$Y, aes(x = 0, y = 0, xend = PC1, yend = PC2), color = 'gray40', arrow = arrow(length = unit(0.05, 'inches'))) + 
  geom_text_repel(data = blah$X, aes(x = PC1, y = PC2, label = rownames(blah$X), color = factor(clust_pca)), size = 3, bg.color = 'white') +
  geom_text(data = blah$Y, aes(x = PC1 * 1.1, y = PC2 * 1.1, label = rownames(blah$Y)), color = 'gray40', segment.colour = NA) + 
  theme_bw() + 
  theme(legend.position = 'none')


#### possible slide on MDS ####
library(RColorBrewer)
library(smacof)
sm <- smacofSym(d)

clust <- cutree(dend, 7)

text(sm$conf, 
     plot(sm$conf, cex = 0),
     labels = den$Nghbrhd,
     cex = 0.5,
     col = brewer.pal(8, 'Set2')[clust])

set.seed(808)
clust.sm <- kmeans(sm$conf, centers = 7)$cluster

text(sm$conf, 
     plot(sm$conf, cex = 0),
     labels = den$Nghbrhd,
     cex = 0.5,
     col = brewer.pal(8, 'Set2')[clust.sm])

den_map['clust.sm'] <- factor(clust.sm)
plot(den_map['clust.sm'], lwd = 0.1)
