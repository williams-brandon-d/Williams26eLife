% main voltage imaging analysis file

clear variables; close all; clc;
cd('D:/Matlab Files/'); % change to your current directory
addpath(genpath('./')); % add all folders and subfolders in cd to path

% extract traces 
[stack, dataPath, frame_rate] = readRawData();
ROItype = 'manual'; % manual, choose, or saved
saveFilename = chooseROIs(stack, dataPath, ROItype); % manual or align previous
load(saveFilename); % load ROIs and extracted traces
plotROIs(ROIs(selectTraceIdx), meanImage, 0);

% for i = 1:numel(neuron); neuron{i}.raw_trace = -1*neuron{i}.raw_trace; end % invert trace

% detect spikes
spikes = detectSpikes(neuron(selectTraceIdx), frame_rate); % detect spikes
plotTracesandSpikes(neuron(selectTraceIdx), frame_rate, dataPath, 1, spikes); % plot traces with spike locations


