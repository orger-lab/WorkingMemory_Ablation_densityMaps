% =========================================================================
% Orger Lab, 2026
%
% Works in registered (template) space:
%   1. Load pre and post stacks, both registered to template
%   2. Threshold to binary
%   3. Crop fixed window in template space
%   4. Compute ablation mask = pre & ~post
%   5. Save per-fish mask
% =========================================================================

clear; clc;

rootDir = 'C:\Users\Joao Marques\Desktop\Mariana\cropping_TEMP';

% Template-space crop window (MATLAB 1-indexed: add 1 if these are 0-indexed)
col_min = 220; col_max = 332;   
row_min = 600; row_max = 802;   
slc_min = 47;  slc_max = 77;    

% Thresholds — same as your existing script
threshold_pre  = 0.10;
threshold_post = 0.10;

% -------------------------------------------------------------------------
% Get all fish folders
% -------------------------------------------------------------------------
fishFolders = dir(rootDir);
fishFolders = fishFolders([fishFolders.isdir] & ...
              ~startsWith({fishFolders.name}, '.') & ...
              ~strcmp({fishFolders.name}, 'ablation_masks'));

outputDir = fullfile(rootDir, 'ablation_masks');
if ~exist(outputDir, 'dir'); mkdir(outputDir); end

nFish = 0;

for i = 1:length(fishFolders)
    folderName = fishFolders(i).name;
    fishDir    = fullfile(rootDir, folderName);

    % Match your filename convention
    preFile  = dir(fullfile(fishDir, '*ToCCUBridge_template_Registered_WithGauss.tif'));
    postFile = dir(fullfile(fishDir, '*Registered_WithGaussToRef.tif'));

    if isempty(preFile) || isempty(postFile)
        fprintf('Skipping %s — registered files not found\n', folderName);
        continue;
    end

    fprintf('\nProcessing %s...\n', folderName);

    pre  = load_and_normalize(fullfile(fishDir, preFile(1).name));
    post = load_and_normalize(fullfile(fishDir, postFile(1).name));

    assert(isequal(size(pre), size(post)), ...
        'Size mismatch in %s — check registration output.', folderName);

    % Threshold
    bw_pre  = pre  > threshold_pre;
    bw_post = post > threshold_post;

    % Crop to template-space window
    mask_window = false(size(bw_pre));
    mask_window(row_min:row_max, col_min:col_max, slc_min:slc_max) = true;

    bw_pre  = bw_pre  & mask_window;
    bw_post = bw_post & mask_window;

    % Ablation mask (full volume, blackened outside window)
    ablation = bw_pre & ~bw_post;
    % Erosion-dilation on ablation mask to remove salt-and-pepper noise
    se = strel('sphere', 1);   % radius — increase if too much noise remains
    n_cycles = 2;
    
    for c = 1:n_cycles
        ablation = imerode(ablation,  se);
        ablation = imdilate(ablation, se);
    end

    fprintf('  Ablated voxels after cleanup: %d\n', sum(ablation(:)));
    fprintf('  Ablated voxels: %d / %d (%.1f%%)\n', ...
        sum(ablation(:)), numel(ablation), 100*mean(ablation(:)));

    % Save
    outPath = fullfile(outputDir, sprintf('%s_ablation_mask.tif', folderName));
    save_tif_stack(uint8(ablation) * 255, outPath);

    nFish = nFish + 1;
end

fprintf('\nDone. Processed %d fish. Masks saved to:\n%s\n', nFish, outputDir);

% =========================================================================
%  LOCAL FUNCTIONS
% =========================================================================

function stack = load_and_normalize(path)
    info  = imfinfo(path);
    nz    = numel(info);
    tmp   = double(imread(path, 1));
    stack = zeros(size(tmp,1), size(tmp,2), nz);
    for z = 1:nz
        stack(:,:,z) = double(imread(path, z));
    end
    lo = prctile(stack(:), 0.5);
    hi = prctile(stack(:), 99.5);
    stack = (stack - lo) / (hi - lo + 1e-9);
    stack = max(0, min(1, stack));
end

function save_tif_stack(stack, path)
    for z = 1:size(stack, 3)
        if z == 1
            imwrite(stack(:,:,z), path);
        else
            imwrite(stack(:,:,z), path, 'WriteMode', 'append');
        end
    end
    fprintf('  Saved: %s\n', path);
end