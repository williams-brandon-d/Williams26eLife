function [ROImask, ROIs] = selectROI(orig, roiFunc)

%% make figure
hFig=figure('visible','off','position',[1 20 1600 900]);

slmin = uicontrol('style','slider','position',[50 50 750 20],'min', 0, 'max', 1, 'callback',@adjustMinMax);
slmax = uicontrol('style','slider','position',[50 20 750 20],'min', 0, 'max', 1, 'callback',@adjustMinMax);
slflatten = uicontrol('style','slider','position',[870 50 700 20],'min', 0, 'max', 1, 'callback',@flattenImage);
btnreset = uicontrol('style','pushbutton', 'position', [830, 20, 150, 20],'String','Reset grayscale' , 'callback', @resetGrayscale);
btndelete = uicontrol('style','pushbutton', 'position', [1000, 20, 150, 20],'String','Delete last ROI' , 'callback', @deleteROI);
slzoom = uicontrol('style','slider','position',[1200 20 370 20],'min', 0.1, 'max', 5,'callback',@zoomImage); slzoom.Value = 1;

uicontrol(hFig ,'Style', 'text','String','Min','Position',[20 50 30 20]);
uicontrol(hFig ,'Style', 'text','String','Max','Position',[20 20 30 20]);
uicontrol(hFig ,'Style', 'text','String','Flatten','Position',[830 50 30 20]);
uicontrol(hFig ,'Style', 'text','String','Zoom','Position',[1160 20 30 20]);

ax = axes('units','pixels','position',[50 100 1400 800]);
movegui(hFig,'center');
set(hFig,'visible','on');

set(findall(hFig, '-property', 'Units' ), 'Units', 'Normalized' )
set(hFig, 'units','normalized','outerposition',[0 0.05 1 0.95]); % maximize figure

%% process image
orig = single(orig); orig = orig-min(orig,[],'all'); orig = orig./max(orig,[],'all');
originalImage = orig;
%originalImage = imflatfield(originalImage, 300);
 
ROImask = zeros(size(originalImage));

absMax = max(originalImage,[],'all'); absMin = min(originalImage,[],'all');
cmax = prctile(originalImage,99.9,'all'); slmax.Value = (cmax - absMin)./(absMax - absMin);
cmin = prctile(originalImage,0.1,'all'); slmin.Value = (cmin - absMin)./(absMax - absMin);

ax = gca;
hIm = imagesc(originalImage);axis image;axis off;colormap(gray);%drawnow;
hSP = imscrollpanel(hFig,hIm);
set(hSP,'Units','normalized','Position',[0 0.1 1 0.9]);
axtoolbar(ax,'Visible','off');
api = iptgetapi(hSP);

slzoom.Value = max(api.findFitMag(), 1.6);
api.setMagnification(slzoom.Value);

ROIs = {};
drawroi = roiFunc;

chooseROI();


function adjustMinMax(~, ~)
    minVal=get(slmin,'value');
    maxVal=get(slmax,'value');
    minVal = min(minVal, maxVal); maxVal = max(minVal, maxVal);
    slmin.Value = minVal; slmax.Value = maxVal;
    cmin = absMin + minVal*(absMax - absMin);
    cmax = absMin + maxVal*(absMax - absMin);

    api.replaceImage(originalImage./(1 + 0.5.*single(ROImask)), [cmin, cmax], 'PreserveView', 1);

end

function flattenImage(~, ~)
    if slflatten.Value > 0  % no flattening
        originalImage = single(orig);
        originalImage = imflatfield(originalImage, 1000.*(1 - slflatten.Value) + 1);
    else
        originalImage = single(orig);
    end
    resetGrayscale();
end

function resetGrayscale(~, ~)
    absMax = max(originalImage,[],'all'); absMin = min(originalImage,[],'all');
    cmax = prctile(originalImage,99.9,'all'); slmax.Value = (cmax - absMin)./(absMax - absMin);
    cmin = prctile(originalImage,0.1,'all'); slmin.Value = (cmin - absMin)./(absMax - absMin);
    adjustMinMax();
end

function zoomImage(~, ~)
    api.setMagnification(slzoom.Value);
end

function chooseROI()
    api.replaceImage(originalImage./(1 + 0.5.*single(ROImask)), [cmin, cmax], 'PreserveView', 1);
    ROI = drawroi();
    while isvalid(ROI) && isvalid(hFig)
        ROIs{end+1} = createMask(ROI);
        bw = createMask(ROI);
        ROImask = ROImask | bw;
        %imagesc(ax, originalImage./(1 + 0.5.*single(ROImask)), [cmin, cmax]);axis image;axis off;colormap(gray);drawnow
        api.replaceImage(originalImage./(1 + 0.5.*single(ROImask)), [cmin, cmax], 'PreserveView', 1);pause(0.1);
        roi_hndl = findobj(ax,'Type','images.roi');
        delete(roi_hndl);clear roi_hndl;
        ROI = drawroi();
    end
end

function deleteROI(~,~)   
    if numel(ROIs) > 0
        ROImask(ROIs{end}) = 0;
        ROIs(end) = [];
        api.replaceImage(originalImage./(1 + 0.5.*single(ROImask)), [cmin, cmax], 'PreserveView', 1);pause(0.1);
    end
end

ROImask = logical(ROImask);

end


