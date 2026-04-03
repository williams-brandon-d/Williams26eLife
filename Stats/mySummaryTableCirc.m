function data_table = mySummaryTableCirc(data_all,cell_types)
[nCells,nGroups] = size(data_all);

% construct data array with NaNs
maxNumEl = max(cellfun(@numel,data_all(:)));
data_all_pad = cellfun(@(x){padarray(x(:),[maxNumEl-numel(x),0],NaN,'post')}, data_all); % Pad each vector with NaN values to equate lengths
data_all_pad = data_all_pad';

if nGroups > 1
    data_all_pad = data_all_pad(:);
    data = reshape(data_all_pad,1,[]);
    data_all_mat = cell2mat(data); 
else
    data_all_mat = cell2mat(data_all_pad);
end

% if size(data_all,2) == 1
%     data_all_mat = data_all_mat';
% end

% circ stat functions cant handle NaNs!!!! <-- trash
meanData = NaN([1,nCells]);
CI95 = meanData;
CI5 = meanData;
N = meanData;
sd = meanData;
SEM = meanData;
medianData = meanData;
dataMin = meanData;
dataMax = meanData;
dataRange = meanData;

for iCell = 1:nCells
    data = data_all_mat(:,iCell);
    notNaN = ~isnan(data);
    data = data(notNaN); % remove NaNs

    [meanData(1,iCell),CI95(1,iCell),CI5(1,iCell)] = circ_mean(data);
    
    N(1,iCell) = sum(notNaN);
    
    if N(1,iCell) < 2
        sd(1,iCell) = NaN;
    else
        sd(1,iCell) = circ_std(data);
    end
    
    SEM(1,iCell) = sd(1,iCell)./sqrt(N(1,iCell));
    
    medianData(1,iCell) = circ_median(data);
        
    dataMin(1,iCell) = min(data);
    dataMax(1,iCell) = max(data);
    dataRange(1,iCell) = range(data);
end

% column names for cell types
varNames = cell(nCells*nGroups,1);
count = 0;
for i = 1:nCells
    switch cell_types{i}
        case {'stellate','Stellate'}
            cellName = 'Stellate';
        case {'pyramidal','Pyramidal'}
            cellName = 'Pyramidal';
        case {'fast spiking','FastSpiking'}
            cellName = 'FastSpiking';
        otherwise
            cellName = cell_types{i};
    end
    for iGroup = 1:nGroups
        count = count+1;
        groupName = sprintf('group%d',iGroup);
        varNames{count} = [cellName '_' groupName];
    end
end

data_table = array2table([meanData; sd; N; SEM; CI5; CI95; medianData; dataMin; dataMax; dataRange],'VariableNames',varNames,'RowNames',{'Mean','SD','N','SEM','CI5','CI95','Median','Min','Max','Range'});

end