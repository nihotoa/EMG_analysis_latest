%{
[explanation of this func]
This function reads EMG data from .ns5 files recorded by Ripple device and formats them into a MATLAB structure.
It processes differential EMG signals from electrode pairs and resamples them to a specified frequency.
The function handles multiple .ns5 files and concatenates the EMG data from all valid files.

[input arguments]
base_dir_path: [char], path to the base directory containing experiment day folders
ref_experiment_day: [char], name of the experiment day folder containing .ns5 files
common_frequency: [double], target sampling rate for resampling EMG data

[output arguments]
CEMG_data_struct: [struct], contains formatted EMG data with fields:
    - CEMG_XXX: [double array], EMG signal data for each muscle
    - CEMG_XXX_KHz: [double], sampling rate in kHz
    - CEMG_XXX_KHz_Orig: [double], original sampling rate in kHz
amplitude_unit: [char], unit of EMG amplitude (e.g., 'uV')
record_time: [double], total recording time in seconds
%}

function [CEMG_data_struct, amplitude_unit, record_time] = formatRippleEMGData(base_dir_path, ref_experiment_day, common_frequency)
ref_experiment_day_dir_path = fullfile(base_dir_path, ref_experiment_day);
EMG_files = dirPlus(fullfile(ref_experiment_day_dir_path, 'datafile*.ns5'));

EMG_files_num = length(EMG_files);
EMG_data_cell = cell(1, EMG_files_num);
record_time_list = nan(1, EMG_files_num);
CEMG_data_struct = struct;

disp(['Processing EMG data from ' ref_experiment_day '...']);

if isempty(EMG_files)
    disp(['No EMG files found in ' ref_experiment_day]);
    return;
end

for file_id = 1:length(EMG_files)
    ref_EMG_file_path = fullfile(ref_experiment_day_dir_path, EMG_files(file_id).name);
    [~, hFile] = ns_OpenFile(ref_EMG_file_path); 
    try
        [start_electrode_id, end_electrode_id] = getEMGElectrodeNum(hFile);
    catch
        % This file does not contain EMG electrode signals, so continue
        continue;
    end

    EMG_id = 1;
    for idx = start_electrode_id:2:end_electrode_id-1
        try
            % get EMG signal from both electrode
            [~, ~, EMG_signal1] = ns_GetAnalogData(hFile, idx, 1, 1e10);
            [~, ~, EMG_signal2] = ns_GetAnalogData(hFile, idx+1, 1, 1e10);
        catch
            % For some reason, the signal obtained from the binary file is empty, so the data from this file is discarded
            break;
        end
        
        % take the difference
        EMG_signal = transpose(EMG_signal1 - EMG_signal2);
    
        % compile the information of record(samplingRate, rosolution, etc...)
        if idx == start_electrode_id
            [~, record_info] = ns_GetAnalogInfo(hFile, idx);
            EMG_original_SR = record_info.SampleRate;
            amplitude_unit = record_info.Units;
            muscle_num = ((end_electrode_id - start_electrode_id) + 1) / 2;
            EMG_data_cell{file_id} = cell(muscle_num, 1);
            record_time_list(file_id) = length(EMG_signal) / EMG_original_SR;
        end
    
        % store the signal & informations
        ref_signal = EMG_signal * hFile.Entity(idx).Scale;
        formatted_number = sprintf('%03d', EMG_id);
        CEMG_data_struct.(['CEMG_' formatted_number '_KHz']) = common_frequency / 1000;
        CEMG_data_struct.(['CEMG_' formatted_number '_KHz_Orig']) = common_frequency / 1000;
        EMG_data_cell{file_id}{EMG_id} = resample(ref_signal, common_frequency, EMG_original_SR);
        EMG_id = EMG_id + 1;
    end
end
validate_file_indeices = find(~cellfun('isempty', EMG_data_cell));
validate_EMG_element_cell = EMG_data_cell(validate_file_indeices);
validate_EMG_files_name = arrayfun(@(x) x.name, EMG_files(validate_file_indeices), 'UniformOutput', false);
validate_record_time_element = record_time_list(validate_file_indeices);
record_time = sum(validate_record_time_element);

% concatenate EMG data
for EMG_id = 1:muscle_num
    ref_muscle_concatenaded_data = cell(1, length(validate_EMG_element_cell));
    for concat_id = 1:length(validate_EMG_element_cell)
        ref_muscle_concatenaded_data{concat_id} = validate_EMG_element_cell{concat_id}{EMG_id};
    end
    CEMG_data_struct.(['CEMG_' sprintf('%03d', EMG_id)]) = cell2mat(ref_muscle_concatenaded_data);
end

disp(['[' ref_experiment_day ' validated files]: ' strjoin(validate_EMG_files_name, ' and ')]);
disp(['Total recording time: ' num2str(record_time) ' seconds']);
end