%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[your operation]
1. Change some parameters (please refer to 'set param' section)
2. Please run this code & select data by following guidance (which is displayed in command window after Running this code)

[role of this code]
concatenate & create one-day EMG data (with resampling(5000Hz)) & save individual muscle data as '(uv).mat' 

[Saved data location]
location: Yachimun/new_nmf_result/'~_standard' (ex.) F170516_standard
file name: muscle_name(uV).mat (ex.) PL(uV).mat

[procedure]
pre:runningEasyfunc.m
post:filterBat_SynNMFPre.m

[Improvement points(Japanaese)]
・ファイルを連結する時に, 連番じゃ無いものは対応していないことを念頭に置いておく
(例)file 002, file004が使用するファイルだった時にはエラー吐く(002, 003, 004をloadしようとするから)
・Yachimunのほうで、'only_task'に対応していないので、追加する
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%% set param
monkey_name = 'Hu'; % prefix of file
extract_EMG_type = 'only_task'; % 'only_task', 'full'
padding_time = 0.5; % (if extract_EMG_type == 'only_task') unit is [second], the seconds of extract data added to the 'task_start' and 'task_end' of each trial

%% code section
switch monkey_name
    case 'Hu'
        task_start_end_timing_id = [1, 6];
    case {'F', 'Ya'}
        task_start_end_timing_id = [2, 5];
end

real_name = get_real_name(monkey_name);
root_dir = fileparts(pwd);

%  get the file name of  'cutout_EMG_data'
cutout_EMG_data_fold_path = fullfile(root_dir, 'saveFold', real_name, 'data', 'EMG_ECoG', 'cutout_EMG_data_list');
disp('Please select all "_cutout_EMG_data" file you want to pre-process');
cutout_EMG_data_list = uigetfile('MultiSelect', 'on', cutout_EMG_data_fold_path);

if isequal(cutout_EMG_data_list, 0)
    disp('user press "cancel" button');
    return;
elseif ischar(cutout_EMG_data_list)
    cutout_EMG_data_list = {cutout_EMG_data_list};
end

day_num = length(cutout_EMG_data_list);
common_save_fold_path = fullfile(root_dir, 'saveFold', real_name, 'data', 'Synergy', 'row_EMG_data', extract_EMG_type);

% combine multiple data for one day into a single data
for session_id = 1:day_num
   ref_cutout_EMG_data_file_name = cutout_EMG_data_list{session_id};
   load(fullfile(cutout_EMG_data_fold_path, ref_cutout_EMG_data_file_name), 'AllData_EMG', 'SampleRate', 'EMGs', 'TimeRange_EMG', 'Tp', 'Unit'); 
   
   unique_save_fold_name = strrep(ref_cutout_EMG_data_file_name, '_cutout_EMG_data.mat', '');
   % concatenate experiment data and save each EMG as individual file
   MakeData4nmf(common_save_fold_path, unique_save_fold_name, EMGs, SampleRate, AllData_EMG, TimeRange_EMG, Unit, extract_EMG_type, Tp, task_start_end_timing_id, padding_time)
end

%% define local function

% [role of this function] concatenate experiment data and save each EMG as individual file
function [] = MakeData4nmf(common_save_fold_path, unique_save_folder_name, EMGs, SampleRate, AllData_EMG, TimeRange, Unit, extract_EMG_type, event_timing_data, task_start_end_timing_id, padding_time)
EMG_num = length(EMGs);
% save EMG data as .mat file for nmf
save_fold_path = fullfile(common_save_fold_path, unique_save_folder_name);
makefold(save_fold_path)

% preparation of EMG to be saved
switch extract_EMG_type
    case 'full'
        extracted_EMG = transpose(AllData_EMG);
    case 'only_task'
        % compile task event timing data which is necxesarry for cutting out EMG
        task_start_event_timing = event_timing_data(:, task_start_end_timing_id(1));
        task_end_event_timing = event_timing_data(:, task_start_end_timing_id(2));
        task_start_end_timing_list = [task_start_event_timing, task_end_event_timing];
        
        % create empty array to store EMG data to be cut out
        trial_num = size(task_start_end_timing_list, 1);
        extracted_EMG = cell(EMG_num, 1);
        event_timings_after_trimmed = zeros(size(event_timing_data));
        
        % perform cutout
        for EMG_id = 1:EMG_num
            ref_EMG = transpose(AllData_EMG(:, EMG_id));
            trimmed_EMG = cell(1, trial_num);
            next_start_sample_idx = 0;
            for trial_id = 1:trial_num
                % extract 'task_start' and 'task_start' event timings of the reference trial.
                ref_trial_range = task_start_end_timing_list(trial_id, :);
                ref_task_start_timing = ref_trial_range(1);
                ref_task_end_timing = ref_trial_range(2);
                cutout_start_timing = (ref_task_start_timing+1) - ceil(SampleRate * padding_time);
                cutout_end_timing = ref_task_end_timing + floor(SampleRate * padding_time);
                
                % cut out EMG according to 'cutout_start_timing' 'cutout_end_timing ' 
                cut_out_EMG = ref_EMG(cutout_start_timing: cutout_end_timing);
                trimmed_EMG{trial_id} = cut_out_EMG;
                
                % modify event data
                ref_event_timing_data = event_timing_data(trial_id, :);
                event_timing_in_this_trial = ref_event_timing_data - cutout_start_timing ;
                event_timings_after_trimmed(trial_id, :) = event_timing_in_this_trial+ next_start_sample_idx;
                next_start_sample_idx = next_start_sample_idx + (cutout_end_timing - cutout_start_timing);
            end
            extracted_EMG{EMG_id} = cell2mat(trimmed_EMG);
        end
        extracted_EMG = cell2mat(extracted_EMG);
end

% save each muscle EMG data to a file
Class = 'continuous channel';
switch extract_EMG_type
    case 'full'
        save_file_suffix = ['(' Unit ').mat'];
        vars_to_save = {'TimeRange', 'Name', 'Class', 'SampleRate', 'Data', 'Unit'};
    case 'only_task'
        save_file_suffix = ['(' Unit ')_trimmed.mat'];
        vars_to_save = {'TimeRange', 'Name', 'Class', 'SampleRate', 'Data', 'Unit', 'event_timings_after_trimmed'};
        sample_num = size(extracted_EMG, 2);
        TimeRange = [0, sample_num / SampleRate];
end

for EMG_id = 1:EMG_num
    Name = cell2mat(EMGs(EMG_id,1));
    Data = extracted_EMG(EMG_id, :);
    save_file_name = [cell2mat(EMGs(EMG_id,1)) save_file_suffix];
    save(fullfile(save_fold_path, save_file_name), vars_to_save{:});
    disp([fullfile(save_fold_path, save_file_name) ' was generated successfully!!']);
end
end

