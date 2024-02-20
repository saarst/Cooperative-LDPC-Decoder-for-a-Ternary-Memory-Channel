function plotGraphFromFiles(matchedString, path, savePath, format)
    arguments
        matchedString string = "TriLDPC_d20021511_n128_si2_sr2_Ri05_Rr05"
        path string = "./Results/"
        savePath string = "./Figures/"
        format string = "fig"
    end
    addpath(genpath("./"));
    files = dir(path);
    status = mkdir(savePath);
    dirFlags = [files.isdir];
    subDirs = files(dirFlags);
    subDirsNames = {subDirs(3:end).name};
    if ~strcmp(matchedString,"")
        subDirsNames = subDirsNames(contains(subDirsNames, matchedString));
    end
    for i=1:length(subDirsNames)
        subDir = subDirsNames{i};
        plotGraphFromFilesAux(subDir, path, savePath, format);
    end
end


function plotGraphFromFilesAux(subDir, path, savePath, format)
    folderPath = fullfile(path,subDir);
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
    vars = {"decoder", "BEP_MsgPas", "BEP_Naive", "p", "q", "statsGeneral", "stats2step", "statsJoint", "n","rate_ind_actual","rate_res_actual"};
    disp("loading from:" + subDir);
    disp("loading " + length(q) + " files" )

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
        if any(strcmp(data.decoder, ["2step", "both"]))
            BEP_Naive = data.BEP_Naive;
            BEPind_Naive = mean([data.stats2step.BEPind_Naive]);
            maxTrueIterNaive = max([data.stats2step.maxTrueIterNaiveInd]);
            if isempty(maxTrueIterNaive)
                maxTrueIterNaive = 0;
            end
            BEP_Naive_Values(r,c) = BEP_Naive;
            BEPind_Naive_Values(r,c) = BEPind_Naive;
        end
        if any(strcmp(data.decoder, ["joint","joint-LC", "both"]))
            BEP_MsgPas = data.BEP_MsgPas;
            BEPind_MsgPas = mean([data.statsJoint.BEPind_MsgPas]);
            maxTrueIterMsgPas = max([data.statsJoint.maxTrueIterMsgPas]);
            if isempty(maxTrueIterMsgPas)
                maxTrueIterMsgPas = 0;
            end
            BEP_MsgPas_Values(r,c) = BEP_MsgPas;
            BEPind_MsgPas_Values(r,c) = BEPind_MsgPas;            
        end

        
       
        % disp(i + ". with (" + data.p  + "," + data.q + ") " +  ": maxIterMsgPas : " + maxTrueIterMsgPas + ...
             % ". maxIterNaive : " + maxTrueIterNaive);
        % Append the values to the arrays


    end
    if i ~= (length(q) + 1)
        disp("missing " + (length(q)+1-i) + " files");
    end
    % sort:
    for k = 1:length(p)
        curr_p = p(k);
        x_ax_vals = q + curr_p;
        fig = figure;        
        if any(strcmp(data.decoder, ["2step", "both"]))
            BEP_Naive = BEP_Naive_Values(:,k);
            plot(x_ax_vals, max(eps,BEP_Naive,"includenan"),'LineWidth',2);    
        end
        hold on
        if any(strcmp(data.decoder, ["joint","joint-LC", "both"]))
            BEP_MsgPas = BEP_MsgPas_Values(:,k);
            plot(x_ax_vals, max(eps,BEP_MsgPas,"includenan"),'LineWidth',2);            
        end
                
        xlabel(sprintf("q+p (up+down) for p=%.2E",curr_p));
        ylabel('BLER');
    
    
        [~,folderName,~] = fileparts(folderPath);
        nameSplitted = strsplit(folderName,"_");
        len = nameSplitted(3).extractAfter(1);
        seqInd = nameSplitted(4).extractAfter(2);
        seqRes = nameSplitted(5).extractAfter(2);
        RateInd = round(data.rate_ind_actual * 100) / 100;
        RateRes = round(data.rate_res_actual * 100) / 100;
        currTitle1 = "$Len = " + len + "$";
        currTitle2 = "$Sequence : [" + seqInd + "," + seqRes + "]" + ...
                    ", Rates : [" + RateInd + "," + RateRes + "]$";
        title({currTitle1, currTitle2},'Interpreter', 'latex', 'FontSize', 14);
        if strcmp(data.decoder, "joint")
            legend('Joint (ours)', 'Location', 'southeast');
        elseif strcmp(data.decoder, "2step")
            legend('2-Step (Prior)', 'Location', 'southeast');
        elseif strcmp(data.decoder, "both")
            legend('2-Step (Prior)', 'Joint (ours)', 'Location', 'southeast');
        elseif strcmp(data.decoder, "joint-LC")
            legend('Joint-LC (ours)', 'Location', 'southeast');
        end

        % saveas(fig,fullfile(savePath,subDir + "." + format));

    end
    % close all

end