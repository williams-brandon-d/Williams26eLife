function myboxchart(groupdata, label_text)

% groups = repmat(1:size(groupdata, 2), size(groupdata, 1), 1);
% b = boxchart(groupdata(:),'GroupByColor',groups(:), 'MarkerStyle','.','Notch','on');hold on;




for i = 1:size(groupdata, 2)
    xdata = repmat(i,size(groupdata,1),1);
    s = swarmchart(xdata, groupdata(:,i), 10,'o','filled'); hold on;
    s.XJitterWidth = 0.7;
    s.MarkerFaceAlpha = 0.5;
    s.MarkerEdgeAlpha = 1; % no edge


    b = boxchart(xdata, groupdata(:,i),'Notch','on');hold on;
    b.BoxFaceColor = [0.2 0.2 0.2];
    b.MarkerStyle = 'none';  % no outlier
    b.BoxWidth = 0.3;
    %plot(i, nanmean(groupdata(:, i)),'x', 'LineWidth', 1, 'Color', [0.3 0.3 0.3]); hold on;
    
end
ylabel(label_text);

h = gca;
h.LineWidth = 1;

end