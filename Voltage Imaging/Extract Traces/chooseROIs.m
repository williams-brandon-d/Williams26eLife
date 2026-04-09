function [neuron,selectTraceIdx,ROIs,ROImask,meanImage] = chooseROIs(stack,dataPath,type)
    % type: manual, choose, saved

    % could have it auto choose ROIs from first recording in folder instead
    % of user selecting

    saveFilename = [dataPath filesep 'Processed Data.mat'];

    if nargin < 3 % no type specified   
        if isfile(saveFilename) % check for saved ROIs
            type = 'saved';
        else % type specified
            [folderNames,folderName] = getFolderNames(dataPath); % folders are named by datetime, get sorted folder names (earliest recording first)
            if strcmp(folderName,folderNames{1}) % check if file is the first recording in folder
                type = 'manual'; % manually select ROIs
            else 
                type = 'align'; % load previous ROIs
            end
        end
    end


    if strcmp(type,'saved')
        load(saveFilename,'neuron','ROIs','ROImask','selectTraceIdx','meanImage'); % load ROIs and extracted traces
    else
        meanImage = double(mean(stack(:,:,1000:1050), 3)); % take an average frame of 51 frames

        switch type
            case 'manual'
                [ROImask, ROIs] = selectROI(meanImage, @drawpolygon);
                ROIs = rankROI(ROIs);
            case 'choose'
                [ROIfile,ROIpath] = uigetfile('*.mat','Select ROI File',dataPath); % select ROI file
            case 'align'
               [folderNames,folderName] = getFolderNames(dataPath); % get previous recording ROIs
               idx = find(strcmp([folderNames{:}], folderName)); % find index of current folder
               ROIfile = folderNames{idx-1}; % previous folder - should have similar ROIs
               [ROIpath,~,~] = fileparts(dataPath); % path for ROI file
        end
         
        if strcmp(type,'choose') || strcmp(type,'align')
            ROIvar = load(fullfile(ROIpath,ROIfile),'ROIs','meanImage','selectTraceIdx');
            ROIs = ROIvar.ROIs;
            ROIimage = ROIvar.meanImage;
            selectTraceIdx = ROIvar.selectTraceIdx;
    
            ROIs = AlignROIs(ROIs,meanImage,ROIimage); % align previous ROIs with current stack
    
            ROImask = false(size(ROIimage));  % new ROI mask after alignment
            for i = 1:numel(ROIs)
                ROImask = ROImask | ROIs{i};
            end
        end
    
        neuron = getNeuron(ROIs,stack);
        
        if ~exist('selectTraceIdx','var')
            N = numel(ROIs);
            selectTraceIdx = 1:N;
        end
    end


    function [folderNames,folderName] = getFolderNames(dataPath)
        [folderPath,folderName,~] = fileparts(dataPath);
        files = dir(folderPath);
        allFolders = files([files.isdir]); 
        folderNames = {allFolders(3:end).name}; % Start at 3 to skip . and ..
    end

end