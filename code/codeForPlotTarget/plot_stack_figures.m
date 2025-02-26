%{
[explanation of this func]:
Function to plot stack figure. 

[input arguments]
data_str:[struct], contains various parameters necessary for plot
element_id:[double], index of element

[output arguments]
%}

function [] = plot_stack_figures(data_str, element_id)
    % stores the field of a structure in a variable of the same name
    field_names = fieldnames(data_str);
    for idx = 1:length(field_names)
        var_name = field_names{idx};
        assignin('base', var_name, data_str.(var_name));
        eval([var_name ' = data_str.' var_name ';'])
    end

    % plot average activity for each session
    for session_id = 1:session_num
        
        % formatting of data to be plotted
        plot_data = plotted_data.time_normalized_EMG{session_id}(element_id, :);
        if iscell(plot_data)
            plot_data = cell2mat(plot_data);
        end

        % datect days_id
        ref_day = days_double(session_id);
        day_id = find(ref_day == TermDays);
        if isempty(day_id) 
            close all;
            error([num2str(ref_day) ' is not included in "TermDays" and cannot be used. Please change "pColor" and run again!'])
        end
        
        % plot
        plot(plotted_data.cutout_range, plot_data, 'Color', Csp(day_id,:), 'LineWidth', LineW);
    end
end
