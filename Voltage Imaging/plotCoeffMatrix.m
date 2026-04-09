function fig = plotCoeffMatrix(coeff,nPCs,sortedIdx)

if isempty(sortedIdx)
    sortedIdx = 1:size(coeff,1);
    fontsize.ytick = 8;
else
    fontsize.ytick = 8;
end

% plot corr matrix
fontsize.title = 20;
fontsize.xtick = 16;
fontsize.cbar = 14;
fontweight = 'bold';


fig = figure; 
imagesc(coeff(:,1:nPCs)); 
set(gca, 'YDir','normal'); % flip y direction

colorbar('Fontsize',fontsize.cbar,'Fontweight',fontweight);
%     clim([-1 1])

ticks = 1:numel(sortedIdx);
yticks(ticks);
yticklabels(string(sortedIdx));

ax = gca;
ax.YAxis.FontSize = fontsize.ytick;
ax.XAxis.FontSize = fontsize.xtick;
ax.YAxis.FontWeight = fontweight;
ax.XAxis.FontWeight = fontweight;

xlabel('Principal Component #','Fontsize',fontsize.xtick,'FontWeight','bold')
ylabel('Neuron #','Fontsize',fontsize.xtick,'FontWeight','bold')
title('PC Loadings','FontSize',fontsize.title)

end