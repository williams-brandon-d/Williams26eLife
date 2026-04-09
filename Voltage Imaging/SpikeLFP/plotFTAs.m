function plotFTAs(spikes, lfp, savenum)
% plot the field triggered average for each neuron

nSelected = numel(spikes(1).locs);
nSamples = numel(lfp.stim_indices_ds);

for ii = 1:2
    
    if ii == 1 
        type = 'Theta';
        phi = lfp.theta_phase_ds(lfp.stim_indices_ds); % restrict time axis to stimulation period 
        phase = linspace(-pi,pi,nSamples);
        phaseTicks = [-pi -pi/2 0 pi/2 pi];
        phaseTickLabels = {'-\pi','-\pi/2','0','\pi/2','\pi'};
%         phi = wrapTo2Pi(unwrap(phi));
%         phase = linspace(0,2*pi,nSamples);
%         phaseTicks = [0 pi/2 pi 3*pi/2 2*pi];
%         phaseTickLabels = {'0','\pi/2','\pi','3\pi/2','2\pi'};
    else 
        type = 'Gamma';
        phi = lfp.gamma_phase_ds(lfp.stim_indices_ds); % restrict time axis to stimulation period 
        phase = linspace(-pi,pi,nSamples);
        phaseTicks = [-pi -pi/2 0 pi/2 pi];
        phaseTickLabels = {'-\pi','-\pi/2','0','\pi/2','\pi'};
    end

    [~,sorted_idx] = sort(phi);

    FTA = zeros(nSelected,nSamples);

    for iNeuron = 1:nSelected 
        spike_mask = spikes.masks{iNeuron};
        spike_mask_stim = spike_mask(lfp.stim_indices_ds); % restrict time axis to stimulation period 
        FTA(iNeuron,:) = spike_mask_stim(sorted_idx);  
    end

    figFTA = plotFTA(phase,FTA,phaseTicks,phaseTickLabels);     % plot FTA
    title(sprintf('LFP %s FTA (n=%d)', type, nSelected),'Fontsize',20,'Fontweight','bold');

    if savenum
        saveas(figFTA,[lfp.dataPath filesep sprintf('LFP %s FTA.png',type)]);
    end

end

    function figFTA = plotFTA(phase,FTA,phaseTicks,phaseTickLabels)
        tickfontsize = 15;
        % plot FTA
        figFTA = figure;
        hold on
        plot(phase, FTA,'Color',0.5*[1 1 1]);
        plot(phase, mean(FTA),'k','Linewidth',2)
        hold off
        xlim([phase(1) phase(end)])
        xlabel('Phase (rad)')
        ylabel('Bin counts');
        xticks(phaseTicks);
        xticklabels(phaseTickLabels);
        ax = gca;
        ax.YAxis.FontSize = tickfontsize;
        ax.YAxis.FontWeight = 'bold';
        ax.XAxis.FontSize = tickfontsize;
        ax.XAxis.FontWeight = 'bold';

    end

end