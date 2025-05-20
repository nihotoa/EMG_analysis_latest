%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[your operation]
1. Navigate to the executeFunctions directory.
2. Change some parameters (please refer to 'set param' section)
3. Run this code

[role of this code]
This script processes raw EMG data and timing data by performing trimming, 
filtering, and saving the processed data. It prepares the data for further 
analysis, such as synergy analysis and error assessment.

[saved data location]
Please refer to the log messages during execution for saved data locations.

[execution procedure]
- Pre: saveLinkageInfo.m
- Post:
    - For EMG analysis: visualizeEMGAndSynergy.m
    - For Synergy analysis: prepareRawEMGDataForNMF.m

[caution!!]
Sometimes the function 'uigetfile' is not executed and an error occurs. Please reboot MATLAB if this happens.
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear
%% set param
% Basic configuration
monkey_prefix = 'F';  % Monkey prefix (e.g., 'Ya', 'F', 'Se', 'Ni', 'Hu')
downsample_rate = 1375; 
time_restriction_enabled = false; % Whether to restrict trials based on duration
trial_time_threshold = 3;  % Trial duration threshold in seconds (used if time_restriction_enabled is true)

%% Code section

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

% Get target files (select linkageInfo.mat files which contain file information)
full_monkey_name = getFullMonkeyName(monkey_prefix);
root_dir_path = fileparts(pwd);
linkageInfo_fold_path = fullfile(root_dir_path, 'saveFold', full_monkey_name, 'data', 'EMG_ECoG', 'linkageInfo');
disp('Please select all "_linkageInfo.mat" files for the dates you want to analyze')
selected_file_name_list = uigetfile('*.mat', 'Select One or More Files', 'MultiSelect', 'on', linkageInfo_fold_path);

if isequal(selected_file_name_list, 0)
    disp('User pressed cancel button')
    return
end

if ischar(selected_file_name_list)
    selected_file_name_list={selected_file_name_list};
end
 
day_num = length(selected_file_name_list);
unique_name_list = strrep(selected_file_name_list, '_linkageInfo.mat','');
common_save_dir_path = fullfile(root_dir_path, 'saveFold', full_monkey_name, 'data', 'EMG_ECoG');

disp(['Starting to process data for ' full_monkey_name ' (' num2str(day_num) ' days)']);

% Perform processing for each experiment day
for day_id = 1:day_num
    ref_linkage_file_path = fullfile(linkageInfo_fold_path, selected_file_name_list{day_id});
    load(ref_linkage_file_path, 'linkageInfo');
    experiment_day = linkageInfo.experiment_day;
    validate_file_range = linkageInfo.validate_file_range;

    disp(['===== Processing data for ' full_monkey_name ' on day ' num2str(experiment_day) ' =====']);
    
    % Extract and process trial data
    disp(['Starting to extract and process trial data for ' monkey_prefix num2str(experiment_day) '...']);
    [transposed_success_timing] = extractAndProcessTrialData(monkey_prefix, full_monkey_name, experiment_day, EMG_name_list, validate_file_range, common_save_dir_path, downsample_rate, time_restriction_enabled, trial_time_threshold);
    
    % Log success_timing.mat and EMG_data.mat files saved by extractAndProcessTrialData
    success_timing_file = 'success_timing.mat';
    if time_restriction_enabled == true
        success_timing_file = ['success_timing(' num2str(trial_time_threshold) '[sec]_restriction).mat'];
    end
    cutout_emg_file = [monkey_prefix num2str(experiment_day) '_cutout_EMG_data.mat'];
    
    success_timing_dir = fullfile(common_save_dir_path, 'success_timing', num2str(experiment_day));
    cutout_dir = fullfile(common_save_dir_path, 'cutout_EMG_data');
    
    success_timing_path = fullfile(success_timing_dir, success_timing_file);
    cutout_emg_path = fullfile(cutout_dir, cutout_emg_file);
    
    disp(['SUCCESS: Saved ' success_timing_file ' to ' success_timing_path]);
    disp(['SUCCESS: Saved ' cutout_emg_file ' to ' cutout_emg_path]);
    
    % Generate trial aligned EMG and timing
    disp(['Starting to generate trial aligned EMG and timing for ' monkey_prefix num2str(experiment_day) '...']);
    [time_normalized_EMG_average, visualized_range, average_visualized_range_sample_num, average_trial_sample_num, each_timing_cutout_EMG_struct, cutout_range_struct, focus_timing_num] = generateTrialAlignedEMGandTiming(monkey_prefix, experiment_day, common_save_dir_path);
    
    % Create struct (Store the EMG trial average data around each timing in another structure)
    each_timing_cutout_mean_EMG_struct = struct();
    for timing_id = 1:focus_timing_num
        each_timing_cutout_mean_EMG_struct.(['timing' num2str(timing_id)]) = each_timing_cutout_EMG_struct.(['timing' num2str(timing_id) '_average']);
        each_timing_cutout_EMG_all_trial_struct.(['timing' num2str(timing_id)]) = each_timing_cutout_EMG_struct.(['timing' num2str(timing_id)]);
    end
    each_timing_cutout_mean_EMG_struct.whole_trial = each_timing_cutout_EMG_struct.whole_trial_average;
    each_timing_cutout_EMG_all_trial_struct.whole_trial = each_timing_cutout_EMG_struct.whole_trial;
    
    %% Save data (location: P-DATA directory)
    % Get folder path & make folder
    Pdata_fold_path = fullfile(common_save_dir_path, 'P-DATA');
    makefold(Pdata_fold_path);
    
    % Log Pdata file saving
    pdata_file = [monkey_prefix sprintf('%d',experiment_day) '_Pdata.mat'];
    pdata_path = fullfile(Pdata_fold_path, pdata_file);
    disp(['Starting to save ' pdata_file ' to ' pdata_path '...']);
    
    save(fullfile(Pdata_fold_path, pdata_file), ...
        'monkey_prefix', 'experiment_day', 'validate_file_range', 'EMG_name_list', 'transposed_success_timing', ...
        'time_normalized_EMG_average', 'visualized_range', 'average_visualized_range_sample_num', ...
        'average_trial_sample_num', 'each_timing_cutout_mean_EMG_struct', 'cutout_range_struct');
    
    disp(['SUCCESS: Saved ' pdata_file ' to ' pdata_path]);
    disp(['===== Completed processing for ' full_monkey_name ' on day ' num2str(experiment_day) ' =====']);
    disp(' ');
end

disp('===== All data processing completed successfully =====');