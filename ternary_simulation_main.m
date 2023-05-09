function ternary_simulation_main(n, p, num_iter_sim)
arguments
    n (1,1) {mustBeInteger,mustBePositive} = 8
    p (1,1) {mustBeLessThanOrEqual(p,1), mustBeGreaterThanOrEqual(p,0)} = 0.1
    num_iter_sim (1,1) {mustBeInteger, mustBePositive} = 100
end

rng('shuffle');
filepath = cd(fileparts(mfilename('fullpath')));
cd(filepath);

%% User-defined parameters
% encoder parameters
% n               = 8;
rate_ind        = 0.1;
rate_res        = 0.1;
% Simulation parameters
% num_iter_sim    = 100; % iterations in simulations
% p               = 0.1; % downward error probability, p
q               = 3;   % alphabet size
q2              = p/2; % upward error probability, q/2
ChannelType     = "random"; % "random" / "upto"
% Other parameters
nIterBetweenFileSave = 10;

%% Construct LDPC codes
addpath(fullfile('.','gen_par_mats'));
addpath(genpath(fullfile('.','LDPC')));

% construct indicator code
filenameLDPC = sprintf('n%d_R0%.0f.mat',n,100*rate_ind);
filepathLDPC = fullfile('.','LDPCcode',filenameLDPC);
if ~exist(filepathLDPC,'file')
    try
        [Lam, ~] = GenerateDist(15,rate_ind); % Generate distributions with requested rate of r
        LDPCWrapper('GenerateIrregular',n,Lam,p,filepathLDPC); % Generate parity matrix for code length of n
        SavePartiyMat(filepathLDPC); % Save MAT file
    catch err
        disp(err.getReport);
        return;
    end
end
load(filepathLDPC,"H","Hnonsys"); % H, Hnonsys are the parity-check matrices of the code
H_sys_ind = full(H);
% what is this for?
% H_nonsys_ind = full(Hnonsys);
% enc_ind = comm.LDPCEncoder('ParityCheckMatrix',Hnonsys); 
% dec_ind = comm.LDPCDecoder('ParityCheckMatrix',Hnonsys); % hard-decision message-passing decoder
rate_ind_actual = (n-size(H_sys_ind,1)) / n;

% construct residual code
filenameLDPC = sprintf('n%d_R0%.0f.mat',n,100*rate_res);
filepathLDPC = fullfile('.','LDPCcode',filenameLDPC);
if ~exist(filepathLDPC,'file')
    try
        [Lam, ~] = GenerateDist(15,rate_res); % Generate distributions with requested rate of r
        LDPCWrapper('GenerateIrregular',n,Lam,p,filepathLDPC); % Generate parity matrix for code length of n
        SavePartiyMat(filepathLDPC); % Save MAT file
    catch err
        disp(err.getReport);
        return;
    end
end
load(filepathLDPC,"H","Hnonsys"); % H, Hnonsys are the parity-check matrices of the code
H_sys_res = full(H);
% what is this for?
% H_nonsys_res = full(Hnonsys);
% enc_res = comm.LDPCEncoder('ParityCheckMatrix',Hnonsys); 
% dec_res = comm.LDPCDecoder('ParityCheckMatrix',Hnonsys); % hard-decision message-passing decoder
rate_res_actual = (n-size(H_sys_res,1)) / n;

rmpath('.\gen_par_mats');


%% Probability of correcting (p,q) errors with LDPC-LDPC code
fprintf('* - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *\n');

% Initialize results arrays
BEP_Naive = ones(1,num_iter_sim); % 
BEP_MsgPas = ones(1,num_iter_sim); % 

tUpDown_Actual = zeros(1,num_iter_sim,2);

% Save start time
simStartTime = datetime;
simStartTime.Format = 'yyyy-MM-dd_HH-mm-ss-SSS';

hwb = waitbar(0);
for iter_sim = 1 : num_iter_sim
    % - % - % Encoding: % - % - % 
    [CodewordComb,CodewordInd,CodewordRes,messageInd,messageRes] = ternary_enc_LDPCLDPC(gf(H_sys_ind,1),gf(H_sys_res,1));
    % - % - % Encoding end % - % - % 
    
    % - % - % Channel (asymmetric one2all): % - % - % 
    tUp = q2* 2;
    tDown = p;
    ChannelOut = asymmchannel(CodewordComb,q,ChannelType,tUp,tDown);
    tUp_Actual = sum(ChannelOut>CodewordComb);
    tDown_Actual = sum(ChannelOut<CodewordComb);
    % - % - % Channel end % - % - % 
    
    % - % - % Decoding: % - % - % 
    [decCodewordRM_Naive, success_naive]  = NaiveDecoder(ChannelOut, H_sys_ind, H_sys_res, p, 2*q2, []);
    [decCodewordRM_MsgPas, probs, success, numIter] = MsgPasDecoder(ChannelOut, H_sys_ind, H_sys_res, p, 2*q2, 100);
    % - % - % Decoding end % - % - % 
    % - % - % BEP % - % - % 
    tUpDown_Actual(iter_sim,1) = tUp_Actual;
    tUpDown_Actual(iter_sim,2) = tDown_Actual;
    
    % 1. Standard 2-step decoder:
    if isequal(decCodewordRM_Naive(:),CodewordComb(:))
        BEP_Naive(iter_sim) = 0;
    end
    % 2. Interleaved iterations in message-passing:
    if isequal(decCodewordRM_MsgPas(:),CodewordComb(:))
        BEP_MsgPas(iter_sim) = 0;
    end
    % - % - % BEP end % - % - % 
    
    % advance waitbar
    wbmsg = sprintf('LDPC(%d,%d): (p,q/2)=(%d,%d), iterSim=%d/%d',rate_ind_actual,rate_res_actual,p,q2,iter_sim,num_iter_sim);
    waitbar(iter_sim/num_iter_sim, hwb, wbmsg);
    
    % save partial results
    if mod(iter_sim,nIterBetweenFileSave)
        save(sprintf('./Results/len%d_p%.5f_q%.5f_LDPC_0%.0f_0%.0f_Joint_nIterSim%d_%s_Seed%.2f_partial.mat',...
            n,p,2*q2,100*rate_ind_actual,100*rate_res_actual,num_iter_sim,string(simStartTime),seed), '-regexp', '^(?!(hwb)$).');
    end

end

fprintf('\tNaive BEP = %E, MsgPas BEP = %E\n',...
    mean(BEP_Naive),mean(BEP_MsgPas));

delete(hwb);
fprintf('* - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *\n');

% Save data to .mat file and delete partial results file
if ~isfolder(fullfile(".","Results"))
    mkdir(fullfile(".","Results"));
end
save(sprintf('./Results/len%d_p%.5f_q%.5f_LDPC_0%.0f_0%.0f_Joint_nIterSim%d_%s_Seed%.2f.mat',...
            n,p,2*q2,100*rate_ind_actual,100*rate_res_actual,num_iter_sim,string(simStartTime),seed));
delete(sprintf('./Results/len%d_p%.5f_q%.5f_LDPC_0%.0f_0%.0f_Joint_nIterSim%d_%s_Seed%.2f_partial.mat',...
            n,p,2*q2,100*rate_ind_actual,100*rate_res_actual,num_iter_sim,string(simStartTime),seed));

%  ------------------------------------------------------------------------
end