function spike_amp = get_raw_spike_amplitude(traces, spike_idx)
    spike_amp = zeros(size(traces, 2), length(spike_idx));
    pre_spike_idx = 1:3;
    for i = 1:length(spike_idx)
        curr_idx = spike_idx(i);
    
        amp_all = abs(traces(curr_idx, 1) - traces(curr_idx - pre_spike_idx, 1));
        [~, maxIdx] = max(amp_all);
        spike_amp(:, i) = traces(curr_idx, :) - traces(curr_idx - maxIdx, :);
    end
    spike_amp = spike_amp.*sign(mean(spike_amp(1,:)));

end