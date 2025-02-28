## Overview
This repository provides codes and files for muscle synergy and EMG analysis.
***

## How to Analyze

  - <span style="font-size: 18px;">**Preliminary Preparations**</span>

    - Please place all recorded data file directly under the monkey name folder.

      (ex.) EMG_analysis_turorial/data/Yachimun/

      - (To obtain the dataset, <strong>please contact the email address given in the contact section.</strong>)

    <!-- insert image -->
    <img src="explanation_materials/explanation1.jpg" alt="explanation1" width="100%" style="display: block; margin-left: auto; margin-right: auto; padding: 20px">

    - Please understand the directory structure of this repository

      Basically, the functions you need to execute in this analysis are stored in 'EMG_data_latest/data/'. All inner functions of these executed functions and packages of frequently used functions are contained in 'EMG_data_latest/code/'.</br>
      The schematic below illustrates the structure of this repository.

      ```
      .
      └── EMG_analysis_latest
          ├── README.md
          ├── code
          │   ├── codeForNibali
          │   ├── codeForNMF
          │   └── (other function packages)
          ├── data
          │   ├── prepareEMGAndTimingData.m
          │   ├── visualizeEMGAndSynergy.m
          │   ├── prepareRawEMGDataForNMF.m
          │   └── (other functions you need to execute)
          └── explanation_materials
              └── (some images)
      ```

    - Please add 'code' and 'data' folder to PATH in MATLAB

    <!-- insert image -->
    <img src="explanation_materials/explanation2.gif" alt="explanation1" width="100%" style="display: block; margin-left: auto; margin-right: auto; padding: 20px">

  - <span style="font-size: 18px;">**Sequence of Analysis**</span>

  The sequence of EMG analysis and muscle synergy analysis is shown in the figure below.<br>
  For details on the usage and processing of each code, please refer to the description at the beginning of code.

  <!-- insert image -->
  <img src="explanation_materials/explanation3.jpg" alt="explanation3" width="80%" style="display: block; margin-left: auto; margin-right: auto; padding: 20px">

***

## Remarks
  The following information is written at the beginning of each code. Please refer to them and proceed with the analysis.
  - **Your operation**<br>
    This describes what you need to do to perform each function.

  - **Role of this code**<br>
    Details of the role each function plays in the overall analysis.

  - **Saved data location**<br>
    Details of the data saved when each function is executed and the location of this

  - **Procedure**<br>
    This describes which code should be executed before and after this code.

***

## Other information

  - The dates adopted as experimental dates are summarized in 'analysis_data_days(Yachimun).csv'. This file is located at the top level of this repository.

  - Details of the experiment and analysis outline are distributed separately. If you would like to get these information, <strong>please contact at the email address given in the contact section</strong>

***

## Contact

  If you have any questions about this analysis, please feel free to contact me at nao-ota@ncnp.go.jp
