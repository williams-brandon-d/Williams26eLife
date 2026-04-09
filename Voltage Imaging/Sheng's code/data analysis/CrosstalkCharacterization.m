dataFiles = uigetdir2('G:/Recordings/');
frame_rate = 800;
invert = true;
snr_thresh = 3;

sessions = numel(dataFiles);
trials = {};
for k = 1:length(dataFiles)
    load(dataFiles{k});

    traces = zeros(length(neuron{1}.raw_trace), numel(neuron));
    for i = 1:numel(neuron)
        traces(:, i) = neuron{i}.raw_trace;
    end
    if min(traces,[],'all') < 75
        offset = 20;mode = 'speed';
    else
        offset = 100;mode = 'sensitivity';
    end

    result = spike_detect_SNR_v4((traces-offset).*((-1)^(invert)), frame_rate, snr_thresh);
    if k == 1
        trials = result;
        trials.mode = mode;
    else
        trials.spike_snr = [trials.spike_snr, result.spike_snr];
        trials.spike_amplitude = [trials.spike_amplitude, result.spike_amplitude];
        trials.spike_df = [trials.spike_df, result.spike_df];
        trials.trace_raw = cat(3, trials.trace_raw, result.trace_raw);
        trials.orig_trace = cat(3, trials.orig_trace, result.orig_trace);
        trials.trace_baseline = cat(3, trials.trace_baseline, result.trace_baseline);
        trials.trace_spikeRemoved = cat(3, trials.trace_spikeRemoved, result.trace_spikeRemoved);
        trials.trace_noise = cat(3, trials.trace_noise, result.trace_noise);
        trials.roaster = cat(3, trials.roaster, result.roaster);
        trials.trace_subthreshold = cat(3, trials.trace_subthreshold, result.trace_subthreshold);

    end

end
info = 'comparison of SNR vs slit width, Voltron';
dataFolderName = split(dataFiles{1},'\');
dataFolderName = join(dataFolderName(1:end-1), '\');
save(dataFolderName{1},'trials', 'mode', 'neuron' ,'info', 'dataFolderName');



%%
dataFiles = uigetdir2('G:/Recordings/');
batch = 2;
gain = [0.264, 0.79];  % conversion gain, ADU to photoelectron
readoutN = [1.2, 1];
conds = [];
emptyROI = [];
dataAll = {};

for j = 1:batch   
    conds(j).subCorr = {};
    conds(j).bkIdx = {};
    for k = 1:length(dataFiles)
        load(dataFiles{k});
        dataAll{k} = trials;
        trialCnt = numel([j:batch:size(trials.spike_snr, 2)]); % number of trials under current condition
        neuronCnt = numel(neuron);

        % calculate cross-correlation on Vm
        subthreshold = trials.trace_subthreshold(:, :, j:batch:end);
        subCorr = zeros(neuronCnt);
        for i = 1:trialCnt
            subCorr = subCorr + corrcoef(subthreshold(:,:,i)')./trialCnt;
        end
        subCorr(subCorr == 1) = nan;

        conds(j).subCorr{k} = subCorr;
        conds(j).bkIdx{k} = bkIdx;
       
    end
end

%%
vmCorr = []; 
vmCorrAll = [];
for j = 1:batch
    meanCorr = [];
    corrAll = [];
    for k = 1:length(conds(1).subCorr)
        idx = conds(j).bkIdx{k};
        corr = conds(j).subCorr{k}(:, :);
        meanCorr = cat(2, meanCorr, mean(corr, 2, 'omitnan')');
        meanCorr = reshape(meanCorr, 1, []);
        corrAll = cat(2, corrAll, corr(:)');
    end
    vmCorr = cat(1, vmCorr, meanCorr);
    vmCorrAll = cat(1, vmCorrAll, corrAll);
end


figure;tiledlayout(2,2);


nexttile;
myboxchart(vmCorr(:,:)','Vm - Vm  correlation');
nexttile;
plotPvalue(vmCorr(:,:));


nexttile;
myboxchart(vmCorrAll(:,:)','Vm - Vm  correlation');
nexttile;
plotPvalue(vmCorrAll(:,:));

%%
figure;
signal_adj = 12; offset = 0;
trialNum = 1:16;
for ind = validIdx
    fileIdx = conds(1).fileIdx(ind); neuronIdx = conds(1).neuronIdx(ind);
    offset = offset + 1;
    rast = reshape(dataAll{fileIdx}.roaster(neuronIdx,:,trialNum), 1, []);rast(rast==0) = NaN;
    orig_trace = reshape(dataAll{fileIdx}.orig_trace(neuronIdx,:,trialNum), 1, []);
    trace_noise = reshape(dataAll{fileIdx}.trace_noise(neuronIdx,:,trialNum), 1, []);
    trace_subthreshold = reshape(dataAll{fileIdx}.trace_subthreshold(neuronIdx,:,trialNum), 1, []);
    

    plot(orig_trace./trace_noise./signal_adj + offset,'k','LineWidth',0.1);
    hold on;
    plot(rast + offset - 0.3,'.r','Color', [1, 0, 0, 0.5],'LineWidth', 0.1); 
    hold on,
end
%%
trialNum = 4;
figure;
signal_adj = 8; offset = 0;
for ind = [10 11]
    fileIdx = conds(1).fileIdx(ind); neuronIdx = conds(1).neuronIdx(ind);
    offset = offset + 1;
    rast = reshape(dataAll{fileIdx}.roaster(neuronIdx,:,trialNum), 1, []);rast(rast==0) = NaN;
    orig_trace = reshape(dataAll{fileIdx}.orig_trace(neuronIdx,:,trialNum), 1, []);
    trace_noise = reshape(dataAll{fileIdx}.trace_noise(neuronIdx,:,trialNum), 1, []);
    trace_subthreshold = reshape(dataAll{fileIdx}.trace_subthreshold(neuronIdx,:,trialNum), 1, []);
    
    plot(orig_trace./trace_noise./signal_adj + offset,'Color',[0.2 0.2 0.2],'LineWidth',0.1);
    hold on;
    plot(rast + offset - 0.3,'.r','Color', [1, 0, 0, 0.5],'LineWidth', 0.1); 
    hold on;
    plot(trace_subthreshold./trace_noise./signal_adj + offset,'Color',[0.8660 0.4740 0.2880],'LineWidth',1.5);
    ylim([0.5, 3.5])
end

%% hyposis testing

hypo = []; pVal = [];
testTarget = meanSNR;
for i = 1:batch
    for j = 1:batch
        [p,h,stats] = signrank(testTarget(i,validIdx),testTarget(j,validIdx));
        pVal(i,j) = p; hypo(i,j) = h;
    end
end
hypo
pVal
