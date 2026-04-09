%% read file
clear variables; close all; clc;

addpath(genpath('./'));
cd('D:/Matlab Files/');
folder = 'D:/';
depth = 30000;
% bin = 1;

dataPath = uigetdir(folder, 'Select a folder to read');
fileInfo = dir([dataPath,'\*raw']);
[~,idx] = sort([fileInfo.datenum]);fileInfo = fileInfo(idx);

% clear stack shifts stack2;
[stack, recordingInfo] = readKinetixRaw(fileInfo, depth);

if exist('recordingInfo','var') && isfield(recordingInfo, 'params')
    frame_rate = recordingInfo.params.frameRate;
end

% % convert stack to .tif for motion correction in NoRMcore
% [~,foldername,~] = fileparts(path);
% tifname = [path filesep foldername '.tif'];
% writeTiff(stack,tifname)

% % downsample by 10x for image registration and motion correction
% factor = 10;
% nFrames = size(stack,3);
% dsIdx = 1:factor:nFrames;
% shortStack = stack(:,:,dsIdx);

% monomodal if images are acquired by the same system
% [optimizer, metric]  = imregconfig('monomodal');
% rigid transformation translates and rotates the image
% tic; imReg = imregister(shortStack(:,:,2),shortStack(:,:,1),'rigid',optimizer, metric);toc; % would take 30 min for 159 images

% normCore motion correction supports .tif files

% tic;[devRow, devCol] = getRegistrationCoordinates(shortStack);toc; % also
% slow
% tic;regMov = makeRegisteredMovie(frames, devRow, devCol);toc;

% outfn = 'RegisteredMovie2.avi';
% writeRegisteredVideo(outfn, regMov)

% stack(:,:,1:1000) = [];

% if motion_correction && exist('ROImask','var')
%      [stack, shifts, ROImask] = registerStack(stack, ROImask);
%      %[stack, shifts, roi_window] = motionCorrection(stack, roi_window);
% elseif motion_correction && ~use_previous_roi
%      [stack, shifts, ROImask] = registerStack(stack);
%      %[stack, shifts, roi_window] = motionCorrection(stack);
% else
%     roi_window = [];shifts = [];
% end

%% load motion corrected data 

% [regfile,regPath] = uigetfile('*.mat');
% load(fullfile(regPath,regfile),'stack');
% slashIdx = strfind(regPath,filesep);
% dataPath = regPath(1:slashIdx(end-1));

averageFrame = double(mean(stack(:,:,1000:1050), 3)); % take an average frame
% try std for reference frame? more frames?
% motion might bias ROIs in averageFrame

meanImage = averageFrame;
shifts = [];

% load params
frame_rate = 800; % default frame rate
offset = 20; % for plotting
snr_thresh = 3; % for plotting
invert = true; % for voltron (negative going spikes)

%% select neuron ROIs

ROI_select = 'saved'; % manual, choose, saved

switch ROI_select
    case 'manual'
        [ROImask, ROIs] = selectROI(averageFrame, @drawpolygon);
        ROIs = rankROI(ROIs);
    case 'choose'
        [ROIfile,ROIpath] = uigetfile('*.mat','Select ROI File',dataPath);
       ROIvar = load(fullfile(ROIpath,ROIfile),'ROIs','ROImask','meanImage');
       ROIs = ROIvar.ROIs;
       ROImask = ROIvar.ROImask;
       ROIimage = ROIvar.meanImage;
    case 'saved'
    % load neuron struct
    saveFilename = [dataPath filesep 'Processed Data.mat'];
    load(saveFilename);
end

if strcmp(ROI_select,'manual') || strcmp(ROI_select,'choose')
    % create neuron struct from ROIs, ROImask, and stack
    N = length(ROIs);
    traces = zeros(size(stack, 3), N);
    stack2 = reshape(stack,[],size(stack,3));
    % neuron = {};
    neuron = cell(N,1);
    SE = strel("disk",5);
    
    for i = 1:N
        traces(:,i) = mean(stack2(ROIs{i},:),1);
        neuron{i}.raw_trace = traces(:, i);
        neuron{i}.edges = edge(ROIs{i});
        neuron{i}.mask = ROIs{i};
    
        surround = logical(imdilate(ROIs{i},SE) - ROIs{i});
        neuron{i}.meanBk = mean(stack2(surround(:),:),'all');
    end
