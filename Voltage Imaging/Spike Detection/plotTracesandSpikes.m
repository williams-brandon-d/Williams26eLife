function fig = plotTracesandSpikes(selectNeurons, frame_rate, saveFolder, savenum, spikes, selectTraceIdx)
% plot traces and Spikes

fieldNames = {'raw','hpf','noMotion'};

nSelected = numel(selectNeurons);

maxPlotTraces = 10;

% normalize traces and plot on the same axis for visualization

for ii = 1:numel(fieldNames)
    fieldName = fieldNames{ii};

    nPlots = ceil(nSelected/maxPlotTraces);

    for iPlot = 1:nPlots
        if iPlot < nPlots
            trace_indices = (iPlot-1)*maxPlotTraces + (1:maxPlotTraces);
        else

            trace_indices = (((iPlot-1)*maxPlotTraces)+1):nSelected;
        end

        fig = plotTraces(selectNeurons,spikes,trace_indices,fieldName,frame_rate,selectTraceIdx);  
        
        if savenum
            print(fig,'-vector','-dsvg',[saveFolder filesep fieldName num2str(iPlot) ' traces with spikes.svg']) % svg
        end
    end

end


    function fig = plotTraces(selectNeurons,spikes,trace_indices,fieldName,frame_rate,selectTraceIdx)

            traceNeurons = selectNeurons(trace_indices);

            N = numel(traceNeurons);

            fig = figure('WindowState', 'maximized');
            hold on;

            for i = 1:N
                trace = traceNeurons{i}.([fieldName '_trace']);
                traceIdx = trace_indices(i);

                normTrace =  (trace - min(trace)) / (max(trace) - min(trace));
                plotTrace = normTrace + i - 0.5;

                nFrames = numel(trace);
                time = (0:nFrames-1)/frame_rate;

                if any(selectTraceIdx == traceIdx)
                    plot(time,plotTrace, 'k','Linewidth',1); % plot select trace
                else
                    plot(time,plotTrace,'m','Linewidth',1) % plot unselected trace
                end

                if ~isempty(spikes(traceIdx).locs)
                    plot(time(spikes(traceIdx).locs),i+0.5,'.r','MarkerSize',6); % plot spikes
                end

            end
            
            xlabel("Time (s)")
            
            if N < 10
                yticks(1:N)
                yticklabels(string(trace_indices))
            else
                factor = 5;
                traceTicks = [1 factor*(1:floor(N/factor))];
                yticks(traceTicks);
                yticklabels(string(trace_indices(traceTicks)));
            end
            
            ylim([0.1, N + 1]) 
            xlim([time(1) time(end)])
            
            ax = gca;
            ax.XAxis.FontSize = 20;
            ax.YAxis.FontSize = 10;
            ax.XAxis.FontWeight = 'bold';
            ax.YAxis.FontWeight = 'bold';
            box off   

    end


end