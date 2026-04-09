% voltage imaging analysis post processing
% combine data from all FOVs
% script for comparing different theta frequencies across all FOVs

clear variables; close all; clc;
cd('D:/Matlab Files/'); % choose your current directory
addpath(genpath('./')); % add all folders and subfolders in cd to path

savenum = 1;

dataPath = 'D:/TICO Voltage Imaging Data/CaMK2-ChR2-Voltron Data/';

savePath = [dataPath 'Summary Figures/'];

sig = 'symbol';

dataTypes = {'phase','frequency','power'};
nTypes = numel(dataTypes);

% theta stimulation frequencies for analysis
stim_freqs = {'4 Hz','8 Hz','12 Hz','16 Hz'};
nFreqs = numel(stim_freqs);

dataCell = cell(nTypes,nFreqs);

for iFreq = 1:nFreqs
    stim_freq = stim_freqs{iFreq};
    
    % find all data folders that contain stim protocol
    foldernames = getFoldernames(dataPath,stim_freq);
    nFolders = numel(foldernames);
    fprintf('Number of Subfolders Found: %d\n',nFolders);
    
    dataArray = zeros(nFolders,nTypes);
    
    for iFolder = 1:nFolders
        fpath = foldernames{iFolder};
        fprintf('Folder %d: %s\n',iFolder,fpath);
            
        % load saved data
        saveFilename = [fpath filesep 'Processed Data.mat'];
        load(saveFilename,'lfp');
    
        % if data not found skip analysis
        if ~exist('lfp','var')
            disp('File does not contain lfp data.');
            continue;
        end
    
        % combine interspike firing rates: FRhistArray
        dataArray(iFolder,:) = reshape(lfp.maxValues,1,[]); % [phase frequency power]
        
        % LFP - compare across theta frequencies in the same plot
        % theta phase, gamma frequency, peak gamma power: lfp.maxValues
        % average number of gamma cycles: numel(lfp.gamma_start_indices_ds{end})
           
    end
    
    dataCell{1,iFreq} = dataArray(:,1); % phase
    dataCell{2,iFreq} = dataArray(:,2); % frequency
    dataCell{3,iFreq} = dataArray(:,3); % % power

end

for iType = 1:nTypes
    typeCell = dataCell(iType,:)';
    type = dataTypes{iType};

    % stats
    if nFreqs > 2
        saveFilename = [savePath sprintf('LFP %s combined stats.xlsx',type)];
        stats = myMultipleIndependentGroupStats(typeCell,stim_freqs,{''},saveFilename,savenum);
    else 
        stats.kw = [];
    end
    
    stats.kw.sig = sig;

    % setup y axis for plots
    switch type
        case 'phase'
            y.min = -pi;
            y.max = pi;
            y.dy = pi;
            y.ticks = y.min:y.dy:y.max;
            y.tickLabels = {'-π','0','π'};
            y.labelstring = 'Theta Phase';
            y.scale = 'linear';
        case 'frequency'
            y.min = 50;
            y.max = 150;
            y.dy = 50;
            y.ticks = y.min:y.dy:y.max;
            y.tickLabels = string(y.ticks);
            y.labelstring = 'Frequency (Hz)';
            y.scale = 'linear';   
        case 'power'
            y.min = 10^1;
            y.max = 10^3;
            y.ticks = 10.^(1:3);
            y.tickLabels = string(y.ticks);
            y.labelstring = 'Power (µV^2)';
            y.scale = 'log';
    end

    % get colors for different stim frequencies
    % colors = lines(nFreqs);
    colors = colormap('lines');
    colors = colors(1:nFreqs,:);
    
    alphas = ones(nFreqs,1);
    
    % plot all theta frequencies for comparison - boxplot/violin plots
    fig = myBoxplot(typeCell,stim_freqs,y,colors,alphas,struct);
    
    % setup stats in myBoxplot for 4 groups or just run 4,8,12 Hz
    
    if savenum
        print(fig,'-vector','-dsvg',[savePath filesep sprintf('LFP %s Boxplot.svg',type)]);
    end

end

function foldernames = getFoldernames(rootPath,pattern)
% find all subfolders that have .mat files excluding Processed Data folders
% could instead find all folders that have both .raw and .abf file and Processed Data.mat
filelist = dir(fullfile(rootPath, '**\*Processed Data.mat')); 

% find unique folders
foldernames = unique({filelist.folder})';

% only folders with pattern
foldernames = foldernames(contains(foldernames,pattern));

% if foldername contains pulse - remove
foldernames(contains(foldernames,'pulse','IgnoreCase',true)) = [];

% if foldername contains Bad data - remove
foldernames(contains(foldernames,'Bad data','IgnoreCase',true)) = [];
% if foldername contains lfp only - remove
foldernames(contains(foldernames,'LFP only','IgnoreCase',true)) = [];

end