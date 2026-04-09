function plotROIs(ROIs,meanImage,saveFolder,savenum)
    % make ROI mask plot 
    nSelected = length(ROIs);
    
    [H,W] = size(ROIs{1});
    selectedROImask = false(H,W);
    selectedROIedges = cell(1,nSelected);
    imEdge = mat2gray(meanImage);
    
    for i = 1:nSelected
        selectedROImask = selectedROImask | ROIs{i};
        selectedROIedges{i} = edge(ROIs{i});
        imEdge = imEdge + mat2gray(selectedROIedges{i});
    end
    
    fig = figure('WindowState', 'maximized');
    hold on
    imshow(selectedROImask,'InitialMagnification','fit');
    % title(sprintf('%s',dataPath),'Interpreter','none');
    for i = 1:nSelected
        S = regionprops(ROIs{i},'Centroid');
        if length(S) > 1
            S = S(1);
        end
        text(S.Centroid(1),S.Centroid(2),string(i),'HorizontalAlignment','Center')
    end
    hold off
    drawnow;
    
    fig2 = figure('WindowState', 'maximized');
    hold on
    imshow(imEdge,'InitialMagnification','fit');
    % title(sprintf('%s',dataPath),'Interpreter','none');
    for i = 1:nSelected
        S = regionprops(ROIs{i},'Centroid');
        texthan = text(S(1).Centroid(1),S(1).Centroid(2), string(i),'HorizontalAlignment','Center');
        set(texthan, 'Color', [1 1 1]);
    end
    hold off
    drawnow;

    if savenum
        % use imwrite instead of exporting figure

%         print(fig,'-vector','-dsvg',[saveFolder filesep 'ROI mask.svg']) % svg
        exportgraphics(fig,[saveFolder filesep 'ROI mask.tif'],'Resolution',300) % tif - less background white than print
%         print(fig2,'-vector','-dsvg',[saveFolder filesep 'meanImage with ROIs.svg']) % svg - text not saving as white
%         print(fig2,'-dtiffn','-r300',[saveFolder filesep 'meanImage with ROIs.tif']) % tif
        exportgraphics(fig2,[saveFolder filesep 'meanImage with ROIs.tif'],'Resolution',300) % tif - less background white than print
    end

end