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

    % load saved data
    saveFilename = [fpath filesep 'Processed Data.mat'];

    % try to load all variables
    load(saveFilename,'spikes','neuron','lfp','finalTraceIdx','frame_rate','ROIs','meanImage');
    % if any not found skip analysis

    if ~exist('spikes','var')
        disp('File does not contain extracted spikes.');
        continue;
    end

    % plot ROI image of selected traces 
    plotROIs(ROIs(finalTraceIdx), meanImage, subfolderName, 1);

    % plot traces of selected neurons + LFP
    % PVlabels = getPVlabels(dataPath,selectTraceIdx); % add PV labels based on IHC registration
    PVlabels = zeros(numel(finalTraceIdx),1); % don't add PVlabels since there are so few
    plotTracesandLFP(neuron(finalTraceIdx), frame_rate, lfp, subfolderName, 1, 0, PVlabels);

    neuron = neuron(finalTraceIdx);
    spikes = spikes(finalTraceIdx);
    ROIs = ROIs(finalTraceIdx);

    % spike lfp analysis

    % what to do with spikes that occur outside gamma bins? before=0,after=NaN
    % unwrap gamma phase for each theta cycle and look at spike timing??
    [hist,bin_midpoints] = spikeGamma({spikes.masks}, lfp, subfolderName, 1); % spike - gamma cycle comparison
    spikeGammaHeatMap(hist, bin_midpoints, subfolderName, 1); % spike gamma bin heatmap instead of histogram - sort by cycle #

    % align spiking to average gamma bins?

    % separate raster and phase histogram plotting functions?
    spikes = plotRaster(spikes, lfp, 0, subfolderName, 1); % plot spike rasters all traces - set plotnum = 1 for individual traces

    FRhistArray = plotRateHist(spikes, lfp, subfolderName, 1); % plot spike rate histograms

    plotPolar({spikes.masks}, lfp, subfolderName, 1); % polar plots for spike times relative to theta and gamma
    % plotFTAs(spikes, lfp, 1); % field triggered average - similar to polar plots
    
    [thetaPPC,gammaPPC] = plotCyclePPCs({spikes.masks}, lfp, subfolderName, 1);

    plotCycleSTAs(spikes, lfp, frame_rate, subfolderName, 1) % compute STA for each first, second, third spike etc.
    
    % cycle by cycle spike coherence?
    plotSpikeCoherence(spikes, lfp, frame_rate, subfolderName, 1); % spike-field coherence

    [coeff,score] = plotPCA(neuron,lfp.stim_indices_ds, subfolderName, 1); % find clusters with PCA - will tell me how much variance is explained by largest cluster 

    R = plotCorrelationMatrix(neuron,lfp,subfolderName,1); % dfoverf 
    Rfr = plotSpikeCorrelationMatrix(spikes,lfp,subfolderName,1); % spikes per theta cycle
    Rspikes = plotSpikeTrainCorrelationMatrix(spikes,lfp,subfolderName,1); % guassian spike train correlations


    % plot pairwise correlations as a function of distance from the center
    % of FOV - also may not be the center of objective due to cropping

    % plot x,y,R - can't correlate individual locations with pairwise correlations, could compare differences in x and y rather than d
