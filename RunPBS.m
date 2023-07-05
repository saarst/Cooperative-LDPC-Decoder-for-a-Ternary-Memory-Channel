function RunPBS(experimentName, logps, sequenceInd, sequenceRes, ratio, n, Rate_ind, Rate_res, numIter, batchSize)
    arguments
        experimentName (1,1) string  = "TriLDPC_"  % Default experiment name
        logps = -5:-3  % Default range of log_p values
        sequenceInd = 2  % Default sequence array
        sequenceRes = 2
        ratio (1,1) string = "u1";
        n = 256  % Default value for n
        Rate_ind = 0.5  % Default value for Rate_ind
        Rate_res = 0.5  % Default value for Rate_res
        numIter = 10000  % Default numIter values based on logps
        batchSize = 500  % Default value for batchSize
    end
    pattern = '^[A-Za-z0-9_]+$';
    assert(~isempty(regexp(experimentName, pattern, 'once')),"experimentName: " + experimentName + " is not valid")
    UpDown = ratio{1}(1);
    assert(any(strcmp(UpDown,["u", "d"])), "ratio needs to be either Up or Down");
    ratio = str2double(extractAfter(ratio,1));
    if strcmp(UpDown,"u")
        ratio = 1 / ratio;
    end


    logsDir = fullfile(".","logs",experimentName);
    if ~isfolder(logsDir)
        mkdir(logsDir);
    end

    for i = 1:length(logps)
        log_p = logps(i);
        if length(numIter) > 1
            numIterCurr = numIter(i);
        else
            numIterCurr = numIter;
        end
        % Format and execute the qsub command with all the parameters
        errorFile = fullfile(logsDir,"e_logp" + log_p + ".txt");
        outputeFile = fullfile(logsDir,"o_logp" + log_p + ".txt");
        system(sprintf("qsub -N %s -o %s -e %s -v log_p=%g,experimentName=%s,sequenceInd=%d,sequenceRes=%d,ratio=%g,n=%d,RateInd=%g,RateRes=%g,numIter=%g,batchSize=%d ./PBS_main.sh", experimentName, outputeFile, errorFile, log_p, experimentName, sequenceInd,sequenceRes, ratio, n, Rate_ind, Rate_res, numIterCurr, batchSize));
        fprintf("%s has started with log_p = %g\n", experimentName, log_p);
    end

end


