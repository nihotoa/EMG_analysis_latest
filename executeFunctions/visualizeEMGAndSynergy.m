%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[your operation]
1. Navigate to the executeFunctions directory.
2. Change some parameters (please refer to 'set param' section)
3. Run this code

[role of this code]
This script visualizes EMG or muscle synergy data around specific timing events 
and for the whole task. It creates plots showing individual session data and/or 
mean with standard deviation, and saves the results as figures.

[saved data location]
Please refer to the log messages during execution for saved data locations.

[execution procedure]
- Pre: prepareEMGAndTimingData.m or prepareSynergyTemporalData.m
- Post: visualizeXcorr.m
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;

%% set param
% Basic configuration
monkey_prefix = 'Hu';          % Prefix of raw data (e.g., 'Se', 'Ya', 'F', 'Ni', 'Hu')
visualize_type = 'EMG';        % Data type to plot: 'EMG' or 'Synergy'

% Plot formatting
ylim_setting_type = 'individual'; % Y-axis limit setting: 'all' (common) or 'individual' (per channel)
ylim_max = 10;                    % Y-axis maximum value when ylim_setting_type = 'all'
ylim_max_list = [200, 80, 80, 20, 30, 80, 100, 30, 50, 20, 80, 50, 30, 60, 30, 20]; % Individual y-axis limits
line_width_value = 1.5;                      % Line width for plots
row_num = 4;                      % Number of rows in subplot figures

% Synergy-specific parameters (used only when visualize_type = 'Synergy')
use_EMG_type = 'only_trial';    % EMG data type: 'full' or 'only_trial'
synergy_num = 4;               % Number of synergies to analyze

%% Initialize paths and settings
% Get full monkey name and root directory
full_monkey_name = getFullMonkeyName(monkey_prefix);
root_dir_path = fileparts(pwd);

% Set base directory path based on plot type
switch visualize_type
    case 'EMG'
        base_dir_path = fullfile(root_dir_path, 'saveFold', full_monkey_name, 'data', 'EMG_ECoG');
    case 'Synergy'
        base_dir_path = fullfile(root_dir_path, 'saveFold', full_monkey_name, 'data', 'Synergy');
end

% Configure monkey-specific timing settings
switch full_monkey_name
    case 'Yachimun'
        timing_name_list = ["Lever1 on ", "Lever1 off ", "Lever2 on ", "Lever2 off"];
        TT_surgery_day = 170530;
        % Plot windows for each timing event (percentage of task duration)
        plot_window_cell{1} = [-25 5];
        plot_window_cell{2} = [-15 15];
        plot_window_cell{3} = [-15 15];
        plot_window_cell{4} = [-5 25];
    case 'SesekiL'
        timing_name_list = ["Lever on ", "Lever off ", "Photo on", "Photo off"];
        TT_surgery_day = 200121;
        plot_window_cell{1} = [-30 15];
        plot_window_cell{2} = [-10 15];
        plot_window_cell{3} = [-15 15];
        plot_window_cell{4} = [-2 15];
    case 'Nibali'
        timing_name_list = ["Task start ", "Grasp on ", "Grasp off ", "Task End"];
        TT_surgery_day = 220530;
        plot_window_cell{1} = [-25 5];
        plot_window_cell{2} = [-15 15];
        plot_window_cell{3} = [-15 15];
        plot_window_cell{4} = [-5 25];
    case 'Hugo'
        timing_name_list = ["Task start ", "Drawer on", "Drawer off", "Grasp on ", "Grasp off ", "Task End"];  
        TT_surgery_day = 250120;
        plot_window_cell{1} = [-25 15];
        plot_window_cell{2} = [-25 15];
        plot_window_cell{3} = [-15 15];
        plot_window_cell{4} = [-15 15];
        plot_window_cell{5} = [-15 15];
        plot_window_cell{6} = [-5 25];
end
timing_num = length(plot_window_cell);

% Set data directory path based on plot type
switch visualize_type
    case 'EMG'
        Pdata_dir_path = fullfile(base_dir_path, 'P-DATA');
    case 'Synergy'
        Pdata_dir_path = fullfile(base_dir_path, 'synergy_across_sessions', use_EMG_type, ...
            ['synergy_num==' num2str(synergy_num)], 'temporal_pattern_data');
end

%% Select and load data files
disp("Please select '_Pdata.mat' files for all the dates you want to plot")
selected_file_name_list = uigetfile(fullfile(Pdata_dir_path, '*.mat'), 'Select One or More Files', 'MultiSelect', 'on');

