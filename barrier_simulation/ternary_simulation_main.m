clear

seed = sum(100*clock);
reset(RandStream.getGlobalStream,seed)

filepath = cd(fileparts(mfilename('fullpath')));
cd(filepath);

%% User-defined parameters
% encoder parameters
n               = 256;
rate_ind        = 0.4;
rate_res        = 0.5;
% Simulation parameters
num_iter_sim    = 2e3; % iterations in simulations
p               = 0.001; % downward error probability, p
q2              = 0.03/2; % upward error probability, q/2
ChannelType     = "random"; % "random" / "upto"
% Other parameters
nIterBetweenFileSave = 50;

%% Construct LDPC codes
addpath('.\gen_par_mats');

% construct indicator code
filenameLDPC = sprintf('n%d_R0%.0f.mat',n,100*rate_ind);
filepathLDPC = fullfile('.','LDPCcode',filenameLDPC);
if ~exist(filepathLDPC,'file')
    try
        [Lam,prob] = GenerateDist(15,rate_ind); % Generate distributions with requested rate of r
        LDPCWrapper('GenerateIrregular',n,Lam,p,filepathLDPC); % Generate parity matrix for code length of n
        SavePartiyMat(filepathLDPC); % Save MAT file
    catch err
        disp(err.getReport);
        return;
    end
end
load(filepathLDPC); % H, Hnonsys are the parity-check matrices of the code
H_sys_ind = full(H);
H_nonsys_ind = full(Hnonsys);
enc_ind = comm.LDPCEncoder('ParityCheckMatrix',Hnonsys); 
dec_ind = comm.LDPCDecoder('ParityCheckMatrix',Hnonsys); % hard-decision message-passing decoder
rate_ind_actual = (n-size(H_sys_ind,1)) / n;

% construct residual code
filenameLDPC = sprintf('n%d_R0%.0f.mat',n,100*rate_res);
filepathLDPC = fullfile('.','LDPCcode',filenameLDPC);
if ~exist(filepathLDPC,'file')
    try
        [Lam,prob] = GenerateDist(15,rate_res); % Generate distributions with requested rate of r
        LDPCWrapper('GenerateIrregular',n,Lam,p,filepathLDPC); % Generate parity matrix for code length of n
        SavePartiyMat(filepathLDPC); % Save MAT file
    catch err
        disp(err.getReport);
        return;
    end
end
load(filepathLDPC); % H, Hnonsys are the parity-check matrices of the code
H_sys_res = full(H);
H_nonsys_res = full(Hnonsys);
enc_res = comm.LDPCEncoder('ParityCheckMatrix',Hnonsys); 
dec_res = comm.LDPCDecoder('ParityCheckMatrix',Hnonsys); % hard-decision message-passing decoder
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
    ChannelOut = asymmchannel(CodewordComb,q,ChannelType,tUp,tDown);
    tUp_Actual = sum(ChannelOut>CodewordComb);
    tDown_Actual = sum(ChannelOut<CodewordComb);
    % - % - % Channel end % - % - % 
    
    % - % - % Decoding: % - % - % 
    % TODO: 
    % [decCodewordRM_Naive, success]  = NaiveDecoder(ChannelOut, H_sys_ind, H_sys_res, p, 2*q2, NaiveDecoderParams);
    % [decCodewordRM_MsgPas, success] = MsgPasDecoder(ChannelOut, H_sys_ind, H_sys_res, p, 2*q2, MsgPasDecoderParams);
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
save(sprintf('./Results/len%d_p%.5f_q%.5f_LDPC_0%.0f_0%.0f_Joint_nIterSim%d_%s_Seed%.2f.mat',...
            n,p,2*q2,100*rate_ind_actual,100*rate_res_actual,num_iter_sim,string(simStartTime),seed));
delete(sprintf('./Results/len%d_p%.5f_q%.5f_LDPC_0%.0f_0%.0f_Joint_nIterSim%d_%s_Seed%.2f_partial.mat',...
            n,p,2*q2,100*rate_ind_actual,100*rate_res_actual,num_iter_sim,string(simStartTime),seed));

%  ------------------------------------------------------------------------