function [Row, Col] = getRegistrationCoordinate(frame1,frame2)

[ysz,xsz] = size(frame1); % assuming frames are the same size



% normalize images so the scale is the same
% normIm1 = normalizeImage(frame1);
% normIm2 = normalizeImage(frame2);

norm1 = normalize(frame1(:));
norm2 = normalize(frame2(:));

normIm1 = reshape(norm1,size(frame1));
normIm2 = reshape(norm2,size(frame2));

cx = xcorr2(normIm1, normIm2);

% figure;
% imagesc(cx);

[~, maxix] = max(cx(:));
[row, col] = ind2sub(size(cx), maxix);    

Col = col - xsz;
Row = row - ysz;

    function normIm = normalizeImage(im)
        maxIm = max(im(:));
        minIm = min(im(:));
        normIm = (im - minIm)./(maxIm - minIm);
    end


end