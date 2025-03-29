# EMG Analysis and Muscle Synergy Framework

![MATLAB R2022b+](https://img.shields.io/badge/MATLAB-R2022b%2B-blue.svg)

## Overview
This repository provides scripts for electromyography (EMG) data analysis and muscle synergy extraction.

## Features and Capabilities

This framework enables you to:

- **Data Integration:** Aggregate multiple data files from the same experimental day into a single data file
- **Signal Processing:** Filter EMG data with customizable parameters
- **Event Timing Analysis:** Generate event timing data for behavioral synchronization
- **Trial Segmentation:** Extract and save EMG data for individual trials
- **Visualization:** Generate clear visualizations of muscle activity patterns for each experimental day
- **Correlation Analysis:** Quantify and visualize similarities between EMG signals using cross-correlation analysis
- **Synergy Extraction:** Extract muscle synergies from EMG datasets using Non-negative Matrix Factorization (NMF)
- **Synergy Visualization:** Create comprehensive visualizations of extracted muscle synergies
- **Performance Metrics:** Visualize Variance Accounted For (VAF) and similarity measures between muscle synergies

## Getting Started

### Preliminary Preparations

Before starting the analysis, please complete the following setup steps:

#### 1. Environment Setup

- **MATLAB Requirements:**
  - MATLAB R2022b or later
  - Signal Processing Toolbox
  - Statistics and Machine Learning Toolbox

- **Add Required Paths:**
  - Launch MATLAB
  - Navigate to the repository root directory
  - Add the repository root directory to MATLAB's path
  - Right-click on the repository root folder and select "Add to Path" → "Selected Folders and Subfolders"
  - Alternatively, run the following command:
    ```matlab
    % Replace with the actual path to your repository root
    addpath(genpath('/path/to/EMG_analysis_latest'));
    ```

#### 2. Data Preparation

- **Data Organization:**
  - Create a `useDataFold` directory at the same level as `modules` and `executeFunctions` in the root of the repository
  - Inside `useDataFold`, create a subdirectory with the monkey name (e.g., `useDataFold/Hugo`)
  - Inside each monkey subdirectory, create folders named by experiment date (e.g., `20250311`)
  - Place raw experimental data files in the appropriate date folders

#### 3. Repository Structure

The repository is organized as follows:

```
EMG_analysis_latest/
├── README.md                # This documentation file
├── executeFunctions/        # Directory containing main executable scripts
│   ├── saveLinkageInfo.m    
│   ├── prepareEMGAndTimingData.m  
│   └── ...                  
├── modules/                 # Directory containing custom functions
│   ├── dataPreparation/     
│   ├── nmfAnalysis/         
│   └── ...                  
├── saveFold/                # Output directory for analysis results (automatically created)
│   └── [MonkeyName]/        # e.g., Hugo
│       └── data/            # Contains processed results
└── useDataFold/             # Input data directory (create manually)
    └── [MonkeyName]/        # e.g., Hugo
        └── [YYYYMMDD]/      # Date-based directories (e.g., 20250311)
            └── ...          # Raw data files
```

> **Note:** The `saveFold` directory will be automatically created when you run the analysis scripts. You do not need to create it manually. Only the `useDataFold` directory and its subdirectories need to be created by the user.

### Analysis Workflow

The complete sequence of EMG analysis and muscle synergy extraction is illustrated below:

<div style="text-align: center; margin: 20px 0;">
  <img src="https://private-user-images.githubusercontent.com/108604104/427816327-3ccecd42-707a-4bb0-aafe-4ac61672a230.png?jwt=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3NDMxMjk0ODksIm5iZiI6MTc0MzEyOTE4OSwicGF0aCI6Ii8xMDg2MDQxMDQvNDI3ODE2MzI3LTNjY2VjZDQyLTcwN2EtNGJiMC1hYWZlLTRhYzYxNjcyYTIzMC5wbmc_WC1BbXotQWxnb3JpdGhtPUFXUzQtSE1BQy1TSEEyNTYmWC1BbXotQ3JlZGVudGlhbD1BS0lBVkNPRFlMU0E1M1BRSzRaQSUyRjIwMjUwMzI4JTJGdXMtZWFzdC0xJTJGczMlMkZhd3M0X3JlcXVlc3QmWC1BbXotRGF0ZT0yMDI1MDMyOFQwMjMzMDlaJlgtQW16LUV4cGlyZXM9MzAwJlgtQW16LVNpZ25hdHVyZT1mYTEyMzIwN2NjNTc2YTI2ZTAxNjFlYmE4ZDM5NzBhOWM4NDQ5Mzc0YTYyMzk0NjNlY2JmMGI5NzgxMGYyODA5JlgtQW16LVNpZ25lZEhlYWRlcnM9aG9zdCJ9.WJSmJ2MSiAMxCFqtvWPGmnr_7yQcU2dfRKyHSN1L1_I" alt="EMG Analysis Workflow" style="max-width: 100%; width: 70%; height: auto;">
</div>

For detailed information about each script's usage and processing steps, please refer to the documentation at the beginning of each file.

## Code Documentation Standards

Each script in this repository follows a standardized header format that varies slightly between directories:

### Documentation in `executeFunctions` directory

Files in the `executeFunctions` directory contain headers with these sections:

| Section | Description |
|---------|-------------|
| **your operation** | Steps required to execute the function |
| **role of this code** | Purpose and function in the overall analysis pipeline |
| **saved data location** | Where output data is stored when the function is executed |
| **execution procedure** | Names of functions to be executed before and after this one |

### Documentation in `modules` directory

Files in the `modules` directory contain headers with these sections:

| Section | Description |
|---------|-------------|
| **Function Description** | Detailed explanation of what the function does |
| **Input Arguments** | Description of all parameters that the function accepts |
| **Output Arguments** | Description of data returned by the function |
| **Caution** | Important notes or warnings about function usage |

## Additional Information

- Detailed information about experiment protocols and analysis methods is available separately
- To access additional documentation, **please contact the email address provided below**

> ⚠️ **Note on disk space:** This analysis generates a significant amount of data. Please ensure you have sufficient free disk space when working with this repository.

## Contact

For questions, support, or to request access to datasets, please contact:

**Email**: otanaohito1102@gmail.com
