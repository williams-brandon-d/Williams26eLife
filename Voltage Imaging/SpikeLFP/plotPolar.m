function plotPolar(spikeMasks, lfp, saveFolder, savenum)

    tickfontsize = 20;
    
    nSelected = numel(spikeMasks);
    spikes_cell = cell(nSelected,1);

    switch lfp.stim_freq
        case 4
            nbins = 100;
        case 8
            nbins = 50;
        case 12
            nbins = 33;
        case 16
            nbins = 25;
    end

    for ii = 1:2
        
        if ii == 1 
            type = 'Theta';
            phase_stim = lfp.theta_phase_ds(lfp.stim_indices_ds);
            color = [1 0 0];
        else 
            type = 'Gamma';
            phase_stim = lfp.gamma_phase_ds(lfp.stim_indices_ds);
            color = [0 0 1];
        end

        edges = linspace(-pi,pi,nbins+1);

        for i = 1:nSelected 
            % restrict time axis to stimulation period 
            spike_mask = spikeMasks{i};
            spike_mask_stim = spike_mask(lfp.stim_indices_ds);
            spikes_cell{i} =  phase_stim(spike_mask_stim);
        end
    
        maxNumEl = max(cellfun(@numel,spikes_cell));
        spikes_pad = cellfun(@(x){padarray(x(:),[maxNumEl-numel(x),0],NaN,'post')}, spikes_cell); % Pad each vector with NaN values to equate lengths
        spikes_mat = cell2mat(spikes_pad);
        
        fig = figure;
        polarhistogram(spikes_mat,edges,'FaceColor',color,'FaceAlpha',1,'Normalization','probability');
        ax = gca;
        ax.ThetaZeroLocation = 'top';
        ax.ThetaDir = 'clockwise'; % 90 degrees at the right
        ax.ThetaTick = [0 90 180 270];
        ax.ThetaTickLabels = {'0','π/2','π/-π','-π/2',};
        ax.FontSize = tickfontsize;
        ax.FontWeight = 'bold';

        if ii == 1 % save rticks from theta histogram
            rlim = get(ax,'RLim');
        elseif ii == 2 % use same ticks for gamma histogram
            ax.RLim = [0 max(rlim)];
        end

        title(sprintf('LFP %s Spike Phase - Stim: %g Hz', type, lfp.stim_freq),'Fontsize',16,'Fontweight','bold');
    
        if savenum
            print(fig,'-vector','-dsvg',[saveFolder filesep sprintf('LFP %s Phase Spike Timing.svg',type) '.svg']) % svg
        end
        
    end

end