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
    load(saveFilename,'neuron','frame_rate','lfp'); % load ROIs and extracted traces

     % save frame_rate and invert traces during trace extraction
    if ~exist('lfp','var')
        lfp = [];
        disp('.abf file not processed.');
    end  


    % save frame_rate and invert traces during trace extraction
    if ~exist('frame_rate','var')
        frame_rate = 800;
        save(saveFilename,'frame_rate','-nocompression','-append'); % save frame_rate
    end

    % invert and save traces
%     for i = 1:numel(neuron); neuron{i}.raw_trace = -1*neuron{i}.raw_trace; end % invert trace
%     save(saveFilename,'neuron','-nocompression','-append'); % save neuron

    if exist('neuron','var') 
        % detect spikes in traces
        [spikes, neuron] = detectSpikes(neuron, frame_rate,lfp); % detect spikes
    
        % check if fov is first in folder
        % -- first fov run spike snr trace selection and manual trace removal
        % -- for the rest of folders in the same fov - use finalTraceIdx from first fov
    
        [fovName,~,~] = fileparts(fpath); % get fov foldername
        fovfoldernames = getFoldernames(fovName); % get fov subfolders
        if strcmp(fovfoldernames(1),fovName)
            fovfoldernames(1) = []; % first folder is fov folder
        end
    
        if strcmp(fpath,fovfoldernames{1}) % if first folder in fov folder
            % remove traces where SNRpeak < 4
            SNRselectTraceIdx = find([spikes.SNRpeak] > 3.75); % 8 for motion videos
            % remove neurons that are continuously firing 
            removeIdx = manualRemoveIdx(fpath);
            finalTraceIdx = SNRselectTraceIdx;
            finalTraceIdx(removeIdx) = [];
            % remove neurons that have nearly identical traces
        else
            fovSaveFileName = [fovfoldernames{1} filesep 'Processed Data.mat'];
            load(fovSaveFileName,'finalTraceIdx'); % load finalTraceIdx from previous file
        end
    
        % plot traces with spike indicators - use different color trace for discarded traces
        fig = plotTracesandSpikes(neuron, frame_rate, subfolderName, 1, spikes, finalTraceIdx); % plot traces with spike locations
    
        if savenum
            save(saveFilename,'neuron','spikes','finalTraceIdx','-nocompression','-append'); % save spikes
        end
    end

    if nFolders > 1
        clearvars neuron frame_rate lfp;
    end

end



function removeIdx = manualRemoveIdx(folderName)

% idx corrresponds to SNRselectTraceIdx

[fovName,~,~] = fileparts(folderName);

switch fovName
    case 'D:\TICO Voltage Imaging Data\CaMK2-ChR2-Voltron Data\03-14-2024 ChR2-Voltron-27\slice2\fov2'
        removeIdx = [1 3 5]; % 1 is continuously firing, 3 and 5 are identical - replaced by ROI 43
    case 'D:\TICO Voltage Imaging Data\CaMK2-ChR2-Voltron Data\03-14-2024 ChR2-Voltron-27\slice3\fov1'
        removeIdx = [5 18 19 22 23]; % 5 is continuously firing, 18+19 and 22+23 replaced with combined ROIs
    case 'D:\TICO Voltage Imaging Data\CaMK2-ChR2-Voltron Data\03-14-2024 ChR2-Voltron-27\slice1\fov1'
        removeIdx = [2 3]; % 2+3 replaced with 74+75
    otherwise
        removeIdx = [];
end

end


function foldernames = getFoldernames(rootPath)
% find all subfolders that have .mat files
filelist = dir(fullfile(rootPath, '**\*Processed Data.mat')); 
% find unique folders
foldernames = unique({filelist.folder})';
end
