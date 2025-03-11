%{
[Function Description]
This function processes EMG data by aligning it to trial events and extracting segments
centered around specific timing events. It applies filtering, time normalization, and
segmentation to prepare EMG data for further analysis. The function handles different
monkey-specific timing structures and creates standardized data formats.

[Input Arguments]
monkey_prefix: [char] Prefix identifying the monkey (e.g., 'Ni', 'Hu', 'Ya')
experiment_day_double: [double] Date of experiment in numeric format
save_fold: [char] Directory path where data is saved (typically 'easyData')
base_dir: [char] Optional base directory path (if not provided, pwd is used)

[Output Arguments]
time_normalized_EMG_average: [cell array] Average EMG activity across all trials for each channel
visualized_range: [double array] Range of cutout window as percentage of trial duration
average_visualized_range_sample_num: [double] Average number of samples in the visualized range
average_trial_sample_num: [double] Average number of samples per trial
each_timing_cutout_EMG_struct: [struct] EMG data centered on each timing event with fields:
    - timingX: [cell array] EMG data around timing event X
    - timingX_average: [cell array] Average EMG data around timing event X
focus_timing_num: [double] Number of timing events being analyzed
cutout_range_struct: [struct] Information about cutout ranges with fields:
    - timingX_pre_post_percentage: [double array] Pre/post percentages for timing X
    - whole_trial_percentage: [double array] Pre/post percentages for whole trial
    - timingX_average_sample_num: [double] Average sample count for timing X
    - filter_parameters_struct: [struct] Filter parameters used
%}

function [time_normalized_EMG_average, visualized_range, average_visualized_range_sample_num, average_trial_sample_num, each_timing_cutout_EMG_struct, cutout_range_struct, focus_timing_num] = generateTrialAlignedEMGandTiming(monkey_prefix, experiment_day_double, save_fold)
%% get informations(path of save_folder, EMG data, timing data ,etc...)
experiment_day = sprintf('%d',experiment_day_double);

% get the path of save_fold
load(fullfile(save_fold, 'cutout_EMG_data', [monkey_prefix experiment_day '_cutout_EMG_data.mat']), 'concatenated_EMG_data', 'transposed_success_timing', 'common_sample_rate', 'EMG_name_list'); 
EMG_num = length(EMG_name_list);
[trial_num, ~] = size(transposed_success_timing);  

%% filter EMG
[filtered_EMG_data, resampled_timing_data, filter_parameters_struct] = filterEMG(concatenated_EMG_data, common_sample_rate, EMG_num, transposed_success_timing);

%% Cut out EMG data for each trial(& perform time normalization(Normalize from 'lever1 on' to 'lever1 off' as 100%))

%define time window
pre_task_percentage = 50; 
post_task_percentage = 50;

% Trim EMG data for each trial & perform time normalization for each trial
[time_normalized_EMG, time_normalized_EMG_average, average_visualized_range_sample_num, average_trial_sample_num] = createTimeNormalizedTrialData(filtered_EMG_data, resampled_timing_data,trial_num,pre_task_percentage,post_task_percentage, EMG_num, monkey_prefix);

% Setting the range to be cut out around each timing
visualized_range = [-1*pre_task_percentage, 100+post_task_percentage];
cutout_range_struct = struct();

% change the range of trimming for each monkey
switch monkey_prefix
    case 'Ni'
        cutout_range_struct.timing1_pre_post_percentage = [50 50];
        cutout_range_struct.timing2_pre_post_percentage = [50 50];
        cutout_range_struct.timing3_pre_post_percentage = [50 50];
        cutout_range_struct.timing4_pre_post_percentage = [50 50];
        cutout_range_struct.whole_trial_percentage= [25,105];
    case 'Hu'
        cutout_range_struct.timing1_pre_post_percentage = [50 50];
        cutout_range_struct.timing2_pre_post_percentage = [50 50];
        cutout_range_struct.timing3_pre_post_percentage = [50 50];
        cutout_range_struct.timing4_pre_post_percentage = [50 50];
        cutout_range_struct.timing5_pre_post_percentage= [50 50];
        cutout_range_struct.timing6_pre_post_percentage= [50 50];
        cutout_range_struct.whole_trial_percentage= [25,105];
    otherwise
        cutout_range_struct.timing1_pre_post_percentage = [50 50];
        cutout_range_struct.timing2_pre_post_percentage = [50 50];
        cutout_range_struct.timing3_pre_post_percentage = [50 50];
        cutout_range_struct.timing4_pre_post_percentage = [50 50];
        cutout_range_struct.whole_trial_percentage= [25,105];
end

% Centering on each timing, trim & get EMG data around it
[each_timing_cutout_EMG_struct, focus_timing_num] = extractEventCenteredSegments(time_normalized_EMG,resampled_timing_data, cutout_range_struct,pre_task_percentage,average_trial_sample_num,EMG_num, monkey_prefix);

% Summary of trimming details(length of trimmed data, cut out range around each timing)
for timing_id = 1:focus_timing_num
    cutout_range_struct.(['timing' num2str(timing_id) '_average_sample_num']) = length(each_timing_cutout_EMG_struct.(['timing' num2str(timing_id) '_average']){1});
end
cutout_range_struct.filter_parameters_struct = filter_parameters_struct;
end