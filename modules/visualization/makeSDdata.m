%{
[explanation of this func]:
Function to add mean and std information for all sessions(date) to 'plotted_data_struct'

[input arguments]
plotted_data_struct: [struct], contains various information around the timing to be focused on
session_num: [double], number of selected files
element_num: [double], number of elements (EMG or synergy)

[output arguments]
plotted_data_struct: [struct], contains various information around the timing to be focused on

%}

function [plotted_data_struct] = makeSDdata(plotted_data_struct, session_num, element_num)

% create empty array to store data
time_normalized_EMG_list = cell(session_num,1);
plotted_data_struct.standard_diviation_list = cell(element_num,1);
plotted_data_struct.mean_EMG_list = cell(element_num,1);

% For each EMG(or synergy), find the mean and standard deviation for all sessions
for element_id = 1:element_num
    for session_id = 1:session_num
        % The structure of 'time_normalized_EMG' differs between 'Pall' and others, so deal with this.
        try
            time_normalized_EMG_list{session_id} = cell2mat(plotted_data_struct.time_normalized_EMG{session_id,1}(element_id,:));
        catch
            time_normalized_EMG_list{session_id} = plotted_data_struct.time_normalized_EMG{session_id,1}(element_id,:);
        end
    end
    plotted_data_struct.standard_diviation_list{element_id} = std(cell2mat(time_normalized_EMG_list), 1, 1);
    plotted_data_struct.mean_EMG_list{element_id} = mean(cell2mat(time_normalized_EMG_list), 1);
end
end

