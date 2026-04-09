dataFiles = uigetdir2('G:/Recordings/');
%dataFiles = uigetdir2('E:/');
frame_rate = 800;
invert = true;
snr_thresh = 4;

sessions = numel(dataFiles);
trials = {};
for k = 1:length(dataFiles)

    load(dataFiles{k});

    traces = zeros(size(neuron{1}.raw_trace, 1), size(neuron{1}.raw_trace, 2), numel(neuron));
    for i = 1:numel(neuron)
        traces(:, :, i) = neuron{i}.raw_trace;
    end
    if min(traces,[],'all') < 70
        offset = 20;mode = 'speed';
    else
        offset = 100;mode = 'sensitivity';
    end

    result = spike_detect_SNR_v4((squeeze(traces(:, 1, :))-offset).*((-1)^(invert)), frame_rate, snr_thresh);
    result.raw_amplitude = {};
    for i = 1:numel(neuron)
        result.raw_amplitude{end+1} = get_raw_spike_amplitude(traces(:,:,i), result.spike_idx{i});
    end
    
    if k == 1
        trials = result;
        trials.mode = mode;
        trials.raw_amplitude = trials.raw_amplitude';
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
        trials.raw_amplitude = [trials.raw_amplitude, result.raw_amplitude'];
    end

end
info = 'comparison of SNR vs slit width, Voltron';
dataFolderName = split(dataFiles{1},'\');
dataFolderName = join(dataFolderName(1:end-1), '\');
save(dataFolderName{1},'trials', 'mode', 'neuron' ,'info', 'dataFolderName');


%%
dataFiles = uigetdir2('G:/Recordings/');
batch = 4;
gain = [0.264, 0.79];  % conversion gain, ADU to photoelectron
readoutN = [1.2, 1];
conds = [];
dataAll = {};

for j = 1:batch   
    conds(j).mean_snr = []; conds(j).mean_amp = [];conds(j).mean_df = [];
    conds(j).spike_rate = [];conds(j).mean_vm_corr = [];conds(j).photo_bleach = [];
    conds(j).mask_sz = []; conds(j).gain = []; conds(j).readoutN = []; 
    conds(j).spike_amp_decay = [];
    conds(j).neuronIdx = []; conds(j).fileIdx = [];
    conds(j).pairwiseDist = []; conds(j).pairwiseVmCorr = [];
    for k = 1:length(dataFiles)
        load(dataFiles{k});
        dataAll{k} = trials;
        trialCnt = numel([j:batch:size(trials.spike_snr, 2)]); % number of trials under current condition
        neuronCnt = numel(neuron);
        
  
        % calculate cross-correlation on Vm
        subthreshold = trials.trace_subthreshold(:, :, j:batch:end);
        subCorr = zeros(neuronCnt);
        pairwiseDist = zeros(neuronCnt);
        centroid = [];
        upperTriangleIdx = logical(triu(ones(neuronCnt),1));
        for i = 1:trialCnt
            subCorr = subCorr + corrcoef(subthreshold(:,:,i)')./trialCnt;
        end
        subCorr(subCorr == 1) = nan;

        % gather average statistics
        for n = 1:neuronCnt % iterate through each neuron
            conds(j).mask_sz(end+1) = sum(neuron{n}.mask(:,:,1), "all");
            conds(j).mean_snr(end+1) = mean(cell2mat(trials.spike_snr(n, j:batch:end)), 'omitnan');
            conds(j).mean_amp(end+1) = mean(cell2mat(trials.spike_amplitude(n, j:batch:end)), 'omitnan');
            conds(j).mean_df(end+1) = mean(cell2mat(trials.spike_df(n, j:batch:end)), 'omitnan');
            conds(j).spike_rate(end+1) = sum(trials.roaster(n, :, j:batch:end), 'all')./trialCnt./size(trials.trace_raw, 2).*frame_rate;
            conds(j).mean_vm_corr(end+1) = mean(subCorr(n,:),'omitnan');

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
            
            
            spike_raw_amp = cell2mat(trials.raw_amplitude(n, j:batch:end));
            raw_amplitude_decay = spike_raw_amp./spike_raw_amp(1,:);
            raw_amplitude_decay  = mean(raw_amplitude_decay, 2, 'omitnan');
            conds(j).spike_amp_decay(end+1, :) = raw_amplitude_decay;
            
            s = regionprops(neuron{n}.mask(:,:,1),'centroid');
            centroid(end+1, :) = s.Centroid;               

        end
        
        for nn = 1:neuronCnt
            for nnn = nn:neuronCnt
                dist = sqrt(sum((centroid(nn, :) - centroid(nnn, :)).^2));
                pairwiseDist(nn, nnn) = dist; pairwiseDist(nnn, nn) = dist;
            end
        end
        
        conds(j).pairwiseDist = [conds(j).pairwiseDist; pairwiseDist(upperTriangleIdx)];
        conds(j).pairwiseVmCorr = [conds(j).pairwiseVmCorr; subCorr(upperTriangleIdx)];

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
    vmCorr(i,:) = conds(i).mean_vm_corr;
    photoBleach(i,:) = conds(i).photo_bleach;   

    shotNoiseSNR(i,:) = meanAmp(i,:)./sqrt(-meanAmp(i,:)./meanDF(i,:));
    readoutSNR(i,:) = meanAmp(i,:)./sqrt(-meanAmp(i,:)./meanDF(i,:) + conds(i).mask_sz .* conds(i).readoutN.^2);
end
validIdx = find(max(spikeRate, [], 1) > 1);


%% boxplot for spike amplitude decay
spike_decay_data = [];
dist_data = [];
cond_data = [];
for i = 1:batch
    spike_decay = conds(i).spike_amp_decay(validIdx, 3:10);
    distGrp = repmat(1:size(spike_decay, 2), size(spike_decay, 1), 1);
    condGrp = ones(size(spike_decay)).*i;
    
    spike_decay_data = [spike_decay_data; spike_decay(:)];
    dist_data = [dist_data; distGrp(:)];
    cond_data = [cond_data; condGrp(:)];
end

figure;
%boxchart(spike_decay_data,{dist_data,cond_data},"ColorGroup",cond_data);
b = boxchart(dist_data.*1.25, spike_decay_data, 'GroupByColor',cond_data);
for i = 1:batch
    b(i).MarkerStyle = '.';
    b(i).Notch = 'on';
    b(i).BoxWidth = 0.75;
end
xlabel('distance to cell membrane / um');ylabel('F/F_0')
legend('4.5um', '11.3um', '22.5um', '156um');
xticks([1:8].*1.25);
xticklabels({'1.6', '4.7', '7.9', '11.0', '14.2', '17.3', '20.5', '23.6'});
ylim([-0.1 0.75]);
xlim([0 9*1.25])

%% statistical testing
% assuming corr and spike amplitude are normal distribution
fprintf('\n\n\n');
for distanceIdx = 1:8

testData = [spike_decay_data(dist_data== distanceIdx & cond_data == 1),...
    spike_decay_data(dist_data== distanceIdx & cond_data == 2),...
    spike_decay_data(dist_data== distanceIdx & cond_data == 3),...
    spike_decay_data(dist_data== distanceIdx & cond_data == 4)];
reps = 1;
%[p,tbl,stats] = anova2(testData,reps);
%[p,tbl,stats] = friedman(testData, reps);
%c = multcompare(stats);
fprintf('dist %d:  ', distanceIdx);
for condIdx = [2 3 4]
    [p, h] = ranksum(testData(:,1), testData(:, condIdx));
    fprintf('  %.4f', p);
end
fprintf('\n');

end
%%


figure;
for j = 1:4
% s = scatter(conds(j).pairwiseDist, conds(j).pairwiseVmCorr,5,'filled');
% s.MarkerFaceAlpha = 0.5;
% hold on;

[fitresult, gof] = fitExpoential_corr(conds(j).pairwiseDist, conds(j).pairwiseVmCorr);
fitresult.a

plotX = 0:800;
plotY = feval(fitresult, plotX);
plot(plotX.*0.4514, plotY);
hold on;

end

legend('4.5um', '11.3um', '22.5um', '156um');
xlabel('pairwise distance / um');
ylabel('Vm-Vm correlation')

%%
bin_sz = 100;  % bin every 50 um
pixel_sz = 0.4514;
vm_corr_data = [];
dist_data = [];
cond_data = [];
for i = 1:batch
    vm_corr = conds(i).pairwiseVmCorr;
    distGrp = conds(i).pairwiseDist.*pixel_sz;
    condGrp = ones(size(vm_corr)).*i;
    
    vm_corr_data = [vm_corr_data;  vm_corr(:)];
    dist_data = [dist_data; distGrp(:)];
    cond_data = [cond_data; condGrp(:)];
end

dist_data = ceil(dist_data./bin_sz);

figure;
%boxchart(spike_decay_data,{dist_data,cond_data},"ColorGroup",cond_data);
b = boxchart(dist_data.*1.25, vm_corr_data, 'GroupByColor',cond_data);
for i = 1:batch
    b(i).MarkerStyle = '.';
    b(i).Notch = 'on';
    b(i).BoxWidth = 0.75;
end


xlabel('pairwise distance / um');ylabel('Vm-Vm correlation')
legend('4.5um', '11.3um', '22.5um', '156um');
xticks([1:9].*1.25);
xticklabels({'50', '150', '250', '350', '450', '550', '650', '750', '850'});
ylim([-0.5 1]);
xlim([0.5 8.5*1.25]);


%% statistical testing
% assuming corr and spike amplitude are normal distribution
fprintf('\n\n\n');
for distanceIdx = 1:8

testData = [vm_corr_data(dist_data== distanceIdx & cond_data == 1),...
    vm_corr_data(dist_data== distanceIdx & cond_data == 2),...
    vm_corr_data(dist_data== distanceIdx & cond_data == 3),...
    vm_corr_data(dist_data== distanceIdx & cond_data == 4)];
reps = 1;
%[p,tbl,stats] = anova2(testData,reps);
%[p,tbl,stats] = friedman(testData, reps);
%c = multcompare(stats);
fprintf('dist %d:  ', distanceIdx);
for condIdx = [2 3 4]
    [p, h] = ranksum(testData(:,1), testData(:, condIdx));
    fprintf('  %.4f', p);
end
fprintf('\n');

end


