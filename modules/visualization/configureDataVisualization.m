%{
[Function Description]
This function creates and configures visualization plots for EMG or synergy data.
It handles different plot types (stack or std) and can focus on either whole trials
or specific timing events. The function manages subplot creation, formatting, and applies
consistent styling across all plots.

[Input Arguments]
figure_struct: [struct] Structure containing figure handles for plotting
plot_data_struct: [struct] Structure containing data and parameters for visualization
  - visualized_data: Data to be plotted
  - element_num: Number of elements (EMG channels or synergies)
  - row_num: Number of rows in subplot grid
  - timing_id: Current timing event ID (for each_timing mode)
  - timing_name: Name of current timing event (for each_timing mode)
  - visualize_type: Type of data ('EMG' or 'Synergy')
  - EMG_name_list: Names of EMG channels or synergies
  - plot_window: X-axis limits for plotting
  - line_width_value: Line width for plots
  - ylim_setting_type: Y-axis limit setting ('all' or 'individual')
  - ylim_max: Maximum y-value when using 'all' setting
  - ylim_max_list: List of maximum y-values for individual elements
plot_mode: [char] Type of data to plot ('each_timing' or 'whole_trial')
plot_style: [char] Type of figure to create ('stack' or 'std')

[Output Arguments]
figure_struct: [struct] Updated structure with modified figure handles

[Note]
This function relies on plotMultiSessionData and plotMeanWithStdShading functions
to generate the actual plots based on the specified style.
%}

function [figure_struct] = configureDataVisualization(figure_struct, plot_data_struct, plot_mode, plot_style)
    % Extract all fields from plot_data_struct into the current workspace
    field_names = fieldnames(plot_data_struct);
    for field_index = 1:length(field_names)
        var_name = field_names{field_index};
        assignin('base', var_name, plot_data_struct.(var_name));
        eval([var_name ' = plot_data_struct.' var_name ';']);
    end
    
    % Process each element (EMG channel or synergy)
    for element_index = 1:element_num
        % Determine the title for this subplot
        subplot_title = '';
        if and(exist('timing_name', 'var'), mod(element_index, row_num) == 1)
            subplot_title = timing_name;
        end

        % Set title and y-axis label based on data type
        switch visualize_type
            case 'EMG'
                subplot_title = [subplot_title EMG_name_list{element_index}];
                y_axis_label = 'Amplitude [μV]';
            case 'Synergy'
                y_axis_label = 'Coefficient';
        end

        % Create subplot in appropriate location based on plot mode
        switch plot_mode
            case 'whole_trial'
                % For whole trial plots, create a single figure with all elements
                figure(figure_struct.fig1);
                column_num = ceil(element_num / row_num);
                subplot(row_num, column_num, element_index);
            case 'each_timing'
                % For timing-specific plots, create multiple figures with timing-based layout
                figure_index = ceil(element_index / row_num); % Figure number to plot
                figure(figure_struct.(['fig' num2str(figure_index)]));
                row_position = element_index - row_num * (figure_index-1);
                subplot_position = timing_num * (row_position - 1) + timing_id;
                subplot(row_num, timing_num, subplot_position);
        end
        hold on;
        
        % Generate plot based on specified style
        switch plot_style
            case 'stack'
                plotMultiSessionData(plot_data_struct, element_index);
            case 'std'
                plotMeanWithStdShading(plot_data_struct, element_index);
        end

        % Add common plot elements and formatting
        xline(0, 'color', 'r', 'LineWidth', line_width_value);
        xline(100, 'color', 'r', 'LineWidth', line_width_value);
        xlim(plot_window);
        xlabel('Task Range [%]');
        hold off;
        
        % Set y-axis limits based on settings
        if and(strcmp(ylim_setting_type, 'all'), not(ylim_max == inf))
            upper_limit = ylim_max;
        else
            upper_limit = ylim_max_list(element_index);
        end
        ylim([0 upper_limit]);
        ylabel(y_axis_label);
        title(subplot_title);

        % Set font size for readability
        set(gca, "FontSize", 15);
    end
end