# Movement Artifact Quantification Research Code

This repository contains the research release of the MATLAB implementation used for the paper review process for the Movement Artifact Quantification paper.

The current release reflects the method as described in the manuscript, including the experimental pipeline used in the paper. It is intentionally provided as a research snapshot rather than a polished software package.

## Status

- This code is a paper-aligned research release.
- It is not the final production version.
- Some parts are hard-coded for the current experimental setup.
- Some algorithms and workflows are still organized in a research-oriented manner rather than as a general-purpose toolbox.
- An improved, cleaner, and better-optimized version will be released after publication.

## Main Script

The main release file is:

- `m1_v5_1_5_mod8_release1.m`

This script includes the end-to-end experimental pipeline used in this release, including:

- dataset loading and preprocessing
- cropping and inversion steps
- movement artifact position estimation
- reference origin point estimation
- movement artifact quantization
- supporting direction-estimation components used within the broader experimental workflow
- evaluation and visualization utilities

## Requirements

- MATLAB
- Image Processing Toolbox
- Signal Processing Toolbox

The implementation uses MATLAB functions such as `imread`, `rgb2gray`, `imcomplement`, `imshow`, and `findpeaks`.

## Dataset Assumptions

The current script is configured for a specific dataset layout and currently contains hard-coded base paths for macOS and Windows.

By default, the script expects dataset folders under paths like:

- macOS: `/Users/geeksloth/Desktop/Movement_Artifact_Dataset_2/cropped/`
- Windows: `E:\Movement_Artifact_Dataset_2\cropped\`

Before running the code, update the dataset path configuration inside `m1_v5_1_5_mod8_release1.m` to match your local environment.

## Notes on Reproducibility

This repository is shared to support transparency and manuscript review. The implementation is close to the research code used for the reported experiments, but it has not yet been fully refactored for external reuse.

In particular:

- comments are minimal or research-oriented in some sections
- configuration values are embedded directly in the script
- path handling is not yet repository-portable
- some parts can be improved for readability, modularity, and robustness

## Intended Use

This release is intended for:

- understanding the experimental workflow behind the paper
- reproducing the reported method with the expected dataset structure
- reviewing the logic of the proposed quantification approach

It is not yet intended to serve as the final public software package.

## Citation

If this repository is useful in your research, please cite the corresponding paper once it is published.

## Future Release

A better-organized, improved, and more reusable version of this codebase will be released after publication.
