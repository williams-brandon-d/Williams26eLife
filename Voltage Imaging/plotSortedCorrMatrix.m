function [HsortedIdx,sortedClusterIdx] = plotSortedCorrMatrix(R,coeff, saveFolder, savenum)

% Compute the distance matrix based on the correlation matrix (1 - correlation)
distMatrix = 1 - R;
distMatrix = squareform(distMatrix);

% Perform hierarchical clustering using the 'average' linkage method
Z = linkage(distMatrix, 'average');

% can use cluster function to find natural clusters using inconsistency cutoff or specify max number of clusters
I = inconsistent(Z);
% inconsistency is just a z score of linkage height: Y = Z(:,3) - mean(Z(:,3)) / std(Z(:,3))

% disp('Dendrogram Inconsistency coeffs:');
% disp(I(:,end)');

% choose inconsistency value cutoff for clustering
cutoff = 1.1; % if heights are greater than 1.1 std deviation from mean
% default depth for inconsistency, D = 2, evaluates inconsistent values by looking to a depth D below each node 
clusterAssignments = cluster(Z,Cutoff=cutoff,Criterion="inconsistent",depth=2);

% clustering by distance with a cutoff that is a percentage of max distance
% - is sensitive to outliers - remove outliers
% - also doesn't work well if largest distances are not well separated 
% cutoff = 0.7*max(Z(:,3)); % linkage distance cutoff for cluster assignment - same cutoff as color threshold on dendrogram
% clusterAssignments = cluster(Z,Cutoff=cutoff,Criterion="distance");

% use cophenetic correlation coefficient to evaluate performance - linkings (Z) should have a strong correlation with the distances
c = cophenet(Z,distMatrix);

% sort by optimal leaf order
leafOrder = optimalleaforder(Z,distMatrix);

leafOrder = flip(leafOrder);

% plot dendrogram
fig1 = figure;
% [H, ~,sortedIdx] = dendrogram(Z, 0);
% [H, ~,sortedIdx] = dendrogram(Z,0,reorder=leafOrder);
[h, ~,sortedIdx] = dendrogram(Z,0,reorder=leafOrder,Orientation="left");
set(h,LineWidth=2);
set(h,Color=[0 0 0]);

sortedClusterIdx = clusterAssignments(sortedIdx);

nColors = max(clusterAssignments);
colors = loadClusterColors(nColors); % my colors :D
colors = 0.8*colors; % darken colors

% reorder sortedClusterIdx
[~, ia ,~] = unique(sortedClusterIdx,'first');
newClusterIndices = sort(ia,'ascend');
reorderedClusterIdx = zeros(numel(sortedClusterIdx),1);
for iCluster = 1:nColors
    startIdx = newClusterIndices(iCluster);
    if iCluster == nColors
        stopIdx = numel(reorderedClusterIdx);
    else
        stopIdx = newClusterIndices(iCluster+1) - 1;
    end
    clusterSize = stopIdx-startIdx+1;
    reorderedClusterIdx(startIdx:stopIdx) = iCluster.*ones(clusterSize,1);
end

sortedClusterIdx = reorderedClusterIdx;

% change line colors if criterion is inconsistency cutoff
for iCluster = 1:nColors 
    yIndices = find(sortedClusterIdx == iCluster); % find y indices for cluster
    color = colors(iCluster,:);
    for i = 1:numel(h)
        ydata = h(i).YData;
        miny = min(ydata);
        maxy = max(ydata);
%         if numel(yIndices) == 1
%             if (floor(miny) == yIndices) || (ceil(maxy) == yIndices)
%                 set( h( i ), 'Color', color );
%             end
%         else
            if (miny >= min(yIndices)) && (maxy <= max(yIndices))
                set( h( i ), 'Color', color );
            end
%         end
    end
end

% % change line colors if criterion is distance cutoff
% for i = 1:numel(h)
%     xdata = h(i).XData;
%     if ~any(xdata > cutoff) % assign cluster colors to linkages below cutoff
%         ydata = floor(h(i).YData);
%         clusterNum = mode(sortedClusterIdx(ydata));
%         color = colors(clusterNum,:);
%         set( h( i ), 'Color', color );
%     else % not a cluster
%         set( h( i ), 'Color', [0 0 0] );
%     end
% end

% plot markers
markerSize = 25;
xmin = min(xlim);
hold on;
for iNeuron = 1:numel(sortedClusterIdx)
    scatter(xmin,iNeuron,markerSize,colors(sortedClusterIdx(iNeuron),:),'filled');
end
hold off;

ax = gca;
ax.YAxis.FontSize = 7;
ax.XAxis.FontSize = 16;
ax.YAxis.FontWeight = 'bold';
ax.XAxis.FontWeight = 'bold';
xlabel('Distance (1-R)','FontSize',16,'Fontweight','bold')
ylabel('Neuron #','FontSize',16,'Fontweight','bold');
title(sprintf('Cophenet Coefficient: %.2f',c));

HsortedIdx = flip(sortedIdx); % flip for corr matrix to align with dendrogram and plot traces

% Reorder the correlation matrix based on optimal leaf order
HsortedR = R(HsortedIdx, HsortedIdx);

fig2 = plotCorrMatrix(HsortedR,HsortedIdx);
sgtitle(fig2,'H-clust Sorted Correlation Matrix','Fontsize',16,'Fontweight','bold');


% sort correlation matrix based on magnitude of pc1 loadings
pc1 = abs(coeff(:,1));
[~,sortedIdx] = sort(pc1,'descend');

sortedR = R(sortedIdx, sortedIdx);

fig3 = plotCorrMatrix(sortedR,sortedIdx);
sgtitle(fig3,'PC1 Sorted Correlation Matrix','Fontsize',16,'Fontweight','bold');

HsortedIdx = flip(HsortedIdx); % flip back to normal



if savenum
    print(fig1,'-vector','-dsvg',[saveFolder filesep 'Sorted Correlation Matrix Dendrogram.svg']) % svg
    print(fig2,'-vector','-dsvg',[saveFolder filesep 'Hclust sorted correlation matrix.svg']) % svg
    print(fig3,'-vector','-dsvg',[saveFolder filesep 'PC1 sorted correlation matrix.svg']) % svg
end

end