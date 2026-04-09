function plotSTAs(spikes, lfp, frame_rate, savenum)
% plot STAs for both theta and gamma

win_s = 0.1; % seconds

win = frame_rate * win_s; % samples
dt = 1 / frame_rate;
win_time = 1000*(-win_s:dt:win_s); % time in ms

nSelected = numel(spikes(1).locs);

for ii = 1:2
    
    if ii == 1 
        type = 'Theta';
        data = lfp.theta_data_ds(lfp.stim_indices_ds); % restrict time axis to stimulation period 
    else 
        type = 'Gamma';
        data = lfp.gamma_data_ds(lfp.stim_indices_ds); % restrict time axis to stimulation period 
    end
    
    STA = zeros(nSelected,2*win+1);
    phase0 = zeros(nSelected,1);
    amplitude = zeros(nSelected,1);

    for iNeuron = 1:nSelected 
        spike_mask = spikes.masks{iNeuron};
        spike_mask_stim = spike_mask(lfp.stim_indices_ds); % restrict time axis to stimulation period 
        spks = find(spike_mask_stim == 1);
        nSpikes = numel(spks);
    
        for iSpike = 1:nSpikes
            if (spks(iSpike) > win && spks(iSpike) + win < numel(data))
                STA(iNeuron,:) = STA(iNeuron,:) + data(spks(iSpike)-win:spks(iSpike)+win)/nSpikes;
            end
        end
    
        phases = angle(hilbert(STA(iNeuron,:))); % from -pi to pi
        phase0(iNeuron) = phases(win+1); % phase at time = 0
        amplitude(iNeuron) = range(STA(iNeuron,:));
    
    end

    % plot individual subplots
    if ii == 2
        subplotSTA(win_time,STA,lfp.data_units);
    end

    % plot STA
    figSTA = plotSTA(win_time,STA,lfp.data_units);
    title(sprintf('LFP %s STA (n=%d)', type, nSelected),'Fontsize',20,'Fontweight','bold');

    % plot histogram of STA phase and amplitudes
    figHist1 = plotPhaseHist(phase0);
    title(sprintf('LFP %s STA Phase (n=%d)', type, nSelected),'Fontsize',20,'Fontweight','bold');

    figHist2 = plotAmplitudeHist(amplitude,lfp.data_units);
    title(sprintf('LFP %s STA Amplitude (n=%d)', type, nSelected),'Fontsize',20,'Fontweight','bold');

    % phase-amplitude plot?
%     plotScatter();

    % theta vs gamma violin plots for phase and amplitude?

    if savenum
        saveas(figSTA,[lfp.dataPath filesep sprintf('LFP %s STA.png',type)]);
        saveas(figHist1,[lfp.dataPath filesep sprintf('LFP %s STA Phase.png',type)]);
        saveas(figHist2,[lfp.dataPath filesep sprintf('LFP %s STA Amplitude.png',type)]);
    end

    if ii == 1
        spikes.STA_theta_phase = phase0;
        spikes.STA_theta_amplitude = amplitude;
    else
        spikes.STA_gamma_phase = phase0;
        spikes.STA_gamma_amplitude = amplitude;
    end

end

    function figSTA = plotSTA(win_time,STA,units)
        tickfontsize = 15;
        % plot STA
        figSTA = figure;
        hold on
        plot(win_time, STA,'Color',0.5*[1 1 1]);
        plot(win_time, mean(STA),'k','Linewidth',2)
        plot([0 0],ylim,'r--');
        hold off
        xlabel('Time (ms)')
        ylabel(sprintf('STA (%s)',units));
        ax = gca;
        ax.YAxis.FontSize = tickfontsize;
        ax.YAxis.FontWeight = 'bold';
        ax.XAxis.FontSize = tickfontsize;
        ax.XAxis.FontWeight = 'bold';

    end

    function subplotSTA(win_time,STA,units)
        tickfontsize = 15;
        nRows = 5;
        nCols = 3;

        N = size(STA,1);
        maxPlots = nRows*nCols;
        nFigs = ceil(N / maxPlots);

        % plot STA
        for iFig = 1:nFigs
            fig = figure;
            for iPlot = 1:maxPlots
                i = (iFig-1)*maxPlots + iPlot; % trace number
                if (i > N); break; end
                subplot(nRows,nCols,iPlot)
                plot(win_time, STA(i,:),'k'); hold on;
                plot([0 0],ylim,'r--'); hold off;
                title(sprintf('neuron %d',i));
            end
            han = axes(fig,'visible','off'); 
            han.XLabel.Visible='on';
            han.YLabel.Visible='on';
            han.Title.Visible='on';
            xlabel(han,'Time (ms)','FontSize',tickfontsize,'FontWeight','bold');
            ylabel(han,sprintf('STA (%s)',units),'FontSize',tickfontsize,'FontWeight','bold');   
            title(han,sprintf('Gamma STA'),'FontSize',tickfontsize,'FontWeight','bold');
        end

    end


    function figHist = plotPhaseHist(data)
        tickfontsize = 15;
        nbins = 30;
        edges = linspace(-pi,pi,nbins+1);
%         delta_bin = edges(2) - edges(1);
%         bin_midpoints = edges(1:end-1) + delta_bin/2;
%         [N,~] = histcounts(data,edges);

        figHist = figure;
%         plot(bin_midpoints,N,'LineStyle','-','Color','k','Linewidth',2);
        histogram(data,edges);
    %     ylim([0 1])
        xlim([-pi pi])
        xlabel('Phase (rad)')
        ylabel('Counts')
        ax = gca;
    %     ax.YTick = 0:0.2:1;
        ax.YAxis.FontSize = tickfontsize;
        ax.YAxis.FontWeight = 'bold';
        ax.XAxis.FontSize = tickfontsize;
        ax.XAxis.FontWeight = 'bold';
        %     ax.YTickLabel = round([0 0.5 1]);
    end
    
    function figHist = plotAmplitudeHist(data,units)
        tickfontsize = 15;

        nbins = 30;
%         [N,edges] = histcounts(data,nbins);
%         delta_bin = edges(2) - edges(1);
%         bin_midpoints = edges(1:end-1) + delta_bin/2;

        figHist = figure;
%         plot(bin_midpoints,N,'LineStyle','-','Color','k','Linewidth',2);
        histogram(data,nbins);
        xlabel(sprintf('Amplitude (%s)',units))
        ylabel('Counts')
        ax = gca;
    %     ax.YTick = 0:0.2:1;
        ax.YAxis.FontSize = tickfontsize;
        ax.YAxis.FontWeight = 'bold';
        ax.XAxis.FontSize = tickfontsize;
        ax.XAxis.FontWeight = 'bold';
        %     ax.YTickLabel = round([0 0.5 1]);
    end

end