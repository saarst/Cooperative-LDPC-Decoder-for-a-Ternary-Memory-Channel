function f = bsc_llr(p)
%BSC_LLR Summary of this function goes here
%   Detailed explanation goes here
    f = @(y) power(-1, y) * log2((1-p)/p);
end

