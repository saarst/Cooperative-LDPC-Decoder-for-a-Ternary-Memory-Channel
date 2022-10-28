H = [1, 1, 0; 0, 0, 0; 1, 1, 1];
vec = [NaN, NaN, 1];

H= zeros(5,5);
H(1,[1, 3 ,5]) = 1;
vec = zeros(1,5);
vec(1,[1, 3 , 4, 5]) = NaN;


LDPC_del_opt(H,vec);