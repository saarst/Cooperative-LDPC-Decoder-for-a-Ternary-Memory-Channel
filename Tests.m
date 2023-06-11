% Tests:

% ratios = [2, 4, 8];
% sequences = {[ 2 2], [4 2], [2 4]}; 
% T = combinations(ratios, sequences);
T = load("testArray.mat","T").T;
date = string(datetime('now','TimeZone','local','Format','d_M'));

for i=1:height(T)
    ratio = T{i,1};
    sequence = T{i,2}{1};
    RunPBS("d" + date + "_TriLDPC_12e3_r" + ratio + "_s" + sequence(1) + "_" + sequence(2), -5:-3, sequence(1), sequence(2), ratio, 256, 0.5, 12e3, 500)
end
