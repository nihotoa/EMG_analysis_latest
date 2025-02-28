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

[Improvement points(Japanaese)]
+ �g�p�����ؓd�̐����l������K�v������̂ŁA�f�B���N�g����������K�w�ǉ�����
+ VisualizeSynergyWeights�̃Z�[�u�f�[�^��ύX�����̂ŁA����ɑΉ�����悤�Ƀ��t�@�N�^�����O
+ K��p����test�f�[�^��A��������Ƃ��낪kf=4�̑O��ŏ�����Ă���̂ŉ��P����
+ �^�C�~���O�̐���4�ł���O��ŏ�����Ă���̂ŁA���P����(plotEasyData_utb�Ƃ��Ȃ莗��pre�Ƃ���)
+ tim�����߂�ۂ̃_�E���T���v�����O��̃T���v�����O���g����100Hz�̑O��ŏ�����Ă���̂ŉ��P����
+ alignData��,alignDataEX��plotEasyData_utb�ƑS���������̂��g���Ă���̂ŁA���[�J���֐��ł͂Ȃ��āA�Ɨ������֐��Ƃ��č���āA
�����ǂݍ���Ŏg���悤�ɕύX����
+ use_EMG_type = 'full'�̎��̓���m�F�͂��ĂȂ�
+ pre��post�ŋ�Ԋ�ꂪ�Ⴄ�̂ɓ���Pdata�Ƃ��ĕۑ������͈̂�a������̂ŁA�΍���l����
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%% set param
term_select_type = 'manual'; %'auto' / 'manual'
term_type = 'all'; %(if term_select_type == 'auto') pre / post / all 
monkeyname = 'Hu';
use_EMG_type = 'only_task'; %' full' / 'only_task'
synergy_num = 4; % number of synergy you want to analyze

range_struct = struct();
% change the range of trimming for each monkey
switch monkeyname
    case 'Ni'
        range_struct.trig1_per = [50 50];
        range_struct.trig2_per = [50 50];
        range_struct.trig3_per = [50 50];
        range_struct.trig4_per = [50 50];
        range_struct.task_per = [25,105];
    case 'Hu'
        range_struct.trig1_per = [50 50];
        range_struct.trig2_per = [50 50];
        range_struct.trig3_per = [50 50];
        range_struct.trig4_per = [50 50];
        range_struct.trig5_per = [50 50];
        range_struct.trig6_per = [50 50];
        range_struct.task_per = [25,105];
    otherwise
        range_struct.trig1_per = [50 50];
        range_struct.trig2_per = [50 50];
        range_struct.trig3_per = [50 50];
        range_struct.trig4_per = [50 50];
        range_struct.task_per = [25,105];
end

%% code section
realname = get_real_name(monkeyname);
root_dir = fileparts(pwd);
base_dir = fullfile(root_dir, 'saveFold', realname, 'data', 'Synergy');
synergy_detail_data_dir = fullfile(base_dir, 'synergy_detail', use_EMG_type);
daily_synergy_data_dir = fullfile(base_dir, 'daily_synergy_analysis_results');
extracted_synergy_data_dir = fullfile(base_dir, 'extracted_synergy', use_EMG_type);

unique_name_cell = getGroupedDates(synergy_detail_data_dir, monkeyname, term_select_type, term_type);
if isempty(unique_name_cell)
    disp('user pressed "cancel" button');
    return;
end

% load order information (as order_data_struct)
selected_day_num = length(unique_name_cell);
selected_day_name_cell = strrep(unique_name_cell, monkeyname, '');

day_range_folder_name = [monkeyname selected_day_name_cell{1} 'to' selected_day_name_cell{end} '_' num2str(selected_day_num)];
synergy_across_sessions_data_dir = fullfile(base_dir, 'synergy_across_sessions', use_EMG_type, ['synergy_num==' num2str(synergy_num)], day_range_folder_name);
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
ResAVE.tData1_AVE = cell(1,synergy_num);
ResAVE.tData2_AVE = cell(1,synergy_num);
ResAVE.tData3_AVE = cell(1,synergy_num);
ResAVE.tData4_AVE = cell(1,synergy_num);
ResAVE.tDataTask_AVE = cell(1,synergy_num);

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
        timing_data_for_filtered_EMG = floor(timing_data_struct.Tp ./ (timing_data_struct.SampleRate/100)); % down sample (to 100Hz)
    end

   [trial_num, ~] = size(timing_data_for_filtered_EMG);
   pre_per = 50; % How long do you want to see the signals before 'lever1 on' starts.
   post_per = 50; % How long do you want to see the signals after 'lever2 off' starts.
   
   % Cut out synergyH for each trial
   [alignedData, alignedDataAVE, AllT, Timing_ave, ~, ~, TIME_W] = alignData(all_H{date_id}', timing_data_for_filtered_EMG, trial_num, pre_per, post_per, synergy_num, monkeyname);
   taskRange = [-1*pre_per, 100+post_per];

    % Cut out synergyH for each trial, around each timing.
   [Res, timing_num] = alignDataEx(alignedData, timing_data_for_filtered_EMG, range_struct, pre_per, TIME_W, synergy_num, monkeyname);

   % Store the information about the cut out range around each timing in structure range_struct
  range_struct.LdTask = length(Res.tDataTask_AVE{1});
  range_struct.RangeTask = range_struct.task_per;
  ResAVE.tDataTask_AVE = Res.tDataTask_AVE;
  for timing_id = 1:timing_num
      range_struct.(['Ld' num2str(timing_id)]) = length(Res.(['tData' num2str(timing_id) '_AVE']){1});
      range_struct.(['Range' num2str(timing_id)]) = range_struct.(['trig' num2str(timing_id) '_per']);
      ResAVE.(['tData' num2str(timing_id) '_AVE']) = Res.(['tData' num2str(timing_id) '_AVE']);
  end
   
   % save data
   xpdate = selected_day_name_cell(date_id);

   % Specify the path of the directory to save
   save_fold_path = fullfile(fileparts(synergy_across_sessions_data_dir), 'temporal_pattern_data');
   save_file_name = [ref_day_unique_name '_Pdata.mat'];
   
   % save data
   makefold(save_fold_path);
   D = range_struct; % to be consistent with legacy codes
   save(fullfile(save_fold_path, save_file_name), 'monkeyname','xpdate','D',...
                                                     'alignedDataAVE', 'ResAVE',...
                                                     'AllT','TIME_W','Timing_ave','taskRange');
   disp(['H_data is saved as: ' fullfile(save_fold_path, save_file_name)]);
end


