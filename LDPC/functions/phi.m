function y = phi(x)
    y = -log(tanh(x/2));
    if y == inf
        % warning("phi output is inf, changing to 10e9");
        y= 10e9;
    end
end

