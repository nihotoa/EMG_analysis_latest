%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[your operation]
1. Navigate to the executeFunctions directory.
2. Change some parameters (please refer to 'set param' section)
3. Run this code and select synergy detail files when prompted

[role of this code]
This script visualizes the Variance Accounted For (VAF) values of muscle synergies 
obtained through Non-negative Matrix Factorization (NMF). It creates and saves plots 
showing how well different numbers of synergies reconstruct the original EMG data, 
which helps determine the optimal number of synergies.

[saved figure location]
The location of the saved figure file is shown in the log when this function is executed.

[execution procedure]
- Pre: synergyExtractionByNMF.m
- Post: compileSynergyData.m

%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;

%% Set parameters
% Analysis type parameters
use_EMG_type = 'only_trial';    % EMG data type ('full' or 'only_trial')
monkey_prefix = 'Hu';           % Prefix of recorded data

% Visualization parameters
figure_type = 'VAF';            % Type of plot ('VAF' or 'dVAF')
VAF_plot_type = 'stack';        % Plot style ('stack' or 'mean')
VAF_threshold = 0.8;            % Threshold line value for VAF plots
font_size = 20;                 % Font size for figure text
use_EMG_num = 16;               % Number of EMG used for NMF

%% Select and load data files
% Set up paths
switch monkey_prefix
    case 'Hu'
        TT_surgery_day = 20250120; % Reference day for calculating elapsed days
    case {'F', 'Ya'}
        TT_surgery_day = 20170530; % Reference day for calculating elapsed days
    case {'Se'}
        TT_surgery_day = 20200120; % Reference day for calculating elapsed days
    case 'Ni'
        TT_surgery_day = 20220530; % Reference day for calculating elapsed days
end

full_monkey_name = getFullMonkeyName(monkey_prefix);
root_dir_path = fileparts(pwd);
base_dir_path = fullfile(root_dir_path, 'saveFold', full_monkey_name, 'data', 'Synergy');
synergy_detail_dir = fullfile(base_dir_path, 'synergy_detail', use_EMG_type, ['use_EMG_num == ' num2str(use_EMG_num)]);

% Select synergy detail files
disp('Please select all files you want to visualize')
selected_file_name_list = uigetfile(synergy_detail_dir, MultiSelect="on");

if not(iscell(selected_file_name_list))
    disp('User pressed "cancel" button.');
    return;
end

% Extract only the date part (numbers) from file names
day_name_list = cell(size(selected_file_name_list));
for i = 1:length(selected_file_name_list)
    % Extract numbers using regular expression
    date_part = regexp(selected_file_name_list{i}, '\d+', 'match');
    if ~isempty(date_part)
        day_name_list{i} = date_part{1}; % Take the first number match (date part)
    else
        day_name_list{i} = ''; % Fallback if no numbers found
    end
end
day_num = length(selected_file_name_list);

% Determine whether to use color bar (used when showing multiple days with surgery reference)
colorbar_flag = 0;
if and(exist("TT_surgery_day", "var"), not(day_num == 1))
    colorbar_flag = 1;
end

%% Load and process VAF data
% Create arrays to store VAF data
VAF_data_list = cell(1, day_num);
shuffle_VAF_data_list = cell(1, day_num);

% Load and process VAF data for each day
for day_id = 1:day_num
    ref_day_synergy_detail_file_name = selected_file_name_list{day_id};
    VAF_data_path = fullfile(synergy_detail_dir, ref_day_synergy_detail_file_name);

    % Load VAF data & shuffle data
    VAF_data = load(VAF_data_path, 'test');
    shuffle_data = load(VAF_data_path, 'shuffle');

    % Calculate average VAF values across cross-validation folds
    VAF_data_list{day_id} = mean(VAF_data.('test').r2, 2);
    shuffle_VAF_data_list{day_id} = mean(shuffle_data.shuffle.r2, 2);
end

% Convert cell arrays to matrices
VAF_data_list = cell2mat(VAF_data_list);
shuffle_VAF_data_list = cell2mat(shuffle_VAF_data_list);

% Calculate dVAF if needed (difference in VAF between consecutive synergy numbers)
if strcmp(figure_type, 'dVAF')
    dVAF_data_list = diff(VAF_data_list, 1);
    shuffle_dVAF_data_list = diff(shuffle_VAF_data_list, 1);
end

% Get number of muscles
[muscle_num, ~] = size(VAF_data_list);

