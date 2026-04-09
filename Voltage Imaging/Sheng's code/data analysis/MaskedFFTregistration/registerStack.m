
function [stack, shifts, mask] = registerStack(stack, mask, template)
GPU_ram_limit = 3; % in GB, maximum stack file size to be transfered to GPU each time
averageWindowSz = 7; % average number of frames before estimating motion 
padSz = floor(averageWindowSz/2);
% setup parameters
if ~exist('template', 'var')
    template = mean(stack(:,:,1:90), 3);
end
myFilter = fspecial('gaussian', size(template), 1) - fspecial('gaussian', size(template), 5);
sz1 = size(stack, 1);sz2 = size(stack, 2); sz3 = size(stack,3);

overlapRatio = 0.8;
chunk = floor(GPU_ram_limit*1024*1024*1024/length(template(:))/2);  % set the size appropriate to GPU memory size, 4 GB limit, assuming uint16
chunkLimit = floor(intmax('int32')/length(template(:)))-1;  % array size limit by NVIDIA GPU max addressible element size
chunk = min(chunk, chunkLimit) - padSz*2;

%% if manual ROI selection
if ~exist('mask', 'var')
    [mask, ~] = selectROI(template, @drawrectangle);
end
%%

mask = single(gpuArray(mask));
maskIdx = find(logical(mask(:)));
template = single(gpuArray(template));
myFilter = single(gpuArray(myFilter));
shifts = zeros(size(stack, 3), 2);

tic;
for startIdx = 1:chunk:size(stack, 3)
    endIdx = min(startIdx + chunk - 1, size(stack, 3));

    stackGpu = gpuArray(stack(:,:,startIdx:endIdx));
    % time average the stack
    stackGpuReg = reshape(stackGpu, sz1*sz2, []);
    stackGpuTmp = padarray(stackGpuReg(maskIdx, :),[0 padSz],'symmetric','both');
    stackGpuReg(maskIdx, :) = movmean(stackGpuTmp, averageWindowSz, 2, 'Endpoints', 'discard');
    stackGpuReg = reshape(stackGpuReg, sz1, sz2, []);

    % estimate translation for each frame
    translation = masked_phase_cross_correlation(stackGpuReg, template, mask, overlapRatio, myFilter);
    translation = gather(translation);
    translation = removeOutlier2(translation, 50);

    for i = 1:size(stackGpu, 3)
        stackGpu(:,:,i) = circshift(stackGpu(:,:,i), translation(i, :));
    end

    stack(:,:,startIdx:endIdx) = stackGpu;
    shifts(startIdx:endIdx, :) = gather(translation);
    clear stackGpu stackGpuReg;
    fprintf('%d frames registered.\n', endIdx);
end
toc

%
mask = gather(mask);

end


function translation = removeOutlier(translation, window_sz)

    shift_amt = sqrt(sum(translation.^2, 2));
    invalidIdx = abs(shift_amt - movmean(shift_amt, window_sz)) > 2 * movstd(shift_amt, window_sz);
    for axis = 1:2
        sf = translation(:, axis);
        sf(invalidIdx) = nan;
        while any(isnan(sf))
            sf = fillmissing(sf, 'movmean', 5);
        end
        translation(:,axis) = round(sf);
    end

end

function translation = removeOutlier2(translation, window_sz)

    shift_amt = sqrt(sum(translation.^2, 2));
    invalidIdx = abs(shift_amt) > ceil(movstd(shift_amt, window_sz));
    for axis = 1:2
        trans = translation(:, axis);
        trans(invalidIdx+1) = nan;
        while any(isnan(trans))
            trans = fillmissing(trans, 'movmean', 5);
        end
        translation(:,axis) = round(trans);
    end

end

