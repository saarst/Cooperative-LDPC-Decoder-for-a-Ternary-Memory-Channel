function RunPBS(experimentName, logps, sequence, n, R, numIter, batchSize)
    arguments
        experimentName = "TriLDPC"  % Default experiment name
        logps = -5:-3  % Default range of log_p values
        sequence = [20, 20]  % Default sequence array
        n = 256  % Default value for n
        R = 0.5  % Default value for R
        numIter = 10.^(-logps + 2)  % Default numIter values based on logps
        batchSize = 50  % Default value for batchSize
    end
    
    for log_p = logps
        % Format and execute the qsub command with all the parameters
        system(sprintf("qsub -V -v log_p=%g,experimentName='%s',sequence=[%s],n=%d,R=%g,numIter=%g,batchSize=%d ./PBS_main.sh", log_p, experimentName, strjoin(string(sequence), ','), n, R, numIter(log_p - logps(1) + 1), batchSize));
    end

end