end

if strcmp(ROI_select, 'saved')
    % get ROIs and ROImask from neuron struct
    N = length(neuron);
    ROIs = cell(1,N);
    traces = zeros(length(neuron{1}.raw_trace),N);
    [H,W] = size(neuron{1}.mask);
    ROImask = false(H,W);
    
    for i = 1:N
        ROIs{i} = neuron{i}.mask;
        traces(:,i) = neuron{i}.raw_trace;
        ROImask = ROImask | neuron{i}.mask;
    end
end
rawTraces = traces.*((-1)^(invert));

%% adjust for drift in ROIs across recordings with same FOV
% shift ROI centroids - use figure tool to choose drift adjustment with
% previous drawn ROIs

% register current averageFrame with ROI file averageFrame
% downsample_factor = 5; % x and y

% [driftY, driftX] = getRegistrationCoordinate(meanImage,ROIimage);

% manual adjustment
driftX = 0; % positive is right shift
driftY = 0; % positive is down shift 

adjustedROIs = ROIs;

[H,W] = size(ROIs{1});

xPad = abs(driftX);
yPad = abs(driftY);

% figure;
% imagesc(adjustedROIs{1});

for i = 1:N
    % cut off ROI if shifted beyond edge of Frame 
    padMask = false(H+2*yPad,W+2*xPad); % extend ROI mask
    padMask((1:H)+yPad,(1:W)+xPad) = adjustedROIs{i}; % center ROI with padded edges
%     figure;
%     imagesc(padMask);

    padMask = circshift(padMask,driftY,1); % shift ROI columns
    padMask = circshift(padMask,driftX,2); % shift ROI rows
%     figure;
%     imagesc(padMask);

    adjustedROIs{i} = padMask((1:H)+yPad,(1:W)+xPad); % keep original ROI frame
end

nAdjusted = length(adjustedROIs);

[H,W] = size(neuron{1}.mask);
adjustedROImask = false(H,W);
adjustedROIedges = cell(1,nAdjusted);
imEdge = mat2gray(meanImage);
imEdge_old = mat2gray(ROIimage);

for i = 1:nAdjusted
    adjustedROImask = adjustedROImask | adjustedROIs{i};
    adjustedROIedges{i} = edge(adjustedROIs{i});
    imEdge = imEdge + mat2gray(adjustedROIedges{i});
    imEdge_old = imEdge_old + mat2gray(adjustedROIedges{i});
end

figure('WindowState', 'maximized');
hold on
imshow(imEdge_old,'InitialMagnification','fit');
% title(sprintf('%s',dataPath),'Interpreter','none');
% for i = 1:nAdjusted
%     S = regionprops(adjustedROIs{i},'Centroid');
%     texthan = text(S.Centroid(1),S.Centroid(2), string(i),'HorizontalAlignment','Center');
%     set(texthan, 'Color', [1 1 1]);
% end
title('Previous ROI image with new ROI edges')
hold off


figure('WindowState', 'maximized');
hold on
imshow(imEdge,'InitialMagnification','fit');
% title(sprintf('%s',dataPath),'Interpreter','none');
% for i = 1:nAdjusted
%     S = regionprops(adjustedROIs{i},'Centroid');
%     texthan = text(S.Centroid(1),S.Centroid(2), string(i),'HorizontalAlignment','Center');
%     set(texthan, 'Color', [1 1 1]);
% end
title('ROIs adjusted for drift')
hold off



%% make ROI mask plot 
save_num = 0;
% selectTraceIdx = [2:6,8:15,17:19,21:26,32:36,40:45,48:51,53,55,56,58,61]; % 20231229-150748
% selectTraceIdx = [2,7,10,14,15,17,20,22,23,25,31:33,35,39,40]; % 20240130-152423
% selectTraceIdx = [1:5,8:11,13:15,17,19,21,25:30,33,34,37,39,42,46]; % 20240130-155853
% selectTraceIdx = [5,7,11,13:15,19:21,23:27,30:31,33:39,41:42,44,46,49:51];
% selectTraceIdx = [2:5 9:12 24 53];

