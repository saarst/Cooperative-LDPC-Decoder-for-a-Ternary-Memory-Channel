function f = barrier_res_llr(p, q, symbolsPrior)
    %BSC_LLR Summary of this function goes here
    %   Detailed explanation goes here
        f = @(y) res_channel(y, p, q, symbolsPrior);
    end
    
function llr = res_channel(y, p, q, symbolsPrior)
    P0 = symbolsPrior(1);
    P1 = symbolsPrior(2);
    P2 = symbolsPrior(3);
    if y==0
        llr = log(  ( (1-q)*(P0) + (p)*(P1)  ) / ( (p)*(P2) ) );
    elseif y==1 
        llr = 2e16;
    elseif y==2
        llr = log(  ( (q/2)*(P0)  ) / ( (1-p)*(P2) ) );
    end
end
    