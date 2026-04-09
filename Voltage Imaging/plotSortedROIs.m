function plotSortedROIs(ROIs,meanImage,clusterIdx,sortedIdx,saveFolder,savenum)
    % make ROI mask plot 
    nSelected = length(ROIs);

    nColors = max(clusterIdx);

    colors = loadClusterColors(nColors);
    colors = 0.8*colors; % darken colors
    
    [H,W] = size(ROIs{1});
    selectedROImask = ones(H*W,3); % H*W x RGB - white

    imEdge = mat2gray(meanImage); % gray scale
    imEdge = repmat(imEdge,1,1,3); % rgb
    
    for i = 1:nSelected
        color = colors(clusterIdx(i),:); % cluster color

        ROIcolor = repmat(color,H,1); % H x RGB
        ROIcolor = permute(ROIcolor,[1 3 2]);% H x 1 x RGB
        ROIcolor = repmat(ROIcolor,1,W,1); % H x W X RBG

        ROImask = repmat(double(ROIs{i}),1,1,3); % ROI mask
        ROIcolor = ROImask.*ROIcolor; % ROI with cluster color
        ROIcolor = reshape(ROIcolor,H*W,3); % H*W x RGB

        % use mask to apply ROI with color
        linMask = find(ROIs{i});
        selectedROImask(linMask,:) = ROIcolor(linMask,:);
%         selectedROImask(row,col,:) = ROIcolor(row,col,:); % full image with all ROIs

        % draw cluster color edge around ROIs on meanImage
        ROIedge = repmat(mat2gray(edge(ROIs{i})),1,1,3);
        ROIedge = ROIedge.*reshape(color,1,1,numel(color)); 
        imEdge = imEdge + ROIedge;
    end

    selectedROImask = reshape(selectedROImask,H,W,3);
    
    fig = figure('WindowState', 'maximized');
    hold on
    imshow(selectedROImask,'InitialMagnification','fit');
    % title(sprintf('%s',dataPath),'Interpreter','none');
    for i = 1:nSelected
        S = regionprops(ROIs{i},'Centroid');
        if length(S) > 1
            S = S(1);
        end
        text(S.Centroid(1),S.Centroid(2),string(sortedIdx(i)),'HorizontalAlignment','Center')
    end
    hold off
    drawnow;
    
    fig2 = figure('WindowState', 'maximized');
    hold on
    imshow(imEdge,'InitialMagnification','fit');
    % title(sprintf('%s',dataPath),'Interpreter','none');
    for i = 1:nSelected
        S = regionprops(ROIs{i},'Centroid');
        text(S(1).Centroid(1),S(1).Centroid(2), string(sortedIdx(i)),'HorizontalAlignment','Center','Color','white');
%         set(texthan, 'Color', [1 1 1]);
    end
    hold off

    if savenum
        print(fig,'-vector','-dsvg',[saveFolder filesep 'ROI mask sorted.svg']) % svg
%         print(fig2,'-vector','-dsvg',[saveFolder filesep 'meanImage with ROIs sorted.svg']) % svg - problem with saving text as white
        exportgraphics(fig2,[saveFolder filesep 'meanImage with ROIs sorted.tif'],'Resolution',300) % tif - less background white than print
        % use print for no compression tif
    end

end