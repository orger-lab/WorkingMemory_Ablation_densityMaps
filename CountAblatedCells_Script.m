% =========================================================================
% Orger Lab, 2026
%
% Ablation quantification via binary mask voxel counting:
%   1. Load and normalise pre and post stacks
%   2. Threshold to binary masks
%   3. Erosion-dilation cycles to clean up masks
%   4. Crop 4 ROIs: left pre, right pre
%   5. Save 2 binary ROIs as TIFs
%   6. Count ON voxels in each ROI and report
%
% =========================================================================

clear; clc;

% -------------------------------------------------------------------------
%  USER OPTIONS
% -------------------------------------------------------------------------
folderList = { ...
    'W19', ...
    'W22', ...
    'W24', ...
    'W25', ...
    'W29', ...
    'W31', ...
    'W32', ...
    'W36', ...
    'W37', ...
    'W52', ...
    'W53', ...
    'W54', ...
    'W57', ...
    'W58', ...
    'W60', ...
    'W63', ...
    'W65', ...
    'W66', ...
    'W67', ...
    'W68', ...
    'W69', ...
    'W70', ...
    'W71', ...
    'W72', ...
    'W73', ...
    'W74', ...
    'W75', ...
    'W76', ...
    'W77', ...
    'W78', ...
};
for i=1:length(folderList)

    folderName = folderList{i};
    filenamePRE = sprintf('%s_ToCCUBridge_template_Registered_WithGauss.tif', folderName);
    filenamePOS = sprintf('%s_ToPreAblation_template_Registered_WithGaussToRef.tif', folderName);
    pre_path  = fullfile('C:\Users\Joao Marques\Desktop\Mariana\cropping_TEMP', folderName, filenamePRE);
    post_path = fullfile('C:\Users\Joao Marques\Desktop\Mariana\cropping_TEMP', folderName, filenamePOS);
    output_dir = 'C:\Users\Joao Marques\Desktop\Mariana\cropping_TEMP';
    
    % Thresholds (normalised [0,1] intensity)
    threshold_pre  = 0.10;
    threshold_post = 0.10;
    
    % Erosion-dilation
    n_iterations = 2;    % number of erode+dilate cycles
    open_radius  = 1;    % SE radius in voxels
    
    % ROI coordinates 
    % [row_min, col_min, slice_min] and [row_max, col_max, slice_max]
    
    column_i = 220;        % coordinates of the top left point      
    row_i = 600;                  
    slice_i = 47;                
    
    column_f = 332;        % coordinated of the bottom right point       
    row_f = 802;                  
    slice_f = 77; 
    
    
    roi_left_min  = [row_i,  column_i,  slice_i]; 
    roi_left_max  = [row_f, column_f, slice_f]; 
    
    % -------------------------------------------------------------------------
    %  LOAD STACKS
    % -------------------------------------------------------------------------
    
    fprintf('Loading pre-ablation stack...\n');
    pre  = load_tif_stack(pre_path);
    
    fprintf('Loading post-ablation stack...\n');
    post = load_tif_stack(post_path);
    
    % -------------------------------------------------------------------------
    %  NORMALISE (0-1 float)
    % -------------------------------------------------------------------------
    
    pre  = normalize_stack(pre);
    post = normalize_stack(post);
    
    % -------------------------------------------------------------------------
    %  THRESHOLD TO BINARY MASKS
    % -------------------------------------------------------------------------
    
    fprintf('\nThresholding...\n');
    bw_pre  = pre  > threshold_pre;
    bw_post = post > threshold_post;
    
    fprintf('  Pre  — ON voxels after threshold: %d\n', sum(bw_pre(:)));
    fprintf('  Post — ON voxels after threshold: %d\n', sum(bw_post(:)));
    
    % -------------------------------------------------------------------------
    %  EROSION-DILATION CYCLES
    % -------------------------------------------------------------------------
    
    se = strel('sphere', open_radius);
    
    fprintf('\nApplying %d erosion-dilation cycles to pre...\n', n_iterations);
    for i = 1:n_iterations
        bw_pre = imerode(bw_pre,  se);
        bw_pre = imdilate(bw_pre, se);
        fprintf('  Cycle %d done\n', i);
    end
    
    fprintf('Applying %d erosion-dilation cycles to post...\n', n_iterations);
    for i = 1:n_iterations
        bw_post = imerode(bw_post,  se);
        bw_post = imdilate(bw_post, se);
        fprintf('  Cycle %d done\n', i);
    end
    
    fprintf('  Pre  — ON voxels after erosion-dilation: %d\n', sum(bw_pre(:)));
    fprintf('  Post — ON voxels after erosion-dilation: %d\n', sum(bw_post(:)));
    
    % -------------------------------------------------------------------------
    %  CROP 2 ROIs
    % -------------------------------------------------------------------------
    
    fprintf('\nCropping ROIs...\n');
    
    % Unpack coordinates
    r1L = roi_left_min(1);  r2L = roi_left_max(1);
    c1L = roi_left_min(2);  c2L = roi_left_max(2);
    s1L = roi_left_min(3);  s2L = roi_left_max(3);
        
    % Crop
    roi_left_pre   = bw_pre( r1L:r2L, c1L:c2L, s1L:s2L);
    roi_left_post  = bw_post(r1L:r2L, c1L:c2L, s1L:s2L);
    
    fprintf('  LEFT  ROI size: %d x %d x %d voxels\n', r2L-r1L+1, c2L-c1L+1, s2L-s1L+1);
    
    % -------------------------------------------------------------------------
    %  SAVE 2 BINARY ROI TIFs
    % -------------------------------------------------------------------------
    
    if ~exist(output_dir, 'dir'); mkdir(output_dir); end
    
    fprintf('\nSaving ROI TIFs...\n');
    save_tif_stack_typed(uint8(roi_left_pre)   * 255, fullfile(output_dir, folderName, 'roi_left_pre.tif'));
    save_tif_stack_typed(uint8(roi_left_post)  * 255, fullfile(output_dir, folderName, 'roi_left_post.tif'));
    
    % -------------------------------------------------------------------------
    %  COUNT ON VOXELS IN EACH ROI
    % -------------------------------------------------------------------------
    
    n_left_pre   = sum(roi_left_pre(:));
    n_left_post  = sum(roi_left_post(:));
    
    fprintf('\n=============================================\n');
    fprintf('  VOXEL COUNTS\n');
    fprintf('=============================================\n');
    fprintf('  Left  PRE  (ablated side,  before): %d\n', n_left_pre);
    fprintf('  Left  POST (ablated side,  after):  %d\n', n_left_post);

    fprintf('---------------------------------------------\n');
    fprintf('  Left  voxel change:  %+d  (%.1f%%)\n', ...
        n_left_post  - n_left_pre,  100*(n_left_post  - n_left_pre)  / (n_left_pre  + 1e-9));
   
    fprintf('=============================================\n\n');
    
    % -------------------------------------------------------------------------
    %  SAVE SUMMARY CSV
    % -------------------------------------------------------------------------
    
    summary = table( ...
        n_left_pre, n_left_post, ...
        n_left_post  - n_left_pre,  100*(n_left_post  - n_left_pre)  / (n_left_pre  + 1e-9), ...
        'VariableNames', { ...
            'Left_pre', 'Left_post', ...
            'Left_change', 'Left_change (%)'});
    
    csv_path = fullfile(output_dir, folderName, 'voxel_counts.csv');
    writetable(summary, csv_path);
    fprintf('Summary saved to: %s\n', csv_path);
    
    % -------------------------------------------------------------------------
    %  FIGURE — bar chart of voxel counts
    % -------------------------------------------------------------------------
    
    figure('Name', 'Voxel counts per ROI', 'Color', [0.15 0.15 0.15]);
    counts = [n_left_pre, n_left_post];
    labels = {'Left PRE', 'Left POST'};
    colors = [0.3 0.7 0.4;    % left pre  — green
              0.2 0.4 0.9];   % left post — blue
    
    b = bar(counts, 'FaceColor', 'flat');
    b.CData = colors;
    set(gca, 'XTickLabel', labels, 'Color', [0.2 0.2 0.2], ...
        'XColor','w', 'YColor','w', 'FontSize', 11);
    ylabel('ON voxels', 'Color', 'w');
    title('Binary mask voxel counts per ROI', 'Color', 'w');
    grid on; grid minor;
    
    % Annotate bars with values
    for i = 1:2
        text(i, counts(i) + max(counts)*0.01, num2str(counts(i)), ...
            'HorizontalAlignment','center', 'Color','w', 'FontSize', 10);
    end
    
    saveas(gcf, fullfile(output_dir, folderName,'voxel_counts.png'));
    fprintf('Figure saved.\n\nDone.\n');
end 

% =========================================================================
%  LOCAL FUNCTIONS
% =========================================================================

function stack = load_tif_stack(path)
    info  = imfinfo(path);
    nz    = numel(info);
    tmp   = imread(path, 1);
    stack = zeros(size(tmp,1), size(tmp,2), nz, 'double');
    for z = 1:nz
        stack(:,:,z) = double(imread(path, z));
    end
end

function stack = normalize_stack(stack)
    lo = prctile(stack(:), 0.5);
    hi = prctile(stack(:), 99.5);
    stack = (stack - lo) / (hi - lo + 1e-9);
    stack = max(0, min(1, stack));
end

function save_tif_stack_typed(stack, path)
    if isfloat(stack)
        stack = uint16(stack * 65535);
    end
    for z = 1:size(stack, 3)
        if z == 1
            imwrite(stack(:,:,z), path);
        else
            imwrite(stack(:,:,z), path, 'WriteMode', 'append');
        end
    end
    fprintf('  Saved: %s\n', path);
end