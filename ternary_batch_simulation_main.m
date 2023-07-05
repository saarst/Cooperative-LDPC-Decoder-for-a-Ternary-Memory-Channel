function ternary_batch_simulation_main(n, log_p, rate_ind, rate_res, num_iter_sim, batchSize, sequenceInd, sequenceRes, ratio, ResultsFolder)
arguments
    n (1,1) {mustBeInteger,mustBePositive} = 16
    log_p (1,1) {mustBeNegative} = -5
    rate_ind (1,1) {mustBeLessThanOrEqual(rate_ind,1), mustBeGreaterThanOrEqual(rate_ind,0)} = 0.25
    rate_res (1,1) {mustBeLessThanOrEqual(rate_res,1), mustBeGreaterThanOrEqual(rate_res,0)} = 0.1
    num_iter_sim (1,1) {mustBeInteger, mustBePositive} = 10^(-log_p + 2);
    batchSize (1,1) {mustBeInteger, mustBePositive} = 1000;
    sequenceInd = 4;
    sequenceRes = 2;
    ratio {mustBePositive} = 0.5; 
    ResultsFolder = "./Results"
end
clc
disp("Ternary LDPC simulation begin");
disp("Parameters:")
fprintf("n = %d, log_p = %g, rate_ind = %f, rate_res = %f, num_iter_sim = %g, batchSize = %g, sequenceInd = %d, sequenceRes = %d, ratio = %g, resultsFolder = %s \n", ...
             n,          log_p,         rate_ind,      rate_res,          num_iter_sim,   batchSize,        sequenceInd,      sequenceRes,                    ResultsFolder);
rng('shuffle');
seed = rng;
filepath = cd(fileparts(mfilename('fullpath')));
cd(filepath);
if ~isfolder(fullfile(".","Results"))
    mkdir(fullfile(".","Results"));
end
if ~isfolder(ResultsFolder)
    mkdir(ResultsFolder);
end

% Check if parallel pool exists, and if not, create one
if isempty(gcp('nocreate'))
    parpool(24); % Create a parallel pool with the default settings
end

% Get information about the parallel pool
pool = gcp();
numWorkers = pool.NumWorkers;
fprintf("num of workers = %g \n", numWorkers);
%% User-defined parameters
% Simulation parameters
p = 10^(log_p);
q               = 3;   % alphabet size
q2              = p/ratio; % upward error probability, q/2
assert(q2 <= 0.5," q2 > 0.5");
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
BEP_Naive_batch = zeros(1,num_threads_sim);  
BEP_MsgPas_batch = zeros(1,num_threads_sim);
BEPind_Naive_batch = zeros(1,num_threads_sim);  
BEPind_MsgPas_batch = zeros(1,num_threads_sim); 
numIterNaive = zeros(1,num_threads_sim);
numIterMsgPas = zeros(1,num_threads_sim);

% Save start time
simStartTime = datetime;
simStartTime.Format = 'yyyy-MM-dd_HH-mm-ss-SSS';

parfor iter_thread = 1 : num_threads_sim
    [BEP_Naive_batch(iter_thread), BEP_MsgPas_batch(iter_thread), numIterNaive(iter_thread), numIterMsgPas(iter_thread), BEPind_Naive_batch(iter_thread), BEPind_MsgPas_batch(iter_thread)] =  ...
        TernaryBatch(ChannelType, H_sys_ind, H_sys_res, q, p, q2, batchSize, sequenceInd, sequenceRes);

end

maxTrueIterNaive = max(numIterNaive);
maxTrueIterMsgPas = max(numIterMsgPas);
% calc BEP
BEP_Naive = mean(BEP_Naive_batch);
BEP_MsgPas = mean(BEP_MsgPas_batch);
BEPind_Naive = mean(BEPind_Naive_batch);
BEPind_MsgPas = mean(BEPind_MsgPas_batch);
fprintf('\tNaive BEP = %E, MsgPas BEP = %E\n', BEP_Naive, BEP_MsgPas);
fprintf('* - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *\n');
fprintf("End of simulation\n");

% Save data to .mat file
save(sprintf('%s/len%d_logp%g_q%g_LDPC_0%.0f_0%.0f_Joint_nIterSim%d_%s.mat',...
            ResultsFolder,n,log_p,2*q2,100*rate_ind_actual,100*rate_res_actual,num_iter_sim,string(simStartTime)));

end
%  ------------------------------------------------------------------------


function [BEP_Naive, BEP_MsgPas, maxTrueIterNaive, maxTrueIterMsgPas, BEPind_Naive, BEPind_MsgPas] = TernaryBatch(ChannelType, H_sys_ind, H_sys_res, q, p, q2, batchSize, sequenceInd, sequenceRes)
    BEP_Naive_vec = ones(1,batchSize);
    BEPind_Naive_vec = ones(1,batchSize);
    BEP_MsgPas_vec = ones(1,batchSize);
    BEPind_MsgPas_vec = ones(1,batchSize);
    MsgPasDec = BuildMsgPasDecoder(H_sys_ind, H_sys_res, p, 2*q2, 45, sequenceInd, sequenceRes);
    NaiveIndDec = BuildNaiveIndDecoder(H_sys_ind, p, 2*q2, 20);
    maxTrueIterNaive = 0;
    maxTrueIterMsgPas = 0;
    for iter_sim = 1:batchSize
        % - % - % Encoding: % - % - % 
        [CodewordComb,CodewordInd,CodewordRes,messageInd,messageRes] = ternary_enc_LDPCLDPC(gf(H_sys_ind,1),gf(H_sys_res,1));
        % - % - % Encoding end % - % - % 
        % - % - % Channel (asymmetric one2all): % - % - % 
        tUp = q2* 2;
        tDown = p;
        ChannelOut = asymmchannel(CodewordComb, q, ChannelType, tUp, tDown);
        tUp_Actual = sum(ChannelOut>CodewordComb);
        tDown_Actual = sum(ChannelOut<CodewordComb);
        % - % - % Channel end % - % - % 
        
        % - % - % Decoding: % - % - % 
        [decCodewordRM_Naive, ~, numIterNaive]  = NaiveDecoder(ChannelOut, NaiveIndDec, H_sys_res, CodewordComb > 0);
        [decCodewordRM_MsgPas, ~, ~, numIterMsgPas] = MsgPasDec.decode(ChannelOut);
        % - % - % Decoding end % - % - % 
        % - % - % BEP % - % - % 
     
        % 1. Standard 2-step decoder:
        if isequal(decCodewordRM_Naive(:) > 0,CodewordComb(:) > 0)
            BEPind_Naive_vec(iter_sim) = 0;
        end

        if isequal(decCodewordRM_Naive(:),CodewordComb(:))
            maxTrueIterNaive = max(maxTrueIterNaive, numIterNaive);
            BEP_Naive_vec(iter_sim) = 0;
        end
        % 2. Interleaved iterations in message-passing:
        if isequal(decCodewordRM_MsgPas(:) > 0,CodewordComb(:) > 0)
            BEPind_MsgPas_vec(iter_sim) = 0;
        end   

        if isequal(decCodewordRM_MsgPas(:),CodewordComb(:))
            maxTrueIterMsgPas = max(maxTrueIterMsgPas, numIterMsgPas);
            BEP_MsgPas_vec(iter_sim) = 0;
        end
    end
    % - % - % BEP end % - % - % 
    BEP_Naive = mean(BEP_Naive_vec);
    BEP_MsgPas = mean(BEP_MsgPas_vec);
    BEPind_Naive = mean(BEPind_Naive_vec);
    BEPind_MsgPas = mean(BEPind_MsgPas_vec);
end