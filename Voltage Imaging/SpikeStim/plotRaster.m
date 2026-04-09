function spikes = plotRaster(spikes, lfp, plotnum, saveFolder, savenum)
% make Raster plots for each trace

tickfontsize = 15;
LineFormat = struct();
LineFormat.LineWidth = 2;
LineFormat.LineStyle = '-';

nSelected = numel(spikes);
nCycles = numel(lfp.cycle_start_indices_ds);

delta_phase = 2*pi/lfp.cycle_length_ds;
cycle_phase = -pi:delta_phase:pi; 
cycle_phase = cycle_phase';

dt = lfp.time_ds(2) - lfp.time_ds(1);

for i = 1:nSelected 

    raster_cell = cell(nCycles,1); % make raster cell for each trace
    FRs = raster_cell;
    spike_indices = spikes(i).locs;
    plotFlag = 0;

    for icycle = 1:nCycles

        cycle_indices = lfp.cycle_start_indices_ds(icycle) + (0:lfp.cycle_length_ds);
        cycle_spike_indices = (spike_indices >= cycle_indices(1)) & (spike_indices <= cycle_indices(end));
        phase_spike_indices = spike_indices(cycle_spike_indices) - cycle_indices(1) + 1;

        if (numel(phase_spike_indices) > 0)
            raster_cell{icycle,:} = cycle_phase(phase_spike_indices)';
            FRs{icycle,:} = 1./(diff(phase_spike_indices)*dt); % Hz
            plotFlag = 1;
        else
            raster_cell{icycle,:} = double.empty(1,0); 
            FRs{icycle,:} = double.empty(1,0); 
        end

    end

    spikes(i).raster_stim = raster_cell;
    spikes(i).FRs = FRs;

    if plotFlag && plotnum
    
       figure;
       [~, ~] = plotSpikeRaster(raster_cell,'PlotType','vertline','LineFormat',LineFormat);
       xlim([cycle_phase(1) cycle_phase(end)])
       ylim([0.5, nCycles + 0.5])
       xlabel('Theta Phase (rad)')
       ylabel('Theta Cycle #')
       xticks([-pi -pi/2 0 pi/2 pi]);
       xticklabels({'-π','-π/2','0','π/2','π'});
%            plotTitle = strjoin({ info(ID_index).cell_type info(ID_index).cell_num});
%            plotTitle = strjoin({info(ID_index).location info(ID_index).cell_type info(ID_index).cell_num info(ID_index).protocol info(ID_index).experiment});
%            plotTitle = sprintf('%s Light Power = %g',info(ID_index).cell_type,info(ID_index).led_input);
%            title(plotTitle,'FontSize',titlefontsize,'FontWeight','bold')
       ax = gca;
       ax.YAxis.FontSize = tickfontsize;
       ax.YAxis.FontWeight = 'bold';
       ax.XAxis.FontSize = tickfontsize;
       ax.XAxis.FontWeight = 'bold';
    end
    
end


% plot histogram of average +- SEM

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

edges = linspace(-pi,pi,nbins+1);

delta_bin = edges(2) - edges(1);
bin_midpoints = edges(1:end-1) + delta_bin/2;

HistArray = zeros(nSelected,nbins);

tickfontsize = 15;
titlefontsize = 15;

Color = [0 0 0];

fig = figure;
hold on;

for i = 1:nSelected 

    spikes_cell = spikes(i).raster_stim;

    if isempty(spikes_cell)
        continue;
    end
    
    maxNumEl = max(cellfun(@numel,spikes_cell));
    spikes_pad = cellfun(@(x){padarray(x(:),[maxNumEl-numel(x),0],NaN,'post')}, spikes_cell); % Pad each vector with NaN values to equate lengths
    spikes_mat = cell2mat(spikes_pad);
        
    [HistArray(i,:),~] = histcounts(spikes_mat,edges);

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
ylim([0 1])
xlim([-pi pi])
xticks([-pi -pi/2 0 pi/2 pi]);
xticklabels({'-π','-π/2','0','π/2','π'});
xlabel('Stim Phase (rad)')
ylabel('Spike Probability')

[~,folderName,~] = fileparts(lfp.dataPath);
plotTitle = sprintf( '%s - Stim: %g Hz',folderName,lfp.stim_freq );
sgtitle(plotTitle,'FontSize',titlefontsize,'FontWeight','bold','Interpreter','none');

ax = gca;
ax.YTick = 0:0.2:1;
ax.YAxis.FontSize = tickfontsize;
ax.YAxis.FontWeight = 'bold';
ax.XAxis.FontSize = tickfontsize;
ax.XAxis.FontWeight = 'bold';

if savenum == 1
    saveName = 'Spike-Stim Histogram';
    print(fig,'-vector','-dsvg',[saveFolder filesep saveName '.svg']) % svg
end



end