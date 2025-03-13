%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[your operation]
1. Change some parameters (please refer to 'set param' section)
2. Please run this code & select data by following guidance (which is displayed in command window after Running this code)

[role of this code]
+ cut out the temporal pattern of muscle synergy for each trial and put it into array
+ save data which is related in displaying temporal synergy

[Saved data location]
location: 
    EMG_analysis/data/Yachimun/new_nmf_result/synData/

[procedure]
pre: visualizeSynergyWeights.m
post: visualizeEMGAndSynergy.m

[caution!!]
In order to use the function 'resample', 'signal processing toolbox' must be installed

%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%% set param
term_select_type = 'manual'; %'auto' / 'manual'
period_type = 'all'; %(if term_select_type == 'auto') pre / post / all
monkey_prefix = 'Hu';
use_EMG_type = 'only_trial'; %' full' / 'only_trial'
synergy_num = 4; % number of synergy you want to analyze

range_struct = struct();
% change the range of trimming for each monkey
switch monkey_prefix
    case 'Ni'
        range_struct.timing1_pre_post_percentage = [50 50];
        range_struct.timing2_pre_post_percentage = [50 50];
        range_struct.timing3_pre_post_percentage = [50 50];
        range_struct.timing4_pre_post_percentage = [50 50];
        range_struct.whole_trial_percentage= [25,105];
    case 'Hu'
        range_struct.timing1_pre_post_percentage = [50 50];
        range_struct.timing2_pre_post_percentage = [50 50];
        range_struct.timing3_pre_post_percentage = [50 50];
        range_struct.timing4_pre_post_percentage = [50 50];
        range_struct.timing5_pre_post_percentage= [50 50];
        range_struct.timing6_pre_post_percentage= [50 50];
        range_struct.whole_trial_percentage= [25,105];
    otherwise
        range_struct.timing1_pre_post_percentage = [50 50];
        range_struct.timing2_pre_post_percentage = [50 50];
        range_struct.timing3_pre_post_percentage = [50 50];
        range_struct.timing4_pre_post_percentage = [50 50];
        range_struct.whole_trial_percentage= [25,105];
end

%% code section
full_monkey_name = getFullMonkeyName(monkey_prefix);
root_dir_path = fileparts(pwd);
base_dir_path = fullfile(root_dir_path, 'saveFold', full_monkey_name, 'data', 'Synergy');
synergy_detail_data_dir = fullfile(base_dir_path, 'synergy_detail', use_EMG_type);
daily_synergy_data_dir = fullfile(base_dir_path, 'daily_synergy_analysis_results');
extracted_synergy_data_dir = fullfile(base_dir_path, 'extracted_synergy', use_EMG_type);

unique_name_cell = getGroupedDates(synergy_detail_data_dir, monkey_prefix, term_select_type, period_type);
if isempty(unique_name_cell)
    disp('user pressed "cancel" button');
    return;
end

% load order information (as order_data_struct)
selected_day_num = length(unique_name_cell);
selected_day_name_cell = strrep(unique_name_cell, monkey_prefix, '');

day_range_folder_name = [monkey_prefix selected_day_name_cell{1} 'to' selected_day_name_cell{end} '_' num2str(selected_day_num)];
synergy_across_sessions_data_dir = fullfile(base_dir_path, 'synergy_across_sessions', use_EMG_type, ['synergy_num==' num2str(synergy_num)], day_range_folder_name);
order_data_file_path = fullfile(synergy_across_sessions_data_dir, 'sort_order_info.mat');
if not(exist(order_data_file_path, "file"))
    error(['There was no file in the "order_tim_list" directory corresponding to the synergy number and date combination you selected.' ...
        '      Please run "visualizeSynergyWeights.m" with the same date combination & synergy_num first to create "order_tim_list" file']);
end
order_data_struct = load(order_data_file_path);
EMG_num = order_data_struct.EMG_num;

% Create an empty array to store the synergy time pattern (synergy H)
all_H = cell(1, selected_day_num);

%% Linking temporal pattern data(synergy H) & arrange order of Synergies between each date.
cutout_flag_list = false(1, selected_day_num);
for date_id =1:selected_day_num %session loop
    % Get the path of the data to be accessed.
    ref_day_unique_name = unique_name_cell{date_id};
    ref_extracted_synergy_folder_path = fullfile(extracted_synergy_data_dir, ref_day_unique_name);
    ref_extracted_synergy_file_name = ['t_' ref_day_unique_name '.mat'];
    
    synergy_tuning_folder_path = fullfile(daily_synergy_data_dir, ref_day_unique_name, ['synergy_num==' num2str(synergy_num )], use_EMG_type, 'H_data');
    synergy_tuning_file_name = 'mean_H_data.mat';

    % order_in_section_struct is the order data required for the linkage of 'test' data to each other.
    try 
        synergy_tuning_info_strurct = load(fullfile(synergy_tuning_folder_path, synergy_tuning_file_name), 'k_arr', 'Wt_coefficient_matrix');
    catch
        disp([unique_name_cell{date_id} 'does not have "mean_H_data.mat"']);
        continue;
    end

    % Get 'test' data on the number of synergies of the target & Concatenate all 'test' data for each synergy.
    synergy_data = load(fullfile(ref_extracted_synergy_folder_path, ref_extracted_synergy_file_name));
    H_data = synergy_data.test.H; % Data on synergy_H at each synergy number.
    [~, segment_num] = size(synergy_tuning_info_strurct.k_arr);
    use_H_data = H_data(synergy_num, :);
    alt_H = cell(1, segment_num);

    for segment_id = 1:segment_num
        sort_order = synergy_tuning_info_strurct.k_arr(:, segment_id);
        for align_id = 1:length(sort_order)
            sort_id = sort_order(align_id);
            alt_H{segment_id}(align_id, :) = use_H_data{segment_id}(sort_id, :) * synergy_tuning_info_strurct.Wt_coefficient_matrix{segment_id}(align_id);
        end
    end
    alt_H = cell2mat(alt_H);

    % Store the concatenated day-by-day synergies in the order of the first day's synergies.
    % Extracting the order of synergies of date(date_id) from 'k_arr'
    day_index =  find(order_data_struct.selected_days==str2double(selected_day_name_cell{date_id}));
    synergy_order = order_data_struct.k_arr(:, day_index); 
    all_H{date_id} = alt_H(synergy_order, :);
    
    % change the flag that determines whether the data of reference day has been cut out or not
    if isfield(synergy_data, 'event_timings_after_trimmed')
        cutout_flag_list(date_id) = true;
    end
