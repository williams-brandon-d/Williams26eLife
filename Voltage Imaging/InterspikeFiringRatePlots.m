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

allData = cell(nFreqs,1);

for iFreq = 1:nFreqs
    stim_freq = stim_freqs{iFreq};
    
    % find all data folders that contain stim protocol
    foldernames = getFoldernames(dataPath,stim_freq);
    nFolders = numel(foldernames);
    fprintf('Number of Subfolders Found: %d\n',nFolders);
    
    dataCell = cell(nFolders,nFreqs);
    
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
        dataCell{iFolder,iFreq} = spikeLFP.FRhistArray; % (nNeurons,nbins)
    
        %     spikeLFP.thetaPPC = thetaPPC;
        %     spikeLFP.gammaPPC = gammaPPC;
        
        
        % LFP - compare across theta frequencies in the same plot
        % theta phase, gamma frequency, peak gamma power: lfp.maxValues
        % average number of gamma cycles: numel(lfp.gamma_start_indices_ds{end})
        
        % spike-LFP - plot for each theta freq
        % combine theta and gamma phase locking values: [thetaPPC,gammaPPC]
        % look for differences to compare across theta freq (spike number etc.)
           
    end
    
    % linearize data for each theta frequency
    dataArray = cell2mat(dataCell(:,iFreq)); % concatenate rows

    % plot for each theta frequency
    fig = plotHist(dataArray);

    if savenum
        saveFilename = [savePath filesep sprintf('Interspike Firing Rates combined %s.svg',stim_freq)];
        print(fig,'-vector','-dsvg',saveFilename);
    end

    allData{iFreq} = dataArray;

end

% need FRs for stats

% saveFilename = [savePath 'Interspike Firing Rate stats.xlsx'];
% stats = myMultipleIndependentGroupStats(allData,stim_freqs,'',saveFilename,savenum);

% stats.kw.sig = sig;
% 
% % setup y axis for violin plots
% y.min = -0.5;
% y.max = 1;
% y.dy = 0.5;
% y.ticks = y.min:y.dy:y.max;
% y.tickLabels = string(y.ticks);
% y.labelstring = 'R_{spikes}';
% y.scale = 'linear';
% 
% % get colors for different stim frequencies
% % colors = lines(nFreqs);
% colors = colormap('lines');
% colors = colors(1:nFreqs,:);
% 
% alphas = ones(nFreqs,1);
% 
% % plot all theta frequencies for comparison - boxplot/violin plots
% % fig = plotViolin(rFreq,stim_freqs,y,colors,alphas,stats);
% fig = myBoxplot(rFreq,stim_freqs,y,colors,alphas,struct);
% 
% % setup stats in myBoxplot for 4 groups
% 
% if savenum
%     saveFilename = [savePath filesep 'Spatial Spike Correlations Boxplot.svg'];
%     print(fig,'-vector','-dsvg',saveFilename);
% end

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

% plot histogram
function fig = plotHist(HistArray)
% HistArray: nNeurons x nbins

edges = 0:10:400; % Hz

delta_bin = edges(2) - edges(1);
bin_midpoints = edges(1:end-1) + delta_bin/2;

tickfontsize = 15;
% titlefontsize = 15;

Color = [0 0 0];

fig = figure;
hold on;

if ~isempty(HistArray)

    % plot SEM
    meanData = mean(HistArray,1);
    SEM = std(HistArray,1) ./ sqrt(size(HistArray,1));
    meanData = reshape(meanData,1,[]); % column vector
    SEM = reshape(SEM,1,[]); % column vector
    xSEM = [bin_midpoints fliplr(bin_midpoints)] ;         
    ySEM = [meanData+SEM fliplr(meanData-SEM)];

    han1 = fill(xSEM,ySEM,Color);
    han1.FaceColor = Color;    
    han1.FaceAlpha = 0.4;      
    han1.EdgeColor = 'none'; 
    drawnow;

    % plot mean
    plot(bin_midpoints,meanData,'Color',Color);

    % plot example
%     if ~isempty(exampleData)
%         plot(bin_midpoints,exampleData,'Color',Color,'LineStyle','--');
%     end

end

hold off
xlim([min(edges) max(edges)])

ymax = 0.6;
ylim([0 ymax]);

xlabel('Interspike Firing Rate (Hz)')
ylabel('Counts (1 / Theta Cycle)')

% [~,folderName,~] = fileparts(lfp.dataPath);
% plotTitle = sprintf( '%s - Stim: %g Hz',folderName,lfp.stim_freq );
% sgtitle(plotTitle,'FontSize',titlefontsize,'FontWeight','bold','Interpreter','none');

ax = gca;
ax.YTick = 0:0.2:ymax;
ax.YAxis.FontSize = tickfontsize;
ax.YAxis.FontWeight = 'bold';
ax.XAxis.FontSize = tickfontsize;
ax.XAxis.FontWeight = 'bold';

end