% selectTraceIdx = [1 4:8 10:20 22 24 26:28 31 33 35 37];

% selectTraceIdx = 1:N;

if exist('adjustedROIs','var')
    ROIs = adjustedROIs;
end

selectedROIs = ROIs(selectTraceIdx);
nSelected = length(selectedROIs);

[H,W] = size(neuron{1}.mask);
selectedROImask = false(H,W);
selectedROIedges = cell(1,nSelected);
imEdge = mat2gray(meanImage);

for i = 1:nSelected
    selectedROImask = selectedROImask | selectedROIs{i};
    selectedROIedges{i} = edge(selectedROIs{i});
    imEdge = imEdge + mat2gray(selectedROIedges{i});
end

figure('WindowState', 'maximized');
hold on
imshow(selectedROImask,'InitialMagnification','fit');
% title(sprintf('%s',dataPath),'Interpreter','none');
for i = 1:nSelected
    S = regionprops(selectedROIs{i},'Centroid');
    if length(S) > 1
        S = S(1);
    end
    text(S.Centroid(1),S.Centroid(2),string(i),'HorizontalAlignment','Center')
end
hold off

if save_num == 1
    saveas(gcf,[dataPath filesep 'ROI mask.png']);
end

figure('WindowState', 'maximized');
hold on
imshow(imEdge,'InitialMagnification','fit');
% title(sprintf('%s',dataPath),'Interpreter','none');

for i = 1:nSelected
    S = regionprops(selectedROIs{i},'Centroid');
    texthan = text(S(1).Centroid(1),S(1).Centroid(2), string(i),'HorizontalAlignment','Center');
    set(texthan, 'Color', [1 1 1]);
end
hold off
if save_num == 1
    saveas(gcf,[dataPath filesep 'meanImage with ROIs.png']);
end

%% plot raw data

% rawTraces = traces.*((-1)^(invert));
figure;
for i = 1:N
    subplot(N,1,i)
%     plot(rawTraces(:,i) , 'k'); hold on,
    trace = rawTraces(:,i);
    meanTrace = mean(trace);
    dfoverf = (trace - meanTrace) / meanTrace;
    plot(dfoverf , 'k'); hold on,
end
hold off

%% motion correction

% [stack, shifts, ROImask] = registerStack(stack, ROImask);

%% plot raw voltage data and processed LFP

savenum = 0;
% selectTraceIdx = [2,36,4:6,8:15,17:19,21:26,32:35,2,40:45,48:51,53,55,56,58,61]; % 20231229-150748 traces were swapped for figure inset
% selectTraceIdx = [2,7,10,14,15,17,20,22,23,25,31:33,35,39,40]; % 20240130-152423
% selectTraceIdx = [1:5,8:11,13:15,17,19,21,25:30,33,34,37,39,42,46]; % 20240130-155853b
% selectTraceIdx = [5,7,11,13:15,19:21,23:27,30:31,33:39,41:42,44,46,49:51];
% selectTraceIdx = [3,4,8:11,15:20,22,24:34,37,51];
% selectTraceIdx = [2,6:10,13,15,16,18,19,21:23,26:38,40,42:45,47,48,50,53,55];

% selectTraceIdx = 1:N;

selectTraces = rawTraces(:,selectTraceIdx);
nSelected = numel(selectTraceIdx);

% detect spikes
spikes = struct();
spikes.peaks = cell(nSelected,1);
spikes.locs = cell(nSelected,1);
spikes.width = cell(nSelected,1);
spikes.prom  = cell(nSelected,1);

minpeakdist = 0.004; % seconds
minpeakwidth = 0.0015; % seconds
minpeakprom = 0.012; % dfoverf

% minpeakdist = 0.004; % seconds
% minpeakwidth = 0.001; % seconds
% minpeakprom = .5; % dfoverf
% threshold = 0; % dfoverf

hpf = 50;% Hz cutoff

