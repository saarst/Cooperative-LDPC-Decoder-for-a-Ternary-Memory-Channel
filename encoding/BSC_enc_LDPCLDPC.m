function [c, message] = BSC_enc_LDPCLDPC(H)
% 
%TERNARY_ENC_LDPCLDPC Encodes a BSC codeword from an LDPC
% 
% Remark: This function can be used with arbitrary codes defined
% by their parity-check matrix.
% 
% Written by: Yuval Ben-Hur, 07/09/2022
% Last modified by: Saar Stern, 20/08/2023
% 
    
    n = size(H,2); % code length
    % - * - encoder - * -
    r = size(H,1);
    k = n-r;
    message = gf(randi([0,1],[1,k])); % random message
    % encode word
    [H_rref, parColsIdxs] = gfrref(H,1);
    parCols = false(1,n); parCols(parColsIdxs) = true; % parity columns
    H_sys = [H_rref(:,~parCols) H_rref(:,parCols)];
    G_sys = [gf(eye(k)) H_sys(:,1:k).'];
    c_perm = message * G_sys; % codeword (permuted)
    perm = [find(~parCols) find(parCols)]; % reverse column permutation
    % generate codeword
    c = gf(zeros(1,n));
    c(perm) = c_perm;

    c = double(c.x);
    message = double(message.x);
    
end

