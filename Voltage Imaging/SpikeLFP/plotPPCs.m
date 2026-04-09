function plotPPCs(spikes, lfp, savenum)

types = {'Theta','Gamma'};
nTypes = numel(types);

nSelected = numel(spikes(1).locs);

ppc0 = zeros(nSelected,nTypes);

for ii = 1:nTypes
    type = types{ii};

    switch type
        case 'Theta'
            phi = lfp.theta_phase_ds(lfp.stim_indices_ds); % restrict time axis to stimulation period 
        case 'Gamma'
            phi = lfp.gamma_phase_ds(lfp.stim_indices_ds); % restrict time axis to stimulation period 
    end

    for iNeuron = 1:nSelected 
        spike_mask = spikes.masks{iNeuron};
        spike_mask_stim = spike_mask(lfp.stim_indices_ds); % restrict time axis to stimulation period 
        phases = phi(spike_mask_stim); % spike phases during stim period
        ppc0(iNeuron,ii) = PPC(phases);  
    end

    fig = plotPPC(ppc0,types); % plot PPC
    title(sprintf('LFP PPC (n=%d)', nSelected),'Fontsize',20,'Fontweight','bold');
    
    if savenum
        saveas(fig,[lfp.dataPath filesep 'LFP PPC.png']);
    end

end

fig = plotPPC(ppc0,types); % plot PPC
title(sprintf('LFP PPC (n=%d)', nSelected),'Fontsize',20,'Fontweight','bold');

if savenum
    saveas(fig,[lfp.dataPath filesep 'LFP PPC.png']);
end

    function fig = plotPPC(ppc0,labels)
        % use fancy violin plot instead of boxplot
        % add nice colors
%         c =  [0.45, 0.80, 0.69;...
%               0.98, 0.40, 0.35;...
%               0.55, 0.60, 0.79;...
%               0.90, 0.70, 0.30]; 

        nGroups = numel(labels);
        groups = ones(size(ppc0,1),size(ppc0,2));

        for i = 2:nGroups
            groups(:,i) = i*ones(size(ppc0,1),1);
        end

        tickfontsize = 15;
        % plot PPC
        fig = figure;
%         boxplot(ppc0,'Labels',labels);
        daviolinplot(ppc0(:),'groups',groups(:),'xtlabels',labels);
%         daviolinplot(ppc0(:),'groups',groups,'xtlabels',labels,'color',c(1:2,:));
        ylim([-0.5 1])
        ylabel('Pairwise Phase Consistency');
        ax = gca;
        ax.YAxis.FontSize = tickfontsize;
        ax.YAxis.FontWeight = 'bold';
        ax.XAxis.FontSize = tickfontsize;
        ax.XAxis.FontWeight = 'bold';
    end

end