function removeROIs(removeIdx,selectTraceIdx)
% removeIdx = [7 9]; % indices of selected traces to remove

if nargin < 2
    % select data path
    dataPath = uigetdir('D:/', 'Select a folder to read');
    saveFilename = [dataPath filesep 'Processed Data.mat'];
    
    % load ROIs from saved file
    load(saveFilename,'selectTraceIdx'); % load ROIs and extracted traces
end

% select ROIs to remove
% ROIs(selectTraceIdx(removeIdx)) = []; % if ROIs are removed selectTraceIdx will also be shifted
selectTraceIdx(removeIdx) = [];

% save new selectTraceIdx
if nargin < 2
    save(saveFilename,'selectTraceIdx','-nocompression','-append');
end

end