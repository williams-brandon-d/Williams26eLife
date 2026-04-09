function findCycleClustersContinuous(selectNeurons,lfp)
% use k means to look for clusters during each stim cycle

% k means parameters    
minClusters = 2; % min number of clusters
maxClusters = 10; % max number of clusters
nReplicates = 100; % number of different seeds per cluster iteration
distance = 'sqEuclidean'; % hamming distance matching is same as kmodes for binary data

k_array = minClusters:maxClusters; % range of cluster numbers
nK = numel(k_array);


% nSelected = numel(spikes(1).locs);
nSelected = numel(selectNeurons);

nCycles = numel(lfp.cycle_start_indices_ds);

k_optimal = zeros(nCycles,1);

for iCycle = 1:nCycles
    cycle_indices = lfp.cycle_start_indices_ds(iCycle) + (0:lfp.cycle_length_ds);
    
    nSamples = numel(cycle_indices);
    
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
        X(iNeuron,:) = trace(cycle_indices);
    end
    
    X = (X - mean(X(:))) / std(X(:)); % normalize by mean and std of all neurons
    
    X = X'; % samples by neurons
    % centroids are weights of each neuron with respect to the cluster number
    
    % use k means for cluster analysis
    meanS = zeros(nK,1);
    
    for ik = 1:nK
        k = k_array(ik);
        idx = kmeans(X,k,'Replicates',nReplicates,'Distance',distance); % can also using hamming method for distance of binary data   
        s = silhouette(X,idx,distance);
        meanS(ik) = mean(s); 
%         fprintf('Evaluating %d number of clusters\n',k);
    end
    
    [maxS,maxIdx]  = max(meanS);
    optimalK = k_array(maxIdx);
    
    figure;
    plot(k_array,meanS);
    title(sprintf('Optimal Num of Clusters %d, silhouette score %.2g',optimalK,maxS));
    xlabel('Number of Clusters');
    ylabel('Silhouette mean');
    
    % plot centroids for optimal number of clusters
    
    [idx,C] = kmeans(X,optimalK,'Replicates',nReplicates,'Distance',distance);
    C = C'; % each cluster is a column
    
    figure; 
    for ii = 1:optimalK
        subplot(optimalK,1,ii)
        plot(C(:,ii));
        title(sprintf('Centroid %d',ii));
    end
    
%     % plotCentroidRaster(C,lfp);
%     
%     figure;
%     [optimalS,~] = silhouette(X,idx,distance);
%     mean_s = mean(optimalS);
%     title(sprintf('Silhouette mean = %.2f',mean_s))
%     hold on
%     plot([mean_s mean_s],ylim,'--r','Linewidth',2)
%     hold off
%     
%     if optimalK == 2
%         figure;
%         scatter(C(:,1),C(:,2));
%     end

    k_optimal(iCycle) = optimalK;

end

disp(k_optimal);

end