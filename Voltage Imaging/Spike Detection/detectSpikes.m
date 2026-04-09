function [spikes,selectNeurons] = detectSpikes(selectNeurons, frame_rate, lfp)
% detect spikes in voltage imaging data

nSelected = numel(selectNeurons);
nFrames = numel(selectNeurons{1}.raw_trace);

spikes = struct(); % initialize struct

% set params for spike detection
minpeakdist = 2; % samples @ 800 Hz = 3.75 ms (3)
minpeakwidth = 0; % samples - no min (0)
maxpeakwidth = 6; % samples @ 800 Hz = 10 ms (8 - half prom)

minpeakprom = 0.0075; % dfoverf (0.005)

hpf_fc = 50; % Hz cutoff - filter out subthreshold activity - decrease to 30 Hz to better detect bursty spikes
hpf_order = 4; % will be doubled by zero phase filter

for i = 1:nSelected 

    trace = selectNeurons{i}.raw_trace;

    % convert F to dF/F
%     meanF = mean(trace);
%     dfoverf = -1*(trace - meanF) / meanF;


    % filter out slow movement less than theta frequency 
    [b_hpf,a_hpf] = butter(1,[0.1 3]/(frame_rate/2),'stop'); % hpf coefficients
    noMotion = filtfilt(b_hpf,a_hpf,trace); % forward and reverse filtering - zero phase but double the filter order 
    dfoverf_noMotion = -1*(noMotion - mean(noMotion)) / mean(noMotion);

    % high pass filter data 
    [b_hpf,a_hpf] = butter(hpf_order,hpf_fc/(frame_rate/2),'high'); % hpf coefficients
    hpf_data = filtfilt(b_hpf,a_hpf,dfoverf_noMotion); % forward and reverse filtering - zero phase but double the filter order 

    % normalize from 0 to 1 for spike detection?

    % calculate noise based on 0.1 seconds after stim - test this
    if ~isempty(lfp) % may contain spikes
        noise_length = 0.1; % seconds
        noise_start = lfp.stim_indices_ds(end) + 1; % immediately after stim off
        noise_stop = noise_start + noise_length*frame_rate - 1; % start + length of noise window
        
        noise_data = dfoverf_noMotion(noise_start:noise_stop); % noise data
        noise_data = detrend(noise_data); % remove trend
        noise_std = std(noise_data(noise_data < 0)); % downward
        minpeakheight = 2*noise_std; % + mean(noise_data);
%         minpeakheight = 4*noise_std;
    else
        minpeakheight = 2*std(hpf_data); % will contain spikes
    end
    


    [peaks,locs,width,prom] = findpeaks(hpf_data,'MinPeakDistance',minpeakdist,'MinPeakProminence',minpeakprom, ...
        'MinPeakWidth',minpeakwidth,'MaxPeakWidth',maxpeakwidth,'MinPeakHeight',minpeakheight,'WidthReference','halfheight');

%     [peaks,locs,width,prom] = findpeaks(hpf_data,'MinPeakDistance',minpeakdist, ...
%         'MinPeakWidth',minpeakwidth,'MaxPeakWidth',maxpeakwidth,'MinPeakHeight',minpeakheight,'WidthReference','halfheight');

%     % if motion
%     [peaks,locs,width,prom] = findpeaks(dfoverf_noMotion,'MinPeakDistance',minpeakdist,'MinPeakProminence',minpeakprom, ...
%         'MinPeakWidth',minpeakwidth,'MaxPeakWidth',maxpeakwidth,'MinPeakHeight',minpeakheight,'WidthReference','halfheight');

    % estimate noise from spike removed trace
    % replace dfoverf(spike time +- spike width) = zero (mean of hpf trace)
    F_nospike = reshape(hpf_data,[],1);

    nSpikes = numel(locs);

    for iSpike = 1:nSpikes
        spike_loc = locs(iSpike);
        spike_width =  ceil(width(iSpike));
        start = max(spike_loc - spike_width,1);
        stop = min(spike_loc + spike_width,nFrames);
        indices = start:stop;
        F_nospike(indices) = zeros(numel(indices),1);
    end

    std_noise = std(F_nospike);

    % calculate SNR from spike amplitude and noise peaks or prominence?
    spikes(i).SNRpeak = mean(peaks) / std_noise;
    spikes(i).SNRprom = mean(prom) / std_noise;
    spikes(i).stdNoise = std_noise;

    % remove spikes that are not greater than 3*std_noise
    removeMask = (peaks < 3.5*std_noise) ;
    peaks(removeMask) = [];   
    locs(removeMask) = [];
    width(removeMask) = [];
    prom(removeMask) = [];

    % save spike info
    spikes(i).peaks = peaks;
    spikes(i).locs = locs;
    spikes(i).width = width;
    spikes(i).prom = prom;

    % save spike mask
    mask = false(nFrames,1);
    mask(locs) = 1;
    spikes(i).masks = mask;

    % save filtered traces
    selectNeurons{i}.hpf_trace = hpf_data;
    selectNeurons{i}.nospike_trace = F_nospike;
    selectNeurons{i}.noMotion_trace = dfoverf_noMotion;
end

end