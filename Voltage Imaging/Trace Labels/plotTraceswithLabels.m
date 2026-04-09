function plotTraceswithLabels(selectNeurons, frame_rate, dataPath, savenum, PVlabels)
% plot traces and Spikes

nSelected = numel(selectNeurons);
nFrames = numel(selectNeurons{1}.raw_trace);

% normalize traces and plot on the same axis for visualization
time = (0:nFrames-1)/frame_rate;

figure('WindowState', 'maximized');
for i = 1:nSelected
    trace = selectNeurons{i}.raw_trace;
    normTrace =  (trace - min(trace)) / (max(trace) - min(trace));
    plotTrace = normTrace + i - 0.5;
    color = 'k';
    if ~isempty(PVlabels) 
        if PVlabels(i) == 1
            color = 'm';
        end
    end
    plot(time,plotTrace, color,'Linewidth',1); hold on, % plot trace
end

xlabel("Time (s)")

if nSelected < 10
    yticks(1:nSelected)
    yticklabels([string(1:nSelected)])
else
    traceTickMax = 5*floor(nSelected/5);
    traceTicks = [1 5:5:traceTickMax];
    yticks(traceTicks);
    yticklabels([string([1 5:5:traceTickMax]) ]);
end

ylim([0.1, nSelected + 1])

xlim([time(1) time(end)])

ax = gca;
ax.XAxis.FontSize = 20;
ax.YAxis.FontSize = 10;
ax.XAxis.FontWeight = 'bold';
ax.YAxis.FontWeight = 'bold';

box off

% sgtitle(sprintf( '%s - Stim: %g Hz - LFP Gamma: %d Hz',lfp.dataPath,lfp.stim_freq,round(lfp.maxValues(2)) ),'FontWeight','bold','Interpreter','none');


if savenum == 1
    if nargin < 5
        saveName = 'traces';
    else
        saveName = 'traces with spikes';
    end
    saveas(gcf,[dataPath filesep saveName '.fig']);
    saveas(gcf,[dataPath filesep saveName '.png']);
%     saveas(gcf,[dataPath filesep saveName '.svg']);
    %print(gcf,'-vector','-dsvg',['D:\traces and lfp high res no labels swap traces','.svg']) % svg
end

end