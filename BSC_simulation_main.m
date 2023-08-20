function BSC_simulation_main(n, log_p, rate, num_iter_sim, ResultsFolder)
arguments
    n (1,1) {mustBeInteger,mustBePositive} = 16
    log_p (1,1) {mustBeNegative} = -1
    rate (1,1) {mustBeLessThanOrEqual(rate,1), mustBeGreaterThanOrEqual(rate,0)} = 0.25
    num_iter_sim (1,1) {mustBeInteger, mustBePositive} = 10^(-log_p + 2);
    ResultsFolder = "./Results"
end
tic
clc
disp("BSC LDPC simulation begin");
disp("Parameters:")
fprintf("n = %d, log_p = %g, rate = %f, num_iter_sim = %g, resultsFolder = '%s' \n", ...
             n,  log_p,      rate,      num_iter_sim,      ResultsFolder);
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
Q   = 2;   % alphabet size
ChannelType     = "random"; % "random" / "upto"
maxIter = 50;

%% Construct LDPC codes
addpath(fullfile('.','gen_par_mats'));
addpath(genpath(fullfile('.','LDPC')));

% construct indicator code
filenameLDPC = sprintf('n%d_R0%.0f.mat',n,100*rate);
filepathLDPC = fullfile('.','LDPCcode',filenameLDPC);
if ~exist(filepathLDPC,'file')
    try
        [Lam, probInd] = GenerateDist(15,rate); % Generate distributions with requested rate of r
        LDPCWrapper('GenerateIrregular',n, Lam, probInd, filepathLDPC); % Generate parity matrix for code length of n
        SavePartiyMat(filepathLDPC); % Save MAT file
    catch err
        disp(err.getReport);
        return;
    end
end
load(filepathLDPC,"H","Hnonsys"); % H, Hnonsys are the parity-check matrices of the code
H_sys = full(H);
% what is this for?
% H_nonsys_ind = full(Hnonsys);
% enc_ind = comm.LDPCEncoder('ParityCheckMatrix',Hnonsys); 
% dec_ind = comm.LDPCDecoder('ParityCheckMatrix',Hnonsys); % hard-decision message-passing decoder
rate_actual = (n-size(H_sys,1)) / n;

rmpath(fullfile('.','gen_par_mats'));
fprintf("Loading Files is complete\n");


%% Probability of correcting (p,q) errors with LDPC-LDPC code
fprintf('* - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *\n');

% Save start time
simStartTime = datetime;
simStartTime.Format = 'yyyy-MM-dd_HH-mm-ss-SSS';

% create parllel pool
c = parcluster('local');
delete(gcp('nocreate'));
parpool(c,min([24*12,c.NumWorkers])); % Create a parallel pool with the default settings
% Get information about the parallel pool
NumWorkers = gcp().NumWorkers;
fprintf("num of workers = %g \n", NumWorkers);

% Initialize results arrays
batchSize = ceil(num_iter_sim / NumWorkers);
num_iter_sim = batchSize * NumWorkers;
stats = BSCBatch([], [], [], [], [], []);
stats = repmat(stats,[1,NumWorkers]);

% main run:
parfor iter_thread = 1 : NumWorkers
    stats(iter_thread) =  ...
        BSCBatch(ChannelType, H_sys, Q, p, batchSize, maxIter);
end
delete(gcp)
delete(c)
% statistics:
BEP = mean([stats.BEP]);

% print BEP
fprintf('\tBEP = %E', BEP);
fprintf('* - * - * - * - * - * - * - * - * - * - * - * - * - * - * - *\n');
fprintf("End of simulation\n");
TimeElapsed = toc;

% Save data to .mat file
save(sprintf('%s/len%d_logp%g_LDPC_0%.0f_nIterSim%d_%s.mat',...
            ResultsFolder,n,log_p,100*rate_actual,num_iter_sim,string(simStartTime)));

end
%  ------------------------------------------------------------------------
% internal functions:

function stats = BSCBatch(ChannelType, H_sys, Q, p, batchSize, ...
                              maxIter)
    % Initializatoins:
    BEP_vec = ones(1,batchSize);
    messageLength_vec = zeros(1, batchSize);
    numIter_vec = zeros(1, batchSize);

    if batchSize > 0
        Dec = BuildBSCDecoder(H_sys, p, maxIter);
        for iter_sim = 1:batchSize
            % - % - % Encoding: % - % - % 
            [Codeword, message] = BSC_enc_LDPCLDPC(gf(H_sys,1));
            % - % - % Encoding end % - % - %
            messageLength_vec(iter_sim) = length(message);
            % - % - % Channel (symetric one2all): % - % - % 
            ChannelOut = BSCchannel(Codeword, Q, ChannelType, p);
            t_Actual = sum(ChannelOut ~= Codeword);
            % - % - % Channel end % - % - % 
            
            % - % - % Decoding: % - % - % 
            [decCodeword, ~, ~, numIter_vec(iter_sim)] = Dec.decode(ChannelOut);
            % - % - % Decoding end % - % - % 
            % - % - % BEP % - % - % 
         
            % 1. Standard 2-step decoder:
    
            if isequal(decCodeword(:),Codeword(:))
                BEP_vec(iter_sim) = 0;
            end
        end
    end
    % - % - % BEP end % - % - %
    % mean messageLength
    stats.messageLen = mean(messageLength_vec);
    % BEP
    stats.BEP = mean(BEP_vec);
    %max iters
    stats.maxTrueIter = max(numIter_vec(BEP_vec == 0));
    % mean of true iters
    stats.meanTrueIter = mean(numIter_vec(BEP_vec == 0));
    % mean of false iters
    stats.meanFalseIter = mean(numIter_vec(BEP_vec == 1));


end
