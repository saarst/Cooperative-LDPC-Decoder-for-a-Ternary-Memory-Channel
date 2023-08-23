function plotBSCGraphFromFiles(matchedString)
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
    BEPValues = [];

    parr = [];


    % Variables to extract from the struct in the file
    vars = {"BEP", "p", "stats"};

    % Iterate over each file in the folder
    for i = 1:numel(files)
        % Load the file and extract the struct
        filePath = fullfile(folderPath, files(i).name);
        data = load(filePath,vars{:});
        
        % Extract the values from the struct
        p = data.p;
        BEP = data.BEP;
        maxTrueIter = max([data.stats.maxTrueIter]);
        if isempty(maxTrueIter)
            maxTrueIter = 0;
        end
        disp("with " + p  + ": maxIter : " + maxTrueIter );
        % Append the values to the arrays
        BEPValues = [BEPValues, BEP];
        parr = [parr; p];
    end
    % sort:
    [x_ax_vals, xIdxs] = sort(parr,"ascend"); % q as x axis
    BEPValues = BEPValues(xIdxs);
    
    % Plot the graph
    figure;
    plot(x_ax_vals, max(eps,BEPValues) );
    xlabel("p");
    ylabel('BEP');


    [~,folderName,~] = fileparts(folderPath);

    title(folderName, 'FontSize', 14);
end