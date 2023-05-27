function [BEP_Naive, BEP_MsgPas] = ternary_simulation_main(n, log_p, R, num_iter_sim)
arguments
    n (1,1) {mustBeInteger,mustBePositive} = 8
    log_p (1,1) {mustBeInteger,mustBeNegative} = -1
    R (1,1) {mustBeLessThanOrEqual(R,1), mustBeGreaterThanOrEqual(R,0)} = 0.1
    num_iter_sim (1,1) {mustBeInteger, mustBePositive} = 10^(-log_p + 2);
end

seed = rng('shuffle').Seed;
filepath = cd(fileparts(mfilename('fullpath')));
cd(filepath);
if ~isfolder(fullfile(".","Results"))
    mkdir(fullfile(".","Results"));
end

% Check if parallel pool exists, and if not, create one
if isempty(gcp('nocreate'))
    parpool(); % Create a parallel pool with the default settings
end

% Get information about the parallel pool
pool = gcp();
numWorkers = pool.NumWorkers;
disp(numWorkers)

%% User-defined parameters
% encoder parameters
% n               = 8;
rate_ind        = R;
rate_res        = R;
% Simulation parameters
% num_iter_sim    = 100; % iterations in simulations
% p               = 0.1; % downward error probability, p
p = 10^(log_p);
q               = 3;   % alphabet size
q2              = p/2; % upward error probability, q/2
ChannelType     = "random"; % "random" / "upto"
% Other parameters
nIterBetweenFileSave = 50;

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

rmpath(fullfile('.','gen_par_mats'));


%% Probability of correcting (p,q) errors with LDPC-LDPC code
fprintf('* - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *\n');


% Initialize results arrays
BEP_Naive_vec = ones(1,num_iter_sim); % 
BEP_MsgPas_vec = ones(1,num_iter_sim); % 

tUp_Actual_total = zeros(1,num_iter_sim);
tDown_Actual_total = zeros(1,num_iter_sim);
% Initialize decoders:
% MsgPasDec = BuildMsgPasDecoder(H_sys_ind, H_sys_res, p, 2*q2, 100);
% NaiveIndDec = BuildNaiveIndDecoder(H_sys_ind, p, 2*q2, 100);
% Save start time
simStartTime = datetime;
simStartTime.Format = 'yyyy-MM-dd_HH-mm-ss-SSS';
% if ispc
%     hwb = waitbar(0);
% end
parfor iter_sim = 1 : num_iter_sim
    % - % - % Encoding: % - % - % 
    [CodewordComb,CodewordInd,CodewordRes,messageInd,messageRes] = ternary_enc_LDPCLDPC(gf(H_sys_ind,1),gf(H_sys_res,1));
    % - % - % Encoding end % - % - % 
    MsgPasDec = BuildMsgPasDecoder(H_sys_ind, H_sys_res, p, 2*q2, 20);
    NaiveIndDec = BuildNaiveIndDecoder(H_sys_ind, p, 2*q2, 20);
    % - % - % Channel (asymmetric one2all): % - % - % 
    tUp = q2* 2;
    tDown = p;
    ChannelOut = asymmchannel(CodewordComb,q,ChannelType,tUp,tDown);
    tUp_Actual = sum(ChannelOut>CodewordComb);
    tDown_Actual = sum(ChannelOut<CodewordComb);
    % - % - % Channel end % - % - % 
    
    % - % - % Decoding: % - % - % 
    [decCodewordRM_Naive, success_naive]  = NaiveDecoder(ChannelOut, NaiveIndDec, H_sys_res);
    [decCodewordRM_MsgPas, probs, success, numIter] = MsgPasDec.decode(ChannelOut);
    % - % - % Decoding end % - % - % 
    % - % - % BEP % - % - % 
    tUp_Actual_total(iter_sim) = tUp_Actual;
    tDown_Actual_total(iter_sim) = tDown_Actual;

    
    % 1. Standard 2-step decoder:
    if isequal(decCodewordRM_Naive(:),CodewordComb(:))
        BEP_Naive_vec(iter_sim) = 0;
    end
    % 2. Interleaved iterations in message-passing:
    if isequal(decCodewordRM_MsgPas(:),CodewordComb(:))
        BEP_MsgPas_vec(iter_sim) = 0;
    end
    % - % - % BEP end % - % - % 
    
    % advance waitbar
    % if ispc
    %     wbmsg = sprintf('LDPC(%d,%d): (p,q/2)=(%d,%d), iterSim=%d/%d',rate_ind_actual,rate_res_actual,p,q2,iter_sim,num_iter_sim);
    %     waitbar(iter_sim/num_iter_sim, hwb, wbmsg);
    % end
    
    % % save partial results
    % if mod(iter_sim,nIterBetweenFileSave)
    %     save(sprintf('./Results/len%d_p%.5f_q%.5f_LDPC_0%.0f_0%.0f_Joint_nIterSim%d_%s_Seed%.2f_partial.mat',...
    %         n,p,2*q2,100*rate_ind_actual,100*rate_res_actual,num_iter_sim,string(simStartTime),seed), '-regexp', '^(?!(hwb)$).');
    % end
end

% calc BEP
BEP_Naive = mean(BEP_Naive_vec);
BEP_MsgPas = mean(BEP_MsgPas_vec);
fprintf('\tNaive BEP = %E, MsgPas BEP = %E\n', BEP_Naive, BEP_MsgPas);

% if ispc
%     delete(hwb);
% end
fprintf('* - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *\n');

% Save data to .mat file and delete partial results file
save(sprintf('./Results/len%d_p%.5f_q%.5f_LDPC_0%.0f_0%.0f_Joint_nIterSim%d_%s_Seed%.2f.mat',...
            n,p,2*q2,100*rate_ind_actual,100*rate_res_actual,num_iter_sim,string(simStartTime),seed));
delete(sprintf('./Results/len%d_p%.5f_q%.5f_LDPC_0%.0f_0%.0f_Joint_nIterSim%d_%s_Seed%.2f_partial.mat',...
            n,p,2*q2,100*rate_ind_actual,100*rate_res_actual,num_iter_sim,string(simStartTime),seed));

%  ------------------------------------------------------------------------
end