end


%%  Cut out synergy H around each task timing.

% Creating arrays from which to store data.
each_timing_cutout_mean_EMG_struct.tData1_AVE = cell(1,synergy_num);
each_timing_cutout_mean_EMG_struct.tData2_AVE = cell(1,synergy_num);
each_timing_cutout_mean_EMG_struct.tData3_AVE = cell(1,synergy_num);
each_timing_cutout_mean_EMG_struct.tData4_AVE = cell(1,synergy_num);
each_timing_cutout_mean_EMG_struct.tDataTask_AVE = cell(1,synergy_num);

% Cutting out synergy H data for each date.
for date_id = 1:selected_day_num 
    ref_flag = cutout_flag_list(date_id);
    ref_day_unique_name = unique_name_cell{date_id};
    if ref_flag
        ref_extracted_synergy_folder_path = fullfile(extracted_synergy_data_dir, ref_day_unique_name);
        ref_extracted_synergy_file_name = ['t_' ref_day_unique_name '.mat'];
        tentetive = load(fullfile(ref_extracted_synergy_folder_path, ref_extracted_synergy_file_name));
        timing_data_for_filtered_EMG = tentetive.event_timings_after_trimmed;
    else
         % get the path of EasyData(which contains each timing data)
        easy_data_fold_path = fullfile(monkey_dir_path, 'easyData', ref_day_unique_name);
        easy_data_file_name = [ref_day_unique_name '_EasyData.mat'];
    
        timing_data_struct = load(fullfile(easy_data_fold_path, easy_data_file_name)); % load the timing data of each trial
        timing_data_for_filtered_EMG = floor(timing_data_struct.transposed_success_timing ./ (timing_data_struct.SampleRate/100)); % down sample (to 100Hz)
    end

   [trial_num, ~] = size(timing_data_for_filtered_EMG);
   pre_task_percentage = 50; % How long do you want to see the signals before 'lever1 on' starts.
   post_task_percentage = 50; % How long do you want to see the signals after 'lever2 off' starts.
   
   % Cut out synergyH for each trial
   [time_normalized_EMG, time_normalized_EMG_average, average_visualized_range_sample_num, Timing_ave, ~, ~, average_trial_sample_num] = createTimeNormalizedTrialData(all_H{date_id}', timing_data_for_filtered_EMG, trial_num, pre_task_percentage, post_task_percentage, synergy_num, monkey_prefix);
   task_range = [-1*pre_task_percentage, 100+post_task_percentage];

    % Cut out synergyH for each trial, around each timing.
   [each_timing_cutout_EMG_struct, timing_num] = extractEventCenteredSegments(time_normalized_EMG, timing_data_for_filtered_EMG, range_struct, pre_task_percentage, average_trial_sample_num, synergy_num, monkey_prefix);

   % Store the information about the cut out range around each timing in structure range_struct
  range_struct.LdTask = length(each_timing_cutout_EMG_struct.tDataTask_AVE{1});
  range_struct.RangeTask = range_struct.whole_trial_percentage;
  each_timing_cutout_mean_EMG_struct.tDataTask_AVE = each_timing_cutout_EMG_struct.tDataTask_AVE;
  for timing_id = 1:timing_num
      range_struct.(['Ld' num2str(timing_id)]) = length(each_timing_cutout_EMG_struct.(['timing' num2str(timing_id) '_AVE']){1});
      range_struct.(['Range' num2str(timing_id)]) = range_struct.(['trig' num2str(timing_id) '_per']);
      each_timing_cutout_mean_EMG_struct.(['timing' num2str(timing_id) '_AVE']) = each_timing_cutout_EMG_struct.(['timing' num2str(timing_id) '_AVE']);
  end
   
   % save data
   experiment_day = selected_day_name_cell(date_id);

   % Specify the path of the directory to save
   save_fold_path = fullfile(fileparts(synergy_across_sessions_data_dir), 'temporal_pattern_data');
   save_file_name = [ref_day_unique_name '_Pdata.mat'];
   
   % save data
   makefold(save_fold_path);
   cutout_range_struct = range_struct; % to be consistent with legacy codes
   save(fullfile(save_fold_path, save_file_name), 'monkey_prefix','experiment_day','cutout_range_struct',...
                                                     'time_normalized_EMG_average', 'each_timing_cutout_mean_EMG_struct',...
                                                     'average_visualized_range_sample_num','average_trial_sample_num','Timing_ave','task_range');
   disp(['H_data is saved as: ' fullfile(save_fold_path, save_file_name)]);
end


