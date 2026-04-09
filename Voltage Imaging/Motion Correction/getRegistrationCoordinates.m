function [devRow, devCol] = getRegistrationCoordinates(frames)

Nframes = size(frames, 3);

xsz = size(frames, 2);
ysz = size(frames, 1);

dev.row = zeros(Nframes, 1);
dev.col = zeros(Nframes, 1);

cx = zeros(2*size(frames, 1)-1, 2*size(frames, 2)-1, Nframes);

dev.x = xsz;
dev.y = ysz;
for i = 1:Nframes

    cx(:, :, i) = xcorr2(frames(:, :, i), frames(:, :, 1));
    tmp = cx(:, :, i);
    [~, maxix] = max(tmp(:));
    [dev.row(i), dev.col(i)] = ind2sub(size(cx), maxix);
    disp(['Processing frame ' num2str(i) '/' num2str(Nframes)]);
    
end

devCol = dev.col - xsz;
devRow = dev.row - ysz;
