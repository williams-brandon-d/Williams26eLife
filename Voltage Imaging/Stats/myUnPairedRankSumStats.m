function rs = myUnPairedRankSumStats(data_all,cell_types)

data_all = reshape(data_all,1,[]); % row vector

[rs.p,~,stats] = ranksum(data_all{1,1},data_all{1,2},'method','exact','tail','both');
rs.w = stats.ranksum;

rs.results = cell2table([cell_types(1) cell_types(2) {rs.w} {rs.p}],"VariableNames",{'Group A','Group B','W','P-value'});

end