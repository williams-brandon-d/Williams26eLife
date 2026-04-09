function stats = myMultipleIndependentCircStats(allData,rowLabels,colLabels,scale,saveFilename,savenum)
% compare between independent groups (rowLabels)

nRows = numel(rowLabels);

stats.summary = mySummaryTableCirc(allData,rowLabels); % calculate mean, SEM and N 

stats.data_table = myDataTable(allData,rowLabels);

% test if data is from von mises distribution?
stats.kp = myKPstats(allData,rowLabels,colLabels); % Computes Rayleigh test for non-uniformity of circular data.
% kuiper test is the circular analogue to the ks test - tests for differences between two distributions
% need relatively large sample size to be powerful - n>= 30, test is highly sensitive for n >= 100

% test to see if data distribution is phase locked
stats.ray = myRayleighstats(allData,rowLabels,colLabels); % Computes Rayleigh test for non-uniformity of circular data.
% assumes unimodal and von-mises distribution

% alternative
stats.ot = myOTeststats(allData,rowLabels,colLabels); % Computes Rayleigh test for non-uniformity of circular data.
%   Computes Omnibus or Hodges-Ajne test for non-uniformity of circular data.
%   Alternative to the Rayleigh and Rao's test. Works well for unimodal,
%   bimodal or multimodal data. If requirements of the Rayleigh test are 
%   met, the latter is more powerful.

% circ_ktest for equal concentrations? - tests between two samples only - assumes von-mises distribution
stats.kt = myKtest(allData,rowLabels);

[nRows,nCols] = size(allData);
if (nRows == 1) || (nCols == 1)
    nRows = max(nRows,nCols);
end

if nRows > 2
    stats.ww = myWWstats(allData,rowLabels);
    stats.cm = myCMstats(allData,rowLabels);
% elseif nRows == 2 % only 2 groups 
%     stats.t2 = myUnPairedTtestStats(allData,rowLabels); % 
%     stats.rs = myUnPairedRankSumStats(allData,rowLabels); % 
end

if savenum
    writetable(stats.data_table,saveFilename,'Sheet','Data','WriteMode','overwritesheet');  % save data table
    writetable(stats.summary,saveFilename,'Sheet','Summary','WriteMode','overwritesheet','WriteRowNames',true);  % save summary stats table
    writetable(stats.kp.results,saveFilename,'Sheet','Kuiper test','WriteMode','overwritesheet');  % save sw stats table
    writetable(stats.ray.results,saveFilename,'Sheet','Rayleigh','WriteMode','overwritesheet');  % save sw stats table
    writetable(stats.ot.results,saveFilename,'Sheet','O-test','WriteMode','overwritesheet');  % save sw stats table
    writetable(stats.kt.results,saveFilename,'Sheet','K-test','WriteMode','overwritesheet');  % save levene stats table
    if nRows > 2
        writetable(stats.ww.results,saveFilename,'Sheet','WW-Bonferroni','WriteMode','overwritesheet');  % save anova stats table
        writetable(stats.ww.tbl,saveFilename,'Sheet','ANOVA-WW','WriteMode','overwritesheet');  % save anova stats table
        writetable(stats.cm.results,saveFilename,'Sheet','Non-parametric-Bonferroni','WriteMode','overwritesheet');  % save kruskal-wallis stats table
        writetable(stats.cm.tbl,saveFilename,'Sheet','Non-parametic-CM','WriteMode','overwritesheet');  % save kruskal-wallis stats table
%     elseif nRows == 2
%         writetable(stats.t2.results,saveFilename,'Sheet','Independent T-test','WriteMode','overwritesheet');  % save independent t-test stats table
%         writetable(stats.rs.results,saveFilename,'Sheet','Rank Sum test','WriteMode','overwritesheet');  % save rank sum test stats table
    end
end


end