%     plotXYSpatialCorrelations(ROIs(finalTraceIdx),R,subfolderName,1); % spatial analysis of pariwise correlations

    CorrTypes = {'raw','spikes'};

    % for each R type compute cluster labels and sort

    for iCorr = 1:numel(CorrTypes)
        type = CorrTypes{iCorr};
        saveFolder = [subfolderName filesep 'clustering ' type];
        if ~isfolder(saveFolder)
            mkdir(saveFolder);
        end

        switch type
            case 'raw'
                corrMatrix = R;
            case 'spikes'
                corrMatrix = Rspikes;
            case 'rate'
                corrMatrix = Rfr;
        end

        % sort correlation matrix
        [sortedIdx,clusterIdx] = plotSortedCorrMatrix(corrMatrix, coeff, saveFolder, 1);
    
        % color traces by cluster
        plotTracesandLFPsorted(neuron(sortedIdx), frame_rate, lfp, clusterIdx, saveFolder, 1, 0, PVlabels, sortedIdx);
    
        % color markers by H-cluster
        [d,r] = plotSpatialCorrelations(ROIs(sortedIdx),corrMatrix(sortedIdx,sortedIdx),clusterIdx,saveFolder,1); % spatial analysis of pairwise correlations
    
        % plot ROIs - color ROIs by cluster
        plotSortedROIs(ROIs(sortedIdx), meanImage, clusterIdx, sortedIdx, saveFolder, 1);
    
        nPCs = min(5,numel(finalTraceIdx));
        % sort neuron PCA loadings matrix by Hclustering
        figCoeff = plotCoeffMatrix(coeff(sortedIdx,:),nPCs,sortedIdx); % plot coeff matrix - could focus on first few components

        % save figures
        print(figCoeff,'-vector','-dsvg',[saveFolder filesep 'dfoverf PCA coeff sorted.svg']) % svg

        % gather ROI positions
        nSelected = numel(ROIs);
        ROIxy = zeros(nSelected,2);
        for iNeuron = 1:nSelected
            S = regionprops(ROIs{iNeuron},'Centroid');
            if length(S) > 1
                S = S(1);
            end
            ROIxy(iNeuron,:) = [S.Centroid(1) S.Centroid(2)];
        end

        % calculate intracluster pairwise distances
        nClusters = max(clusterIdx);
        dist = cell(nClusters,1);
        pixelSize = 0.4514; % pixel size - um / pixel 
        for iCluster = 1:nClusters
            mask = sortedIdx(clusterIdx == iCluster); 
            clusterXY = ROIxy(mask,:);
            dcluster = pdist(clusterXY,'euclidean'); % pairwise distance - pixel units
            dist{iCluster,1} = reshape(dcluster*pixelSize,[],1); % pairwise distance - microns
        end

        % normalize ROIxy range from 0 to 1
        scaledROIxy = [rescale(ROIxy(:,1)) rescale(ROIxy(:,2))];

        figS = figure;
        [s,~] = silhouette(scaledROIxy(sortedIdx,:),clusterIdx,'Euclidean');
        xlim([-1 1]);
        s(s == 1) = NaN; % remove clusters with only one neuron for silhouette scoring?
        meanS = mean(s,'omitnan'); % silhouette score
        title(sprintf('Silhouette mean = %.2f',meanS))
        hold on
        plot([meanS meanS],ylim,'--r','Linewidth',2)
        hold off
        print(figS,'-vector','-dsvg',[saveFolder filesep 'Silhouette.svg']) % svg

        spikeLFP.intraDist.(type) = cell2mat(dist);
        spikeLFP.meanS.(type) = meanS;

        % save data
        spikeLFP.clusterIdx.(type) = clusterIdx;
        spikeLFP.sortedIdx.(type) = sortedIdx;
        spikeLFP.d.(type) = d;
        spikeLFP.r.(type) = r;

    end

    % sort spikeGammaHeatMap by hclust


    % separate script for comparing different theta frequencies across all FOVs
    % output structure for comparisons
%     spikeLFP.d = d;
%     spikeLFP.r = r;

    spikeLFP.PCA.coeff = coeff;
    spikeLFP.PCA.score = score;

    spikeLFP.FRhistArray = FRhistArray;
    spikeLFP.thetaPPC = thetaPPC;
    spikeLFP.gammaPPC = gammaPPC;

    spikeLFP.R = R; % save unsorted voltage and spike corrleation matrices
    spikeLFP.Rspikes = Rspikes;
    spikeLFP.Rfr = Rfr;

    % LFP 
    % theta phase, gamma frequency, peak gamma power: lfp.maxValues
    % average number of gamma cycles: numel(lfp.gamma_start_indices_ds{end})
    
    % spike-LFP
    % combine theta and gamma phase locking values: [thetaPPC,gammaPPC]

    % spike only
    % combine pairwise spike correlation values for each theta stim freq: [d,r]
    % combine interspike firing rates: FRhistArray


    % k means does not work well for time series data
    % binarizing spikes is essentially the most extreme high pass filter - data is already normalized from 0 to 1
%     findClusters(spikes,lfp); % use k modes to look for clusters in binary spike data during stim period
    % normalize each trace from 0 to 1 before clustering continous data
%     findClustersContinuous(neuron,lfp,subfolderName,1); % use k means to look for clusters in continuous fluorescence data during stim period    
    % try finding clusters on a cycle by cycle basis? use gamma cycle bins?
    % findCycleClustersContinuous(neuron(selectTraceIdx),lfp); % use k means to look for clusters in continuous fluorescence data during each stim cycle


    if savenum
        save(saveFilename,'spikeLFP','-nocompression','-append'); % save spikes
    end

    if nFolders > 1
        clearvars spikes neuron lfp finalTraceIdx frame_rate ROIs meanImage;
        close all;
    end

end


function foldernames = getFoldernames(rootPath)
% find all subfolders that have .mat files excluding Processed Data folders
% could instead find all folders that have both .raw and .abf file and Processed Data.mat
filelist = dir(fullfile(rootPath, '**\*Processed Data.mat')); 
% find unique folders
foldernames = unique({filelist.folder})';

% if foldername contains Bad data - remove
foldernames(contains(foldernames,'Bad data','IgnoreCase',true)) = [];
% if foldername contains lfp only - remove
foldernames(contains(foldernames,'LFP only','IgnoreCase',true)) = [];
end
