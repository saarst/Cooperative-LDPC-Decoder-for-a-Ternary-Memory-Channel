function RunPBS(experimentName, num_iter_sim, logps, logqs, sequenceInd, sequenceRes, n, Rate_ind, Rate_res)
    arguments
        experimentName (1,1) string  = "TriLDPC_"  % Default experiment name
        num_iter_sim (:,:) {mustBeInteger, mustBePositive} = 24e3;
        logps = -5:-3  % Default range of log_p values
        logqs = -5:-3  % Default range of log_q2 values
        sequenceInd = 2  % Default sequence array
        sequenceRes = 2
        n = 256  % Default value for n
        Rate_ind = 0.5  % Default value for Rate_ind
        Rate_res = 0.5  % Default value for Rate_res
    end
    pattern = '^[A-Za-z0-9_]+$';
    assert(~isempty(regexp(experimentName, pattern, 'once')),"experimentName: " + experimentName + " is not valid")
    
    logsDir = fullfile(".","logs",experimentName);
    if ~isfolder(logsDir)
        mkdir(logsDir);
    end

    for ii = 1:length(logps)
        log_p = logps(ii);
        for jj = 1:length(logqs)
            log_q = logqs(jj);

            if any(size(num_iter_sim) > 1)
                numIterCurr = num_iter_sim(ii,jj);
            else
                numIterCurr = num_iter_sim;
            end
            % Format and execute the qsub command with all the parameters
            errorFile = fullfile(logsDir,"e_logp" + log_p + "_logq" + log_q + ".txt");
            outputeFile = fullfile(logsDir,"o_logp" + log_p + "logq" + log_q + ".txt");
            cmdString = "qsub -N %s -o %s -e %s -v log_p=%g,log_q=%g,experimentName=%s,sequenceInd=%s,sequenceRes=%s,n=%s,RateInd=%g,RateRes=%g,numIter=%g ./PBS_main.sh";
            cmdVars = [experimentName, outputeFile, errorFile, log_p, log_q, experimentName, sequenceInd, sequenceRes, n, Rate_ind, Rate_res, numIterCurr];
            system(sprintf(cmdString, cmdVars));
            fprintf("%s has started with log_p = %g log_q = %g\n", experimentName, log_p, log_q);
        end
    end

end


