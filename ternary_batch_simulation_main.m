function ternary_batch_simulation_main(decoder, loadWords, id, n, log_p, log_q, rate_ind, rate_res, num_iter_sim, sequenceInd, sequenceRes, ResultsFolder)
arguments
    decoder (1,1) string {mustBeMember(decoder, ["generateWords", "2step", "joint", "joint-LC", "both"])} = "both"
    loadWords (1,1) = 1;
    id (1,1) = 0;
    n (1,1) {mustBeInteger,mustBePositive} = 128
    log_p (1,1) {mustBeNegative} = -5
    log_q (1,1) {mustBeNegative} = -0.2
    rate_ind (1,1) {mustBeLessThanOrEqual(rate_ind,1), mustBeGreaterThanOrEqual(rate_ind,0)} = 0.5
    rate_res (1,1) {mustBeLessThanOrEqual(rate_res,1), mustBeGreaterThanOrEqual(rate_res,0)} = 0.5
    num_iter_sim (1,1) {mustBeInteger, mustBeNonnegative} = 100; 
    sequenceInd = 2;
    sequenceRes = 1;    
    ResultsFolder = "./Results"
end

tic
clc
disp("Ternary LDPC simulation begin");
disp("Parameters:")
fprintf("decoder = %s, loadWords = %d, n = %d, log_p = %g, log_q = %g, rate_ind = %f, rate_res = %f, num_iter_sim = %g, sequenceInd = %d, sequenceRes = %d, resultsFolder = '%s' \n", ...
             decoder, loadWords, n,  log_p,      log_q,      rate_ind,      rate_res,      num_iter_sim,      sequenceInd,      sequenceRes,      ResultsFolder);
rng('shuffle');
seed = rng;
rng(seed.Seed + id);
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
        dInd = 15;
        [Lam, probInd] = GenerateDist(dInd,rate_ind); % Generate distributions with requested rate of r
        LDPCWrapper('GenerateIrregular',n, Lam, probInd, filepathLDPC); % Generate parity matrix for code length of n
        SavePartiyMat(filepathLDPC,dInd); % Save MAT file
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

