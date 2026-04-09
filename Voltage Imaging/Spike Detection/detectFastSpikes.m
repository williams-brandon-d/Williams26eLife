function spikes = detectFastSpikes(selectNeurons, frame_rate)
% detect spikes
nSelected = numel(selectNeurons);
nFrames = numel(selectNeurons{1}.raw_trace);

% initialize struct
spikes = struct();
spikes.peaks = cell(nSelected,1);
spikes.locs = cell(nSelected,1);
spikes.width = cell(nSelected,1);
spikes.prom  = cell(nSelected,1);

spikes.dt = (1/frame_rate);
spikes.time = (0:nFrames-1)*spikes.dt;

% set params for spike detection
minpeakdist = 2; % samples
minpeakwidth = 0; % samples
maxpeakwidth = 5; % samples

% minpeakprom = 0.012; % dfoverf

minpeakprom = 0; % dfoverf

% minpeakdist = 0.004; % seconds
% minpeakwidth = 0.001; % seconds
% minpeakprom = .5; % dfoverf
% threshold = 0; % dfoverf

hpf = 50; % Hz cutoff - filter out subthreshold activity

for i = 1:nSelected 

    trace = selectNeurons{i}.raw_trace;

    % determine baseline noise in each trace - after stim
    

    meanF = mean(trace);
    dfoverf = -1*(trace - meanF) / meanF;

    % high pass filter data 
    [b_hpf,a_hpf] = butter(2,hpf/(frame_rate/2),'high'); % hpf coefficients
    dfoverf = filtfilt(b_hpf,a_hpf,dfoverf); % hpf data

%     hpf_data = (hpf_data - mean(hpf_data)) / std(hpf_data);

    minpeakheight = mean(dfoverf) + 1.5*std(dfoverf);

    [peaks,locs,width,prom] = findpeaks(dfoverf,'MinPeakDistance',minpeakdist,'MinPeakProminence',minpeakprom,'MinPeakWidth',minpeakwidth,'MaxPeakWidth',maxpeakwidth,'MinPeakHeight',minpeakheight);

%     % remove outliers
%     outliers = zeros(numel(peaks),1);
%     outliers = peaks < (mean(peaks) - 3*std(peaks));
%     outliers  = outliers && (width );
%     outlierIdx = find( outliers );
%     peaks(outlierIdx) = [];   
%     locs(outlierIdx) = [];
%     width(outlierIdx) = [];
%     prom(outlierIdx) = [];

    spikes.peaks{i} = peaks;
    spikes.locs{i} = locs;
    spikes.width{i} = width;
    spikes.prom{i} = prom;

    mask = false(nFrames,1);
    mask(locs) = 1;
    spikes.masks{i} = mask;
end

end