function [out,fig] = plotallCyclePSD(data,Fs,cycle_start_indices,cycle_length,PSDtype,data_units,plotnum)
% plot PSDs each theta cycle of raw lfp data

% find peak in gamma range with the greatest prominence 

gamma_range = [60 200];

% params for interpolation
flimits = [0 250];
df = 1;
freq = flimits(1):df:flimits(2);

% params for mtftt
ntapers = 3;

nCycles = numel(cycle_start_indices);

data_all = zeros(nCycles*cycle_length,1);

for iCycle = 1:nCycles
    % array indices
    start_index = (iCycle-1)*cycle_length + 1;
    stop_index = start_index + cycle_length - 1;
    
    % raw data indices
    cycle_indices = cycle_start_indices(iCycle) + (0:cycle_length-1);
    
    % raw data
    data_all(start_index:stop_index) = data(cycle_indices)'; % samples x trials

end

switch PSDtype
    case 'pwelch'
        % when using 50% overlap between cycles - you need to include an
        % extra half window of data after if you want nwin = cycle_length
        data_pad = reshape(data(stop_index+1+(0:(cycle_length-1))),[],1);
        data_all = [data_all;data_pad];
        [S,freq] = welchPSD(data_all,Fs,2*nCycles,freq);
    case 'mtspec'
        [S,freq] = mtspecPSD(data,Fs,ntapers,freq);
end

% S = 10*log10(S); % dB

% find gamma range
gamma_mask = (freq >= gamma_range(1) & freq <= gamma_range(2));

gamma_start_index = find(gamma_mask,1);

% find most prominent gamma peak
[~, peak_indices,~,peak_proms] = findpeaks(S(gamma_mask));
[~,maxPromIdx] = max(peak_proms);
max_gamma_idx = peak_indices(maxPromIdx);

max_index = gamma_start_index + max_gamma_idx - 1;
max_gamma_freq = freq(max_index);
max_gamma_power = S(max_index);

% sum gamma power +- 15 Hz from the peak
half_bandwidth = 15; % Hz
nHalf = half_bandwidth/df; % number of samples
sum_gamma_power = sum(S(max_index-nHalf:max_index+nHalf));


if plotnum
    tickfontsize = 15;
    
    % plot spectra
    fig = figure;
    hold on
    plot(freq,S,'-k','LineWidth',1.5)
    yLim = ylim;
    if ~isempty(max_gamma_power)
        plot([max_gamma_freq max_gamma_freq],[yLim(1) max_gamma_power],'--b');
    end
    hold off
    xlabel('Frequency (Hz)');
    ylabel(sprintf('PSD (%s^{2}/Hz)',data_units));
    % ylabel('PSD (dB)');
    xlim(gamma_range);
    title(sprintf('Peak Gamma: %d Hz',max_gamma_freq),'FontSize',12);
    box off
    ax = gca;
    ax.YAxis.FontSize = tickfontsize;
    ax.YAxis.FontWeight = 'bold';
    ax.XAxis.FontSize = tickfontsize;
    ax.XAxis.FontWeight = 'bold';
else
    fig = [];
end

out.type = PSDtype;
out.S_all = S;
out.f_all = freq;
out.sum_gamma_power_all = sum_gamma_power;
out.max_gamma_power_all = max_gamma_power;
out.max_psd_gamma_freq_all = max_gamma_freq;

end