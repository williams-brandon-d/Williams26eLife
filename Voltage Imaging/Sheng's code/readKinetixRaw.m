function varargout = readKinetixRaw(fileInfo, depth, skipFrames)

% read metadata
metadata = fileread([fileInfo(1).folder,'\0_imagej_import.txt']);
expr = '[0-9]{1,4}';
matches = regexp(metadata, expr,'match');
type = str2num(matches{1});
width = str2num(matches{2});
height = str2num(matches{3});
offset = str2num(matches{4});
gap = str2num(matches{5}) / (type / 8); % express in number of pixels (uint8 or uint16)

if type == 8
    dataType = 'uint8=>uint8';
else
    dataType = 'uint16=>uint16';
end

% calculate number of frames to read
chunkSize = 15; % maximum read data size per chunk in GB
chunk = floor(chunkSize*1024*1024*1024/(width*height + gap)/(type/8));
fileSize = fileInfo.bytes;
frameCnt = (fileSize-offset)/(width*height + gap)/(type/8); % 16 bit or 8 bit image
depth = min(depth, frameCnt);

% open file
fileID = fopen([fileInfo(1).folder,'\',fileInfo(1).name]);


% read image stack, crop to ROI, and perform pixel binning
tic;
if ~exist('skipFrames','var')
    skipFrames = 10;
end
%stack = zeros(height*width, depth-skipFrames, 'uint16'); 
stack = {};

frewind(fileID);
fread(fileID, offset, 'uint8=>uint8');  % skip initial offset
fseek(fileID, (width*height + gap)*(type/8)*skipFrames, 'cof'); % remove first 10 frames
for i = 1:ceil((depth-skipFrames)/chunk)
    remainingFrames = depth - skipFrames - (i-1)*chunk;
    tmp = fread(fileID, [width*height+gap min(chunk, remainingFrames)], dataType);
    idx = (i-1)*chunk + 1;
    tmp((width*height+1):end, :) = [];
    %tmp = reshape(tmp(1:width*height, :), width, height, []);
    %if i == 1
    %    stack(:,:,)  = permute(tmp, [2,1,3]);
    %else
    %tmp = uint16(permute(tmp, [2,1,3]));
    stack{1,i} = tmp;
        %stack(:, idx:min(i*chunk, frameCnt-skipFrames))  = tmp;
    %end
end



% for fn = 1:numel(fileInfo)
%     fileSize = fileInfo(fn).bytes;
%     frameCnt = (fileSize-offset)/(width*height + gap)/(type/8); % 16 bit or 8 bit image
%     fprintf('Total frames %d\n', frameCnt);
%     batchSize = floor(maxReadSize*1024*1024*1024/(width*height + gap)/(type/8));
%     
%     for i = 1:ceil(frameCnt./batchSize)
%         depth = i * batchSize;
%         skipFrame = max(5, (i-1) * batchSize);
%         fprintf('Reading frame up to %d out of %d\n', depth, frameCnt);
%     
%         clear stack shifts stack2;
%         [stack, ~] = readKinetixRaw(fileInfo(fn), depth, skipFrame);
%         
%     end
% end


stack = cell2mat(stack);
stack = reshape(stack, width, height, []);
stack = permute(stack, [2 1 3]);

fclose(fileID);
toc

%% check if extra mat file is saved in the same folder

matFile = dir([fileInfo.folder,'\*-data.mat']);
if numel(matFile) > 0
    acqData = load([matFile(end).folder,'\',matFile(end).name]);
else
    acqData = [];
end

%% complie output
nOutputs = nargout;
varargout = cell(1,nOutputs);

varargout{1} = stack;

if nOutputs == 2
    varargout{2} = acqData;
end


end