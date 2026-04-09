function updateROIs()
% function to update ROIs (add and delete) for entire FOV folder
% followed by updated trace extraction and analysis

dataPath = []; % select path
depth = 30000;

% read raw data stack
[stack, dataPath, ~] = readRawData(dataPath,depth); % could load stack only if new ROIs are added

% load saved ROIs
saveFilename = [dataPath filesep 'Processed Data.mat'];

load(saveFilename,'finalTraceIdx','ROIs','meanImage'); % load ROIs and extracted traces

% plot original ROIs
plotROIs(ROIs(finalTraceIdx), meanImage,'', 0);

% combine neighboring ROIs if time traces are the same?
% -- check correlation with nearest 4 traces

% user select ROIs to remove
removeIdx = input("Input ROI #s to remove [1 2 3...]: ");


% finalTraceIdx get replaced when running spikes only SNR selection
% - need to remove indices from ROIs
% - but if ROIs are removed Trace Idx is shifted
% - assign removal in spikes only function instead

% ROIs(selectTraceIdx(removeIdx)) = []; % if ROIs are removed TraceIdx will also be shifted
finalTraceIdx(removeIdx) = [];

% draw new ROIs
[~, newROIs] = selectROI(meanImage, @drawpolygon);
newROIs = rankROI(newROIs);

nNewROIs = numel(newROIs);
nOldROIs = numel(ROIs);

% add to current ROIs
ROIs = [ROIs newROIs];

nROIs = numel(ROIs);

if nNewROIs > 0
    finalTraceIdx = [finalTraceIdx nOldROIs+1:nROIs];
end

% plot updated ROIs
plotROIs(ROIs(finalTraceIdx), meanImage,'', 0);

% create new ROI mask
ROImask = getROImask(ROIs);

% extract traces with updated ROIs
neuron = getNeuron(ROIs,stack); 

% save updated ROIs and traces
save(saveFilename,'neuron','finalTraceIdx','ROIs','ROImask','meanImage','-nocompression','-append');


end