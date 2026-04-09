function lfp = downsampleLFP(lfp, frame_rate)
    % downsample lfp data using cubic interpolation

    lfp.time_ds = (0:(lfp.nFrames-1))/frame_rate;

    method = 'cubic';
    lfp.lfp_data_ds = interp1(lfp.time, lfp.lfp_data, lfp.time_ds, method);
    lfp.theta_data_ds = interp1(lfp.time, lfp.theta_data, lfp.time_ds, method);
    lfp.gamma_data_ds = interp1(lfp.time, lfp.gamma_data, lfp.time_ds, method);
    
    % plotds(lfp.time,lfp.theta_data,spikes.time,lfp.theta_data_ds);
    % plotds(lfp.time,lfp.gamma_data,spikes.time,lfp.gamma_data_ds);

    % get downsampled stim indices
    lfp.ds_ratio = lfp.Fs / frame_rate;
    lfp.cycle_length_ds = round(frame_rate / lfp.stim_freq);
    
    stim_start_index = round( (lfp.cycle_start_index(1)) / lfp.ds_ratio);
    stim_stop_index = round( (lfp.cycle_start_index(end)) / lfp.ds_ratio) + lfp.cycle_length_ds;
    lfp.stim_indices_ds = stim_start_index:stim_stop_index;  % restrict time axis to stimulation period 
    
    % get downsampled stim cycle start indices
    lfp.cycle_start_indices_ds = round( (lfp.cycle_start_index) / lfp.ds_ratio);

%     lfp.stim_data_ds = interp1(lfp.time, lfp.stim_data, spikes.time, method);
%     figure;
%     plot(spikes.time,lfp.stim_data_ds,'-k',...
%         spikes.time(stim_start_index),lfp.stim_data_ds(stim_start_index),'or',...
%         spikes.time(stim_stop_index),lfp.stim_data_ds(stim_stop_index),'ob');

end