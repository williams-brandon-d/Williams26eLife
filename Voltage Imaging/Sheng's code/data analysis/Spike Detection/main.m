frame_rate = 800;
clear traces;
for i = 1:length(neuron)
   traces(:,i) = neuron{i}.raw_trace;
end

result = spike_detect_SNR_v3b(-traces, frame_rate);
plot_results(result, neuron, meanImage, frame_rate);

%%
invalidIdx = [];
for i = 1:length(result.spike_snr)
    if length(result.spike_snr{i}) <= 3
        invalidIdx(end+1) = i;
    end
end

neuron(invalidIdx) = [];

clear traces;
for i = 1:length(neuron)
   traces(:,i) = neuron{i}.raw_trace;
end

result = spike_detect_SNR_v3b(-traces, frame_rate);
plot_results(result, neuron, meanImage, frame_rate);