for i = 1:nSelected 
%     % high pass filter data 
%     [b_hpf,a_hpf] = butter(2,hpf/(frame_rate/2),'high'); % hpf coefficients
%     hpf_data = filtfilt(b_hpf,a_hpf,selectTraces(:,i)); % hpf data
% 
%     hpf_data = (hpf_data - mean(hpf_data)) / std(hpf_data);
    traceIdx = selectTraceIdx(i);

    meanF = mean(selectTraces(:,i));
    dfoverf = -1*(selectTraces(:,i) - meanF) / meanF;
    minpeakheight = median(dfoverf);

    [peaks,locs,width,prom] = findpeaks(dfoverf,'MinPeakDistance',minpeakdist,'MinPeakProminence',minpeakprom,'MinPeakWidth',minpeakwidth,'MinPeakHeight',minpeakheight);
    % remove outliers
    outlierIdx = find( peaks < (mean(peaks) - 3*std(peaks)) );
    peaks(outlierIdx) = []; spikes.peaks{i} = peaks;
    locs(outlierIdx) = []; spikes.locs{i} = locs;
    width(outlierIdx) = []; spikes.width{i} = width;
    prom(outlierIdx) = []; spikes.prom{i} = prom;
end


% normalize traces and plot on the same axis for visualization
normTraces = zeros(size(selectTraces,1),size(selectTraces,2));
nSamples = size(selectTraces,1);
time = (0:nSamples-1)/frame_rate;

figure('WindowState', 'maximized');
for i = 1:nSelected
    trace = selectTraces(:,i);
    normTraces(:,i) =  (trace - min(trace)) / (max(trace) - min(trace));
    plotTrace = normTraces(:,i) + i - 0.5;
    plot(time,plotTrace, 'k','Linewidth',1); hold on, % plot trace
    plot(time(spikes.locs{i}),plotTrace(spikes.locs{i}),'or') % plot spikes
end
hold off
% ylabel("ROI #")
xlabel("Time (s)")

lfpFileInfo = dir([dataPath,'\*abf']);
fullname = fullfile(dataPath,lfpFileInfo.name);
[lfp.data,lfp.si,lfp.file_info] = abfload(fullname,'start',0,'stop','e');

nLFPsamples = size(lfp.data,1);

lfp.dt = lfp.si*(1e-6); % sampling interval (seconds)
lfp.Fs = 1/lfp.dt; % sampling frequency (Hz)
time = (0:nLFPsamples-1)*lfp.dt; % time in sec
time = time'; % column vector

