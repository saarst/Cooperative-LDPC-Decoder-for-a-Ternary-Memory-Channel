% Function to check job status
function isFinished = checkJobStatus(jobID)
    [status, cmdout] = system(sprintf('qstat -f %s', jobID));
    if status ~= 0
        % If qstat fails, assume job is finished
        isFinished = true;
        return;
    end

    % Check if the job state is completed or exited
    isFinished = contains(cmdout, 'job_state = C');
end
