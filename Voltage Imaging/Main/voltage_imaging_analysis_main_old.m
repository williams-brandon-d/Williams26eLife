% main voltage imaging analysis file

clear variables; close all; clc;
cd('D:/Matlab Files/'); % choose your current directory
addpath(genpath('./')); % add all folders and subfolders in cd to path

% select saved .mat file to load
% [file,dataPath] = uigetfile('*.mat');
% saveFilename = fullfile(dataPath,file);
% frame_rate = 800;
% load(saveFilename); % load ROIs and extracted traces

% extractTraces(); % extract traces - 

% updateROIs(); % separate function for removing and adding ROIs

% select raw image folder to extract ROIs and traces
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

% combine neighboring ROIs if time traces are the same
% - function to update ROIs (add and delete)

% PVlabels = getPVlabels(dataPath,selectTraceIdx); % add PV labels based on IHC registration
nSelected = numel(selectTraceIdx);
PVlabels = zeros(nSelected,1);
% PVlabels = [];

plotTraceswithLabels(neuron(selectTraceIdx), frame_rate, dataPath, 1,PVlabels); % plot traces with spike locations

% cluster cell types based on activity features
% -- spike half width, pre-stim firing, max firing rate, ISI distribution

% apply narrow bandpass for gamma based on cwt or psd average
lfp = analyzeLFP(dataPath, 1, 1);

lfp = downsampleLFP(lfp, spikes, frame_rate); % downsample LFP data to frame_rate

lfp = plotCyclePSD(lfp,frame_rate,1); % multitaper psd of each theta cycle
% plotPSD(lfp,frame_rate,1); % multitaper psd of raw data during stim

lfp = getLFPphase(lfp, spikes, 1, 1); % LFP phase
lfp = segmentGamma(lfp,frame_rate,0); % segment gamma cycles over each theta stim period

plotHeatMap(lfp, 1); % plot theta and gamma phase as heat map across cycles
plotGammaBins(lfp, 1); % plot gamma bins as heatmap

% spike gamma analysis
spikes = spikeGamma(spikes,lfp,1); % spike - gamma cycle comparison
spikeGammaHeatMap(spikes,lfp, 1); % spike gamma bin heatmap instead of histogram - sort by cycle #

plotTracesandLFP(neuron(selectTraceIdx), frame_rate, lfp, 1, 0, PVlabels); % plot traces + LFP
plotRaster(spikes, lfp, 0, 1); % plot spike rasters for each trace
plotPolar(spikes, lfp, 1); % polar plots for spike times relative to theta and gamma
plotFTAs(spikes, lfp, 1); % field triggered average - similar to polar plots

% plotPPCs(spikes, lfp, 1); % pairwise phase consisency - unbiased phase locking value
plotCyclePPCs(spikes, lfp, 1)
% plotSTAs(spikes, lfp, frame_rate, 1); % plot STAs for each neuron for both theta and gamma
plotCycleSTAs(spikes, lfp, frame_rate, 1) % compute STA for each first, second, third spike etc.
% cycle by cycle spike coherence?
plotSpikeCoherence(spikes, lfp, frame_rate, 1); % spike-field coherence

save(saveFilename,'spikes','-nocompression','-append'); % save spike data
save(saveFilename,'lfp','-nocompression','-append'); % save LFP data


% what to do with spikes that occur outside gamma bins??? -- no thresholding ??
% unwrap gamma phase for each theta cycle and look at spike timing??


% plotPCA(neuron(selectTraceIdx),lfp.stim_indices_ds); % find clusters with PCA - will tell me how much variance is explained by largest cluster 

% binarizing spikes is essentially the most extreme high pass filter - data is already normalized from 0 to 1
% findClusters(spikes,lfp); % use k modes to look for clusters in binary spike data during stim period

% normalize each trace from 0 to 1 before clustering continous data
% findClusters(neuron(selectTraceIdx),lfp); % use k means to look for clusters in continuous fluorescence data during stim period

% try finding clusters on a cycle by cycle basis? use gamma cycle bins?
% findCycleClusters(neuron(selectTraceIdx),lfp); % use k means to look for clusters in continuous fluorescence data during each stim cycle



% spatial analysis? 50 um bins? 



% separate script for comparing different theta frequencies in same FOV
% what values to compare across theta frequencies?
% theta phase of peak gamma power?
% total theta phase 
% gamma frequency of peak gamma power?



