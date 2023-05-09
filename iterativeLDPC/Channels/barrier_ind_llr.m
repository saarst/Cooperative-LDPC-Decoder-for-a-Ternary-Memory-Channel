function f = barrier_ind_llr(p,q)
%BSC_LLR Summary of this function goes here
%   Detailed explanation goes here
    f = @(y) ind_channel(y,p,q);
end

function llr = ind_channel(y,p,q)
    if y==0
        llr = log2((1-q)/p);
    elseif y==1 || y==2
        llr = log2(q/(1-p));
    end
end
