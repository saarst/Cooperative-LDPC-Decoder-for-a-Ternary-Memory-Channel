% Function to periodic check on jobIDs
function totalWaitTime = periodicCheck(jobIDs)
    jobIDs = jobIDs(:);
    totalWaitTime = 0; % Initialize total wait time
    
    % Iterate over each job ID
    for i = 1:length(jobIDs)
        jobID = jobIDs{i};
        startTime = tic; % Start timer
        lastHalfHour = 0; % Initialize last half hour
        
        % Periodically check if the job is finished
        while true
            elapsedTime = toc(startTime); % Calculate elapsed time
            totalHalfHours = floor(elapsedTime / 1800); % Calculate total half hours
            currentHalfHour = mod(totalHalfHours, 48); % Calculate current half hour
            
            if currentHalfHour > lastHalfHour
                fprintf('Job %s is still running. Total elapsed time: %.2f hours.\n', jobID, elapsedTime/3600);
                lastHalfHour = currentHalfHour; % Update last half hour
            end
            if checkJobStatus(jobID)
                fprintf('Job %s has finished.\n', jobID);
                break;
            end          
            pause(60); % Wait for 60 seconds before checking again

        end

        % Add the elapsed time for this job to total wait time
        totalWaitTime = totalWaitTime + elapsedTime;
        
        fprintf('Job %s is complete. Total elapsed time: %.2f hours.\n', jobID, elapsedTime/3600);
    end
    
    fprintf('Total time waited for all jobs: %.2f hours.\n', totalWaitTime/3600);
end