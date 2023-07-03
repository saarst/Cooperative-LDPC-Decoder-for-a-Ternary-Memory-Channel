function plotGraphFromFiles()
    addpath(genpath("./Results"));
    files = dir("./Results");
    
    dirFlags = [files.isdir];
    subDirs = files(dirFlags);
    subDirsNames = {subDirs(3:end).name};
    for i=1:length(subDirsNames)
        subDir = subDirsNames{i};
        plotGraphFromFilesAux(fullfile("./Results",subDir));
    end
end


function plotGraphFromFilesAux(folderPath)
    % plotGraphFromFiles - Plot a graph of (n, log_p) pairs from files in a folder
    %   folderPath: string, optional, path to the folder containing the files (default: "./Results")

    arguments
        folderPath string = "./Results" % Default folder path
    end
    
    addpath(genpath(folderPath));
    
    % Get a list of all files in the folder
    files = dir(fullfile(folderPath, '*.mat'));

    % Initialize arrays to store (n, log_p) pairs
    BEP_Naive_Values = [];
    BEP_MsgPas_Values = [];
    
    BEPind_Naive_Values = [];
    BEPind_MsgPas_Values = [];
    logPValues = [];

    % Variables to extract from the struct in the file
    vars = {"BEP_MsgPas", "BEP_Naive", "log_p", "BEPind_Naive", "BEPind_MsgPas", "maxTrueIterMsgPas", "maxTrueIterNaive"};

    % Iterate over each file in the folder
    for i = 1:numel(files)
        % Load the file and extract the struct
        filePath = fullfile(folderPath, files(i).name);
        data = load(filePath,vars{:});
        
        % Extract the log_p and BEP values from the struct
        logP = data.log_p;
        BEP_Naive = data.BEP_Naive;
        BEP_MsgPas = data.BEP_MsgPas;
        BEPind_MsgPas = data.BEPind_MsgPas;
        BEPind_Naive = data.BEPind_Naive;
        maxTrueIterMsgPas = data.maxTrueIterMsgPas;
        maxTrueIterNaive = data.maxTrueIterNaive;
        disp("with" + logP  + ": maxIterMsgPas : " + maxTrueIterMsgPas + ". maxIterNaive : " + maxTrueIterNaive);
        % Append the values to the arrays
        BEP_Naive_Values = [BEP_Naive_Values, BEP_Naive];
        BEP_MsgPas_Values = [BEP_MsgPas_Values, BEP_MsgPas];
        BEPind_Naive_Values = [BEPind_Naive_Values, BEPind_Naive];
        BEPind_MsgPas_Values = [BEPind_MsgPas_Values, BEPind_MsgPas];
        logPValues = [logPValues, logP];
    end
    
    % Plot the graph
    figure;
    semilogy(logPValues, BEP_Naive_Values);
    hold on
    semilogy(logPValues, BEPind_Naive_Values);
    hold on
    semilogy(logPValues, BEP_MsgPas_Values);
    hold on
    semilogy(logPValues, BEPind_MsgPas_Values);
    xlabel('log_p');
    ylabel('BEP');
    folderPath = "./Results/d14_6_TriLDPC_12e3_r8_s4_2";
    [~,folderName,~] = fileparts(folderPath);
    nameSplitted = strsplit(folderName,"_");
    ratioString = nameSplitted(5); ratio = extractAfter(ratioString,1);
    seq1String = nameSplitted(6); seq1 = extractAfter(seq1String,1);
    seq2 = nameSplitted(7);
    currTitle = "$Iter : " + nameSplitted(4) + ",  \frac{\mathrm{Up}}{\mathrm{Down}} = " + ratio +  ", sequence : [" + seq1 + "," + seq2 + "]$";
    title(currTitle,'Interpreter', 'latex', 'FontSize', 22);
    legend('BEP Naive',  'BEP ind Naive', 'BEP MsgPas', 'BEP ind MsgPas', 'Location', 'northwest');
end