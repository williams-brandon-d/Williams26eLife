function R = plotCorrelationMatrix(selectNeurons,lfp,saveFolder,savenum)

% spatial analysis? 50 um bins? 
% need pixelsize in um - 

% find center of all ROIs
% perform pairwise correlations with both raw data and spike trains?

nSelected = numel(selectNeurons);

nSamples = numel(lfp.stim_indices_ds);

X = zeros(nSelected,nSamples);

corrType = 'dfoverf';

% build data matrix
for iNeuron = 1:nSelected   
    if isfield(selectNeurons{1},'noMotion_trace')
        trace = selectNeurons{iNeuron}.noMotion_trace;
    else
        trace = selectNeurons{iNeuron}.raw_trace;
    end
    meanF = mean(trace);
    trace = -1*(trace - meanF) / meanF; % normalize by mean
    X(iNeuron,:) = trace(lfp.stim_indices_ds);
end

% X = (X - mean(X(:))) / std(X(:));    % normalize by mean and std of all neurons???

X = X'; % samples by neurons

R = corrcoef(X); % correlation matrix: X - each column is a time series

fig = plotCorrMatrix(R,1:nSelected);
sgtitle(fig,sprintf('%s Correlation Matrix',corrType),'Fontsize',16,'Fontweight','bold');

if savenum
    print(fig,'-vector','-dsvg',[saveFolder filesep 'Raw trace correlation matrix.svg']) % svg
end


% function fig = plotCorrMatrix(R)
% 
% % plot corr matrix
% fontsize.title = 20;
% fontsize.tick = 16;
% fontsize.cbar = 14;
% fontweight = 'bold';
% 
% 
% fig = figure; 
% imagesc(R); 
% 
% %title('Correlation Matrix','Fontsize',fontsize.title,'Fontweight',fontweight);
% 
% colorbar('Fontsize',fontsize.cbar,'Fontweight',fontweight);
% if min(R) > 0
%     cmin = 0;
% else
%     cmin = -1;
% end
% clim([cmin 1])
% 
% xlabel('Neuron #','Fontsize',fontsize.tick)
% ylabel('Neuron #','Fontsize',fontsize.tick)
% 
% ax = gca;
% ax.YAxis.FontSize = fontsize.tick;
% ax.XAxis.FontSize = fontsize.tick;
% ax.YAxis.FontWeight = fontweight;
% ax.XAxis.FontWeight = fontweight;
% 
% end


% cycle by cycle correlations
% cycles = 1:5;
% 
% nCorrCycles = numel(cycles);
% 
% cycleCorr = zeros(2*(file.cycle_length)+1,nCorrCycles);
% lags = cycleCorr;
% 
% for iCycle = 1:nCorrCycles
%     cycle = cycles(iCycle);
%     cycle_start = file.cycle_start_index_noArtifacts(cycle);
%     cycle_stop = cycle_start + file.cycle_length; 
%     cell_data = file.cell.gamma_data(cycle_start:cycle_stop);
%     lfp_data = file.lfp.gamma_data(cycle_start:cycle_stop);
%     [cycleCorr(:,iCycle), lags] = xcorr(cell_data,lfp_data,'normalized');
% end
% 
% lags_ms = lags*file.dt*1000; % time in msec
% meanCycleCorr = mean(cycleCorr,2);
% [~,max_meanCorr_index] = max(meanCycleCorr,[],'ComparisonMethod','auto');
% max_meanLag = lags_ms(max_meanCorr_index);
% max_meanCorr = meanCycleCorr(max_meanCorr_index);
% 
% [max_peakCorr,max_peakCorr_index] = max(cycleCorr(:));
% [maxRow,maxCol] = ind2sub(size(cycleCorr),max_peakCorr_index);
% peakCorr_Lag = lags_ms(maxRow);
% maxCorr = cycleCorr(:,maxCol);
% 
% fontsize = loadFontSizes();
% fig = figure;
% plot(lags_ms,cycleCorr,'Color',0.5*[1 1 1])
% hold on
% plot(lags_ms,meanCycleCorr,'k','Linewidth',2)
% hold off
% axis([-50 50 -1 1]);
% box off
% set(gcf, 'Renderer', 'painters');
% ax = gca;
% ax.XAxis.FontSize = fontsize.tick;
% ax.XAxis.FontWeight = 'bold';
% ax.YAxis.FontSize = fontsize.tick;
% ax.YAxis.FontWeight = 'bold';   
% xlabel('Lag (ms)','FontSize',20,'FontWeight','bold');
% ylabel('Correlation Coeff.','FontSize',20,'FontWeight','bold');
% title(sprintf('Peak Corr. = %.2g    Lag = %.2g ms    ',max_meanCorr,max_meanLag),'FontSize',20,'FontWeight','bold');





end