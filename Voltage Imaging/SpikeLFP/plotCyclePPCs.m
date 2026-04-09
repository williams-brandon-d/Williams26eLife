function [thetaPPC,gammaPPC] = plotCyclePPCs(spikeMasks, lfp, saveFolder, savenum)

minTotalSpikes = 10;

types = {'Theta','Gamma'};

switch lfp.stim_freq
    case 4
        maxSpikes = 6;
    case 8
        maxSpikes = 4;
    case {12, 16}
        maxSpikes = 2;
end

nTypes = numel(types);
nSelected = numel(spikeMasks);
nCycles = numel(lfp.cycle_start_indices_ds);

for ii = 1:nTypes
    type = types{ii};

    switch type
        case 'Theta'
            phi = lfp.theta_phase_ds; 
            color = [1 0 0];
        case 'Gamma'
            phi = lfp.gamma_phase_ds;
            color = [0 0 1];
    end

    ppc0 = zeros(nSelected,maxSpikes);

    for iNeuron = 1:nSelected 
        spike_mask = spikeMasks{iNeuron};

         for iSpike = 1:maxSpikes
            phase_cell = cell(nCycles,1); % make raster cell for each trace
            
            for iCycle =  1:nCycles
                cycle_start_index = lfp.cycle_start_indices_ds(iCycle);
                cycle_indices = cycle_start_index + (0:lfp.cycle_length_ds);
                spike_mask_stim = spike_mask(cycle_indices); % restrict time axis to stim cycle
                cycle_spike_indices = find(spike_mask_stim);

                if numel(cycle_spike_indices) < iSpike
                    phase_cell{iCycle} = double.empty(1,0); 
                else
                    phase_cell{iCycle} = phi(cycle_spike_indices(iSpike));
                end

            end

            phase_cell = phase_cell(~cellfun('isempty',phase_cell)); % remove empty cells 
            phases = cell2mat(phase_cell);

            % if number of cycles with spikes is < 10... do not record PPC
            if numel(phases) < minTotalSpikes
                ppc0(iNeuron,iSpike) = NaN;
            else
                ppc0(iNeuron,iSpike) = PPC(phases); 
            end

        end


    end

    fig = plotPPC(ppc0,color,[]); % plot PPC
    title(sprintf('LFP %s PPC', type),'Fontsize',20,'Fontweight','bold');
    
    if savenum
        print(fig,'-vector','-dsvg',[saveFolder filesep sprintf('LFP %s cyclePPC.png',type) '.svg']) % svg
    end

    if ii == 1
       thetaPPC = ppc0;
    else
        gammaPPC = ppc0;
    end

end


    function fig = plotPPC(ppc0,color,xlabel)
        % add nice colors
%         c =  [0.45, 0.80, 0.69;...
%               0.98, 0.40, 0.35;...
%               0.55, 0.60, 0.79;...
%               0.90, 0.70, 0.30]; 

        % check if any columns are all NaN - remove group but save correct labels
        nGroups = size(ppc0,2);

        lin_ppc0 = ppc0(:);

        nan_mask = isnan(lin_ppc0);
        lin_ppc0(nan_mask) = []; % remove NaNs from linear array

        groups = ones(numel(ppc0),1);
        for i = 2:nGroups
            idx_start = ((i-1)*size(ppc0,1)) + 1;
            idx_stop = idx_start + size(ppc0,1) - 1;
            groups(idx_start:idx_stop) = i*ones(size(ppc0,1),1);
        end
        groups(nan_mask) = []; % remove NaNs from linear array

        newGroups = unique(groups);
        newNGroups = numel(newGroups);

        colors = repmat(color,[newNGroups, 1]);

        labels = cell(newNGroups,1);
        for iGroup = 1:newNGroups
            group = newGroups(iGroup);
%             ppc_group = lin_ppc0(groups == group);
%             N = numel(ppc_group);
%             labels{iGroup} = sprintf('%s_{Spike%d} (n=%d)',cellType,group,N);
            if isempty(xlabel)
                labels{iGroup} = sprintf('Spike{%d}',group);
            else
                labels{iGroup} = sprintf('%s_{Spike%d}',xlabel,group);
            end
        end

        tickfontsize = 15;

        % plot PPC
        fig = figure;
        if ~isempty(lin_ppc0)
            if isempty(color)
                daviolinplot(lin_ppc0,'groups',groups,'xtlabels',labels); % default colors
            else
                daviolinplot(lin_ppc0,'groups',groups,'xtlabels',labels,'color',colors); % my colors
            end
        end
        ylim([-0.5 1.5])
        ylabel({'Pairwise Phase';'Consistency'});
        ax = gca;
        ax.YAxis.FontSize = tickfontsize;
        ax.YAxis.FontWeight = 'bold';
        ax.XAxis.FontSize = tickfontsize;
        ax.XAxis.FontWeight = 'bold';
    end


end