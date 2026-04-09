function allFRs = getFRs(spikes,lfp)

nSelected = numel(spikes);
nCycles = numel(lfp.cycle_start_indices_ds);

dt = lfp.time_ds(2) - lfp.time_ds(1);

allFRs = cell(nSelected,1);

for i = 1:nSelected 

    FRs = cell(nCycles,1); % make raster cell for each trace
    spike_indices = spikes(i).locs;

    for icycle = 1:nCycles

        cycle_indices = lfp.cycle_start_indices_ds(icycle) + (0:lfp.cycle_length_ds);
        cycle_spike_indices = (spike_indices >= cycle_indices(1)) & (spike_indices <= cycle_indices(end));
        phase_spike_indices = spike_indices(cycle_spike_indices) - cycle_indices(1) + 1;

        if (numel(phase_spike_indices) > 0)
            FRs{icycle,:} = 1./(diff(phase_spike_indices)*dt); % Hz
        else
            FRs{icycle,:} = double.empty(1,0); 
        end

    end

    % remove empty cells before concatentation
    FRs = FRs(~cellfun(@isempty,FRs));

    allFRs{i} = cell2mat(FRs);

end


end