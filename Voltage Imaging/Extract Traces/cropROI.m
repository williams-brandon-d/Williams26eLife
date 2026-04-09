%% crop ROI images in all subfolders

% find all .tif files in subfolders and save a cropped copy 
xWidth = 2000; % pixels
yWidth = 800; % pixels



path = 'D:\';

% [fname,fpath] = uigetfile('*.tif','Choose Tiff image:',path);
rootPath = uigetdir(path, 'Choose Folder Path:');
disp(['Folder Selected: ' rootPath]);

% find all subfolders that have .tif files excluding Processsed Data folders
foldernames = getFoldernames(rootPath);
nFolders = numel(foldernames);
fprintf('Number of Subfolders Found: %d\n',nFolders);

for iFolder = 1:nFolders
    fpath = foldernames{iFolder};
    fprintf('Folder %d: %s\n',iFolder,fpath);

    slashIdx = strfind(fpath,'\');
    folderName = fpath(slashIdx(end)+1:end);
    
    subfolderName = [fpath filesep 'Processed Data'];
    disp(['Processed Data Folder: ' subfolderName]);

    if ~isfolder(subfolderName)
        mkdir(subfolderName);
    end
   
    filenames = getFilenames(fpath,'.tif');
    nImages = numel(filenames);
    fprintf('Number of .tif Files found in Folder: %d\n',nImages);
    
    im1_name = fullfile(fpath, filenames{1} );
    im1 = imread(im1_name);
    im1_info = imfinfo( fullfile(fpath, filenames{1} ) );
    fprintf('Height = %d, Width = %d\n',im1_info.Height,im1_info.Width);
    
    xmlStruct = readstruct( fullfile(fpath,'Experiment.xml') );

    pixelSize = xmlStruct.LSM.pixelSizeUMAttribute; % microns
    fprintf('pixelSize = %.3g um\n',pixelSize);

%     frameRate = xmlStruct.LSM.frameRateAttribute ./ xmlStruct.LSM.averageNumAttribute; % frames / sec
%     fprintf('frameRate = %.3g frames/second\n',frameRate);

%     stack = zeros(im1_info.Height,im1_info.Width,nImages,'like',im1);

%     videoName = sprintf('%s.avi',folderName);
%     videoSaveName = fullfile(subfolderName,videoName);
%     disp(['Creating Video File: ' videoName]);
    
%     % video writer is trash for making long videos 
%     v = VideoWriter(videoSaveName);
%     v.FrameRate = frameRate; % frames per second
%     v.Quality = 100; % integer [0,100]
%     open(v);
%     fprintf('Writing video frames:');
    
    for iIm = 1:nImages
        fname = filenames{iIm};
 
        chanName = fname(1:5);
        if strcmp(chanName, 'ChanA')
            colorMap = makeColormap(256,'green');
        elseif strcmp(chanName, 'ChanB')
            colorMap = makeColormap(256,'red');
        end
        
%         stack(:,:,iIm) = readTiff(fullfile(fpath,fname));
%         stack(:,:,iIm) = imread(fullfile(fpath,fname));
        im = imread(fullfile(fpath,fname));

%         im = flip(im,1);
        
    %     figure; imshow(im,'Colormap',colorMap,'DisplayRange',climits);
        
        rgbImage = scaleRGB(im,cLimUpperPercentile,colorMap);
        rgbImage = addScalebar(rgbImage,pixelSize);
    
    %     figure; imshow(rgbImage);

        saveName = sprintf('%s_%d.tif',folderName,iIm);
        fprintf('Saved .tif Image: %s\n',saveName);
        saveFilename = fullfile(subfolderName,saveName);
        writeTiffRGB(uint8(rgbImage*255),saveFilename);
    
        fprintf(' %d',iIm);
%         writeVideo(v,rgbImage);
    
%         stack(:,:,iIm) = im;
    
    end

%     saveFilename = sprintf('%s.tif',fpath);
%     writeTiff(stack,saveFilename);

    
    fprintf('\n');
%     close(v);
    
%     stackSTD = std(stack,0,3);
%     rgbSTD = scaleRGB(stackSTD,cLimUpperPercentile,colorMap);
%     rgbSTD = addScalebar(rgbSTD,pixelSize);
%     
%     % figure; imshow(rgbSTD);
%     
%     saveName = sprintf('%s_STD.tif',folderName);
%     fprintf('Stack STD Filename: %s\n',saveName);
%     saveFilename = fullfile(subfolderName,saveName);
%     writeTiffRGB(uint8(rgbSTD*255),saveFilename);
%     
%     stackMean = mean(stack,3);
%     rgbMean = scaleRGB(stackMean,cLimUpperPercentile,colorMap);
%     rgbMean = addScalebar(rgbMean,pixelSize);
%     
%     % figure; imshow(rgbMean);
%     
%     saveName = sprintf('%s_Average.tif',folderName);
%     fprintf('Stack Average Filename: %s\n',saveName);
%     saveFilename = fullfile(subfolderName,saveName);
%     writeTiffRGB(uint8(rgbMean*255),saveFilename);

end

fprintf('done.\n');

%% functions

function foldernames = getFoldernames(rootPath)
% find all subfolders that have .tif files excluding Processed Data folders
% find all .tif files in folder and all subfolders
filelist = dir(fullfile(rootPath, '**\*.tif')); 
% find unique folders
foldernames = unique({filelist.folder})';
% remove Processed Data folders from list
removeMask = contains(foldernames,'Processed Data');
foldernames(removeMask) = [];
end

function filenames = getFilenames(fpath,extension)
filePattern = fullfile(fpath, sprintf('*%s',extension) );
folderInfo = dir(filePattern);
filenames = {folderInfo.name};
% remove preview .tif files from list
removeMask = contains(filenames,'Preview');
filenames(removeMask) = [];
% if more than 999 .tif files are recorded then filenames become longer and
% need to be sorted
if length(filenames) > 999
    [~,sortIndices] = sort(cellfun(@length,filenames),'ascend');
    filenames = filenames(sortIndices);
end
end

function colorMap = makeColormap(nMap,color)
% colormap values are double precision [0,1]
linMap = linspace(0,1,nMap);
colorMap = zeros(nMap,3); % map columns are RGB

switch color
    case 'red'
        colorMap(:,1) = linMap;
    case 'green'
        colorMap(:,2) = linMap;
    case 'blue'
        colorMap(:,3) = linMap;
end

end

function rgbImage = scaleRGB(im,cLimUpperPercentile,colormap)
% scale monocolor image to new maximum value using upper percentile bound
% then convert to RGB using colormap
% RGB values are double precision [0,1]
nMap = size(colormap,1);
imMax = prctile(im(:),cLimUpperPercentile);
climits = [0 imMax];
mask = im > imMax;
imNew = im;
imNew(mask) = imMax;
imScaled = uint16(rescale(imNew, climits(1),nMap-1));
rgbImage = ind2rgb(imScaled, colormap);
end

function rgbScalebar = addScalebar(rgbImage,pixelSize)

barWidthUM = 100; % microns
barWidthPixels = round(barWidthUM / pixelSize);

[Height,Width,~] = size(rgbImage);

barThickness = round(0.005*Height); 

% bottom align
row2 = round(0.95*Height); 
row1 = row2 - barThickness;

% left align
column1 = round(0.05*Width); 
column2 = column1 + barWidthPixels;

% % right align
% column2 = round(0.95*Width); 
% column1 = column2 - barWidthPixels;

rgbImage(row1:row2, column1:column2, :) = 1; % Write white bar into image.
% imshow(rgbImage);

rgbScalebar = rgbImage;
end
