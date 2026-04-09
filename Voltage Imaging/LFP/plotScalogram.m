function fig = plotScalogram(x,y,z,plotTitle,maxValues,data_units)
    fontsize = loadFontSizes();
    fontsize.tick = 20;
    fontsize.cbar = 14;
    fontweight = 'bold';
    
    fig = figure;

%     surf(x,y,z,'EdgeColor', 'none');

    % downsample surf plot resolution to save as vector graphics
    x_new  = linspace(-pi,pi,size(z,1));
    z_ds = interp1(x(1,:), z', x_new, 'linear')';
    [X_new,Y_new] = meshgrid(x_new,y(:,1));

    surf(X_new,Y_new,z_ds,'EdgeColor', 'none');
    shading interp
    view(0,90)

    hcb = colorbar('Fontsize',fontsize.cbar,'Fontweight', fontweight);
    title(hcb,sprintf('Power (%s^2)',data_units),'FontSize',fontsize.cbar,'FontWeight',fontweight) 
    xlim([-inf inf])
    ylim([-inf inf])
    clim([0 inf])
    colormap('hot')

    ax = gca;
    ax.XAxis.TickLabelInterpreter = 'tex';   % tex for x-axis
    xticks([-pi -pi/2 0 pi/2 pi]);
%     xticklabels({'-\pi','-\pi/2','0','\pi/2','\pi'});
    xticklabels({'-π','-π/2','0','π/2','π'});
    ax.YAxis.FontSize = fontsize.tick;
    ax.XAxis.FontSize = fontsize.tick;

    xlabel('Theta Phase (rad)','Fontsize',fontsize.tick)
    ylabel('Frequency (Hz)','Fontsize',fontsize.tick)
    ax.YAxis.FontWeight = fontweight;
    ax.XAxis.FontWeight = fontweight;

    if nargin > 3
%         title(plotTitle,'FontSize',fontsize.title,'Interpreter','none')
    end
    if nargin > 4
        hold on
%         plot3(maxValues(1),maxValues(2),maxValues(3),'xb')
        hold off
    end
    
end