if ~loadWords
    % construct indG_sys and parColsIdxs just one time!
    indH_gf = gf(H_nonsys_ind,1);
    rInd = size(indH_gf,1);
    kInd = n-rInd;
    [indH_rref, parColsIdxs] = gfrref(indH_gf,1);
    parCols = false(1,n); parCols(parColsIdxs) = true; % parity columns
    indH_sys = [indH_rref(:,~parCols) indH_rref(:,parCols)];
    indG_sys = [gf(eye(kInd)) indH_sys(:,1:kInd).'];
else
    indG_sys = [];
    parCols = [];
end

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

%% Loading codewords
if loadWords
    nameOfFile = sprintf('Codewords/len%d_Ri0%.0f_Rr0%.0f.mat',...
        n,100*rate_ind_actual,100*rate_res_actual);
    load(nameOfFile, 'totalCodewords', 'messageIndLen', 'messageResLen');
    totalNumberCodewords = length(totalCodewords);
    symbolsPrior  = histcounts(totalCodewords,"Normalization","probability");
else
    symbolsPrior = [0.5, 0.25, 0.25]; % default prior
    totalNumberCodewords = length(num_iter_sim);
end

%% Probability of correcting (p,q) errors with LDPC-LDPC code
fprintf('* - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *\n');

% Save start time
simStartTime = datetime;
simStartTime.Format = 'yyyy-MM-dd_HH-mm-ss-SSS';

NumWorkers = 1;
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

% slices codewords between cells:
if  loadWords && num_iter_sim > totalNumberCodewords
    codeWordsPerCell = floor(totalNumberCodewords / NumWorkers);
else
    codeWordsPerCell = ceil(num_iter_sim / NumWorkers);
end
totalNumberCodewords = codeWordsPerCell * NumWorkers;
CodewordsCell = cell(1, NumWorkers);
if loadWords
    for iter_thread = 1 : NumWorkers
    startIndex = (iter_thread - 1) * codeWordsPerCell + 1;
    endIndex = iter_thread * codeWordsPerCell;
    % Extract the slice for the current worker
    CodewordsCell{iter_thread} = totalCodewords(startIndex:endIndex, :);
    end
end

% Initialize results arrays
if loadWords && num_iter_sim > totalNumberCodewords
    repeatFactor = ceil(num_iter_sim / totalNumberCodewords);
else
    repeatFactor = 1;
end
[statsJoint, stats2step, statsGeneral] = TernaryBatch(decoder, [], [], [], [], [], [], [], 0, [], []);
statsJoint = repmat(statsJoint,[1,NumWorkers]);
stats2step = repmat(stats2step,[1,NumWorkers]);
statsGeneral = repmat(statsGeneral,[1,NumWorkers]);


% main run:
parfor iter_thread = 1 : NumWorkers
    % Calculate start and end indices for each worker's slice of the matrix
    if loadWords
        currCodewords = CodewordsCell{iter_thread};
    else
        currCodewords = [];
    end
    [statsJoint(iter_thread), stats2step(iter_thread), statsGeneral(iter_thread)] =  ...
        TernaryBatch(decoder, currCodewords, symbolsPrior, ChannelType, H_nonsys_ind, H_nonsys_res, Q, p, q, ...
        codeWordsPerCell, repeatFactor, sequenceInd, sequenceRes, maxIterNaive, maxIterMsgPas, indG_sys, parCols);
end

% remove the codewords from the results file:
clear totalCodewords currCodewords CodewordsCell
% statistics:
BEP_Naive = NaN;
BEP_MsgPas = NaN;
if any(strcmp(decoder, ["2step" , "both"]))
    BEP_Naive = mean([stats2step.BEP_Naive]);
end
if any(strcmp(decoder, ["joint", "joint-LC" , "both"]))
    BEP_MsgPas = mean([statsJoint.BEP_MsgPas]);
end

TimeElapsed = toc;

% print BEP
fprintf('\tNaive BEP = %E, MsgPas BEP = %E\n', BEP_Naive, BEP_MsgPas);
fprintf('* - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *\n');
fprintf('Time elapsed: %f seconds\n', TimeElapsed)
fprintf("End of simulation\n");

if strcmp(decoder, "generateWords")
    % concatenate codewords to single file
    totalCodewords = vertcat(statsGeneral(:).codewords);
    messageIndLen = mean([statsGeneral.messageIndLen]);
    messageResLen = mean([statsGeneral.messageResLen]);
    nameOfFile = sprintf('Codewords/len%d_Ri0%.0f_Rr0%.0f_%s.mat',...
            n,100*rate_ind_actual,100*rate_res_actual,string(simStartTime));
    save(nameOfFile, 'totalCodewords', 'messageIndLen', 'messageResLen', 'id', 'seed');
else
% Save data to .mat file
save(sprintf('%s/len%d_logp%g_logq%g_LDPC_0%.0f_0%.0f_%s.mat',...
            ResultsFolder,n,log_p,log_q,100*rate_ind_actual,100*rate_res_actual,string(simStartTime)));
end

end
%  ------------------------------------------------------------------------
% internal functions:

function [statsJoint, stats2step, statsGeneral] = TernaryBatch(decoder, codewords, symbolsPrior, ChannelType, H_nonsys_ind, H_nonsys_res, Q, p, q, codeWordsPerCell, ...
          repeatFacor, sequenceInd, sequenceRes, maxIterNaive, maxIterMsgPas, indG_sys, parCols)
    % Initializatoins:
    batchSize = codeWordsPerCell * repeatFacor;
    if strcmp(decoder,"generateWords")
        codewords = zeros(batchSize,size(H_nonsys_ind,2),'uint8');
    end
    statsJoint = struct;
    stats2step = struct;
    statsGeneral = struct;
    if any(strcmp(decoder, ["2step" , "both"]))
        BEP_Naive_vec = ones(1,batchSize);
        BEPind_Naive_vec = ones(1,batchSize);
        numIterNaiveInd_vec = zeros(1, batchSize);
        numIterNaiveRes_vec = zeros(1, batchSize);
        SER_Naive_vec = ones(1,batchSize);
    end

    if any(strcmp(decoder, ["joint", "joint-LC" , "both"]))
        BEP_MsgPas_vec = ones(1,batchSize);
        BEPind_MsgPas_vec = ones(1,batchSize);
        numIterMsgPas_vec = zeros(1, batchSize);
        SER_MsgPas_vec = ones(1,batchSize);
    end

    messageIndLength_vec = zeros(1, codeWordsPerCell);
    messageResLength_vec = zeros(1, codeWordsPerCell);
    tUpActual_vec = zeros(1, batchSize);
    tDownActual_vec = zeros(1, batchSize);
    iter_sim = 0;

    if batchSize > 0
        if any(strcmp(decoder, ["joint", "joint-LC" , "both"]))
            lowComplex = strcmp(decoder,"joint-LC");
            MsgPasDec = BuildMsgPasDecoder(symbolsPrior, H_nonsys_ind, H_nonsys_res, p, q, maxIterMsgPas, sequenceInd, sequenceRes, lowComplex);
        end
        if any(strcmp(decoder, ["2step" , "both"]))
            NaiveIndDec = BuildNaiveIndDecoder(H_nonsys_ind, p, q, maxIterNaive);
        end
        
        for iter_sim = 1:codeWordsPerCell
            % - % - % Encoding: % - % - % 
            if isempty(codewords) || strcmp(decoder,"generateWords")
                [CodewordComb, ~, ~, messageInd, messageRes] =  ...
                    ternary_enc_LDPCLDPC(gf(H_nonsys_ind,1), gf(H_nonsys_res,1), indG_sys, parCols);
                % - % - % Encoding end % - % - %
                messageIndLength_vec(iter_sim) = length(messageInd);
                messageResLength_vec(iter_sim) = length(messageRes);
                if strcmp(decoder,"generateWords")
                    codewords(iter_sim,:) = uint8(CodewordComb);
                    continue
                end
            else
                CodewordComb = double(codewords(iter_sim,:));
            end
            % - % - % Channel (asymmetric one2all): % - % - % 
            for iter_error = 1:repeatFacor
                batch_sim = (iter_sim-1) * repeatFacor + iter_error;
                ChannelOut = asymmchannel(CodewordComb, Q, ChannelType, q, p);
                tIndActual = sum((ChannelOut ~= 0) ~= (CodewordComb ~= 0));
                tResActual = sum((ChannelOut == 2) ~= (CodewordComb == 2));
                tUpActual_vec(batch_sim) = sum(ChannelOut>CodewordComb);
                tDownActual_vec(batch_sim) = sum(ChannelOut<CodewordComb);
                % - % - % Channel end % - % - % 
                
                % - % - % Decoding: % - % - %
                if any(strcmp(decoder, ["2step" , "both"]))
                    [decCodewordRM_Naive, ~, numIterNaiveInd_vec(batch_sim), ...
                        numIterNaiveRes_vec(batch_sim)]  =  ...
                        NaiveDecoder(ChannelOut, NaiveIndDec, H_nonsys_res, CodewordComb > 0);
                end
                if any(strcmp(decoder, ["joint", "joint-LC" , "both"]))
                    [decCodewordRM_MsgPas, ~, ~, numIterMsgPas_vec(batch_sim)] =  ...
                        MsgPasDec.decode(ChannelOut);
                end
                % - % - % Decoding end % - % - % 
                % - % - % BEP % - % - % 
             
                % 1. Standard 2-step decoder:
                if any(strcmp(decoder, ["2step" , "both"]))
                    if isequal(decCodewordRM_Naive(:) > 0,CodewordComb(:) > 0)
                        BEPind_Naive_vec(batch_sim) = 0;
                    end
            
                    if isequal(decCodewordRM_Naive(:),CodewordComb(:))
                        BEP_Naive_vec(batch_sim) = 0;
                    end
                    SER_Naive_vec(batch_sim) = mean(decCodewordRM_Naive ~= CodewordComb);

                end
                % 2. Interleaved iterations in message-passing:
                if any(strcmp(decoder, ["joint", "joint-LC" , "both"]))            
                    if isequal(decCodewordRM_MsgPas(:) > 0,CodewordComb(:) > 0)
                        BEPind_MsgPas_vec(batch_sim) = 0;
                    end   
            
                    if isequal(decCodewordRM_MsgPas(:),CodewordComb(:))
                        BEP_MsgPas_vec(batch_sim) = 0;
                    end
                    SER_MsgPas_vec(batch_sim) = mean(decCodewordRM_MsgPas ~= CodewordComb);
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

    if strcmp(decoder,"generateWords")
    % save codewords mode:
        statsGeneral.codewords = codewords;
    end

    % joint decoder stats:
    if any(strcmp(decoder, ["joint", "joint-LC" , "both"]))            
        statsJoint.BEP_MsgPas = mean(BEP_MsgPas_vec);
        statsJoint.BEPind_MsgPas = mean(BEPind_MsgPas_vec);
        statsJoint.SER_MsgPas = mean(SER_MsgPas_vec);
        statsJoint.maxTrueIterMsgPas = max(max(numIterMsgPas_vec(BEP_MsgPas_vec == 0)),0);
        statsJoint.meanTrueIterMsgPas =  max(mean(numIterMsgPas_vec(BEP_MsgPas_vec == 0)),0);
        statsJoint.meanFalseIterMsgPas =  max(mean(numIterMsgPas_vec(BEP_MsgPas_vec == 1)),0);
    end
    % 2-step decoder stats:
    if any(strcmp(decoder, ["2step" , "both"]))
        % BEP
        stats2step.BEP_Naive = mean(BEP_Naive_vec);
        stats2step.BEPind_Naive = mean(BEPind_Naive_vec);
        stats2step.SER_Naive = mean(SER_Naive_vec);
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
