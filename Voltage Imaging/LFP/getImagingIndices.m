function [imaging_indices,nFrames] = getImagingIndices(camera_data,offset_frames,plotnum)

% could instead use recorded camera frames to find camera start and finish

threshold = 2.5; % volts

frame_start_indices = find( camera_data(1:end-1) < threshold & camera_data(2:end) > threshold );

if isempty(frame_start_indices) % no imaging data
    nFrames = 0;
    imaging_indices = [];
else
    df = mean(diff(frame_start_indices));
    offset_start_index = frame_start_indices(offset_frames + 1); % first camera trigger is not a frame but initiates the sequence
    camera_stop_index = uint64(frame_start_indices(end) + df - 1);
    imaging_indices = offset_start_index:camera_stop_index;
    nFrames = numel(frame_start_indices) - offset_frames - 1; % total number of images after offset
    
    if plotnum
        figure;
        plot(camera_data);
        hold on
        plot(offset_start_index,camera_data(offset_start_index),'or');
        plot(camera_stop_index,camera_data(camera_stop_index),'ok');
        hold off
    end
end

end