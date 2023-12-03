function plotGraphFromFiles_v2(matchedString, path)
    arguments
        matchedString string = ""
        path string = "./Results/256sep"
    end
    addpath(genpath("./"));
    files = dir(path);
    
    dirFlags = [files.isdir];
    subDirs = files(dirFlags);
    subDirsNames = {subDirs(3:end).name};
    if ~strcmp(matchedString,"")
        subDirsNames = subDirsNames(contains(subDirsNames, matchedString));
    end
    for i=1:length(subDirsNames)
        subDir = subDirsNames{i};
        plotGraphFromFilesAux(subDir, path);
    end
end


function plotGraphFromFilesAux(subDir, path)
    
    folderPath_up = fullfile(path,subDir);
    files_up = dir(folderPath_up);
    dirFlags = [files_up.isdir];
    subDirs = files_up(dirFlags);
    subDirsNames = {subDirs(3:end).name};
    for j=1:length(subDirsNames) % j=1:3 because 3 sequences
        subDir2 = subDirsNames{j};
        folderPath = fullfile(folderPath_up,subDir2);
        addpath(genpath(folderPath));
    
        % Get a list of all files in the folder
        files = dir(fullfile(folderPath, '*.mat'));
        p = 10.^(load(folderPath + "/pq.mat").log_p);
        q = 10.^(load(folderPath + "/pq.mat").log_q);
        [~,Q] = meshgrid(p,q);
    
    
        % Initialize arrays to store (n, log_p) pairs
        BEP_Naive_Values{j} = NaN(size(Q));
        BEP_MsgPas_Values{j} = NaN(size(Q));
        
        % Variables to extract from the struct in the file
        vars = {"BEP_MsgPas", "BEP_Naive", "p", "q", "stats","n","rate_ind_actual","rate_res_actual",...
            "sequenceInd","sequenceRes"};
        disp("loading from:" + subDir);
        disp("loading " + length(q) + " files" )
        sequenceStr = {"[1,1]","[2,2]","[4,2]"};

    
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

            BEP_Naive_Values{j}(r,c) = data.BEP_Naive;
            BEP_MsgPas_Values{j}(r,c) = data.BEP_MsgPas;
        end
        sequence = [data.sequenceInd,data.sequenceRes];
        if all(sequence == [1,1])
            js(j) = 1;
        elseif all(sequence == [2,2])
            js(j) = 2;
        elseif all(sequence == [4,2])
            js(j) = 3;
        end

        if i ~= (length(q) + 1)
            disp("missing " + (length(q)+1-i) + " files");
        end        
    end

    for k = 1:length(p)
            curr_p = p(k);
            x_ax_vals = q + curr_p;
            BEP_Naive = [BEP_Naive_Values{:}];
            BEP_Naive = mean(BEP_Naive,2);

            
            % Plot the graph
            fig = figure;
            semilogy(x_ax_vals, max(eps,BEP_Naive,"includenan"),'LineWidth',2);
            hold on
            nums = 1:3;
            for i=1:length(BEP_MsgPas_Values)
                BEP_MsgPas = BEP_MsgPas_Values{nums(js == i)};
                BEP_MsgPas = BEP_MsgPas(:,k);
                semilogy(x_ax_vals, max(eps,BEP_MsgPas,"includenan"),'LineWidth',1.5);
            end
            xlabel(sprintf("q+p (up+down) for p=%.2E",curr_p));
            ylabel('BER');
            ylim([1e-2,1]);
            xlim([0,0.2]);
        
            len = data.n;
            RateInd = round(data.rate_ind_actual * 100) / 100;
            RateRes = round(data.rate_res_actual * 100) / 100;
            currTitle1 = "$Len = " + len + "$";
            currTitle2 = "$Rates : [" + RateInd + "," + RateRes + "]$";
            title({currTitle1, currTitle2},'Interpreter', 'latex', 'FontSize', 14);
            legend('Naive', ...
                'MsgPas ' + sequenceStr{1}, ...
                'MsgPas ' + sequenceStr{2}, ...
                'MsgPas ' + sequenceStr{3}, ...
                'Location', 'southeast');
            % saveas(fig,fullfile("./Figures/fig128",subDir + ".fig"));
    
     end

end