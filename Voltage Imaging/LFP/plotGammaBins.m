function plotGammaBins(lfp, savenum)
% plot lfp gamma cycle as different colors for each stim cycle 

% color = load_fav_colors();

nCycles = numel(lfp.cycle_start_index);

delta_phase = 2*pi/lfp.cycle_length_ds;
cycle_phase = (-pi:delta_phase:pi)'; 

data = zeros(nCycles+1,lfp.cycle_length_ds+1);

for iCycle = 1:nCycles+1
    gamma_cycle_start = lfp.gamma_start_indices_ds{iCycle};
    gamma_cycle_stop = lfp.gamma_stop_indices_ds{iCycle};
    for iGamma = 1:numel(gamma_cycle_start)
        gamma_indices = gamma_cycle_start(iGamma):gamma_cycle_stop(iGamma);
        data(iCycle,gamma_indices) = iGamma;
    end
end

tickfontsize = 25;
xvalues = cycle_phase;
yvalues = 1:nCycles+1;

factor = 5;
yTicks = factor:factor:(factor*floor(nCycles/factor));

fig = figure;
imagesc(xvalues,yvalues,data);
xticks([-pi -pi/2 0 pi/2 pi]);
xticklabels({'-π','-π/2','0','π/2','π'});
% yticks([1 5 10 15 20]);
% yticklabels({'1','5','10','15','20'});
yticks([1 yTicks nCycles+1]);
yticklabels(["1" string(yTicks) "Avg"]);
colormap('hot');

xlabel('Phase (rad)');
ylabel('Theta Cycle #');
title('Gamma Cycle Bins','Fontsize',tickfontsize,'Fontweight','bold');
h = colorbar('Fontsize',tickfontsize,'Fontweight','bold');
title(h,{'Gamma';'Cycle #'},'Fontsize',tickfontsize,'Fontweight','bold');

ax = gca;
ax.YAxis.FontSize = tickfontsize;
ax.YAxis.FontWeight = 'bold';
ax.XAxis.FontSize = tickfontsize;
ax.XAxis.FontWeight = 'bold';

if savenum
    print(fig,'-vector','-dsvg',[lfp.savePath filesep 'LFP Gamma Bins.svg']) % svg
end


end