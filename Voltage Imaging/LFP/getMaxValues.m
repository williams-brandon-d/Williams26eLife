function maxValues = getMaxValues(x,y,z,freq_max_threshold)
    if nargin < 4; freq_max_threshold = 0; end
    
    z(y < freq_max_threshold) = 0;
    
    ymin = min(y(y>=freq_max_threshold),[],'all');
    
    Zmax = max(z(:)); % get max value in scalogram
    [rowsOfMaxes, colsOfMaxes] = find(z == Zmax); % find indices of max value
    Xmax = median(x(rowsOfMaxes(1),colsOfMaxes)); % time at max power
    Ymax = median(y(rowsOfMaxes,colsOfMaxes(1))); % freq at max power
%     maxValues = [Xmax Ymax Zmax];

    if Ymax == ymin
        % find 2D peaks in spectrum
        % sigma = 4; % 2D gaussian filter size = 2*ceil(2*sigma)+1
        % z_smooth = imgaussfilt(z_threshold,sigma);
  
        [~,cent_map] = FastPeakFind(z);
        % centx_index = cent(1:2:end);
        % centy_index = cent(2:2:end);
        lin_cent_map = cent_map(:);
        centLin_index = find(lin_cent_map == 1);
        
        X_peaks = x(centLin_index);
        Y_peaks = y(centLin_index);
        Z_peaks = z(centLin_index);
        
        Z_max = max(Z_peaks);
        X_max = X_peaks(Z_peaks == Z_max);
        Y_max = Y_peaks(Z_peaks == Z_max);
        maxValues = [X_max Y_max Z_max];

        figure;
        surf(x,y,z)
        shading interp
        colormap('hot')
        view(0,90)
        plot3(X_max,Y_max,Z_max,'*g')
        plot3(X_peaks,Y_peaks,Z_peaks,'+m') 
    else
        maxValues = [Xmax Ymax Zmax];
    end