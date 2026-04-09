% Thy1 vs PV data comparisons

clear variables; close all; clc;
cd('C:\Users\brndn\OneDrive\Desktop\White Lab\Matlab Files\');
addpath(genpath('./')); % add all folders and subfolders in cd to path
savenum = 1; % 0 = don't save, 1 = save info

cellTypes = {'Stellate','Pyramidal','FastSpiking'};

dataSets = {'Thy1','PV Transgenic'};

dataTypes = {'power','frequency','phase'};

saveTableFolder = 'C:\Users\brndn\OneDrive\Desktop\White Lab\My Papers\stats\';

nDataTypes = numel(dataTypes);
nDataSets = numel(dataSets); % n Groups
nCellTypes = numel(cellTypes);

data = struct;

for iType = 1:nDataTypes
    dataType = dataTypes{iType};
    allData = cell(nDataSets*nCellTypes,1);
    allNames = allData;
    count = 0;
    
    for iSet = 1:nDataSets
        dataSet = dataSets{iSet};
        saveFolder = getSummarySaveFolder(dataSet);
        saveFilename = sprintf('%s theta inhibition %s stats.xlsx',dataSet,dataType);
        fullname = fullfile(saveFolder,saveFilename);

        t = readtable(fullname,'Sheet','data'); % load data table from spreadsheet
        
        for iCell = 1:nCellTypes
            count = count + 1;
            cellType = cellTypes{iCell};
            allData{count} = t.(cellType);
            allNames{count} = sprintf('%s %s',dataSet,cellType); % add dataset name to cell name
        end

    end

    allData_ttest = reshape(allData, nCellTypes, nDataSets);
    allNames_ttest = reshape(allNames, nCellTypes, nDataSets);
    saveTablename = sprintf('%s and %s %s TTest.xlsx',dataSets{1},dataSets{2},dataType);
    fullTablename = fullfile(saveTableFolder,saveTablename);
    stats = myUnPairedStats(allData_ttest,cellTypes,dataSets,fullTablename,savenum);
    
    a = myAnovaStats(allData,allNames); % anova with all celltypes and all datasets for each datatype

    if savenum
        saveTablename = sprintf('%s and %s %s Anova.xlsx',dataSets{1},dataSets{2},dataType);
        fullTablename = fullfile(saveTableFolder,saveTablename);
        writetable(a.results,fullTablename,'Sheet','ANOVA','WriteMode','overwritesheet');  % save anova stats table
    end

end

%% compare PV vs DNQX after

