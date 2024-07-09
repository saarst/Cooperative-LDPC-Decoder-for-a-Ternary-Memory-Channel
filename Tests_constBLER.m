sequenceCell = { [6,2]};
ratesCell = {[0.8, 0.5]};

for ii = 1:length(sequenceCell)
    for jj = 1:length(ratesCell)
date = char(datetime('now','TimeZone','local','Format','ddMMHHmm'));
n = 192;
num_exp = 4;
decoder = 'joint';
load targetBLER_joint_1E-4.mat
p = p(1:3);
q = NaN(num_exp,length(p));
if strcmp(decoder,'joint')
    q_lims = q_MsgPas_lims;
else
    q_lims = q_Naive_lims;
end
for kk=1:length(p)
    q(:,kk) = logspace(log10(q_lims(kk,1)),log10(q_lims(kk,2)),num_exp);
end
log_p = log10(p);
log_q = log10(q);

numIter1 = max(min(ceil(10.^(-log_q+3)),1e8),1e3);
numIter2 = repmat(max(min(ceil(10.^(-log_p+3)),1e8),1e3),num_exp,1);
numIter = max(numIter1,numIter2);
sequence = sequenceCell{ii};
rates = ratesCell{jj};
rateIndStr = string(rates(1)).replace(".","");
rateResStr = string(rates(2)).replace(".","");
experimentName = sprintf("TriLDPC_d%s_n%d_si%d_sr%d_Ri%s_Rr%s",date, n, sequence(1), sequence(2), rateIndStr, rateResStr);
ResultsFolder = './Results/'  + experimentName;

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