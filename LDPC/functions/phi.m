function y = phi(x)
    if x <= 2e3 * eps
        y = 30;
        return
    end 
    y = -log(tanh(x/2));
end

