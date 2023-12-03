function RunBSCPBS(experimentName, num_iter_sim, logps, n, Rate)
    arguments
        experimentName (1,1) string  = "TriLDPC_"  % Default experiment name
        num_iter_sim (:,:) {mustBeInteger, mustBePositive} = 24e3;
        logps = -5:-3  % Default range of log_p values
        n = 256  % Default value for n
        Rate = 0.5  % Default value for Rate_ind
    end
    pattern = '^[A-Za-z0-9_]+$';
    assert(~isempty(regexp(experimentName, pattern, 'once')),"experimentName: " + experimentName + " is not valid")
    
    logsDir = fullfile(".","logs",experimentName);
    if ~isfolder(logsDir)
        mkdir(logsDir);
    end

    for ii = 1:length(logps)
        log_p = logps(ii);
        if any(size(num_iter_sim) > 1)
            numIterCurr = num_iter_sim(ii);
        else
            numIterCurr = num_iter_sim;
        end
        % Format and execute the qsub command with all the parameters
        errorFile = fullfile(logsDir,"e_logp" + log_p + ".txt");
        outputeFile = fullfile(logsDir,"o_logp" + log_p + ".txt");
        cmdString = "qsub -N %s -o %s -e %s -v log_p=%g,experimentName=%s,n=%s,Rate=%g,numIter=%g ./PBS_BSC.sh";
        cmdVars = [experimentName, outputeFile, errorFile, log_p, experimentName, n, Rate, numIterCurr];
        system(sprintf(cmdString, cmdVars));
        fprintf("%s has started with log_p = %g\n", experimentName, log_p);
    end

end


