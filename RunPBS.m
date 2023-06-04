function RunPBS(experimentName, logps, sequenceInd, sequenceRes, n, R, numIter, batchSize)
    arguments
        experimentName = "TriLDPC"  % Default experiment name
        logps = -5:-3  % Default range of log_p values
        sequenceInd = 2  % Default sequence array
        sequenceRes = 2
        n = 256  % Default value for n
        R = 0.5  % Default value for R
        numIter = 10.^(-logps + 2)  % Default numIter values based on logps
        batchSize = 50  % Default value for batchSize
    end
    
    for i = 1:length(logps)
        log_p = logps(i);
        if length(numIter) > 1
            numIterCurr = numIter(i);
        else
            numIterCurr = numIter;
        end
        % Format and execute the qsub command with all the parameters
        system(sprintf("qsub -v log_p=%g,experimentName='%s',sequenceInd=%d, sequenceRes=%d,n=%d,R=%g,numIter=%g,batchSize=%d ./PBS_main.sh", log_p, experimentName, sequenceInd,sequenceRes, n, R, numIterCurr, batchSize));
    end

end


