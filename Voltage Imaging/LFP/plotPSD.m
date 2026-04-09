function plotPSD(lfp,frame_rate,savenum)
% plot PSDs for both stim data and post stim noise data

% noise_time_length = 0.5; % baseline noise time length post-stim (seconds)

TW = 3; % time-bandwidth product determines number of tapers

flimits = [0 200];

tickfontsize = 15;

% params for mtftt
ntapers = 2*TW-1;
params.Fs = frame_rate;
params.tapers = [TW,ntapers];
params.pad = -1; % no padding
params.trialave = 0;

% gather raw stim data indices
stim_indices = lfp.stim_indices_ds;

% % gather raw noise data indices
% noise_start_index = lfp.cycle_start_indices_ds(end) + lfp.cycle_length_ds;
% noise_stop_index = noise_start_index + noise_time_length*frame_rate;
% noise_indices = noise_start_index:noise_stop_index;

% raw stim and noise data
lfp_data_stim = lfp.lfp_data_ds(stim_indices)'; % samples x trials
% noise_data = lfp.lfp_data_ds(noise_indices)'; % samples x trials

% stim and noise spectra
[S_stim,f_stim] = mtspectrumc( lfp_data_stim, params );
% [S_noise,f_noise] = mtspectrumc( noise_data, params );

% interpolate spectra to the same frequency axis and subtract noise
freq = flimits(1):flimits(2);
method = 'cubic';
% S_noise = interp1(f_noise, S_noise, freq, method);
S_stim = interp1(f_stim, S_stim, freq, method);

% dB
S_stim_db = 10*log10(S_stim);
% S_noise_db = 10*log10(S_noise);

% plot spectra
fig = figure;
% subplot(1,3,1);
plot(freq,S_stim_db,'LineWidth',1.5)
xlabel('Frequency (Hz)');
% ylabel('PSD (uV^2/Hz)');
ylabel('PSD (dB)');
xlim(flimits);
title('Raw LFP Data PSD','FontSize',15);

% subplot(1,3,2);
% plot(freq,S_noise_db)
% xlabel('Frequency (Hz)');
% % ylabel('PSD (uV^2/Hz)');
% ylabel('PSD (dB)');
% xlim(flimits);
% 
% subplot(1,3,3);
% plot(freq,S_stim_db-S_noise_db)
% xlabel('Frequency (Hz)');
% % ylabel('PSD (uV^2/Hz)');
% ylabel('PSD signal-noise (dB)');
% xlim([0 200]);

box off
ax = gca;
ax.YAxis.FontSize = tickfontsize;
ax.YAxis.FontWeight = 'bold';
ax.XAxis.FontSize = tickfontsize;
ax.XAxis.FontWeight = 'bold';


if savenum
    saveas(fig,[lfp.dataPath filesep 'LFP Raw Data PSD.png']);
end


end