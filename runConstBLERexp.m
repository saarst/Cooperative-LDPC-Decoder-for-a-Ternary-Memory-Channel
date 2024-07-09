function runConstBLERexp(BLER, n, rates, sequence, num_iters, starting_iter, just_plot)
arguments
    BLER = "1E-4"
    n = 192
    rates = [0.8, 0.5]
    sequence = [6,2]
    num_iters = 1
    starting_iter = 0 %in case of already existings file, 0 = last previous iter
    just_plot = 0
end

    % more params
    num_exp_in_interval = 3;
    include_interval_bounds = true;
    
    % 1. Initialize\load data structure:
    rateIndStr = string(rates(1)).replace(".","");
    rateResStr = string(rates(2)).replace(".","");
    file_name = sprintf("targetBLER_n%d_Ri%s_Rr%s.mat", n, rateIndStr, rateResStr);
    if isfile(file_name)
        load(file_name,"metadata","targetBLER_Dict");
        assert(all(metadata.sequence == sequence),"We do not support yet different sequences in this exp...");
    else
        targetBLER_Dict = dictionary;
        TableArray = TargetBLER_DS_creation();
        targetBLER_Dict{BLER} = TableArray;
        metadata.n = n;
        metadata.sequence = sequence;
        metadata.rates = rates;
        save(file_name,"targetBLER_Dict","metadata");
    end
    
    if ~isKey(targetBLER_Dict,BLER)
        targetBLER_Dict{BLER} = TargetBLER_DS_creation();
    end

        TableArray = targetBLER_Dict{BLER};
        decoders = ["joint", "prior"];
if starting_iter==0        
    starting_iter = length(TableArray);
end


% option: just graph
if just_plot
    TargetBLER_graph(TableArray(starting_iter),metadata, str2double(BLER),"linear");
    return
end

% 2. Iterations:
for iter = starting_iter:(starting_iter +  num_iters)
    assert(iter <= length(TableArray));
    currTable = TableArray(iter);
    savefile = "lastState" + num2str(iter) + ".mat";

    % sending jobs 
    for decoderIdx = 1:2
        decoder = decoders(decoderIdx);
        [jobIDs{decoderIdx}, ResultsFolder{decoderIdx}] = constBLER_submitJobs(currTable.(decoder), metadata, BLER, iter, decoder, num_exp_in_interval, include_interval_bounds); % submitting the jobs

    end
    % save jobIds and ResultsFolder for continuation if something crashed
    save(savefile, "jobIDs", "ResultsFolder");
    return

    %
    % pause(60); wait
    load(savefile,"jobIDs","ResultsFolder");    
    % if something got wrong run:
    % deleteJobs(jobIDs{1})
    % deleteJobs(jobIDs{2})
    % for decoderIdx = 1:2
    %     periodicCheck(jobIDs{decoderIdx}); % wait for them
    % end

    tempT = struct;
    for decoderIdx = 1:2
        decoder = decoders(decoderIdx);
        tempT.(decoder) = constBLER_updateTable(currTable.(decoder) , str2double(BLER), ResultsFolder{decoderIdx});
        %assure q_l and q_h are monotonic
        % for k=1:height(tempT.(decoder))-1
        %     if tempT.(decoder).q_l(k) > tempT.(decoder).q_l(k+1)
        %         tempT.(decoder).q_l(k+1) = tempT.(decoder).q_l(k);
        %         tempT.(decoder).BLER_at_q_l(k+1) = NaN;
        %     end
        % 
        %     if tempT.(decoder).q_h(k) > tempT.(decoder).q_h(k+1)
        %         tempT.(decoder).q_h(k+1) = tempT.(decoder).q_h(k);
        %         tempT.(decoder).BLER_at_q_h(k+1) = NaN;
        %     end
        % 
        % end
    end

    % save the new Table
    
    TableArray(iter+1) = tempT;
    targetBLER_Dict{BLER} = TableArray;
    save(file_name,"targetBLER_Dict","metadata");
    % optionally make a graph of the iteration
    return

    

end


end