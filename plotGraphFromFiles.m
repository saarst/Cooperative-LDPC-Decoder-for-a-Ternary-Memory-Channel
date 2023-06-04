function plotGraphFromFiles(folderPath)
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
    logPValues = [];

    % Variables to extract from the struct in the file
    vars = {"BEP_MsgPas", "BEP_Naive", "log_p"};

    % Iterate over each file in the folder
    for i = 1:numel(files)
        % Load the file and extract the struct
        filePath = fullfile(folderPath, files(i).name);
        data = load(filePath,vars{:});
        
        % Extract the log_p and BEP values from the struct
        logP = data.log_p;
        BEP_Naive = data.BEP_Naive;
        BEP_MsgPas = data.BEP_MsgPas;
        
        % Append the values to the arrays
        BEP_Naive_Values = [BEP_Naive_Values, BEP_Naive];
        BEP_MsgPas_Values = [BEP_MsgPas_Values, BEP_MsgPas];
        logPValues = [logPValues, logP];
    end
    
    % Plot the graph
    figure(1);
    semilogy(logPValues, BEP_Naive_Values, 'o');
    hold on
    semilogy(logPValues, BEP_MsgPas_Values, 'o');
    xlabel('log_p');
    ylabel('BEP');
    title('BEP over log_p, n=256, R=0.5');
    legend('BEP Naive', 'BEP MsgPas', 'Location', 'northwest');
end