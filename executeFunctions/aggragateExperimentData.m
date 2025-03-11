%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[your operation]
1. Verify that the prefix of the measurement data is correct.
2. Navigate to the executeFunctions directory.
3. Change some parameters (please refer to 'set param' section)
4. Please run this code

[role of this code]
This script reads EMG data from .nev files and ECoG & timing data from AlphaOmega files. 
It then concatenates all files for a single day and merges the data into a single file 
in the format <monkey_prefix><day>-<file number>.mat. This is useful for consolidating 
scattered experimental data into a unified format for further analysis.

[saved data location]
The location of the saved file is shown in the log when this function is executed.

[execution procedure]
- Pre: None
- Post: saveLinkageInfo.m

[Improvement point(Japanese)]
+ たまにCTTL関連のデータがセーブされない時があるので、原因を探る
+ データがデカすぎてセーブできないことがあるので、使ってないチャンネルを削るようにする(サルごとに設定)
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%% set param
monkey_prefix = 'Hu'; % prefix of recorded file name
common_frequency = 1375; % [Hz]

%% code section
% get the real monkey name
full_monkey_name = getFullMonkeyName(monkey_prefix);
root_dir_path = fileparts(pwd);
base_dir_path = fullfile(root_dir_path, 'useDataFold', full_monkey_name);

disp('Please select experiment date folders for processing')
selected_experiment_day_list = uiselect(dirdir(base_dir_path),1,'Please select experiment date folders (e.g., 20241205) to process');

if isempty(selected_experiment_day_list)
    disp("user press 'cancel'");
    return;
end

for idx = 1:length(selected_experiment_day_list)
    ref_experiment_day = selected_experiment_day_list{idx};
    disp('-----------------------------------------------------------------------');
    disp(['Starting data processing for ' ref_experiment_day '...']);
    disp('-----------------------------------------------------------------------');

    % generate EMG data
    [CEMG_data_struct, amplitude_unit, record_time] = formatRippleEMGData(base_dir_path, ref_experiment_day, common_frequency);
    
    try
        % generate(concatenate) ECoG & timing data.
        [CAI_struct, CLFP_struct, CRAW_struct, CTTL_struct] = integrateAlphaOmegaData(base_dir_path, ref_experiment_day, monkey_prefix, common_frequency, record_time);
    catch
        disp('something wrong is happend')
        disp("skip to next day's data processing...")
        continue;
    end
    
    % save data
    save_dir_path = fullfile(root_dir_path, 'saveFold', full_monkey_name, 'data', 'EMG_ECoG', 'AllData');
    if not(exist(save_dir_path, "dir"))
        makefold(save_dir_path)
    end
    all_data_file_path = fullfile(save_dir_path, ['AllData_' monkey_prefix ref_experiment_day '.mat']); % this file was made to provide Roland-san.
    aggregated_experiment_data_file_path = fullfile(base_dir_path, [monkey_prefix ref_experiment_day(3:end) '-' sprintf('%04d', 1) '.mat']); % this file was made to align format with data obtained from 'Yachimun' or 'Seseki')

    saveAggregatedExperimentData(all_data_file_path, CEMG_data_struct, CAI_struct, CRAW_struct, CLFP_struct, CTTL_struct);
    saveAggregatedExperimentData(aggregated_experiment_data_file_path, CEMG_data_struct, CAI_struct, CRAW_struct, CLFP_struct, CTTL_struct);
    disp(['The data for ' ref_experiment_day ' was propely processed!!']);

    % Clear all struct variables from workspace to free memory
    workspace_vars = who;
    for var_idx = 1:length(workspace_vars)
        if isstruct(eval(workspace_vars{var_idx}))
            eval(['clear ' workspace_vars{var_idx} ';']);
        end
    end
end
disp('All processing is completed!!');