%% Prepare for plotting
% Set plot parameters based on figure type
switch figure_type
    case 'VAF'
        use_shuffle_data_list = shuffle_VAF_data_list;
        use_VAF_data_list = VAF_data_list;
        x_axis = 1:muscle_num; 
        y_range = [0 1];
        legend_location = 'northwest';
    case 'dVAF'
        use_shuffle_data_list = shuffle_dVAF_data_list;
        use_VAF_data_list = dVAF_data_list;
        x_axis = 2:muscle_num;
        y_range = [0 0.4];
        legend_location = 'northeast';
end

%% Create and customize plot
figure('Position', [100, 100, 800, 600]);
hold on;

% Plot shuffled data results
shuffle_mean = mean(use_shuffle_data_list, 2);
shuffle_std = std(use_shuffle_data_list, 0, 2);
errorbar(x_axis, shuffle_mean, shuffle_std, 'o-', 'LineWidth', 2, 'Color', 'blue', 'DisplayName', [figure_type '-shuffle']);

% Plot actual VAF data based on plot type
switch VAF_plot_type
    case 'stack'
        % Prepare color matrix for multiple days
        if colorbar_flag == 1
            % Calculate day ranges relative to surgery day
            day_range = zeros(1, 2);
            day_range(1) = CountElapsedDate(day_name_list{1}, TT_surgery_day);
            day_range(2) = CountElapsedDate(day_name_list{end}, TT_surgery_day);

            % Create color gradient based on pre/post surgery
            color_matrix = zeros(day_num, 3);
            color_vector = linspace(0.4, 1, day_num);
            
            % Use green for pre-surgery days, red for post-surgery or mixed
            if all(day_range < 0)
                color_matrix(:, 2) = color_vector; % Green gradient for pre-surgery
            else
                color_matrix(:, 1) = color_vector; % Red gradient for post-surgery or mixed
            end
        else
            % Default red gradient if no surgery reference
            color_matrix = zeros(day_num, 3);
            color_vector = linspace(0.4, 1, day_num);
            color_matrix(:, 1) = color_vector;
        end

        % Plot each day's data
        for day_id = 1:day_num
            plot_VAF = use_VAF_data_list(:, day_id);
            plot(x_axis, plot_VAF, 'LineWidth', 2, 'Color', color_matrix(day_id, :), HandleVisibility='off');
            plot(x_axis, plot_VAF, 'o', 'LineWidth', 2, 'Color', color_matrix(day_id, :), HandleVisibility='off');
        end
    
        % Add colorbar if showing multiple days
        if colorbar_flag == 1
            clim(day_range);
            colormap(color_matrix);
            h = colorbar;
            ylabel(h, 'Elapsed day(criterion = TT)', 'FontSize', font_size);
        end
        
    case 'mean'
        % Calculate and plot mean VAF across all days
        plot_VAF = mean(use_VAF_data_list, 2);
        plot_VAF_std = std(use_VAF_data_list, 0, 2);
        errorbar(x_axis, plot_VAF, plot_VAF_std, 'o-', 'LineWidth', 2, 'Color', 'red', 'DisplayName', [figure_type '-' num2str(muscle_num) 'EMG_name_list']);
end

% Add threshold line for VAF plots
if strcmp(figure_type, 'VAF')
    yline(VAF_threshold, 'Color', 'k', 'LineWidth', 2, HandleVisibility='off');
end

% Add labels and customize plot appearance
xlim([0 muscle_num]);
ylim(y_range);
xlabel('Number of synergy', 'FontSize', font_size);
ylabel(['Value of ' figure_type], 'FontSize', font_size);
legend('Location', legend_location);
title([figure_type ' value of each session'], 'FontSize', font_size);

set(gca, 'FontSize', 25);
grid on;
hold off;

%% Save figures
% Set up save directory
save_figure_base_fold_path = strrep(base_dir_path, 'data', 'figure');
save_figure_fold_path = fullfile(save_figure_base_fold_path, 'VAF_result', figure_type, VAF_plot_type, use_EMG_type, ['use_EMG_num == ' num2str(use_EMG_num)]);
makefold(save_figure_fold_path);

% Create filenames and save figures based on selection mode
disp('--------------------------------------------------------------');
disp('Saving figures...');
figure_name = [figure_type '_result(' day_name_list{1} 'to' day_name_list{end} '_' num2str(length(day_name_list)) 'days_' VAF_plot_type ')'];
png_path = fullfile(save_figure_fold_path, [figure_name '.png']);
fig_path = fullfile(save_figure_fold_path, [figure_name '.fig']);

saveas(gcf, png_path);
saveas(gcf, fig_path);

disp(['Saved PNG figure to: ' png_path]);
disp(['Saved FIG figure to: ' fig_path]);
disp('Figure saving complete!');
disp('--------------------------------------------------------------');

close all;

