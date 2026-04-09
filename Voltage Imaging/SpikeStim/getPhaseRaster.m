function getPhaseRaster(spikes, lfp, frame_rate)
% get spike raster for phase data 



nSelected = numel(spikes(1).locs);

nCycles = numel(lfp.cycle_start_index);

cycle_length = frame_rate / lfp.stim_freq;

delta_phase = 2*pi/cycle_length;
cycle_phase = -pi:delta_phase:pi; 
cycle_phase = cycle_phase';


for i = 1:nSelected 

    % make raster cell for each trace
    raster_cell = cell(nCycles,1);
    spike_indices = spikes.locs{i};
    spike_mask = spikes.masks{i};
    plotFlag = 0;

    for icycle = 1:nCycles

        cycle_indices = round( (lfp.cycle_start_index(icycle) - lfp.offset_shift) / ds_ratio) + (0:cycle_length);
        cycle_spike_indices = (spike_indices >= cycle_indices(1)) & (spike_indices <= cycle_indices(end));
        phase_spike_indices = spike_indices(cycle_spike_indices) - cycle_indices(1) + 1;

        if (numel(phase_spike_indices) > 0)
            raster_cell{icycle,:} = cycle_phase(phase_spike_indices)';
            plotFlag = 1;
        else
            raster_cell{icycle,:} = double.empty(1,0); 
        end

    end

    spikes.raster_stim{i} = raster_cell;

end
