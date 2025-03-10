%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[your operation]
1. Navigate to the executeFunctions directory.
2. Change some parameters (please refer to 'set param' section)
3. Please run this code

[role of this code]
This script processes raw EMG data and timing data by performing trimming, filtering, and saving the processed data. It prepares the data for further analysis, such as synergy analysis and error assessment.

[saved data location]


[execution procedure]
- Pre: saveLinkageInfo.m
- Post:
    - For EMG analysis: visualizeEMGAndSynergy.m
    - For Synergy analysis: prepareRawEMGDataForNMF.m

[caution!!]
Sometimes the function 'uigetfile' is not executed and an error occurs. Please reboot MATLAB if this happens.

[improvement suggestion]
+ タイミングデータの作成に関して、Seseki, Yachimun, Nibaliの処理部分確認してない
+ ログ出す
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear
%% set param
% which monkey?
monkey_prefix = 'Hu';  % 'Ya', 'F'
downsample_rate = 1375; % (if down_E ==1)sampling rate of after resampling
time_restriction_enabled = false; % true/false
time_restriction_limit = 3;  % [s]

%% code section

% Define EMG channel configuration for each monkey
switch monkey_prefix
    case {'Ya', 'F'}
        EMG_name_list=cell(12,1) ;
        EMG_name_list{1,1}= 'FDP';
        EMG_name_list{2,1}= 'FDSprox';
        EMG_name_list{3,1}= 'FDSdist';
        EMG_name_list{4,1}= 'FCU';
        EMG_name_list{5,1}= 'PL';
        EMG_name_list{6,1}= 'FCR';
        EMG_name_list{7,1}= 'BRD';
        EMG_name_list{8,1}= 'ECR';
        EMG_name_list{9,1}= 'EDCprox';
        EMG_name_list{10,1}= 'EDCdist';
        EMG_name_list{11,1}= 'ED23';
        EMG_name_list{12,1}= 'ECU';
   case 'Se'
        EMG_name_list=cell(12, 1) ;
        EMG_name_list{1,1}= 'EDC';
        EMG_name_list{2,1}= 'ED23';
        EMG_name_list{3,1}= 'ED45';
        EMG_name_list{4,1}= 'ECU';
        EMG_name_list{5,1}= 'ECR';
        EMG_name_list{6,1}= 'Deltoid';
        EMG_name_list{7,1}= 'FDS';
        EMG_name_list{8,1}= 'FDP';
        EMG_name_list{9,1}= 'FCR';
        EMG_name_list{10,1}= 'FCU';
        EMG_name_list{11,1}= 'PL';
        EMG_name_list{12,1}= 'BRD';
    case 'Ni'
        EMG_name_list=cell(16,1) ;
        EMG_name_list{1,1}= 'EDCdist';
        EMG_name_list{2,1}= 'EDCprox';
        EMG_name_list{3,1}= 'ED23';
        EMG_name_list{4,1}= 'ED45';
        EMG_name_list{5,1}= 'ECR';
        EMG_name_list{6,1}= 'ECU';
        EMG_name_list{7,1}= 'BRD';
        EMG_name_list{8,1}= 'EPL';
        EMG_name_list{9,1}= 'FDSdist';
        EMG_name_list{10,1}= 'FDSprox';
        EMG_name_list{11,1}= 'FDP';
        EMG_name_list{12,1}= 'FCR';
        EMG_name_list{13,1}= 'FCU';
        EMG_name_list{14,1}= 'FPL';
        EMG_name_list{15,1}= 'Biceps';
        EMG_name_list{16,1}= 'Triceps';
    case 'Hu'
        EMG_name_list=cell(16,1) ;
        EMG_name_list{1,1}= 'EDC';
        EMG_name_list{2,1}= 'ED23';
        EMG_name_list{3,1}= 'ED45';
        EMG_name_list{4,1}= 'ECR';
        EMG_name_list{5,1}= 'ECU';
        EMG_name_list{6,1}= 'FDI';
        EMG_name_list{7,1}= 'ADP';
        EMG_name_list{8,1}= 'ADM';
        EMG_name_list{9,1}= 'Biceps';
        EMG_name_list{10,1}= 'Triceps';
        EMG_name_list{11,1}= 'FDS';
        EMG_name_list{12,1}= 'FDP';
        EMG_name_list{13,1}= 'PL';
        EMG_name_list{14,1}= 'FCR';
        EMG_name_list{15,1}= 'FCU';
        EMG_name_list{16,1}= 'BRD';
