function ternary_batch_simulation_main(n, log_p, log_q, rate_ind, rate_res, num_iter_sim, sequenceInd, sequenceRes, ResultsFolder)
arguments
    n (1,1) {mustBeInteger,mustBePositive} = 128
    log_p (1,1) {mustBeNegative} = -1
    log_q (1,1) {mustBeNegative} = -1
    rate_ind (1,1) {mustBeLessThanOrEqual(rate_ind,1), mustBeGreaterThanOrEqual(rate_ind,0)} = 0.25
    rate_res (1,1) {mustBeLessThanOrEqual(rate_res,1), mustBeGreaterThanOrEqual(rate_res,0)} = 0.1
    num_iter_sim (1,1) {mustBeInteger, mustBePositive} = 10^(-log_p + 2);
    sequenceInd = 4;
    sequenceRes = 2;
    ResultsFolder = "./Results"
end
tic
clc
disp("Ternary LDPC simulation begin");
disp("Parameters:")
fprintf("n = %d, log_p = %g, log_q = %g, rate_ind = %f, rate_res = %f, num_iter_sim = %g, sequenceInd = %d, sequenceRes = %d, resultsFolder = '%s' \n", ...
             n,  log_p,      log_q,      rate_ind,      rate_res,      num_iter_sim,      sequenceInd,      sequenceRes,      ResultsFolder);
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

%% User-defined parameters
% Simulation parameters
p = 10^(log_p);
q  = 10^(log_q); % upward error probability, q/2
Q   = 3;   % alphabet size
ChannelType     = "random"; % "random" / "upto"
maxIterNaive = 20;
maxIterMsgPas = 20;

%% Construct LDPC codes
addpath(fullfile('.','gen_par_mats'));
addpath(genpath(fullfile('.','LDPC')));

% construct indicator code
filenameLDPC = sprintf('n%d_R0%.0f.mat',n,100*rate_ind);
filepathLDPC = fullfile('.','LDPCcode',filenameLDPC);
if ~exist(filepathLDPC,'file')
    try
        [Lam, probInd] = GenerateDist(15,rate_ind); % Generate distributions with requested rate of r
        LDPCWrapper('GenerateIrregular',n, Lam, probInd, filepathLDPC); % Generate parity matrix for code length of n
        SavePartiyMat(filepathLDPC); % Save MAT file
    catch err
        disp(err.getReport);
        return;
    end
end
load(filepathLDPC,"H","Hnonsys"); % H, Hnonsys are the parity-check matrices of the code
H_nonsys_ind = full(Hnonsys);
% enc_ind = comm.LDPCEncoder('ParityCheckMatrix',Hnonsys); 
% dec_ind = comm.LDPCDecoder('ParityCheckMatrix',Hnonsys); % hard-decision message-passing decoder
rate_ind_actual = (n-size(H_nonsys_ind,1)) / n;

% construct residual code
filenameLDPC = sprintf('n%d_R0%.0f.mat',n,100*rate_res);
filepathLDPC = fullfile('.','LDPCcode',filenameLDPC);
if ~exist(filepathLDPC,'file')
    try
        [Lam, probRes] = GenerateDist(15,rate_res); % Generate distributions with requested rate of r
        LDPCWrapper('GenerateIrregular', n, Lam, probRes, filepathLDPC); % Generate parity matrix for code length of n
        SavePartiyMat(filepathLDPC); % Save MAT file
    catch err
        disp(err.getReport);
        return;
    end
end
load(filepathLDPC,"H","Hnonsys"); % H, Hnonsys are the parity-check matrices of the code
H_nonsys_res = full(Hnonsys);
% enc_res = comm.LDPCEncoder('ParityCheckMatrix',Hnonsys); 
% dec_res = comm.LDPCDecoder('ParityCheckMatrix',Hnonsys); % hard-decision message-passing decoder
rate_res_actual = (n-size(H_nonsys_res,1)) / n;

rmpath(fullfile('.','gen_par_mats'));
fprintf("Loading Files is complete\n");


%% Probability of correcting (p,q) errors with LDPC-LDPC code
fprintf('* - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *\n');

% Save start time
simStartTime = datetime;
simStartTime.Format = 'yyyy-MM-dd_HH-mm-ss-SSS';

% create parllel pool
currentPool = gcp('nocreate');
if isempty(currentPool)
    % If no parallel pool exists, create one with max workers
    poolSize = feature('numCores');
    parpool(poolSize);
    currentPool = gcp; % Get the current parallel pool
    NumWorkers = currentPool.NumWorkers;
    disp(['Parallel pool created with ', num2str(poolSize), ' workers.']);
else
    % If a parallel pool exists, display the number of workers
    NumWorkers = currentPool.NumWorkers;
    disp(['Using existing parallel pool with ', num2str(NumWorkers), ' workers.']);
end

% Initialize results arrays
batchSize = ceil(num_iter_sim / NumWorkers);
num_iter_sim = batchSize * NumWorkers;
stats = TernaryBatch([], [], [], [], [], [], 0, [], []);
stats = repmat(stats,[1,NumWorkers]);

% main run:
parfor iter_thread = 1 : NumWorkers
    stats(iter_thread) =  ...
        TernaryBatch(ChannelType, H_nonsys_ind, H_nonsys_res, Q, p, q, ...
        batchSize, sequenceInd, sequenceRes, maxIterNaive, maxIterMsgPas);
end
% statistics:
BEP_Naive = mean([stats.BEP_Naive]);
BEP_MsgPas = mean([stats.BEP_MsgPas]);

% print BEP
fprintf('\tNaive BEP = %E, MsgPas BEP = %E\n', BEP_Naive, BEP_MsgPas);
fprintf('* - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *\n');
fprintf("End of simulation\n");
TimeElapsed = toc;

