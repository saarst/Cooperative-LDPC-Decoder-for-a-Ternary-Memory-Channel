function deleteJobs(jobIDs)
    jobIDs = jobIDs(:);
    for i = 1: length(jobIDs)
        jobID = jobIDs(i);
        system("qdel " + jobID);
    end
end