function R = plotSpikeTrainCorrelationMatrix(spikes,lfp,saveFolder,savenum) 
% perform pairwise correlations with spike trains

% convolve spike train with guassian?
corrType = 'Spike Train';

nSelected = numel(spikes);
nSamples = numel(lfp.stim_indices_ds);
X = zeros(nSelected,nSamples);

% create gaussian filter
sigma = 2; % std in samples

sz = 6*sigma; % +- 3 sigma : length of gaussFilter vector
x = linspace(-sz / 2, sz / 2, sz);
gaussFilter = exp(-x .^ 2 / (2 * sigma ^ 2));
gaussFilter = gaussFilter / sum (gaussFilter); % normalize

% build data matrix
for iNeuron = 1:nSelected 
    spike_mask = [spikes(iNeuron).masks];
    % binary spike mask - correlations are very low - binary data likely
    % needs different distance metric (phi coefficient)
%     X(iNeuron,:) = spike_mask(lfp.stim_indices_ds);  
    % binned spike counts
    spike_mask_stim = spike_mask(lfp.stim_indices_ds);   
%     X(iNeuron,:) = spike_mask_stim;
    X(iNeuron,:) = conv(spike_mask_stim, gaussFilter, 'same'); % filter spike mask with gaussian
end

X = X'; % samples by neurons

% why mean subtract spke train data? - creates negative correlations
% X = X - mean(X,1); % center non-binary data

R = corrcoef(X); % correlation matrix: X - each column is a time series

% set nan values to zero - due to traces with no spikes
nanIdx = find(isnan(R));
R(nanIdx) = zeros(numel(nanIdx),1);

% replace diagonal values with 1
for i = 1:numel(diag(R))
    R(i,i) = 1;
end

fig = plotCorrMatrix(R,1:nSelected);
sgtitle(fig,sprintf('%s Correlation Matrix',corrType),'Fontsize',16,'Fontweight','bold');

if savenum
    print(fig,'-vector','-dsvg',[saveFolder filesep sprintf('%s correlation matrix.svg',corrType)]) % svg
end


end