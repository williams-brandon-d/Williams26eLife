function lfp = analyzeLFP(dataPath,printnum,savenum)

lfp.dataPath = dataPath;
lfp.savePath = [dataPath filesep 'Processed Data'];

% apply wide gamma filter at first then narrow based on peak gamma frequency

% filter params
lfp.gamma_bandpass = [60 120]; % Hz
lfp.filter_order = 4; % theta filter must be max order 4 - gamma can be higher

% first 10 imaging frames are removed due to shutter opening - fix offset in lfp 12.5ms @ 800Hz
lfp.offset_frames = 10;

% load LFP data from .abf file
lfpFileInfo = dir([dataPath,filesep,'*abf']);
[lfp.data,lfp.si,lfp.file_info] = abfload(fullfile(dataPath,lfpFileInfo.name),'start',0,'stop','e');

nChannels = size(lfp.data,2);

% check channels to see if they switched
if strcmp(lfpFileInfo.name,'24221010.abf') || strcmp(lfpFileInfo.name,'24314008.abf')
    lfp.lfp_data = squeeze(lfp.data(:,3,:));
    lfp.stim_data = squeeze(lfp.data(:,1,:));
    lfp.camera_data = squeeze(lfp.data(:,2,:));
else
    if nChannels == 3
        lfp.lfp_data = squeeze(lfp.data(:,1,:));
        lfp.stim_data = squeeze(lfp.data(:,2,:));
        lfp.camera_data = squeeze(lfp.data(:,3,:));
    else 
        lfp.lfp_data = squeeze(lfp.data(:,1,:));
        lfp.stim_data = squeeze(lfp.data(:,2,:));
        lfp.camera_data = [];
        lfp.nFrames = 0;
    end
end

lfp.lfp_data = lfp.lfp_data*1000; % convert to uV
lfp.data_units = 'µV'; % lfp data is converted to uV instead of mV
% lfp.data_units = char(lfp.file_info.recChUnits(1));

lfp.dt = lfp.si*(1e-6); % sampling interval (seconds)
lfp.Fs = 1/lfp.dt; % sampling frequency (Hz)

% get experimental params
backslash_index = strfind(lfp.file_info.protocolName,'\');
lfp.protocol_name = lfp.file_info.protocolName(backslash_index(end)+1:end-4);

lfp.led_input = lfp.file_info.DACEpoch.fEpochInitLevel(2);    

lfp.cycle_length = lfp.file_info.DACEpoch.lEpochPulsePeriod(2);
lfp.stim_freq = round(lfp.Fs / lfp.cycle_length); % Hz

if isfield(lfp.file_info, 'comment')
    lfp.comment = lfp.file_info.comment;
else 
    lfp.comment = 'no comment found';
end

% restrict lfp data to imaging time
if ~isempty(lfp.camera_data)
    [imaging_indices,lfp.nFrames] = getImagingIndices(lfp.camera_data,lfp.offset_frames,0);

    if ~isempty(imaging_indices)
        lfp.lfp_data = lfp.lfp_data(imaging_indices);
        lfp.stim_data = lfp.stim_data(imaging_indices);
        lfp.camera_data = lfp.camera_data(imaging_indices);
    end
end

% check for stim artefact


% construct time axis for plotting
nLFPsamples = size(lfp.lfp_data,1);
time = (0:nLFPsamples-1)*lfp.dt; % time in sec
lfp.time = time'; % column vector

% lfp.offset_mask = lfp.time > lfp.offset_frames / frame_rate;
% lfp.offset_time = (0:(length(lfp.time(lfp.offset_mask))-1))*lfp.dt;
% lfp.offset_shift = find(lfp.offset_mask, 1) - 1; 


% filter LFP data into theta and gamma frequency components

switch lfp.stim_freq % theta bandpass is changed based on stimulation frequency
    case 4
        lfp.theta_bandpass = [2 6]; % Hz
    case 8
        lfp.theta_bandpass = [4 12]; % Hz
    case 12
        lfp.theta_bandpass = [8 16]; % Hz      
    case 16
        lfp.theta_bandpass = [12 20]; % Hz
end

lfp.theta_data = filterData(lfp.lfp_data,lfp.Fs,lfp.theta_bandpass,lfp.filter_order);
lfp.gamma_data = filterData(lfp.lfp_data,lfp.Fs,lfp.gamma_bandpass,lfp.filter_order);

[x,y,z,lfp] = thetaCWT(lfp);

lfp.maxValues = getMaxValues(x,y,z);

figLFP = plotLFP(lfp);

sgtitle(figLFP,sprintf( '%s - Stim: %g Hz - LFP Gamma: %d Hz',dataPath,lfp.stim_freq,round(lfp.maxValues(2)) ),'FontWeight','bold','Interpreter','none');

lfp.peakStats = getXmaxPeakStats(x,y,z,lfp.maxValues(1));

figCWT = plotScalogram(x,y,z,"",lfp.maxValues,lfp.data_units);


% change gamma bandpass filter here based on CWT peak


if printnum == 1
    fprintf('Protocol: %s\n',lfp.protocol_name);
    fprintf('LED Input = %g mV\n',lfp.led_input);
    fprintf('Stim Frequency: %g Hz\n',lfp.stim_freq);
    fprintf('%s\n',lfp.comment);
    fprintf('LFP Gamma Frequency: %d Hz\n',round(lfp.maxValues(2)));
end

if savenum == 1
    % save LFP plot as different file types
%     saveas(figLFP,[dataPath filesep 'lfp.svg']);
    print(figLFP,'-vector','-dsvg',[lfp.savePath filesep 'lfp.svg']) % svg
    
    % save CWT scalogram as different file types
%     saveas(figCWT,[lfp.savePath filesep 'lfp scalogram.fig']);
%     exportgraphics(figCWT, [lfp.savePath filesep 'lfp scalogram.png'], 'ContentType', 'image', 'Resolution', 300);
    print(figCWT,'-vector','-dsvg',[lfp.savePath filesep 'lfp scalogram.svg']) % svg

    % set(gcf, 'Renderer', 'painters');
    % saveas(gcf,[dataPath filesep 'lfp scalogram.svg']);
end

lfp.dataPath = dataPath;

end
