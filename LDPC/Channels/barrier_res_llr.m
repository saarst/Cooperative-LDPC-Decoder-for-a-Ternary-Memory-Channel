function f = barrier_res_llr(p,q)
    %BSC_LLR Summary of this function goes here
    %   Detailed explanation goes here
        f = @(y) res_channel(y,p,q);
    end
    
    function llr = res_channel(y,p,q)
        if y==0
            llr = log2(p / (2*(1-q)));
        elseif y==1 
            llr = log2((1-p)/q);
        elseif y==2
            llr = -1e9;
        end
    end
    