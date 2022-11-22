% To design an LDPC code, run the following MATLAB script

nLDPC = 2^m; % code length
rLDPC = 0.5; % code rate

filenameLDPC = sprintf('n%d_R0%.0f',nLDPC,100*rLDPC);
filepathLDPC = fullfile('.',filenameLDPC);
if ~exist(filepathLDPC,'file')
    [Lam,p] = GenerateDist(15,rLDPC); % Generate distributions with requested rate of r
    LDPCWrapper('GenerateIrregular',nLDPC,Lam,p,filepathLDPC); % Generate parity matrix for code length of n
    SavePartiyMat(filepathLDPC); % Save MAT file
end
load([filepathLDPC '.mat']); % H, Hnonsys are the parity-check matrices of the code
HLDPC_sys = full(H);
HLDPC_nonsys = full(Hnonsys);

rLDPC_actual = (nLDPC-size(HLDPC_sys,1)) / nLDPC;
