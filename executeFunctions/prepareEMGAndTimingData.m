%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[your operation]
1. Navigate to the executeFunctions directory.
2. Change some parameters (please refer to 'set param' section)
3. Please run this code

[role of this code]
This script processes raw EMG data and timing data by performing trimming, filtering, and saving the processed data. It prepares the data for further analysis, such as synergy analysis and error assessment.

[saved data location]
- Folder path for processed EMG data: <root_dir>/saveFold/<full_monkey_name>/data/EMG_ECoG/P-DATA/
  - File names include:
    - <monkey_prefix>_<xpdate>_Pdata.mat: Contains data for synergy analysis, including timing data, trimmed EMG, and more.

- Data saved by custom functions:
  - `makeEasyData_all`: Saves processed EMG data and timing information.
  - `CTcheck`: Saves cross-talk data of EMG.
  - `plotEasyData_utb`: Saves aligned EMG data for each trial.

[execution procedure]
- Pre: saveLinkageInfo.m
- Post: 
  - For EMG analysis: visualizeEMGAndSynergy.m
  - For Synergy analysis: prepareRawEMGDataForNMF.m

[caution!!]
Sometimes the function 'uigetfile' is not executed and an error occurs. Please reboot MATLAB if this happens.

[improvement suggestion]
This function currently handles multiple tasks, including data processing, timing extraction, and saving results. It is recommended to break down these tasks into smaller, more focused functions to improve maintainability and readability.
+ タイミングデータの作成に関して、Sesekiの処理部分確認してない
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear 
%% set param
% which monkey?
monkey_prefix = 'Hu';  % 'Ya', 'F'
emg_params_struct = struct();
emg_params_struct.downsample_rate = 1375; % (if down_E ==1)sampling rate of after resampling
emg_params_struct.time_restriction_enabled = false; % true/false
emg_params_struct.time_restriction_limit = 3;  %[s]

%% code section
% get target files(select standard.mat files which contain file information, e.g. file numbers)
full_monkey_name = getFullMonkeyName(monkey_prefix);
root_dir = fileparts(pwd);
linkageInfo_fold_path = fullfile(root_dir, 'saveFold', full_monkey_name, 'data', 'EMG_ECoG', 'linkageInfo_list');
disp(['Please select all "_linkageInfo.mat" of all dates you want to analyze'])
Allfiles_S = uigetfile('*.mat', 'Select One or More Files', 'MultiSelect', 'on', linkageInfo_fold_path);

if isequal(Allfiles_S, 0)
    disp('user press canceled')
    return
end

%change 'char' to 'cell'
if ischar(Allfiles_S)
    Allfiles_S={Allfiles_S};
end
    
day_num = length(Allfiles_S);
Allfiles = strrep(Allfiles_S, '_linkageInfo.mat','');
%% RUNNING FUNC LIST (make data)
common_save_fold_path = fullfile(root_dir, 'saveFold', full_monkey_name, 'data', 'EMG_ECoG');

for day_id = 1:day_num
    load(fullfile(linkageInfo_fold_path, Allfiles_S{day_id}), 'linkageInfo');
    xpdate = linkageInfo.xpdate;
    file_num = linkageInfo.file_num;
    
    % Perform all preprocessing with 3 functions
    % 1. Perform data concatenation & filtering processing & Obtain information on each timing for EMG trial-by-trial extraction
    [EMGs,Tp,Tp3] = makeEasyData_all(monkey_prefix, full_monkey_name, xpdate, file_num, common_save_fold_path, emg_params_struct); 

    % 2. Check for cross-talk between measured EMGs
    [Yave,Y3ave] = CTcheck(monkey_prefix, xpdate, common_save_fold_path, full_monkey_name);

    % 3. Cut out EMG for each trial & Focusing on various timings and cut out EMG around them
    [alignedDataAVE,alignedData_all,taskRange,AllT,Timing_ave,TIME_W,Res,D, focus_timing_num] = plotEasyData_utb(monkey_prefix, xpdate, common_save_fold_path);
    
    % create struct(Store the EMG trial average data around each timing in another structure)
    ResAVE = struct();
    for timing_id = 1:focus_timing_num
        ResAVE.(['tData' num2str(timing_id) '_AVE']) = Res.(['tData' num2str(timing_id) '_AVE']);
        alignedData_trial.(['tData' num2str(timing_id)]) = Res.(['tData' num2str(timing_id)]);
    end
    ResAVE.tDataTask_AVE = Res.tDataTask_AVE;
    alignedData_trial.tDataTask = Res.tDataTask;
    
    %% save data(location: easyData/P-Data)
    % get folder path & make folder
    Pdata_fold_path = fullfile(common_save_fold_path, 'P-DATA');
    makefold(Pdata_fold_path);
    save(fullfile(Pdata_fold_path, [monkey_prefix sprintf('%d',xpdate) '_Pdata.mat']), ...
        'monkey_prefix', 'xpdate', 'file_num', 'EMGs', 'Tp', 'Tp3', ...
        'Yave', 'Y3ave', 'alignedDataAVE', 'taskRange', 'AllT', ...
        'Timing_ave', 'TIME_W', 'ResAVE', 'D');
end