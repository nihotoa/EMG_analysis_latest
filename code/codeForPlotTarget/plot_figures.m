%{
[explanation of this func]:

[input arguments]
figure_str: [struct], contains some figure object
data_str:[struct], contains various parameters necessary for plot
trim_type:[char ('each_timing' / 'whole_task')], char to distinguish data to be extracted
fig_type: [char ('stack' / 'std')],  char to distinguish the type of diagram to be plotted

[output arguments]
figure_str: [struct], contains some figure object

%}

function [figure_str] = plot_figures(figure_str, data_str, trim_type, fig_type)
    % stores the field of a structure in a variable of the same name
    field_names = fieldnames(data_str);
    for idx = 1:length(field_names)
        var_name = field_names{idx};
        assignin('base', var_name, data_str.(var_name));
        eval([var_name ' = data_str.' var_name ';'])
    end
    
    for m = 1:element_num
        % determine the title of this subplot
        title_str = '';
        if and(exist('timing_name', 'var'), mod(m, row_num) == 1)
            title_str = timing_name;
        end

        switch plot_type
            case 'EMG'
                title_str = [title_str EMGs{m}];
                ylabel_str = 'Amplitude[uV]';
            case 'Synergy'
                ylabel_str = 'Coefficient';
        end

        % identify subplot location & subplot
        switch trim_type
            case 'whole_task'
                figure(figure_str.fig1)
                col_num = ceil(element_num / row_num);
                subplot(row_num, col_num, m)
            case  'each_timing'
                figure_idx = ceil(m / row_num); % figure number to plot
                figure(figure_str.(['fig' num2str(figure_idx)]))
                row_idx = m - row_num * (figure_idx-1) ;
                subplot_idx = timing_num * (row_idx - 1) + timing_id; % if
                subplot(row_num, timing_num, subplot_idx);
        end
        hold on
        
        % plot according to 'fig_type'
        switch fig_type
            case 'stack'
                 plot_stack_figures(data_str, m)
            case 'std'
                plot_std_figures(data_str, m)
        end

        % decoration
        xline(0,'color','r','LineWidth',LineW)
        xline(100,'color','r','LineWidth',LineW)
        xlim(plotWindow);
        xlabel('task range[%]')
        hold off

        if normalizeAmp == 1
            ylim([0 1]);
        else
            %{
            if and(exist("y_max_value_list"), ylim_max==inf)
                ref_y_max_value = y_max_value_list(m);
                upper_lim = ceil(ref_y_max_value / 10) * 10;
                ylim([0 upper_lim]);
            else
                ylim([0 ylim_max]);
            end
            %}
            if and(strcmp(ylim_setting_type, 'all'), not(ylim_max == inf))
                upper_value = ylim_max;
            else
                upper_value = ylim_max_list(m);
            end
            ylim([0 upper_value]);
            ylabel(ylabel_str)
        end
        title(title_str)

        % title 
        set(gca, "FontSize", 15);
    end
end