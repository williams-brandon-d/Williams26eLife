function lfp = plotHeatMap(lfp, savenum)
% plot lfp gamma amplitude as heat map for each stim cycle 

dataTypes = {'theta','gamma'};
nTypes = numel(dataTypes);

nCycles = numel(lfp.cycle_start_index);

delta_phase = 2*pi/lfp.cycle_length_ds;
cycle_phase = -pi:delta_phase:pi; 
cycle_phase = cycle_phase';

for i = 1:nTypes

    data = zeros(nCycles,lfp.cycle_length_ds+1);
    type = dataTypes{i};
    type_data = lfp.([type '_data_ds']);
    
    for icycle = 1:nCycles
        cycle_indices = lfp.cycle_start_indices_ds(icycle) + (0:lfp.cycle_length_ds);
        if cycle_indices(end) < numel(type_data)
            data(icycle,:) = type_data(cycle_indices);
        end
    end

    lfp.([type '_data_ds_mean']) = mean(data,1); % save mean data 
    
    X = [data; mean(data,1)];

    tickfontsize = 20;

    xvalues = cycle_phase;
    yvalues = 1:size(X,1);

    factor = 5;
    yTicks = factor:factor:(factor*floor(nCycles/factor));
    
    fig = figure;
    imagesc(xvalues,yvalues,X);
    xticks([-pi -pi/2 0 pi/2 pi]);
%     xticklabels({'-\pi','-\pi/2','0','\pi/2','\pi'});
    xticklabels({'-π','-π/2','0','π/2','π'});
    yticks([1 yTicks nCycles+1]);
    yticklabels(["1" string(yTicks) "Avg"]);
    colormap('hot');
    
    xlabel('Phase (rad)');
    ylabel('cycle #');
    title(sprintf('%s amplitude',type),'Fontsize',tickfontsize,'Fontweight','bold');
    h = colorbar('Fontsize',tickfontsize,'Fontweight','bold');
    title(h,lfp.data_units,'Fontsize',tickfontsize,'Fontweight','bold');
    
    ax = gca;
    ax.YAxis.FontSize = tickfontsize;
    ax.YAxis.FontWeight = 'bold';
    ax.XAxis.FontSize = tickfontsize;
    ax.XAxis.FontWeight = 'bold';

    alpha = 0.5;

    switch type
        case 'theta'
            color = [1 0 0 alpha];
        case 'gamma'
            color = [0 0 1 alpha];
    end

    % plot mean LFP gamma 
    figMean = figure;
    plot(cycle_phase,lfp.([type '_data_ds_mean']),'Color',color)
    xticks([-pi -pi/2 0 pi/2 pi]);
    xticklabels({'-π','-π/2','0','π/2','π'});
    xlim([-inf inf]);
    xlabel('Phase (rad)')
    ylabel('LFP (μV)');

    ax = gca;
    ax.YAxis.FontSize = tickfontsize;
    ax.YAxis.FontWeight = 'bold';
    ax.XAxis.FontSize = tickfontsize;
    ax.XAxis.FontWeight = 'bold';

    if savenum
        print(fig,'-vector','-dsvg',[lfp.savePath filesep sprintf('LFP %s Heatmap.svg',type)]) % svg
        print(figMean,'-vector','-dsvg',[lfp.savePath filesep sprintf('LFP %s Mean.svg',type)]) % svg
    end


end

end