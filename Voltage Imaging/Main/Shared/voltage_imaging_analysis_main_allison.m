% main voltage imaging analysis file

clear variables; close all; clc;
cd('D:/Matlab Files/'); % choose your current directory
addpath(genpath('./')); % add all folders and subfolders in cd to path

% select save file to load
% [file,dataPath] = uigetfile('*.mat');
% saveFilename = fullfile(dataPath,file);
% frame_rate = 800;

% updateROIs(); % separate function for removing and adding ROIs

% extractTraces(); % extract traces 

[stack, dataPath, frame_rate] = readRawData();
ROItype = 'choose'; % manual, choose, or saved
saveFilename = chooseROIs(stack, dataPath, ROItype); % manual or align previous


load(saveFilename); % load ROIs and extracted traces

% selectTraceIdx = [3 5 7:10];
plotROIs(ROIs(selectTraceIdx), meanImage, dataPath, 1);

% for i = 1:numel(neuron); neuron{i}.raw_trace = -1*neuron{i}.raw_trace; end % invert trace

% detect spikes
spikes = detectSpikes(neuron(selectTraceIdx), frame_rate); % detect spikes
plotTracesandSpikes(neuron(selectTraceIdx), frame_rate, dataPath, 1, spikes); % plot traces with spike locations