function ternary_batch_simulation_main(decoder, n, log_p, log_q, rate_ind, rate_res, num_iter_sim, sequenceInd, sequenceRes, ResultsFolder)
arguments
    decoder (1,1) string {mustBeMember(decoder, ["2step", "joint", "both"])} = "joint"
    n (1,1) {mustBeInteger,mustBePositive} = 32
    log_p (1,1) {mustBeNegative} = -1
    log_q (1,1) {mustBeNegative} = -1
    rate_ind (1,1) {mustBeLessThanOrEqual(rate_ind,1), mustBeGreaterThanOrEqual(rate_ind,0)} = 0.25
    rate_res (1,1) {mustBeLessThanOrEqual(rate_res,1), mustBeGreaterThanOrEqual(rate_res,0)} = 0.1
    num_iter_sim (1,1) {mustBeInteger, mustBePositive} = 10^(-log_p + 2);
    sequenceInd = 2;
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

NumWorkers = 2;
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
[statsJoint, stats2step, statsGeneral] = TernaryBatch(decoder, [], [], [], [], [], [], 0, [], []);
statsJoint = repmat(statsJoint,[1,NumWorkers]);
stats2step = repmat(stats2step,[1,NumWorkers]);
statsGeneral = repmat(statsGeneral,[1,NumWorkers]);

% main run:
parfor iter_thread = 1 : NumWorkers
    [statsJoint(iter_thread), stats2step(iter_thread), statsGeneral(iter_thread)] =  ...
        TernaryBatch(decoder, ChannelType, H_nonsys_ind, H_nonsys_res, Q, p, q, ...
        batchSize, sequenceInd, sequenceRes, maxIterNaive, maxIterMsgPas);
end
% statistics:
BEP_Naive = NaN;
BEP_MsgPas = NaN;
if any(strcmp(decoder, ["2step" , "both"]))
    BEP_Naive = mean([stats2step.BEP_Naive]);
end
if any(strcmp(decoder, ["joint" , "both"]))
    BEP_MsgPas = mean([statsJoint.BEP_MsgPas]);
end

TimeElapsed = toc;

% print BEP
fprintf('\tNaive BEP = %E, MsgPas BEP = %E\n', BEP_Naive, BEP_MsgPas);
fprintf('* - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *\n');
fprintf('Time elapsed: %f seconds\n', TimeElapsed)
fprintf("End of simulation\n");

% Save data to .mat file
save(sprintf('%s/len%d_logp%g_logq%g_LDPC_0%.0f_0%.0f_Joint_nIterSim%d_%s.mat',...
            ResultsFolder,n,log_p,log_q,100*rate_ind_actual,100*rate_res_actual,num_iter_sim,string(simStartTime)));

end
%  ------------------------------------------------------------------------
% internal functions:

