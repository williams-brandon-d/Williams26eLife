function cycle_start_index = getCycleStartIndices(norm_stim, cycle_length, time, stim_plotnum )
    prom = (max(norm_stim)-min(norm_stim))/2;
%     dist = 1000; % samples
    dist = 0.95*cycle_length; % samples

    [~, min_locs] = findpeaks(-1*norm_stim,'MinPeakProminence',prom,'MinPeakDistance',dist);
    [~, max_locs] = findpeaks(norm_stim,'MinPeakProminence',prom,'MinPeakDistance',dist);

    stim_start_index = min_locs(1) - cycle_length;

%     last_cycle_end = min_locs(end) + cycle_length;
%     nStimCycles = floor((last_cycle_end - stim_start_index)/cycle_length);
%     last_cycle_start = stim_start_index + (nStimCycles-1)*cycle_length;
%     cycle_start_index = stim_start_index:cycle_length:last_cycle_start;

    cycle_start_index = [stim_start_index; min_locs];

    cycle_lengths = diff(cycle_start_index);

    cycle_start_index(cycle_lengths > cycle_length+2) = []; % remove cycle start indices with potential stim artefacts


    if stim_plotnum == 1
        plotType = 2;
        min_peaks = norm_stim(min_locs);
        max_peaks = norm_stim(max_locs);
        min_time_peaks = time(min_locs);
        max_time_peaks = time(max_locs);
        switch plotType
            case 1
                figure; 
                plot(time,norm_stim,min_time_peaks,min_peaks,'ok',...
                    max_time_peaks,max_peaks,'or')
            case 2
                time_start = time(stim_start_index);
                stim_start = norm_stim(stim_start_index);
                time_windows_start = time(cycle_start_index);
                stim_windows_start = norm_stim(cycle_start_index);
                figure;
                plot(time,norm_stim,min_time_peaks,min_peaks,'ok',...
                    max_time_peaks,max_peaks,'or',...
                    time_start,stim_start,'xg',...
                    time_windows_start,stim_windows_start,'xm')
        end
    end
end