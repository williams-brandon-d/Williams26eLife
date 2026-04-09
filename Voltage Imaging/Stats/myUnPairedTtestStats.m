function t2 = myUnPairedTtestStats(data_all,cell_types)

data_all = reshape(data_all,1,[]); % row vector

[~,t2.p,~,stats] = ttest2(data_all{1,1}, data_all{1,2},'tail','both','Vartype','equal');
t2.tstat = stats.tstat;
t2.df = stats.df;

t2.results = cell2table([cell_types(1) cell_types(2) {t2.tstat} {t2.df} {t2.p}],"VariableNames",{'Group A','Group B','T','df','P-value'});

end