% Handle user selection
if ischar(selected_file_name_list)
    selected_file_name_list = {selected_file_name_list};
elseif isequal(selected_file_name_list, 0)
    disp('User pressed "cancel" button')
    return;
end

% Get session count and extract day information
[~, session_num] = size(selected_file_name_list);
unique_name_list = strrep(selected_file_name_list, '_Pdata.mat', '');
date_string_list = strrep(unique_name_list, monkey_prefix, '');

%% Calculate average data lengths across sessions
% Initialize structures to store length information
session_average_length = 0;
visualized_range_length_list = zeros(session_num, 1);
timing_session_average_length_struct = struct();
timing_length_list_struct = struct();

% Initialize timing-specific length structures
for timing_id = 1:timing_num
    ref_timing_unique_name = ['timing' num2str(timing_id)];
    timing_session_average_length_struct.(ref_timing_unique_name) = 0;
    timing_length_list_struct.(ref_timing_unique_name) = zeros(session_num, 1);
end

% Load and process length parameters from each session
for session_id = 1:session_num
    % Load parameters from Pdata file
    ref_day_Pdata_file_path = fullfile(Pdata_dir_path, selected_file_name_list{session_id});
    load(ref_day_Pdata_file_path, "average_visualized_range_sample_num", "average_trial_sample_num", "cutout_range_struct");
    
    % Update whole task average length (running average)
    session_average_length = (session_average_length * (session_id - 1) + average_visualized_range_sample_num) / session_id; 
    visualized_range_length_list(session_id) = average_visualized_range_sample_num;
    
    % Update timing-specific average lengths
    for timing_id = 1:timing_num
        ref_timing_unique_name = ['timing' num2str(timing_id)];
        ref_timing_length = cutout_range_struct.([ref_timing_unique_name '_average_sample_num']);
        
        % Calculate running average
        current_average_length = timing_session_average_length_struct.(ref_timing_unique_name);
        timing_session_average_length_struct.(ref_timing_unique_name) = (current_average_length * (session_id-1) + ref_timing_length) / session_id;
        timing_length_list_struct.(ref_timing_unique_name)(session_id) = ref_timing_length;
    end
end

%% Prepare data structures for time normalization
% Initialize structures for whole task data
visualized_range_activity_pattern_struct = struct();
visualized_range_activity_pattern_struct.session_average_length = round(session_average_length);
visualized_range_activity_pattern_struct.length_list = visualized_range_length_list;
visualized_range_activity_pattern_struct.time_normalized_activity_pattern = cell(session_num, 1);

% Initialize structures for each timing event
visualized_each_timing_activity_pattern_cell = cell(timing_num, 1);
for timing_id = 1:timing_num
    ref_timing_unique_name = ['timing' num2str(timing_id)];
    
    % Create structure for this timing event
    visualized_each_timing_activity_pattern_cell{timing_id} = struct();
    visualized_each_timing_activity_pattern_cell{timing_id}.session_average_length = round(timing_session_average_length_struct.(ref_timing_unique_name));
    visualized_each_timing_activity_pattern_cell{timing_id}.length_list = round(timing_length_list_struct.(ref_timing_unique_name));
    visualized_each_timing_activity_pattern_cell{timing_id}.time_normalized_activity_pattern = cell(session_num, 1);
    
    % Calculate cutout range and set plot range
    pre_post_percentages = cutout_range_struct.([ref_timing_unique_name '_pre_post_percentage']);
    visualized_each_timing_activity_pattern_cell{timing_id}.cutout_range = linspace(...
        -pre_post_percentages(1), ...
        pre_post_percentages(2), ...
        visualized_each_timing_activity_pattern_cell{timing_id}.session_average_length...
    );
    visualized_each_timing_activity_pattern_cell{timing_id}.plot_range = plot_window_cell{timing_id};
end

%% Perform time normalization for whole task data
% Process each session
for session_id = 1:session_num
    % Load EMG or synergy data
    activity_pattern_struct = load(fullfile(Pdata_dir_path, selected_file_name_list{session_id}));
    try
        time_normalized_activity_pattern_average = activity_pattern_struct.time_normalized_activity_pattern_average;
    catch
        time_normalized_activity_pattern_average = activity_pattern_struct.time_normalized_EMG_average;
    end

    % Get number of elements (EMG channels or synergies) from first session
    if session_id == 1
        element_num = length(time_normalized_activity_pattern_average);
    end
    
    % Resample data to common length and store
    time_normalized_data = resampleToUniformLength(time_normalized_activity_pattern_average, visualized_range_activity_pattern_struct.session_average_length); 
    visualized_range_activity_pattern_struct.time_normalized_activity_pattern{session_id, 1} = cell2mat(time_normalized_data);
