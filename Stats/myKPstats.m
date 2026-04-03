function kp = myKPstats(data_all,rowLabels,colLabels)
% stats - normality and anova

[nRows,nCols] = size(data_all);

kp = struct();

kp.p = cell(nRows*nCols,1);
kp.k = kp.p;
kp.K = kp.p;
cellArray = kp.p;
commentArray = kp.p;

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
            % circ cant handle NaN inputs
            [thetahat, kappa] = circ_vmpar(data); % estimate vm params
            vm = circ_vmrnd(thetahat, kappa, 30); % generate samples from von mises distribution
            [kp.p{iArray}, kp.k{iArray}, kp.K{iArray}] = circ_kuipertest(data,vm); % kuiper's test to compare distributions
        else
            kp.p{iArray} = NaN; kp.k{iArray} = NaN; kp.K{iArray} = NaN;
        end
    end
end

kp.results = cell2table([cellArray commentArray kp.p kp.k kp.K],'VariableNames',{'Cell Types', 'Comments','P-value','k test statistic','K critcal value'});

end