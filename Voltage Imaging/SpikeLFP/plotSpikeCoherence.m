function plotSpikeCoherence(spikes, lfp, frame_rate, saveFolder, savenum)
% spike-field coherence 

% can implement GLM to reduce spike rate bias in coherence
% can also use thinning to equate spike rates
% see Kramer book and paper for examples

% dataTypes = {'Raw','Theta','Gamma'};
dataTypes = {'Raw'};

% params for mtftt
TW = 3;
ntapers = 2*TW-1;

params.Fs = frame_rate;
params.tapers = [TW,ntapers];
params.pad = -1; % no padding
params.trialave = 0;
% params.fpass = [0 200]; % Hz

stim_indices = lfp.stim_indices_ds;

N = numel(stim_indices);
nfft = max(2^(nextpow2(N)+params.pad),N); % all frequencies
nfft = floor((nfft/2)) + 1; % positive frequencies

nSelected = numel(spikes);

nTypes = numel(dataTypes);

for ii = 1:nTypes

    type = dataTypes{ii};

    switch type
        case 'Raw'
            lfp_data_stim = lfp.lfp_data_ds(stim_indices)'; % samples x trials
        case 'Theta'
            lfp_data_stim = lfp.theta_data_ds(stim_indices)'; % samples x trials
        case 'Gamma'
            lfp_data_stim = lfp.gamma_data_ds(stim_indices)'; % samples x trials
    end
    
    C = zeros(nfft,nSelected);
    Snn = zeros(nfft,nSelected);
    
    for i = 1:nSelected
    
        spike_mask = [spikes(i).masks];
        spike_mask_stim = double( spike_mask(stim_indices) );
    
        [C(:,i),~,~,Syy,Snn(:,i),f] = coherencycpb(lfp_data_stim, spike_mask_stim, params);
    
    end
    
    fig = figure;

    subplot(2,2,1);
    plot(f,Snn)
    hold on; plot(f,mean(Snn,2),'k','Linewidth',2)
    xlim([0 200]);
    title('Snn')
    ylabel('Power (Hz)')
    xlabel('Frequency (Hz)')

    subplot(2,2,2)
    plot(f,C)
    hold on; plot(f,mean(C,2),'k','Linewidth',2)
    xlim([0 200]);
    ylabel('Coherence')
    xlabel('Frequency (Hz)')

    subplot(2,2,3)
    plot(f,Syy);
    xlim([lfp.theta_bandpass(1) lfp.theta_bandpass(2)]);
    title('Theta')
    ylabel('Power (uV^2/Hz)')
    xlabel('Frequency (Hz)')
    
    subplot(2,2,4)
    plot(f,Syy);
    xlim([lfp.gamma_bandpass(1) lfp.gamma_bandpass(2)]);
    title('Gamma')
    ylabel('Power (uV^2/Hz)')
    xlabel('Frequency (Hz)')

    if nTypes > 1
        sgtitle(fig,sprintf('%s',type))
    end

    if savenum
        print(fig,'-vector','-dsvg',[saveFolder filesep sprintf('LFP %s SFC.svg',type)]) % svg
    end

end


end