% % Tests:
% ratios = "u" + ["10"];
% sequences = {[4 2]};
% rates = {[0.5, 0.4]}; % first is ind, second is res
% T = combinations(ratios, sequences, rates);
T = load("testWaterfall.mat","T").T;
date = char(datetime('now','TimeZone','local','Format','ddMMHHmm'));

n = 128;
numIter = "48e3";
for i=1:height(T)
    ratio = T{i,1};
    sequence = T{i,2}{1};
    rate = T{i,3}{1};
    rateIndStr = string(rate(1)).replace(".","");
    rateResStr = string(rate(2)).replace(".","");
    experimentName = sprintf("TriLDPC_d%s_n%d_I%s_r%s_si%d_sr%d_Ri%s_Rr%s",date, n, numIter, ratio, sequence(1), sequence(2), rateIndStr, rateResStr);
    % d - date, I - num of Iterations, r - ratio, 
    % si - indicator part of sequence, sr - residual part of seuquence
    % RunPBS(experimentName, -3:0.1:0.1, sequence(1), sequence(2), ratio, n, rate(1), rate(2), str2double(numIter))
    RunPBS(experimentName, -3, sequence(1), sequence(2), ratio, n, rate(1), rate(2), str2double(numIter))

end
