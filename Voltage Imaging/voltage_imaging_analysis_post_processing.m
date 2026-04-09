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

% can set fieldname to spikes or raw

% theta stimulation frequencies for analysis
stim_freqs = {'4 Hz','8 Hz','12 Hz','16 Hz'};
% stim_freqs = {'8 Hz'};
nFreqs = numel(stim_freqs);

rFreq = cell(nFreqs,1);

for iFreq = 1:nFreqs
    stim_freq = stim_freqs{iFreq};
    
    % find all data folders that contain stim protocol
    foldernames = getFoldernames(dataPath,stim_freq);
    nFolders = numel(foldernames);
    fprintf('Number of Subfolders Found: %d\n',nFolders);
    
    dCell = cell(nFolders,nFreqs);
    rCell = cell(nFolders,nFreqs);
    
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

        if isfield(spikeLFP.d,'spikes')
            d = spikeLFP.d.spikes;
            r = spikeLFP.r.spikes;
        else % no subfields
            d = spikeLFP.d;
            r = spikeLFP.r;
        end
        
        d = reshape(d,[],1); % column vector
        r = reshape(r,[],1); % column vector

        % combine pairwise spike correlation values for each theta stim freq: [d,r]
        dCell{iFolder,iFreq} = d; % column vector
        rCell{iFolder,iFreq} = r;

        % could also compare R2 for each recording
    
        %     spikeLFP.FRhistArray = FRhistArray;
        %     spikeLFP.thetaPPC = thetaPPC;
        %     spikeLFP.gammaPPC = gammaPPC;
        
        
        % LFP - compare across theta frequencies in the same plot
        % theta phase, gamma frequency, peak gamma power: lfp.maxValues
        % average number of gamma cycles: numel(lfp.gamma_start_indices_ds{end})
        
        % spike-LFP - plot for each theta freq
        % combine theta and gamma phase locking values: [thetaPPC,gammaPPC]
        % look for differences to compare across theta freq (spike number etc.)
        
        % spike only - plot for each theta freq
        % combine pairwise spike correlation values for each theta stim freq: [d,r]
        % combine interspike firing rates: FRhistArray
    
        % then compare boxplot/violin plots across theta freq
   
    end
    
    % linearize data for each theta frequency
    dVector = cell2mat(dCell(:,iFreq)); % concatenate column vectors
    rVector = cell2mat(rCell(:,iFreq));

    % plot for each theta frequency
    [fig, ~] = plotCorrVsDist(dVector,rVector);
    ylim([-0.5 1]);

    if savenum
        saveFilename = [savePath filesep sprintf('Spatial Spike Correlations combined min neg05 %s.svg',stim_freq)];
        print(fig,'-vector','-dsvg',saveFilename);
    end

    rFreq{iFreq} = rVector;

end

% stats
if nFreqs > 2
    saveFilename = [savePath 'Spatial Spike Correlations stats.xlsx'];
    stats = myMultipleIndependentGroupStats(rFreq,stim_freqs,'',saveFilename,savenum);
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
y.labelstring = 'R_{spikes}';
y.scale = 'linear';

% get colors for different stim frequencies
% colors = lines(nFreqs);
colors = colormap('lines');
colors = colors(1:nFreqs,:);

alphas = ones(nFreqs,1);

% plot all theta frequencies for comparison - boxplot/violin plots
% fig = plotViolin(rFreq,stim_freqs,y,colors,alphas,stats);
fig = myBoxplot(rFreq,stim_freqs,y,colors,alphas,struct);

% setup stats in myBoxplot for 4 groups

if savenum
    saveFilename = [savePath filesep 'Spatial Spike Correlations Boxplot.svg'];
    print(fig,'-vector','-dsvg',saveFilename);
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
