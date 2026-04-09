function [stack,dataPath,frame_rate] = readRawData(dataPath, depth)

    if isempty(dataPath)
        dataPath = uigetdir('D:/', 'Select a folder to read');
    end

    if isempty(depth)
        depth = 30000; % max number of frames to load --- set greater than length
    end
    
    fileInfo = dir([dataPath, filesep, '*raw']);
    [~,idx] = sort([fileInfo.datenum]);
    fileInfo = fileInfo(idx);
    
    [stack, recordingInfo] = readKinetixRaw(fileInfo, depth);
    
    if exist('recordingInfo','var') && isfield(recordingInfo, 'params')
        frame_rate = recordingInfo.params.frameRate;
    else
        frame_rate = 800; % Hz
    end

end