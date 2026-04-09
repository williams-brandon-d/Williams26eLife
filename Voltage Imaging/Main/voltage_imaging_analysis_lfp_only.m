% main voltage imaging analysis file

clear variables; close all; clc;
cd('D:/Matlab Files/'); % choose your current directory
addpath(genpath('./')); % add all folders and subfolders in cd to path

savenum = 1;

% select rootPath 
folder = 'D:/TICO Voltage Imaging Data/CaMK2-ChR2-Voltron Data/';
rootPath = uigetdir(folder, 'Select a folder to read');
disp(['Folder Selected: ' rootPath]);

% find all subfolders that have .abf files
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

    % load saved frame rate
    saveFilename = [fpath filesep 'Processed Data.mat'];

    if exist(saveFilename,'file')
        load(saveFilename,'frame_rate'); % load frame rate
        if ~exist('frame_rate','var')
            frame_rate = 800;
            save(saveFilename,'frame_rate','-nocompression','-append'); % save frame_rate
        end
    else
        frame_rate = 800;
        save(saveFilename,'frame_rate','-nocompression'); % save frame_rate
    end

    % apply narrow bandpass for gamma based on cwt or psd average

    lfp = analyzeLFP(fpath, 1, 1);
    
    if lfp.nFrames > 0 % if imaging
        lfp = downsampleLFP(lfp, frame_rate); % downsample LFP data to frame_rate
        lfp = plotHeatMap(lfp, 1); % plot theta and gamma phase as heat map across cycles
        [lfp.psd,figPSD] = plotCyclePSD(lfp.lfp_data_ds,frame_rate,lfp.cycle_start_indices_ds,lfp.cycle_length_ds,'pwelch',lfp.data_units,1);
%     [lfp.psdAll,figPSDAll] = plotallCyclePSD(lfp.lfp_data_ds,frame_rate,lfp.cycle_start_indices_ds,lfp.cycle_length_ds,'pwelch',lfp.data_units,1);
        lfp = getLFPphase(lfp, 1, 1); % LFP phase
        lfp = segmentGamma(lfp,frame_rate,0); % segment gamma cycles over each theta stim period
        plotGammaBins(lfp, 1); % plot gamma bins as heatmap
        if savenum
            print(figPSD,'-vector','-dsvg',[lfp.savePath filesep 'LFP PSD.svg']) % svg
    %         print(figPSDAll,'-vector','-dsvg',[lfp.savePath filesep 'LFP PSD all cycles.svg']) % svg
        end
    end


    if savenum
        save(saveFilename,'lfp','-nocompression','-append'); % save spikes
    end

end


function foldernames = getFoldernames(rootPath)
% find all subfolders that have .abf files 
filelist = dir(fullfile(rootPath, '**\*.abf')); 
% find unique folders
foldernames = unique({filelist.folder})';
end
