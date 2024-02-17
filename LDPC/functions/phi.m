function y = phi(x)
    y = -log(tanh(x/2));
    y(isinf(y)) = 1000;
end

