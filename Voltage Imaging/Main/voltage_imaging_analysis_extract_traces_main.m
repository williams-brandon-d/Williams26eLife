% extract traces in all subfolders

clear variables; close all; clc;
cd('D:/Matlab Files/'); % choose your current directory
addpath(genpath('./')); % add all folders and subfolders in cd to path

ROItype = 'choose';

% select rootPath 
folder = 'D:/TICO Voltage Imaging Data/CaMK2-ChR2-Voltron Data/';
rootPath = uigetdir(folder, 'Select a folder to read');
disp(['Folder Selected: ' rootPath]);

% find all subfolders that have .mat files excluding Processed Data folders
foldernames = getFoldernames(rootPath);
nFolders = numel(foldernames);
fprintf('Number of Subfolders Found: %d\n',nFolders);

for iFolder = 1:nFolders
    fpath = foldernames{iFolder};
    fprintf('Folder %d: %s\n',iFolder,fpath);

    extractTraces(fpath, ROItype); % extract traces from each data folder
end


function foldernames = getFoldernames(rootPath)

filelist = dir(fullfile(rootPath, '**\*.raw')); % find all .raw files in folder and all subfolders
foldernames = unique({filelist.folder})'; % find unique folders

end
