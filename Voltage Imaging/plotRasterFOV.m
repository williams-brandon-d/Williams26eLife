% raster plot for entire FOV

clear variables; close all; clc;
cd('D:/Matlab Files/'); % choose your current directory
addpath(genpath('./')); % add all folders and subfolders in cd to path

savenum = 0;

% select rootPath 
folder = 'D:/TICO Voltage Imaging Data/CaMK2-ChR2-Voltron Data/';
rootPath = uigetdir(folder, 'Select a folder to read');
disp(['Folder Selected: ' rootPath]);

% find all subfolders that have .mat files excluding Processsed Data folders
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

    % load saved ROI data
    saveFilename = [fpath filesep 'Processed Data.mat'];
    load(saveFilename,'spikes','frame_rate','finalTraceIdx','lfp');

     % save frame_rate and invert traces during trace extraction
    if ~exist('lfp','var')
        lfp = [];
        disp('.abf file not processed.');
    end  

    % save frame_rate and invert traces during trace extraction
    if ~exist('frame_rate','var')
        frame_rate = 800;
        save(saveFilename,'frame_rate','-nocompression','-append'); % save frame_rate
    end


    if exist('spikes','var') 
        spikes = spikes(finalTraceIdx);

        % plot raster for entire FOV
        fig = rasterPlotFOV(spikes,lfp,frame_rate,1);
        % save fig
        plotFilename = [subfolderName filesep 'raster plot FOV.svg'];
        print(fig,'-vector','-dsvg',plotFilename);
    
%         % save spikes
%         if savenum
%             save(saveFilename,'spikes','-nocompression','-append'); % save spikes
%         end
    end

    % clear variables before next file
    if nFolders > 1
        clearvars spikes frame_rate lfp;
    end

end

function foldernames = getFoldernames(rootPath)
% find all subfolders that have .mat files
filelist = dir(fullfile(rootPath, '**\*Processed Data.mat')); 
% find unique folders
foldernames = unique({filelist.folder})';
end


function fig = rasterPlotFOV(spikes,lfp,frame_rate,savenum)

% make Raster plots for each trace

tickfontsize = 15;

% for 'PlotType','vertline','LineFormat',LineFormat
% LineFormat = struct();
% LineFormat.LineWidth = 1;
% LineFormat.LineStyle = '-';

% for 
MarkerFormat = struct();
% MarkerFormat.MarkerSize = 5;
MarkerFormat.MarkerSize = 10;
MarkerFormat.Color = 0*[1 1 1];
MarkerFormat.LineStyle = 'none';

fontsize = 12;

nSelected = numel(spikes);
nFrames = numel(spikes(1).masks);

% time = (0:nFrames-1)/frame_rate;

% downsample stim data
stim_data = interp1(lfp.time, lfp.stim_data, lfp.time_ds, 'cubic');
stim_time = 1:nFrames;

rasterArray = false(nSelected,nFrames);

% gather binary spike masks into array
for i = 1:nSelected 

    rasterArray(i,:) = spikes(i).masks;
    
end

% flip y axis to match voltage trace plot
rasterArray = flipud(rasterArray);

% plot raster
fig = figure('WindowState','maximized');
ax1 = subplot(2,1,1);
   [~, ~] = plotSpikeRaster(rasterArray,'PlotType','scatter','MarkerFormat',MarkerFormat);
   xlim([-inf inf])
%    ylim([-inf inf])
   xlabel('Time (s)')
   ylabel('Neuron #')
%        xticks([-pi -pi/2 0 pi/2 pi]);
%        xticklabels({'-π','-π/2','0','π/2','π'});
%            plotTitle = sprintf('%s Light Power = %g',info(ID_index).cell_type,info(ID_index).led_input);
%            title(plotTitle,'FontSize',titlefontsize,'FontWeight','bold')

%     xlim([0, nFrames+1]);
    xlim([lfp.cycle_start_indices_ds(8) lfp.cycle_start_indices_ds(12)])

   ax1.YAxis.FontSize = tickfontsize;
   ax1.YAxis.FontWeight = 'bold';
   ax1.XAxis.FontSize = tickfontsize;
   ax1.XAxis.FontWeight = 'bold';

   set(ax1,'visible','off')

    ax1pos = get(ax1, 'Position'); % pos array = [x y width height]
    ax1pos(2) = 0.50;
    ax1pos(4) = 0.50;
    set(ax1, 'Position', ax1pos)
    drawnow;

   % add stim
    color = [91, 207, 244] / 255;

    ax2 = subplot(2,1,2);

    ax2pos = get(ax2, 'Position'); % pos array = [x y width height]
    ax2pos(2) = 0.45;
    ax2pos(4) = 0.05;
    set(ax2, 'Position', ax2pos)
    drawnow;

    han2 = fill(stim_time,stim_data,color,'DisplayName','Light');
    han2.EdgeColor = 'none';
    han2.LineStyle = 'none';

    ylim([0 max(stim_data)])

%     xlim([0, nFrames+1]);
    xlim([lfp.cycle_start_indices_ds(8) lfp.cycle_start_indices_ds(12)])

    set(ax2,'visible','off')
    drawnow;

%     ax2pos = get(ax2, 'Position'); % pos array = [x y width height]
%     ax2pos(2) = 0.05;
%     ax2pos(4) = 0.05;
%     set(ax2, 'Position', ax2pos)
%     drawnow;

    % time scalebar
    time_scaleBar = 0.500; % s
    tscaleshift = 0.550; % s

    % convert to samples
    shift = tscaleshift*frame_rate;
    time_scale = time_scaleBar*frame_rate;

    Xlim = xlim;
    Ylim = ylim;

    tscaleX = Xlim(1) + shift + [0 time_scale];
    tscaleY = Ylim(1)*ones(1,2) - 0.2*(Ylim(2)-Ylim(1));

    hold on;
    plot(tscaleX,tscaleY,'-k','Linewidth',2); % plot time scalebar
    drawnow;

    textX = tscaleX(1) + 0.5*time_scale; % center of X scalebar
    textY = tscaleY(1); % y position of X scalebar
    xscale = text(textX,textY,sprintf('%g ms',time_scaleBar*1000)); % plot text
    xscale.FontSize = fontsize;
    xscale.FontWeight = 'bold';
    xscale.VerticalAlignment = 'top';
    xscale.HorizontalAlignment = 'center';
    hold off;

    ylim([tscaleY(1) Ylim(2)]);

end