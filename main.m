H = ([[1, 1, 1, 1, 0, 0, 0, 0, 0, 0],
              [1, 0, 0, 0, 1, 1, 1, 0, 0, 0],
              [0, 1, 0, 0, 1, 0, 0, 1, 1, 0],
              [0, 0, 1, 0, 0, 1, 0, 1, 0, 1],
              [0, 0, 0, 1, 0, 0, 1, 0, 1, 1]]);

model = bsc_llr(0.1);
tg = from_biadjacency_matrix(H, model);
orig_c = [1, 1, 0, 0, 1, 0, 0, 0, 0, 0];
c =([1, 1, 0, 0, 1, 0, 0, 0, 0, 1]);
bp = BeliefPropagation(tg, H, 10);
[estimate, llr, decode_success] = bp.decode(c);

if decode_success && all((estimate == orig_c))
    disp("SUCCESS");
else
    disp("LOSER");
end
