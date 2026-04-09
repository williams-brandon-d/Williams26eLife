dataFiles = uigetdir2('G:/Recordings/');
%dataFiles = uigetdir2('E:/');
frame_rate = 800;
invert = true;
snr_thresh = 4;

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
dataAll = {};

for j = 1:batch   
    conds(j).mean_snr = []; conds(j).mean_amp = [];conds(j).mean_df = [];
    conds(j).spike_rate = [];conds(j).vm_corr = [];conds(j).photo_bleach = [];
    conds(j).mask_sz = []; conds(j).gain = []; conds(j).readoutN = []; 
    conds(j).neuronIdx = []; conds(j).fileIdx = [];
    for k = 1:length(dataFiles)
        load(dataFiles{k});
        dataAll{k} = trials;
        trialCnt = numel([j:batch:size(trials.spike_snr, 2)]); % number of trials under current condition
        neuronCnt = numel(neuron);
        %bleachWindow = min(size(trials.trace_raw, 2)/2, frame_rate * 20);

        
        % calculate cross-correlation on Vm
        subthreshold = trials.trace_subthreshold(:, :, j:batch:end);
        subCorr = zeros(neuronCnt);
        for i = 1:trialCnt
            subCorr = subCorr + corrcoef(subthreshold(:,:,i)')./trialCnt;
        end
        subCorr(subCorr == 1) = nan;
        
        % gather average statistics
        for n = 1:neuronCnt % iterate through each neuron
            conds(j).mask_sz(end+1) = sum(neuron{n}.mask, "all");
            conds(j).mean_snr(end+1) = mean(cell2mat(trials.spike_snr(n, j:batch:end)), 'omitnan');
            conds(j).mean_amp(end+1) = mean(cell2mat(trials.spike_amplitude(n, j:batch:end)), 'omitnan');
            conds(j).mean_df(end+1) = mean(cell2mat(trials.spike_df(n, j:batch:end)), 'omitnan');
            conds(j).spike_rate(end+1) = sum(trials.roaster(n, :, j:batch:end), 'all')./trialCnt./size(trials.trace_raw, 2).*frame_rate;
            conds(j).vm_corr(end+1) = mean(subCorr(n,:),'omitnan');

            [expFit, ~] = fitExpoential(abs(trials.trace_baseline(n,:,j:batch:end)));
            conds(j).photo_bleach(end+1) = 1 - feval(expFit, frame_rate * 60)./feval(expFit, frame_rate * 1);

            conds(j).neuronIdx(end+1) = n;
            conds(j).fileIdx(end+1) = k;

            if strcmp(mode, 'speed')
                conds(j).gain(end+1) = gain(2);
                conds(j).readoutN(end+1) = readoutN(2);
            else
                conds(j).gain(end+1) = gain(1);
                conds(j).readoutN(end+1) = readoutN(1);
            end
                

        end

    end
end

%%
meanSNR = []; meanAmp = []; meanDF = []; 
spikeRate = [];vmCorr = []; photoBleach = [];
shotNoiseSNR = []; readoutSNR = [];
for i = 1:batch
    meanSNR(i,:) = conds(i).mean_snr;
    meanAmp(i,:) = conds(i).mean_amp .* conds(i).mask_sz .* conds(i).gain;
    meanDF(i,:) = conds(i).mean_df;
    spikeRate(i,:) = conds(i).spike_rate;
    vmCorr(i,:) = conds(i).vm_corr;
    photoBleach(i,:) = conds(i).photo_bleach;   

    shotNoiseSNR(i,:) = meanAmp(i,:)./sqrt(-meanAmp(i,:)./meanDF(i,:));
    readoutSNR(i,:) = meanAmp(i,:)./sqrt(-meanAmp(i,:)./meanDF(i,:) + conds(i).mask_sz .* conds(i).readoutN.^2);
end

%validIdx = intersect(find(max(spikeRate, [], 1) > 1), find(max(meanSNR, [], 1) > 4));
validIdx = find(max(spikeRate, [], 1) > 1);
validIdx = find(max(meanSNR, [], 1) > 0);

%validIdx([5 12 28 33 35 38 39 41])  = [];
%validIdx(10:13)  = [];
figure;tiledlayout(3,6);

nexttile;
myboxchart(meanAmp(:,validIdx)','Spike amplitude');
nexttile;
plotPvalue(meanAmp(:,validIdx));


nexttile;
myboxchart(meanAmp(:,validIdx)'./abs(meanDF(:,validIdx)'),'Baseline amplitude');
nexttile;
plotPvalue(meanAmp(:,validIdx)./abs(meanDF(:,validIdx)));

nexttile;
myboxchart(abs(meanDF(:,validIdx)'),'Spike df');
nexttile;
plotPvalue(meanDF(:,validIdx));

nexttile;
myboxchart(meanSNR(:,validIdx)','average SNR');
nexttile;
plotPvalue(meanSNR(:,validIdx));

nexttile;
myboxchart(shotNoiseSNR(:,validIdx)','shot noise SNR');
nexttile;
plotPvalue(shotNoiseSNR(:,validIdx));

nexttile;
myboxchart(readoutSNR(:,validIdx)','readout  SNR');
nexttile;
plotPvalue(readoutSNR(:,validIdx));

nexttile;
myboxchart(abs(spikeRate(:,validIdx)'),'Spike rate / Hz');
nexttile;
plotPvalue(spikeRate(:,validIdx));

nexttile;
myboxchart(vmCorr(:,:)','Vm - Vm  correlation');
nexttile;
plotPvalue(vmCorr(:,:));

nexttile;
myboxchart(photoBleach(:,:)','Photobleach / % per 60s');
nexttile;
plotPvalue(photoBleach(:,:));

%%
figure;
signal_adj = 12; offset = 0;
trialNum = 1:8;
for ind = validIdx
%for ind = validIdx(1)
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
figure;figIdx = 1;
for trialNum = 5:8
subplot(4,1,figIdx); figIdx = figIdx + 1;

signal_adj = 8; offset = 0;
trace_sub = {};
for ind = [9 12 16]
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
    ylim([0.5 offset+1])
    trace_sub{end+1} = trace_subthreshold./trace_noise;
end
R = corrcoef(trace_sub{1},trace_sub{2});
R = R(:);R(R==1) = [];
title(['R=', num2str(mean(R))]);
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
