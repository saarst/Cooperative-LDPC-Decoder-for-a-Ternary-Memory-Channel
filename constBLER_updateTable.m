function T = constBLER_updateTable(T, targetValue, folderPath, savePath, format, mode)
%this function is for constBLER experiment only! so decoder is joint OR 2-step
    arguments
        T
        targetValue = 1E-4
        folderPath string = "./Results/TriLDPC_d02051011_n192_si6_sr2_Ri08_Rr05"
        savePath string = "./Figures/"
        format string = "fig"
        mode = "BLER"
    end

    addpath(genpath(folderPath));
    
    % Get a list of all files in the folder
    files = dir(fullfile(folderPath, '*.mat'));
    p = 10.^(load(folderPath + "/pq.mat").log_p);
    q = 10.^(load(folderPath + "/pq.mat").log_q);
    log_q = load(folderPath + "/pq.mat").log_q;
    if isempty(p) || isempty(q)
        return
    end
    
    % Initialize arrays to store (n, log_p) pairs
    empiricalBLER_Values = NaN(size(q));
    empiricalSER_Values = NaN(size(q));    

    % Variables to extract from the struct in the file
    vars = {"decoder", "BEP_MsgPas", "BEP_Naive", "p", "q","log_q", "statsGeneral", "stats2step", "statsJoint", "n","rate_ind_actual","rate_res_actual"};
    disp("loading from:" + folderPath);
    disp("loading " + numel(files) + " files" )

    % Iterate over each file in the folder
    for i = 1:numel(files)
        % Load the file and extract the struct
        if strcmp(files(i).name, 'pq.mat')
            continue
        end
        filePath = fullfile(folderPath, files(i).name);
        data = load(filePath,vars{:});
        
        % Extract the log_p and BEP values from the struct
        [~,c] = min(abs(p - data.p));
        [~,r] = min(abs(log_q(:,c) - data.log_q));
        if strcmp(data.decoder, "2step")
            empiricalBLER_Values(r,c) = data.BEP_Naive;
            empiricalSER_Values(r,c) = mean([data.stats2step.SER_Naive]);
        elseif any(strcmp(data.decoder, ["joint","joint-LC"]))
            empiricalBLER_Values(r,c) = data.BEP_MsgPas;
            empiricalSER_Values(r,c) = mean([data.statsJoint.SER_MsgPas]);
        else
            error("unsupported decoder");
        end

    end
    
    nearest_q = NaN(length(p),1);
    % q_MsgPas_interp = NaN(size(p));
    nearest_BLER_lims = NaN(length(p),2);
    nearest_q_lims = NaN(length(p),2);
    [~, loc] = ismember(p, T.p);  % keep an eye on this, can really go wtrong
    for k = 1:length(p)
        % curr_p = p(k);
        curr_q_vec = q(:,k);
        if strcmp(mode,"BLER")
            empiricalValues = empiricalBLER_Values(:,k);
        elseif strcmp(mode,"SER")
            empiricalValues = empiricalSER_Values(:,k);
        end

        if abs(curr_q_vec(1) - T.q_l(loc(k))) > eps && abs(curr_q_vec(end) - T.q_h(loc(k))) > eps
            if loc(k) > 0
                curr_q_vec = [T.q_l(loc(k)); curr_q_vec; T.q_h(loc(k))];
                empiricalValues = [T.BLER_at_q_l(loc(k)); empiricalValues; T.BLER_at_q_h(loc(k))];
            else
                error("bad distuation")
            end
        end

        % to avoid weird things, make sure empiricalValues is monotonic
        % series, this is just for the iteratoins, and is turned off before
        % final iteration to get real results.
        figure;
        plot(log10(curr_q_vec), log10(empiricalValues),"-o");
        yline(-4);
        % for l = 1:length(empiricalValues)-1
        %     if (empiricalValues(l) > empiricalValues(l+1))
        %         empiricalValues(l) = empiricalValues(l+1);
        %     end
        % end
        
        errors = abs(empiricalValues - targetValue);
        if all(errors < 1E-6)
            nearest_q_lims(k,1) = mean(curr_q_vec);
            nearest_q_lims(k,2) = mean(curr_q_vec);
            nearest_BLER_lims(k,1) = targetValue;
            nearest_BLER_lims(k,2) = targetValue;
            T.forRun(k) = false;
        end
        [error, Target_nearestIdx] = min(errors);
        nearest_Target = empiricalValues(Target_nearestIdx);
        nearest_q(k) = curr_q_vec(Target_nearestIdx);
            if (( nearest_Target == min(empiricalValues) ) && nearest_Target > targetValue )
                if error < 1E-5
                    nearest_q_lims(k,1) = 10^(log10(nearest_q(k)) - 0.001);
                else
                    nearest_q_lims(k,1) = nearest_q(k) / 10;
                end
                nearest_q_lims(k,2) = nearest_q(k);
                nearest_BLER_lims(k,1) = NaN;
                nearest_BLER_lims(k,2) = nearest_Target;
            elseif ( ( nearest_Target == max(empiricalValues)) && nearest_Target < targetValue )
                nearest_q_lims(k,1) = nearest_q(k);
                if error < 1E-5
                    nearest_q_lims(k,2) = 10^(log10(nearest_q(k)) + 0.01);
                else
                    nearest_q_lims(k,2) = nearest_q(k) * 10;
                end
                nearest_BLER_lims(k,1) = nearest_Target;
                nearest_BLER_lims(k,2) = NaN;
            elseif (nearest_Target <= targetValue)
                nearest_q_lims(k,1) = nearest_q(k);
                nearest_q_lims(k,2) = curr_q_vec(Target_nearestIdx + 1);
                nearest_BLER_lims(k,1) = nearest_Target;
                nearest_BLER_lims(k,2) = empiricalValues(Target_nearestIdx + 1);
            elseif (nearest_Target > targetValue)
                nearest_q_lims(k,1) = curr_q_vec(Target_nearestIdx - 1);
                nearest_q_lims(k,2) = nearest_q(k);
                nearest_BLER_lims(k,1) = empiricalValues(Target_nearestIdx - 1);
                nearest_BLER_lims(k,2) = empiricalValues(Target_nearestIdx);
            end

    end
    
    % sorting for graph ?
    % [p, I] = sort(p);
    % q_MsgPas = q_MsgPas(I);
    % q_Naive = q_Naive(I);
    % q_MsgPas_lims = q_MsgPas_lims(I,:);
    % q_Naive_lims = q_Naive_lims(I,:);
    % q_MsgPas_interp = q_MsgPas_interp(I);

    % update the table
    
    % Filter out the non-zero locations (valid keys found in the table)
    valid_locs = loc(loc > 0);
    assert(length(valid_locs) == length(p), "something is missing")
    nearest_BLER_lims = nearest_BLER_lims(loc > 0,:);
    nearest_q_lims = nearest_q_lims(loc > 0,:);

    T.BLER_at_q_l(valid_locs) = nearest_BLER_lims(:,1);
    T.BLER_at_q_h(valid_locs) = nearest_BLER_lims(:,2);
    T.q_l(valid_locs) = nearest_q_lims(:,1);
    T.q_h(valid_locs) = nearest_q_lims(:,2);

end