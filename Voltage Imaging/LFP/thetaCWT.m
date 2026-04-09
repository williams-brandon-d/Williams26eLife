function [x,y,z,lfp] = thetaCWT(lfp)

    % make scalogram for lfp 
    wname = 'amor'; % 'morse' (default), 'amor', 'bump'
    VoicesPerOctave = 32; % number of scales per octave
    flimits = [0 300]; % frequency limits for wavelet analysis
    
    delta_phase = 2*pi/lfp.cycle_length;
    cycle_phase = -pi:delta_phase:pi;
    fb = cwtfilterbank('Wavelet',wname,'SignalLength',numel(cycle_phase),...
    'FrequencyLimits',flimits,'SamplingFrequency',lfp.Fs,'VoicesPerOctave',VoicesPerOctave);
    
    lpf_stim = filterStimData(lfp.stim_data,lfp.Fs,lfp.stim_freq);
    norm_stim = normalizeStimData(lpf_stim);
    
    % zero out pulse before theta stim
    zeroEndTime = 0.5; % sec
    maskTime = lfp.time < zeroEndTime;
    norm_stim(maskTime) = min(norm_stim)*zeros(sum(maskTime),1);
    % figure; plot(norm_stim)
    
    lfp.cycle_start_index = getCycleStartIndices(norm_stim, lfp.cycle_length, lfp.time, 0);

    % remove first theta cycle from analysis unless stim pulse is part of
    % protocol
    if ~contains(lfp.protocol_name,'_pulseStart')
        lfp.cycle_start_index(1) = [];
    end

    nCycles = numel(lfp.cycle_start_index);
    
    cycles = 1:nCycles;
    
    for icycle = 1:numel(cycles)
           cycle = cycles(icycle);
           cycle_start = lfp.cycle_start_index(cycle);
           cycle_stop = cycle_start + lfp.cycle_length; 
           window_data_lfp = lfp.gamma_data(cycle_start:cycle_stop);
    
    %        figure;
    %        subplot(2,1,1)
    %        plot(window_data_lfp)
    %        subplot(2,1,2)
    %        plot(norm_stim(cycle_start:cycle_stop))
    
           [wt,freq] = cwt(window_data_lfp,'FilterBank',fb);
           if icycle == cycles(1)
               z = abs( wt ).^2;
           else
               z = z + abs( wt ).^2;
           end
    end
    z = z / nCycles;
    
    [x,y] = meshgrid(cycle_phase,freq);
    
end