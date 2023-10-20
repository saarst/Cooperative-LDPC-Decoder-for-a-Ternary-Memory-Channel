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
        plotGraphFromFilesAux(subDir);
    end
end


function plotGraphFromFilesAux(subDir)
    folderPath = fullfile("./Results",subDir);
    addpath(genpath(folderPath));
    
    % Get a list of all files in the folder
    files = dir(fullfile(folderPath, '*.mat'));
    p = 10.^(load(folderPath + "/pq.mat").log_p);
    q = 10.^(load(folderPath + "/pq.mat").log_q);
    [~,Q] = meshgrid(p,q);


    % Initialize arrays to store (n, log_p) pairs
    BEP_Naive_Values = NaN(size(Q));
    BEP_MsgPas_Values = NaN(size(Q));
    
    BEPind_Naive_Values = NaN(size(Q));
    BEPind_MsgPas_Values = NaN(size(Q));
    
    % Variables to extract from the struct in the file
    vars = {"BEP_MsgPas", "BEP_Naive", "p", "q", "stats"};

    % Iterate over each file in the folder
    for i = 1:numel(files)
        % Load the file and extract the struct
        if strcmp(files(i).name, 'pq.mat')
            continue
        end
        filePath = fullfile(folderPath, files(i).name);
        data = load(filePath,vars{:});
        
        % Extract the log_p and BEP values from the struct
        [~,c] = min(abs(p - data.p));
        [~,r] = min(abs(q - data.q));

        BEP_Naive = data.BEP_Naive;
        BEP_MsgPas = data.BEP_MsgPas;
        BEPind_MsgPas = mean([data.stats.BEPind_MsgPas]);
        BEPind_Naive = mean([data.stats.BEPind_Naive]);
        maxTrueIterMsgPas = max([data.stats.maxTrueIterMsgPas]);
        maxTrueIterNaive = max([data.stats.maxTrueIterNaiveInd]);
        if isempty(maxTrueIterMsgPas)
            maxTrueIterMsgPas = 0;
        end
        if isempty(maxTrueIterNaive)
            maxTrueIterNaive = 0;
        end
        disp("with (" + data.p  + "," + data.q + ") " +  ": maxIterMsgPas : " + maxTrueIterMsgPas + ...
             ". maxIterNaive : " + maxTrueIterNaive);
        % Append the values to the arrays

        BEP_Naive_Values(r,c) = BEP_Naive;
        BEP_MsgPas_Values(r,c) = BEP_MsgPas;
        BEPind_Naive_Values(r,c) = BEPind_Naive;
        BEPind_MsgPas_Values(r,c) = BEPind_MsgPas;
    end
    % sort:
    for k = 1:length(p)
        curr_p = p(k);
%         [x_ax_vals, xIdxs] = sort(q(:,2),"ascend"); % q as x axis
        x_ax_vals = q + curr_p;
        BEP_Naive = BEP_Naive_Values(:,k);
        BEP_MsgPas = BEP_MsgPas_Values(:,k);
        BEPind_Naive = BEPind_Naive_Values(:,k);
        BEPind_MsgPas = BEPind_MsgPas_Values(:,k);
        
        % Plot the graph
        fig = figure;
        plot(x_ax_vals, max(eps,BEP_Naive,"includenan"),'LineWidth',2);
        hold on
%         plot(x_ax_vals, max(eps,BEPind_Naive) );
%         hold on
        plot(x_ax_vals, max(eps,BEP_MsgPas,"includenan"),'LineWidth',2);
%         hold on
%         plot(x_ax_vals, max(eps,BEPind_MsgPas) );
        xlabel(sprintf("q+p (up+down) for p=%.2E",curr_p));
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
%         legend('BEP Naive',  'BEP ind Naive', 'BEP MsgPas', 'BEP ind MsgPas', 'Location', 'northwest');
        legend('BEP Naive', 'BEP MsgPas', 'Location', 'northwest');
        % saveas(fig,fullfile("./Figures",subDir));
        saveas(fig,fullfile("./Figures",subDir + ".svg"));
        close all

    end
end