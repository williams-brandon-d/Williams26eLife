function colors = loadClusterColors(nColors)
% up to 5 clusters
colors  = [0.8500 0.3250 0.0980; % orange
           0.4940 0.1840 0.5560; % purple
           0.4660 0.6740 0.1880; % green
           0 0.4470 0.7410; % cyan
          0.6350 0.0780 0.1840]; % redish

if nColors > size(colors,1)
    cmap = colormap('hsv'); % 256 colors in map by default
    sizeMap = size(cmap,1);
    range = [0.1 0.95]; % truncate colormap to avoid similar colors at extremes
    colors  = interp1(1:sizeMap, cmap, linspace(round(range(1)*sizeMap), round(range(2)*sizeMap), nColors)); % interpolate for nColors
end

end