end
EMG_num = length(EMG_name_list);

% get target files(select standard.mat files which contain file information, e.g. file numbers)
full_monkey_name = getFullMonkeyName(monkey_prefix);
root_dir_path = fileparts(pwd);
linkageInfo_fold_path = fullfile(root_dir_path, 'saveFold', full_monkey_name, 'data', 'EMG_ECoG', 'linkageInfo_list');
disp('Please select all "_linkageInfo.mat" of all dates you want to analyze')
selected_file_name_list = uigetfile('*.mat', 'Select One or More Files', 'MultiSelect', 'on', linkageInfo_fold_path);

if isequal(selected_file_name_list, 0)
    disp('user press canceled')
    return
end

if ischar(selected_file_name_list)
    selected_file_name_list={selected_file_name_list};
end
 
day_num = length(selected_file_name_list);
unique_name_list = strrep(selected_file_name_list, '_linkageInfo.mat','');
common_save_dir_path = fullfile(root_dir_path, 'saveFold', full_monkey_name, 'data', 'EMG_ECoG');

% perform processing for each experiment day
for day_id = 1:day_num
    ref_linkage_file_path = fullfile(linkageInfo_fold_path, selected_file_name_list{day_id});
    load(ref_linkage_file_path, 'linkageInfo');
    experiment_day = linkageInfo.experiment_day;
    validate_file_range = linkageInfo.validate_file_range;

    [transposed_success_timing] = extractAndProcessTrialData(monkey_prefix, full_monkey_name, experiment_day, EMG_name_list, validate_file_range, common_save_dir_path, downsample_rate, time_restriction_enabled, time_restriction_limit);
    [time_normalized_EMG_average, visualized_range, average_visualized_range_sample_num, average_trial_sample_num, each_timing_cutout_EMG_struct, cutout_range_struct, focus_timing_num] = generateTrialAlignedEMGandTiming(monkey_prefix, experiment_day, common_save_dir_path);
    
    % create struct(Store the EMG trial average data around each timing in another structure)
    each_timing_cutout_mean_EMG_struct = struct();
    for timing_id = 1:focus_timing_num
        each_timing_cutout_mean_EMG_struct.(['timing' num2str(timing_id)]) = each_timing_cutout_EMG_struct.(['timing' num2str(timing_id) '_average']);
        each_timing_cutout_EMG_all_trial_struct.(['timing' num2str(timing_id)]) = each_timing_cutout_EMG_struct.(['timing' num2str(timing_id)]);
    end
    each_timing_cutout_mean_EMG_struct.whole_trial = each_timing_cutout_EMG_struct.whole_trial_average;
    each_timing_cutout_EMG_all_trial_struct.whole_trial = each_timing_cutout_EMG_struct.whole_trial;
    
    %% save data(location: easyData/P-Data)
    % get folder path & make folder
    Pdata_fold_path = fullfile(common_save_dir_path, 'P-DATA');
    makefold(Pdata_fold_path);
    save(fullfile(Pdata_fold_path, [monkey_prefix sprintf('%d',experiment_day) '_Pdata.mat']), ...
        'monkey_prefix', 'experiment_day', 'validate_file_range', 'EMG_name_list', 'transposed_success_timing', ...
        'time_normalized_EMG_average', 'visualized_range', 'average_visualized_range_sample_num', ...
        'average_trial_sample_num', 'each_timing_cutout_mean_EMG_struct', 'cutout_range_struct');
end