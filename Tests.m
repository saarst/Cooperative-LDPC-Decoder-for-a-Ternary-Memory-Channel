% Tests:

% ratios = "u" + ["1", "10", "100", "1000"];
% sequences = {[2 2], [4 2], [2 4]}; 
% sequences = {[ 2 2]}; 
% T = combinations(ratios, sequences);
T = load("testArray.mat","T").T;
date = string(datetime('now','TimeZone','local','Format','d_M'));
numIter = "12e3";
for i=1:height(T)
    ratio = T{i,1};
    sequence = T{i,2}{1};
    % experimentName = "d" + date + "_TriLDPC_12e3_r" + ratio + "_s" + sequence(1) + "_" + sequence(2);
    experimentName = sprintf("TriLDPC_d%s_n%s_r%s_si%d_sr%d",date, numIter, ratio, sequence(1), sequence(2));
    % d - date, I - num of Iterations, r - ratio, 
    % si - indicator part of sequence, sr - residual part of seuquence
    RunPBS(experimentName, -7:-4, sequence(1), sequence(2), ratio, 256, 0.5, str2double(numIter), 500)
end
