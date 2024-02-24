function f = barrier_ind_llr(p,q, symbolsPrior)
%BSC_LLR Summary of this function goes here
%   Detailed explanation goes here
    f = @(y) ind_channel(y,p,q, symbolsPrior);
end

function llr = ind_channel(y,p,q, symbolsPrior)
    P0 = symbolsPrior(1);
    P1 = symbolsPrior(2);
    P2 = symbolsPrior(3);
    if y == 0
        llr = log(  ( (1-q)*(P0)  ) / ( (p)*(P1+P2) ) );
    elseif y == 1 
        llr = log(  ( (q/2)*(P0)  ) / ( (1-p)*(P1) ) );
    elseif y == 2
        llr = log(  ( (q/2)*(P0)  ) / ( (1-p)*(P2) ) );
    end
end
