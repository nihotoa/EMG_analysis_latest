%{
[Function Description]
This function extracts EMG data for individual muscles and saves them as separate files.
It processes data according to the specified extraction type (full recording or specific segments),
applies appropriate timing adjustments, and saves each muscle's data with relevant metadata.
The function supports different extraction modes for focusing on specific parts of trials.

[Input Arguments]
common_save_data_path: [char] Base directory path for saving the extracted data
unique_save_dir_name: [char] Unique directory name for this dataset
ref_cutout_EMG_data_struct: [struct] Structure containing EMG data and metadata
extract_EMG_type: [char] Type of extraction ('full', 'only_trial', 'only_drawer', 'only_food')
trim_start_end_timings: [double array] Indices [start_idx, end_idx] specifying which event columns to use
padding_time: [double] Time in seconds to add before and after each segment

[Output Arguments]
None - Files are saved to disk
%}

function [] = extractAndSaveEMGPerMuscle(common_save_data_path, unique_save_dir_name, ref_cutout_EMG_data_struct, extract_EMG_type, trim_start_end_timings, padding_time)
% Extract data from the ref_cutout_EMG_data_struct structure
EMG_name_list = ref_cutout_EMG_data_struct.EMG_name_list;
common_sample_rate = ref_cutout_EMG_data_struct.common_sample_rate;
concatenated_EMG_data = ref_cutout_EMG_data_struct.concatenated_EMG_data;
TimeRange = ref_cutout_EMG_data_struct.TimeRange_EMG;
Unit = ref_cutout_EMG_data_struct.Unit;
event_timing_data = ref_cutout_EMG_data_struct.transposed_success_timing;
EMG_num = length(EMG_name_list);

% save EMG data as .mat file for nmf
save_dir_path = fullfile(common_save_data_path, unique_save_dir_name);
makefold(save_dir_path)

% preparation of EMG to be saved
switch extract_EMG_type
    case 'full'
        extracted_EMG = transpose(concatenated_EMG_data);
    otherwise
        if not(strcmp(extract_EMG_type, 'only_trial'))
            padding_time = 0;
        end
        [extracted_EMG, event_timings_after_trimmed] = extractEMGSegments(concatenated_EMG_data, event_timing_data, trim_start_end_timings, common_sample_rate, padding_time);
end

% save each muscle EMG data to a file
Class = 'continuous channel'; % I(ohta) don't know how this parameter is used
if not(strcmp(extract_EMG_type, 'full'))
    sample_num = size(extracted_EMG, 2);
    TimeRange = [0, sample_num / common_sample_rate];
end

for EMG_id = 1:EMG_num
    muscle_name = cell2mat(EMG_name_list(EMG_id,1));
    EMG_data = extracted_EMG(EMG_id, :);
    save_file_name = [cell2mat(EMG_name_list(EMG_id,1)) '(' Unit ').mat'];
    
    % Create a structure with all variables to save
    data_to_save = struct('TimeRange', TimeRange, ...
                          'muscle_name', muscle_name, ...
                          'Class', Class, ...
                          'common_sample_rate', common_sample_rate, ...
                          'EMG_data', EMG_data, ...
                          'Unit', Unit);
    
    % Add event_timings_after_trimmed for 'only_trial' case
    if not(strcmp(extract_EMG_type, 'full'))
        data_to_save.event_timings_after_trimmed = event_timings_after_trimmed;
    end
    
    % Save the structure
    save(fullfile(save_dir_path, save_file_name), '-struct', 'data_to_save');
    disp([fullfile(save_dir_path, save_file_name) ' was generated successfully!!']);
end
end