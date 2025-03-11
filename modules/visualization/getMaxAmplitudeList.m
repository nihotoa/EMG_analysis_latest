%{
[Function Description]
This function calculates the maximum amplitude for each EMG channel across all sessions.
It processes data from multiple sessions and returns a list of maximum values for each channel.

[Input Arguments]
plotData: [cell array] Cell array containing EMG data for each session

[Output Arguments]
max_amplitude_list: [double array] Maximum amplitude values for each EMG channel
%}

function max_amplitude_list = getMaxAmplitudeList(plotData)
    % Get dimensions
    session_num = length(plotData);
    EMG_num = length(plotData{1});
    
    % Initialize output array
    max_amplitude_list = zeros(EMG_num, 1);
    
    % Calculate maximum amplitude for each EMG channel
    for EMG_id = 1:EMG_num
        % Collect data for this EMG channel from all sessions
        ref_data = cell(1, session_num);
        for session_id = 1:session_num
            ref_data{session_id} = plotData{session_id}{EMG_id};
        end
        
        % Combine data and find maximum
        ref_data = cell2mat(ref_data);
        max_amplitude_list(EMG_id) = max(ref_data);
    end
end