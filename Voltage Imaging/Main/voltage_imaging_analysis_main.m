% main voltage imaging analysis file

clear variables; close all; clc;
cd('D:/Matlab Files/'); % choose your current directory
addpath(genpath('./')); % add all folders and subfolders in cd to path

savenum = 1;

% select rootPath 
folder = 'D:/TICO Voltage Imaging Data/CaMK2-ChR2-Voltron Data/';
rootPath = uigetdir(folder, 'Select a folder to read');
disp(['Folder Selected: ' rootPath]);

% find all subfolders that have .mat files excluding Processsed Data folders
foldernames = getFoldernames(rootPath);
nFolders = numel(foldernames);
fprintf('Number of Subfolders Found: %d\n',nFolders);

for iFolder = 1:nFolders
    fpath = foldernames{iFolder};
    fprintf('Folder %d: %s\n',iFolder,fpath);

    slashIdx = strfind(fpath,'\');
    folderName = fpath(slashIdx(end)+1:end);
    
    subfolderName = [fpath filesep 'Processed Data'];
    disp(['Processed Data Folder: ' subfolderName]);

    if ~isfolder(subfolderName)
        mkdir(subfolderName);
    end

    % load saved ROI data
    saveFilename = [fpath filesep 'Processed Data.mat'];
    load(saveFilename,'neuron','selectTraceIdx','frame_rate'); % load ROIs and extracted traces

    if ~exist('frame_rate','var')
        frame_rate = 800;
        save(saveFilename,'frame_rate','-nocompression','-append'); % save frame_rate
    end

%     for i = 1:numel(neuron); neuron{i}.raw_trace = -1*neuron{i}.raw_trace; end % invert trace


%     selectNeurons = neuron(selectTraceIdx);

    % detect spikes in traces
    [spikes, neuron] = detectSpikes(neuron, frame_rate); % detect spikes

    % remove traces where SNRpeak < 4
    SNRselectTraceIdx = find([spikes.SNRpeak] > 4);

    % remove neurons that are continuously firing 
%     removeIdx = manualRemoveIdx(folderName);

    % remove neurons that have nearly identical traces

    % plot traces with spike indicators - use different color trace for low SNR traces
    fig = plotTracesandSpikes(neuron, frame_rate, subfolderName, 1, spikes, SNRselectTraceIdx); % plot traces with spike locations

    if savenum
        save(saveFilename,'spikes','SNRselectTraceIdx','-nocompression','-append'); % save spikes
    end

end

function removeIdx = manualRemoveIdx(folderName)

% idx corresponds to original neuron struct idx

[fovName,~,~] = fileparts(folderName);

switch fovName
    case 'D:/TICO Voltage Imaging Data/CaMK2-ChR2-Voltron Data/03-14-2024 ChR2-Voltron-27/slice2/fov2'
        removeIdx = 2;
end


end



% % combine neighboring ROIs if time traces are the same
% % - function to update ROIs (add and delete)
% 
% % PVlabels = getPVlabels(dataPath,selectTraceIdx); % add PV labels based on IHC registration
% nSelected = numel(selectTraceIdx);
% PVlabels = zeros(nSelected,1);
% % PVlabels = [];
% 
% plotTraceswithLabels(neuron(selectTraceIdx), frame_rate, dataPath, 1,PVlabels); % plot traces with spike locations
% 
% % cluster cell types based on activity features
% % -- spike half width, pre-stim firing, max firing rate, ISI distribution
% 
% % apply narrow bandpass for gamma based on cwt or psd average
% lfp = analyzeLFP(dataPath, 1, 1);
% 
% lfp = downsampleLFP(lfp, spikes, frame_rate); % downsample LFP data to frame_rate
% 
% lfp = plotCyclePSD(lfp,frame_rate,1); % multitaper psd of each theta cycle
% % plotPSD(lfp,frame_rate,1); % multitaper psd of raw data during stim
% 
% lfp = getLFPphase(lfp, spikes, 1, 1); % LFP phase
% lfp = segmentGamma(lfp,frame_rate,0); % segment gamma cycles over each theta stim period
% 
% plotHeatMap(lfp, 1); % plot theta and gamma phase as heat map across cycles
% plotGammaBins(lfp, 1); % plot gamma bins as heatmap
% 
% % spike gamma analysis
% spikes = spikeGamma(spikes,lfp,1); % spike - gamma cycle comparison
% spikeGammaHeatMap(spikes,lfp, 1); % spike gamma bin heatmap instead of histogram - sort by cycle #
% 
% plotTracesandLFP(neuron(selectTraceIdx), frame_rate, lfp, 1, 0, PVlabels); % plot traces + LFP
% plotRaster(spikes, lfp, 0, 1); % plot spike rasters for each trace
% plotPolar(spikes, lfp, 1); % polar plots for spike times relative to theta and gamma
% plotFTAs(spikes, lfp, 1); % field triggered average - similar to polar plots
% 
% % plotPPCs(spikes, lfp, 1); % pairwise phase consisency - unbiased phase locking value
% plotCyclePPCs(spikes, lfp, 1)
% % plotSTAs(spikes, lfp, frame_rate, 1); % plot STAs for each neuron for both theta and gamma
% plotCycleSTAs(spikes, lfp, frame_rate, 1) % compute STA for each first, second, third spike etc.
% % cycle by cycle spike coherence?
% plotSpikeCoherence(spikes, lfp, frame_rate, 1); % spike-field coherence
% 
% save(saveFilename,'spikes','-nocompression','-append'); % save spike data
% save(saveFilename,'lfp','-nocompression','-append'); % save LFP data


% what to do with spikes that occur outside gamma bins??? -- no thresholding ??
% unwrap gamma phase for each theta cycle and look at spike timing??


% plotPCA(neuron(selectTraceIdx),lfp.stim_indices_ds); % find clusters with PCA - will tell me how much variance is explained by largest cluster 

% binarizing spikes is essentially the most extreme high pass filter - data is already normalized from 0 to 1
% findClusters(spikes,lfp); % use k modes to look for clusters in binary spike data during stim period

% normalize each trace from 0 to 1 before clustering continous data
% findClusters(neuron(selectTraceIdx),lfp); % use k means to look for clusters in continuous fluorescence data during stim period

% try finding clusters on a cycle by cycle basis? use gamma cycle bins?
% findCycleClusters(neuron(selectTraceIdx),lfp); % use k means to look for clusters in continuous fluorescence data during each stim cycle



% spatial analysis? 50 um bins? 



% separate script for comparing different theta frequencies in same FOV
% what values to compare across theta frequencies?
% theta phase of peak gamma power?
% total theta phase 
% gamma frequency of peak gamma power?


function foldernames = getFoldernames(rootPath)
% find all subfolders that have .mat files excluding Processed Data folders
% find all .tif files in folder and all subfolders
filelist = dir(fullfile(rootPath, '**\*Processed Data.mat')); 
% find unique folders
foldernames = unique({filelist.folder})';
% remove Processed Data folders from list
% removeMask = contains(foldernames,'Processed Data');
% foldernames(removeMask) = [];
end
