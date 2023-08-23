% % Tests:
% log_p = {log10(0.001)}; % downward errors
% log_q = {log10(linspace(0.01,0.2,20))};
% sequences = {[4 2]};
% rates = {[0.75, 0.6]}; % first is ind, second is res
% T = combinations(log_p, log_q, sequences, rates);
% T = load("testPQ4.mat","T").T;

date = char(datetime('now','TimeZone','local','Format','ddMMHHmm'));
n = 1024;
log_p = log10(linspace(0.005,0.08,20));
numIter = ceil(10.^(-min(log_p)+2));
rate = 0.25;
rateStr = string(rate).replace(".","");
experimentName = sprintf("BSCLDPC_d%s_n%d_R%s",date, n, rateStr);
% d - date, I - num of Iterations
RunBSCPBS(experimentName, numIter, log_p, n, rate)
