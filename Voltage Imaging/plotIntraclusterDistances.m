% voltage imaging analysis post processing
% combine data from all FOVs
% script for comparing different theta frequencies across all FOVs

% analyze intracluster distances in raw voltage clustering vs spikes
% plot histograms, cdfs or compare violins

clear variables; close all; clc;
cd('D:/Matlab Files/'); % choose your current directory
addpath(genpath('./')); % add all folders and subfolders in cd to path

savenum = 1;

% dataPath = 'D:/TICO Voltage Imaging Data/CaMK2-ChR2-Voltron Data/'; % all folders
dataPath = "D:/TICO Voltage Imaging Data/CaMK2-ChR2-Voltron Data/03-14-2024 ChR2-Voltron-27/slice2/fov2/20240314-170853 - 8 Hz"; % test

savePath = 'D:/TICO Voltage Imaging Data/CaMK2-ChR2-Voltron Data/Summary Figures/';

sig = 'symbol';

% theta stimulation frequencies for analysis
% stim_freqs = {'4 Hz','8 Hz','12 Hz','16 Hz'};
stim_freqs = {'8 Hz'};

CorrTypes = {'raw','spikes'};

nFreqs = numel(stim_freqs);
nCorrTypes = numel(CorrTypes);

for iFreq = 1:nFreqs
    stim_freq = stim_freqs{iFreq};
    
    % find all data folders that contain stim protocol
    foldernames = getFoldernames(dataPath,stim_freq);
    nFolders = numel(foldernames);
    fprintf('Number of Subfolders Found: %d\n',nFolders);

    dist = cell(nFolders,nCorrTypes);
            
    for iFolder = 1:nFolders
        fpath = foldernames{iFolder};
        fprintf('Folder %d: %s\n',iFolder,fpath);
            
        % load saved data
        saveFilename = [fpath filesep 'Processed Data.mat'];
        load(saveFilename,'spikeLFP');
    
        % if data not found skip analysis
        if ~exist('spikeLFP','var')
            disp('File does not contain spikeLFP data.');
            continue;
        end
    
        % load intracluster distances
        for iCorr = 1:nCorrTypes
            type = CorrTypes{iCorr};
            % calculate or load distances
            dist{iFolder,iCorr} = spikeLFP.intraDist.(type);
%             clusterIdx = spikeLFP.clusterIdx.(type);
%             sortedIdx = spikeLFP.sortedIdx.(type);
        end
   
    end
    
    % linearize data for all folders in each corr type
    Dist = cell(nCorrTypes,1);
    for iCorr = 1:nCorrTypes
        Dist{iCorr} = cell2mat(dist(:,iCorr)); % concatenate column vectors
    end

    % stats
    if nCorrTypes > 1
        saveFilename = [savePath 'Intracluster Distance stats.xlsx'];
        stats = myMultipleIndependentGroupStats(Dist,CorrTypes,'',saveFilename,savenum);
    else 
        stats.rs = [];
    end
    
    stats.rs.sig = sig;
    
    % setup y axis for violin plots
    y.min = 0;
    y.max = 500;
    y.dy = 100;
    y.ticks = y.min:y.dy:y.max;
    y.tickLabels = string(y.ticks);
    y.labelstring = 'Intracluster Distance (μm)';
    y.scale = 'linear';
    
    % get colors for different stim frequencies
    % colors = lines(nFreqs);
    colors = colormap('lines');
    colors = colors(1:nCorrTypes,:);
    
    alphas = ones(nFreqs,1);
    
    % plot corrTypes for comparison - boxplot/violin plots
    fig = plotViolin(Dist,CorrTypes,y,colors,alphas,stats.rs);
    % fig = myBoxplot(Dist,CorrTypes,y,colors,alphas,struct);
    
    if savenum
        saveFilename = [savePath filesep 'Intracluster Distance Violin.svg'];
        print(fig,'-vector','-dsvg',saveFilename);
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