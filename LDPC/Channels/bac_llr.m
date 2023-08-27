function f = bac_llr(p,q)
%BSC_LLR Summary of this function goes here
% p - probability of down 1 -> 0
% q - probability of up   0 -> 1
%   Detailed explanation goes here
    f = @(y) (y==1) * log2(p/(1-p))  +  (y==0) * log2((1-q)/q);
end

