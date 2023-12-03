sequenceCell = { [1,1]};
ratesCell = {[0.5, 0.3]};

for ii = 1:length(sequenceCell)
    for jj = 1:length(ratesCell)
date = char(datetime('now','TimeZone','local','Format','ddMMHHmm'));
n = 128;
p = 0.001;
q = logspace(log10(0.001),log10(0.5),25);
log_p = log10(p);
log_q = log10(q);
[P,Q] = meshgrid(log_p, log_q);
numIter = ceil(10.^(-min(P,Q)+2)) + 10e3;
sequence = sequenceCell{ii};
rates = ratesCell{jj};
rateIndStr = string(rates(1)).replace(".","");
rateResStr = string(rates(2)).replace(".","");
experimentName = sprintf("TriLDPC_d%s_n%d_si%d_sr%d_Ri%s_Rr%s",date, n, sequence(1), sequence(2), rateIndStr, rateResStr);
ResultsFolder = './Results/'  + experimentName;
if ~isfolder(fullfile(".","Results"))
    mkdir(fullfile(".","Results"));
end
if ~isfolder(ResultsFolder)
    mkdir(ResultsFolder);
end
save(ResultsFolder + "/pq.mat","log_p","log_q");
% d - date, I - num of Iterations, r - ratio, 
% si - indicator part of sequence, sr - residual part of seuquence
RunPBS(experimentName, numIter, log_p, log_q, sequence(1), sequence(2), n, rates(1), rates(2))
    end
end