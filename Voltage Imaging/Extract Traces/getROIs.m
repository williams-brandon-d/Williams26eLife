function chooseROIs(stack,dataPath,type)
    % types: manual, choose, saved
    saveFilename = [dataPath filesep 'Processed Data.mat'];
    if nargin < 3    
        if isfile(saveFilename) % check for saved ROIs
            type = 'saved';
        else
            [folderNames,folderName] = getFolderNames(dataPath);
            if strcmp(folderName,folderNames{1}) % check if file is the first recording in folder
                type = 'manual'; % manually select ROIs
            else 
                type = 'choose'; % load previous ROIs
            end
        end
    end

    switch type
        case 'manual'
            averageFrame = double(mean(stack(:,:,1000:1050), 3)); % take an average frame
            [ROImask, ROIs] = selectROI(averageFrame, @drawpolygon);
            ROIs = rankROI(ROIs);
        case 'choose'
%             [ROIfile,ROIpath] = uigetfile('*.mat','Select ROI File',dataPath); % select ROI file
           [folderNames,folderName] = getFolderNames(dataPath); % get previous recording ROIs
           idx = find(strcmp([folderNames{:}], folderName)); % find index of current folder
           ROIfile = folderNames{idx-1}; % previous folder - should have similar ROIs
           [ROIpath,~,~] = fileparts(dataPath); % path for ROI file

           ROIvar = load(fullfile(ROIpath,ROIfile),'ROIs','ROImask','meanImage');
           ROIs = ROIvar.ROIs;
           ROImask = ROIvar.ROImask;
           ROIimage = ROIvar.meanImage;
        case 'saved'
            saveFilename = [dataPath filesep 'Processed Data.mat'];
            load(saveFilename,'neuron','ROImask');
    end
     
    if strcmp(type,'manual') || strcmp(type,'choose')
        % create neuron struct from ROIs, ROImask, and stack
        N = length(ROIs);
        traces = zeros(size(stack, 3), N);
        stack2 = reshape(stack,[],size(stack,3));
        % neuron = {};
        neuron = cell(N,1);
        SE = strel("disk",5);
        
        for i = 1:N
            traces(:,i) = mean(stack2(ROIs{i},:),1);
            neuron{i}.raw_trace = traces(:, i);
            neuron{i}.edges = edge(ROIs{i});
            neuron{i}.mask = ROIs{i};
        
            surround = logical(imdilate(ROIs{i},SE) - ROIs{i});
            neuron{i}.meanBk = mean(stack2(surround(:),:),'all');
        end
    end
    
    if strcmp(type,'choose')
        % align previous ROIs with current stack
        averageFrame = double(mean(stack(:,:,1000:1050), 3)); % take an average frame
        neuron = AlignROIs(neuron,averageFrame,ROIimage); 
    end
    
    % save ROIs 


    function [folderNames,folderName] = getFolderNames(dataPath)
        [folderPath,folderName,~] = fileparts(dataPath);
        files = dir(folderPath);
        dirFlags = [files.isdir];
        allFolders = files(dirFlags); 
        folderNames = {allFolders(3:end).name}; % Start at 3 to skip . and ..
    end

end