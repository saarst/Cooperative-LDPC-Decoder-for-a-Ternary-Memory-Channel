function [c,cInd,cRes,messageInd,messageRes] = ternary_enc_LDPCLDPC(indH,resH)
% function [CodewordComb,CodewordIndicator,CodewordResidual,messageIndicator,messageResidual] = ...
%     ternary_enc_RMLDPC(r,m,HeBCH,kRM)
% 
%TERNARY_ENC_LDPCLDPC Encodes a ternary combined codeword from an LDPC
%indicator code (defined by the parity-check matrix indH) and an LDPC
%residual code (defined by the parity-check matrix resH).
% 
% Remark: This function can be used with arbitrary codes defined
% by their parity-check matrix.
% 
% Written by: Yuval Ben-Hur, 07/09/2022
% Last modified by: Yuval Ben-Hur, 02/10/2022
% 
    
    if ~isequal(size(resH,2),size(indH,2)), error("Parity-check matrix mismatch."); end % check code lengths matches
    n = size(indH,2); % code length
        
    % - * - Indicator encoder - * -
    rInd = size(indH,1);
    kInd = n-rInd;
    messageInd = gf(randi([0,1],[1,kInd])); % random indicator message
    % encode indicator word
    [indH_rref, parColsIdxs] = gfrref(indH,1);
    parCols = false(1,n); parCols(parColsIdxs) = true; % parity columns
    indH_sys = [indH_rref(:,~parCols) indH_rref(:,parCols)];
    indG_sys = [gf(eye(kInd)) indH_sys(:,1:kInd).'];
    cInd_perm = messageInd * indG_sys; % indicator codeword (permuted)
    perm = [find(~parCols) find(parCols)]; % reverse column permutation
    % generate indicator codeword
    cInd = gf(zeros(1,n));
    cInd(perm) = cInd_perm; 
    
    % - * - Residual encoder - * -    
    % encode residual word, given indicator codeword
    if ~cInd.any % zero indicator word --> empty residual code
        messageRes = gf(0,1);
        cRes = gf(zeros(1,n),1);
    else
        nzH = resH(:,logical(cInd.x)); % columns corresponding to un-nulled locations
        n_res_short = size(nzH,2); % shortened residual code length
        k_res_short = n_res_short-gfrank(double(nzH.x),2); % shortened residual code dimension
        if k_res_short<=0 % residual code too short --> empty residual code
            messageRes = gf(0,1);
            cRes = gf(zeros(1,n),1);
        else
            [nzHrref,parColsIdxs] = gfrref(nzH,1);
            nzHrref = nzHrref(any(nzHrref,2),:);
            parCols = false(1,n_res_short); parCols(parColsIdxs) = true; % parity columns
            nzHsys = [nzHrref(:,~parCols) nzHrref(:,parCols)];
            nzGsys = [gf(eye(k_res_short)) nzHsys(:,1:k_res_short).'];
            % encode short permuted eBCH
            messageRes = gf(randi([0 1],[1 k_res_short]));
            cRes_short_perm = messageRes * nzGsys;
            % reverse column permutation
            cRes_short = gf(zeros(1,n_res_short),1);
            cRes_short(~parCols) = cRes_short_perm(1:n_res_short-sum(parCols));
            cRes_short(parCols) = cRes_short_perm(n_res_short-sum(parCols)+1:n_res_short);
            % generate eBCH codeword
            cRes = gf(zeros(1,n));
            cRes(logical(cInd.x)) = cRes_short;
        end
    end
    
    % combine binary codewords to ternary codeword
    cInd = double(cInd.x);
    cRes = double(cRes.x); 
    messageInd = double(messageInd.x);
    messageRes = double(messageRes.x);
    c = cInd + cRes;

end

