function kt = myKtest(data_all,cell_types)

[nCells,~] = size(data_all);

% construct data array with NaNs
maxNumEl = max(cellfun(@numel,data_all(:)));
data_all_pad = cellfun(@(x){padarray(x(:),[maxNumEl-numel(x),0],NaN,'post')}, data_all(:)); % Pad each vector with NaN values to equate lengths
data_all_mat = cell2mat(data_all_pad'); 

% test for equal concentrations - ktest

% remove NaNs
notNaNall = ~isnan(data_all_mat);

for i = 1:nCells
    data_all{i,1} = data_all_mat(notNaNall(:,i),i);
end

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

[nComparisons,~] = size(test_indices);

p = NaN([nComparisons,1]);
f = p;
rbar = p;

msg = cell(nComparisons,1);

for iComp = 1:nComparisons    
    [p(iComp),f(iComp),msg{iComp},rbar(iComp)] = circ_ktest(data_all{test_indices(iComp,1),1},data_all{test_indices(iComp,2),1});
end

gnames = reshape(cell_types,[],1);
kt.results = array2table([test_indices,f,p],"VariableNames",["Group A","Group B","P statistic","P-value"]);
kt.results.("Group A") = gnames(kt.results.("Group A"));
kt.results.("Group B") = gnames(kt.results.("Group B"));
kt.results = [kt.results cell2table(msg,'VariableNames',{'Message'})];
kt.results = [kt.results array2table(rbar,'VariableNames',{'rbar'})];

end