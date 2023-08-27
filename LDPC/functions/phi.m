function y = phi(x)
    if x <= eps
        y = 40;
        return
    end 
    y = -log2(tanh(x/2));
end

