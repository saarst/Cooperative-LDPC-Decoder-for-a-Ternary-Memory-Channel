sequenceCell = { [2,2]};
ratesCell = {[0.85, 0.5]};

for ii = 1:length(sequenceCell)
    for jj = 1:length(ratesCell)
date = char(datetime('now','TimeZone','local','Format','ddMMHHmm'));
n = 256;
p = 1e-3;
q = logspace(log10(0.001),log10(0.5),1); % changed 2 to 25
log_p = log10(p);
log_q = log10(q);
[P,Q] = meshgrid(log_p, log_q);
numIter = 100e3;
sequence = sequenceCell{ii};
rates = ratesCell{jj};
rateIndStr = string(rates(1)).replace(".","");
rateResStr = string(rates(2)).replace(".","");
experimentName = sprintf("TriLDPC_d%s_n%d_si%d_sr%d_Ri%s_Rr%s",date, n, sequence(1), sequence(2), rateIndStr, rateResStr);
ResultsFolder = './Results/'  + experimentName;
decoder = 'generateWords';
loadWords = 0; % it means do not generate words, just load them.
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