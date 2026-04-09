function spikeGammaHeatMap(HistArray,bin_midpoints,saveFolder, savenum)
% plot spike probability for binned gamma cycles as heat map for each theta stim cycle 

[nSelected,nGammaBins] = size(HistArray);

tickfontsize = 16;

xvalues = bin_midpoints;
yvalues = 1:nSelected;

% % skip gamma cycle 0 column
% data = data(:,2:end);
% nGammaBins = size(data,2);
% xvalues = xvalues(2:end);

% setup sorting params
% columns = 1:nGammaBins; % sort by cycle 0 first
columns = 2:nGammaBins; % sort by cycle 1 first
nCols = numel(columns);
direction = 'descend';
directions = cell(1,nCols); % sort all columns by the same direction
[directions{1:nCols}] = deal(direction);

% sort by cluster with highest spike probability
HistArray = sortrows(HistArray,columns,directions);

HistArray = [HistArray; mean(HistArray,1)]; % add mean to bottom of heatmap
yvalues = [yvalues, nSelected+1]; % number of neurons + mean

% plot heatmap of gamma cycle spike probability for all neurons
factor = 10; % plot tick marks every factor
yTicks = factor*(1:1:floor(nSelected/factor)); % tick marks

fig = figure;
imagesc(xvalues,yvalues,HistArray);
yticks([yTicks, size(HistArray,1)]);
yticklabels([string(yTicks), "Avg"]);
colormap('hot');

xlabel('Gamma Cycle #');
ylabel('Neuron #');
title('Spike Rate (1/Gamma Bin/Theta Cycle)','Fontsize',tickfontsize,'Fontweight','bold');
colorbar('Fontsize',tickfontsize,'Fontweight','bold');
clim([0 1]);

ax = gca;
ax.YAxis.FontSize = tickfontsize;
ax.YAxis.FontWeight = 'bold';
ax.XAxis.FontSize = tickfontsize;
ax.XAxis.FontWeight = 'bold';

if savenum
    print(fig,'-vector','-dsvg',[saveFolder filesep 'Gamma Bin Heatmap.svg']) % svg
end

end