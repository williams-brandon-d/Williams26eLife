function translation = masked_phase_cross_correlation(stack, template, mask, overlapRatio, fltr)

% prepare data
if exist('overlapRatio', 'var')
    overlapRatio = 0.6;
end
if exist('fltr', 'var')
    fltrFFT = fft2(fltr);
    template = real(ifftshift(ifft2(fft2(single(template)).*fltrFFT)));
else
    template = single(template);
end

mask = single(mask);
imageSize = size(template);


% calculate FFTs for mask
rotatedTemplateMask = rot90(mask,2);
fixedMaskFFT = fft2(mask);
rotatedMovingMaskFFT = fft2(rotatedTemplateMask);

% calculate FFTs for template
template(mask==0) = 0;
rotatedTemplateImage = rot90(template,2);
rotatedMovingFFT = fft2(rotatedTemplateImage);
rotatedMovingSquaredFFT = fft2(rotatedTemplateImage.^2);

% calculate FFTs for correlation mask
numberOfOverlapMaskedPixels = real(ifft2(rotatedMovingMaskFFT.*fixedMaskFFT));
numberOfOverlapMaskedPixels = round(numberOfOverlapMaskedPixels);
numberOfOverlapMaskedPixels = max(numberOfOverlapMaskedPixels,eps);
numberOfPixelsThreshold = overlapRatio * max(numberOfOverlapMaskedPixels(:));
invalidMask = numberOfOverlapMaskedPixels < numberOfPixelsThreshold;

% calculate FFTs for denominator related to template
maskCorrelatedRotatedMovingFFT = real(ifft2(fixedMaskFFT.*rotatedMovingFFT));
movingDenom = real(ifft2(fixedMaskFFT.*rotatedMovingSquaredFFT)) - maskCorrelatedRotatedMovingFFT.^2 ./ numberOfOverlapMaskedPixels;
movingDenom = max(movingDenom,0);

frameCnt = size(stack, 3);
translation = zeros(frameCnt, 2);
translation = gpuArray(translation);


for i = 1:frameCnt
    currentImage = stack(:,:,i);
    if exist('fltr', 'var')
        currentImage = abs(ifftshift(ifft2(fft2(single(currentImage)).*fltrFFT)));
    else
        currentImage = single(currentImage);
    end  
    
    currentImage(mask==0) = 0;
    currentImgFFT = fft2(currentImage);
    currentImgSquaredFFT = fft2(currentImage.^2);
    
    % calculate FFTs for current frame
    maskCorrelatedFixedFFT = real(ifft2(rotatedMovingMaskFFT.*currentImgFFT));
    
    numerator = real(ifft2(rotatedMovingFFT.*currentImgFFT)) - maskCorrelatedFixedFFT .* maskCorrelatedRotatedMovingFFT ./ numberOfOverlapMaskedPixels;
    
    fixedDenom = real(ifft2(rotatedMovingMaskFFT.*currentImgSquaredFFT)) - maskCorrelatedFixedFFT.^2 ./ numberOfOverlapMaskedPixels;
    fixedDenom = max(fixedDenom,0);
    
    denom = sqrt(fixedDenom .* movingDenom);
    
    C = numerator ./ denom;
    C = max(C, -1);
    C = min(C, 1);
    
    % Mask the borders;
    C(invalidMask) = 0;
    
    [~, imax] = max(C(:));
    [ypeak, xpeak] = ind2sub(size(C),imax(1));
    translation(i, :) = [ypeak xpeak];
end
translation(translation(:, 1) > imageSize(1)/2, 1) = translation(translation(:, 1) > imageSize(1)/2, 1) - imageSize(1);
translation(translation(:, 2) > imageSize(2)/2, 2) = translation(translation(:, 2) > imageSize(2)/2, 2) - imageSize(2);

translation = -round(translation);
end