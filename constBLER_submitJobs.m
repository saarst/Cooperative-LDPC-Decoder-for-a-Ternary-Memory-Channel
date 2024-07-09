function [jobIDs, ResultsFolder] = constBLER_submitJobs(T, metadata, BLER, iter, decoder, num_exp_in_interval, include_interval_bounds)

    % tweak
    if ~include_interval_bounds
        num_exp_in_interval = num_exp_in_interval + 2;
    end
    
    % load info
    n = metadata.n;
    sequence = metadata.sequence;
    rates = metadata.rates;

    
    date = char(datetime('now','TimeZone','local','Format','ddMMHHmm'));
    p = T{logical(T.forRun),"p"}';
    q = NaN(num_exp_in_interval,length(p));
    q_lims = T{logical(T.forRun),["q_l","q_h"]};
    
    for kk=1:length(p)
        q(:,kk) = logspace(log10(q_lims(kk,1)),log10(q_lims(kk,2)),num_exp_in_interval);
    end
    if ~include_interval_bounds
        q = q(2:end-1,:);
    end
    log_p = log10(p);
    log_q = log10(q);
    
    numIter1 = max(min(ceil(10.^(-log_q+5)),1e11),1e3);
    numIter2 = repmat(max(min(ceil(10.^(-log_p+5)),1e9),1e11),height(q),1);
    numIter = max(numIter1,numIter2);
    rateIndStr = string(rates(1)).replace(".","");
    rateResStr = string(rates(2)).replace(".","");
    experimentName = sprintf("BLERexp_%s_n%d_Ri%s_Rr%s/dec_%s_iter%d_d%s/",BLER, n, rateIndStr, rateResStr, decoder, iter,date);
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
    if strcmp(decoder, "prior")
        decoder = "2step"; % to match with past functions..
    end
    jobIDs = RunPBS(experimentName, decoder, loadWords, numIter, log_p, log_q, sequence(1), sequence(2), n, rates(1), rates(2));

end
