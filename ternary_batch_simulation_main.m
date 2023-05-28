function [BEP_Naive, BEP_MsgPas] = ternary_batch_simulation_main(n, log_p, R, num_iter_sim, batchSize)
arguments
    n (1,1) {mustBeInteger,mustBePositive} = 8
    log_p (1,1) {mustBeInteger,mustBeNegative} = -1
    R (1,1) {mustBeLessThanOrEqual(R,1), mustBeGreaterThanOrEqual(R,0)} = 0.1
    num_iter_sim (1,1) {mustBeInteger, mustBePositive} = 10^(-log_p + 2);
    batchSize (1,1) {mustBeInteger, mustBePositive} = 1000;
end

seed = rng('shuffle').Seed;
filepath = cd(fileparts(mfilename('fullpath')));
cd(filepath);
if ~isfolder(fullfile(".","Results"))
    mkdir(fullfile(".","Results"));
end

% % Check if parallel pool exists, and if not, create one
% if isempty(gcp('nocreate'))
%     parpool(); % Create a parallel pool with the default settings
% end
% 
% % Get information about the parallel pool
% pool = gcp();
% numWorkers = pool.NumWorkers;
% disp(numWorkers)

%% User-defined parameters
% encoder parameters
rate_ind        = R;
rate_res        = R;
% Simulation parameters
p = 10^(log_p);
q               = 3;   % alphabet size
q2              = p/2; % upward error probability, q/2
ChannelType     = "random"; % "random" / "upto"

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
num_threads_sim = num_iter_sim / batchSize;
BEP_Naive_batch = ones(1,num_threads_sim); % 
BEP_MsgPas_batch = ones(1,num_threads_sim); % 

% Save start time
simStartTime = datetime;
simStartTime.Format = 'yyyy-MM-dd_HH-mm-ss-SSS';

parfor iter_thread = 1 : num_threads_sim
    [BEP_Naive_batch(iter_thread), BEP_MsgPas_batch(iter_thread)] = TernaryBatch(ChannelType, H_sys_ind, H_sys_res, q, p, q2, batchSize);
end

% calc BEP
BEP_Naive = mean(BEP_Naive_batch);
BEP_MsgPas = mean(BEP_MsgPas_batch);
fprintf('\tNaive BEP = %E, MsgPas BEP = %E\n', BEP_Naive, BEP_MsgPas);
fprintf('* - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *\n');

% Save data to .mat file
save(sprintf('./Results/len%d_p%g_q%g_LDPC_0%.0f_0%.0f_Joint_nIterSim%d_%s_Seed%.2f.mat',...
            n,p,2*q2,100*rate_ind_actual,100*rate_res_actual,num_iter_sim,string(simStartTime),seed));

end
%  ------------------------------------------------------------------------


function [BEP_Naive, BEP_MsgPas] = TernaryBatch(ChannelType, H_sys_ind, H_sys_res, q, p, q2, batchSize)
    BEP_Naive_vec = ones(1,batchSize);  
    BEP_MsgPas_vec = ones(1,batchSize);  
    MsgPasDec = BuildMsgPasDecoder(H_sys_ind, H_sys_res, p, 2*q2, 20);
    NaiveIndDec = BuildNaiveIndDecoder(H_sys_ind, p, 2*q2, 20);
    for iter_sim = 1:batchSize
        % tic
        % - % - % Encoding: % - % - % 
        [CodewordComb,CodewordInd,CodewordRes,messageInd,messageRes] = ternary_enc_LDPCLDPC(gf(H_sys_ind,1),gf(H_sys_res,1));
        % - % - % Encoding end % - % - % 
        % - % - % Channel (asymmetric one2all): % - % - % 
        tUp = q2* 2;
        tDown = p;
        ChannelOut = asymmchannel(CodewordComb, q, ChannelType, tUp, tDown);
        % - % - % Channel end % - % - % 
        
        % - % - % Decoding: % - % - % 
        [decCodewordRM_Naive, success_naive]  = NaiveDecoder(ChannelOut, NaiveIndDec, H_sys_res);
        [decCodewordRM_MsgPas, ~, success, numIter] = MsgPasDec.decode(ChannelOut);
        % - % - % Decoding end % - % - % 
        % - % - % BEP % - % - % 
     
        % 1. Standard 2-step decoder:
        if isequal(decCodewordRM_Naive(:),CodewordComb(:))
            BEP_Naive_vec(iter_sim) = 0;
        end
        % 2. Interleaved iterations in message-passing:
        if isequal(decCodewordRM_MsgPas(:),CodewordComb(:))
            BEP_MsgPas_vec(iter_sim) = 0;
        end
    end
    % - % - % BEP end % - % - % 
    BEP_Naive = mean(BEP_Naive_vec);
    BEP_MsgPas = mean(BEP_MsgPas_vec);
end