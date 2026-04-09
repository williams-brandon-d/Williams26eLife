function ot = myOTeststats(data_all,rowLabels,colLabels)
% stats - normality and anova

[nRows,nCols] = size(data_all);

ot = struct();

ot.p = cell(nRows*nCols,1);
ot.m = ot.p;
cellArray = ot.p;
commentArray = ot.p;

% check normality - or use cellfun
iArray = 0;
for i = 1:nRows
    for j = 1:nCols
        iArray = iArray + 1;
        cellArray{iArray} = rowLabels{i};
        if nCols == 1
            if iscell(colLabels)
                commentArray{iArray} = cell2mat(reshape(colLabels,1,[]));
            else
                commentArray{iArray} = colLabels;
            end
        else
            if iscell(colLabels)
                commentArray{iArray} = colLabels{j};
            else
                commentArray{iArray} = colLabels;
            end
        end

        data = data_all{i,j};
        notNaN = ~isnan(data);
        data = data(notNaN); % remove NaNs
        N = numel(data);
        if N > 2
            % circ_rtest cant handle NaN inputs
            [ot.p{iArray}, ot.m{iArray}] = circ_otest(data); % Computes Omnibus or Hodges-Ajne test for non-uniformity of circular data.
        else
            ot.p{iArray} = NaN; ot.z{iArray} = NaN;
        end
    end
end

ot.results = cell2table([cellArray commentArray ot.p ot.m],'VariableNames',{'Cell Types', 'Comments','P-value','M'});

end