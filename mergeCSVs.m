% =========================================================================
% Orger Lab, 2026
%
% % Merge all CSV files from subfolders into one combined CSV
%
% =========================================================================

rootDir = 'C:\Users\Joao Marques\Desktop\Mariana\cropping_TEMP';

% Find all CSV files in subfolders
csvFiles = dir(fullfile(rootDir, '**', '*.csv'));

% Remove any CSV files directly in the root folder (only want subfolders)
csvFiles = csvFiles(~strcmp({csvFiles.folder}, rootDir));

if isempty(csvFiles)
    error('No CSV files found in subfolders of %s', rootDir);
end

% Read the header from the first file
firstFile = fullfile(csvFiles(1).folder, csvFiles(1).name);
opts = detectImportOptions(firstFile);
opts.DataLines = [1 2]; % header + one data row
T_first = readtable(firstFile, opts);

% Get header names
headers = T_first.Properties.VariableNames;

% Pre-allocate a table
allData = table();

for i = 1:length(csvFiles)
    filePath = fullfile(csvFiles(i).folder, csvFiles(i).name);
    folderName = csvFiles(i).folder;
    [~, subfolderName] = fileparts(folderName);
    
    try
        opts = detectImportOptions(filePath);
        opts.DataLines = [2 2]; % data row only (skip header)
        T = readtable(filePath, opts);
        T.Properties.VariableNames = headers;
        
        % Add a column with the source subfolder name
        T.Source = {subfolderName};
        
        allData = [allData; T];
        fprintf('Read: %s\n', filePath);
    catch e
        fprintf('WARNING: Could not read %s — %s\n', filePath, e.message);
    end
end

% Reorder so Source is the first column
allData = [allData(:, end), allData(:, 1:end-1)];

% Write output
outputFile = fullfile(rootDir, 'merged_results.csv');
writetable(allData, outputFile);
fprintf('\nDone! Merged %d files into:\n%s\n', height(allData), outputFile);