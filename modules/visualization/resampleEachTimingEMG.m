%{
[Function Description]
This function resamples activity_pattern data for each timing event to a common length across all sessions.
It eliminates differences in trial data length between sessions by resampling each dataset
to the average length, ensuring consistent data for visualization and analysis.

[Input Arguments]
selected_file_name_list: [cell array] List of selected file names
ref_timing_activity_pattern_struct: [struct] Contains information about the timing event to be processed
ref_timing: [double] Timing number to be focused on
select_folder_path: [char] Path to the folder containing Pdata files
element_num: [double] Number of elements (EMG channels or synergies)

[Output Arguments]
ref_timing_activity_pattern_struct: [struct] Updated structure with resampled activity_pattern data

[Note]
This function requires the Signal Processing Toolbox for the resample function.
%}

function [ref_timing_activity_pattern_struct] = resampleEachTimingEMG(selected_file_name_list, ref_timing_activity_pattern_struct, ref_timing, select_folder_path, element_num)  
    session_num = length(selected_file_name_list);
    
    % Process each session
    for session_id = 1:session_num 
        % Load Pdata for this session
        tentetive = load(fullfile(select_folder_path, selected_file_name_list{session_id}));
        try
            each_timing_cutout_mean_activity_pattern_struct = tentetive.each_timing_cutout_mean_activity_pattern_struct;
        catch
            each_timing_cutout_mean_activity_pattern_struct = tentetive.each_timing_cutout_mean_EMG_struct;
        end

        % Get activity_pattern data for the specified timing event
        ref_session_activity_pattern_data = each_timing_cutout_mean_activity_pattern_struct.(['timing' num2str(ref_timing)]);
        ref_session_data_length = ref_timing_activity_pattern_struct.length_list(session_id, 1);
        common_data_length = ref_timing_activity_pattern_struct.session_average_length;
        
        % Initialize matrix for time-normalized EMG data
        time_normalized_activity_pattern = zeros(element_num, common_data_length);

        % Resample data to the common length
        if ref_session_data_length == common_data_length
            % If lengths match, use data as is
            for element_id = 1:element_num
                time_normalized_activity_pattern(element_id, :) = ref_session_activity_pattern_data{1, element_id};
            end
        elseif ref_session_data_length < common_data_length 
            % If data is shorter, use interpolation to expand
            for element_id = 1:element_num
                ref_element_data = ref_session_activity_pattern_data{1, element_id};
                time_normalized_activity_pattern(element_id, :) = interpft(ref_element_data, common_data_length);
            end
        else
            % If data is longer, use resampling to reduce
            for element_id = 1:element_num
                ref_element_data = ref_session_activity_pattern_data{1, element_id};
                time_normalized_activity_pattern(element_id, :) = resample(ref_element_data, common_data_length, ref_session_data_length);
            end
        end

        % Store the resampled data
        ref_timing_activity_pattern_struct.time_normalized_activity_pattern{session_id, 1} = time_normalized_activity_pattern;
    end
end