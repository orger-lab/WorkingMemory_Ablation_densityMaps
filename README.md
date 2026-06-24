# Working Memory Ablation: Density Maps

This repository contains MATLAB scripts for visualizing ablated cell data. The pipeline calculates ablated voxels, merges datasets across subjects, and generates density map visualizations.

## Pipeline Overview

The analysis is split into two main workflows. Scripts should be executed in the exact order listed below.

### Part 1: Cell Counting and Plotting
1. **`CountAblatedCells_Script.m`**
   * **Description:** Counts the number of voxels in the ablated region for each subject.
   * **Outputs:** * A `.csv` file for each fish containing the voxel counts.
     * Two binary `.tif` files corresponding to the areas of interest (pre- and post-ablation).

2. **`mergeCSV.m`**
   * **Description:** Scans each fish folder and merges all individual `.csv` files into a single `.csv` file.

3. **`makeplots.m`**
   * **Description:** Visualizes the voxel data before and after ablation. Generates plots for all fish aggregated together, as well as separate plots for individual fish.

---

### Part 2: Density Maps and Visualization
1. **`IdentifyAblation.m`**
   * **Description:** Makes a density map for the targeted ablation area. 

2. **`heatmap.m`**
   * **Description:** Processes the density map data to render a heatmap, allowing for a better visual display of the ablation distribution.

