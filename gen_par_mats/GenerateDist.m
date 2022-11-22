function [Lam,p] = GenerateDist(d,R)

    H = sum(1./(1:d));
    Lam = [0 1./(H.*(1:d))];
    al = H*(d+1)/d;
    beta = 1-R;
    ar = al/beta;
    alpha = linspace(0,d,d*1000);
    [minVal,minInd] = min(abs(ar-alpha.*exp(alpha)./(exp(alpha)-1)));
    if minVal>1e-3
        error('Unable to find alpha');
    end
    alpha = alpha(minInd);
    p = [0 (exp(-alpha)*alpha.^(1:5*d-1))./factorial(1:5*d-1)];
    [pm,pi] = max(p);
    tmp = p;
    tmp(1:pi) = pm;
    trunc = find(tmp<1e-3,1,'first');
    p = p(1:trunc-1);

end
