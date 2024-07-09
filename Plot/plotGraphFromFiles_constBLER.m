function plotGraphFromFiles_constBLER(matchedString, path, savePath, format, target)
    arguments
        matchedString string = "TriLDPC_d02051011_n192_si6_sr2_Ri08_Rr05"
        path string = "./Results/"
        savePath string = "./Figures/"
        format string = "fig"
        target  = 10^(-4)
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
    ps = []; qs_Naive = []; qs_MsgPas = [];
    for i=1:length(subDirsNames)
        subDir = subDirsNames{i};
        plotGraphFromFilesAux_constBLER(subDir, path, savePath, format, "BLER", target);

    end
 

end


function [p, q_Naive, q_MsgPas] = plotGraphFromFilesAux_constBLER(subDir, path, savePath, format, mode, target)
    folderPath = fullfile(path,subDir);
    addpath(genpath(folderPath));
    
    % Get a list of all files in the folder
    files = dir(fullfile(folderPath, '*.mat'));
    p = 10.^(load(folderPath + "/pq.mat").log_p);
    q = 10.^(load(folderPath + "/pq.mat").log_q);
    


    % Initialize arrays to store (n, log_p) pairs
    BEP_Naive_Values = NaN(size(q));
    BEP_MsgPas_Values = NaN(size(q));
    
    BEPind_Naive_Values = NaN(size(q));
    BEPind_MsgPas_Values = NaN(size(q));

    SER_Naive_Values = NaN(size(q));
    SER_MsgPas_Values = NaN(size(q));
    
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
        [~,r] = min(abs(q(:,c) - data.q));
        if any(strcmp(data.decoder, ["2step", "both"]))
            BEP_Naive = data.BEP_Naive;
            BEPind_Naive = mean([data.stats2step.BEPind_Naive]);
            SER_Naive = mean([data.stats2step.SER_Naive]);
            maxTrueIterNaive = max([data.stats2step.maxTrueIterNaiveInd]);
            if isempty(maxTrueIterNaive)
                maxTrueIterNaive = 0;
            end
            BEP_Naive_Values(r,c) = BEP_Naive;
            BEPind_Naive_Values(r,c) = BEPind_Naive;
            SER_Naive_Values(r,c) = SER_Naive;
        end
        if any(strcmp(data.decoder, ["joint","joint-LC", "both"]))
            BEP_MsgPas = data.BEP_MsgPas;
            BEPind_MsgPas = mean([data.statsJoint.BEPind_MsgPas]);
            SER_MsgPas = mean([data.statsJoint.SER_MsgPas]);
            maxTrueIterMsgPas = max([data.statsJoint.maxTrueIterMsgPas]);
            if isempty(maxTrueIterMsgPas)
                maxTrueIterMsgPas = 0;
            end
            BEP_MsgPas_Values(r,c) = BEP_MsgPas;
            BEPind_MsgPas_Values(r,c) = BEPind_MsgPas;
            SER_MsgPas_Values(r,c) = SER_MsgPas;
        end


    end
    
    q_Naive = NaN(size(p));
    q_MsgPas = NaN(size(p));
    q_MsgPas_interp = NaN(size(p));
    q_Naive_lims = NaN(length(p),2);
    q_MsgPas_lims = NaN(length(p),2);
    for k = 1:length(p)
        curr_p = p(k);
        x_ax_vals = q(:,k);
        if any(strcmp(data.decoder, ["2step", "both"]))
            if strcmp(mode,"BLER")
                Naive = BEP_Naive_Values(:,k);
            else
                Naive = SER_Naive_Values(:,k);
            end
            % q_Naive(k) = 10^(interp1(log10(Naive), log10(x_ax_vals), log10(target),"linear"));
            % q_Naive(k) = interp1(Naive, log10(x_ax_vals), target, "nearest");
            [~,target_nearest] = min(abs(Naive - target));
            q_Naive(k) = x_ax_vals(target_nearest);
            if (target_nearest == 1)
                q_Naive_lims(k,1) = q_Naive(k) / 10;
            else
                q_Naive_lims(k,1) = x_ax_vals(target_nearest - 1);
            end

            if (target_nearest == length(Naive))
                q_Naive_lims(k,2) = q_Naive(k) * 10;
            else
                q_Naive_lims(k,2) = x_ax_vals(target_nearest + 1);
            end

        end
        if any(strcmp(data.decoder, ["joint","joint-LC", "both"]))
            if strcmp(mode,"BLER")
                MsgPas = BEP_MsgPas_Values(:,k);
            else
                MsgPas = SER_MsgPas_Values(:,k);
            end
            q_MsgPas_interp(k) = 10.^(interp1(log10(MsgPas), log10(x_ax_vals), log10(target),"linear"));
            % q_MsgPas(k) = interp1(MsgPas , log10(x_ax_vals), target, "nearest");

            [nearest_BLER, target_nearest] = min(abs(MsgPas - target));
            q_MsgPas(k) = x_ax_vals(target_nearest);
            if ( (nearest_BLER == min(MsgPas)) && nearest_BLER > target )
                q_MsgPas_lims(k,1) = q_MsgPas(k) / 10;
                q_MsgPas_lims(k,2) = q_MsgPas(k);
            elseif ((nearest_BLER == max(MsgPas)) && nearest_BLER < target )
                q_MsgPas_lims(k,1) = q_MsgPas(k);
                q_MsgPas_lims(k,2) = q_MsgPas(k) * 10;
            elseif (nearest_BLER <= target)
                q_MsgPas_lims(k,1) = q_MsgPas(k);
                q_MsgPas_lims(k,2) = x_ax_vals(target_nearest + 1);
            elseif (nearest_BLER > target)
                q_MsgPas_lims(k,1) = x_ax_vals(target_nearest - 1);
                q_MsgPas_lims(k,2) = q_MsgPas(k);

            end


        end

    end
    [p, I] = sort(p);
    q_MsgPas = q_MsgPas(I);
    q_Naive = q_Naive(I);
    q_MsgPas_lims = q_MsgPas_lims(I,:);
    q_Naive_lims = q_Naive_lims(I,:);
    q_MsgPas_interp = q_MsgPas_interp(I);
    update = 0;
    if update
        save ("targetBLER_joint_1E-4","p" ,"q_MsgPas_lims");
        disp("saving");
    end
    fig = figure;
    loglog(p,q_MsgPas_interp,"LineWidth",2,"Marker","+")
    hold on
    loglog(p,q_Naive,"LineWidth",2,"Marker","o")
    legend("Msg Pas (ours)", "2 step (prior)")
    xlabel(sprintf("p(down) for %s=%E",mode,target));
    ylabel("q");
    grid on


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
    % paperStyle(fig,len,curr_p,RateInd,RateRes);
    % saveas(fig,fullfile(savePath,subDir + "." + format));
    % close all

end