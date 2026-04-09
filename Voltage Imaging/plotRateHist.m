function HistArray = plotRateHist(spikes, lfp, saveFolder, savenum)

% plot histogram of average +- SEM

edges = 0:10:400; % Hz
nbins = numel(edges) - 1;

delta_bin = edges(2) - edges(1);
bin_midpoints = edges(1:end-1) + delta_bin/2;

nSelected = numel(spikes);
nCycles = numel(lfp.cycle_start_indices_ds);

HistArray = zeros(nSelected,nbins);

tickfontsize = 15;
titlefontsize = 15;

Color = [0 0 0];

fig = figure;
hold on;

for i = 1:nSelected 

    data_cell = spikes(i).FRs;

    if ~isempty(data_cell)
        maxNumEl = max(cellfun(@numel,data_cell));
        data_pad = cellfun(@(x){padarray(x(:),[maxNumEl-numel(x),0],NaN,'post')}, data_cell); % Pad each vector with NaN values to equate lengths
        data_mat = cell2mat(data_pad);
            
        [HistArray(i,:),~] = histcounts(data_mat,edges);
    end

end

HistArray = HistArray / nCycles; 

% plot histogram

if ~isempty(HistArray)

    % plot SEM
    meanData = mean(HistArray,1);
    SEM = std(HistArray,1) ./ sqrt(size(HistArray,1));
    meanData = reshape(meanData,1,[]); % column vector
    SEM = reshape(SEM,1,[]); % column vector
    xSEM = [bin_midpoints fliplr(bin_midpoints)] ;         
    ySEM = [meanData+SEM fliplr(meanData-SEM)];

    han1 = fill(xSEM,ySEM,Color);
    han1.FaceColor = Color;    
    han1.FaceAlpha = 0.4;      
    han1.EdgeColor = 'none'; 
    drawnow;

    % plot mean
    plot(bin_midpoints,meanData,'Color',Color);

    % plot example
%     if ~isempty(exampleData)
%         plot(bin_midpoints,exampleData,'Color',Color,'LineStyle','--');
%     end

end

hold off
xlim([min(edges) max(edges)])

ymax = 1;
ylim([0 ymax]);

xlabel('Interspike Firing Rate (Hz)')
ylabel('Counts (1 / Theta Cycle)')


[~,folderName,~] = fileparts(lfp.dataPath);
plotTitle = sprintf( '%s - Stim: %g Hz',folderName,lfp.stim_freq );
sgtitle(plotTitle,'FontSize',titlefontsize,'FontWeight','bold','Interpreter','none');

ax = gca;
ax.YTick = 0:0.2:ymax;
ax.YAxis.FontSize = tickfontsize;
ax.YAxis.FontWeight = 'bold';
ax.XAxis.FontSize = tickfontsize;
ax.XAxis.FontWeight = 'bold';

if savenum == 1
    saveName = 'Firing Rate Histogram';
    print(fig,'-vector','-dsvg',[saveFolder filesep saveName '.svg']) % svg
end


end