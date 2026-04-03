function ray = myRayleighstats(data_all,rowLabels,colLabels)
% stats - normality and anova

[nRows,nCols] = size(data_all);

ray = struct();

ray.p = cell(nRows*nCols,1);
ray.z = ray.p;
cellArray = ray.p;
commentArray = ray.p;

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
            [ray.p{iArray}, ray.z{iArray}] = circ_rtest(data); % Rayleigh's test for nonuniformity
        else
            ray.p{iArray} = NaN; ray.z{iArray} = NaN;
        end
    end
end

ray.results = cell2table([cellArray commentArray ray.p ray.z],'VariableNames',{'Cell Types', 'Comments','P-value','Z'});

end