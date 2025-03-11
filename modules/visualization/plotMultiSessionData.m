%{
[Function Description]
This function creates a stacked line plot showing EMG or synergy data from multiple sessions.
Each line represents data from a different experimental session, with color coding based on 
the chronological order of sessions. This visualization helps identify trends and changes 
in muscle activity or synergy patterns over time.

[Input Arguments]
plot_data_struct: [struct] Structure containing data and parameters for visualization
  - visualized_data: [struct] Contains the data to be plotted
    - cutout_range: X-axis values for plotting
    - time_normalized_activity_pattern: Cell array of time-normalized data for each session
  - session_num: Number of sessions to plot
  - date_double_list: List of session dates as numbers
  - selected_period_dates: List of dates in the selected period (pre/post treatment)
  - RGB_matrix: Color matrix for session visualization
  - line_width_value: Line width for plots
element_index: [double] Index of the element (EMG channel or synergy) to plot

[Output Arguments]
None (creates plot in current axes)

[Note]
The function uses a color gradient to represent the chronological progression of sessions,
making it easy to identify trends over time. If a session date is not found in the 
selected_period_dates list, the function will display an error message.
%}

function [] = plotMultiSessionData(plot_data_struct, element_index)
    % Extract necessary variables from the input structure
    visualized_data = plot_data_struct.visualized_data;
    session_num = plot_data_struct.session_num;
    date_double_list = plot_data_struct.date_double_list;
    selected_period_dates = plot_data_struct.selected_period_dates;
    RGB_matrix = plot_data_struct.RGB_matrix;
    line_width = plot_data_struct.line_width_value;
    
    % Plot data for each session with appropriate color coding
    for session_index = 1:session_num
        % Extract data for this element and session
        session_data = visualized_data.time_normalized_activity_pattern{session_index}(element_index, :);
        
        % Convert cell to matrix if necessary
        if iscell(session_data)
            session_data = cell2mat(session_data);
        end

        % Find the corresponding day index for color mapping
        session_date = date_double_list(session_index);
        day_index = find(session_date == selected_period_dates);
        
        % Error handling if day not found in selected_period_dates
        if isempty(day_index) 
            close all;
            error(['Session date ' num2str(session_date) ' is not included in "selected_period_dates". ' ...
                   'Please check your date selection criteria and try again.']);
        end
        
        % Plot the data with color based on day_index
        plot(visualized_data.cutout_range, session_data, 'Color', RGB_matrix(day_index, :), 'LineWidth', line_width);
    end
end