function [statsJoint, stats2step, statsGeneral] = TernaryBatch(decoder, ChannelType, H_nonsys_ind, H_nonsys_res, Q, p, q, batchSize, ...
          sequenceInd, sequenceRes, maxIterNaive, maxIterMsgPas)
    % Initializatoins:
    statsJoint = struct;
    stats2step = struct;
    statsGeneral = struct;
    if any(strcmp(decoder, ["2step" , "both"]))
        BEP_Naive_vec = ones(1,batchSize);
        BEPind_Naive_vec = ones(1,batchSize);
        numIterNaiveInd_vec = zeros(1, batchSize);
        numIterNaiveRes_vec = zeros(1, batchSize);
    end

    if any(strcmp(decoder, ["joint" , "both"]))
        BEP_MsgPas_vec = ones(1,batchSize);
        BEPind_MsgPas_vec = ones(1,batchSize);
        numIterMsgPas_vec = zeros(1, batchSize);
    end

    messageIndLength_vec = zeros(1, batchSize);
    messageResLength_vec = zeros(1, batchSize);
    tUpActual_vec = zeros(1, batchSize);
    tDownActual_vec = zeros(1, batchSize);
    iter_sim = 0;

    if batchSize > 0
        if any(strcmp(decoder, ["joint" , "both"]))
            MsgPasDec = BuildMsgPasDecoder(H_nonsys_ind, H_nonsys_res, p, q, maxIterMsgPas, sequenceInd, sequenceRes);
        end
        if any(strcmp(decoder, ["2step" , "both"]))
            NaiveIndDec = BuildNaiveIndDecoder(H_nonsys_ind, p, q, maxIterNaive);
        end
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
            if any(strcmp(decoder, ["2step" , "both"]))
                [decCodewordRM_Naive, ~, numIterNaiveInd_vec(iter_sim), ...
                    numIterNaiveRes_vec(iter_sim)]  =  ...
                    NaiveDecoder(ChannelOut, NaiveIndDec, H_nonsys_res, CodewordComb > 0);
            end
            if any(strcmp(decoder, ["joint" , "both"]))
                [decCodewordRM_MsgPas, ~, ~, numIterMsgPas_vec(iter_sim)] =  ...
                    MsgPasDec.decode(ChannelOut);
            end
            % - % - % Decoding end % - % - % 
            % - % - % BEP % - % - % 
         
            % 1. Standard 2-step decoder:
            if any(strcmp(decoder, ["2step" , "both"]))
                if isequal(decCodewordRM_Naive(:) > 0,CodewordComb(:) > 0)
                    BEPind_Naive_vec(iter_sim) = 0;
                end
        
                if isequal(decCodewordRM_Naive(:),CodewordComb(:))
                    BEP_Naive_vec(iter_sim) = 0;
                end
            end
            % 2. Interleaved iterations in message-passing:
            if any(strcmp(decoder, ["joint" , "both"]))            
                if isequal(decCodewordRM_MsgPas(:) > 0,CodewordComb(:) > 0)
                    BEPind_MsgPas_vec(iter_sim) = 0;
                end   
        
                if isequal(decCodewordRM_MsgPas(:),CodewordComb(:))
                    BEP_MsgPas_vec(iter_sim) = 0;
                end
            end
        end
    end
    % - % - % BEP end % - % - %


    % general stats
    % mean messageLength
    statsGeneral.messageIndLen = mean(messageIndLength_vec);
    statsGeneral.messageResLen = mean(messageResLength_vec);
    %tActual
    statsGeneral.tUpActual = mean(tUpActual_vec);
    statsGeneral.tDownActual = mean(tDownActual_vec);
    %
    statsGeneral.iters = iter_sim;



    % joint decoder stats:
    if any(strcmp(decoder, ["joint" , "both"]))            
        statsJoint.BEP_MsgPas = mean(BEP_MsgPas_vec);
        statsJoint.BEPind_MsgPas = mean(BEPind_MsgPas_vec);
        statsJoint.maxTrueIterMsgPas = max(max(numIterMsgPas_vec(BEP_MsgPas_vec == 0)),0);
        statsJoint.meanTrueIterMsgPas =  max(mean(numIterMsgPas_vec(BEP_MsgPas_vec == 0)),0);
        statsJoint.meanFalseIterMsgPas =  max(mean(numIterMsgPas_vec(BEP_MsgPas_vec == 1)),0);
    end
    % 2-step decoder stats:
    if any(strcmp(decoder, ["2step" , "both"]))
        % BEP
        stats2step.BEP_Naive = mean(BEP_Naive_vec);
        stats2step.BEPind_Naive = mean(BEPind_Naive_vec);
        %max iters
        stats2step.maxTrueIterNaiveInd = max(max(numIterNaiveInd_vec(BEPind_Naive_vec == 0)),0);
        stats2step.maxTrueIterNaiveRes = max(max(numIterNaiveRes_vec(BEP_Naive_vec == 0)),0);
        % mean of true iters
        stats2step.meanTrueIterNaiveInd =  max(mean(numIterNaiveInd_vec(BEPind_Naive_vec == 0)),0);
        stats2step.meanTrueIterNaiveRes =  max(mean(numIterNaiveRes_vec(BEP_Naive_vec == 0)),0);
        % mean of false iters
        stats2step.meanFalseIterNaiveInd =  max(mean(numIterNaiveInd_vec(BEPind_Naive_vec == 1)),0);
        stats2step.meanFalseIterNaiveRes =  max(mean(numIterNaiveRes_vec(BEP_Naive_vec == 1)),0);
    end


end
