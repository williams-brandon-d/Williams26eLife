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

% theta stimulation frequencies for analysis
stim_freqs = {'4 Hz','8 Hz','12 Hz','16 Hz'};
nFreqs = numel(stim_freqs);

dataFreq = cell(nFreqs,1);

for iFreq = 1:nFreqs
    stim_freq = stim_freqs{iFreq};
    
    % find all data folders that contain stim protocol
    foldernames = getFoldernames(dataPath,stim_freq);
    nFolders = numel(foldernames);
    fprintf('Number of Subfolders Found: %d\n',nFolders);
    
    thetaCell = cell(nFolders,nFreqs);
    gammaCell = cell(nFolders,nFreqs);
    
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
    
        % combine interspike firing rates: FRhistArray
        thetaCell{iFolder,iFreq} = spikeLFP.thetaPPC; % (nNeurons,nSpikes)
        gammaCell{iFolder,iFreq} = spikeLFP.gammaPPC; % (nNeurons,nSpikes)
        
        % LFP - compare across theta frequencies in the same plot
        % theta phase, gamma frequency, peak gamma power: lfp.maxValues
        % average number of gamma cycles: numel(lfp.gamma_start_indices_ds{end})
        
        % spike-LFP - plot for each theta freq
        % combine theta and gamma phase locking values: [thetaPPC,gammaPPC]
        % look for differences to compare across theta freq (spike number etc.)
           
    end
    
    % linearize data for each theta frequency
    thetaArray = cell2mat(thetaCell(:,iFreq)); % concatenate rows
    gammaArray = cell2mat(gammaCell(:,iFreq)); % concatenate rows

    % plot for each theta frequency
    figTheta = plotPPC(thetaArray,[1 0 0],[]);
    figGamma = plotPPC(gammaArray,[0 0 1],[]);

    if savenum
        print(figTheta,'-vector','-dsvg',[savePath filesep sprintf('PPC combined Theta %s.svg',stim_freq)]);
        print(figGamma,'-vector','-dsvg',[savePath filesep sprintf('PPC combined Gamma %s.svg',stim_freq)]);
    end

    dataFreq{iFreq} = gammaArray(:,1); % gamma spike 1 PPCs for all neurons

end

% stats
if nFreqs > 2
    saveFilename = [savePath 'PPC combined Gamma Spike1 stats.xlsx'];
    stats = myMultipleIndependentGroupStats(dataFreq,stim_freqs,'',saveFilename,savenum);
else 
    stats.kw = [];
end

stats.kw.sig = sig;

% setup y axis for violin plots
y.min = -0.5;
y.max = 1;
y.dy = 0.5;
y.ticks = y.min:y.dy:y.max;
y.tickLabels = string(y.ticks);
y.labelstring = 'PPC';
y.scale = 'linear';

% get colors for different stim frequencies
% colors = lines(nFreqs);
colors = colormap('lines');
colors = colors(1:nFreqs,:);

alphas = ones(nFreqs,1);

% plot all theta frequencies for comparison - boxplot/violin plots
% fig = plotViolin(dataFreq,stim_freqs,y,colors,alphas,stats);
fig = myBoxplot(dataFreq,stim_freqs,y,colors,alphas,struct);
sgtitle('Gamma Spike 1','Fontweight','bold');
ylim([-0.15 1.05]);

% setup stats in myBoxplot for 4 groups

if savenum
    print(fig,'-vector','-dsvg',[savePath filesep 'PPC combined Gamma Spike1 Boxplot.svg']);
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

    function fig = plotPPC(ppc0,color,xlabel)
        % add nice colors
%         c =  [0.45, 0.80, 0.69;...
%               0.98, 0.40, 0.35;...
%               0.55, 0.60, 0.79;...
%               0.90, 0.70, 0.30]; 

        % check if any columns are all NaN - remove group but save correct labels
        nGroups = size(ppc0,2);

        lin_ppc0 = ppc0(:);

        nan_mask = isnan(lin_ppc0);
        lin_ppc0(nan_mask) = []; % remove NaNs from linear array

        groups = ones(numel(ppc0),1);
        for i = 2:nGroups
            idx_start = ((i-1)*size(ppc0,1)) + 1;
            idx_stop = idx_start + size(ppc0,1) - 1;
            groups(idx_start:idx_stop) = i*ones(size(ppc0,1),1);
        end
        groups(nan_mask) = []; % remove NaNs from linear array

        newGroups = unique(groups);
        newNGroups = numel(newGroups);

        colors = repmat(color,[newNGroups, 1]);

        labels = cell(newNGroups,1);
        for iGroup = 1:newNGroups
            group = newGroups(iGroup);
%             ppc_group = lin_ppc0(groups == group);
%             N = numel(ppc_group);
%             labels{iGroup} = sprintf('%s_{Spike%d} (n=%d)',cellType,group,N);
            if isempty(xlabel)
                labels{iGroup} = sprintf('Spike{%d}',group);
            else
                labels{iGroup} = sprintf('%s_{Spike%d}',xlabel,group);
            end
        end

        tickfontsize = 15;

        % plot PPC
        fig = figure;
        if ~isempty(lin_ppc0)
            if isempty(color)
                daviolinplot(lin_ppc0,'groups',groups,'xtlabels',labels); % default colors
            else
                daviolinplot(lin_ppc0,'groups',groups,'xtlabels',labels,'color',colors); % my colors
            end
        end
        ylim([-0.5 1.5])
        ylabel({'Pairwise Phase';'Consistency'});
        ax = gca;
        ax.YAxis.FontSize = tickfontsize;
        ax.YAxis.FontWeight = 'bold';
        ax.XAxis.FontSize = tickfontsize;
        ax.XAxis.FontWeight = 'bold';
    end
