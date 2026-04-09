function ROIs = AlignROIs(ROIs,meanImage,ROIimage)
% register current averageFrame with ROI file averageFrame

% INPUT:
% neuron - structure containing ROI masks
% meanImage - average frame from prior recording with same ROIs
% ROIimage - average frame form current recording

% OUTPUT
% ROIs - structure containing updated ROI masks

% FUNCTION AlignROIs()
% plots figures with previous recording average frame and current recording average frame
% starts with ROI mask locations from prior recording on both figures
% user is then asked to input manual x and y translation if necessary
% update ROI figures with user input shifted ROIs
% confirm drift is correct [0 0] or input different drift coordinates [xshift yshift]
% xshift - positive shifts image left
% yshift - positive shifts image up 

% possible alternative approach:
% downsample images for cross correlation
% downsample_factor = 5; % x and y
% before xcorr could bandpass filter images
% then normalize pixel values and binarize image
% [driftY, driftX] = getRegistrationCoordinate(meanImage,ROIimage);

shift = [0 0]; % initialize with zero shift

N = numel(ROIs);
[H,W] = size(ROIs{1});

flag = 1;

while flag % shift is nonzero

    xPad = abs(shift(1));
    yPad = abs(shift(2));

    imEdge = mat2gray(meanImage); 
    imEdge_old = mat2gray(ROIimage);
        
    for i = 1:N
        % need to add functionality to cut off ROI if shifted beyond edge of Frame 

        padMask = false(H+2*yPad,W+2*xPad); % extend ROI mask
        padMask((1:H)+yPad,(1:W)+xPad) = ROIs{i}; % center ROI with padded edges
    
        padMask = circshift(padMask,shift(2),1); % shift ROI columns
        padMask = circshift(padMask,shift(1),2); % shift ROI rows
    
        ROIs{i} = padMask((1:H)+yPad,(1:W)+xPad); % keep original ROI frame

        adjustedROIedge = mat2gray(edge(ROIs{i}));
        imEdge = imEdge + adjustedROIedge; % draw ROI edge on meanImage
        imEdge_old = imEdge_old + adjustedROIedge; % draw ROI edge on ROIimage
    end

    figure('WindowState', 'maximized');
    imshow(imEdge_old,'InitialMagnification','fit');
    title('Previous ROI image with new ROI edges')
    
    figure('WindowState', 'maximized');
    imshow(imEdge,'InitialMagnification','fit');
    title('ROIs adjusted for drift')
    
    shift = input("Input relative X and Y shift in pixels [x y]: ");
    flag = any(shift); % if any nonzero shift run again
end

end
