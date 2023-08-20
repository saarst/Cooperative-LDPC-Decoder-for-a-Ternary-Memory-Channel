% % Tests:
% log_p = {log10(0.001)}; % downward errors
% log_q = {log10(linspace(0.01,0.2,20))};
% sequences = {[4 2]};
% rates = {[0.75, 0.6]}; % first is ind, second is res
% T = combinations(log_p, log_q, sequences, rates);
% T = load("testPQ4.mat","T").T;

date = char(datetime('now','TimeZone','local','Format','ddMMHHmm'));
n = 128;
log_p = log10(0.0001);
log_q = log10(linspace(0.001,0.05,25));
log_pq = [repmat(log_p,size(log_q(:))), log_q(:)].';
numIter = ceil(10.^(-min(log_pq)+2));
sequence = [4, 2];
rates = [0.75, 0.6];
rateIndStr = string(rates(1)).replace(".","");
rateResStr = string(rates(2)).replace(".","");
experimentName = sprintf("TriLDPC_d%s_n%d_si%d_sr%d_Ri%s_Rr%s",date, n, sequence(1), sequence(2), rateIndStr, rateResStr);
% d - date, I - num of Iterations, r - ratio, 
% si - indicator part of sequence, sr - residual part of seuquence
RunPBS(experimentName, numIter, log_p, log_q, sequence(1), sequence(2), n, rates(1), rates(2))
