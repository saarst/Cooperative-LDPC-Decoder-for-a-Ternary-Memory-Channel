function RunPBS(experimentName, logps, sequenceInd, sequenceRes, ratio, n, R, numIter, batchSize)
    arguments
        experimentName (1,1) string  = "TriLDPC_"  % Default experiment name
        logps = -5:-3  % Default range of log_p values
        sequenceInd = 2  % Default sequence array
        sequenceRes = 2
        ratio {mustBePositive} = 2;
        n = 256  % Default value for n
        R = 0.5  % Default value for R
        numIter = 10000  % Default numIter values based on logps
        batchSize = 500  % Default value for batchSize
    end
    pattern = '^[A-Za-z0-9_]+$';
    if isempty(regexp(experimentName, pattern, 'once'))
        disp('String is not valid');
    end

    if ~isfolder(fullfile(".","logs",experimentName))
        mkdir(ResultsFolder);
    end

    for i = 1:length(logps)
        log_p = logps(i);
        if length(numIter) > 1
            numIterCurr = numIter(i);
        else
            numIterCurr = numIter;
        end
        % Format and execute the qsub command with all the parameters
        system(sprintf("qsub -N %s -v log_p=%g,experimentName=%s,sequenceInd=%d,sequenceRes=%d,ratio=%g,n=%d,R=%g,numIter=%g,batchSize=%d ./PBS_main.sh", experimentName, log_p, experimentName, sequenceInd,sequenceRes, ratio, n, R, numIterCurr, batchSize));
    end

end


