function [HistArray,bin_midpoints] = spikeGamma(spikeMasks, lfp, saveFolder, savenum)

nSelected = numel(spikeMasks);
nCycles = numel(lfp.cycle_start_indices_ds);

gamma_cycle = cell(nSelected,1);

for iNeuron = 1:nSelected 
    spike_mask = spikeMasks{iNeuron};
    spike_mask_stim = spike_mask(lfp.stim_indices_ds); % restrict time axis to stimulation period 
    gamma_cycle{iNeuron} = lfp.gamma_cycle_bins(spike_mask_stim);
end

% find empty cells
emptyCells = cellfun(@isempty,gamma_cycle);

% plot histogram of average
maxbins = max(cellfun(@max,gamma_cycle(~emptyCells)));
minbins = min(cellfun(@min,gamma_cycle(~emptyCells)));

edges = minbins-0.5:maxbins+0.5;
bin_midpoints = minbins:maxbins;
nbins = numel(bin_midpoints);

tickfontsize = 16;
titlefontsize = 16;

% could plot mean+-sem instead

HistArray = zeros(nSelected,nbins);

Color = [0 0 0];

fig = figure;
hold on;

for i = 1:nSelected 

    spikes_gamma = gamma_cycle{i};

    [HistArray(i,:),~] = histcounts(spikes_gamma,edges);

end

HistArray = HistArray / nCycles;

if ~isempty(HistArray)

    % plot SEM
    meanData = mean(HistArray,1);
    SEM = std(HistArray,1) ./ sqrt(size(HistArray,1));
    meanData = reshape(meanData,1,[]); % column vector
    SEM = reshape(SEM,1,[]); % column vector
    xSEM = [bin_midpoints fliplr(bin_midpoints)] ;         
    ySEM = [meanData+SEM fliplr(meanData-SEM)];

    han1 = fill(xSEM,ySEM,Color);
    han1.FaceColor = Color;    
    han1.FaceAlpha = 0.4;      
    han1.EdgeColor = 'none'; 
    drawnow;

    % plot mean
    plot(bin_midpoints,meanData,'Color',Color);

end

hold off
xlim([minbins-0.5 maxbins+0.5])
ylim([0 1])

xlabel('Gamma Cycle Bins')
ylabel('Spike Rate') % (1/Gamma Bin/Theta Cycle)

[~,folderName,~] = fileparts(lfp.dataPath);
plotTitle = sprintf( '%s - Stim: %g Hz',folderName,lfp.stim_freq );
sgtitle(plotTitle,'FontSize',titlefontsize,'FontWeight','bold','Interpreter','none');

ax = gca;
ax.YTick = 0:0.2:1;
ax.YAxis.FontSize = tickfontsize;
ax.YAxis.FontWeight = 'bold';
ax.XAxis.FontSize = tickfontsize;
ax.XAxis.FontWeight = 'bold';

if savenum == 1
    saveName = 'Spike-Gamma Histogram';
    print(fig,'-vector','-dsvg',[saveFolder filesep saveName '.svg']) % svg
end

end