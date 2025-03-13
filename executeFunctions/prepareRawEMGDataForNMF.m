%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[your operation]
1. Navigate to the executeFunctions directory.
2. Change some parameters (please refer to 'set param' section)
3. Please run this code & select data by following guidance (which is displayed in command window)

[role of this code]
This script processes EMG data for non-negative matrix factorization (NMF) analysis.
It extracts specific segments of EMG data based on task events, resamples the data,
and saves individual muscle data files. Various extraction modes allow focusing on
different parts of the task (full recording, trial periods, drawer or food-related events).

[saved data location]
please refer to the log displayed after running this function

[execution procedure]
- Pre: prepareEMGAndTimingData.m
- Post: filterEMGForNMF.m
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%% set param
monkey_prefix = 'Hu'; % Prefix of recorded file name
extract_EMG_type = 'only_food'; % Data extraction mode: 'full', 'only_trial', 'only_drawer', 'only_food'
padding_time = 0.5; % Padding time in seconds added before and after each segment (used when extract_EMG_type is not 'full')

%% code section
% Define timing indices for different extraction modes and monkeys
timing_indices = struct();
% Common extraction modes for all monkeys
timing_indices.full = [];

% Monkey-specific timing indices
switch monkey_prefix
    case 'Hu'
        timing_indices.only_trial = [1, 6];
        timing_indices.only_drawer = [1, 3];
        timing_indices.only_food = [4, 6];
    case 'Ni'
        timing_indices.only_trial = [1, 4];
    otherwise
        timing_indices.only_trial = [2, 5];
end

% Validate and get timing indices for the selected extraction mode
if ~isfield(timing_indices, extract_EMG_type)
    error('Invalid extraction mode: %s. Available modes: %s', extract_EMG_type, ...
          strjoin(fieldnames(timing_indices), ', '));
end
trim_start_end_timings = timing_indices.(extract_EMG_type);

% Get full monkey name and set paths
full_monkey_name = getFullMonkeyName(monkey_prefix);
root_dir_path = fileparts(pwd);

% Get the file names of cutout EMG data
cutout_EMG_data_dir_path = fullfile(root_dir_path, 'saveFold', full_monkey_name, 'data', 'EMG_ECoG', 'cutout_EMG_data');
disp('Please select all "_cutout_EMG_data" file you want to pre-process');
cutout_EMG_data_list = uigetfile('MultiSelect', 'on', cutout_EMG_data_dir_path);

if isequal(cutout_EMG_data_list, 0)
    disp('User pressed "cancel" button');
    return;
elseif ischar(cutout_EMG_data_list)
    cutout_EMG_data_list = {cutout_EMG_data_list};
end

day_num = length(cutout_EMG_data_list);
common_save_data_path = fullfile(root_dir_path, 'saveFold', full_monkey_name, 'data', 'Synergy', 'row_EMG_data', extract_EMG_type);

% Process each selected data file
for session_id = 1:day_num
    ref_cutout_EMG_data_file_name = cutout_EMG_data_list{session_id};
    ref_cutout_EMG_data_struct = load(fullfile(cutout_EMG_data_dir_path, ref_cutout_EMG_data_file_name)); 

    unique_save_dir_name = strrep(ref_cutout_EMG_data_file_name, '_cutout_EMG_data.mat', '');
    % Extract and save EMG data for each muscle
    extractAndSaveEMGPerMuscle(common_save_data_path, unique_save_dir_name, ref_cutout_EMG_data_struct, extract_EMG_type, trim_start_end_timings, padding_time)
end

