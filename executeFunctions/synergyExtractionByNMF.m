%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[your operation]
1. Navigate to the executeFunctions directory.
2. Change some parameters (please refer to 'set param' section)
3. Run this code and select data following the guidance displayed in the command window.

[role of this code]
This script performs muscle synergy analysis using Non-negative Matrix Factorization (NMF)
and saves the results as .mat files. It extracts synergy patterns from preprocessed EMG data
and evaluates their quality through cross-validation.

[saved data location]
The location of the saved file is shown in the log when this function is executed.

[execution procedure]
- Pre: filterEMGForNMF.m
- Post: 
  - To plot VAF value: visualizeVAF.m
  - To find optimal synergy numbers: determineOptimalSynergyNumber.m
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;

%% Set parameters
% Subject information
monkey_prefix = 'Hu';      % Prefix of recorded data (e.g., 'Hu')
use_EMG_type = 'only_trial'; % Data extraction mode: 'full', 'only_trial', 'only_drawer', 'only_food'

% NMF analysis parameters
segment_num = 4;           % Number of parts for cross-validation
search_iteration_num = 20;  % Number of repetitions for synergy search
shuffle_flag = true;       % Whether to perform shuffle analysis (0: off, 1: number of shuffles)
NMF_algorithm_type = 'mult'; % NMF algorithm ('mult': Multiplicative Update, 'als': Alternating Least Squares)

%% Initialize paths and settings
root_dir_path = fileparts(pwd);
warning('off');

% Get the full monkey name and set base directory
full_monkey_name = getFullMonkeyName(monkey_prefix);
base_dir_path = fullfile(root_dir_path, 'saveFold', full_monkey_name, 'data', 'Synergy', 'filtered_EMG_data', use_EMG_type);

%% Select folders and EMG data files
% Select day folders for analysis
disp('【Please select all day folders you want to analyze (Multiple selections are possible)】')
day_folder_list = uiselect(dirdir(base_dir_path), 1, 'Please select folders containing the data you want to analyze');

if isempty(day_folder_list)
    disp('User pressed cancel. No folders selected. Exiting process.');
    return;
end

% Select EMG files to analyze
ref_day_folder = day_folder_list{1};
filtered_EMG_file_list = sortxls(dirmat(fullfile(base_dir_path, ref_day_folder)));
disp('【Please select used EMG Data】')
filtered_EMG_file_list = uiselect(filtered_EMG_file_list, 1, 'Please select all filtered muscle data');

if isempty(filtered_EMG_file_list)
    disp('User pressed cancel. No muscle data selected. Exiting process.');
    return;
end

%% Set output directories
use_EMG_num = length(filtered_EMG_file_list);
common_synergy_detail_save_dir = fullfile(strrep(base_dir_path, 'filtered_EMG_data', 'synergy_detail'), ['use_EMG_num == ' num2str(use_EMG_num)]);
common_extracted_synergy_save_dir = fullfile(strrep(base_dir_path, 'filtered_EMG_data', 'extracted_synergy'), ['use_EMG_num == ' num2str(use_EMG_num)]);

%% Process each day folder and extract synergies
day_num = length(day_folder_list);
muscle_num = length(filtered_EMG_file_list);

for day_id = 1:day_num
    ref_day_folder = day_folder_list{day_id};
    disp([num2str(day_id), '/', num2str(day_num), ': Processing day folder: ', ref_day_folder]);

    % Load and organize EMG data for all selected muscles
    EMG_dataset = zeros(muscle_num, 0);  % Will be resized after loading first muscle
    muscle_name = cell(muscle_num, 1);
    
    for muscle_id = 1:muscle_num
        % Clear previous data and get file path
        clear('ref_filtered_EMG_data_struct');
        ref_filtered_EMG_file = filtered_EMG_file_list{muscle_id};
        ref_filtered_EMG_file_path = fullfile(base_dir_path, ref_day_folder, ref_filtered_EMG_file);

        % Load event timings from the first muscle file if needed
        if muscle_id == 1 && ~strcmp(use_EMG_type, 'full')
            load(ref_filtered_EMG_file_path, 'event_timings_after_trimmed');
        end

        % Load EMG data
        ref_filtered_EMG_data_struct = load(ref_filtered_EMG_file_path);
        ref_filtered_EMG = ref_filtered_EMG_data_struct.EMG_data;

        % Initialize data matrix after loading first muscle
        if muscle_id == 1
            EMG_dataset = zeros(muscle_num, size(ref_filtered_EMG, 2));
        end
        
        % Store EMG data and muscle name
        EMG_dataset(muscle_id, :) = ref_filtered_EMG;
        muscle_name{muscle_id} = ref_filtered_EMG_data_struct.muscle_name;
    end

    % Preprocess EMG data
    EMG_dataset = offset(EMG_dataset, 'min');    % Offset to make minimum value 0
    EMG_dataset = normalize(EMG_dataset, 'mean'); % Normalize each EMG by its mean
    EMG_dataset(EMG_dataset < 0) = 0;             % Set negative values to 0

    % Extract muscle synergies using NMF
    [synergy_detail_struct, extracted_synergy_struct] = performCustomNMF(EMG_dataset, segment_num, search_iteration_num, shuffle_flag, NMF_algorithm_type);

    % Add metadata to the synergy structures
    % Basic information
    synergy_detail_struct.muscle_name = muscle_name;
    synergy_detail_struct.AnalysisType = 'EMGNMF';
    synergy_detail_struct.TargetName = muscle_name;
    
    % Technical information from the first loaded EMG data
    synergy_detail_struct.Info.Class = ref_filtered_EMG_data_struct.Class;
    synergy_detail_struct.Info.resample_rate = ref_filtered_EMG_data_struct.resample_rate;
    synergy_detail_struct.Info.Unit = ref_filtered_EMG_data_struct.Unit;
    
    % EMG type information
    synergy_detail_struct.use_EMG_type = use_EMG_type;
    extracted_synergy_struct.use_EMG_type = use_EMG_type;
    
    % Add event timing information if available
    if ~strcmp(use_EMG_type, 'full')
        synergy_detail_struct.event_timings_after_trimmed = event_timings_after_trimmed;
        extracted_synergy_struct.event_timings_after_trimmed = event_timings_after_trimmed;
    end

    % Create directories and save results
    extracted_synergy_save_dir = fullfile(common_extracted_synergy_save_dir);
    synergy_detail_save_dir = fullfile(common_synergy_detail_save_dir);
    makefold(extracted_synergy_save_dir);
    makefold(synergy_detail_save_dir);

    % Define filenames
    extracted_synergy_file_name = [ref_day_folder '_extracted_synergy_data.mat'];
    synergy_detail_file_name = [ref_day_folder '_synergy_detail.mat'];

    % Save the synergy data
    save(fullfile(extracted_synergy_save_dir, extracted_synergy_file_name), '-struct', 'extracted_synergy_struct');
    disp(['Saved synergy data to: ', fullfile(extracted_synergy_save_dir, extracted_synergy_file_name)]);
    
    save(fullfile(synergy_detail_save_dir, synergy_detail_file_name), '-struct', 'synergy_detail_struct');
    disp(['Saved synergy details to: ', fullfile(synergy_detail_save_dir, synergy_detail_file_name)]);
end

warning('on');