end

% Calculate mean and standard deviation across sessions
[visualized_range_activity_pattern_struct] = calculateAverageAndStd(visualized_range_activity_pattern_struct, session_num, element_num);

%% Perform time normalization for each timing event
for timing_id = 1:timing_num
    % Get structure for this timing event
    ref_timing_EMG_struct = visualized_each_timing_activity_pattern_cell{timing_id};
    
    % Resample data for this timing event
    [ref_timing_EMG_struct] = resampleEachTimingEMG(...
        selected_file_name_list, ...
        ref_timing_EMG_struct, ...
        timing_id, ...
        Pdata_dir_path, ...
        element_num...
    );

    % Calculate mean and standard deviation
    [ref_timing_EMG_struct] = calculateAverageAndStd(ref_timing_EMG_struct, session_num, element_num);
    visualized_each_timing_activity_pattern_cell{timing_id} = ref_timing_EMG_struct;
end

%% Configure color mapping for plots
% Convert day strings to numbers for color mapping
date_double_list = str2double(date_string_list');
selected_first_Pdata_name = selected_file_name_list{1};
selected_last_Pdata_name = selected_file_name_list{end};
[selected_period_dates, period_type] = categorizeExperimentDates(TT_surgery_day, Pdata_dir_path, selected_first_Pdata_name, selected_last_Pdata_name);

% Set color scheme based on term type (pre/post/both) and monkey
switch period_type
    case 'pre'
        color_id = 2;  % Use green color gradient for pre-sugery
        
        selected_period_day_num = length(selected_period_dates);
        % Create color gradient
        RGB_matrix = zeros(selected_period_day_num, 3);
        RGB_matrix(:, color_id) = ones(selected_period_day_num, 1) .* linspace(0.3, 1, selected_period_day_num)';
        
    case 'post'
        color_id = 1;
        
        selected_period_day_num = length(selected_period_dates);
        % Create color gradient
        RGB_matrix = zeros(selected_period_day_num, 3);
        RGB_matrix(:, color_id) = ones(selected_period_day_num, 1) .* linspace(0.3, 1, selected_period_day_num)';
        
    case 'both'
        % For mixed pre/post data, use different colors for pre and post
        selected_period_day_num = length(selected_period_dates);
        RGB_matrix = zeros(selected_period_day_num, 3);
        
        % First calculate days from surgery for all dates
        days_from_surgery_list = zeros(selected_period_day_num, 1);
        for day_idx = 1:selected_period_day_num
            current_date = selected_period_dates(day_idx);
            days_from_surgery_list(day_idx) = CountElapsedDate(num2str(current_date), TT_surgery_day);
        end
        
        % Find maximum absolute values for pre and post periods
        pre_indices = days_from_surgery_list < 0;
        post_indices = days_from_surgery_list >= 0;
        
        % Handle case where there might be no pre or post dates
        max_pre_abs = 1;
        if any(pre_indices)
            max_pre_abs = max(abs(days_from_surgery_list(pre_indices)));
        end
        
        max_post = 1;
        if any(post_indices)
            max_post = max(days_from_surgery_list(post_indices));
        end
        
        % Assign colors based on pre/post status
        for day_idx = 1:selected_period_day_num
            days_from_surgery = days_from_surgery_list(day_idx);
            
            if days_from_surgery < 0
                % Pre-sugery dates: use green (column 2)
                RGB_matrix(day_idx, 2) = 0.3 + 0.7 * (abs(days_from_surgery) / max_pre_abs);
            else
                % Post-sugery dates: use red (column 1)
                RGB_matrix(day_idx, 1) = 0.3 + 0.7 * (days_from_surgery / max_post);
            end
        end
end

%% Set up output directory
% Create unique name for output folder
save_figure_dir_name = [unique_name_list{1} 'to' date_string_list{end} '_' num2str(length(unique_name_list))];

% Set output directory based on plot type
switch visualize_type
    case 'EMG'
        save_figure_fold_path = fullfile(root_dir_path, 'saveFold', full_monkey_name, 'figure', 'EMG', 'each_timing_EMG', save_figure_dir_name);
    case 'Synergy'
        tentetive = strrep(base_dir_path, 'data', 'figure');
        save_figure_fold_path = fullfile(tentetive, 'synergy_across_sessions', use_EMG_type, ...
            ['synergy_num==' num2str(synergy_num)], save_figure_dir_name, 'H_figures');
end
makefold(save_figure_fold_path);
disp(['Created output directory: ' save_figure_fold_path]);

%% Configure plot settings
% Calculate maximum amplitude for y-axis limits if needed
if and(strcmp(ylim_setting_type, 'all'), ylim_max == inf)
    max_amplitude_list = getMaxAmplitudeList(visualized_range_activity_pattern_struct.time_normalized_activity_pattern);
    max_amplitude_list = transpose(max_amplitude_list);
    ylim_max_list = ceil(max_amplitude_list / 10) * 10;
end

% Load additional visualization parameters
switch visualize_type
    case 'EMG' 
        load(fullfile(Pdata_dir_path, selected_file_name_list{1}), 'visualized_range', 'EMG_name_list');
    case 'Synergy'
        load(fullfile(Pdata_dir_path, selected_file_name_list{1}), 'visualized_range');
        % Create synergy names if EMG_name_list doesn't exist
        if ~exist('EMG_name_list', 'var')
            EMG_name_list = cell(element_num, 1);
            for i = 1:element_num
                EMG_name_list{i} = ['Synergy ' num2str(i)];
            end
        end
end

% Set cutout range for whole task visualization
visualized_range_activity_pattern_struct.cutout_range = linspace(...
    visualized_range(1), ...
    visualized_range(2), ...
    visualized_range_activity_pattern_struct.session_average_length...
);

%% Prepare data structure for plotting
% List of variables to include in data structure
base_variable_list = {'element_num', 'session_num', 'line_width_value', 'ylim_setting_type', 'ylim_max', 'ylim_max_list', 'visualize_type', 'selected_period_dates', 'date_double_list', 'RGB_matrix', 'row_num', 'timing_num'};

% Add EMG_name_list only if it exists
plot_data_struct = struct();
use_variable_list = base_variable_list;
if exist('EMG_name_list', 'var')
    use_variable_list = [use_variable_list, {'EMG_name_list'}];
end

% Copy variables to data structure
not_exist_variables = {};
for variable_id = 1:length(use_variable_list)
    variable_name = use_variable_list{variable_id};
    try
        plot_data_struct.(variable_name) = eval(variable_name);
    catch
        not_exist_variables{end+1} = variable_name;
    end
end

% Report any missing variables
if ~isempty(not_exist_variables)
    disp(['Warning: The following variables were not found: (' char(join(not_exist_variables, ', ')) ')']);
end

%% Plot whole task data
% Set up figure name and data
save_figure_name = ['All_' visualize_type '(whole task)'];
plot_data_struct.visualized_data = visualized_range_activity_pattern_struct;
plot_data_struct.plot_window = [-25 105];
figure_type_cell = {'stack', 'std'}; % Plot types: 'stack' (individual sessions) and 'std' (mean ± std)

% Create and save figures for each plot type
for fig_type_idx = 1:length(figure_type_cell)
    ref_figure_type = figure_type_cell{fig_type_idx};

    if strcmp(ref_figure_type, 'std') && strcmp(period_type, 'both')
        continue;
    end

    % Create figure
    whole_trial_figure_struct.fig1 = figure('position', [100, 100, 1000, 1000]);
    
    % Generate plot
    whole_trial_figure_struct = configureDataVisualization(whole_trial_figure_struct, plot_data_struct, 'whole_trial', ref_figure_type);
    
    % Add title
    sgtitle([ref_figure_type ' ' visualize_type ' in task (from ' num2str(date_string_list{1}) ' to ' num2str(date_string_list{end}) ...
        ' - ' num2str(length(date_string_list)) ')'], 'FontSize', 25);
    
    % Save figure
    fig_path = fullfile(save_figure_fold_path, [save_figure_name '_' ref_figure_type '.fig']);
    png_path = fullfile(save_figure_fold_path, [save_figure_name '_' ref_figure_type '.png']);
    saveas(gcf, fig_path);
    saveas(gcf, png_path);
    disp(['Saved whole task figure: ' fig_path]);
    close all;
end

%% Plot data for each timing event
% Calculate number of figures needed
figure_num = ceil(element_num / row_num);

% Create figure structures
figure_struct = struct();
for fig_type_idx = 1:length(figure_type_cell)
    ref_figure_type = figure_type_cell{fig_type_idx};

    if strcmp(ref_figure_type, 'std') && strcmp(period_type, 'both')
        continue;
    end

    figure_struct.(ref_figure_type) = struct();
    
    % Create figures
    for figure_id = 1:figure_num
        figure_struct.(ref_figure_type).(['fig' num2str(figure_id)]) = figure("position", [100, 100, 250 * timing_num, 1000]);
    end
end

% Process each timing event
for timing_id = 1:timing_num
    % Get timing name and data
    timing_name = timing_name_list(timing_id);
    ref_timing_visualized_data = visualized_each_timing_activity_pattern_cell{timing_id};
    
    % Set cutout range
    ref_timing_unique_name = ['timing' num2str(timing_id)];
    pre_post_percentages = cutout_range_struct.([ref_timing_unique_name '_pre_post_percentage']);
    ref_timing_visualized_data.cutout_range = linspace(...
        -pre_post_percentages(1), ...
        pre_post_percentages(2), ...
        ref_timing_visualized_data.session_average_length...
    );
    
    % Set plot window
    plot_window = plot_window_cell{timing_id};

    % Update data structure for this timing
    plot_data_struct.timing_id = timing_id;
    plot_data_struct.timing_name = timing_name;
    plot_data_struct.plot_window = plot_window;
    plot_data_struct.visualized_data = ref_timing_visualized_data;

    % Generate plots for each figure type
    for fig_type_idx = 1:length(figure_type_cell)
        ref_figure_type = figure_type_cell{fig_type_idx};

        if strcmp(ref_figure_type, 'std') && strcmp(period_type, 'both')
            continue;
        end

        figure_struct.(ref_figure_type) = configureDataVisualization(figure_struct.(ref_figure_type), plot_data_struct, 'each_timing', ref_figure_type);
    end
end

% Save all figures
for figure_id = 1:figure_num
    save_figure_name = ['each_timing_figure' num2str(figure_id)];
    
    for fig_type_idx = 1:length(figure_type_cell)
        ref_figure_type = figure_type_cell{fig_type_idx};

        if strcmp(ref_figure_type, 'std') && strcmp(period_type, 'both')
            continue;
        end
        
        figure(figure_struct.(ref_figure_type).(['fig' num2str(figure_id)]));
        
        fig_path = fullfile(save_figure_fold_path, [save_figure_name '_' ref_figure_type '.fig']);
        png_path = fullfile(save_figure_fold_path, [save_figure_name '_' ref_figure_type '.png']);
        saveas(gcf, fig_path);
        saveas(gcf, png_path);
        disp(['Saved timing event figure: ' fig_path]);
    end
end
close all;

%% Save processed data for further analysis
% Set output directory for processed data
switch visualize_type
    case 'EMG'
        save_data_dir_path = fullfile(base_dir_path, 'EMG_across_sessions', 'EMG_for_each_timing');
    case 'Synergy'
        save_data_dir_path = fullfile(fileparts(Pdata_dir_path), 'temporal_pattern_for_each_timing');
end
makefold(save_data_dir_path);
disp(['Created data output directory: ' save_data_dir_path]);

% Save data for each session
for session_id = 1:session_num
    % Initialize structures
    each_timing_EMG_cell = cell(timing_num, 1);
    
    % Extract data for each timing event
    for timing_id = 1:timing_num
        ref_timing_saved_struct = struct();
        ref_timing_used_struct = visualized_each_timing_activity_pattern_cell{timing_id};
        
        ref_timing_saved_struct.time_normalized_activity_pattern = ref_timing_used_struct.time_normalized_activity_pattern{session_id};
        ref_timing_saved_struct.session_average_length = ref_timing_used_struct.session_average_length;
        ref_timing_saved_struct.cutout_range = ref_timing_used_struct.cutout_range;
        ref_timing_saved_struct.plot_range = ref_timing_used_struct.plot_range;

        each_timing_EMG_cell{timing_id} = ref_timing_saved_struct;
    end
    
    % Save data to file
    save_file_name = [monkey_prefix date_string_list{session_id} '_each_timing_pattern.mat'];
    save_path = fullfile(save_data_dir_path, save_file_name);
    save(save_path, 'visualized_range_activity_pattern_struct', 'each_timing_EMG_cell', 'timing_name_list');
    disp(['Saved processed data for session ' num2str(session_id) ': ' save_path]);
end

% Display completion message
disp(['Visualization complete. Results saved to: ' save_figure_fold_path]);