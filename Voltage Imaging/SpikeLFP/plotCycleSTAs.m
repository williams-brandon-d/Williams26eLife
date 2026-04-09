function plotCycleSTAs(spikes, lfp, frame_rate, saveFolder, savenum)
% plot STAs for both theta and gamma

% compute STA for each first, second, third spike etc.
% use spike raster data window by stim theta cycle
% find max number of spikes in a theta cycle and compute STA for each spike number 

dataTypes = {'Theta','Gamma'};
titlefontsize = 15;

win_s = 0.1; % seconds

win = frame_rate * win_s; % samples
dt = 1 / frame_rate;
win_time = 1000*(-win_s:dt:win_s); % time in ms

nSelected = numel(spikes);
nCycles = numel(lfp.cycle_start_indices_ds);
nDataTypes = numel(dataTypes);

switch lfp.stim_freq
    case 4
        maxSpikes = 6;
    case 8
        maxSpikes = 4;
    case {12, 16}
        maxSpikes = 2;
end

%  maxSpikes = max(cellfun(@numel,spikes.raster_stim{iNeuron}),[],1); % get max number of spikes in all cycles         

for iData = 1:nDataTypes
    type = dataTypes{iData};
    switch type
        case 'Theta'
            data = lfp.theta_data_ds;
        case 'Gamma' 
            data = lfp.gamma_data_ds;
    end
    
    phase0 = zeros(nSelected,maxSpikes);
    amplitude = zeros(nSelected,maxSpikes);
    STA = zeros(nSelected,2*win+1,maxSpikes);

    for iNeuron = 1:nSelected 
        spike_mask = [spikes(iNeuron).masks];

        for iSpike = 1:maxSpikes
            raster_cell = cell(nCycles,1); % make raster cell for each trace
            
            for iCycle =  1:nCycles
                cycle_start_index = lfp.cycle_start_indices_ds(iCycle);
                cycle_indices = cycle_start_index + (0:lfp.cycle_length_ds);
                spike_mask_stim = spike_mask(cycle_indices); % restrict time axis to stim cycle
                cycle_spike_indices = find(spike_mask_stim);

                if numel(cycle_spike_indices) < iSpike
                    raster_cell{iCycle} = double.empty(1,0); 
                else
                    raster_cell{iCycle} = cycle_start_index - 1 + cycle_spike_indices(iSpike); % iSpike index in data indices
                end

            end
            
            raster_cell = raster_cell(~cellfun('isempty',raster_cell)); % remove empty cells 
            nSpikes = numel(raster_cell); % number of non empty cells from all cycles
            
            for ii = 1:nSpikes
                idx = raster_cell{ii};
                if (idx > win && idx + win < numel(data))
                    STA(iNeuron,:,iSpike) = STA(iNeuron,:,iSpike) + data(idx-win:idx+win)/nSpikes; % average STA over all cycles
                end
            end
        
            phases = angle(hilbert(STA(iNeuron,:,iSpike))); % from -pi to pi
            phase0(iNeuron,iSpike) = phases(win+1); % phase at time = 0
            amplitude(iNeuron,iSpike) = range(STA(iNeuron,:,iSpike));
        end
    
    end

%     % plot individual subplots
%     if iData == 2
%         subplotSTA(win_time,STA,lfp.data_units);
%     end

    % plot STA
    figSTA = plotSTA(win_time,STA,lfp.data_units);
%     title(sprintf('%s STA', type),'Fontsize',titlefontsize,'Fontweight','bold');

    % plot histogram of STA phase and amplitudes
    figHist1 = plotPhaseHist(phase0);
    title(sprintf('%s STA Phase', type),'Fontsize',titlefontsize,'Fontweight','bold');

    figHist2 = plotAmplitudeHist(amplitude,lfp.data_units);
    title(sprintf('%s STA Amplitude', type),'Fontsize',titlefontsize,'Fontweight','bold');

%     % phase-amplitude plot?
% %     plotScatter();
% 
%     % theta vs gamma violin plots for phase and amplitude?

    if savenum
        print(figSTA,'-vector','-dsvg',[saveFolder filesep sprintf('LFP %s Cycle STA.svg',type)]) % svg
        print(figHist1,'-vector','-dsvg',[saveFolder filesep sprintf('LFP %s Cycle STA Phase.svg',type)]) % svg
        print(figHist2,'-vector','-dsvg',[saveFolder filesep sprintf('LFP %s Cycle STA Amplitude.svg',type)]) % svg
    end

%     if iData == 1
%         spikes.STA_theta_phase = phase0;
%         spikes.STA_theta_amplitude = amplitude;
%     else
%         spikes.STA_gamma_phase = phase0;
%         spikes.STA_gamma_amplitude = amplitude;
%     end

