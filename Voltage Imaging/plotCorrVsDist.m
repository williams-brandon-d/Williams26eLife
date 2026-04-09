function [fig, Rsq] = plotCorrVsDist(x,y)

% y = abs(y); % compare magnitude correlation

x = reshape(x,[],1); % column vector
y = reshape(y,[],1); % column vector

% linear fit for all data
[yfit,Rsq] = linearfit(x,y);

% plot corr matrix
fontsize.title = 20;
fontsize.tick = 16;
fontsize.cbar = 14;
fontweight = 'bold';

color = [0 0 0];

fig = figure; 
hold on;
scatter(x,y,8,color,'filled'); 
han1 = plot(x,yfit,'-r','Linewidth',2,'DisplayName',sprintf('   R^{2} = %.3f',Rsq)); 
hold off;

legend(han1,'location','Northeast','FontSize',12,'FontWeight','bold')
% legend([han1 han2],'location','Northeast')
legend('boxoff');

xlabel('Pairwise Distance (μm)','Fontsize',fontsize.tick)
% ylabel('|R|','Fontsize',fontsize.tick)
ylabel('R_{spike}','Fontsize',fontsize.tick)

if min(y) >= 0
    ymin = 0;
else
    ymin = -0.5;
end
ylim([ymin 1])

% ylim([0 1]);

ax = gca;
ax.YAxis.FontSize = fontsize.tick;
ax.XAxis.FontSize = fontsize.tick;
ax.YAxis.FontWeight = fontweight;
ax.XAxis.FontWeight = fontweight;

drawnow;

    function [yfit,Rsq] = linearfit(x,y)
        % linear fit for all data
        X = [ones(length(x),1) x];
        b = X \ y;
        yfit = X*b; % linear fit
        Rsq = 1 - sum((y - yfit).^2)/sum((y - mean(y)).^2);

    end

end