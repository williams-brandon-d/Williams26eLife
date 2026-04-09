function lfp = getLFPphase(lfp, plotnum, savenum)
% get instantaneous phase of theta and gamma oscillations in LFP

% get phase of oscillation using hilbert transform
lfp.theta_phase = angle(hilbert(lfp.theta_data)); % from -pi to pi
lfp.gamma_phase = angle(hilbert(lfp.gamma_data)); % from -pi to pi

% downsample unwrapped lfp phase data using linear interpolation
if lfp.nFrames > 0
    lfp.theta_phase_ds = wrapToPi(interp1(lfp.time,unwrap(lfp.theta_phase),lfp.time_ds));
    lfp.gamma_phase_ds = wrapToPi(interp1(lfp.time,unwrap(lfp.gamma_phase),lfp.time_ds));
end

% alternative method - downsample data first then hilbert transform
% lfp.theta_phase_ds = angle(hilbert(lfp.theta_data_ds)); % from -pi to pi
% lfp.gamma_phase_ds = angle(hilbert(lfp.gamma_data_ds)); % from -pi to pi

% check downsample quality
% plotds(lfp.time,lfp.theta_phase,spikes.time,lfp.theta_phase_ds);
% plotds(lfp.time,lfp.gamma_phase,spikes.time,lfp.gamma_phase_ds);

if plotnum
    thetaFig = plotHilbert(lfp.theta_data,lfp.theta_phase,lfp.dt);
    sgtitle('Theta','Fontweight','bold');
    gammaFig = plotHilbert(lfp.gamma_data,lfp.gamma_phase,lfp.dt);
    sgtitle('Gamma','Fontweight','bold');
%     plotHilbert(lfp.theta_data_ds,lfp.theta_phase_ds)
%     plotHilbert(lfp.gamma_data_ds,lfp.gamma_phase_ds)
end

if savenum
    print(thetaFig,'-vector','-dsvg',[lfp.savePath filesep 'hilbert theta.svg']) % svg
    print(gammaFig,'-vector','-dsvg',[lfp.savePath filesep 'hilbert gamma.svg']) % svg
end

function fig = plotHilbert(y,phase,dt)
    % freq = instfreq(y,fs,'Method','hilbert');
    tickfontsize = 12;

    nSamples = numel(y);
    dt_ms = 1000*dt; % dt in ms
    time = (0:nSamples-1)*dt_ms;

    fig = figure;

    subplot(2,1,1)
    plot(time,y)
    xlim([-inf inf]);
    ylabel('uV');
    title('Filtered Data');
    ax = gca;
    ax.YAxis.FontSize = tickfontsize;
    ax.YAxis.FontWeight = 'bold';
    ax.XAxis.FontSize = tickfontsize;
    ax.XAxis.FontWeight = 'bold';

    subplot(2,1,2)
    plot(time,phase)
    xlim([-inf inf]);
    ylabel('Phase (rad)');
    yticks([-pi -pi/2 0 pi/2 pi]);
    yticklabels({'-\pi','-\pi/2','0','\pi/2','\pi'});
    title('Hilbert Phase');
    ax = gca;
    ax.YAxis.FontSize = tickfontsize;
    ax.YAxis.FontWeight = 'bold';
    ax.XAxis.FontSize = tickfontsize;
    ax.XAxis.FontWeight = 'bold';

    % subplot(3,1,2)
    % plot(freq)

    han = axes(fig,'visible','off'); 
    han.XLabel.Visible='on';
    han.YLabel.Visible='on';
    han.Title.Visible='on';
    xlabel(han,'Time (ms)','FontSize',tickfontsize,'FontWeight','bold');

end

end