backslash_index = strfind(lfp.file_info.protocolName,'\');
lfp.protocol_name = lfp.file_info.protocolName(backslash_index(end)+1:end-4);
fprintf('Protocol: %s\n',lfp.protocol_name)

% check channels to see if they switched
if strcmp(lfpFileInfo.name,'24221010.abf') || strcmp(lfpFileInfo.name,'24314008.abf')
    lfp.lfp_data = squeeze(lfp.data(:,3,:))*1000;
    lfp.stim_data = squeeze(lfp.data(:,1,:));
    lfp.camera_data = squeeze(lfp.data(:,2,:));
else
    lfp.lfp_data = squeeze(lfp.data(:,1,:))*1000;
    lfp.stim_data = squeeze(lfp.data(:,2,:));
    lfp.camera_data = squeeze(lfp.data(:,3,:));
end

lfp.led_input = lfp.file_info.DACEpoch.fEpochInitLevel(2);    
fprintf('LED Input = %g mV\n',lfp.led_input)

cycle_length = lfp.file_info.DACEpoch.lEpochPulsePeriod(2);
lfp.stim_freq = round(lfp.Fs / cycle_length); % Hz
fprintf('Stim Frequency: %g Hz\n',lfp.stim_freq)

if isfield(lfp.file_info, 'comment')
    lfp.comment = lfp.file_info.comment;
    fprintf('%s\n',lfp.comment)
else 
    lfp.comment = '';
end

data_units = char(lfp.file_info.recChUnits(1));
data_units = 'uV';

lfp.gamma_hpf = 50;
lfp.gamma_lpf = 150;
lfp.filter_order = 4;

if lfp.gamma_hpf > 0
    [b_hpf,a_hpf] = butter(lfp.filter_order,lfp.gamma_hpf/(lfp.Fs/2),'high'); % hpf coefficients
    hpf_data = filtfilt(b_hpf,a_hpf,lfp.lfp_data); % hpf data
else
    hpf_data = lfp.lfp_data;
end

if lfp.gamma_lpf > 0
    [b_lpf,a_lpf] = butter(lfp.filter_order,lfp.gamma_lpf/(lfp.Fs/2),'low');
    lpf_data = filtfilt(b_lpf,a_lpf,hpf_data);
else
    lpf_data = hpf_data;
end

lfp.gamma_data = lpf_data;

trace = lfp.gamma_data;
normLFP = (trace - min(trace)) / (max(trace) - min(trace));

% first 10 frames are skipped - fix offset in lfp 12.5ms @ 800Hz
offset_frames = 10;
offset_mask = time > offset_frames / frame_rate;
offset_time = (0:(length(time(offset_mask))-1))*lfp.dt;

hold on;
plot(offset_time,normLFP(offset_mask) - 0.5,'b','Linewidth',1);

switch lfp.stim_freq
    case 4
        lfp.theta_hpf = 2;
        lfp.theta_lpf = 6;
    case 8
        lfp.theta_hpf = 4;
        lfp.theta_lpf = 12;
    case 12
        lfp.theta_hpf = 8;
        lfp.theta_lpf = 16;        
    case 16
        lfp.theta_hpf = 12;
        lfp.theta_lpf = 20;
end

lfp.filter_order = 4;

if lfp.theta_hpf > 0
    [b_hpf,a_hpf] = butter(lfp.filter_order,lfp.theta_hpf/(lfp.Fs/2),'high'); % hpf coefficients
    hpf_data = filtfilt(b_hpf,a_hpf,lfp.lfp_data); % hpf data
else
    hpf_data = lfp.lfp_data;
end

if lfp.theta_lpf > 0
    [b_lpf,a_lpf] = butter(lfp.filter_order,lfp.theta_lpf/(lfp.Fs/2),'low');
    lpf_data = filtfilt(b_lpf,a_lpf,hpf_data);
else
    lpf_data = hpf_data;
end

lfp.theta_data = lpf_data;

trace = lfp.theta_data;
normLFP = (trace - min(trace)) / (max(trace) - min(trace));

hold on;
plot(offset_time,normLFP(offset_mask) - 1.5,'r','Linewidth',2);

% add stim indicator
trace = lfp.stim_data;
normStim = (trace - min(trace)) / (max(trace) - min(trace));
hold on;
plot(offset_time,normStim(offset_mask) - 2.5,'Color',[91, 207, 244] / 255,'Linewidth',2);
% han3 = fill(time(mask_indices),norm_stim(mask_indices),'b','DisplayName','Light');
% han3.FaceColor =  [91, 207, 244] / 255; % light blue
% han3.EdgeColor = han3.FaceColor;

if nSelected < 10
    yticks(-2:nSelected)
    yticklabels(["Stim","Theta","Gamma",string(1:nSelected)])
else
    traceTickMax = 5*floor(nSelected/5);
    traceTicks = [-2:1 5:5:traceTickMax];
    yticks(traceTicks);
    yticklabels([ "Stim","Theta","Gamma",string([1 5:5:traceTickMax]) ]);
end


ylim([-2.9, nSelected + 1])

nFrames = size(selectTraces,1);
frame_dt = 1/frame_rate;
xlim([0 (nFrames-1)*frame_dt])

ax = gca;
ax.XAxis.FontSize = 20;
ax.YAxis.FontSize = 10;
ax.XAxis.FontWeight = 'bold';
ax.YAxis.FontWeight = 'bold';

% switch lfp.stim_freq
%     case 4
%         xlim([0 5])
%     case 8
%         xlim([0 4])
%     case 16
%         xlim([0 2])
% end
% % xlim([-inf inf])
% % xlim([0 4])
box off

% title(sprintf('CaMK2-ChR2 %g Hz Stim',lfp.stim_freq))

% make scalogram for lfp 
wname = 'amor'; % 'morse' (default), 'amor', 'bump'
VoicesPerOctave = 32; % number of scales per octave
flimits = [0 300]; % frequency limits for wavelet analysis
freq_threshold = 0; % zero frequencies below threshold for scalograms

delta_phase = 2*pi/cycle_length;
cycle_phase = -pi:delta_phase:pi;
fb = cwtfilterbank('Wavelet',wname,'SignalLength',numel(cycle_phase),...
'FrequencyLimits',flimits,'SamplingFrequency',lfp.Fs,'VoicesPerOctave',VoicesPerOctave);

lpf_stim = filterStimData(lfp.stim_data,lfp.Fs,lfp.stim_freq);
norm_stim = normalizeStimData(lpf_stim);

% zero out pulse before theta stim
zeroEndTime = 0.5; % sec
maskTime = time < zeroEndTime;
norm_stim(maskTime) = min(norm_stim)*zeros(sum(maskTime),1);
% figure; plot(norm_stim)

cycle_start_index = getCycleStartIndices(norm_stim, cycle_length, time, 0);
nCycles = numel(cycle_start_index);

cycles = 1:nCycles;

% switch lfp.protocol_name
%     case {'Voltage_imaging_theta_stim_8Hz','Voltage_imaging_theta_stim_4Hz',...
%             'Voltage_imaging_theta_stim_12Hz','Voltage_imaging_theta_stim_16Hz'}
%         cycles = 1:nCycles;
%     case {'Voltage_imaging_theta_stim_8Hz_pulseStart','Voltage_imaging_theta_stim_4Hz_pulseStart',...
%             'Voltage_imaging_theta_stim_12Hz_pulseStart','Voltage_imaging_theta_stim_16Hz_pulseStart'}
%         cycles = 2:nCycles; % skip pulse for theta-gamma analysis
% end

for icycle = 1:numel(cycles)
       cycle = cycles(icycle);
       cycle_start = cycle_start_index(cycle);
       cycle_stop = cycle_start + cycle_length; 
       window_data_lfp = lfp.gamma_data(cycle_start:cycle_stop);

%        figure;
%        subplot(2,1,1)
%        plot(window_data_lfp)
%        subplot(2,1,2)
%        plot(norm_stim(cycle_start:cycle_stop))

       [wt,freq] = cwt(window_data_lfp,'FilterBank',fb);
       if icycle == cycles(1)
           z = abs( wt ).^2;
       else
           z = z + abs( wt ).^2;
       end
end
z = z / nCycles;

[x,y] = meshgrid(cycle_phase,freq);

maxValues = getMaxValues(x,y,z);
fprintf('LFP Gamma Frequency: %d Hz\n',round(maxValues(2)));
peakStats = getXmaxPeakStats(x,y,z,maxValues(1),flimits,freq_threshold);

title(sprintf('%s; Stim: %g Hz; LFP Gamma: %d Hz',dataPath,lfp.stim_freq,round(maxValues(2))))

if savenum == 1
    saveas(gcf,[dataPath filesep 'traces and lfp.fig']);
    saveas(gcf,[dataPath filesep 'traces and lfp.png']);
    saveas(gcf,[dataPath filesep 'traces and lfp.svg']);
    %print(gcf,'-vector','-dsvg',['D:\traces and lfp high res no labels swap traces','.svg']) % svg
    
    plotScalogram(x,y,z,"",maxValues,data_units);
    saveas(gcf,[dataPath filesep 'lfp scalogram.fig']);
    saveas(gcf,[dataPath filesep 'lfp scalogram.png']);
    % set(gcf, 'Renderer', 'painters');
    % saveas(gcf,[dataPath filesep 'lfp scalogram.svg']);
    
    % save data
    save([dataPath filesep 'Processed Data.mat'],'neuron','selectTraceIdx','ROIs','ROImask','meanImage','maxValues','lfp','spikes','-nocompression');
end

%% make spike - gamma phase plots

% get phase of stim, theta and gamma 
fs = lfp.Fs;

% use stim to window theta cycles for freq/phase analysis 

y = norm_stim;
z = hilbert(y);
phase = angle(z); % from -pi to pi
% freq = instfreq(y,fs,'Method','hilbert');
figure;
subplot(2,1,1)
plot(y)
% subplot(3,1,2)
% plot(freq)
subplot(2,1,2)
plot(phase)

y = lfp.theta_data;
z = hilbert(y);
phase = angle(z);
% freq = instfreq(y,fs,'Method','hilbert');
figure;
subplot(2,1,1)
plot(y)
% subplot(3,1,2)
% plot(freq)
subplot(2,1,2)
plot(phase)

y = lfp.gamma_data;
z = hilbert(y);
phase = angle(z);
% freq = instfreq(y,fs,'Method','hilbert');
figure;
subplot(2,1,1)
plot(y)
% subplot(3,1,2)
% plot(freq)
subplot(2,1,2)
plot(phase)

%% get spikes
snr_thresh = 0;

result = spike_detect_SNR_v4(selectTraces - offset, frame_rate, snr_thresh);
plot_results(result, neuron, averageFrame, frame_rate, recordingInfo);
sgtitle(path);


%% use findpeaks to get spike times
nSelected = numel(selectTraceIdx);
selectTraces = rawTraces(:,selectTraceIdx);

spikes = struct();
spikes.peaks = cell(nSelected,1);
spikes.locs = cell(nSelected,1);
spikes.width = cell(nSelected,1);
spikes.prom  = cell(nSelected,1);

minpeakdist = 0.004; % s
minpeakwidth = 0; % s
minpeakprom = 0; % raw photon count

for i = 1:nSelected 
    [spikes.peaks{i},spikes.locs{i},spikes.width{i},spikes.prom{i}] = findpeaks(selectTraces(:,i),'MinPeakDistance',minpeakdist,'MinPeakProminence',minpeakprom);
end



%% write stack as binary file
save(dataPath,'dataPath', 'meanImage', 'neuron', 'shifts', 'roi_window','recordingInfo','-nocompression');

%% read and process large files
dataPath = uigetdir(folder, 'Select a folder to read');
fileInfo = dir([dataPath,'\*raw']);
[~,idx] = sort([fileInfo.datenum]);fileInfo = fileInfo(idx);

% no motion correction
[neuron, traces, averageFrame, shifts] = extractTrace(fileInfo, ROIs, roi_window, 0);
%traces(8001:end,:) = [];
result = spike_detect_SNR_v4(traces.*((-1)^(invert)), frame_rate, snr_thresh);
plot_results(result, neuron, averageFrame, frame_rate, recordingInfo);
sgtitle(dataPath);drawnow;
save([dataPath,'-no_motion_correction'],'dataPath', 'meanImage', 'neuron', 'shifts', 'roi_window','recordingInfo','-nocompression');


[neuron, traces, averageFrame, shifts] = extractTrace(fileInfo, ROIs, roi_window, 1);
%traces(8001:end,:) = [];
result = spike_detect_SNR_v4((traces-20).*((-1)^(invert)), frame_rate, snr_thresh);
plot_results(result, neuron, averageFrame, frame_rate, recordingInfo);
sgtitle(dataPath);
figure;plot(abs(sqrt(shifts(:,1).^2 + shifts(:,2).^2)));title('Absolute motion');
save([dataPath,'-motion_corrected'],'dataPath', 'meanImage', 'neuron', 'shifts', 'roi_window','recordingInfo','-nocompression');


%% load mat file and make some plots
% invert = true;
% frame_rate = 800;
% offset = 100;
% snr_thresh = 3;
% N = length(neuron);
% traces = zeros(length(neuron{1}.raw_trace), N);
% ROIs = {};
% %figure;
% for i = 1:N
%     %subplot(8,ceil(N/8),i);
%     traces(:, i) = neuron{i}.raw_trace(:,1);
%     %traces([557336 595124], i) = nan;
%     while any(isnan(traces(:, i)))
%         traces(:, i) = fillmissing(traces(:, i), 'movmean',3);
%     end
% 
%     ROIs{end+1} = neuron{i}.mask;
%     %plot((traces(:,i)), 'k');hold on,
% end
% %traces(1:end-16000,:) = [];
% result = spike_detect_SNR_v4((traces - offset).*((-1)^(invert)), frame_rate, snr_thresh);
% plot_results(result, neuron, meanImage, frame_rate, recordingInfo);
%%

% fid = fopen([path,'\registered.raw'],'w');
% fwrite(fid,stack,'uint16');
% fclose(fid);

%% functions

function lpf_stim = filterStimData(mean_stim_data,Fs,stim_freq)

    stim_lpf_fc = stim_freq*10; % Hz cutoff freq for filtering theta stim
    stim_lpf_order = 2;

    [b,a] = butter(stim_lpf_order,stim_lpf_fc/(Fs/2),'low'); % 
    lpf_stim = filtfilt(b,a,mean_stim_data);
end

function norm_stim = normalizeStimData(stim_data)
    min_stim = min(stim_data);
    max_stim = max(stim_data);
    norm_stim = (stim_data - min_stim)/(max_stim - min_stim); % norm values from 0 to 1
end

function cycle_start_index = getCycleStartIndices(norm_stim, cycle_length, time, stim_plotnum )
    prom = (max(norm_stim)-min(norm_stim))/2;
    dist = 1000; % samples

    [~, min_locs] = findpeaks(-1*norm_stim,'MinPeakProminence',prom,'MinPeakDistance',dist);
    [~, max_locs] = findpeaks(norm_stim,'MinPeakProminence',prom,'MinPeakDistance',dist);

    stim_start_index = min_locs(1) - cycle_length;

    first_cycle_end = min_locs(1);
    first_cycle_start = first_cycle_end - cycle_length;
    last_cycle_end = min_locs(end) + cycle_length;
    nStimCycles = floor((last_cycle_end - first_cycle_start)/cycle_length);
    last_cycle_start = first_cycle_start + (nStimCycles-1)*cycle_length;

    cycle_start_index = first_cycle_start:cycle_length:last_cycle_start;

    if stim_plotnum == 1
        plotType = 2;
        min_peaks = norm_stim(min_locs);
        max_peaks = norm_stim(max_locs);
        min_time_peaks = time(min_locs);
        max_time_peaks = time(max_locs);
        switch plotType
            case 1
                figure; 
                plot(time,norm_stim,min_time_peaks,min_peaks,'ok',...
                    max_time_peaks,max_peaks,'or')
            case 2
                time_start = time(stim_start_index);
                stim_start = norm_stim(stim_start_index);
                time_windows_start = time(cycle_start_index);
                stim_windows_start = norm_stim(cycle_start_index);
                figure;
                plot(time,norm_stim,min_time_peaks,min_peaks,'ok',...
                    max_time_peaks,max_peaks,'or',...
                    time_start,stim_start,'xg',...
                    time_windows_start,stim_windows_start,'xm')
        end
    end
end

function plotScalogram(x,y,z,plotTitle,maxValues,data_units)
    fontsize = loadFontSizes();
    figure;
    surf(x,y,z)
    shading interp
    view(0,90)
    hcb = colorbar('Fontsize',fontsize.cbar,'Fontweight','bold');
    title(hcb,sprintf('Power (%s^2)',data_units),'FontSize',fontsize.cbar,'FontWeight','bold') 
    xlim([-inf inf])
    ylim([-inf inf])
%     clim([0 1595])
    colormap('hot')
    ax = gca;
    ax.YAxis.FontSize = fontsize.tick;
    ax.XAxis.FontSize = fontsize.tick;
    xlabel('Phase (rad)','Fontsize',20)
    ylabel('Frequency (Hz)','Fontsize',20)
    ax.YAxis.FontWeight = 'bold';
    ax.XAxis.FontWeight = 'bold';
    if nargin > 3
%         title(plotTitle,'FontSize',fontsize.title,'Interpreter','none')
    end
    if nargin > 4
        hold on
%         plot3(maxValues(1),maxValues(2),maxValues(3),'xb')
        hold off
    end
end

function fontsize = loadFontSizes()
fontsize.title = 20;
fontsize.xlabel = 20;
fontsize.ylabel = 12;
fontsize.tick = 12;
fontsize.cbar = 12;
end

