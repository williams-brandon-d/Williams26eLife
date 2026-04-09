function plotXYSpatialCorrelations(ROIs,R,saveFolder,savenum)

pixelSize = 0.4514; % pixel size - um / pixel 

% find center of all ROIs

% corrType = 'dfoverf';

nSelected = numel(ROIs);

ROIxy = zeros(nSelected,2);

for i = 1:nSelected
    S = regionprops(ROIs{i},'Centroid');
    if length(S) > 1
        S = S(1);
    end
    ROIxy(i,:) = [S.Centroid(1) S.Centroid(2)];
end

ROIxy = ROIxy*pixelSize; % locations in microns

dx = pdist(ROIxy(:,1),'euclidean');
dy = pdist(ROIxy(:,2),'euclidean');

R = R.*~eye(size(R)); % change diagonal values to zero for square form conversion
r = squareform(R); % convert R from square matrix to list form

% distcorr = corrcoef([d',r']);

[fig, ~] = plotCorrVsXY(dx,dy,r);
% sgtitle(fig,sprintf('XY distance Correlation (R^{2} = %.2g)',Rsq),'Fontsize',16,'Fontweight','bold');

if savenum
%     print(fig,'-vector','-dsvg',[saveFolder filesep 'Raw trace XY spatial correlations.svg']) % svg
end


function [fig, Rsq] = plotCorrVsXY(x,y,z)

x = reshape(x,[],1); % column vector
y = reshape(y,[],1); % column vector
z = reshape(z,[],1); % column vector

X = [x y ones(length(x),1)];
b = X \ z;


xv = [min(X(:,1)) max(X(:,1))];
yv = [min(X(:,2)) max(X(:,2))];
zv = [xv(:), yv(:), ones(2,1)] * b; % Calculate Regression Plane


% Rsq = 1 - sum((z - zfit).^2)/sum((z - mean(z)).^2);
Rsq = [];


% plot corr matrix
fontsize.title = 20;
fontsize.tick = 16;
fontsize.cbar = 14;
fontweight = 'bold';


fig = figure; 
plot3(x,y,z,'.b');
hold on
patch([min(xv) min(xv) max(xv) max(xv)], [min(yv) max(yv) max(yv) min(yv)], [min(zv) min(zv) max(zv) max(zv)], 'r', 'FaceAlpha',0.5)
hold off
grid on
ylabel('Y distance (um)','Fontsize',fontsize.tick)
xlabel('X distance (um)','Fontsize',fontsize.tick)
zlabel('Correlation Coeff.','Fontsize',fontsize.tick)

drawnow;

end

end