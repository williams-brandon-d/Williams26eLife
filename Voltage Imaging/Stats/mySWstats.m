function sw = mySWstats(data_all,rowLabels,colLabels)
% stats - normality and anova

[nRows,nCols] = size(data_all);

sw = struct();
sw.Alpha = 0.05;

sw.H = cell(nRows*nCols,1);
sw.p = sw.H;
sw.W = sw.H;
cellArray = sw.H;
commentArray = sw.H;

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
            commentArray{iArray} = colLabels{j};
        end
        data = data_all{i,j}; % vectorize if needed
        [sw.H{iArray}, sw.p{iArray}, sw.W{iArray}] = swtest(data(:), sw.Alpha); % H=0 is normal
    end
end

sw.results = cell2table([cellArray commentArray sw.p sw.W],'VariableNames',{'Stim', 'Comments','P-value','W'});

end