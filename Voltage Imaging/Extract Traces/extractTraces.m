function extractTraces(dataPath, ROItype)
% extract traces from a selected data folder

% read raw data stack
depth = 30000; % max number of frames to load --- set greater than length

disp('Reading .raw file...');
[stack, dataPath, frame_rate] = readRawData(dataPath,depth);
disp('done.')

disp('Choosing ROIs...');
[neuron,selectTraceIdx,ROIs,ROImask,meanImage] = chooseROIs(stack, dataPath, ROItype);
disp('done.');

plotROIs(ROIs(selectTraceIdx), meanImage, '', 0);
drawnow;

% could combine neighboring ROIs if time traces are the same?
% -- check correlation with nearest 4 traces

saveFilename = [dataPath filesep 'Processed Data.mat'];

% save ROIs and traces
% to speed up save time could use hdf5 format
disp('Saving data...');
if isfile(saveFilename)
    save(saveFilename,'neuron','selectTraceIdx','ROIs','ROImask','meanImage','frame_rate','-nocompression','-append');
else
    save(saveFilename,'neuron','selectTraceIdx','ROIs','ROImask','meanImage','frame_rate','-v7','-nocompression');
end
disp('done.');

end
