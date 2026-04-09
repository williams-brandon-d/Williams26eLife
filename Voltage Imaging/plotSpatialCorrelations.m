function [d,r] = plotSpatialCorrelations(ROIs,R,clusterIdx,saveFolder,savenum)

pixelSize = 0.4514; % pixel size - um / pixel 

% find center of all ROIs
% perform pairwise correlations with both raw data and spike trains?

% corrType = 'dfoverf';

nSelected = numel(ROIs);

ROIxy = zeros(nSelected,2);

for iNeuron = 1:nSelected
    S = regionprops(ROIs{iNeuron},'Centroid');
    if length(S) > 1
        S = S(1);
    end
    ROIxy(iNeuron,:) = [S.Centroid(1) S.Centroid(2)];
end

d = pdist(ROIxy,'euclidean'); % pairwise distance - pixel units
d = d*pixelSize; % pairwise distance - microns

R = R.*~eye(size(R)); % change diagonal values to zero for square form conversion
r = squareform(R); % convert R from square matrix to list form

% distcorr = corrcoef([d',r']);

[fig, ~] = plotCorrVsDist(d,r,clusterIdx);
% sgtitle(fig,sprintf('%s Spatial Correlation',corrType),'Fontsize',16,'Fontweight','bold');
% sgtitle(fig,sprintf('%s Spatial Correlation (R = %.2g)',corrType,distcorr(1,2)),'Fontsize',16,'Fontweight','bold');
% ylim([0 1]);

if savenum
    print(fig,'-vector','-dsvg',[saveFolder filesep 'Raw trace spatial correlations.svg']) % svg
end


function [fig, Rsq] = plotCorrVsDist(x,y,clusterIdx)

% y = abs(y); % compare magnitude correlation

x = reshape(x,[],1); % column vector
y = reshape(y,[],1); % column vector

% linear fit for all data
[yfit,Rsq] = linearfit(x,y);


% plot corr matrix
fontsize.title = 20;
fontsize.tick = 16;
fontsize.cbar = 14;
fontweight = 'bold';

nColors = max(clusterIdx);
colors = loadClusterColors(nColors); % my colors :D

% assign color to each cluster
% generate color for each cluster as mix for each pair

% i = n - 2 - floor(sqrt(-8*k + 4*n*(n-1)-7)/2.0 - 0.5);
% j = k + i + 1 - n*(n-1)/2 + (n-i)*((n-i)-1)/2;

Y = squareform(y);
[col, row] = triind2sub(size(Y), find(ones(size(Y))));
col = real(col(1:numel(y)));
row = real(row(1:numel(y)));


% linear fit for largest cluster 
largest_cluster = mode(clusterIdx); % most frequent cluster
clusterIdx1 = find(clusterIdx == largest_cluster); % indices of neurons in most frequent cluster

rowMaskAll = false(numel(y),1);
colMaskAll = false(numel(y),1);

% build mask for largest cluster
for iii = 1:numel(clusterIdx1)
    
    neuron = clusterIdx1(iii);

    rowMask = row == neuron; % neuron 1 indices in linear mask
    rowMaskAll = rowMaskAll | rowMask; % find all rows corresponding to cluster1
    colMask = col == neuron;
    colMaskAll = colMaskAll | colMask; % find all cols corresponding to cluster1

end

% linMask1 = rowMaskAll & colMaskAll; % pairs with both neurons in cluster1
% x1 = x(linMask1);
% y1 = y(linMask1);
% [yfit1,Rsq1] = linearfit(x1,y1);


fig = figure; 
hold on;
for ii = 1:numel(clusterIdx) % for each neuron
    maskRow = row == ii; % neuron index for first neuron in pair
    maskCol = col == ii; % neuron index for second neuron in pair
    cluster = clusterIdx(ii); % neuron cluster assignment
    color = colors(cluster,:); % cluster color

    h = scatter(x(maskRow),y(maskRow),8,color,'filled'); % plot cluster color for neuron 1 in pair
    alpha(h,.5)
    h2 = scatter(x(maskCol),y(maskCol),8,color,'filled'); % plot cluster color for neuron 2 in pair
    alpha(h2,.5)
end

han1 = plot(x,yfit,'-k','Linewidth',2,'DisplayName',sprintf('All data:   Rsq = %.3f',Rsq)); 
% han2 = plot(x1,yfit1,'-','Color',0.5*[1 1 1],'Linewidth',2,'DisplayName',sprintf('Cluster 1: Rsq = %.3f',Rsq1));
hold off;

legend(han1,'location','Northeast')
% legend([han1 han2],'location','Northeast')

xlabel('Pairwise Distance (μm)','Fontsize',fontsize.tick)
% ylabel('|R|','Fontsize',fontsize.tick)
ylabel('R','Fontsize',fontsize.tick)

if min(y) >= 0
    ymin = 0;
else
    ymin = -0.5;
end
% ylim([ymin 1])

ylim([-0.5 1]);

ax = gca;
ax.YAxis.FontSize = fontsize.tick;
ax.XAxis.FontSize = fontsize.tick;
ax.YAxis.FontWeight = fontweight;
ax.XAxis.FontWeight = fontweight;

drawnow;

    function [yfit,Rsq] = linearfit(x,y)
        % linear fit for all data
        X = [ones(length(x),1) x];
        b = X \ y;
        yfit = X*b; % linear fit
        Rsq = 1 - sum((y - yfit).^2)/sum((y - mean(y)).^2);

    end

end

end