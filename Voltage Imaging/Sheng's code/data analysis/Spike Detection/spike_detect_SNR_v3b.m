function  result=spike_detect_SNR_v3b(traces,frame_rate,snr_thresh)

    FS = frame_rate; % sampling frequency

    event_parameter.pre_peak_data_point = 1;
    event_parameter.post_peak_data_point = 1;
    event_parameter.event_moving_window = 101; % data points
       
    event_parameter.noise_threshold = 7;
    event_parameter.noise_pre_extension = 0; % data points
    event_parameter.noise_post_extension = 3; % data points
    event_parameter.noise_extension = 3; % data points
    event_parameter.noise_moving_window = 31; % data points
    
    event_parameter.snr_threshold = snr_thresh;
    event_parameter.down_threshold = 4;
    event_parameter.up_threshold = 4;
    event_parameter.moving_window = round(FS*0.4);  % smoothed trace +/- 200 ms window
    
result=[];
for neuron=1:size(traces,2)

    event.idx=[];
    event.amplitude=[];
    event.snr=[];
    
    current_traceOrig = (traces(:,neuron));
    current_trace = current_traceOrig - fastsmooth(current_traceOrig,FS*1,1,1); 
    %smoothed_trace = fastsmooth(current_trace,round(FS/16.67),1,1);
    smoothed_trace = fastsmooth(current_trace,round(FS/16.67),1,1);
    f_trace= current_trace - smoothed_trace; % high pass at 16.67 Hz
         
    u_f_trace = get_upper_trace(f_trace,event_parameter.moving_window); % upper half trace
    l_f_trace = get_lower_trace(f_trace,event_parameter.moving_window); % lower half trace
    
    d_u_f_trace = diff(u_f_trace);
    d_u_f_trace = [0;d_u_f_trace];

    d_l_f_trace = diff(l_f_trace);
    d_l_f_trace = [0;d_l_f_trace];
            
    current_trace_noise = 2*std(l_f_trace);   % baseline fluctuation
    
%%%%%%%%%%%
    event_parameter.up_threshold_value = event_parameter.up_threshold*nanstd(d_l_f_trace);
    event_parameter.down_threshold_value = event_parameter.down_threshold*nanstd(d_l_f_trace);

    event.event_parameter.up_threshold_value = event_parameter.up_threshold_value;           
    event.event_parameter.down_threshold_value = event_parameter.down_threshold_value;
    
%%%%%%%%%%%%%%%%%%
%    denoise_trace = current_trace;
%     noise_idx_list = find_noise_idx(f_trace,event_parameter.moving_window,event_parameter.noise_moving_window,event_parameter.noise_threshold,event_parameter.noise_extension);
%     for idx=1:numel(noise_idx_list)
%         current_noise_idx = noise_idx_list(idx);
%         if current_noise_idx-event_parameter.noise_pre_extension>0
%             denoise_trace(current_noise_idx-event_parameter.noise_pre_extension:min(current_noise_idx+event_parameter.noise_post_extension,length(current_trace))) = nan;
%         end
%     end
%%%%%%%%%%
    pre_d_trace = d_u_f_trace;
    if event_parameter.pre_peak_data_point>0
        for idx=1:event_parameter.pre_peak_data_point
            shifted_d_trace = [zeros(idx,1);d_u_f_trace(1:end-idx)];
            shifted_d_trace(shifted_d_trace<0) = 0;
            pre_d_trace = pre_d_trace+shifted_d_trace;
        end
    end
            
    post_d_trace = d_u_f_trace;
    if event_parameter.post_peak_data_point>0
        for idx=1:event_parameter.post_peak_data_point
            shifted_d_trace = [d_u_f_trace(idx+1:end);zeros(idx,1)];
            shifted_d_trace(shifted_d_trace>0) = 0;
            post_d_trace = post_d_trace+shifted_d_trace;
        end
    end

