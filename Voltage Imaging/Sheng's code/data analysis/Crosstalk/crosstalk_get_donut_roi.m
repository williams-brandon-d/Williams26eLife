folderCnt = 5;
pathsAll = {};
dataFilesAll = {};
for f = 1:folderCnt
    folder = 'G:\Recordings\2022.12.07 Targeted vs Uniform/';
    pathsAll{f} = uigetdir2(folder, ['Select folder',[num2str(f)],' to read']);
    dataFilesAll{f} = uigetdir2(folder, ['Select file ',[num2str(f)],' to read']);
end
%%
%for f = 1:folderCnt
for f = 4:4
    load(dataFilesAll{f}{1});
    paths = pathsAll{f};
fprintf('reading roi %d\n\n\n', f);
pz = 6.5*12.5/180; % pixel size

invert = true;
frame_rate = 800;
snr_thresh = 4;
neuronCnt = length(neuron);

complete_mask = neuron{1}.mask;
ROIneuron = {};
for i = 1:neuronCnt
    ROIneuron{end+1} = neuron{i}.mask;
    complete_mask = complete_mask | neuron{i}.mask;
end


donut_sz = round(3/pz);
SE = strel("disk",round(3/pz));

ROIs = {};
for i = 1:neuronCnt
    ROIs{end+1} = neuron{i}.mask;  % first mask is the cell itself

    SE_curr = strel("disk", donut_sz);
    ROIs{end+1} = logical(neuron{i}.mask - imerode(neuron{i}.mask, SE_curr)); % second mask is 3 um donut inside the cell

    for j = 1:8
        % donut roi outside the cell, 3 um step
        SE_pre = strel("disk",donut_sz*(j-1));
        SE_curr = strel("disk", donut_sz*j);
        ROIs{end+1} = logical(imdilate(neuron{i}.mask, SE_curr) - imdilate(neuron{i}.mask, SE_pre)); 
    end   
end

mask_per_cell = 10;


motion_correction = true;
for i = 1:length(paths)
    fprintf('reading roi %d, file %d\n\n\n', f, i);
    % read folder
    fileInfo = dir([paths{i},'\*raw']);
    [~,idx] = sort([fileInfo.datenum]);fileInfo = fileInfo(idx);

    [neuron, traces, averageFrame, shifts] = extractTrace(fileInfo, ROIs, roi_window, motion_correction);
    for n = 1:neuronCnt
        for kk = 1:mask_per_cell
            idx = (n-1)*mask_per_cell + kk;
            neuron{n}.mask(:,:,kk) = neuron{idx}.mask;
            neuron{n}.raw_trace(:,kk) = neuron{idx}.raw_trace;
        end
    end
    neuron(neuronCnt+1:end) = [];
    % analysis SNR
    result = spike_detect_SNR_v4(traces(:,1:mask_per_cell:end).*((-1)^(invert)), frame_rate,snr_thresh);

    plot_results(result, neuron, averageFrame, frame_rate);drawnow;
    %figure;plot(sqrt(sum(shifts.^2, 2)));drawnow

    dataPath = paths{i};
    meanImage = averageFrame;
    save(paths{i},'dataPath', 'meanImage', 'neuron', 'shifts', 'roi_window','recordingInfo','mask_per_cell','donut_sz','-nocompression');
end
close all;
drawnow;

end