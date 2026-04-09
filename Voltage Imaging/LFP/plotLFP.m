function fig = plotLFP(lfp)

    fig = figure('WindowState', 'maximized');
    
    subplot(4,1,1)
    plot(lfp.time,lfp.lfp_data,'k','Linewidth',1);
    title('Raw','FontSize',20,'FontWeight','bold')
    ylabel(lfp.data_units);
    xlim([-inf inf]);
    ax = gca;
    ax.XAxis.FontSize = 15;
    ax.YAxis.FontSize = 15;
    ax.XAxis.FontWeight = 'bold';
    ax.YAxis.FontWeight = 'bold';
    box off

    subplot(4,1,2)
    plot(lfp.time,lfp.gamma_data,'b','Linewidth',1);
    title('Gamma','FontSize',20,'FontWeight','bold');
    ylabel(lfp.data_units);
    xlim([-inf inf]);
    ax = gca;
    ax.XAxis.FontSize = 15;
    ax.YAxis.FontSize = 15;
    ax.XAxis.FontWeight = 'bold';
    ax.YAxis.FontWeight = 'bold';
    box off

    subplot(4,1,3)
    plot(lfp.time,lfp.theta_data,'r','Linewidth',1);
    title('Theta','FontSize',20,'FontWeight','bold');
    ylabel(lfp.data_units);
    xlim([-inf inf]);
    ax = gca;
    ax.XAxis.FontSize = 15;
    ax.YAxis.FontSize = 15;
    ax.XAxis.FontWeight = 'bold';
    ax.YAxis.FontWeight = 'bold';
    box off

    subplot(4,1,4)
    plot(lfp.time,lfp.stim_data,'Color',[91, 207, 244] / 255,'Linewidth',1);
    title('Stim','FontSize',20,'FontWeight','bold');
    xlim([-inf inf]);
    ax = gca;
    ax.XAxis.FontSize = 15;
    ax.YAxis.FontSize = 15;
    ax.XAxis.FontWeight = 'bold';
    ax.YAxis.FontWeight = 'bold';
    box off

    xlabel("Time (s)",'FontSize',20,'FontWeight','bold')
    % sgtitle(sprintf('CaMK2-ChR2 %g Hz Stim',lfp.stim_freq))

end