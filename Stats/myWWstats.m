function ww = myWWstats(data_all,cell_types)

[nCells,~] = size(data_all);

% construct data array with NaNs
maxNumEl = max(cellfun(@numel,data_all(:)));
data_all_pad = cellfun(@(x){padarray(x(:),[maxNumEl-numel(x),0],NaN,'post')}, data_all(:)); % Pad each vector with NaN values to equate lengths
data_all_mat = cell2mat(data_all_pad'); 

% run one-way anova and multiple comparisons test 
%   The Watson-Williams two-sample test assumes underlying von-Mises distributrions. 
%   All groups are assumed to have a common concentration parameter k. (circ_ktest)

notNaNall = ~isnan(data_all_mat);
Ns = sum(notNaNall,1);
totalN = sum(notNaNall(:));
dataVector = zeros(totalN,1);
idxVector = dataVector;

% build all data vector and group indices
for iCell = 1:nCells
    data = data_all{iCell,1};
    notNaN = ~isnan(data);
    data = data(notNaN);
    N = numel(data);

    if iCell == 1
        start = 1;
    else 
        start = sum(Ns(1:(iCell-1))) + 1;
    end
    stop = sum(Ns(1:iCell));
    dataVector(start:stop) = data;
    idxVector(start:stop) = iCell*ones(N,1);
end

ww.testType = 'One-way ANOVA';

[~,tbl,msg,rw] = circ_wwtest(dataVector,idxVector);

% set up table
msgArray = cell(size(tbl,1)-1,1);
msgArray{1} = msg;
rwArray = NaN(size(tbl,1)-1,1);
rwArray(1) = rw;
ww.tbl = cell2table(tbl(2:end,2:end),'VariableNames',tbl(1,2:end),'RowNames',tbl(2:end,1));
ww.tbl = [ww.tbl cell2table(msgArray,'VariableNames',{'Message'})];
ww.tbl = [ww.tbl array2table(rwArray,'VariableNames',{'rw'})];

% perform pairwise mean comparisons for all combinations
if nCells == 3
    test_indices = [1 2;
                    1 3;
                    2 3];
elseif nCells == 4
    test_indices = [1 2;
                    1 3;
                    1 4;
                    2 3;
                    2 4;
                    3 4];
else
    error('comparisons testing not set up for more than 4 groups');
end

[nComparisons,nGroups] = size(test_indices);

p = NaN([nComparisons,1]);
rw = p;
msg = cell(nComparisons,1);

for iComp = 1:nComparisons
    % build data and index vectors for ww test
    comp_idx = test_indices(iComp,:);
    groupNs = Ns(comp_idx);
    totalgroupNs = sum(groupNs(:));
    dataComp = zeros(totalgroupNs,1);
    idxComp = dataComp;

    for iGroup = 1:nGroups
        group = comp_idx(iGroup);
        data = data_all{group,1};
        notNaN = ~isnan(data);
        data = data(notNaN);
        N = numel(data);
    
        if iGroup == 1
            start = 1;
        else 
            start = sum(groupNs(1:(iGroup-1))) + 1;
        end
        stop = sum(groupNs(1:iGroup));
        dataComp(start:stop) = data;
        idxComp(start:stop) = iGroup*ones(N,1);
    end
    
    [p(iComp),~,msg{iComp},rw(iComp)] = circ_wwtest(dataComp,idxComp);

end

p_bonf = p*nComparisons; % bonferroni correction for multiple comparisons
gnames = reshape(cell_types,[],1);

ww.results = array2table([test_indices,p,p_bonf],"VariableNames",["Group A","Group B","P-value","P-value (bonferroni)"]);
ww.results.("Group A") = gnames(ww.results.("Group A"));
ww.results.("Group B") = gnames(ww.results.("Group B"));
ww.results = [ww.results cell2table(msg,'VariableNames',{'Message'})];
ww.results = [ww.results array2table(rw,'VariableNames',{'rw'})];

end