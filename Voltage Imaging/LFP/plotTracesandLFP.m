function plotTracesandLFP(selectNeurons, frame_rate, lfp, saveFolder, savenum, spikes, PVlabels)
% plot traces and LFP

nSelected = numel(selectNeurons);
nFrames = numel(selectNeurons{1}.raw_trace);

% normalize traces and plot on the same axis for visualization
time = (0:nFrames-1)/frame_rate;

% for each fieldname - raw and noMotion
fieldNames = {'raw','noMotion'};

for ii = 1:numel(fieldNames)
    fieldName = fieldNames{ii};

    if ~isfield(selectNeurons{1}, [fieldName '_trace'])
        continue; % skip if not a field
    end

    
    figure('WindowState', 'maximized');
    for i = 1:nSelected
        trace = selectNeurons{i}.([fieldName '_trace']);
        normTrace =  (trace - min(trace)) / (max(trace) - min(trace));
        plotTrace = normTrace + i - 0.5;
        if PVlabels(i) == 1
            color = 'm';
        else
            color = 'k';
        end
        plot(time,plotTrace, color,'Linewidth',1); hold on, % plot trace
        if any(spikes)
            plot(time(spikes.locs{i}),plotTrace(spikes.locs{i}),'or') % plot spikes
        end
    end
    
    xlabel("Time (s)")
    
    trace = lfp.gamma_data;
    normLFP = (trace - min(trace)) / (max(trace) - min(trace));
    
    han1 = plot(lfp.time,normLFP - 0.5,'b','Linewidth',1,'DisplayName','LFP Gamma');
    
    trace = lfp.theta_data;
    normLFP = (trace - min(trace)) / (max(trace) - min(trace));
    
    han2 = plot(lfp.time,normLFP - 1.5,'r','Linewidth',2,'DisplayName','LFP Theta');
    
    trace = lfp.stim_data;
    normStim = (trace - min(trace)) / (max(trace) - min(trace));
    
    han3 = plot(lfp.time,normStim - 2.5,'Color',[91, 207, 244] / 255,'Linewidth',2,'DisplayName','Stim');
    % han3 = fill(time(mask_indices),norm_stim(mask_indices),'b','DisplayName','Light');
    % han3.FaceColor =  [91, 207, 244] / 255; % light blue
    % han3.EdgeColor = han3.FaceColor;
    
    intervals = 10;
    
    if nSelected < intervals
    %     yticks(-2:nSelected)
    %     yticklabels(["Stim","Theta","Gamma",string(1:nSelected)])
        yticks(1:nSelected)
        yticklabels(string(1:nSelected))
    else
        traceTickMax = intervals*floor(nSelected/intervals);
        traceTicks = [1 intervals:intervals:traceTickMax];
        yticks(traceTicks);
        yticklabels(string([1 intervals:intervals:traceTickMax]));
    end
    
    ylim([-2.9, nSelected + 1])
    
    xlim([time(1) time(end)])
    
    ax = gca;
    ax.XAxis.FontSize = 20;
    ax.YAxis.FontSize = 20;
    ax.XAxis.FontWeight = 'bold';
    ax.YAxis.FontWeight = 'bold';
    
    box off
    
    lgd = legend([han1 han2 han3],'Location','northeastoutside');
    lgd.FontSize = 14;
    lgd.FontWeight = 'bold';
    lgd.Box = 'off';
    
    % [~,folderName,~] = fileparts(lfp.dataPath);
    % sgtitle(sprintf( '%s - Stim: %g Hz - LFP Gamma: %d Hz',folderName,lfp.stim_freq,round(lfp.maxValues(2)) ),'FontWeight','bold','Interpreter','none');
    
    
    if savenum
        if any(spikes)
            saveName = 'traces with spikes and lfp';
        else
            saveName = 'traces and lfp';
        end
        saveas(gcf,[saveFolder filesep saveName fieldName '.fig']);
        print(gcf,'-vector','-dsvg',[saveFolder filesep saveName fieldName '.svg']) % forces vector graphics rendering
    end

end

end