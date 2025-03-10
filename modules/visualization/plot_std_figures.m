%{
[explanation of this func]:
Function to plot mean +- std figure. 

[input arguments]
data_str:[struct], contains various parameters necessary for plot
element_id:[double], index of element

[output arguments]

%}

function [] = plot_std_figures(data_str, element_id)
    % stores the field of a structure in a variable of the same name
    field_names = fieldnames(data_str);
    for idx = 1:length(field_names)
        var_name = field_names{idx};
        assignin('base', var_name, data_str.(var_name));
        eval([var_name ' = data_str.' var_name ';'])
    end

    % plot background by refering to std
    sd = plotted_data.standard_diviation_list{element_id};
    y = plotted_data.mean_EMG_list{element_id};
    xconf = [plotted_data.cutout_range plotted_data.cutout_range(end:-1:1)];
    yconf = [y+sd y(end:-1:1)-sd(end:-1:1)];
    fi = fill(xconf,yconf,'k');
    fi.FaceColor = [0.8 0.8 1]; % make the filled area pink
    fi.EdgeColor = 'none'; % remove the line around the filled area

    % plot averarge data
    plot(plotted_data.cutout_range,y,'k','LineWidth',LineW);
end
