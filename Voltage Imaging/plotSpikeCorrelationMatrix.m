function R = plotSpikeCorrelationMatrix(spikes,lfp,saveFolder,savenum) 
% perform pairwise correlations with and spike trains

nSelected = numel(spikes);

% nSamples = numel(lfp.stim_indices_ds);
% X = zeros(nSelected,nSamples);

corrType = 'Spike Rate';

frame_rate = 800;
bin_width = 0.125; % ms
bin_width_samples = frame_rate*bin_width;
num_bins = floor(length(lfp.stim_indices_ds) / bin_width_samples);
X = zeros(nSelected,num_bins);

% build data matrix
for iNeuron = 1:nSelected 
    spike_mask = [spikes(iNeuron).masks];
    % binary spike mask - correlations are very low - binary data likely
    % needs different distance metric (phi coefficient)
%     X(iNeuron,:) = spike_mask(lfp.stim_indices_ds);  
    % binned spike counts
    spike_mask_stim = spike_mask(lfp.stim_indices_ds);   
    X(iNeuron,:) = sum(reshape(spike_mask_stim(1:num_bins*bin_width_samples), bin_width_samples, []), 1);
end

X = X'; % samples by neurons

X = X - mean(X,1); % center non-binary data

R = corrcoef(X); % correlation matrix: X - each column is a time series

fig = plotCorrMatrix(R,1:nSelected);
sgtitle(fig,sprintf('%s Correlation Matrix',corrType),'Fontsize',16,'Fontweight','bold');

if savenum
    print(fig,'-vector','-dsvg',[saveFolder filesep sprintf('%s correlation matrix.svg',corrType)]) % svg
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
% colorbar('Fontsize',fontsize.cbar,'Fontweight',fontweight);
% %     clim([0 1595])
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


end