%%%%%%%%%%%%%
 trace_val = pre_d_trace;
 up_idx_list = find(d_u_f_trace>(nanmean(d_u_f_trace)+event_parameter.up_threshold_value)); % <-- Use this one

 for up_idx=up_idx_list'

    if up_idx > round(FS/800*3) && (up_idx+1) <= length(d_u_f_trace) && d_u_f_trace(up_idx)>0 

        peak_intensity = current_trace(up_idx);
        pre_peak_intensity = current_trace(up_idx-round(FS/800*3):up_idx-1);
        post_peak_intensity_1 = current_trace(up_idx+1);
        peak_V=trace_val(up_idx);
        
        valnear= find(abs( up_idx- up_idx_list) <= 2 &   abs( up_idx- up_idx_list)>0);
        if isempty(valnear)
            vthres=0; 
        else  
            vthres=max(trace_val(up_idx_list(valnear)));
        end
           
        current_signal_intensity = max(peak_intensity - pre_peak_intensity);
        current_snr = current_signal_intensity/current_trace_noise;
        if peak_V > vthres && current_snr>=event_parameter.snr_threshold && current_trace(up_idx)> std(current_trace)*2
            event.idx(end + 1) = up_idx;
            event.amplitude(end + 1) =  current_signal_intensity;
            event.snr(end + 1) = current_snr;
        end
    end
 end

event.roaster = zeros(size(current_trace));
event.roaster(event.idx) = 1;   
event.roaster2 = zeros(size(current_trace));
event.roaster2(up_idx_list) = 1;  
event.trace_noise = current_trace_noise;
event.snr_threshold = event_parameter.snr_threshold;

% create subthreshold trace by removing spikes
tracews=current_trace;
for sind=1:length(event.idx)
   if event.idx(sind) > 2  & event.idx(sind)< length(current_trace)-2
        tracews( event.idx(sind))= mean(current_trace([event.idx(sind)-2 event.idx(sind)+2]));
        tracews( event.idx(sind)-1)= mean(tracews([event.idx(sind)-2 event.idx(sind)-2]));
        tracews(event.idx(sind)+1)= mean(tracews([event.idx(sind)+2 event.idx(sind)+2]));
        tracews( event.idx(sind))= mean(tracews([event.idx(sind)-1  event.idx(sind) event.idx(sind)+1]));
   end
end


   
result.orig_trace(neuron,:) = current_trace;
%result.denoise_trace(neuron,:) = denoise_trace;
result.trace_ws(neuron,:) = tracews;
%result.orig_traceDN(neuron,:) = v1;
result.orig_trace_untrended(neuron,:) =current_traceOrig;
result.roaster(neuron,:) = event.roaster;
result.roaster2(neuron,:) = event.roaster2;

result.spike_snr{neuron,1} =  event.snr ;

result.spike_amplitude{neuron,1} = event.amplitude' ;
result.spike_idx{neuron,1} =  event.idx  ;
result.trace_noise(neuron,1)= event.trace_noise;
end
end




function lower_trace = get_lower_trace(current_trace,trace_moving_window)

    m_trace = movmean(current_trace,trace_moving_window);
    lower_trace = current_trace;
    % replace the part below moving average with moving average
    %idx = find(lower_trace>m_trace);
    %lower_trace(idx)=m_trace(idx);
    lower_trace = min(lower_trace, m_trace);
end


function upper_trace = get_upper_trace(current_trace,trace_moving_window)

    m_trace = movmean(current_trace,trace_moving_window);
    upper_trace = current_trace;
    % replace the part below moving average with moving average
    %idx = find(upper_trace<m_trace);
    %upper_trace(idx)=m_trace(idx);
    upper_trace = max(upper_trace, m_trace);
end

function noise_idx_list = find_noise_idx(current_trace,trace_moving_window,noise_moving_window,noise_threshold,noise_extension)

    m_trace = movmean(current_trace,trace_moving_window);
    lower_current_trace = current_trace;
    lower_current_trace = min(lower_current_trace, m_trace);

    movstd_lower_current_trace = movstd(lower_current_trace,noise_moving_window);
    noise_idx_list = find(isoutlier(movstd_lower_current_trace,'gesd')==1);

    % connect noise index
    noise_idx_list = sort(noise_idx_list);
    d_noise_idx_list = diff(noise_idx_list);
    noise_extension_idx = find(d_noise_idx_list>1 & d_noise_idx_list<noise_extension);
    if ~isempty(noise_extension_idx)
        for idx=1:numel(noise_extension_idx)
            current_idx = noise_extension_idx(idx);
            noise_idx_list = cat(1,noise_idx_list,[noise_idx_list(current_idx):noise_idx_list(current_idx+1)]');
        end
    end

    noise_idx_list = unique(noise_idx_list);

end


