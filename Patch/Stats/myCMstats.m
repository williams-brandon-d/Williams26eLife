function cm = myCMstats(data_all,cell_types)

[nCells,~] = size(data_all);

% construct data array with NaNs
maxNumEl = max(cellfun(@numel,data_all(:)));
data_all_pad = cellfun(@(x){padarray(x(:),[maxNumEl-numel(x),0],NaN,'post')}, data_all(:)); % Pad each vector with NaN values to equate lengths
data_all_mat = cell2mat(data_all_pad'); 

% run non-parametric one-way anova similar to Kruskal-Wallis test and multiple comparisons test 
%   The common medians test - test if two medians are equal 

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

cm.testType = 'Non-parametric one-way ANOVA';

[pval,~,P,msg] = circ_cmtest(dataVector,idxVector);

% set up table
cm.tbl = array2table([pval,P],'VariableNames',{'P-value','P statistic'});
cm.tbl = [cm.tbl cell2table({msg},'VariableNames',{'Message'})];

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
pstat = p;
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
    
    [p(iComp),~,pstat(iComp),msg{iComp}] = circ_cmtest(dataComp,idxComp);

end

p_bonf = p*nComparisons; % bonferroni correction for multiple comparisons
gnames = reshape(cell_types,[],1);
cm.results = array2table([test_indices,pstat,p,p_bonf],"VariableNames",["Group A","Group B","P statistic","P-value","P-value (bonferroni)"]);
cm.results.("Group A") = gnames(cm.results.("Group A"));
cm.results.("Group B") = gnames(cm.results.("Group B"));
cm.results = [cm.results cell2table(msg,'VariableNames',{'Message'})];

end