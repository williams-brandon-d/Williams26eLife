function [coeff,score] = plotPCA(selectNeurons, data_indices, saveFolder, savenum)
% use PCA to determine variance explained by components of neurons during stim period
% find clusters with PCA - will tell me how much variance is explained by largest cluster

nSelected = numel(selectNeurons);
nSamples = numel(data_indices);

X = zeros(nSelected,nSamples); % neurons by samples

% build data matrix
for iNeuron = 1:nSelected 
    if isfield(selectNeurons{1},'noMotion_trace')
        trace = selectNeurons{iNeuron}.noMotion_trace;
    else
        trace = selectNeurons{iNeuron}.raw_trace;
    end
%     X(iNeuron,:) = trace(data_indices); % no normalization
    trace = trace(data_indices);
    X(iNeuron,:) = trace - mean(trace); % already dfoverf
%     X(iNeuron,:) = (trace - mean(trace)) / mean(trace); % normalize by mean (dfoverf)
%     X(iNeuron,:) = (trace - min(trace)) / ( max(trace) - min(trace) ); % normalize traces from 0 to 1
end

% X = (X - mean(X(:))) / std(X(:)); % normalize by mean and std of all neurons

X = X'; % samples by neurons
% rows of X correspond to observations while columns are the variables

% use PCA to determine the variance explained by each cluster

% scores are principal components while coeffs are weights
% Xcentered = score*coeff'; % reconstruct centered data
% Xnew = score*coeff' + repmat(mu,size(X,1),1); % reconstruct data

[coeff,score,~,~,explained,~] = pca(X);

% disp(explained);

nPCs = min(5,nSelected);

fig = plotVarExplained(explained,nPCs); % plot variance explained

fig2 = plotCoeffMatrix(coeff,nPCs,[]); % plot coeff matrix - could focus on first few components

fig3 = plotScores(score,nPCs); % plot first few principal component scores




if savenum
    print(fig,'-vector','-dsvg',[saveFolder filesep 'dfoverf PCA explained.svg']) % svg
    print(fig2,'-vector','-dsvg',[saveFolder filesep 'dfoverf PCA coeff.svg']) % svg
    print(fig3,'-vector','-dsvg',[saveFolder filesep 'dfoverf PCA scores.svg']) % svg
end


function fig = plotVarExplained(explained,nPCs)

tickfontsize = 15;
fig = figure;
plot(explained(1:nPCs),'Linewidth',2);
xlim([-inf inf])
ylim([0 100]);

ticks = 1:nPCs;
xticks(ticks);
xticklabels(string(ticks));

xlabel('Principal Component #');
ylabel('Variance Explained (%)');
title(sprintf('PC1: %.1f%%, PC2: %.1f%%, PC3: %.1f%%',explained(1),explained(2),explained(3)), 'FontSize',20 );
ax = gca;
ax.YAxis.FontSize = tickfontsize;
ax.YAxis.FontWeight = 'bold';
ax.XAxis.FontSize = tickfontsize;
ax.XAxis.FontWeight = 'bold';

end


function fig = plotScores(score,nPCs)

frame_rate = 800;
dt = 1/frame_rate;
time = (0:(size(score,1)-1))*dt;

tickfontsize = 12;
fig = figure('WindowState','maximized');

for i = 1:nPCs
    subplot(nPCs,1,i)
    plot(time,score(:,i),'Linewidth',1);
    title(sprintf('PC %d',i));

    xlim([-inf inf])
    ax = gca;
    ax.YAxis.FontSize = tickfontsize;
    ax.YAxis.FontWeight = 'bold';
    ax.XAxis.FontSize = tickfontsize;
    ax.XAxis.FontWeight = 'bold';
end

xlabel('Time (s)')
ax = gca;
ax.YAxis.FontSize = tickfontsize;
ax.YAxis.FontWeight = 'bold';
ax.XAxis.FontSize = tickfontsize;
ax.XAxis.FontWeight = 'bold';

end



end