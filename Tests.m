% Tests:
% ratios = "u" + ["100"];
% sequences = {[2 2], [4 2], [6 2]};
% rates = {[0.75, 0.5], [0.75, 0.1]}; % first is ind, second is res
% T = combinations(ratios, sequences, rates);
T = load("testArrayDebug.mat","T").T;
date = char(datetime('now','TimeZone','local','Format','ddMMHHmm'));

n = 128;
numIter = "24e3";
for i=1:height(T)
    ratio = T{i,1};
    sequence = T{i,2}{1};
    rate = T{i,3}{1};
    rateIndStr = string(rate(1)).replace(".","");
    rateResStr = string(rate(2)).replace(".","");
    experimentName = sprintf("TriLDPC_d%s_n%d_I%s_r%s_si%d_sr%d_Ri%s_Rr%s",date, n, numIter, ratio, sequence(1), sequence(2), rateIndStr, rateResStr);
    % d - date, I - num of Iterations, r - ratio, 
    % si - indicator part of sequence, sr - residual part of seuquence
    RunPBS(experimentName, -7:-4, sequence(1), sequence(2), ratio, n, rate(1), rate(2), str2double(numIter), 1000)
end
