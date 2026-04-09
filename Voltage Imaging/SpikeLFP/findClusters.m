function findClusters(selectNeurons,lfp)
% use k means to look for clusters in binary spike data during stim period

% nSelected = numel(spikes(1).locs);
nSelected = numel(selectNeurons);

nSamples = numel(lfp.stim_indices_ds);

X = zeros(nSelected,nSamples);

% build data matrix
for iNeuron = 1:nSelected 
%     spike_mask = spikes.masks{iNeuron};
%     X(iNeuron,:) = spike_mask(lfp.stim_indices_ds);   
    trace = selectNeurons{iNeuron}.raw_trace;
%     meanF = mean(trace);
%     dfoverf = -1*(trace - meanF) / meanF; % normalize by mean
%     normData = (trace - meanF)/std(trace); % normalize by std
%     X(iNeuron,:) = normData(lfp.stim_indices_ds);
    X(iNeuron,:) = trace(lfp.stim_indices_ds);
end

X = (X - mean(X(:))) / std(X(:));    % normalize by mean and std of all neurons???

X = X'; % samples by neurons
% centroids are weights of each neuron with respect to the cluster number

% use k means for cluster analysis

minClusters = 2; % min number of clusters
maxClusters = 10; % max number of clusters
nReplicates = 100; % number of different seeds per cluster iteration
distance = 'sqEuclidean'; % hamming distance matching is same as kmodes

k_array = minClusters:maxClusters; % range of cluster numbers
nK = numel(k_array);
meanS = zeros(nK,1);

for ik = 1:nK
    k = k_array(ik);
    idx = kmeans(X,k,'Replicates',nReplicates,'Distance',distance); % can also using hamming method for distance of binary data   
    s = silhouette(X,idx,distance);
    meanS(ik) = mean(s); 
    fprintf('Evaluating %d number of clusters\n',k);
end

[maxS,maxIdx]  = max(meanS);
optimalK = k_array(maxIdx);

figure;
plot(k_array,meanS);
title(sprintf('Optimal Num of Clusters %d, silhouette score %.2g',optimalK,maxS));
xlabel('Number of Clusters');
ylabel('Silhouette mean');

% plot centroids for optimal number of clusters

[idx,C] = kmeans(X,optimalK,'Replicates',nReplicates,'Distance',distance); % can also using hamming method for distance of binary data
C = C'; % each cluster is a column

figure; 
for ii = 1:optimalK
    subplot(optimalK,1,ii)
    plot(C(:,ii));
    title(sprintf('Centroid %d',ii));
end

% plotCentroidRaster(C,lfp);

figure;
[optimalS,h] = silhouette(X,idx,distance);
mean_s = mean(optimalS);
title(sprintf('Silhouette mean = %.2f',mean_s))
hold on
plot([mean_s mean_s],ylim,'--r','Linewidth',2)
hold off

if optimalK == 2
    figure;
    scatter(C(:,1),C(:,2));
end


function plotCentroidRaster(C,lfp)

        nClusters = size(C,2);

        % plot centroids as rasters
        tickfontsize = 15;
        LineFormat = struct();
        LineFormat.LineWidth = 2;
        LineFormat.LineStyle = '-';
        
        nCycles = numel(lfp.cycle_start_index);
        
        delta_phase = 2*pi/lfp.cycle_length_ds;
        cycle_phase = -pi:delta_phase:pi; 
        cycle_phase = cycle_phase';
        
        plotFlag = 0;
        for i = 1:nClusters
            raster_cell = cell(nCycles,1); % make raster cell for each cluster
        
            for icycle = 1:nCycles
                cycle_indices = (icycle-1)*lfp.cycle_length_ds + (1:lfp.cycle_length_ds+1);
                cycle_spike_idx = find( C(cycle_indices,nClusters) );
        
                if (numel(cycle_spike_idx) > 0)
                    raster_cell{icycle,:} = cycle_phase(cycle_spike_idx)';
                    plotFlag = 1;
                else
                    raster_cell{icycle,:} = double.empty(1,0); 
                end
        
            end
                
            if plotFlag
            
               figure;
               [~, ~] = plotSpikeRaster(raster_cell,'PlotType','vertline','LineFormat',LineFormat);
               xlim([cycle_phase(1) cycle_phase(end)])
               ylim([0.5, nCycles + 0.5])
               xlabel('Phase (rad)')
               ylabel('cycle #')
               title(sprintf('Cluster %d',i),'FontSize',tickfontsize,'FontWeight','bold')
               ax = gca;
               ax.YAxis.FontSize = tickfontsize;
               ax.YAxis.FontWeight = 'bold';
               ax.XAxis.FontSize = tickfontsize;
               ax.XAxis.FontWeight = 'bold';
            end
    
        end
        
    end

end