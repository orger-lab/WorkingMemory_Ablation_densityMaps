% =========================================================================
% Orger Lab, 2026
%
% Plot Left Pre vs Left Post voxel counts
% Figure 1: all fish overlaid 
% Figure 2: subplots, one per fish
%
% =========================================================================

rootDir = 'C:\Users\Joao Marques\Desktop\Mariana\cropping_TEMP';

% --- Collect data ---
csvFiles = dir(fullfile(rootDir, '**', '*.csv'));
csvFiles = csvFiles(~strcmp({csvFiles.folder}, rootDir));

if isempty(csvFiles)
    error('No CSV files found in subfolders.');
end

nFish = length(csvFiles);
preVals  = nan(nFish, 1);
postVals = nan(nFish, 1);
pctChange  = nan(nFish, 1);
fishNames = cell(nFish, 1);

for i = 1:nFish
    filePath = fullfile(csvFiles(i).folder, csvFiles(i).name);
    [~, subName] = fileparts(csvFiles(i).folder);
    fishNames{i} = subName;
    try
        T = readtable(filePath);
        preVals(i)  = T.Left_pre(1);
        postVals(i) = T.Left_post(1);
        pctChange(i) = T.Left_change___(1);
    catch e
        fprintf('WARNING: Could not read %s — %s\n', filePath, e.message);
    end
end

% Remove any failed reads
valid = ~isnan(preVals) & ~isnan(postVals);
preVals   = preVals(valid);
postVals  = postVals(valid);
fishNames = fishNames(valid);
pctChange = pctChange(valid);  
nFish     = sum(valid);

% --- Stats ---
meanPre  = mean(preVals);
meanPost = mean(postVals);
[~, pVal] = ttest(preVals, postVals);

% =========================================================
% FIGURE 1 — Group plot
% =========================================================
figure('Color','w','Position',[100 100 400 500]);
hold on;

% Individual fish lines (grey)
for i = 1:nFish
    plot([1 2], [preVals(i) postVals(i)], '-', ...
        'Color', [0.75 0.75 0.75], 'LineWidth', 1);
end

% Group mean line (bold black)
plot([1 2], [meanPre meanPost], 'k-', 'LineWidth', 3);

% Mean markers (open circles)
plot(1, meanPre,  'ko', 'MarkerSize', 10, 'MarkerFaceColor', 'w', 'LineWidth', 2);
plot(2, meanPost, 'ko', 'MarkerSize', 10, 'MarkerFaceColor', 'w', 'LineWidth', 2);

% Formatting
xlim([0.7 2.3]);
yMax = max([preVals; postVals]) * 1.1;
ylim([0 yMax]);
set(gca, 'XTick', [1 2], 'XTickLabel', {'Pre', 'Post'}, 'FontSize', 12);
ylabel('Voxel count (Left hemisphere)', 'FontSize', 12);
title(sprintf('pVal=%.4e  N=%d', pVal, nFish), 'FontSize', 11);
box off;

saveas(gcf, fullfile(rootDir, 'Left_pre_post_group.png'));

% =========================================================
% FIGURE 2 — One subplot per fish
% =========================================================
nCols = ceil(sqrt(nFish));
nRows = ceil(nFish / nCols);

figure('Color','w','Position',[100 100 250*nCols 220*nRows]);

for i = 1:nFish
    subplot(nRows, nCols, i);
    hold on;

    % Line
    plot([1 2], [preVals(i) postVals(i)], 'k-', 'LineWidth', 2);

    % Markers
    plot(1, preVals(i),  'ko', 'MarkerSize', 7, 'MarkerFaceColor', 'w', 'LineWidth', 1.5);
    plot(2, postVals(i), 'ko', 'MarkerSize', 7, 'MarkerFaceColor', 'w', 'LineWidth', 1.5);

    % Colour the line red if post < pre (loss), blue if post > pre (gain)
    if postVals(i) < preVals(i)
        lineColor = [0.85 0.2 0.2];
    else
        lineColor = [0.2 0.5 0.85];
    end
    plot([1 2], [preVals(i) postVals(i)], '-', 'Color', lineColor, 'LineWidth', 2);

    xlim([0.7 2.3]);
    ylim([0 max(preVals(i), postVals(i)) * 1.2]);
    set(gca, 'XTick', [1 2], 'XTickLabel', {'Pre','Post'}, 'FontSize', 8);
    title(sprintf('%s\n%.1f%%', fishNames{i}, pctChange(i)), ...
        'FontSize', 8, 'Interpreter', 'none');    ylabel('Voxels', 'FontSize', 7);
    box off;
end

% Hide unused subplots
for i = nFish+1 : nRows*nCols
    subplot(nRows, nCols, i);
    axis off;
end

sgtitle('Left hemisphere — voxel count per fish', 'FontSize', 13);
saveas(gcf, fullfile(rootDir, 'Left_pre_post_perfish.png'));

fprintf('\nDone. Figures saved to:\n%s\n', rootDir);