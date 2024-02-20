% Specify the directory containing the .mat files
directory = "./Codewords";
name = "len128_Ri048_Rr076";
filePattern = fullfile(directory, name + "*.mat");
% Get a list of all files that match the filePattern
files = dir(filePattern);
    
% Initialize an empty matrix for concatenating the totalCodewords
totalCodewords = [];
messageIndLenVec= [];
messageResLenVec = [];

% Loop through each file in the directory
for k = 1:length(files)
    % Full path to the file
    fullPath = fullfile(files(k).folder, files(k).name);
    
    % Load the totalCodewords variable from the .mat file
    loadedData = load(fullPath, 'totalCodewords','messageIndLen','messageResLen');
    
    % Check if totalCodewords exists in the loaded data
    if isfield(loadedData, 'totalCodewords')
        % Concatenate the loaded totalCodewords to the combined matrix
        totalCodewords = [totalCodewords; loadedData.totalCodewords];
        messageIndLenVec = [messageIndLenVec; loadedData.messageIndLen];
        messageResLenVec = [messageResLenVec; loadedData.messageResLen];
    else
        warning('Variable "totalCodewords" not found in %s.', files(k).name);
    end
end

messageIndLen = mean(messageIndLenVec);
messageResLen = mean(messageResLenVec);
% Ensure the combinedCodewords is still of type uint (if necessary)
% combinedCodewords = uint(combinedCodewords);

% Save the combined totalCodewords to a new .mat file
saveFileName = name + ".mat";
save(fullfile(directory, saveFileName), 'totalCodewords','messageResLen','messageIndLen');

% Display completion message
fprintf('Combined totalCodewords saved to %s\n', fullfile(directory, saveFileName));