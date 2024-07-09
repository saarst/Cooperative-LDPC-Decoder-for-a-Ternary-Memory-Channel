sequenceCell = { [6,2]};
ratesCell = {[0.8, 0.5]};

for ii = 1:length(sequenceCell)
    for jj = 1:length(ratesCell)
date = char(datetime('now','TimeZone','local','Format','ddMMHHmm'));
n = 192;
p = [logspace(log10(1e-5),log10(1e-4),10)];
q = [logspace(log10(1e-5),log10(10^(-3)),10)];
log_p = log10(p);
log_q = log10(q);
[P,Q] = meshgrid(p, q);
logPr_err = log10(1 - (1-P).* (1-Q));
[logP,logQ] = meshgrid(log_p, log_q);

numIter = max(min(ceil(10.^(-max(logQ,logP)+3)),1e8),1e3);
% numIter = max(min(ceil(10.^(-logPr_err+2)),1e8),1e3);
sequence = sequenceCell{ii};
rates = ratesCell{jj};
rateIndStr = string(rates(1)).replace(".","");
rateResStr = string(rates(2)).replace(".","");
experimentName = sprintf("TriLDPC_d%s_n%d_si%d_sr%d_Ri%s_Rr%s",date, n, sequence(1), sequence(2), rateIndStr, rateResStr);
ResultsFolder = './Results/'  + experimentName;
decoder = 'both';
loadWords = 1; % it means do not generate words, just load them.
if ~isfolder(fullfile(".","Results"))
    mkdir(fullfile(".","Results"));
end
if ~isfolder(ResultsFolder)
    mkdir(ResultsFolder);
end
save(ResultsFolder + "/pq.mat","log_p","log_q");
% d - date, I - num of Iterations, r - ratio, 
% si - indicator part of sequence, sr - residual part of seuquence
RunPBS(experimentName, decoder, loadWords, numIter, log_p, log_q, sequence(1), sequence(2), n, rates(1), rates(2))
    end
end