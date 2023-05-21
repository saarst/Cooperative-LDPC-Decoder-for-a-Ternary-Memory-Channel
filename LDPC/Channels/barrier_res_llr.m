function f = barrier_res_llr(p,q)
    %BSC_LLR Summary of this function goes here
    %   Detailed explanation goes here
        f = @(y) res_channel(y,p,q);
    end
    
    function llr = res_channel(y,p,q)
        if y==0
            llr = log2(1+2*(1-q)/p);
        elseif y==1 
            llr = 2e31;
        elseif y==2
            llr = log2(q/(1-p));
        end
    end
    