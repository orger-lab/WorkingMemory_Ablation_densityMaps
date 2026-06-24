% =========================================================================
% Orger Lab, 2026
% Accumulates per-fish ablation masks into a group density heatmap
%
% =========================================================================

clear; clc;

rootDir   = 'C:\Users\Joao Marques\Desktop\Mariana\cropping_TEMP';
outputDir = fullfile(rootDir, 'ablation_masks');

maskFiles = dir(fullfile(outputDir, '*_ablation_mask.tif'));

if isempty(maskFiles)
    error('No ablation mask files found in %s', outputDir);
end

nFish      = length(maskFiles);
densityMap = [];

for i = 1:nFish
    path = fullfile(maskFiles(i).folder, maskFiles(i).name);
    fprintf('Loading %d/%d: %s\n', i, nFish, maskFiles(i).name);

    mask = load_tif_binary(path);   % logical, full template size

    if isempty(densityMap)
        densityMap = double(mask);
    else
        assert(isequal(size(densityMap), size(mask)), ...
            'Size mismatch at fish %d — all masks must be full template size.', i);
        densityMap = densityMap + double(mask);
    end
end

fprintf('\nDensity map complete. Max overlap: %d / %d fish\n', ...
    round(max(densityMap(:))), nFish);

% --- Save raw count map (voxel value = n fish ablated there) ---
outCount = fullfile(rootDir,'ablation_masks', 'density_map_counts.tif');
save_tif_stack(uint16(densityMap), outCount);
fprintf('Saved count map: %s\n', outCount);

% --- Save normalised map (0-1, fraction of fish) ---
densityNorm = densityMap ./ nFish;
outNorm = fullfile(rootDir,'ablation_masks', 'density_map_normalised.tif');
save_tif_stack(uint16(densityNorm * 65535), outNorm);
fprintf('Saved normalised map: %s\n', outNorm);

% --- Gaussian smoothing ---                          % ADD FROM HERE
sigma = 2;                                            % in voxels — increase for more smoothing
densitySmooth = imgaussfilt3(densityNorm, sigma);
outSmooth = fullfile(rootDir, 'ablation_masks', 'density_map_smoothed.tif');
save_tif_stack(uint16(densitySmooth * 65535), outSmooth);
fprintf('Saved smoothed map: %s\n', outSmooth);       % TO HERE

% --- MIP heatmap for quick QC ---
% --- MIP heatmap ---
mip       = max(densityMap,    [], 3);          % raw counts
mipSmooth = max(densitySmooth, [], 3);          % smoothed, 0-1 range

% Convert raw counts MIP to percentage for display
mipPct       = (mip       ./ nFish) * 100;     % 0-100
mipSmoothPct = (mipSmooth ./ max(densitySmooth(:))) * 100;  % 0-100 (post-smoothing)

figure('Color','w', 'Position', [100 100 900 400]);

subplot(1,2,1);
imagesc(mipPct);
axis image off;
colormap(hot);
cb = colorbar;
cb.Label.String = 'Ablation overlap (% of fish)';
caxis([0 100]);
title(sprintf('Raw counts — MIP (N=%d)', nFish), 'FontSize', 12);

subplot(1,2,2);
imagesc(mipSmoothPct);
axis image off;
colormap(hot);
cb = colorbar;
cb.Label.String = 'Ablation overlap (% of fish)';
caxis([0 100]);
title(sprintf('Smoothed (\\sigma=%d) — MIP (N=%d)', sigma, nFish), 'FontSize', 12);

saveas(gcf, fullfile(rootDir, 'density_map_MIP.png'));
fprintf('Saved MIP figure.\n\nDone.\n');


% =========================================================================
%  LOCAL FUNCTIONS
% =========================================================================

function stack = load_tif_binary(path)
    info  = imfinfo(path);
    nz    = numel(info);
    tmp   = imread(path, 1);
    stack = false(size(tmp,1), size(tmp,2), nz);
    for z = 1:nz
        stack(:,:,z) = imread(path, z) > 0;
    end
end

function save_tif_stack(stack, path)
    for z = 1:size(stack, 3)
        if z == 1
            imwrite(stack(:,:,z), path);
        else
            imwrite(stack(:,:,z), path, 'WriteMode', 'append');
        end
    end
end