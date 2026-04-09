function plot_results(result, neuron, meanImage, frame_rate, recordingInfo)

neuronCnt = size(result.orig_trace, 1);

if exist('recordingInfo','var') && isfield(recordingInfo, 'params')
    frame_rate = recordingInfo.params.frameRate;
end

if size(result.orig_trace, 3) > 1
    result.orig_trace = reshape(result.orig_trace, neuronCnt, []);
    result.trace_noise = reshape(result.trace_noise, neuronCnt, []);
    result.roaster = reshape(result.roaster, neuronCnt, []);
end


rast = result.roaster;
rast(rast==0) = NaN;



figure;
subplot(3,3,[1,2,4,5,7,8])
signal_adj = 15;
for ind = 1:neuronCnt
% Plots the trace as the signal/noise divide by some factor
plot( ((result.orig_trace(ind,:)./result.trace_noise(ind,:)))./signal_adj + ind,'k','LineWidth',0.1);
hold on;
end

% Scale bars for all traces
posx = -0;
posy = 0.5;
time_scale = frame_rate; %  
SNR_scale = 5./signal_adj; % SNR of 5
plot([posx, posx + time_scale], [posy, posy], 'r-', 'LineWidth', 2);
hold on;
plot([posx, posx], [posy, posy + SNR_scale], 'r-', 'LineWidth', 2);
hold on;
ht = text(posx - 550, posy, ['SNR ' num2str(SNR_scale*signal_adj)]);
set(ht,'Rotation', 90);
hold on;
text(posx + 50, posy-0.15, [num2str(time_scale/frame_rate) ' s']);

%plot spike locations
% hold on;
% result.roaster2(result.roaster2==0) = nan;
% for ind=1:size(result.roaster2,1)
% plot(result.roaster2(ind,:) + (ind-0.3),'.r','Color', [0, 0, 1, 0.5],'LineWidth', 0.1); hold on,
% end
hold on;
for ind = 1:neuronCnt
plot(rast(ind,:) + (ind-0.3),'.r','Color', [1, 0, 0, 0.5],'LineWidth', 0.1); hold on,
end


% plot visual stimuli onset time
if exist('recordingInfo','var') && isfield(recordingInfo, 'visualTiming')
    for i = 2:recordingInfo.visualTiming.recordingFrame
        switchingFrameCount = recordingInfo.visualTiming.recordingFrame;
        frameDelay = recordingInfo.params.VisualStimuliDelayInMs./recordingInfo.params.frameRate;
        switchingFrameCount = switchingFrameCount + round(frameDelay);
        plot([switchingFrameCount  switchingFrameCount], [0, size(result.orig_trace,1)+1],'Color', [0.5, 0.5, 0.5], 'LineWidth', 1.2); hold on;
    end
end

axis tight;
set(gca,'XTick',0:frame_rate*5:size(result.orig_trace, 2));
set(gca,'xticklabel',{[]})
set(gca, 'YTick', [1:size(result.orig_trace, 1)]);
xlabel('Time (5s/div)'); ylabel('neuron')




%% plot average SNR
subplot(3,3,6)
clear SNR_val
for ind=1:length(result.spike_snr)
    SNR_val(ind)= mean(result.spike_snr{ind});
end
bar(SNR_val');xlabel('neuron'); ylabel('SNR')

%% plot average df
subplot(3,3,9)
clear df_val
for ind=1:length(result.spike_df)
    df_val(ind)= abs(mean(result.spike_df{ind}));
end
bar(df_val');xlabel('neuron'); ylabel('dF/F')

%% show average image and neuron labels
subplot(3,3,3);
imagesc(meanImage); colormap(gray); axis image; axis off; hold on;
for i=1:length(neuron)
    [B,~] = bwboundaries(neuron{i}.mask(:,:,1));
    boundary = B{1};
    %plot(boundary(:,2), boundary(:,1),'Color', [1, 0, 0, 0.5],'LineWidth',1);

    col = min(boundary(:,2)); row = max(boundary(:,1));
    h = text(col+1, row-1, num2str(i));
    set(h,'Color','w','FontSize',7);
    neuron{i}.boundary = boundary;
end

end