date = char(datetime('now','TimeZone','local','Format','ddMMHHmm'));
n = 256;
log_p = log10(linspace(0.005,0.08,20));
% log_p = log10(0.005);

numIter = ceil(10.^(-min(log_p)+2));
rate = 0.5;
rateStr = string(rate).replace(".","");
experimentName = sprintf("BSCLDPC_d%s_n%d_R%s",date, n, rateStr);
% d - date, I - num of Iterations
RunBSCPBS(experimentName, numIter, log_p, n, rate)