end

    function fig = plotSTA(win_time,STA,units)

        nSubplots  = size(STA,3);
        tickfontsize = 10;
        labelfontsize = 15;
        color = [0 0 0];

        % plot STA
        fig = figure('WindowState', 'maximized');
        for iPlot = 1:nSubplots
            spikeSTA = squeeze(STA(:,:,iPlot));

            meanData = mean(spikeSTA,1);
            SEM = std(spikeSTA,1) ./ sqrt(size(spikeSTA,1));
            meanData = reshape(meanData,1,[]); % column vector
            SEM = reshape(SEM,1,[]); % column vector

            xSEM = [win_time fliplr(win_time)] ;         
            ySEM = [meanData+SEM fliplr(meanData-SEM)];

            subplot(1,nSubplots,iPlot); 
            hold on
%             plot(win_time, spikeSTA,'Color',0.5*[1 1 1]);

            % plot SEM
            han1 = fill(xSEM,ySEM,color);
            han1.FaceColor = color;    
            han1.FaceAlpha = 0.4;      
            han1.EdgeColor = 'none'; 
            drawnow;

            % plot mean
            plot(win_time, meanData,'Color',color,'Linewidth',1)

            title(sprintf('Cycle Spike %d',iPlot));
            pbaspect([1 1 1])
            ax = gca;
            ax.YAxis.FontSize = tickfontsize;
            ax.YAxis.FontWeight = 'bold';
            ax.XAxis.FontSize = tickfontsize;
            ax.XAxis.FontWeight = 'bold';

            % plot dashed line at t = 0
            plot([0 0],ylim,'r--');
            hold off

            if iPlot == 1 
                ax1 = ax;
            end
        end

        % Give common xlabel, ylabel and title to your figure
        han=axes(fig,'visible','off'); 
        han.Title.Visible='on';
        han.XLabel.Visible='on';
        han.YLabel.Visible='on';
        ylabel(ax1,sprintf('%s STA (%s)',type,units),'FontSize',labelfontsize,'FontWeight','bold');
        xlabel(ax1,'Time (ms)','FontSize',labelfontsize,'FontWeight','bold');
%         title(han,sprintf('Cycle Spike %d',iPlot),'FontSize',tickfontsize,'FontWeight','bold');
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
                ax = gca;
                ax.YAxis.FontSize = tickfontsize;
                ax.YAxis.FontWeight = 'bold';
                ax.XAxis.FontSize = tickfontsize;
                ax.XAxis.FontWeight = 'bold';
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


    function fig = plotPhaseHist(data)

        % change to violin plots

        nPlots = size(data,2);
        tickfontsize = 15;
        nbins = 30;
        edges = linspace(-pi,pi,nbins+1);

        fig = figure;
        for iPlot = 1:nPlots
            subplot(nPlots,1,iPlot);
            histogram(data(:,iPlot),edges);
            xlim([-pi pi])
            title(sprintf('Cycle Spike %d',iPlot));
            xticks([-pi -pi/2 0 pi/2 pi]);
            xticklabels({'-\pi','-\pi/2','0','\pi/2','\pi'});
            ax = gca;
            ax.YAxis.FontSize = tickfontsize;
            ax.YAxis.FontWeight = 'bold';
            ax.XAxis.FontSize = tickfontsize;
            ax.XAxis.FontWeight = 'bold';
        end

        han = axes(fig,'visible','off'); 
        han.XLabel.Visible='on';
        han.YLabel.Visible='on';
        han.Title.Visible='on';
        xlabel(han,'Phase (rad)','FontSize',tickfontsize,'FontWeight','bold');
        ylabel(han,'Counts','FontSize',tickfontsize,'FontWeight','bold');   
    end
    
    function fig = plotAmplitudeHist(data,units)

        % change to violin plots

        nPlots = size(data,2);
        tickfontsize = 15;
        nbins = 30;

        fig = figure;
        for iPlot = 1:nPlots
            subplot(nPlots,1,iPlot);
            histogram(data(:,iPlot),nbins);
            title(sprintf('Cycle Spike %d',iPlot));
            ax = gca;
            ax.YAxis.FontSize = tickfontsize;
            ax.YAxis.FontWeight = 'bold';
            ax.XAxis.FontSize = tickfontsize;
            ax.XAxis.FontWeight = 'bold';
        end

        han = axes(fig,'visible','off'); 
        han.XLabel.Visible='on';
        han.YLabel.Visible='on';
        han.Title.Visible='on';
        xlabel(han,sprintf('Amplitude (%s)',units),'FontSize',tickfontsize,'FontWeight','bold');
        ylabel(han,'Counts','FontSize',tickfontsize,'FontWeight','bold'); 
    end

end