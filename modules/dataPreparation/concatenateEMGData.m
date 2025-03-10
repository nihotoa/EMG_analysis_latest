%{
[Function Description]
This function concatenates EMG data from multiple recording files into a single continuous dataset.
It loads EMG data from each file in the specified range, combines them in chronological order,
and returns the concatenated data along with timing information. The function handles
data from different monkeys and experimental setups.

[Input Arguments]
monkey_prefix: [char] Prefix identifying the monkey
experiment_day: [char] Date of experiment as a string
validate_file_range: [double array] Range of files to process
EMG_num: [integer] Number of EMG channels
full_monkey_name: [char] Full name of the monkey

[Output Arguments]
concatenated_EMG_data: [double array] Combined EMG data from all files with dimensions
    [samples x channels]
TimeRange: [double array] Time range of the concatenated data [start_time, end_time]
original_EMG_SR: [double] Original sampling rate of the EMG data in Hz
%}

function [concatenated_EMG_data, TimeRange, original_EMG_SR] = concatenateEMGData(monkey_prefix, experiment_day, validate_file_range, EMG_num, full_monkey_name)
file_num = (validate_file_range(end) - validate_file_range(1)) + 1;
first_file_number = validate_file_range(1);
last_file_number = validate_file_range(end);
EMG_data_by_each_file = cell(file_num,1);
root_dir_path = fileparts(pwd);
raw_data_dir_path = fullfile(root_dir_path, 'useDataFold', full_monkey_name);
first_raw_data_file_name = [monkey_prefix experiment_day '-' sprintf('%04d', first_file_number)];
load(fullfile(raw_data_dir_path, first_raw_data_file_name), 'CEMG_001_TimeBegin');
TimeRange = zeros(1,2);
TimeRange(1,1) = CEMG_001_TimeBegin;

for file_id = first_file_number:last_file_number
    ref_file_name = [monkey_prefix experiment_day '-' sprintf('%04d', file_id)];
    ref_file_data_struct = load(fullfile(raw_data_dir_path, ref_file_name), 'CEMG*');

    for EMG_id = 1:EMG_num
        ref_EMG_data = ref_file_data_struct.(['CEMG_' sprintf('%03d', EMG_id)]);
        if EMG_id == 1
            original_EMG_SR = ref_file_data_struct.CEMG_001_KHz * 1000;
            TimeRange(1,2) = ref_file_data_struct.CEMG_001_TimeEnd;
            ref_file_sample_num = length(ref_EMG_data);
            ref_file_EMG_list = zeros(ref_file_sample_num, EMG_num);
        end
        ref_file_EMG_list(:, EMG_id) = ref_EMG_data;
    end
    EMG_data_by_each_file{(file_id - validate_file_range(1, 1)) + 1, 1} = ref_file_EMG_list;
end
concatenated_EMG_data = cell2mat(EMG_data_by_each_file);
end
