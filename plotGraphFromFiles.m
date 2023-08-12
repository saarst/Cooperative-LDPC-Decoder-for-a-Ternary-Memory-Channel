function plotGraphFromFiles(matchedString)
    arguments
        matchedString string = ""
    end
    addpath(genpath("./"));
    files = dir("./Results");
    
    dirFlags = [files.isdir];
    subDirs = files(dirFlags);
    subDirsNames = {subDirs(3:end).name};
    if ~strcmp(matchedString,"")
        subDirsNames = subDirsNames(contains(subDirsNames, matchedString));
    end
    for i=1:length(subDirsNames)
        subDir = subDirsNames{i};
        plotGraphFromFilesAux(fullfile("./Results",subDir));
    end
end


function plotGraphFromFilesAux(folderPath)
    % plotGraphFromFiles - Plot a graph of (n, log_p) pairs from files in a folder
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
    pq = [];

    % Variables to extract from the struct in the file
    vars = {"BEP_MsgPas", "BEP_Naive", "p", "q", "stats"};

    % Iterate over each file in the folder
    for i = 1:numel(files)
        % Load the file and extract the struct
        filePath = fullfile(folderPath, files(i).name);
        data = load(filePath,vars{:});
        
        % Extract the log_p and BEP values from the struct
%         logP = data.log_p;
        p = data.p;
        q = data.q;
        BEP_Naive = data.BEP_Naive;
        BEP_MsgPas = data.BEP_MsgPas;
        BEPind_MsgPas = mean([data.stats.BEPind_MsgPas]);
        BEPind_Naive = mean([data.stats.BEPind_Naive]);
        maxTrueIterMsgPas = max([data.stats.maxTrueIterMsgPas]);
        maxTrueIterNaive = max([data.stats.maxTrueIterNaiveInd]);
        disp("with (" + p  + "," + q + ") " +  ": maxIterMsgPas : " + maxTrueIterMsgPas + ...
             ". maxIterNaive : " + maxTrueIterNaive);
        % Append the values to the arrays
        BEP_Naive_Values = [BEP_Naive_Values, BEP_Naive];
        BEP_MsgPas_Values = [BEP_MsgPas_Values, BEP_MsgPas];
        BEPind_Naive_Values = [BEPind_Naive_Values, BEPind_Naive];
        BEPind_MsgPas_Values = [BEPind_MsgPas_Values, BEPind_MsgPas];
%         logPValues = [logPValues, logP];
        pq = [pq; [p, q]];
    end
    % sort:
    [x_ax_vals, xIdxs] = sort(pq(:,2),"ascend"); % q as x axis
    x_ax_vals = x_ax_vals + pq(1,1);
    BEP_Naive_Values = BEP_Naive_Values(xIdxs);
    BEP_MsgPas_Values = BEP_MsgPas_Values(xIdxs);
    BEPind_Naive_Values = BEPind_Naive_Values(xIdxs);
    BEPind_MsgPas_Values = BEPind_MsgPas_Values(xIdxs);
    
    % Plot the graph
    figure;
    plot(x_ax_vals, max(eps,BEP_Naive_Values) );
    hold on
    plot(x_ax_vals, max(eps,BEPind_Naive_Values) );
    hold on
    plot(x_ax_vals, max(eps,BEP_MsgPas_Values) );
    hold on
    semilogy(x_ax_vals, max(eps,BEPind_MsgPas_Values) );
    xlabel(sprintf("q+p (up+down) for p=%.2E",p));
    ylabel('BEP');


    [~,folderName,~] = fileparts(folderPath);
    nameSplitted = strsplit(folderName,"_");
    len = nameSplitted(3).extractAfter(1);
    seqInd = nameSplitted(4).extractAfter(2);
    seqRes = nameSplitted(5).extractAfter(2);
    RateInd = nameSplitted(6).extractAfter(2).insertAfter("0",".");
    RateRes = nameSplitted(7).extractAfter(2).insertAfter("0",".");
    currTitle1 = "$Len = " + len + "$";
    currTitle2 = "$Sequence : [" + seqInd + "," + seqRes + "]" + ...
                ", Rates : [" + RateInd + "," + RateRes + "]$";
    title({currTitle1, currTitle2},'Interpreter', 'latex', 'FontSize', 14);
    legend('BEP Naive',  'BEP ind Naive', 'BEP MsgPas', 'BEP ind MsgPas', 'Location', 'northwest');
end