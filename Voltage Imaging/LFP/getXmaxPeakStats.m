function PeakStats = getXmaxPeakStats(x,y,z,Xmax,flimits,freq_threshold)
    if nargin < 6 
        freq_threshold = 0;
    end
    if nargin < 5 
       flimits = [min(y(:)) max(y(:))];
    end

    [~,Xmax_index] = find(x == Xmax);
    Xmax_index = Xmax_index(1);
    
    Xmax_powers = flip(z(:,Xmax_index));
    Frequencies = flip(y(:,Xmax_index));
    
    freq_axis = flimits(1):flimits(2);
    power_axis = interp1(Frequencies,Xmax_powers,freq_axis);
    
    [pks,~,widths,proms] = findpeaks(power_axis,freq_axis);
    
    max_pk = max(pks);
    [sorted_pks,sorted_indices] = sort(pks,'descend');

    PeakStats.bandwidth = widths(pks == max_pk); % width at half prominence of peak 

    powers_adjusted = power_axis(freq_axis > freq_threshold);
    PeakStats.peakScore = (max_pk - mean(powers_adjusted))/std(powers_adjusted);

    if numel(pks) > 1
        max_pk2 = sorted_pks(2);
        PeakStats.peakRatio = max_pk/max_pk2; 
        prom1 = proms(pks == max_pk); % prom of highest peak
        prom2 = proms(sorted_indices(2)); % prom of 2nd highest peak
        PeakStats.promRatio = prom1/prom2; 
    else
        PeakStats.peakRatio = []; 
        PeakStats.promRatio = []; 
    end