% Save data to .mat file
save(sprintf('%s/len%d_logp%g_logq%g_LDPC_0%.0f_0%.0f_Joint_nIterSim%d_%s.mat',...
            ResultsFolder,n,log_p,log_q,100*rate_ind_actual,100*rate_res_actual,num_iter_sim,string(simStartTime)));

end
%  ------------------------------------------------------------------------
% internal functions:

function stats = TernaryBatch(ChannelType, H_nonsys_ind, H_nonsys_res, Q, p, q, batchSize, ...
          sequenceInd, sequenceRes, maxIterNaive, maxIterMsgPas)
    % Initializatoins:
    BEP_Naive_vec = ones(1,batchSize);
    BEPind_Naive_vec = ones(1,batchSize);
    BEP_MsgPas_vec = ones(1,batchSize);
    BEPind_MsgPas_vec = ones(1,batchSize);
    messageIndLength_vec = zeros(1, batchSize);
    messageResLength_vec = zeros(1, batchSize);
    numIterMsgPas_vec = zeros(1, batchSize);
    numIterNaiveInd_vec = zeros(1, batchSize);
    numIterNaiveRes_vec = zeros(1, batchSize);
    tUpActual_vec = zeros(1, batchSize);
    tDownActual_vec = zeros(1, batchSize);

    if batchSize > 0
        MsgPasDec = BuildMsgPasDecoder(H_nonsys_ind, H_nonsys_res, p, q, maxIterMsgPas, sequenceInd, sequenceRes);
        NaiveIndDec = BuildNaiveIndDecoder(H_nonsys_ind, p, q, maxIterNaive);
        for iter_sim = 1:batchSize
            % - % - % Encoding: % - % - % 
            [CodewordComb, ~, ~, messageInd, messageRes] =  ...
                ternary_enc_LDPCLDPC(gf(H_nonsys_ind,1),gf(H_nonsys_res,1));
            % - % - % Encoding end % - % - %
            messageIndLength_vec(iter_sim) = length(messageInd);
            messageResLength_vec(iter_sim) = length(messageRes);
            % - % - % Channel (asymmetric one2all): % - % - % 
            
            ChannelOut = asymmchannel(CodewordComb, Q, ChannelType, q, p);
            tUpActual_vec(iter_sim) = sum(ChannelOut>CodewordComb);
            tDownActual_vec(iter_sim) = sum(ChannelOut<CodewordComb);
            % - % - % Channel end % - % - % 
            
            % - % - % Decoding: % - % - % 
            [decCodewordRM_Naive, ~, numIterNaiveInd_vec(iter_sim), ...
                numIterNaiveRes_vec(iter_sim)]  =  ...
                NaiveDecoder(ChannelOut, NaiveIndDec, H_nonsys_res, CodewordComb > 0);

            [decCodewordRM_MsgPas, ~, ~, numIterMsgPas_vec(iter_sim)] =  ...
                MsgPasDec.decode(ChannelOut);
            % - % - % Decoding end % - % - % 
            % - % - % BEP % - % - % 
         
            % 1. Standard 2-step decoder:
            if isequal(decCodewordRM_Naive(:) > 0,CodewordComb(:) > 0)
                BEPind_Naive_vec(iter_sim) = 0;
            end
    
            if isequal(decCodewordRM_Naive(:),CodewordComb(:))
                BEP_Naive_vec(iter_sim) = 0;
            end
            % 2. Interleaved iterations in message-passing:
            if isequal(decCodewordRM_MsgPas(:) > 0,CodewordComb(:) > 0)
                BEPind_MsgPas_vec(iter_sim) = 0;
            end   
    
            if isequal(decCodewordRM_MsgPas(:),CodewordComb(:))
                BEP_MsgPas_vec(iter_sim) = 0;
            end
        end
    end
    % - % - % BEP end % - % - %
    % mean messageLength
    stats.messageIndLen = mean(messageIndLength_vec);
    stats.messageResLen = mean(messageResLength_vec);
    % BEP
    stats.BEP_Naive = mean(BEP_Naive_vec);
    stats.BEP_MsgPas = mean(BEP_MsgPas_vec);
    stats.BEPind_Naive = mean(BEPind_Naive_vec);
    stats.BEPind_MsgPas = mean(BEPind_MsgPas_vec);
    %max iters
    stats.maxTrueIterNaiveInd = max(numIterNaiveInd_vec(BEPind_Naive_vec == 0));
    stats.maxTrueIterNaiveRes = max(numIterNaiveRes_vec(BEP_Naive_vec == 0));
    stats.maxTrueIterMsgPas = max(numIterMsgPas_vec(BEP_MsgPas_vec == 0));
    % mean of true iters
    stats.meanTrueIterNaiveInd = mean(numIterNaiveInd_vec(BEPind_Naive_vec == 0));
    stats.meanTrueIterNaiveRes = mean(numIterNaiveRes_vec(BEP_Naive_vec == 0));
    stats.meanTrueIterMsgPas = mean(numIterMsgPas_vec(BEP_MsgPas_vec == 0));
    % mean of false iters
    stats.meanFalseIterNaiveInd = mean(numIterNaiveInd_vec(BEPind_Naive_vec == 1));
    stats.meanFalseIterNaiveRes = mean(numIterNaiveRes_vec(BEP_Naive_vec == 1));
    stats.meanFalseIterMsgPas = mean(numIterMsgPas_vec(BEP_MsgPas_vec == 1));
    %tActual
    stats.tUpActual = mean(tUpActual_vec);
    stats.tDownActual = mean(tDownActual_vec);

end
