function fig = plotCorrMatrix(R,sortedIdx)

if isempty(sortedIdx)
    sortedIdx = 1:length(R);
end

% plot corr matrix
fontsize.title = 20;
fontsize.tick = 8;
fontsize.cbar = 14;
fontweight = 'bold';


fig = figure; 
imagesc(R); 

%title('Correlation Matrix','Fontsize',fontsize.title,'Fontweight',fontweight);

colormap('parula')
colorbar('Fontsize',fontsize.cbar,'Fontweight',fontweight);

if min(R,[],'all') >= 0
    cmin = 0;
else
%     cmin = -1;
    cmin = min(R,[],'all');
end
clim([cmin 1])

ticks = 1:length(R);
yticks(ticks);
yticklabels(string(sortedIdx));
xticks(ticks);
xticklabels(string(sortedIdx));

ax = gca;
ax.YAxis.FontSize = fontsize.tick;
ax.XAxis.FontSize = fontsize.tick;
ax.YAxis.FontWeight = fontweight;
ax.XAxis.FontWeight = fontweight;

xlabel('Neuron #','Fontsize',16,'FontWeight','bold')
ylabel('Neuron #','Fontsize',16,'FontWeight','bold')

end