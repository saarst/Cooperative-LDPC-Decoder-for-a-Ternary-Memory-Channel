function [decCodewordRM_Naive, success, indIter, resIter] = NaiveDecoder(ChannelOut, NaiveIndDec, H_sys_res, originalInd)
    SER_flag = 1; % we calculate the SER
    decCodewordRM_Naive = [];
    resIter = 0;
    success = false;
    %% 1. build r_ind
    r_ind = ChannelOut > 0;
    %% 2. decode c_ind from r_ind
    [c_ind_estimate, ~, ind_success, indIter] = NaiveIndDec.decode(r_ind);
    if ~SER_flag && (~ind_success || ~isequal(c_ind_estimate(:), originalInd(:)))
        return
    end

    %% 3. build r_res
    r_res_tmp = ChannelOut;
    r_res_tmp(c_ind_estimate & ChannelOut==0) = NaN; % putting ? in down errors
    r_res_tmp(c_ind_estimate==0) = 0; % removing UP errors
    r_res = r_res_tmp - c_ind_estimate;

    %% 4. decode c_res from r_res
    [res_success, c_res_estimate, resIter] = LDPC_del_iterative(H_sys_res, r_res);
    if ~SER_flag && ~res_success
        decCodewordRM_Naive = c_ind_estimate;
        return
    end

    %% 5. build decCodewordRM_Naive
    decCodewordRM_Naive = c_res_estimate + c_ind_estimate;
    success = true;
end

