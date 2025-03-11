%{
[Function Description]
This function calculates the mean and standard deviation of EMG or synergy data across all sessions.
It processes the time-normalized data for each element (EMG channel or synergy) and adds
the statistical information to the provided data structure.

[Input Arguments]
input_data: [struct] Structure containing time-normalized EMG or synergy data
session_num: [double] Number of selected sessions/files
element_num: [double] Number of elements (EMG channels or synergies)

[Output Arguments]
input_data: [struct] Updated structure with added mean and standard deviation fields
%}

function [input_data] = calculateAverageAndStd(input_data, session_num, element_num)
    % Initialize arrays to store statistical data
    time_normalized_input_data_list = cell(session_num, 1);
    input_data.std_list = cell(element_num, 1);
    input_data.average_activity_pattern_list = cell(element_num, 1);

    % Calculate mean and standard deviation for each element across all sessions
    for element_id = 1:element_num
        % Extract data for this element from all sessions
        for session_id = 1:session_num
            % Handle different data structures (cell array vs. matrix)
            try
                time_normalized_input_data_list{session_id} = cell2mat(input_data.time_normalized_activity_pattern{session_id, 1}(element_id, :));
            catch
                time_normalized_input_data_list{session_id} = input_data.time_normalized_activity_pattern{session_id, 1}(element_id, :);
            end
        end
        
        % Calculate standard deviation and mean
        input_data.std_list{element_id} = std(cell2mat(time_normalized_input_data_list), 1, 1);
        input_data.average_activity_pattern_list{element_id} = mean(cell2mat(time_normalized_input_data_list), 1);
    end
end

