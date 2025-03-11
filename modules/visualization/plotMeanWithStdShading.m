%{
[Function Description]
This function creates a plot showing the mean activity pattern with standard deviation shading.
It visualizes the average EMG or synergy data as a black line and displays the variability
as a shaded area around the mean, providing a clear representation of data consistency across sessions.

[Input Arguments]
plot_data_struct: [struct] Structure containing data and parameters for visualization
  - visualized_data: [struct] Contains the data to be plotted
    - cutout_range: X-axis values for plotting
    - average_activity_pattern_list: List of mean values for each element
    - std_list: List of standard deviation values for each element
  - line_width_value: Line width for the mean line
element_index: [double] Index of the element (EMG channel or synergy) to plot

[Output Arguments]
None (creates plot in current axes)

[Note]
The function uses a light blue shaded area to represent the standard deviation
and a black line to represent the mean, making it easy to distinguish between
the average trend and the variability in the data.
%}

function [] = plotMeanWithStdShading(plot_data_struct, element_index)
    % Extract necessary variables from the input structure
    visualized_data = plot_data_struct.visualized_data;
    line_width = plot_data_struct.line_width_value;

    % Get standard deviation and mean data for this element
    std_values = visualized_data.std_list{element_index};
    mean_values = visualized_data.average_activity_pattern_list{element_index};
    x_values = visualized_data.cutout_range;
    
    % Create x and y coordinates for the shaded area (mean ± std)
    % First go forward with upper bound, then backward with lower bound
    x_coordinates = [x_values x_values(end:-1:1)];
    y_coordinates = [mean_values + std_values mean_values(end:-1:1) - std_values(end:-1:1)];
    
    % Plot the shaded area for standard deviation
    shaded_area = fill(x_coordinates, y_coordinates, 'k');
    shaded_area.FaceColor = [0.8 0.8 1]; % Light blue shading
    shaded_area.EdgeColor = 'none';      % Remove border

    % Plot the mean line on top of the shaded area
    plot(x_values, mean_values, 'k', 'LineWidth', line_width);
end
